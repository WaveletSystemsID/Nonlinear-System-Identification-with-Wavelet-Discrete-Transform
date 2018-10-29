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


%% Random Vector 
rng('default'); % For reproducibility


%% Simulated Kernel - random
ker1 = rand(M1,1)-rand(1);
ker2 = second_order_kernel(M2);

% Non-linear System 
NL_system.Responses = {gains(1).*ker1, gains(2).*ker2};


%% Plot 2-D kernel
kernel_plot(NL_system.Responses);



%% Adaptive filter parameters

% GENERAL FOR ALL MODELS: 

mu = [0.1, 0.1];            %Step sizes for different kernels 

% Run parameters
iter = 1*80000;            % Number of iterations



% for WAVTERRA (WAVELET VOLTERRA ADAPTIVE FILTER)
level = 1;                  % Levels of Wavelet decomposition for different kernels
filters = 'db1';            % Set wavelet type for different kernels

%%
% FOR MSAFTERRA AND SAFTERRA: 

M = [M1, M2];                    % Length of adaptive weight vector
if level ==1 
    N = 2;                       % Number of subbands
else 
    N = level^2;
end
                      
D = N/2;                    % Decimation factor for 2x oversampling
L = 8*N;                    % Length of analysis filters, M=2KN, 

%% plot parameters
nmse_n_points = 1000; 


%%
% CREATE DESIRED RESPONSE 

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
fprintf('Total time = %.3f mins \n',toc/60);
err_sqr = en.^2;
    
% create figure handler for MSE

MSE_fig = figure(2);         

% plot MSE
q = 0.99; MSE = filter((1-q),[1 -q],err_sqr);

%MSE 
figure(MSE_fig); 
plot((0:length(MSE)-1)/1024,10*log10(MSE),'DisplayName', 'Wavleterra');
axis([0 iter/1024 -120 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)'); grid on;
fprintf('MSE = %.2f dB\n', mean(10*log10(MSE(end-2048:end))))


%create figure handler for NMSE
NMSE_fig = figure(3); 

%NMSE
figure(NMSE_fig); 
[NMSE, indx] = NMSE_compute(dn, en, nmse_n_points);
plot(indx, NMSE,'DisplayName', 'Wavleterra');
axis([indx(1) indx(end) -50 10]);
xlabel('Iteration number'); 
ylabel('NMSE'); grid on;
fprintf('NMSE = %.2f dB\n', NMSE(end))



%% MSAFTERRA
% Nonlinear model fehprintf('--------------------------------------------------------------------\n');
fprintf('MSAFTERRA\n');

disp(sprintf('Number of subbands, N = %d, step size = %.2f',N,mu));

S = MSAFTERRA_Init(M,mu,N,L);
tic;
[en,S] = MSAFTERRA_adapt(un,dn,S);
disp(sprintf('Total time = %.3f mins',toc/60));
err_sqr = en.^2;

%MSE
figure(MSE_fig); 
hold on; 
plot((0:length(MSE)-1)/1024,10*log10(MSE),'DisplayName', 'MSAFTERRA');
axis([0 iter/1024 -120 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)'); grid on;
fprintf('MSE = %.2f dB\n', mean(10*log10(MSE(end-2048:end))))

% NMSE
figure(NMSE_fig); 
hold on; 
[NMSE, indx] = NMSE_compute(dn, en, nmse_n_points);
plot(indx, NMSE,'DisplayName', 'MSAFTERRA');
axis([indx(1) indx(end) -50 10]);
xlabel('Iteration number'); 
ylabel('NMSE'); grid on;
fprintf('NMSE = %.2f dB\n', NMSE(end))

%% SAFTERRA

% Nonlinear model 
fprintf('--------------------------------------------------------------------\n');
fprintf('SAFTERRA\n');
disp(sprintf('Number of subbands, N = %d, step size = %.2f',N,mu));

S = SAFTERRA_Init(M,mu,N,D,L);
tic;
[en,S] = SAFTERRA_adapt(un,dn,S);
disp(sprintf('Total time = %.3f mins',toc/60));
err_sqr = en.^2;

% MSE 
figure(MSE_fig);  
hold on; 
plot((0:length(MSE)-1)/1024,10*log10(MSE),'DisplayName', 'SAFTERRA');
axis([0 iter/1024 -120 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)'); grid on;
fprintf('MSE = %.2f dB\n', mean(10*log10(MSE(end-2048:end))))


% NMSE
figure(NMSE_fig); 
hold on; 
[NMSE, indx] = NMSE_compute(dn, en, nmse_n_points);
plot(indx, NMSE,'DisplayName', 'SAFTERRA');
axis([indx(1) indx(end) -50 10]);
xlabel('Iteration number'); 
ylabel('NMSE'); grid on;
fprintf('NMSE = %.2f dB\n', NMSE(end))


%% Fullband Volterra NLMS


fprintf('--------------------------------------------------------------------\n');
fprintf('FULLBAND NLMS\n');
mu = [0.1, 0.1];

tic;
Sfull = Volterra_NLMS_init(NL_system.M, mu); 
[en, Sfull] = Volterra_NLMS_adapt(un, dn, Sfull);
fprintf('Total time = %.3f mins \n',toc/60);
err_sqr_full = en.^2;

%MSE
figure(MSE_fig);  
hold on; 
plot((0:length(MSE)-1)/1024,10*log10(MSE),'DisplayName', 'FBAND');
axis([0 iter/1024 -120 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)'); grid on;
fprintf('MSE = %.2f dB\n', mean(10*log10(MSE(end-2048:end))))

%NMSE
figure(NMSE_fig); 
hold on; 
[NMSE, indx] = NMSE_compute(dn, en, nmse_n_points);
plot(indx, NMSE,'DisplayName', 'FBAND');
axis([indx(1) indx(end) -50 10]);
xlabel('Iteration number'); 
ylabel('NMSE'); grid on;
fprintf('NMSE = %.2f dB\n', NMSE(end))


%% linear model
fprintf('--------------------------------------------------------------------\n');
fprintf('LINEAR WMSAF\n');
fprintf('Wavelet type: %s, levels: %d, step size = %s, filter length = %d\n', filters, level, mu(1), M(1));

tic;
Slin = SWAFinit(M(1), mu(1), level, filters); 
[en, Slin] = MWSAFadapt(un, dn, Slin); 
fprintf('Total time = %.3f mins \n',toc/60);
err_sqr_lin = en.^2;

%MSE
figure(MSE_fig);  
hold on; 
plot( (0:length(MSE)-1)/1024,10*log10(MSE),'DisplayName', 'WMSAFLIN');
axis([0 iter/1024 -120 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)'); grid on;
fprintf('MSE = %.2f dB\n', mean(10*log10(MSE(end-2048:end))))
legend('show');

%NMSE
figure(NMSE_fig); 
hold on; 
[NMSE, indx] = NMSE_compute(dn, en, nmse_n_points);
plot(indx, NMSE,'DisplayName', 'WMSAFLIN');
axis([indx(1) indx(end) -50 10]);
xlabel('Iteration number'); 
ylabel('NMSE'); grid on;
fprintf('NMSE = %.2f dB\n', NMSE(end))
legend('show');
