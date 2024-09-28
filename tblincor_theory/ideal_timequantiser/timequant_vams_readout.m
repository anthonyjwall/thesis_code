function result = timequant_vams_readout()

	import cadence.Query.*
	%import cadence.srrdata.*

	adeInfo = cadence.AdeInfoManager.getInstance();
	adeInfo.loadResult();

	rdb =  adeInfo.adeRDB;

% 	simdata.currentTime = cadence.srrdata.getData(...
% 		'cyborg65r2_tb_FVFpingpong.I_TQ.currentTime', ...
% 		'result', 'tran');	
% 
% 	simdata.currentTime_q = cadence.srrdata.getData(...
% 		'cyborg65r2_tb_FVFpingpong.I_TQ.currentTime_q', ...
% 		'result', 'tran');	
% 	
% 	simdata.period = cadence.srrdata.getData(...
% 		'cyborg65r2_tb_FVFpingpong.I_TQ.period', ...
% 		'result', 'tran');
% 
% 	simdata.period_q = cadence.srrdata.getData(...
% 		'cyborg65r2_tb_FVFpingpong.I_TQ.period_q', ...
% 		'result', 'tran');

	simdata.currentTime = cadence.srrdata.getData(...
		'cyborg65r2_pingpong_CCRO_tb.I_TQ.currentTime', ...
		'result', 'tran');	

	simdata.currentTime_q = cadence.srrdata.getData(...
		'cyborg65r2_pingpong_CCRO_tb.I_TQ.currentTime_q', ...
		'result', 'tran');	
	
	simdata.period = cadence.srrdata.getData(...
		'cyborg65r2_pingpong_CCRO_tb.I_TQ.period', ...
		'result', 'tran');

	simdata.period_q = cadence.srrdata.getData(...
		'cyborg65r2_pingpong_CCRO_tb.I_TQ.period_q', ...
		'result', 'tran');

	%simdata.I_IN = cds_srr(adeInfo.adeCurrentResultsPath, 'tran-tran', 'cyborg65_anthony_pingpong_cco_timequant_ideal.I_CCRO.CNTL_$flow');




 	
 	filepath = strcat(getenv('CDS_WORKAREA'), '/MATLAB/ADE_Functions/output_files/timequant_vams_readout/');

	if adeInfo.adeDataPoint == 1
		vars = rdb.paramConditions;
		varfilename = strcat(filepath, 'variables.dat');
		writetable(vars, varfilename);
	
		metafilename = strcat(filepath, 'metadata.mat');
		save(metafilename, "adeInfo");
	end
 
 	filename = sprintf('%d', adeInfo.adeDataPoint);
 	%filename = sprintf('%e', rdb.query('constraint', Output=='filename').Result);

 
  	filepath = strcat(filepath, filename, '.mat');
	save(filepath, 'simdata')
%  	filedata = [Phi_OUT_0.x, Phi_OUT_0.y Phi_OUT_1.x Phi_OUT_1.y];
%  	
%  	writematrix(filedata, filepath, 'delimiter', ',');

	result = 'success!';

end
