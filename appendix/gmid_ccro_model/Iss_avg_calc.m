function Iss_avg = Iss_avg_calc(Iin, Vth, V_CNTL, W_N, L, C_L, Vstep, nch)
 
    Vin = Vth;
    Vout = V_CNTL;
    dVin = Iin./C_L; % This is the slope of the input ramp
    
    Iter = 0;
    Ttotal = 0;
    
    if(sum(isnan([Vin Vout]))) % If either value is nan, the current should be nan
        Iss_avg(k) = NaN;
    else
        while Vout >  Vth % while we're still above V_TH, keep discharging
           Iter = Iter + 1;
           Iss = W_N * 1e6 * lookup(nch, 'ID_W', 'VGS', Vin, 'VDS', Vout, 'L', L*1e6, 'VSB', 0); % Calculate the instantaneous current
           dt  = min((C_L.*Vstep./Iss), (Vstep./dVin)); % This is the timestep that results in a Vstep output or input change
           Vout = Vout - (Iss.*dt./C_L); % Regressively calculating the new output
           Vin = Vin + dt.*dVin;   % Update the input voltage

           Ttotal = Ttotal + dt;
        end
        Iss_avg = C_L .* (V_CNTL - Vout)./Ttotal;



end