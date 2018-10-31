% WAVTERRA_demo      TestBench script for Nonlinear System Identification
%                       with Wavelet Transform Subband Adaptive Filters
%
%   This script runs the WAVTERRA structure and compares its results with
%   the conventional NLMS FullBand Adaptive filter
%
% by A. Castellani & S. Cornell [Universit� Politecnica delle Marche]

diary log_WAVTERRA_TB.txt                 % Log files, all the Command Window (no figures)

fprintf('%s \n', datestr(datetime('now')));

addpath(genpath('../Common'));             % Functions in Common folder
addpath('DFT_bank Volterra'); 
addpath('../MWSAF'); 
clear all;  
close all;

%% Hyperparameters
% Kernel Hyperpar
order = 2;                      % Order of volterra filter (just 2 atm)
M1 = 256;                       % length of first order volterra kernel
M2 = 32;                        % length of second order volterra kernel
gains = [1 1];                  % Kernel gains

% Signal Hyperpar

speech = 1;                     % Choose either 1 or 0, for using speech sample or noise 
speech_sample = 'speech_harvard_m.mat'; 


AR = 4;                         % AutoRegressive filter for white noise shaping, choose either 1 to 4, 1 is white noise
iter = 0.1*80000;                 % Number of iterations, NON speech
SNR = 40;

% Structure Hyperpar            (This can be modified to allow comparison)

runs = 4;                       % Number of runs for different wtype or levels
par_level = [3];
par_filters = 'db1';

par_C = M2;                     % Channels, #diagonal of kernel (max: M2)
par_SB = 1:2^par_level(end);    % Nonlinear subband (max: 1:2^level)

mu = [0.1, 0.1];                % Stepsize for different kernels 


% Create combination
runs = length(par_level)*length(par_filters);
par_comb = combvec(1:length(par_level), 1:length(par_filters));

%% Create and plot kernel
% Create Kernel mode

kermode = 'simulated';     %modes: "delta", "randomdiag", "random", "lowpass", "simulated"


% Create Kernel parameters
deltapos = [5, 3];
Ndiag = 5;
normfreq = [0.6, 0.2];
h1h2 = ["h1.dat", "h2.dat"];
param = {deltapos, Ndiag, normfreq, h1h2};

[ker1, ker2] = create_kernel(M1, M2, kermode, param);

NL_system.M = [M1, M2];
NL_system.Responses = {gains(1).*ker1, gains(2).*ker2};

% Plotting kernel
kernel_plot(NL_system.Responses);

%% Create Signals
disp('Creating desired and input signals. . .');
if speech == 1
    fprintf('Kernel Memory: [%d, %d], Input signal: (%s) \n', M1, M2, speech_sample);
    [un,dn,vn] = GenerateResponses_speech_Volterra(NL_system, speech_sample);
    figure('Name', 'SpeechSpectrum');
    spectrogram(un, 1024, 256, 1024, 'yaxis');
else
    fprintf('Kernel Memory: [%d, %d], Input signal: noise colored wtih AR(%d)\n', M1, M2, AR);
    [un,dn,vn] = GenerateResponses_Volterra(iter, NL_system ,sum(100*clock),AR,SNR); %iter, b, seed, ARtype, SNR
    powerspec_plot(AR, iter);
end
fprintf('\n');


% figures handlers
MSEfig = figure('Name', 'MSE');
NMSEfig = figure('Name', 'NMSE');

%% WAVTERRA
fprintf('WAVTERRA\n');
for i = 1:runs  
    fprintf('--------------------------------------------------------------------\n'); 
    level = par_level(par_comb(1,i));
    filters = par_filters{par_comb(2,i)};
    SB = 1:2^level;
    C = par_C;
    
    fprintf('Running iter (%d) of (%d), level = %d , wtype = %s\n', i, runs, level, filters);           
    fprintf('step size = %s \n', sprintf('%.2f ', mu));

    tic;
    S = Volterra_Init(NL_system.M, mu, level, filters); 
    [en, S] = Volterra_2ord_adapt_v3(un, dn, S, C, SB);
 
    err_sqr = en.^2;
    er_len = length(err_sqr);

    fprintf('Total time = %.2f s \n',toc);

    % Plot MSE       
    figure(MSEfig);
    if speech == 1
        subplot(4, 1, 1:3);
    end
    q = 0.99; MSE = filter((1-q),[1 -q],err_sqr);
    hold on; plot((0:er_len-1)/1024,10*log10(MSE), 'DisplayName', ['WAVTERRA - Level:' ,num2str(level), ' ', filters]);
    
    NMSE(i) = 10*log10(sum(err_sqr)/sum(dn.^2));
    fprintf('NMSE = %.2f dB\n', NMSE(i));
    
    % Plot NMSE
    figure(NMSEfig);
    hold on; plot((0:er_len-1)/1024, 10*log10(cumsum(err_sqr)./(cumsum(dn.^2))), 'DisplayName', ['WAVTERRA - Level:' ,num2str(level), ' ', filters] );
            
    fprintf('\n');
end

%% FULLBAND VOLTERRA
fprintf('FULLBAND VOLTERRA NLMS\n');
fprintf('-------------------------------------------------------------\n');

Sfull = Volterra_NLMS_init(NL_system.M, mu); 

tic;
[en, Sfull] = Volterra_NLMS_adapt(un, dn, Sfull);     

err_sqr_full = en.^2;
    
fprintf('Total time = %.2f s \n',toc);

% Plot MSE
figure(MSEfig);
q = 0.99; MSE_full = filter((1-q),[1 -q],err_sqr_full);
plot((0:length(MSE_full)-1)/1024,10*log10(MSE_full), 'DisplayName', 'FB NLMS');

NMSE_FB = 10*log10(sum(err_sqr_full(256:end))/sum(dn(256:end).^2));
fprintf('NMSE = %.2f dB\n', NMSE_FB);

figure(NMSEfig);
hold on; plot((0:er_len-1)/1024, 10*log10(cumsum(err_sqr_full)./(cumsum(dn.^2))), 'DisplayName', 'FB NLMS');
axis([0 er_len/1024 -60 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Normalized Mean-square error'); grid on;

%% Adding title and labels to plots
figure(MSEfig);
ylabel('Mean-square error'); grid on;
legend('show');
if speech == 1
    axis([0 er_len/1024 -120 inf]);
    subplot(4,1,4)
    plot((0:er_len-1)/1024, un, 'DisplayName', 'un');   
    axis([0 er_len/1024 -inf inf]);
    ylabel('Amplitude'); grid on;
else
    axis([0 er_len/1024 -60 10]);
end
xlabel('Number of iterations (\times 1024 input samples)');


figure(NMSEfig);
axis([0 er_len/1024 -20 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Normalized Mean-square error'); grid on;
legend('show');


fprintf('\n');  % Empty line in logfile

diary off
