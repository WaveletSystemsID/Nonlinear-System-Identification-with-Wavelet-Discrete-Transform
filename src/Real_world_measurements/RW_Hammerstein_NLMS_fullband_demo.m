% Volterra NLMS fullband demo       Fullband Volterra second order adaptive
%                                   filtering
% 
% by A. Castellani & S. Cornell [Universit� Politecnica delle Marche]

diary log_VNLMS.txt
fprintf('%s \n', datestr(datetime('now')));
addpath(genpath('../../Common'));             % Functions in Common folder
clear all;  
%close all;

%% Unidentified System parameters

order = 4; 
M = 256; %% hammerstein filters lens
gains = ones(2,1);

%algorithm parameters
mu = [0.02 0.02]; %ap aw
leak = [0 0]; 


un = load('xperia_ref_speech_f'); 
un = un.un;
dn = load('xperia_resp_speech_f'); 
dn = dn.dn;

[corr, lag]= xcorr(un,dn); 
[~, ind]= max(abs(corr)); 
latency = abs(lag(ind)); 

%latency = 3120; 
 
dn = dn(latency:end); 
un = un(1:end-latency); 

 % normalization 

% un = un/std(dn);
% dn = dn/std(dn);

%normalization speech 
a = abs(max(dn))/sqrt(2); 
un = un/a; 
dn= dn/ a; 
%  
 
max_iter = size(un,2); 

%% Hammerstein
fprintf('-------------------------------------------------------------\n');
fprintf('HAMMERSTEIN\n');

% Run parameters
iter = 2.0*80000;   % Number of iterations

if iter > max_iter
   
    disp("WARNING: iter must be < max iter"); 
    iter = max_iter; 
    
end

un = un(1,1:iter); 
dn = dn(1,1:iter); 


%[un,dn,vn] = GenerateResponses_nonlinear(iter,b,sum(100*clock),1,40, 'tanh', 0.2); %iter, b, seed, ARtype, SNR


%[un,dn,vn] = GenerateResponses_Hammerstein(iter, lin_system ,gains, order,sum(100*clock),1,40);
% [un,dn,vn] = GenerateResponses_speech_Volterra(NL_system,'speech.mat');

tic;
Sfull = Hammerstein_NLMS_init(order, M, mu, leak); 
[en, Sfull] = Hammerstein_NLMS_adapt(un, dn, Sfull);     

err_sqr_full = en.^2;
    
fprintf('Total time = %.3f mins \n',toc/60);

% Plot MSE
figure;
q = 0.99; MSE_full = filter((1-q),[1 -q],err_sqr_full);
subplot(2,1,1); 
plot((0:length(MSE_full)-1)/1024,10*log10(MSE_full), 'DisplayName', 'FB NLMS');
axis([0 length(MSE_full)/1024 -inf 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)'); grid on;
legend('show');

fprintf('NMSE = %.2f dB\n', 10*log10(sum(err_sqr_full)/sum(dn.^2)));

fprintf('\n');  % Empty line in logfile
diary off

subplot(2,1,2); 
plot((0:length(dn)-1)/1024,dn, 'DisplayName', 'dn');
axis([0 length(dn)/1024 -3  3]);
