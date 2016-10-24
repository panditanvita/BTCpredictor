%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function:         step(FVr_x)
% Author:           Rainer Storn
% Description:      Implements the step function which is 0 for
%                   negative input arguments and 1 otherwise.
% Parameters:       FVr_x        (I)    Input vector
% Return value:     FVr_y        (O)    Output vector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FVr_y = step(FVr_x)
   FVr_y = 0.5*sign(FVr_x)+0.5;
return