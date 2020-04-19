clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%generate zonal mean time series of GW variables
%
%Corwin Wright, c.wright@bath.ac.uk, 03/MAR/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%where to put the data?
Settings.OutFile = 'zm_data_gws_S.mat';

%gridding?
Settings.LatRange    = [-65,-55];
Settings.TimeScale   = datenum(2002,1,1):1:datenum(2019,12,31);
Settings.HeightScale = 20:10:60;

%data storage
% Settings.DataDir.Ecmwf = [LocalDataDir,'/ERA5/'];
Settings.DataDir.Saber = [LocalDataDir,'/corwin/gws_saber/'];
Settings.DataDir.Airs  = [LocalDataDir,'/corwin/sh_ssw/'];
Settings.DataDir.Mls   = [LocalDataDir,'/corwin/gws_mls/'];


%variables and sources
%'Instrument','Output Variable Name'
% Settings.Vars{1} = {'MLS','A','K'};
% Settings.Vars{2} = {'MLS','Lz','km'};
% Settings.Vars{3} = {'MLS','Lh','km'};
% Settings.Vars{4} = {'MLS','MF','mPa'};


Settings.Vars{1} = {'AIRS','A','K'};
Settings.Vars{2} = {'AIRS','Lz','km'};
Settings.Vars{3} = {'AIRS','Lh','km'};
Settings.Vars{4} = {'AIRS','Mz','mPa'};
Settings.Vars{5} = {'AIRS','Mm','mPa'};
Settings.Vars{6} = {'AIRS','MF','mPa'};

% Settings.Vars{1} = {'SABER','MF','mPa'};
% Settings.Vars{2} = {'SABER','A','K'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create needed variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Results.Data = NaN(numel(Settings.Vars),        ...
                   numel(Settings.TimeScale),   ...
                   numel(Settings.HeightScale));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% loop over and import data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%don't reload a file if it's not necessary
OldFilePath.Airs = '';
Data = struct(); Data.Saber = struct();

for iDay=1:1:numel(Settings.TimeScale)
  disp(datestr(Settings.TimeScale(iDay)))
  
  for iVar=1:1:numel(Settings.Vars)
%   try
    
    %get variable info
    VarInfo = Settings.Vars{iVar};
    disp(['---> ',VarInfo{1},' - ',VarInfo{2}])
    
    switch VarInfo{1}
        
      case 'SABER';
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %SABER
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
         %find the file for this day
        InFile = [Settings.DataDir.Saber,'/gws_',num2str(Settings.TimeScale(iDay)),'.mat'];
        if ~exist(InFile); continue; end
        
        %load data
        Data = load(InFile); Data = Data.Store;

        %choose variable
        VarData = Data.(VarInfo{2});
        
        %special case of remove outliers
        if strcmp(VarInfo{2},'Lh') == 1; VarData(VarData > 15000) = NaN; end
        
        %extract lat range
        InLatRange = inrange(Data.Lat,Settings.LatRange);
        if numel(InLatRange) ==0 ; continue; end
        
        %take zonal mean, interpolate to height scale, and store
        VarData =  nanmean(VarData(:,InLatRange),2);
        VarData = interp1(Data.Z,VarData,Settings.HeightScale);
        
        Results.Data(iVar,iDay,:) = VarData;
        
      case 'AIRS'; 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %AIRS 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         
   
        %load file for this day
        DayFile = [Settings.DataDir.Airs,'/gws_',num2str(Settings.TimeScale(iDay)),'.mat'];
        if strcmp(DayFile,OldFilePath.Airs) ~= 1;
          %load file
          if ~exist(DayFile); continue;end
          Data.Airs = load(DayFile);
          OldFilePath.Airs = DayFile;
          
          %prepare data for later use
          sz = size(Data.Airs.Results.A);
          Data.Airs.Results.P  = h2p(Data.Airs.Results.Z);
          Data.Airs.Results.Z  = repmat(permute(Data.Airs.Results.Z,[2,1]),sz(1),1,sz(3),sz(4));
          Data.Airs.Results.P  = repmat(permute(Data.Airs.Results.P,[2,1]),sz(1),1,sz(3),sz(4));       
          clear sz
          
%           %nighttime only
%           Day =  find(Data.Airs.Results.DayNight == 1);
%           Data.Airs.Results.Lat(Day) = NaN; %this will shortcircuit the gridding
%           clear Day
          
        end
        
        %extract desired vars
        switch VarInfo{2}
          case 'A';   VarData = Data.Airs.Results.A;
          case 'Lz';  VarData = 1./Data.Airs.Results.m;
          case 'Lh';  VarData = 1./quadadd(Data.Airs.Results.k,Data.Airs.Results.l);
          case 'Mz';  VarData = -1000.*cjw_airdensity(Data.Airs.Results.P,Data.Airs.Results.BG)./2  ...
                             .*  (9.81/0.02).^2                             ...
                             .*  (Data.Airs.Results.A./Data.Airs.Results.BG).^2                       ...
                             .*  (Data.Airs.Results.k./Data.Airs.Results.m);
          case 'Mm';  VarData = -1000.*cjw_airdensity(Data.Airs.Results.P,Data.Airs.Results.BG)./2  ...
                             .*  (9.81/0.02).^2                             ...
                             .*  (Data.Airs.Results.A./Data.Airs.Results.BG).^2                       ...
                             .*  (Data.Airs.Results.l./Data.Airs.Results.m);
          case 'MF';  VarData = 1000.*cjw_airdensity(Data.Airs.Results.P,Data.Airs.Results.BG)./2  ...
                             .*  (9.81/0.02).^2                             ...
                             .*  (Data.Airs.Results.A./Data.Airs.Results.BG).^2                       ...
                             .*  (quadadd(Data.Airs.Results.k,Data.Airs.Results.l)./Data.Airs.Results.m);
          otherwise; disp('Variable error'); stop;
        end        
        
        %extract region and take  mean
        sz = size(VarData);
        VarData = reshape(permute(VarData,[1,3,4,2]),sz(1)*sz(4)*sz(3),sz(2));
        clear sz
        
        InLatRange = inrange(Data.Airs.Results.Lat(:),Settings.LatRange);
        VarData = nanmean(VarData(InLatRange,:),1);
        
        %interpolate to output height scale and store       
        Results.Data(iVar,iDay,:) =  interp1(squeeze(Data.Airs.Results.Z(1,:,1,1)),VarData,Settings.HeightScale);

        clear VarData InLatRange

      case 'MLS'; 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %MLS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%          

        %find the file for this day
        InFile = [Settings.DataDir.Mls,'/gws_',num2str(Settings.TimeScale(iDay)),'.mat'];
        if ~exist(InFile); continue; end
        
        %load data
        Data = load(InFile); Data = Data.Store;

        %choose variable
        VarData = Data.(VarInfo{2});
        
        %special case of remove outliers
        if strcmp(VarInfo{2},'Lh') == 1; VarData(VarData > 15000) = NaN; end
        
        %extract lat range
        InLatRange = inrange(Data.Lat,Settings.LatRange);
        if numel(InLatRange) ==0 ; continue; end
        
        %take zonal mean, interpolate to height scale, and store
        VarData =  nanmean(VarData(:,InLatRange),2);
        VarData = interp1(Data.Z,VarData,Settings.HeightScale);
        
        Results.Data(iVar,iDay,:) = VarData;
        
        
      otherwise; disp('Dataset not specified');stop;
    end
    
    clear VarInfo

%   catch;end
  end; clear iVar
  
  if mod(iDay,30) == 0;
    pause(0.05) %was having trouble with very fast empty loops locking the file
    save(Settings.OutFile,'Results','Settings')
    disp('==========Saved!============')
  end
  
end; clear iDay

save(Settings.OutFile,'Results','Settings')
disp('Complete')
