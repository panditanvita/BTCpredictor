# btcpredictor
predicting bitcoin prices using bayesian regression techniques

this project aims to implement the algorithm described in the 2014 MIT paper, Bayesian Regression and Bitcoin 
by Devavrat Shah and Kang Zhang. The paper is here -> https://arxiv.org/pdf/1410.1231v1.pdf

The algorithm first attempts to identify patterns within historical price data using k-means clustering using one set of prices.
It then uses the second set of prices to train weights for its predicted price function. This is where the Bayesian regression comes in - 
at time t, we evaluate three vectors of past prices of different time intervals. We compare these vectors to the known kmeans patterns 
with their known price change, to find a probabilistic average for the predicted price change at t.
The third set of prices is used to evaluate the algorithm. 

##How to use it: 
All the relevant code is in MATLAB. The BTC price data is avaiable as two csvs of okcoin or coinbase data at 5s intervals. The okcoin 
data also comes with bid volume and ask volume (number of bitcoins bidded/asked at time t).
Run algotrading.m in matlab, which will carry out all three steps above and return [bank,error], which is the predicted profit, and 
the error of the current implementation. 

-bayesian.m performs the bayesian regression 
-train_regressor.m trains the weights w using linear regression and L2 regularization 
-brtrade.m performs the final evaluation
-vecsim.m calculates similarity between two vectors

##Exciting News, Oct 24, 2016
a certain Han Li emailed me a number of code improvements, including the use of Sample Entropy to choose effective patterns, and a Diffrential Evolution optimisation function (instead of the previous linear regression code), and several bug fixes
the results are a lot more promising and make a very modest profit of about ~1% across three days trading on the historical data.

![alt tag]('buy-sell.png')

I also realized matlab doesn't do garbage collection, and have thus added a lot more cleanup 

##Attribution
The scraping of historical prices was done by Shaurya Saluja. The DE algorithm is available at http://www1.icsi.berkeley.edu/~storn/code.html, and adding the DE and sample entropy was done by Han Li
All other code was written by me (Anvita Pandit).
If you find this useful, or want to discuss it further, I can be reached at pandit at mit dot edu
If you use this, do attribute me.

The csv files are available at https://bitbucket.org/anvitapandit/btcpredictor (too large for my github)
