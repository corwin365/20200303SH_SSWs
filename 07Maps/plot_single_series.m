% clearvars

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

% % %input
% % Settings.Instrument  = 'AIRS';
% % Settings.SpecialYear = 2019; %set to zero to plot climatology
% % Settings.Var         = 'MF';
% % Settings.Height      = 30;



%times to plot
%%%%%%%%%%%%%%

if      strcmp(Settings.Instrument,'MLS');
  Settings.NDaysPerPlot =3;
elseif strcmp(Settings.Instrument,'AIRS');
%   if strcmp(Settings.Var,'Mz') | strcmp(Settings.Var,'Mm');
    Settings.NDaysPerPlot = 3;
%   else Settings.NDaysPerPlot = 1;
%   end
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
  case {'U','T','PV','O3','dPV','PW mode 1','PW mode 2','PW mode 3'};  Settings.Type = 'raw';
  case {'A','MF','Mz','Mm','Lz','Lh'};                                 Settings.Type = 'gws';
  otherwise; stop
end

%file IDs
switch Settings.Type
  case 'raw';
    if Settings.SpecialYear ~= 0;
      Settings.YearFile  = ['data/rawmaps_',Settings.Instrument,'_',num2str(Settings.SpecialYear),'.mat'];
    else
      Settings.YearFile  = ['data/rawmaps_',Settings.Instrument,'_clim.mat'];  
    end
  case 'gws'
    if Settings.SpecialYear ~= 0;
      Settings.YearFile  = ['data/maps_',Settings.Instrument,'_',num2str(Settings.SpecialYear),'.mat'];
    else
      Settings.YearFile  = ['data/maps_',Settings.Instrument,'_clim.mat'];    
    end
  otherwise
    stop
end

%load data
Data.Year = load(Settings.YearFile);  Data.Year.Data = Data.Year.Results.Data;

%pull out height level
zidx = closest(Data.Year.Settings.HeightScale,Settings.Height);
Data.Year.Data = squeeze(Data.Year.Data(:,:,zidx,:,:));
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
  lon = -250:1:250;
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
  
  if Settings.SpecialYear ~= 0;
    title(datestr(datenum(Settings.SpecialYear,1,Settings.PlotTimes(iPlot)),'dd/mmm/yy'),'fontsize',9)
  else
    title(datestr(datenum(Settings.SpecialYear,1,Settings.PlotTimes(iPlot)),'dd/mmm'),'fontsize',9)  
  end
  
    
  %colours and colour/line values
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  if     strcmp(Settings.Var,  'U') == 1; CLevels = -80:10:80; LLevels = -210:20:200;
  elseif strcmp(Settings.Var,  'T') == 1; CLevels = 190:5:250; LLevels = 0:10:1000;
  elseif strcmp(Settings.Var, 'O3') == 1; CLevels = 4:0.25:8; LLevels = (0:1:10);
  elseif strcmp(Settings.Var, 'Mz') == 1; CLevels = -20:4:20;  LLevels = -500:10:500; LLevels(LLevels == 0) = [];
  elseif strcmp(Settings.Var, 'Mm') == 1; CLevels = -20:4:20;  LLevels = -500:10:500; LLevels(LLevels == 0) = [];
  elseif strcmp(Settings.Var, 'Lh') == 1; CLevels = 0:20:300;  LLevels = 0:100:300;
  elseif strcmp(Settings.Var, 'Lz') == 1; CLevels = 10:2:30;   LLevels = 0:2:100;
  elseif strcmp(Settings.Var, 'PV') == 1; CLevels = -9:.5:-2;  LLevels = -100:2:100; LLevels(LLevels == 0) = [];
  elseif strcmp(Settings.Var,'dPV') == 1; CLevels = -.5:.1:.5;   LLevels =[];% -20:.2:20; LLevels(LLevels == 0) = [];
  elseif strcmp(Settings.Var,  'A') == 1
    if     strcmp(Settings.Instrument,'MLS')   == 1; CLevels = 0:1:15; LLevels = 0:2:100;
    elseif strcmp(Settings.Instrument,'SABER') == 1; CLevels = 0:1:15; LLevels = 0:2:100;
    elseif strcmp(Settings.Instrument,'AIRS')  == 1; CLevels = 1.5:0.1:2.5;  LLevels = 0:1:100;
    end
  elseif strcmp(Settings.Var,'MF') == 1
    if     strcmp(Settings.Instrument,'MLS')   == 1; CLevels = 0:1:18;  LLevels = 0:5:100;
    elseif strcmp(Settings.Instrument,'SABER') == 1; CLevels = 0:5:100;  LLevels = 0:20:200;
    elseif strcmp(Settings.Instrument,'AIRS')  == 1; CLevels = 30:10:100;  LLevels = 0:20:100;
    end
    
  elseif strcmp(Settings.Var,'PW mode 1') == 1; CLevels = -10:1:10; LLevels = -100:5:100; LLevels(LLevels == 0) = [];
  elseif strcmp(Settings.Var,'PW mode 2') == 1; CLevels = -5:1:5; LLevels = -100:2.5:100; LLevels(LLevels == 0) = [];
  elseif strcmp(Settings.Var,'PW mode 3') == 1; CLevels = -5:1:5; LLevels = -100:2.5:100; LLevels(LLevels == 0) = [];
  end
  
  %colours and labels
  switch Settings.Var
    case 'U';  colormap(cbrew('nph_BlueOrange',numel(CLevels))); Label = 'Zonal Wind [ms^{-1}]';
    case 'O3'; colormap(cbrew('nph_RdBuPastel',numel(CLevels))); Label = 'Ozone Concentration [ppm]';
    case 'T';  colormap(cbrew('RdBu',          numel(CLevels))); Label = 'Temperature [K]';
    case 'PW mode 1';  colormap(cbrew('RdBu',  numel(CLevels))); Label = '\Delta Temperature [K]';
    case 'PW mode 2';  colormap(cbrew('RdBu',  numel(CLevels))); Label = '\Delta Temperature [K]';
    case 'PW mode 3';  colormap(cbrew('RdBu',  numel(CLevels))); Label = '\Delta Temperature [K]';      
    case 'Mz'; colormap(cbrew('PRGn',          numel(CLevels))); Label = 'Zonal MF [mPa]';
    case 'Mm'; colormap(cbrew('BrBG',          numel(CLevels))); Label = 'Meridional MF [mPa]';
    case 'Lz'; colormap(cbrew('Purples',       numel(CLevels))); Label = 'Vertical wavelength [km]';
    case 'Lh'; colormap(cbrew('Blues',         numel(CLevels))); Label = 'Horizontal wavelength [km]';
    case 'MF'; colormap(cbrew('RdYlBu',        numel(CLevels))); Label = 'Absolute MF [mPa]';
    case  'A'; colormap(cbrew('Greens',        numel(CLevels))); Label = 'Wave Amplitude [K]';
    case 'PV'; colormap(cbrew('RdYlGn',        numel(CLevels))); Label = 'PV [10^{-4} Km^2kg^{-1}s^{-1}]';
    case 'dPV'; colormap(cbrew('nph_BuOr2',    numel(CLevels))); Label = 'dPV/dLat [10^{-4} Km^2kg^{-1}s^{-1}deg^{-1}]';
    otherwise; colormap(cbrew('RdYlBu',        numel(CLevels))); Label = 'VARIABLE?? [UNITS??]';
  end
  
  %scalings
  switch Settings.Var
    case 'O3';  ToPlot = ToPlot.*1e6;
    case 'PV';  ToPlot = ToPlot.*1e4;
    case 'dPV'; ToPlot = ToPlot.*1e4; 
    case 'MF'; 
      if strcmp(Settings.Instrument,'AIRS') ~= 1;ToPlot = ToPlot.*1e3; end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %create map
  m_proj('stereographic','lat',-90,'radius',55);
  
  %plot data
  
  TP2 = ToPlot; TP2(TP2 < min(CLevels)) = min(CLevels);
%   m_pcolor(lon,lat,TP2');
%   shading flat  
  
  m_contourf(lon,lat,TP2',CLevels,'edgecolor','none');
  [c,h] = m_contour(lon,lat,ToPlot',LLevels(LLevels > 0),'edgecolor','k');
  clabel(c,h,'fontsize',8)
  [c,h] = m_contour(lon,lat,ToPlot',LLevels(LLevels < 0),'edgecolor','k','linestyle',':');
  clabel(c,h,'fontsize',8)
  
  if any(LLevels == 0)
    [c,h] = m_contour(lon,lat,ToPlot',[0,0],'edgecolor','k','linestyle','--');
    clabel(c,h,'fontsize',8)
  end
  
  %colours
  
  %     colormap(flipud(cbrewer('div','RdYlBu',32)))
  caxis([min(CLevels) max(CLevels)])
  % % %     colorbar('southoutside')
  
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
  
