%algo trading

%import prices and dateTime as column vectors from the csv sheet
%about 120 000 values
importcsv();

assert(length(prices) == length(askVolume));
assert(length(prices) == length(bidVolume));
prices = transpose(prices);

prices = prices(1:2:length(prices)); %turns 5s to 10s steps
askVolume = askVolume(1:2:length(askVolume));
bidVolume = bidVolume(1:2:length(bidVolume));

prices1 = prices(1:20000); 
prices2 = prices(20001:40000);
prices3 = prices(40001:length(prices));

%#############################
%#step 1: creating intervals S_j
%#############################
%#create list of all 720*10s, 360*10s and 180*10s intervals
%#each item is (interval of prices, NEXT TEN SEC interval price change)

priceDiff = diff(prices);
validIntSize = length(prices1)-750; %valid interval size
interval720s = zeros(validIntSize,720+1);
interval360s = zeros(validIntSize,360+1);
interval180s = zeros(validIntSize,180+1); 

for i = 1:validIntSize   
    interval180s(i,:) = [prices1(i:i+179),priceDiff(i+179)]; 
    interval360s(i,:) = [prices1(i:i+359),priceDiff(i+359)]; 
    interval720s(i,:) = [prices1(i:i+719),priceDiff(i+719)];   
end

%#now we k-means cluster all 3 interval lists to get the 20 best patterns
%#for each of the interval lists 
clusters = 20;

[~,kmeans180s] = kmeans(interval180s,clusters); 
[~,kmeans360s] = kmeans(interval360s,clusters); 
[~,kmeans720s] = kmeans(interval720s,clusters); %this one has difficulty converging

%TODO for speed, use similarity instead of L2 norm for kmeans?

for i = 1:clusters
    kmeans180s(i,1:180) = zscore(kmeans180s(i,1:180));
    kmeans360s(i,1:360) = zscore(kmeans360s(i,1:360));
    kmeans720s(i,1:720) = zscore(kmeans720s(i,1:720));
end

disp('finished clustering and normalizing');
%################
%#step 2: predicting average price change dp_j and learning parameters w_i
%#using Bayesian regression
%#
%#equation:
%#dp = w0 + w1*dp1 + w2*dp2 + w3*dp3 + w4*r
%################

regressorX = zeros(length(prices2)-750-1,4);
regressorY = zeros(1,length(prices2)-750-1);

for i= 750:length(prices2)-1
    price180 = prices2(i-179:i);      
    price360 = prices2(i-359:i);      
    price720 = prices2(i-719:i);
    
%#average price change dp_j is given by bayesian regression    
    dp1 = bayesian(price180, kmeans180s);
    dp2 = bayesian(price360, kmeans360s);
    dp3 = bayesian(price720, kmeans720s);
    
    r = (bidVolume(i)-askVolume(i))/(bidVolume(i)+askVolume(i)); 
    
    regressorX(i-749,:) = [dp1,dp2,dp3,r];
    regressorY(i-749) = prices2(i+1)-prices2(i);   
end

%last parameter is regularization gamma, need to find a good value TODO
[theta, theta0] = train_regressor(regressorX, transpose(regressorY), 1);
disp('finished regression, ready to trade');

m = length(prices1) + length(prices2); %we want to take bid/ask data from right index

%start trading with last list of prices
tic
[bank,error] = brtrade(prices3, kmeans180s,kmeans360s,kmeans720s,theta,theta0,bidVolume(m:end),askVolume(m:end));
toc
