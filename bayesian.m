%#to calculate the expected price change dp_j based on a given x, where
%#x is the vector of current empirical prices, ending in our current price
%#
%#equation:
%#dpj = (sum over i=1 to n(y_i * exp(c(x,x_i))))/(sum over i=1 to n(exp(c(x,x_i)))
%#n=20 for our given set of patterns
%#x_i is a given pattern
%#y_i is the price change for the kmeans pattern
%#c is a constant chosen for best fit
%#defined in the paper
function dpj = bayesian(x, kmeans180s,kmeans360s,kmeans720s)
    %#based on the length of x, we choose S_j
    dpj = 1;
    S = [];
    c = -1; %#TODO choose a better c, should it be negative or not??
    switch length(x) 
    case 180
        S = kmeans180s;
    case 360
        S = kmeans360s;
    case 720
        S = kmeans720s;
    otherwise
    end
    %#compare x with the it in S using our similarity measure
    %#and return the conditional expectation, which is dp
    num = 0.0;
    den = 0.0;
    for i = 1:20
        cutS = S(i,1:length(x));
        distance = exp(c*vecsim(x,cutS));
        num = num + S(i,length(x))*distance;
        den = den + distance;    
    end
    
    if den~=0
        dpj = num/den;
    end
    
    end
    
