% Volterra MWSAF       Multi Structured Wavelet-domain Adaptive Filter Demo
% 
% by A. Castellani & S. Cornell [Universit� Politecnica delle Marche]

addpath '../Common';             % Functions in Common folder
clear all;  
% close all;

%% Unidentified System parameters
order = 2; 
M1 = 256; % length of first order volterra kernel
M2 = 8; % length of second order volterra kernel

NL_system.M = [M1, M2];
gains = [1 1];

%NL_system = create_volterra_sys(order, M, gains, 'nlsys1'); 
%% Just a Delta
% ker1 = zeros(M1,1);
% ker1(1) = 1;
% % ker2 = diag(ones(M2,1));
% ker2 = zeros(M2,M2);
% ker2(1,1) = 2;

%% Random Vector 
rng('default'); % For reproducibility
% ker1 = rand(M1,1) - rand(1);
% shift = 0;      
% ker2 = diag(rand(M2-shift,1)- rand(1) , shift); 
% 
% N = 5; %diagonals number, beyond the main one
% for i = 1:N
%     d = diag(ones(M2-i,1),i);
%     ker2(d(:,:)==1) = rand(M2-i, 1) - rand(1);
% end    
% 
% d = eye(M2); ker2(d(:,:)==1) = rand(M2,1)- rand(1) ;     % instert principal diagonal

%% Simulated Kernel - random
ker1 = rand(M1,1)-rand(1);
ker2 = second_order_kernel(M2);


%% Simulated kernel - from h1 h2
% b1 = load('h1.dat');
% b1 = b1(1:M1);
% ker1 = b1;
% 
% b2 = load('h2.dat');
% b2 = b2(1:M2);
% ker2 = second_order_kernel(b2);


NL_system.Responses = {gains(1).*ker1, gains(2).*ker2};


% NL_system = create_volterra_sys(order, M, gains, 'nlsys1'); 

%% Plot 2-D kernel
kernel_plot(NL_system.Responses);


%% Adaptive filter parameters
mu = [0.1, 0.1];            %Step sizes for different kernels 

level = 3;                  % Levels of Wavelet decomposition for different kernels
filters = 'db1';            % Set wavelet type for different kernels


% Run parameters
iter = 1.5*80000;            % Number of iterations

%%
% Adaptation process

disp('Creating desired and input signals. . .');
fprintf('Kernel Length: [%d, %d], iter= %d\n', M1, M2, iter);
%[un,dn,vn] = GenerateResponses_Volterra(iter, NL_system ,sum(100*clock),1,40); %iter, b, seed, ARtype, SNR
[un,dn,vn] = GenerateResponses_speech_Volterra(NL_system,'speech_harvard.mat');


%% WAVTERRA

% Nonlinear model 
fprintf('--------------------------------------------------------------------\n');
fprintf('WAVTERRA\n');
fprintf('Wavelet type: %s, levels: %d, step size = %s \n', filters, level, sprintf('%s ', mu));

tic;
S = Volterra_Init(NL_system.M, mu, level, filters); 

% [en, S] = Volterra_2ord_adapt(un, dn, S);     
% [en, S] = Volterra_2ord_adapt_shift(un, dn, S, shift);   

S.true = NL_system.Responses; 
[en, S] = Volterra_2ord_adapt_v3(un, dn, S);

% [en, S] = Volterra_2ord_adapt_oldadapt(un, dn, S,10);

err_sqr = en.^2;
    
fprintf('Total time = %.3f mins \n',toc/60);


%plot norm misalignment
% figure;         
% q = 0.99; nmis = filter((1-q),[1 -q],misalignment);
% hold on; plot((0:length(nmis)-1)/1024,10*log10(nmis), 'DisplayName', 'Wavleterra');
% axis([0 iter/1024 -60 10]);
% xlabel('Number of iterations (\times 1024 input samples)'); 
% ylabel('Normalized Misalignment (with delay)'); grid on;
% fprintf('NMIS = %.2f dB\n', mean(10*log10(nmis(end-2048:end))))




figure;         % Plot MSE
q = 0.99; MSE = filter((1-q),[1 -q],err_sqr);
hold on; plot((0:length(MSE)-1)/1024,10*log10(MSE), 'DisplayName', 'Wavleterra');
axis([0 iter/1024 -90 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)'); grid on;
fprintf('MSE = %.2f dB\n', mean(10*log10(MSE(end-2048:end))))
fprintf('NMSE = %.2f dB\n', 10*log10((dn*dn')./(en*en'))); 


%% MSAFTERRA

% Nonlinear model 
fprintf('--------------------------------------------------------------------\n');
fprintf('MSAFTERRA\n');

mu = [0.1, 0.1];                   % Step size (0<mu<2)
M = [M1, M2];                    % Length of adaptive weight vector
N = 8;                      % Number of subbands, 4
D = N/2;                    % Decimation factor for 2x oversampling
L = 8*N;                    % Length of analysis filters, M=2KN, 
                            %   overlapping factor K=4



disp(sprintf('Number of subbands, N = %d, step size = %.2f',N,mu));

S = MSAFTERRA_Init(M,mu,N,L);
tic;
[en,S] = MSAFTERRA_adapt(un,dn,S);
err_sqr = en.^2;

disp(sprintf('Total time = %.3f mins',toc/60));

q = 0.99; MSE = filter((1-q),[1 -q],err_sqr);
hold on; plot((0:length(MSE)-1)/1024,10*log10(MSE), 'DisplayName', 'MSAFterra');;
axis([0 iter/1024 -90 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)');
grid on;
fprintf('MSE = %.2f dB\n', mean(10*log10(MSE(end-2048:end))))
fprintf('ERLE = %.2f dB\n', 10*log10((dn*dn')./(en*en'))); 

%% SAFTERRA

% Nonlinear model 
fprintf('--------------------------------------------------------------------\n');
fprintf('SAFTERRA\n');

mu = [0.1, 0.1];                   % Step size (0<mu<2)
M = [M1, M2];                    % Length of adaptive weight vector
N = 8;                      % Number of subbands, 4
D = N/2;                    % Decimation factor for 2x oversampling
L = 8*N;                    % Length of analysis filters, M=2KN, 
                            %   overlapping factor K=4



disp(sprintf('Number of subbands, N = %d, step size = %.2f',N,mu));

S = SAFTERRA_Init(M,mu,N,D,L);
tic;
[en,S] = SAFTERRA_adapt(un,dn,S);
err_sqr = en.^2;

disp(sprintf('Total time = %.3f mins',toc/60));

q = 0.99; MSE = filter((1-q),[1 -q],err_sqr);
hold on; plot((0:length(MSE)-1)/1024,10*log10(MSE), 'DisplayName', 'SAFterra');;
axis([0 iter/1024 -90 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)');
grid on;
fprintf('MSE = %.2f dB\n', mean(10*log10(MSE(end-2048:end))))
fprintf('ERLE = %.2f dB\n', 10*log10((dn*dn')./(en*en'))); 


%% Fullband Volterra NLMS


fprintf('--------------------------------------------------------------------\n');
fprintf('FULLBAND NLMS\n');
mu = [0.1, 0.1];

tic;
Sfull = Volterra_NLMS_init(NL_system.M, mu); 

% [en, Sfull] = Volterra_NLMS_adapt_mfilters(un, dn, Sfull);  
[en, Sfull] = Volterra_NLMS_adapt(un, dn, Sfull);

err_sqr_full = en.^2;
    
fprintf('Total time = %.3f mins \n',toc/60);

% Plot MSE
q = 0.99; MSE_full = filter((1-q),[1 -q],err_sqr_full);
hold on; plot((0:length(MSE_full)-1)/1024,10*log10(MSE_full), 'DisplayName', 'FB NLMS');
axis([0 iter/1024 -90 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)'); grid on;
fprintf('MSE = %.2f dB\n', mean(10*log10(MSE_full(end-2048:end))))
fprintf('ERLE = %.2f dB\n', 10*log10((dn*dn')./(en*en'))); 
legend('show');



%% linear model
fprintf('--------------------------------------------------------------------\n');
fprintf('LINEAR WMSAF\n');
mu = 0.1;
level = 2;
filters = 'db2';
M = M1;
fprintf('Wavelet type: %s, levels: %d, step size = %s, filter length = %d\n', filters, level, mu, M);

tic;
Slin = SWAFinit(M, mu, level, filters); 
[en, Slin] = MWSAFadapt(un, dn, Slin); 

err_sqr_lin = en.^2;
    
fprintf('Total time = %.3f mins \n',toc/60);

% Plot MSE
q = 0.99; MSE_lin = filter((1-q),[1 -q],err_sqr_lin);
hold on; plot((0:length(MSE_lin)-1)/1024,10*log10(MSE_lin), 'DisplayName', 'LWSAF');
axis([0 iter/1024 -90 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)'); grid on;
fprintf('MSE_lin = %.2f dB\n', mean(10*log10(MSE_lin(end-2048:end))))
fprintf('ERLE = %.2f dB\n', 10*log10((dn*dn')./(en*en'))); 