%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function:         [FVr_bestmem,S_bestval,I_nfeval] = deopt(fname,S_struct)
%                    
% Author:           Rainer Storn, Ken Price, Arnold Neumaier, Jim Van Zandt
% Description:      Minimization of a user-supplied function with respect to x(1:I_D),
%                   using the differential evolution (DE) algorithm.
%                   DE works best if [FVr_minbound,FVr_maxbound] covers the region where the
%                   global minimum is expected. DE is also somewhat sensitive to
%                   the choice of the stepsize F_weight. A good initial guess is to
%                   choose F_weight from interval [0.5, 1], e.g. 0.8. F_CR, the crossover
%                   probability constant from interval [0, 1] helps to maintain
%                   the diversity of the population but should be close to 1 for most. 
%                   practical cases. Only separable problems do better with CR close to 0.
%                   If the parameters are correlated, high values of F_CR work better.
%                   The reverse is true for no correlation.
%
%                   The number of population members I_NP is also not very critical. A
%                   good initial guess is 10*I_D. Depending on the difficulty of the
%                   problem I_NP can be lower than 10*I_D or must be higher than 10*I_D
%                   to achieve convergence.
%
%                   deopt is a vectorized variant of DE which, however, has a
%                   property which differs from the original version of DE:
%                   The random selection of vectors is performed by shuffling the
%                   population array. Hence a certain vector can't be chosen twice
%                   in the same term of the perturbation expression.
%                   Due to the vectorized expressions deopt executes fairly fast
%                   in MATLAB's interpreter environment.
%
% Parameters:       fname        (I)    String naming a function f(x,y) to minimize.
%                   S_struct     (I)    Problem data vector (must remain fixed during the
%                                       minimization). For details see Rundeopt.m.
%                   ---------members of S_struct----------------------------------------------------
%                   F_VTR        (I)    "Value To Reach". deopt will stop its minimization
%                                       if either the maximum number of iterations "I_itermax"
%                                       is reached or the best parameter vector "FVr_bestmem" 
%                                       has found a value f(FVr_bestmem,y) <= F_VTR.
%                   FVr_minbound (I)    Vector of lower bounds FVr_minbound(1) ... FVr_minbound(I_D)
%                                       of initial population.
%                                       *** note: these are not bound constraints!! ***
%                   FVr_maxbound (I)    Vector of upper bounds FVr_maxbound(1) ... FVr_maxbound(I_D)
%                                       of initial population.
%                   I_D          (I)    Number of parameters of the objective function. 
%                   I_NP         (I)    Number of population members.
%                   I_itermax    (I)    Maximum number of iterations (generations).
%                   F_weight     (I)    DE-stepsize F_weight from interval [0, 2].
%                   F_CR         (I)    Crossover probability constant from interval [0, 1].
%                   I_strategy   (I)    1 --> DE/rand/1             
%                                       2 --> DE/local-to-best/1             
%                                       3 --> DE/best/1 with jitter  
%                                       4 --> DE/rand/1 with per-vector-dither           
%                                       5 --> DE/rand/1 with per-generation-dither
%                                       6 --> DE/rand/1 either-or-algorithm
%                   I_refresh     (I)   Intermediate output will be produced after "I_refresh"
%                                       iterations. No intermediate output will be produced
%                                       if I_refresh is < 1.
%                                       
% Return value:     FVr_bestmem      (O)    Best parameter vector.
%                   S_bestval.I_nc   (O)    Number of constraints
%                   S_bestval.FVr_ca (O)    Constraint values. 0 means the constraints
%                                           are met. Values > 0 measure the distance
%                                           to a particular constraint.
%                   S_bestval.I_no   (O)    Number of objectives.
%                   S_bestval.FVr_oa (O)    Objective function values.
%                   I_nfeval         (O)    Number of function evaluations.
%
% Note:
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 1, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details. A copy of the GNU 
% General Public License can be obtained from the 
% Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [FVr_bestmem,S_bestval,I_nfeval] = deopt(fname,S_struct)

%-----This is just for notational convenience and to keep the code uncluttered.--------
I_NP         = S_struct.I_NP;
F_weight     = S_struct.F_weight;
F_CR         = S_struct.F_CR;
I_D          = S_struct.I_D;
FVr_minbound = S_struct.FVr_minbound;
FVr_maxbound = S_struct.FVr_maxbound;
I_bnd_constr = S_struct.I_bnd_constr;
I_itermax    = S_struct.I_itermax;
F_VTR        = S_struct.F_VTR;
I_strategy   = S_struct.I_strategy;
I_refresh    = S_struct.I_refresh;
I_plotting   = S_struct.I_plotting;

%-----Check input variables---------------------------------------------
if (I_NP < 5)
   I_NP=5;
   fprintf(1,' I_NP increased to minimal value 5\n');
end
if ((F_CR < 0) | (F_CR > 1))
   F_CR=0.5;
   fprintf(1,'F_CR should be from interval [0,1]; set to default value 0.5\n');
end
if (I_itermax <= 0)
   I_itermax = 200;
   fprintf(1,'I_itermax should be > 0; set to default value 200\n');
end
I_refresh = floor(I_refresh);

%-----Initialize population and some arrays-------------------------------
FM_pop = zeros(I_NP,I_D); %initialize FM_pop to gain speed

%----FM_pop is a matrix of size I_NPx(I_D+1). It will be initialized------
%----with random values between the min and max values of the-------------
%----parameters-----------------------------------------------------------

for k=1:I_NP
   FM_pop(k,:) = FVr_minbound + rand(1,I_D).*(FVr_maxbound - FVr_minbound);
end

FM_popold     = zeros(size(FM_pop));  % toggle population
FVr_bestmem   = zeros(1,I_D);% best population member ever
FVr_bestmemit = zeros(1,I_D);% best population member in iteration
I_nfeval      = 0;                    % number of function evaluations

%------Evaluate the best member after initialization----------------------

I_best_index   = 1;                   % start with first population member
S_val(1)       = feval(fname,FM_pop(I_best_index,:),S_struct);

S_bestval = S_val(1);                 % best objective function value so far
I_nfeval  = I_nfeval + 1;
for k=2:I_NP                          % check the remaining members
  S_val(k)  = feval(fname,FM_pop(k,:),S_struct);
  I_nfeval  = I_nfeval + 1;
  if (left_win(S_val(k),S_bestval) == 1)
     I_best_index   = k;              % save its location
     S_bestval      = S_val(k);
  end   
end
FVr_bestmemit = FM_pop(I_best_index,:); % best member of current iteration
S_bestvalit   = S_bestval;              % best value of current iteration

FVr_bestmem = FVr_bestmemit;            % best member ever

%------DE-Minimization---------------------------------------------
%------FM_popold is the population which has to compete. It is--------
%------static through one iteration. FM_pop is the newly--------------
%------emerging population.----------------------------------------

FM_pm1   = zeros(I_NP,I_D);   % initialize population matrix 1
FM_pm2   = zeros(I_NP,I_D);   % initialize population matrix 2
FM_pm3   = zeros(I_NP,I_D);   % initialize population matrix 3
FM_pm4   = zeros(I_NP,I_D);   % initialize population matrix 4
FM_pm5   = zeros(I_NP,I_D);   % initialize population matrix 5
FM_bm    = zeros(I_NP,I_D);   % initialize FVr_bestmember  matrix
FM_ui    = zeros(I_NP,I_D);   % intermediate population of perturbed vectors
FM_mui   = zeros(I_NP,I_D);   % mask for intermediate population
FM_mpo   = zeros(I_NP,I_D);   % mask for old population
FVr_rot  = (0:1:I_NP-1);               % rotating index array (size I_NP)
FVr_rotd = (0:1:I_D-1);       % rotating index array (size I_D)
FVr_rt   = zeros(I_NP);                % another rotating index array
FVr_rtd  = zeros(I_D);                 % rotating index array for exponential crossover
FVr_a1   = zeros(I_NP);                % index array
FVr_a2   = zeros(I_NP);                % index array
FVr_a3   = zeros(I_NP);                % index array
FVr_a4   = zeros(I_NP);                % index array
FVr_a5   = zeros(I_NP);                % index array
FVr_ind  = zeros(4);

FM_meanv = ones(I_NP,I_D);

I_iter = 1;
while ((I_iter < I_itermax) & (S_bestval.FVr_oa(1) > F_VTR))
  FM_popold = FM_pop;                  % save the old population
  S_struct.FM_pop = FM_pop;
  S_struct.FVr_bestmem = FVr_bestmem;
  
  FVr_ind = randperm(4);               % index pointer array

  FVr_a1  = randperm(I_NP);                   % shuffle locations of vectors
  FVr_rt  = rem(FVr_rot+FVr_ind(1),I_NP);     % rotate indices by ind(1) positions
  FVr_a2  = FVr_a1(FVr_rt+1);                 % rotate vector locations
  FVr_rt  = rem(FVr_rot+FVr_ind(2),I_NP);
  FVr_a3  = FVr_a2(FVr_rt+1);                
  FVr_rt  = rem(FVr_rot+FVr_ind(3),I_NP);
  FVr_a4  = FVr_a3(FVr_rt+1);               
  FVr_rt  = rem(FVr_rot+FVr_ind(4),I_NP);
  FVr_a5  = FVr_a4(FVr_rt+1);                

  FM_pm1 = FM_popold(FVr_a1,:);             % shuffled population 1
  FM_pm2 = FM_popold(FVr_a2,:);             % shuffled population 2
  FM_pm3 = FM_popold(FVr_a3,:);             % shuffled population 3
  FM_pm4 = FM_popold(FVr_a4,:);             % shuffled population 4
  FM_pm5 = FM_popold(FVr_a5,:);             % shuffled population 5

  for k=1:I_NP                              % population filled with the best member
    FM_bm(k,:) = FVr_bestmemit;             % of the last iteration
  end

  FM_mui = rand(I_NP,I_D) < F_CR;  % all random numbers < F_CR are 1, 0 otherwise
  
  %----Insert this if you want exponential crossover.----------------
  %FM_mui = sort(FM_mui');	  % transpose, collect 1's in each column
  %for k  = 1:I_NP
  %  n = floor(rand*I_D);
  %  if (n > 0)
  %     FVr_rtd     = rem(FVr_rotd+n,I_D);
  %     FM_mui(:,k) = FM_mui(FVr_rtd+1,k); %rotate column k by n
  %  end
  %end
  %FM_mui = FM_mui';			  % transpose back
  %----End: exponential crossover------------------------------------
  
  FM_mpo = FM_mui < 0.5;    % inverse mask to FM_mui

  if (I_strategy == 1)                             % DE/rand/1
    FM_ui = FM_pm3 + F_weight*(FM_pm1 - FM_pm2);   % differential variation
    FM_ui = FM_popold.*FM_mpo + FM_ui.*FM_mui;     % crossover
    FM_origin = FM_pm3;
  elseif (I_strategy == 2)                         % DE/local-to-best/1
    FM_ui = FM_popold + F_weight*(FM_bm-FM_popold) + F_weight*(FM_pm1 - FM_pm2);
    FM_ui = FM_popold.*FM_mpo + FM_ui.*FM_mui;
    FM_origin = FM_popold;
  elseif (I_strategy == 3)                         % DE/best/1 with jitter
    FM_ui = FM_bm + (FM_pm1 - FM_pm2).*((1-0.9999)*rand(I_NP,I_D)+F_weight);               
    FM_ui = FM_popold.*FM_mpo + FM_ui.*FM_mui;
    FM_origin = FM_bm;
  elseif (I_strategy == 4)                         % DE/rand/1 with per-vector-dither
     f1 = ((1-F_weight)*rand(I_NP,1)+F_weight);
     for k=1:I_D
        FM_pm5(:,k)=f1;
     end
     FM_ui = FM_pm3 + (FM_pm1 - FM_pm2).*FM_pm5;    % differential variation
     FM_origin = FM_pm3;
     FM_ui = FM_popold.*FM_mpo + FM_ui.*FM_mui;     % crossover
  elseif (I_strategy == 5)                          % DE/rand/1 with per-vector-dither
     f1 = ((1-F_weight)*rand+F_weight);
     FM_ui = FM_pm3 + (FM_pm1 - FM_pm2)*f1;         % differential variation
     FM_origin = FM_pm3;
     FM_ui = FM_popold.*FM_mpo + FM_ui.*FM_mui;     % crossover
  else                                              % either-or-algorithm
     if (rand < 0.5);                               % Pmu = 0.5
        FM_ui = FM_pm3 + F_weight*(FM_pm1 - FM_pm2);% differential variation
        FM_origin = FM_pm3;
     else                                           % use F-K-Rule: K = 0.5(F+1)
        FM_ui = FM_pm3 + 0.5*(F_weight+1.0)*(FM_pm1 + FM_pm2 - 2*FM_pm3);
     end
     FM_ui = FM_popold.*FM_mpo + FM_ui.*FM_mui;     % crossover     
  end
  
%-----Optional parent+child selection-----------------------------------------
  
%-----Select which vectors are allowed to enter the new population------------
  for k=1:I_NP
   
      %=====Only use this if boundary constraints are needed==================
      if (I_bnd_constr == 1)
         for j=1:I_D %----boundary constraints via bounce back-------
            if (FM_ui(k,j) > FVr_maxbound(j))
               FM_ui(k,j) = FVr_maxbound(j) + rand*(FM_origin(k,j) - FVr_maxbound(j));
            end
            if (FM_ui(k,j) < FVr_minbound(j))
               FM_ui(k,j) = FVr_minbound(j) + rand*(FM_origin(k,j) - FVr_minbound(j));
            end   
         end
      end
      %=====End boundary constraints==========================================
  
      S_tempval = feval(fname,FM_ui(k,:),S_struct);   % check cost of competitor
      I_nfeval  = I_nfeval + 1;
      if (left_win(S_tempval,S_val(k)) == 1)   
         FM_pop(k,:) = FM_ui(k,:);                    % replace old vector with new one (for new iteration)
         S_val(k)   = S_tempval;                      % save value in "cost array"
      
         %----we update S_bestval only in case of success to save time-----------
         if (left_win(S_tempval,S_bestval) == 1)   
            S_bestval = S_tempval;                    % new best value
            FVr_bestmem = FM_ui(k,:);                 % new best parameter vector ever
         end
      end
   end % for k = 1:NP

  FVr_bestmemit = FVr_bestmem;       % freeze the best member of this iteration for the coming 
                                     % iteration. This is needed for some of the strategies.

%----Output section----------------------------------------------------------

  if (I_refresh > 0)
     if ((rem(I_iter,I_refresh) == 0) | I_iter == 1)
       fprintf(1,'Iteration: %d,  Best: %f,  F_weight: %f,  F_CR: %f,  I_NP: %d\n',I_iter,S_bestval.FVr_oa(1),F_weight,F_CR,I_NP);
       %var(FM_pop)
       format long e;
       for n=1:I_D
          fprintf(1,'best(%d) = %g\n',n,FVr_bestmem(n));
       end
       if (I_plotting == 1)
          PlotIt(FVr_bestmem,I_iter,S_struct); 
       end
    end
  end

  I_iter = I_iter + 1;
end %---end while ((I_iter < I_itermax) ...
