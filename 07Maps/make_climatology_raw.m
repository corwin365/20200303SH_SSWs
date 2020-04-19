clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DataSet = 'ECMWF';
ExcludeYears = [2002,2010,2019];
OutFile = ['data/rawmaps_',DataSet,'_clim.mat']

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% import data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for Year=2002:1:2019;
  disp(Year)
  %skip exclude years
  if any(Year == ExcludeYears); continue; end
  
  %load data
  InFile = ['data/rawmaps_',DataSet,'_',num2str(Year),'.mat'];
  if ~exist(InFile); continue; end
  In = load(InFile);
  
  if ~exist('Store');
    Store = In;
  else
    Store.Results.Data       = cat(2,Store.Results.Data,      In.Results.Data);
    Store.Settings.TimeScale = cat(2,Store.Settings.TimeScale,In.Settings.TimeScale);
  end
  
end

clear Year In ExcludeYears DataSet InFile

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% annualise
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dd = date2doy(Store.Settings.TimeScale);
sz = size(Store.Results.Data);

Out = NaN(sz(1),365,sz(3),sz(4),sz(5));
for iDay=1:1:365;
  Out(:,iDay,:,:,:) = nanmean(Store.Results.Data(:,dd == iDay,:,:,:),2);
end; clear iDay dd sz

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% store
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Store.Results.Data = Out; clear Out
Results = Store.Results;
Settings = Store.Settings;
Settings.TimeScale = 1:1:365;
clear Store

save(OutFile,'Settings','Results')
