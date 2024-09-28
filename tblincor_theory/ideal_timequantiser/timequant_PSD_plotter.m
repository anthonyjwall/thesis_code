%% Time domain Quantiser PSD Plotting
%%  Microelectronic Circuits Centre Ireland (www.mcci.ie)
% 
%% 
% *Filename: *    PingPong_CCRO_PSD_Plot.m
%%                    
% *Written by: *  Anthony Wall
%% 
% *Created on:*  31st July 2022
% 
% *Revised on:*   -
% 
% 
% 
% *File Description:*
% 4
%  Script to plot the Power Spectral Density of the output of a time domain quantiser
%  from the output of a file generated by the ADE MATLAB Integration
%  post-processing script (timequant_vams_readout.m)
% 
% 
% 
% _* Copyright 2022 Anthony Wall*_

%% Initialisation Section

clearvars -except nch pch
global ON OFF fc T kb;

ON = 1;

OFF = 0;


fc = 0;

maxNumCompThreads(32);

set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');
set(groot, 'defaultTextInterpreter','latex');

profile on

%% Parameter Declaration

% Switches
plotRaw = 1; % Set to 1 if raw data is to be plotted, 0 if not
plotFFT = 1;

% Physical Constants
T = 300.15;
kb = physconst('Boltzmann');
q = 1.602e-19;

% Setting the FFT Parameters
Nwindows = 2;
Frac_Overlap = inf;

% Setting NBW and the frequencies within which to measure the noisefloor
NBW = 1e6;
f_NF = [100 500]*1e3;


%% Simulation time and real frequency calculations
corr_fin = 1;
Nsamp = 2^25;
%Nsamp = 262144;
T_Q = 10e-12;
DC_IN = 10e-6;
LSB_corr = 0;
LSB_corr_vec = LSB_corr

K_CCRO = 1/(2 * 0.398 * 117.25e-15);
t_dead = 210e-12;

Tsim = T_Q * (Nsamp-1);
%Tsim = 5e-6;

K_CCRO_effective = K_CCRO ./ (1 + 2.*t_dead .* K_CCRO .* DC_IN);

N_pulses = Tsim * K_CCRO_effective * DC_IN;

f_in_des = 100e3;
if corr_fin == 0
	for k = 1:length(LSB_corr_vec)
		Mcyc(k) = NearestPrime((f_in_des*T_Q) * (Nsamp/Nwindows));
		f_in_vec(k) = ones(size(LSB_corr_vec(k))) .* (Mcyc(k)/(Nsamp/Nwindows)) / T_Q;
	end
else
	for k = 1:length(LSB_corr_vec)
		Mcyc(k) = NearestPrime((f_in_des*T_Q) * ((Nsamp/Nwindows) + (N_pulses .* LSB_corr_vec(k))));
		f_in_vec(k) = Mcyc(k) / (( (Nsamp/Nwindows) + (N_pulses.*LSB_corr_vec(k))).*T_Q);
	end
end
format longeng, Tsim, f_in_vec, format shorteng


%% File Parameters
%foldername = 'posto_sims/FVFppong_wNoise_612p6mVref_12uIbias_2pCin';
foldername = 'tmp';

datadir = strcat(getenv('CDS_WORKAREA'), '/MATLAB/ADC_Modelling/timequant_readout/rawdata/', foldername, '/');

%% Simulation (meta) data readin

filenames = dir(strcat(datadir, '*.mat'));

variables = readtable(strcat(datadir, 'variables.dat'));

% Filtering input filenames to just data (removing metadata)
for k = 1:length(filenames)
	tmp = regexp(filenames(k).name, '\d+\.mat');
	if(isempty(tmp))
		filenames(k) = [];
	end
end

%metadata = load(strcat(datadir, 'metadata.mat'));

% Extracting the desired variables from the variables file
f_in = engstr_to_num(variables.f_in);
Tsim = engstr_to_num(variables.Tsim);
Iin_pk = engstr_to_num(variables.Iin_pk);
T_Q = engstr_to_num(variables.T_Q);
LSB_corr_vec = engstr_to_num(variables.LSB_corr);
%T_Q = ones(size(Iin_pk)) .* 6e-12;

%% Extracting the raw data and processing
fc = fc + 1;
for runloop = 1:length(variables.DataPoint)
	fprintf('Progress: %d/%d points\n\n', runloop, length(variables.DataPoint));

	% Extracting the raw data from the data file
	tmp = load(strcat(filenames(runloop).folder, '/', sprintf('%d', variables.DataPoint(runloop)), '.mat'));
	rawdata = tmp.simdata;

% Plotting the raw data as a sanity check
	if(plotRaw)
		figure(fc)
		clf
		hold on
		stairs(rawdata.currentTime.x, rawdata.currentTime.y, '-*')
		stairs(rawdata.currentTime_q.x, rawdata.currentTime_q.y, '-x')
		grid on
		legend('exact time', 'quantised time')
		title(sprintf('Edge times for $I_{IN}^{pk} = %.3f \\mathrm{\\mu A}$', Iin_pk(runloop)*1e6))
	
		figure(fc+1)
		clf
		plot(rawdata.period.x, rawdata.period.y, '-*', ...
		 	rawdata.period_q.x, rawdata.period_q.y, '-x')
		grid on
		legend('exact period', 'quantised period')
		title(sprintf('Edge times for $I_{IN}^{pk} = %.3f \\mathrm{\\mu A}$', Iin_pk(runloop)*1e6))
	end

% Creating a uniform time vector to fit edges to
%% Fitting the FIFO out data to a uniform T_Q time vector
	
	t_Q_vec = rawdata.currentTime.x(1):T_Q(runloop):rawdata.currentTime.x(end); % Creating the uniform time vector at T_Q sample rate
 	DFF_out_padded = zeros(size(t_Q_vec));


	tmp = round(rawdata.currentTime_q.y ./T_Q(runloop));
	edgecount = (1:length(tmp))';
	tmp = tmp - edgecount*LSB_corr;
	tmp(tmp<1) = 1;
	DFF_out_padded(tmp(2:end)+1) = 1;
	

	%% Taking the FFT of the T_Q rate sampled data
	
	% Constraining to the last Nsamp data points
	Nsamp = 2.^floor(log2(length(t_Q_vec)));
	t_Q_vec = t_Q_vec(1:(Nsamp));
	DFF_out_padded = DFF_out_padded(1:(Nsamp));
	
	% Taking the FFT
	[Pout, f{runloop}] = pwelch(DFF_out_padded, blackmanharris(Nsamp/Nwindows), Nsamp/Frac_Overlap, [], 1/T_Q(runloop), 'onesided');
	
 % Postprocessing the FFT to calculate performance metrics
    metrics{runloop} = calculateFFTMetrics(f{runloop}, Pout, f_in(runloop), NBW, f_NF);
    metrics{runloop}


    
    if(plotFFT)
       figure(fc+4)
       clf
       semilogx(metrics{runloop}.f, metrics{runloop}.Dout_f_dBc)
       grid on
       title(sprintf('PSD Plot for $I_{IN}^{pk} = %.3f~\\mathrm{\\mu A}$', 1e6*Iin_pk(runloop)))
       xlabel('Frequency (Hz)')
       ylabel('PSD $\mathrm{[A/\surd Hz]}$')
	   set(gca, 'xscale', 'log')
       
    end
    
    
   
    
 end
fc=fc+4;

%% Adding Metadata to the metrics

	% Renaming some variables for compatibility
	%variables.Iin_pk = variables.I_DC;
	% Packing into save file
    saveData.filename = foldername;
    saveData.variables = variables;
    saveData.Nwindows = Nwindows;
    saveData.Nfft = Nsamp;
    %saveData.metrics = metrics;

%% Plotting the SNDR 
for k = 1:length(metrics)
   saveData.I_DC(k) =  metrics{k}.I_DC;
   saveData.Iin_pk_fft(k) = metrics{k}.Iin_pk_fft;
   saveData.Pow_NF_dBc(k) = metrics{k}.Pow_NF_dBc;
   saveData.H2_over_H1(k) = metrics{k}.H2_over_H1;
   saveData.H3_over_H1(k) = metrics{k}.H3_over_H1;
   saveData.THD(k) = metrics{k}.THD;
   saveData.SNR(k) = metrics{k}.SNR;
   saveData.SNDR(k) = metrics{k}.SNDR;
   saveData.f{k} = metrics{k}.f(1:floor(end/16));
   saveData.Dout_f_dBc{k} = metrics{k}.Dout_f_dBc(1:floor(end/16));
   
   
   
end

PSD_SaveName = inputdlg('Enter the PSD file Save Name');
if strcmp(PSD_SaveName{1}, 'same')
    save(foldername, 'saveData')
else
    save(PSD_SaveName{1}, 'saveData')
end




fc=fc+1
figure(fc)
clf
plot(Iin_pk, saveData.SNDR, '-*', Iin_pk, saveData.SNR, Iin_pk, -saveData.THD);
grid on
legend('SNDR', 'SNR', '-THD')
xlabel('Peak Input Current ($I_{in}^{pk}$) $\mathrm{[A^{pk}]}$')
ylabel('$\mathrm{[dB]}$')
set(gca, 'Xscale', 'log')
set(gca, 'Yscale', 'linear')
set(gca, 'fontsize', 14)






profile viewer