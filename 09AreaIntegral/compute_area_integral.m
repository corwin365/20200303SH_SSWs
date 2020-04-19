clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compute and plot area-integral MF over SH region
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%input
Settings.Instrument  = 'AIRS';
Settings.SpecialYear = 2019; %set to zero to plot climatology
Settings.Var         = 'MF';
Settings.Height      = 30;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch Settings.Var
  case {'U','T','PV','O3','dPV','PW mode 1','PW mode 2','PW mode 3','Sum of PWs'};  Settings.Type = 'raw';
  case {'A','MF','Mz','Mm','Lz','Lh'};                                              Settings.Type = 'gws';
  otherwise; stop
end

%file IDs
switch Settings.Type
  case 'raw';
    Settings.YearFile  = ['../07Maps/data/rawmaps_',Settings.Instrument,'_',num2str(Settings.SpecialYear),'.mat'];
    Settings.ClimFile  = ['../07Maps/data/rawmaps_',Settings.Instrument,'_clim.mat'];
  case 'gws'
    Settings.YearFile  = ['../07Maps/data/maps_',Settings.Instrument,'_',num2str(Settings.SpecialYear),'.mat'];
    Settings.ClimFile  = ['../07Maps/data/maps_',Settings.Instrument,'_clim.mat'];
  otherwise
    stop
end

%load data
Data.Year = load(Settings.YearFile); 
Data.Clim = load(Settings.ClimFile); 
Data.Year.Data = Data.Year.Results.Data;
Data.StaD.Data = Data.Clim.Results.StD;
Data.Clim.Data = Data.Clim.Results.Data;

%pull out height level
zidx = closest(Data.Year.Settings.HeightScale,Settings.Height);
Data.Year.Data = squeeze(Data.Year.Data(:,:,zidx,:,:));
Data.Clim.Data = squeeze(Data.Clim.Data(:,:,zidx,:,:)); 
clear zidx

%pull out variable
for iVar=1:1:numel(Data.Year.Settings.Vars)
  a = Data.Year.Settings.Vars{iVar};
  a = a{2};
  if strcmp(a,Settings.Var);
    Var = iVar;
  end
end; clear iVar a
if ~exist('Var'); stop; end
Data.Year.Data = squeeze(Data.Year.Data(Var,:,:,:));
Data.Clim.Data = squeeze(Data.Clim.Data(Var,:,:,:));
clear Var


%select region
InLatRange = find(Data.Year.Settings.LatScale < -45);
Data.Year.Settings.LatScale = Data.Year.Settings.LatScale(InLatRange);
Data.Year.Data =  Data.Year.Data(:,:,InLatRange);
Data.Clim.Data =  Data.Clim.Data(:,:,InLatRange);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compute area of each gridbox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%find grid size
Grid.Lon = Data.Year.Settings.LonScale;
Grid.Lat = Data.Year.Settings.LatScale;

dLon = mean(diff(Grid.Lon));
dLat = mean(diff(Grid.Lat));

Area = NaN.*meshgrid(Grid.Lon,Grid.Lat);
for iLat=1:1:numel(Grid.Lat)
  
  YSize = 111.321 .* dLat;
  XSize = 111.321 .* dLon .* cosd(Grid.Lat(iLat));
 
  Area(iLat,:) = XSize .* YSize;
  
end

clear iLat dLon dLat Grid

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% require a box to be filled in both datasets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Bad = find(isnan(sum(Data.Year.Data + Data.Clim.Data)));
Data.Year.Data(Bad) = NaN;
Data.Clim.Data(Bad) = NaN;



Area = repmat(permute(Area,[3,2,1]),365,1,1);
Sigma.Year = nanmean(Data.Year.Data .* Area,[2,3])./sum(Area(:));
Sigma.Clim = nanmean(Data.Clim.Data .* Area,[2,3])./sum(Area(:));






