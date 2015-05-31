%################
%#step 3: evaluation of performance
%
%#using our third set of prices, we estimate dp at each time interval,
%#if dp > t and current position <= 0 , we buy
%#if dp < -t and current position >= 0, we sell
%#else, do nothing
%################

%#trade using the above algorithm. returns expected profit
%#
%#given a list of prices
%#assumes k-means clustered patterns have already been calculated
%#assumes parameters w_i have already been calculated
%#position is -1, 0 or 1 (we have sold a bitcoin, done nothing, bought a bitcoin)
%#bank is the amount of cash we have
%#threshold is the threshold for buying/selling
%#defined in the paper
function [bank,error] = brtrade(prices, kmeans180s,kmeans360s,kmeans720s,theta,theta0,bidVolume,askVolume)
    threshold = .6;
    position = 0;
    bank = 0;
    error = 0; %current error metric is sum(abs(error))/time interval = ~.9
    
    for t = 750:length(prices)-1    
        price180 = prices(t-179:t);      
        price360 = prices(t-359:t);      
        price720 = prices(t-719:t);

%#average price change dp_j is given by bayesian regression    
        dp1 = bayesian(price180,kmeans180s);
        dp2 = bayesian(price360,kmeans360s);
        dp3 = bayesian(price720,kmeans720s);

        r = (bidVolume(t)-askVolume(t))/(bidVolume(t)+askVolume(t));
        
        dp = theta0 +  theta(1)*dp1 + theta(2)*dp2 + theta(3)*dp3 + theta(4)*r;
        
        error = error + abs(prices(t+1)-(prices(t)+dp));
        %#BUY
        if (dp >threshold && position <= 0)
            position = position + 1;
            bank = bank- prices(t);
            disp('buying');
        end 
        %#SELL
        if (dp < -threshold && position >= 0)
            position = position -1;
            bank = bank + prices(t);
            disp('selling');
        end
    end
    
    error = error/(length(prices)-1);
    %settle at end
    if (position == 1)
        bank = bank + prices(length(prices));
    end
    if (position == -1)
        bank = bank - prices(length(prices));
    end
    
    end
