clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot data extracted by compute_maps
%
%Corwin Wright, c.wright@bath.ac.uk, 10/MAR/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%input
Settings.Instrument  = 'MLS';
Settings.SpecialYear = 2019; %set to zero to plot climatology
Settings.Var         = 'MF';
Settings.Height      = 30;


%times to plot
%%%%%%%%%%%%%%

if      strcmp(Settings.Instrument,'MLS');
  Settings.NDaysPerPlot =3;
elseif strcmp(Settings.Instrument,'AIRS');
    Settings.NDaysPerPlot = 3;
elseif strcmp(Settings.Instrument,'SABER');
  if   strcmp(Settings.Var,'A');  Settings.NDaysPerPlot =3;
  else strcmp(Settings.Var,'MF'); Settings.NDaysPerPlot = 7;
  end
else; Settings.NDaysPerPlot = 1; end

Settings.PlotTimes = -22+(date2doy(datenum(2002,8,6)):1:date2doy(datenum(2002,10,16)));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and prepare data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch Settings.Var
  case {'U','T','PV','O3','dPV','PW mode 1','PW mode 2','PW mode 3','Sum of PWs'};  Settings.Type = 'raw';
  case {'A','MF','Mz','Mm','Lz','Lh'};                                              Settings.Type = 'gws';
  otherwise; stop
end

%file IDs
switch Settings.Type
  case 'raw';
    Settings.YearFile  = ['data/rawmaps_',Settings.Instrument,'_',num2str(Settings.SpecialYear),'.mat'];
    Settings.ClimFile  = ['data/rawmaps_',Settings.Instrument,'_clim.mat'];
  case 'gws'
    Settings.YearFile  = ['data/maps_',Settings.Instrument,'_',num2str(Settings.SpecialYear),'.mat'];
    Settings.ClimFile  = ['data/maps_',Settings.Instrument,'_clim.mat'];
  otherwise
    stop
end

%load data
Data.Year = load(Settings.YearFile); 
Data.Clim = load(Settings.ClimFile); 
Data.Year.Data = Data.Year.Results.Data;
Data.StaD.Data = Data.Clim.Results.StD;
Data.Clim.Data = Data.Clim.Results.Data;

%convert data to z-scores
Data.Year.Data = (Data.Year.Data -  Data.Clim.Data)./Data.StaD.Data;


%load dPV data
Settings.dPVFile  = ['data/rawmaps_ECMWFdpv_',num2str(Settings.SpecialYear),'.mat'];
Data.dPV = load(Settings.dPVFile); Data.dPV.Data = Data.dPV.Results.Data;


%pull out height level
zidx = closest(Data.Year.Settings.HeightScale,Settings.Height);
Data.Year.Data = squeeze(Data.Year.Data(:,:,zidx,:,:));
zidx = closest(Data.dPV.Settings.HeightScale,Settings.Height);
Data.dPV.Data = squeeze(Data.dPV.Data(:,:,zidx,:,:));
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
clear Var

%pull out dPV, and find the maximum-gradient line
Data.dPV.Data = squeeze(Data.dPV.Data(1,:,:,:));
Data.dPV.Data = smoothn(Data.dPV.Data,[1,1,5]);
MaxdPV.Lon = [Data.dPV.Settings.LonScale;180];
idxes = find(Data.dPV.Settings.LatScale < -35 & Data.dPV.Settings.LatScale > -75);
Lat = Data.dPV.Settings.LatScale(idxes);
dPV = Data.dPV.Data(:,:,idxes);
[dPV,idxes] =  max(dPV,[],3);
MaxdPV.Lat = Lat(idxes); MaxdPV.dPV = dPV;
MaxdPV.Lat(:,end+1) = MaxdPV.Lat(:,1);
MaxdPV.dPV(:,end+1) = MaxdPV.dPV(:,1);
Data = rmfield(Data,'dPV');
clear idxes Lat dPV dPV


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% produce plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%prepare figure
clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, 0.01, 0.025, [0.01 0.08]);
NPlots = numel(Settings.PlotTimes);

for iPlot=1:1:NPlots;
  
  DaysToUse = Settings.PlotTimes(iPlot)+(-floor(Settings.NDaysPerPlot/2):1:floor(Settings.NDaysPerPlot/2));
  ToPlot = squeeze(nanmean(Data.Year.Data(DaysToUse,:,:),1));
  
  
  %duplicate endpoint
  LonScale = Data.Year.Settings.LonScale + mean(diff(Data.Year.Settings.LonScale))/2;
  ToPlot(end,:) = ToPlot(1,:);
    %interpolate the data onto a common grid for all analyses

% %     lon = LonScale;
% %     lat = Data.Year.Settings.LatScale;
  lon = -190:1:190;
  lat = -90:1:-20;
  [xi,yi] = meshgrid(lon,lat);
  tp = interp2(LonScale,Data.Year.Settings.LatScale,ToPlot',xi,yi)';
  ToPlot = tp;
  
  
  %and smooth a bit
  Bad = find(isnan(ToPlot));
  ToPlot = inpaint_nans(ToPlot);
  ToPlot = smoothn(ToPlot,[1,1,].*5);
  ToPlot(Bad) = NaN;
  
  
% %   %minor bug with ECMWF
% %   if strcmp(Settings.Instrument,'ECMWF') || strcmp(Settings.Instrument,'ECMWFpv') || strcmp(Settings.Instrument,'ECMWFdpv')
% %     ToPlot = inpaint_nans(ToPlot);
% %   end  
  
  %create panel
  subplot(6,ceil(NPlots./6),iPlot)
  cla
  hold on
  
  %title
%   title({[datestr(Settings.PlotTimes(iPlot),'dd/mmm'),' - ',datestr(Settings.PlotTimes(iPlot)+Settings.NDaysPerPlot-1,'dd/mmm')],[num2str(Settings.SpecialYear),', ',num2str(Settings.Height),'km']})
%   
%   if Settings.SpecialYear ~= 0;
%     title(datestr(datenum(Settings.SpecialYear,1,Settings.PlotTimes(iPlot)),'dd/mmm/yy'),'fontsize',9)
%   else
%     title(datestr(datenum(Settings.SpecialYear,1,Settings.PlotTimes(iPlot)),'dd/mmm'),'fontsize',9)  
%   end
  
  
  title(Settings.PlotTimes(iPlot))
    
  %colours and colour/line values
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  CLevels = -3:0.5:3;
  LLevels = -9:1:9;
  colormap(cbrew('RdBu',numel(CLevels))); Label = 'St. Dev from Climatology';

  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %create map
  m_proj('stereographic','lat',-90,'radius',55);
  
  %plot data
  
  TP2 = ToPlot; TP2(TP2 < min(CLevels)) = min(CLevels);
%   m_pcolor(lon,lat,TP2');
%   shading flat  
  
  m_contourf(lon,lat,TP2',CLevels,'edgecolor','none');
%   [c,h] = m_contour(lon,lat,ToPlot',LLevels(LLevels > 0),'edgecolor','k');
%   clabel(c,h,'fontsize',8)
%   [c,h] = m_contour(lon,lat,ToPlot',LLevels(LLevels < 0),'edgecolor','k','linestyle',':');
%   clabel(c,h,'fontsize',8)
%   
%   if any(LLevels == 0)
%     [c,h] = m_contour(lon,lat,ToPlot',[0,0],'edgecolor','k','linestyle','--');
%     clabel(c,h,'fontsize',8)
%   end
  
  %colours
  
  %     colormap(flipud(cbrewer('div','RdYlBu',32)))
  caxis([min(CLevels) max(CLevels)])
  % % %     colorbar('southoutside')
  
  %plot maximum pv line
  %%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %extract line
  PVLine = squeeze(nanmean(MaxdPV.Lat(DaysToUse,:),1));
  PVVal  = squeeze(nanmean(MaxdPV.dPV(DaysToUse,:),1));
  n = numel(PVLine);
  PVLine = [PVLine,PVLine,PVLine];
  PVLine = smooth(PVLine,7);
  PVLine = PVLine(n+1:2*n);
  
%   %remove outliers
%   Cut = prctile(PVLine,[10,90]);
%   PVLine(PVLine > max(Cut)) = NaN;
%   PVLine(PVLine < min(Cut)) = NaN;
%   PVLine = inpaint_nans(PVLine);
  
  Strong = find(PVVal > 0.3e-4);
  m_plot(MaxdPV.Lon,PVLine,':','linewi',2,'color','k')
  
  for iEl=1:1:numel(Strong)-1
    A = diff(Strong([0,1]+iEl));
    if A > 1; continue; end
    X = MaxdPV.Lon(Strong([0,1]+iEl));
    Y = PVLine(    Strong([0,1]+iEl)); 
    m_plot(X,Y,'-','linewi',3,'color','k')
  end
  
  %finalise map
  m_coast('color',[1,1,1].*0.5);
  m_grid('ytick',[],'xtick',[]);
  
  %done
  drawnow

  
  %put a colourbar right in the middle
  if iPlot == 1;
    %special cases of names
    SourceName = Settings.Instrument;
    switch SourceName
      case 'ECMWF';    SourceName = 'ERA5';
      case 'ECMWFpv';  SourceName = 'ERA5';
      case 'ECMWFdpv'; SourceName = 'ERA5';
      case 'MLSpw';    SourceName = 'MLS';      
      case 'SABERpw';  SourceName = 'SABER';                
    end
    MeanType = 'mean';
    
    cb = colorbar('eastoutside','position',[0.95 0.40 0.01 0.2]);
    cb.Label.String = Label;
    set(get(cb,'Title'),'String',{[SourceName,' ',Settings.Var],[num2str(Settings.Height),' km'],[num2str(Settings.NDaysPerPlot),'-day ',MeanType]});
  end

  
end
  
