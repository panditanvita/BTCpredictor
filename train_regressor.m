function [theta, theta_0] = train_regressor(X, y, gamma)
% X is a matrix with d columns, one for each dimension of the 
% feature vector, and n rows, one for each training example
% y is an n-length vector of training example values.
% gamma is a scalar regularization parameter (gamma = 0, no regularization)
% theta is an n-length vector of feature weights, 
% theta_0 is a scalar offset.

% If the data can be fit perfectly, then X*theta + theta_0 = y, otherwise
% theta and theta_0 are chosen to minimize the sum of the squares of the error
% plus gamma *(theta'*theta + theta_0^2).  Here, the error is 
% (y - (X*theta + theta_0)).
d = size(X,2);
n = size(X,1);

last_col = ones(n,1);
Xp = [X, last_col];
if gamma > 0
    I_np1 = speye(d+1);
    I_n = I_np1(1:end-1, :);
    Xp = [Xp; sqrt(gamma)*I_n];
    y = [y; zeros(d,1)];
end
    
theta_theta_0 = Xp \ y;
assert(length(theta_theta_0 ) == d+1);
theta = theta_theta_0(1:d);
theta_0 = theta_theta_0(end);

end

