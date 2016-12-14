% algo trading
clear all;
% delete('reg.mat') % won't exist on first run

% import prices as column vectors from the csv sheet
% about 120 000 values
dataArray = csvread('okcoin5s.csv');
prices = dataArray(:,2);
askVolume = dataArray(:,3);
bidVolume = dataArray(:,4);
clear dataArray;

prices = transpose(prices);
% breakpoint for selecting price series
% prices1 = [:b] prices2 = [b:b*2] prices3 = [b*2:]
b = 20000;

prices = prices(1:2:end); %turns 5s to 10s steps
askVolume = askVolume(1:2:end);
bidVolume = bidVolume(1:2:end);

askVolume = askVolume(b+1:end);
bidVolume = bidVolume(b+1:end);

prices1 = prices(1:b); 
prices2 = prices(b+1:b*2);
prices3 = prices(b*2+1:end);
%
% step 1: creating intervals S_j
%
% create list of all 720*10s, 360*10s and 180*10s intervals
% each item is (interval of prices, NEXT TEN SEC interval price change)

priceDiff = diff(prices);
clear prices
validIntSize = length(prices1)-750; %valid interval size
interval720s = zeros(validIntSize,720+1);
interval360s = zeros(validIntSize,360+1);
interval180s = zeros(validIntSize,180+1); 

for i = 1:validIntSize   
    interval180s(i,:) = [prices1(i:i+179),priceDiff(i+179)]; 
    interval360s(i,:) = [prices1(i:i+359),priceDiff(i+359)]; 
    interval720s(i,:) = [prices1(i:i+719),priceDiff(i+719)];   
end

clear prices1
clear priceDiff
%now we k-means cluster all 3 interval lists to get the 20 best patterns
%for each of the interval lists 

clusters = 100;
% parpool doesn't work for me locally
% to use, uncomment the two lines and change UseParallel option to 1

%pool = parpool;                      % Invokes workers
stream = RandStream('mlfg6331_64');  % Random number stream
options = statset('UseParallel',0,'UseSubstreams',1,...
    'Streams',stream);
disp('starting clustering');
tic
[ID180,kmeans180s1] = kmeans(interval180s,clusters,'Options',options,'MaxIter',10000,'Display','final','Replicates',4);
[ID360,kmeans360s1] = kmeans(interval360s,clusters,'Options',options,'MaxIter',10000,'Display','final','Replicates',4);
[ID720,kmeans720s1] = kmeans(interval720s,clusters,'Options',options,'MaxIter',10000,'Display','final','Replicates',4);
toc
%delete(pool)

% consider: for speed, use similarity instead of L2 norm for kmeans?

% regularize so the mean = 0 and std =1
for i = 1:clusters
kmeans180s1(i,1:180) = zscore(kmeans180s1(i,1:180));
kmeans360s1(i,1:360) = zscore(kmeans360s1(i,1:360));
kmeans720s1(i,1:720) = zscore(kmeans720s1(i,1:720));
end

% use sample entropy to choose interesting/effective patterns 
entropy180=zeros(clusters,1);
entropy360=zeros(clusters,1);
entropy720=zeros(clusters,1);
for i = 1:clusters
 entropy180(i)=ys_sampEntropy(kmeans180s1(i,1:180));
 entropy360(i)=ys_sampEntropy(kmeans360s1(i,1:180));   
 entropy720(i)=ys_sampEntropy(kmeans720s1(i,1:180)); % looks wrong, but gets worse profits when corrected  
end
% sort by 20 most interesting, and save these
[B,IX]=sort(entropy180,'descend');
IX180=IX(1:20);
[B,IX]=sort(entropy360,'descend');
IX360=IX(1:20);
[B,IX]=sort(entropy720,'descend');
IX720=IX(1:20);
kmeans180s=kmeans180s1(IX180,:);
kmeans360s=kmeans360s1(IX360,:);
kmeans720s=kmeans720s1(IX720,:);

disp('finished clustering and normalizing');
clear kmeans180s1;
clear kmeans360s1;
clear kmeans720s1;

%
%step 2: predicting average price change dp_j and learning parameters w_i
%using Bayesian regression
%
%equation:
%dp = w0 + w1*dp1 + w2*dp2 + w3*dp3 + w4*r
%

regressorX = zeros(length(prices2)-750-1,4);
regressorY = zeros(1,length(prices2)-750-1);

for i= 750:length(prices2)-1
    price180 = zscore(prices2(i-179:i));      
    price360 = zscore(prices2(i-359:i));      
    price720 = zscore(prices2(i-719:i));
    
    %average price change dp_j is given by bayesian regression    
    dp1 = bayesian(price180, kmeans180s);
    dp2 = bayesian(price360, kmeans360s); 
    dp3 = bayesian(price720, kmeans720s);
    
    r = (bidVolume(i)-askVolume(i))/(bidVolume(i)+askVolume(i)); 
    
    regressorX(i-749,:) = [dp1,dp2,dp3,r];
    regressorY(i-749) = prices2(i+1)-prices2(i);   
end

clear prices2

% Set up differential evolution optimization

save('reg.mat','regressorX','regressorY');
run Rundeopt;

theta=zeros(4,1);
theta0=0;
theta(1)=FVr_x(1);
theta(2)=FVr_x(2);
theta(3)=FVr_x(3);
theta(4)=FVr_x(4);
theta0=FVr_x(5);

% Start trading with last list of prices
disp('finished regression, ready to trade');
tic
[error,jinzhi,bank,buy,sell,proba] = brtrade(prices3, kmeans180s,kmeans360s, ...
    kmeans720s,theta,theta0,bidVolume(b+1:end),askVolume(b+1:end));
toc

% set up plots
n = length(prices3);
sbuy = nan(n,1);
ssell = nan(n,2);
sbuy(buy) = prices3(buy);
ssell(sell) = prices3(sell);
fprintf('Win rate: %d percent\nTotal profit: %d\n', proba, bank);

% create plots of buy/sell points
% note: cannot plot when running on -nojvm flag
plot(1:n,prices3,'blue');
hold on
plot(1:n,sbuy,'.red' ,'MarkerSize',20);
hold on
plot(1:n,ssell,'.green' ,'MarkerSize',20);
