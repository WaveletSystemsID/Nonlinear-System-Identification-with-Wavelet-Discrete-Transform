%% DISCRETE WAVELET DECOMPOSITION TESTING

% Testing Signal
clear all; close all

d = 256;        %Total signal length
t=0:0.001:10;
f=20*(t.^2).*(1-t).^4.*cos(12*t.*pi)+sin(2*pi*t*5000)+sin(2*pi*t*150);
f = f(1:d)';
% f=f(1:256);
%f = [1; -10; 324; 48; -483; 4; 7; -5532; 34; 8889; -57; 54];
%d=length(f);

% d = 512;
% f = load('h1.dat');         % Unknown system (select h1 or h2)
% f = f(1:d);                 % Truncate to length M

% f = zeros(d, 1);
% f(129) = 1;

wtype = 'db2';
level = 2;
wdt_mod = 'zpd';

%% Generazione dei coefficienti del filtro
[low_d,high_d,low_r,high_r] = wfilters(wtype);
W = WaveletMat_nL(d, level, low_d, high_d); % DWT transform matrix
H = [low_d', high_d'];  % filter matrix analysis
F = [low_r', high_r'];  % filter matrix synthesis
[len, ~] = size(H);     % wavelet filter length

%% Decomposizone con funzione matlab
dwtmode(wdt_mod)
tic
[C, L] = wavedec(f, level, wtype);
fr = waverec(C, L, wtype);
toc
D = detcoef(C,L,'cells');
A = appcoef(C, L, wtype);
errC = max(abs(f-fr))

%% Decomposizione con Matrice W
% tic
% if (wdt_mod == 'per') %padding mode, if per cA and cA has minumum length
%     Z = W*f;
%     Zr = W'*Z;  
%     toc
%     errZ = max(abs(f-Zr))    
%     
%     % Decompose approximation and detail coefficient
%     for dval=1:level 
%         zD{dval} = Z((d/(2^(dval)))+1:(d/(2^(dval-1)))); 
%         if (dval == level) % only last level for cA
%             zA{dval} = Z(1:(d/(2^(dval)))); 
%         end   
%     end
% else
%     % Zeropads the matrix border
%     % PROBLEM: proper filling of the matrix, dont introduce useless delays
%     padsize = len/2-1;
%     W_pad = padarray(W, [padsize padsize], 'both');
%     % W_pad = [zeros(d,1), W, zeros(256,1)];
%     % W_pad = [zeros(d+2,1)'; W_pad];
%     % W_pad = [W_pad(1:d/2,:); zeros(d+2,1)'; W_pad(d/2+1:end,:)]; %this works as matlab function
%     f_pad = padarray(f, padsize, 'both');
% 
%     Z = W_pad*f_pad;
%     Zr = W_pad'*Z;
%     toc
%     
%     Zr = Zr(1+padsize:end-padsize);
%     errZ = max(abs(f-Zr))
%     
%     % Decompose approximation and detail coefficient
%     % Works ok for 1 level, for 2 level still have to manage the padding.
%     lf = length(low_d);
%     LL = [d; zeros(level,1)];  %ERROR, cumsum LL instead d. Must be the proper dimension of Z
%     for i= 1:level
%         LL = [floor((LL(1)+lf-1)/2); LL(1:end-1)];
%     end
%     LL = [LL(1); LL]';
% % 
% %     % Z = [cA||cD||...||cD]
% %     zA = Z(1:L(1));
% %     index = cumsum(L(1:end-1));
% %     for i=1:level
% %         zD{i} = Z(index(i)+1:index(i+1));
% %     end
% end
% 
% if length(Z) == length(C)
%     diff_ZC = max(abs(C-Z)) %diff from C and Z
% else    
%     fprintf(['-------------------------------------------\n',...
%         'WARNING: C and Z have different length \n',...
%         '-------------------------------------------\n']);
% end
% 
% % %Plotting difference Matlab DWT and W-Matrix DWT
% % stem([Z, C]); legend('Z','MatLab');
% % title('Z-C'); grid on;

%% Decomposizione manuale
% % Analysis
% [McA,McD] = dwt(f,low_d,high_d);       %level 1
% [McA2,McD2] = dwt(McA,low_d,high_d);   %level 2
% 
% % Synthesis
% McR2 = idwt(McA2,McD2,low_r,high_r);
% McR = idwt(McR2,McD,low_r,high_r);
% err0 = max(abs(f-McR))

% %% Border Effect 
% lx = length(f); lf = length(low_d);
% % ex = [randn(1,lf) f' randn(1,lf)];
% ex = [zeros(1,lf) f' zeros(1,lf)];
% % dwtmode('zpd')
% 
% % Decomposition.
% la = floor((lx+lf-1)/2);
% ar = wkeep(dyaddown(conv(ex,low_d)),la);
% dr = wkeep(dyaddown(conv(ex,high_d)),la);
% % Reconstruction.
% xr = idwt(ar,dr,wtype,lx); %central portion
% 
% % Check perfect reconstruction.
% err1 = max(abs(f'-xr))

%% Real time DWT 1 level (PERFETCT as mode zpd)
% if level == 1
% tic
% delay = length(H)-1;            %total delay (analysis + synthesis)
% x = zeros(length(H),1);
% b = zeros(length(F),1);
% yn = zeros(d+delay, 1);
% fpad = [f; zeros(delay, 1)];
% 
% % Decompose approximation and detail coefficient
% lf = length(low_d);
% LL = [d; zeros(level,1)];  %ERROR, cumsum LL instead d. Must be the proper dimension of Z
% for i= 1:level
%     LL = [floor((LL(1)+lf-1)/2); LL(1:end-1)];
% end
% LL = [LL(1); LL]';
% % LL(end) = sum(LL(1:end-1));
% 
% cD = zeros(LL(2), 1);
% cA = zeros(LL(1), 1);
% 
% for n = 1:d+delay
%     x = [fpad(n); x(1:end-1)];
%     if mod(n,2) == 0
%         xD = x'*H;
%         cD = [cD(2:end); xD(2)];
%         cA = [cA(2:end); xD(1)];
%         b = F*xD' + b;
%     end
%     yn(n) = b(1);
%     b = [b(2:end); 0];
% end
% toc
% err2 = max(abs(f-yn(1+delay:end)))
% errC = max(abs(C-[cA; cD]))
% end

%% Plotting Stuff
% figure; 
% subplot(3,1,1);
% plot(f); title('Original'); axis([1 d -inf inf]);
% subplot(3,1,2);
% plot([zD{1}, D{1}, cD]); axis([1 d/2 -inf inf]);
% title('cD'); legend('Matrix W', 'MATLAB', 'Real-Time'); grid on;
% subplot(3,1,3);
% plot([zA{1}, A, cA]); axis([1 d/2 -inf inf]);
% title('cA'); legend('Matrix W', 'MATLAB', 'Real-Time'); grid on;

%% Real time DWT 2level
% % PROBLEMS: with delay!!!
% if level == 2
% tic
% delay = level*length(H)-1;            %total delay (analysis + synthesis)
% lf = length(H)-1;
% x = zeros(length(H),1);
% b = zeros(length(F),1);
% bb = zeros(length(F),1);
% yn = zeros(d+delay, 1);
% fpad = [f; zeros(delay, 1)];
% 
% % Decompose approximation and detail coefficient
% ld = length(low_d);
% LL = [d; zeros(level,1)];  %ERROR, cumsum LL instead d. Must be the proper dimension of Z
% for i= 1:level
%     LL = [floor((LL(1)+ld-1)/2); LL(1:end-1)];
% end
% LL = [LL(1); LL]';
% 
% cD = zeros(LL(3), 1);
% cA = zeros(LL(3), 1);
% cD2 = zeros(LL(2), 1);
% cA2 = zeros(LL(1), 1);
% 
% for n = 1:d+delay
%     x = [fpad(n); x(1:end-1)];
%     if mod(n,2) == 0
%         xD = x'*H;
%         cD = [cD(2:end); xD(2)]; %problem here, last shift not needeed
%         cA = [cA(2:end); xD(1)];
%         if mod(n,4) == 0
%             xDD = [cA(end:-1:end-lf)]'*H;
%             cD2 = [cD2(2:end); xDD(2)];
%             cA2 = [cA2(2:end); xDD(1)];
%             bb = F*xDD' + bb;
%         end
%     b = F*[bb(1), cD(end-lf)]' + b;
%     bb = [bb(2:end); 0];
%     end
%     yn(n) = b(1);
%     b = [b(2:end); 0];
% end
% toc
% err2lv = max(abs(f-yn(1+delay:end)))
% end

%% Real time DWT, generic YEEEE
tic
delay = level*length(H)-1;            %total delay (analysis + synthesis)
lf = length(H)-1;
x = zeros(length(H),1);
xDD = x;
yn = zeros(d+delay, 1);
fpad = [f; zeros(delay, 1)];

% Decompose approximation and detail coefficient
ld = length(low_d);
LL = [d; zeros(level,1)]; 
for i= 1:level
    LL = [floor((LL(1)+ld-1)/2); LL(1:end-1)];
end
LL = [LL(1); LL]';


for i = 1:level
    cD{i} = zeros(LL(end-i),1);
    cA{i} = zeros(LL(end-i),1);
    bb{i} = zeros(length(F),1);    
    delays(i) = 2^i-1; 
end    
xD = zeros(2,1);


for n = 1:d+delay
    x = [fpad(n); x(1:end-1)];
    
    tmp = x;
    for i = 1:level
        if mod(n,2^i) == 0
            xD = H'*tmp;
            cD{i} = [cD{i}(2:end); xD(2)]; 
            cA{i} = [cA{i}(2:end); xD(1)];
            tmp = cA{i}(end:-1:end-lf);
        end
    end
%     % Analysis
%     for i=1:level
%         if i == 1 %init
%             if mod(n,2) == 0
%                 xD{i} = H'*x;
%                 cD{i} = [cD{i}(2:end); xD{i}(2)]; 
%                 cA{i} = [cA{i}(2:end); xD{i}(1)];
%             end
%         elseif i == level %last level, compute both cD and cA
%             if mod(n,2^i) == 0
%                 xD{i} = H'*[cA{i-1}(end:-1:end-lf)];
%                 cD{i} = [cD{i}(2:end); xD{i}(2)]; 
%                 cA{i} = [cA{i}(2:end); xD{i}(1)];
%             end
%         else % do middle levels
%             if mod(n,2^i) == 0
%                 xD{i} = H'*[cA{i-1}(end:-1:end-lf)];
%                 cD{i} = [cD{i}(2:end); xD{i}(2)]; 
%                 cA{i} = [cA{i}(2:end); xD{i}(1)];
%             end
%         end
%     end
    

    %Synthesis
    for i = level:-1:1
        if i == level
            if mod(n,2^i) == 0
                bb{i} = F*xD + bb{i};
            end
        else
            if mod(n,2^i) == 0                
                bb{i} = F*[bb{i+1}(1); cD{i}(end-lf*delays(end-i))] + bb{i};
                bb{i+1} = [bb{i+1}(2:end); 0];
            end            
        end
    end   
    yn(n) = bb{i}(1);
    bb{i} = [bb{i}(2:end); 0];               
    
end
toc
err2lv = max(abs(f-yn(1+delay:end)))    %problem with delays. This works fine 
                                        %but reconstructed signal is shifted for some reason
