clearvars


%merge together data from different runs of the compute-r
OutFile = 'data/merged_zm_gws.mat';

%we want:
%1. AIRS Mz
%2. AIRS T'
%3. MLS MF
%4. MLS T'
%5. SABER MF


%first file - AIRS 
%this has six entries in, so will form the ur-template
A = load('data/zm_data_gws_A_polar.mat');
Results.Data = A.Results.Data([4,1],:,:);

Settings = A.Settings; Settings = rmfield(Settings,{'Vars','LatRange'});

a = A.Settings.LatRange; A.Settings = rmfield(A.Settings,'LatRange');
Settings.LatRange{1} = a;
Settings.LatRange{2} = a;
Settings.Vars{1} = A.Settings.Vars{4}; 
Settings.Vars{2} = A.Settings.Vars{1}; 


clear a A


%second file - MLS
B = load('data/zm_data_gws_M_polar.mat');
Results.Data(3,:,:) = B.Results.Data(1,:,:);
Results.Data(4,:,:) = B.Results.Data(4,:,:);

Settings.Vars{3} = B.Settings.Vars{1};
Settings.Vars{4} = B.Settings.Vars{4};

Settings.LatRange{3} = B.Settings.LatRange;
Settings.LatRange{4} = B.Settings.LatRange;

clear B




%third file - SABER T
C = load('data/zm_data_gws_S_polar.mat');
Results.Data(6,:,:) = C.Results.Data(1,:,:);
Results.Data(5,:,:) = C.Results.Data(2,:,:);

Settings.Vars{5} = C.Settings.Vars{2};
Settings.Vars{6} = C.Settings.Vars{1};

Settings.LatRange{5} = C.Settings.LatRange;
Settings.LatRange{6} = C.Settings.LatRange;


clear C

save(OutFile,'Results','Settings')