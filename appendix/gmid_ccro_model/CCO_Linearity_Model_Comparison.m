%% Current Controlled Ring Oscillator gm/Id Model
%%  Microelectronic Circuits Centre Ireland (www.mcci.ie)


%% Initialisation Section


clearvars -EXCEPT n12rvt p12rvt n12lvt p12lvt LinData
global ON OFF s FigureCounter T kb fmin fmax FreqPoints wmax wmin w_test f;


% Load the device models if not already loaded
if(~exist('n12rvt', 'var'))
   load 65n12rvt; 
end
if(~exist('p12rvt', 'var'))
   load 65p12rvt; 
end
if(~exist('n12lvt', 'var'))
   load 65n12lvt; 
end
if(~exist('p12lvt', 'var'))
   load 65p12lvt; 
end

% Set a thread limit
maxNumCompThreads(32);

%% Parameter Declaration


% Physical Constants
T = 300.15;
kb = physconst('Boltzmann');
q = 1.602e-19;

% Input current sweep
Iin = logspace(log10(10e-9), log10(20e-6), 100);

% Device Dimensions
W_N = 500e-9;
W_P = 8000e-9 .* ones(size(Iin));
L_P = 400e-9 .* ones(size(Iin));
L_N = 60e-9 .* ones(size(Iin));

% Extrinsic load cap
C_L = 150e-15 .* ones(size(Iin)); 



for m = 1:size(Iin, 2)
        V_CNTL(m) = V_CNTL_NOSW_calc_CCO(Iin(m), 0.55, W_P(m), L_P(m), p12rvt, 1.2); % Recursively setting the V_CNTL
end


for k = 1:length(Iin) % Accounting for load cap contribution by devices
   Cgg_N(k) = 1e6.*W_N * lookup(n12rvt, 'CGG_W', 'VGS', V_CNTL(k), 'VDS', V_CNTL(k), 'L', L_N(k).*1e6, 'VSB', 0);
   Cgg_P(k) = 1e6.*W_P(k) * lookup(p12rvt, 'CGG_W', 'VGS', V_CNTL(k), 'VDS', V_CNTL(k), 'L', L_P(k).*1e6, 'VSB', 0);
   C_L(k) = C_L(k) + Cgg_P(k) + Cgg_N(k);
end


% Now taking into account varying Iss with Iin (via Va). This also takes
% into account the variation in Vth

% First find Vth - do this for each Va by finding where I_MN = I_MP
% Do this by creating a current difference function, then find the local
% minimum
%options = optimset('Display', 'iter', 'TolX', 0.1e-3);
options = optimset('TolX', 2e-3);

for k = 1:length(Iin)
Idiff_fun = @(Vth_guess) abs(W_N.*1e6 .* lookup(n12rvt, 'ID_W','VGS', Vth_guess, 'VDS', Vth_guess, 'L', L_N(1).*1e6, 'VSB', 0) - W_P(k).*1e6 .* lookup(p12rvt, 'ID_W','VGS', (V_CNTL(k)-Vth_guess), 'VDS', (V_CNTL(k)-Vth_guess), 'L', L_P(1).*1e6, 'VSB', min([1.2-V_CNTL(k) 0.6])));
Vth(k) = fminbnd(Idiff_fun, 0, 0.5, options);
end

% Calculating Iss by integrating current through the input ramp
for k = 1:length(Iin)
   Iss_avg(k) = Iss_avg_calc(Iin(k), Vth(k), V_CNTL(k), W_N, L_N(k), C_L(k), 5e-3, n12rvt);
end

Fout_ideal_NLIss = 1./(3.*C_L.*(Vth.*((1./Iin)-(1./Iss_avg)) + V_CNTL .* (1./Iss_avg))); % All that's left is to fill it into the nonlinear formula



