%
% step 3: evaluation of performance
%
% using our third set of prices, we estimate dp at each time interval,
% if dp > t and current position <= 0 , we buy
% if dp < -t and current position >= 0, we sell
% else, do:nothing
%

% trade using the above algorithm. returns expected profit
%
% given a list of prices
% assumes k-means clustered patterns have already been calculated
% assumes parameters w_i have already been calculated
% position is 0 or 1 (we have nothing, we have a bitcoin)
% bank is the amount of cash we have
% threshold is the threshold for buying/selling
% defined in the paper
function [error,jinzhi,bank,buy,sell,proba] = brtrade(prices, bidVolume,askVolume, fee)
    assert(exist('thetas.mat','file')==2)
    load('thetas.mat');
    assert(isequal(length(prices), length(bidVolume)));
    assert(isequal(length(prices), length(askVolume)));
    position = 0;
    bank = 0;
    jinzhi = zeros(length(prices)-750, 1);
    error = 0; 
    %current error metric is sum(abs(error))/time interval = ~.9
    %current error = 0.06
    buy = [];
    sell = [];
    counttotal = 0;
    counts = 0;
    temp = 0;
    for t = 720:length(prices)-1  
        price180 = zscore(prices(t-179:t));      
        price360 = zscore(prices(t-359:t));      
        price720 = zscore(prices(t-719:t));

        %average price change dp_j is given by bayesian regression    
        dp1 = bayesian(price180,kmeans180s);
        dp2 = bayesian(price360,kmeans360s);
        dp3 = bayesian(price720,kmeans720s);

        r = (bidVolume(t)-askVolume(t))/(bidVolume(t)+askVolume(t));
        
        dp = theta0 +  theta(1)*dp1 + theta(2)*dp2 + theta(3)*dp3;% + theta(4)*r;
        
        % compare price at t+1 with predicted price jump
        error = error + abs(prices(t+1)-prices(t)-dp);
        
        % calculate transaction fee??
        % threshold 1 and 2 before...but 
        % there is definitely not going to be a 
        % 5-8$ price jump predicted in the next ten seconds
        % need to consider TODO
		fee = 0;
		if (fee == 0)
            tfee_buy = 0.001;
            tfee_sell = 0.003;
        else
            tfee_buy = fee*prices(2)/100;
            tfee_sell = tfee_buy;
        end
        %BUY
        if (dp > tfee_buy && position == 0)
            position = 1;
            temp = prices(t);
            fprintf('Buying at %d\n', temp);
            buy = [buy;t];
        end 
        %SELL
        if (dp < -tfee_sell && position == 1)
            position = 0;
            bank = bank + prices(t)-temp;
            fprintf('Selling at %d\n', prices(t));
            sell = [sell;t];
            counttotal = counttotal+1;
            if prices(t)-temp>0
                counts = counts+1;
            end
        end

        jinzhi(t) = bank;
    end
    
    % forces us to close the position at the end
    % tradeoffs to this decision
    % on one side: more realistic
    % but the algorithm doesn't yet account for it
    if (position == 1)
        bank = bank + prices(t)-temp;
        fprintf('Final sale at %d\n', prices(t));
        sell = [sell;t];
        counttotal = counttotal+1;
        if prices(t)-temp>0
            counts = counts+1;
        end
    end
    proba = (counts./counttotal)*100;
    end
