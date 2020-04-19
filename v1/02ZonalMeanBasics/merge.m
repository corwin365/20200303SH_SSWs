clearvars


%merge together data from different runs of the compute-r
OutFile = 'merged_zm.mat';


%first file - AIRS 
%this has six entries in, so will form the ur-template
A = load('zm_data_A.mat');
a = A.Settings.LatRange; A.Settings = rmfield(A.Settings,'LatRange');
A.Settings.LatRange{6} = a; clear a




%second file - ERA5 U and T
B = load('zm_data.mat');
A.Results.Data(1,:,:) = B.Results.Data(1,:,:);
A.Results.Data(2,:,:) = B.Results.Data(2,:,:);

A.Settings.Vars{1} = B.Settings.Vars{1};
A.Settings.Vars{2} = B.Settings.Vars{2};

A.Settings.LatRange{1} = B.Settings.LatRange;
A.Settings.LatRange{2} = B.Settings.LatRange;

clear B




%third file - SABER T
C = load('zm_data_S.mat');
A.Results.Data(3,:,:) = C.Results.Data(1,:,:);

A.Settings.Vars{3} = C.Settings.Vars{1};

A.Settings.LatRange{3} = C.Settings.LatRange;


clear C

%fourth file - MLS T and O3
D = load('zm_data_M.mat');
A.Results.Data(4,:,:) = D.Results.Data(1,:,:);
A.Results.Data(5,:,:) = D.Results.Data(2,:,:);
A.Settings.Vars{4} = D.Settings.Vars{1};
A.Settings.Vars{5} = D.Settings.Vars{2};
A.Settings.LatRange{4} = D.Settings.LatRange;
A.Settings.LatRange{5} = D.Settings.LatRange;



% % %fifth file - fixed airs 
% % E = load('zm_data_A_v2.mat');
% % A.Results.Data(6,:,:)  = E.Results.Data(1,:,:);
% % A.Settings.Vars{6}     = E.Settings.Vars{1};
% % A.Settings.LatRange{6} = E.Settings.LatRange;
% % 




Results  = A.Results;
Settings = A.Settings;
save(OutFile,'Results','Settings')