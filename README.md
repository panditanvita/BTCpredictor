# btcpredictor
predicting bitcoin prices using bayesian regression techniques

this project aims to implement the algorithm described in the 2014 MIT paper, Bayesian Regression and Bitcoin 
by Devavrat Shah and Kang Zhang. The paper can be found under references/mit paper

The algorithm first attempts to identify patterns within historical price data using k-means clustering using one set of prices.
It then uses the second set of prices to train weights for its predicted price function. This is where the Bayesian regression comes in - 
at time t, we evaluate three vectors of past prices of different time intervals. We compare these vectors to the known kmeans patterns 
with their known price change, to find a probabilistic average for the predicted price change at t.
The third set of prices is used to evaluate the algorithm. 

How to use it:
All the relevant code is in MATLAB. The BTC price data is avaiable as two csvs of okcoin or coinbase data at 5s intervals. The okcoin 
data also comes with bid volume and ask volume (number of bitcoins bidded/asked at time t).
Run algotrading.m in matlab, which will carry out all three steps above and return [bank,error], which is the predicted profit, and 
the error of the current implementation. 

bayesian.m performs the bayesian regression 
train_regressor.m trains the weights w using linear regression and l2 regularization 
brtrade.m performs the final evaluation
vecsim.m calculates similarity between two vectors

What Next?
The code in its current state does not seem to be effective at its function. It is possible to further tweak several constants 
but I am currently at a loss as to how the paper acheived a Sharpe ratio of 4. I will be following up on this with some more 
math-oriented friends, because I think I implemented what was described. 

Attribution
The train_regressor code was written by MIT 6.S03 staff, and the scraping of historical prices was done by Shaurya Saluja. 
All other code was written by me (Anvita Pandit).
