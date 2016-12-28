% make plots and print out useful stats

function n = make_plots(prices, buy, sell, proba, bank, error) 

n = length(prices);
sbuy = nan(n,1);
ssell = nan(n,2);
sbuy(buy) = prices(buy);
ssell(sell) = prices(sell);
fprintf('Error of prediction, on average: %d\n', error/n);
fprintf('Win rate: %d percent\nTotal profit: $%d \n', proba, bank);
fprintf('Percent profit(approx): %d\n', bank*100/prices(end))
% create plots of buy/sell points
% note: cannot plot when running on -nojvm flag
plot(1:n,prices,'blue');
hold on
plot(1:n,sbuy,'.red' ,'MarkerSize',20);
hold on
plot(1:n,ssell,'.green' ,'MarkerSize',20);

end