function V_CNTL = V_CNTL_NOSW_calc_CCO(Iin_CCO, Vds_scaler, W_P, L, pch, Vb)
 
 % Take into account the input current dependancy of Va
% While keeping Iss constant 
Jd_P = Iin_CCO./(W_P*1e6);

% Setting initial guesses for Va
V_CNTL = 0.55*ones(size(Iin_CCO));

for k=1:5
	if(isnan(V_CNTL))
        V_CNTL = 1; % If there's an issue, set V_CNTL = 1 for a sensible retry
	end
		% V_CNTL  = VGS_MP, for a given bias current and VDS. VS must be
		% recursively honed.
        V_CNTL = lookupVGS(pch, 'ID_W', Jd_P, 'Vds', Vds_scaler*V_CNTL, 'L', L.*1e6, 'VSB', min([Vb-V_CNTL 0.6])); 
end

    
end