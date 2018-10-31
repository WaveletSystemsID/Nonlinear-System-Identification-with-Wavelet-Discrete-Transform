function [en,S] = Hammerstein_NLMS_adapt(un,dn,S)
% Fullband Volterra filtering adapt, 2nd order              
% 
% Arguments:
% un                Input signal
% dn                Desired signal
% S                 Adptive filter parameters as defined in Volterra_NLMS_init.m
% en                History of error signal

order = S.order; 
M = S.filters_lengths;              % kernel memory lengths 
mu = S.step;                      % Step Size here is an array 
AdaptStart = S.AdaptStart;        % Transient
alpha = S.alpha;                  % Small constant (1e-6)
leak = S.leaks;                 % Leaky factor 



xp = zeros(order, 1);  
w = zeros(M,1);
p = zeros(order, 1); % non linearity coeffs vector 
p(1) = 1; 
X = zeros(M, order); 

ITER = length(un);              % Length of input sequence
en = zeros(1,ITER);             % Initialize error sequence to zero

	
for n = 1:ITER
    
    for i = 1:order % build the coeff vector (taylor expansion)
        
         xp = [un(n)^i; xp(1:end-1)];                   
    end 
    
    X = cat(1, xp', X(1:end-1,:));  
    
    
    
    
    en(n) = dn(n) - w'*X*p;    
    
    if n >= AdaptStart
    
        p = (1-mu*leak)*p + (mu*en(n)*X'*w)/((X'*w)'*(X'*w)+alpha);
    
        w = (1-mu*leak)*w + (mu*en(n)*X*p)/((X*p)'*(X*p) + alpha); 
    
        S.iter = S.iter + 1;
    end
end

S.coeffs = w;           
end


    

