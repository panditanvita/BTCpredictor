# btcpredictor
predicting bitcoin prices using bayesian regression techniques

this project aims to implement the algorithm described in the 2014 MIT paper, Bayesian Regression and Bitcoin 
by Devavrat Shah and Kang Zhang. The paper can be found under references/mit paper

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

##What Next? 
The code in its current state does not seem to be effective at its function. After speaking to one of the authors of the paper, I think I implemented what was described. The main item left would be to selectively choose 20 effective patterns from the 100 k-means clustered patterns - the current implementation goes straight to clustering 20 patterns.  It is possible to further tweak several constants, but I am still left at a loss as to how the paper acheived a Sharpe ratio of 4. 

##Edit Sep 10, 2015
**Some things which I should have written up much earlier (sorry!). 
A potential reason why the current implementation is ineffective:
The current patterns chosen by the algorithm using clustering look like flat lines when graphed. For example, a set of 20 price vectors at 5-s intervals will have 20 vectors with similar mean values, which do not diverge much from this mea value over the entire time interval. This makes sense because this averaging would give the lowest error margins between the k-means vector patterns and the set of all vector patterns, so the algorithm would choose for it. But a flat line is not a good predictor of price changes.**

As explained in the paper, the authors hand-selected 20 patterns and observed that their 'best' patterns were similar to those seen in trading textbooks i.e. the head and shoulders, the triangle. 

Another important point is that the algorithm described in the paper has not been implemented in real time yet - the current version created by the authors, which reaches the purported Sharpe ratio, is not fast enough to use in the market. I believe the authors of the paper are currently working on this, and I've heard from a dozen other github users that they are as well. good luck! I personally have not put more work into this - the code given was my last attempt - but I'd be happy to answer any questions.**

##Attribution
The train_regressor code was written by MIT 6.S03 staff, and the scraping of historical prices was done by Shaurya Saluja. 
All other code was written by me (Anvita Pandit).
If you find this useful, or want to discuss it further, I can be reached at pandit at mit dot edu
If you use this, do attribute me.

The csv files are available at https://bitbucket.org/anvitapandit/btcpredictor (too large for my github)
