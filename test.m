% testing on new December 2016 price data

dataArray = csvread('results.csv');
prices = transpose(dataArray(:,2));
askVolume = dataArray(:,3);
bidVolume = dataArray(:,4);

prices = prices(1:2:end);
askVolume = askVolume(1:2:end);
bidVolume = bidVolume(1:2:end);

% estimate transaction fee at %1
[error,jinzhi,bank,buy,sell,proba] = brtrade(prices,bidVolume,askVolume, 1);

% set up plots
make_plots(prices, buy, sell, proba, bank, error);
