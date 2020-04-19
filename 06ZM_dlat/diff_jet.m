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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% calcns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%compute climatology for each day
ClimaYears = [2003:2009,2018:2018];
dd = date2doy(t);
yy = datevec(t); yy = yy(:,1)';

Clima = NaN(365,size(Data,2),size(Data,3));

for iDay=1:1:365;
  Clima(iDay,:,:) = nanmean(Data(dd == iDay,:,:));
end; clear iDay


%generate comparative years
Delta.y2002 = Data(yy == 2002,:,:) - Clima;
Delta.y2010 = Data(yy == 2010,:,:) - Clima;
Delta.y2019 = Data(yy == 2019,:,:) - Clima;

clear yy dd t Data ClimaYears

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%prepare figure
clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, 0.05, [0.05], [0.05]);

%choose days of year (2002 is arbitrary)
TimeRange = date2doy(datenum(2002,9,20)):1:date2doy(datenum(2002,9,30));

%prepare colours 
rb  = flipud(cbrewer('div','RdBu',33));
ryb = flipud(cbrewer('div','RdYlBu',33));

%plot climatology
h1 = subplot(2,4,1);
[c,h] = contourf(Lat,Z,squeeze(nanmean(Clima(TimeRange,:,:))));
clabel(c,h); caxis([-60,60])
colormap(h1,ryb);
colorbar
axis square
xlabel('Latitude');ylabel('Altitude');title('Climatological U')

%plot annual figures
k= 1;
for Year=[2002,2010,2019];
  k = k+1;
  ToPlot = Delta.(['y',num2str(Year)])+Clima;
  ToPlot = squeeze(nanmean(ToPlot(TimeRange,:,:)));

  
  h3 = subplot(2,4,k);
  [c,h] = contourf(Lat,Z,ToPlot);
  clabel(c,h); caxis([-1,1].*60)
  colormap(h3,ryb);  
  colorbar
  axis square
  
  xlabel('Latitude');ylabel('Altitude');
  title(['U ',num2str(Year)])
  
  drawnow
end


%plot differences
k = 5;
for Year=[2002,2010,2019];
  k = k+1;
  ToPlot = Delta.(['y',num2str(Year)]);
  ToPlot = squeeze(nanmean(ToPlot(TimeRange,:,:)));

  
  h2 = subplot(2,4,k);
  [c,h] = contourf(Lat,Z,ToPlot);
  clabel(c,h); caxis([-1,1].*50)
  colormap(h2,rb);  
  colorbar
  axis square
  
  xlabel('Latitude');ylabel('Altitude');
  title(['\Delta ',num2str(Year)])
  
  drawnow
end
