clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%locate and track jet centre in gridded ERA5 data
%Corwin Wright, c.wright@bath.ac.uk, 2020/MAR/08
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.InFile      = 'zm_data_dlat_E.mat';
Settings.HeightRange = [10,80];
Settings.LatRange    = [-85,-30];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load data and select wind field
Data = load(Settings.InFile);
Data.Data = squeeze(Data.Results.Data(1,:,:,:));

%drop regions outside box
BoxLat = inrange(Data.Settings.LatScale,   Settings.LatRange);
BoxZ   = inrange(Data.Settings.HeightScale,Settings.HeightRange);

t    = Data.Settings.TimeScale;
Lat  = Data.Settings.LatScale(   BoxLat);
Z    = Data.Settings.HeightScale(  BoxZ);
Data = Data.Data(:,BoxZ,BoxLat);
clear BoxZ BoxLat


%create results arrays
NTimes = size(Data,1);
Results.t   = t;
Results.Lat = NaN(NTimes,1);
Results.Z   = NaN(NTimes,1);
Results.U   = NaN(NTimes,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% do it
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sz = size(Data);
Data = reshape(Data,sz(1),sz(2)*sz(3));

[Results.U,idx] = max(Data,[],2);
[Results.Z,Results.Lat] = ind2sub([sz(2) sz(3)],idx);

Results.Z   = Z(Results.Z);
Results.Lat = Lat(Results.Lat);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear idx Lat Z t sz Data NTimes

clf
for iPlot=1:1:3;
  subplot(3,1,iPlot)
  cla

  hold on
  
  % % % % % Bad = find(Results.U < 30);
  % % % % % Results.U(Bad) = NaN;
  % % % % % Results.Lat(Bad) = NaN;
  % % % % % Results.Z(Bad) = NaN;
  
  if iPlot == 1; ToPlot = Results.U;   ylabel('Magnitude'); end
  if iPlot == 2; ToPlot = Results.Lat; ylabel('Latitude');  end
  if iPlot == 3; ToPlot = Results.Z;   ylabel('Altitude');  end
  
  yy = datevec(Results.t);
  dd = date2doy(Results.t);
  
%   ToPlot = smoothn(ToPlot,[1,5]);
  
  for Year=[2003:2009,2011:2018];
    plot(dd(Year == yy),ToPlot(Year == yy),'k-')
  end
  
  for Year=2002;
    plot(dd(Year == yy),ToPlot(Year == yy),'r-','linewi',2)
  end
  
  for Year=2010;
    plot(dd(Year == yy),ToPlot(Year == yy),'-','linewi',2,'color',[255,128,0]./255)
  end
  
  for Year=2019;
    plot(dd(Year == yy),ToPlot(Year == yy),'b-','linewi',2)
  end
  
  xlim([0 365])
end