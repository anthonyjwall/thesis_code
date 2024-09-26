function [Sim] = FrequencyCounter_Lin(Sim)
% Sim is a struct containing at least the following:
% Sim.Vout: Array of Time Outputs
% Sim.t: Array of sample times
% At the end of the function, Sim will be repacked with the following data
% appended:
% Sim.Tper: The First Difference of the edge times, the period of each
% sample
% Sim.f: The frequency of each sample period f=1./Tper
% Sim.Tper_avg: Average Frequency of the whole dataset
%Sim.f_avg: Average Frequency. f_avg=1./Tper_avg
% Sim.cycles: The number of edges counted in the data
%Sim.dV: The maximum voltage swing of the data in the inner two quartiles (in time)
%of the data

% Removing the zero padding from the end of the waveform
for k=1:size(Sim.Vout, 2)
    ind = Sim.t{k}(:)~=0; % Finding the indices where time is zero (indicating padding)
    tmp{k} = Sim.Vout{k}(ind(2:end)); % 2:end because t(1) = zero, the sim start time
    tmp2{k} = Sim.t{k}(ind(2:end));
end
Sim.Vout=tmp;
Sim.t=tmp2;



for k=1:size(Sim.Vout, 2)  
    % Finding the Midpoint Threshold Voltage of the Output Voltage
    Vmax{k} = max(Sim.Vout{k}(floor(0.75*end):end));
    Vmin{k} = min(Sim.Vout{k}(floor(0.75*end):end));
    dV{k} = Vmax{k}-Vmin{k};
    Vth{k} = Vmin{k}+ 0.5*(dV{k});
    


    % Finding Vout samples below Vth
    Ind_LessVth{k} = (Sim.Vout{k}<Vth{k});
 
    % Finding Samples crossing the Threshold
    Ind_Cross{k} = diff(Ind_LessVth{k});

    % Constraining to just Falling Edges
    Ind_Cross{k} = (Ind_Cross{k} == 1);
    
    % Constraining to just Rising Edges
    %Ind_Cross{k} = (Ind_Cross{k} == 1);
    
    % Getting the Index
    Ind_Cross{k} = find(Ind_Cross{k});
    Ind_Cross{k} = Ind_Cross{k}(Ind_Cross{k}~=1);
    
    
    % Finding Crossing Times
    t_edge{k} = 0.5*(Sim.t{k}(Ind_Cross{k}) + Sim.t{k}(Ind_Cross{k}-1));
    
    % Removing the first 25% Edges to remove startup effects
    %t_edge{k} = t_edge{k}(10:end);
    t_edge{k} = t_edge{k}(max(floor(0.25*end),1):end);
    
    % Taking the First Difference to extract each Period
    Tper{k} = diff(t_edge{k});
    
    %Inverting for frequency of each cycle
    f{k} = 1./Tper{k};
    
    %Counting the number of cycles
     cycles(k) = length(Tper{k});
    
    % Extracting the Average Period and Average Frequency
    Tper_avg(k) = mean(Tper{k}, 'omitnan');

end

f_avg = 1./Tper_avg;

%figure
%plot(Sim.t(:,2), Sim.Vout(:,2),'.', t_edge{2}, Vth(2)*ones(length(t_edge{2})),'*');
%grid on

Sim.t_edge = t_edge;
Sim.Tper = Tper;
Sim.f = f;
Sim.Tper_avg = Tper_avg;
Sim.f_avg = f_avg;
Sim.cycles=cycles;
Sim.dV = dV;
Sim.Vth = Vth;
end