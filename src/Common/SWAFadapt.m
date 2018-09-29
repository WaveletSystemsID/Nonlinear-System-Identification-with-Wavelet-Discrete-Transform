function [en,S] = SWAFadapt(un,dn,S)
% TESTING FOR 2 LEVELS, EASY EXTENSION TO GENERAL LEVEL AND WAVELET
% FUNCTIONS
% SWAFadapt         Wavelet-transformed Subband Adaptive Filter (WAF)                 
%
% Arguments:
% un                Input signal
% dn                Desired signal
% S                 Adptive filter parameters as defined in WSAFinit.m
% en                History of error signal

M = S.length;                     % Unknown system length (Equivalent adpative filter lenght)
mu = S.step;                      % Step Size
AdaptStart = S.AdaptStart;        % Transient
alpha = S.alpha;                  % Small constant (1e-6)
H = S.analysis;
F = S.synthesis;
[len, ~] = size(H);               % Wavelet filter length
level = S.levels;                 % Wavelet Levels
L = S.L;                          % Wavelet decomposition Length, sufilter length [cAn cDn cDn-1 ... cD1]

for i= 1:level
    if i == level
        w{i} = zeros(L(end-i),2);
    else
        w{i} = zeros(L(end-i),1);         % Subband adaptive filter coefficient, initialize to zeros
    end
end


u = zeros(len,1);                 % Tapped-delay line of input signal (Analysis FB)  
y = zeros(len,1);                 % Tapped-delay line of desired response (Analysis FB)
% z = zeros(len,1);                 % Tapped-delay line of error signal (Synthesis FB)

ITER = length(un);
en = zeros(1,ITER);               % Initialize error sequence to zero


% % ONLY FOR TESTING PURPOSE
% t=0:0.001:1;
% un=20*(t.^2).*(1-t).^4.*cos(12*t.*pi)+sin(2*pi*t*5000)+sin(2*pi*t*150);  

% %helping
% w{1} = zeros(128,2);
% % w{1}(1,:) = 1;

% for i= 1:level
%     U{i} = zeros(L(end-i),2);         % Tapped-delay lines of adaptive subfilters, wavelet coefficient C{1} = cA, C{2}:C{end} = cDs
% end  
% eDr = zeros(len,1);
% eD1 = zeros(len,1);
% Y1 = zeros(len,2);  
% Z = zeros(len,1);
% if level == 1
%     for n = 1:ITER
%         u = [un(n); u(1:end-1)];        % Input signal vector contains [u(n),u(n-1),...,u(n-M+1)]'
%         y = [dn(n); y(1:end-1)];        % Desired response vector 
%         if mod(n,2) == 0
%             U{1} = [u'*H; U{1}(1:end-1,:)];
%             Y = y'*H;
%             eD = Y - sum(U{1}.*w{1});
% 
%             if n >= AdaptStart
%                 w{1} = w{1} + U{1}.*(eD./(sum(U{1}.*U{1})+alpha))*mu;
%                 S.iter{1} = S.iter{1} + 1;
%             end
%             Z = F*eD' + Z;
%         end
%         en(n) = Z(1);
%         Z = [Z(2:end); 0];
%     end    
% 
%     en = en(1:ITER);
%     S.coeffs = w;
%     
% 
% elseif level == 2
% % %little help
% % w{1}(1) = 1;
% % w{2}(1,:) = 1;
%     for n = 1:ITER    
%         u = [un(n); u(1:end-1)];        % Input signal vector contains [u(n),u(n-1),...,u(n-M+1)]'
%         y = [dn(n); y(1:end-1)];        % Desired response vector        
% 
%         if mod(n,2) == 0                
%             U{1} = [u'*H; U{1}(1:end-1,:)];  % 1 level; 1st col = cA, 2nd col = cD
%             Y1 = [y'*H; Y1(1:end-1,:)];
%             eD1 =  [Y1(1,2) - U{1}(:,2)'*w{1}; eD1(1:end-1,:)];
% 
%             if n >= AdaptStart
%                  w{1} = w{1} + (mu*eD1(1)/(U{1}(:,2)'*U{1}(:,2) + alpha))*U{1}(:,2);
%                  S.iter{1} = S.iter{1} + 1;
%             end
% 
%             if mod(n,4) == 0            % 2nd level, downsample by 2*2
%                 U{2} = [U{1}(1:len)*H; U{2}(1:end-1,:)]; % 2 level; 1st col = cA2, 2nd col = cD2
%                 Y2 = Y1(1:len)*H;
%                 eD2 = Y2 - sum(U{2}.*w{2});
% 
%                 if n >= AdaptStart
%                     w{2} = w{2} + U{2}.*(eD2./(sum(U{2}.*U{2})+alpha))*mu; 
%                     S.iter{2} = S.iter{2} + 1 ;
%                 end
% 
%                 Z = F*eD2' + Z ;              % 2nd level error signal reconstuction     
%             end
%             eDr = F*[Z(1), eD1(len)]' + eDr;             %1st level error signal reconstruction
%             Z = [Z(2:end); 0];                     % Adjust delay line
%         end
%         en(n) = eDr(1);                           % Total error
%         eDr = [eDr(2:end); 0];                    % Adjust delay line
%     end     
% 
%     en = en(1:ITER);
%     S.coeffs = w;
% end    
    
% w{1} = zeros(L(end-1),2);
% w{1}(1,:) = 1;
for i = 1:level
    U.cD{i} = zeros(L(end-i),1);
    U.cA{i} = zeros(L(end-i),1);    
    Y.cD{i} = zeros(L(end-i),1);
    Y.cA{i} = zeros(L(end-i),1);
    eD{i} = zeros(L(end-i),1);
    eDr{i} = zeros(len,1);
    delays(i) = 2^i-1; 
end  
eD{i} = zeros(1,2);
U.tmp = zeros(len,1);
Y.tmp = zeros(len,1);
U.Z = zeros(2,1);
Y.Z = zeros(2,1);



for n = 1:ITER    
    u = [un(n); u(1:end-1)];        % Input signal vector contains [u(n),u(n-1),...,u(n-M+1)]'
    y = [dn(n); y(1:end-1)];        % Desired response vector        

    % Analysis Bank
    U.tmp = u;
    Y.tmp = y;
    for i = 1:level
        if mod(n,2^i) == 0
            U.Z = H'*U.tmp;
            U.cD{i} = [U.Z(2); U.cD{i}(1:end-1)]; 
            U.cA{i} = [U.Z(1); U.cA{i}(1:end-1)];
            U.tmp = U.cA{i}(1:len);
            
            Y.Z = H'*Y.tmp;
            Y.cD{i} = [Y.Z(2); Y.cD{i}(1:end-1)]; 
            Y.cA{i} = [Y.Z(1); Y.cA{i}(1:end-1)];
            Y.tmp = Y.cA{i}(1:len);
            
            if i == level
                eD{i} = Y.Z' - sum(([U.cA{i}, U.cD{i}]).*w{i});

                if n >= AdaptStart
                    w{i} = w{i} + [U.cA{i},U.cD{i}].*(eD{i}./(sum([U.cA{i},U.cD{i}].*[U.cA{i},U.cD{i}])+alpha))*mu; 
                end 
            else
                eD{i} = [Y.cD{i}(1) - U.cD{i}'*w{i}; eD{i}(1:end-1)]; 

                if n >= AdaptStart
                    w{i} = w{i} + (mu*eD{i}(1)/(U.cD{i}'*U.cD{i} + alpha))*U.cD{i};
                end
            end
                
        end
    end    


    % Synthesis Bank
    for i = level:-1:1
        if i == level
            if mod(n,2^i) == 0
                eDr{i} = F*eD{i}' + eDr{i};
            end
        else
            if mod(n,2^i) == 0                
                eDr{i} = F*[eDr{i+1}(1); eD{i}((len)*delays(end-i))] + eDr{i};
                eDr{i+1} = [eDr{i+1}(2:end); 0];
            end            
        end
    end   
    en(n) = eDr{i}(1);
    eDr{i} = [eDr{i}(2:end); 0];           
end

en = en(1:ITER);
S.coeffs = w;

end


