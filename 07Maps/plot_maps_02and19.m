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
Settings.Instrument    = 'ECMWFpv'
Settings.Var           = 'PV';
Settings.Height        = 30;


%times to plot
%%%%%%%%%%%%%%%
Settings.NDaysPerPlot = 9;
Settings.PlotTimes = date2doy(datenum(2002,8,2)):Settings.NDaysPerPlot:date2doy(datenum(2002,10,10));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and prepare data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch Settings.Var
  case {'U','T','O3','PV'};            Settings.Type = 'raw';
  case {'A','MF','Mz','Mm','Lz','Lh'}; Settings.Type = 'gws';
  otherwise; stop
end

%file IDs
switch Settings.Type
  case 'raw';
    Settings.ClimaFile = ['data/rawmaps_',Settings.Instrument,'_clim.mat'];
    Settings.Ye02File  = ['data/rawmaps_',Settings.Instrument,'_2002.mat']; 
    Settings.Ye19File  = ['data/rawmaps_',Settings.Instrument,'_2019.mat']; 
  case 'gws'
    Settings.ClimaFile = ['data/maps_',Settings.Instrument,'_clim.mat'];
    Settings.Ye02File  = ['data/maps_',Settings.Instrument,'_2002.mat']; 
    Settings.Ye19File  = ['data/rawmaps_',Settings.Instrument,'_2019.mat']; 
  otherwise
    stop
end

%load data
Data.Clim = load(Settings.ClimaFile); Data.Clim.Data = Data.Clim.Results.Data;
Data.Ye02 = load(Settings.Ye02File);  Data.Ye02.Data = Data.Ye02.Results.Data;
Data.Ye19 = load(Settings.Ye19File);  Data.Ye19.Data = Data.Ye19.Results.Data;

%pull out height level
zidx = closest(Data.Clim.Settings.HeightScale,Settings.Height);
Data.Clim.Data = squeeze(Data.Clim.Data(:,:,zidx,:,:));
zidx = closest(Data.Ye02.Settings.HeightScale,Settings.Height);
Data.Ye02.Data = squeeze(Data.Ye02.Data(:,:,zidx,:,:));
zidx = closest(Data.Ye19.Settings.HeightScale,Settings.Height);
Data.Ye19.Data = squeeze(Data.Ye19.Data(:,:,zidx,:,:));
clear zidx

%pull out variable
for iVar=1:1:numel(Data.Clim.Settings.Vars)
  a = Data.Clim.Settings.Vars{iVar};
  a = a{2};
  if strcmp(a,Settings.Var);
    Var = iVar;
  end
end; clear iVar a
if ~exist('Var'); stop; end
Data.Clim.Data = squeeze(Data.Clim.Data(Var,:,:,:));
Data.Ye02.Data = squeeze(Data.Ye02.Data(Var,:,:,:));
Data.Ye19.Data = squeeze(Data.Ye19.Data(Var,:,:,:));
clear Var


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% produce plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%prepare figure
clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, [0.04,0.01], 0.06, [0.01 0.07]);
NPlots = numel(Settings.PlotTimes);

for iPlot=1:1:NPlots;
  
  for iPanel=[0,1,2];
    
    %get data
    switch iPanel
      case 0; ToPlot = squeeze(nanmean(Data.Clim.Data(Settings.PlotTimes(iPlot)+(0:1:Settings.NDaysPerPlot-1),:,:),1));      
      case 1; ToPlot = squeeze(nanmean(Data.Ye02.Data(Settings.PlotTimes(iPlot)+(0:1:Settings.NDaysPerPlot-1),:,:),1));
      case 2; ToPlot = squeeze(nanmean(Data.Ye19.Data(Settings.PlotTimes(iPlot)+(0:1:Settings.NDaysPerPlot-1),:,:),1));
    end
    
    %duplicate endpoint
    LonScale = Data.Clim.Settings.LonScale;
    ToPlot(end,:) = ToPlot(1,:);
    
    %interpolate the data onto a common grid for all analyses
    lon = -180:1:180;
    lat = -90:1:0;    
    [xi,yi] = meshgrid(lon,lat);
    tp = interp2(LonScale,Data.Ye02.Settings.LatScale,ToPlot',xi,yi)';
    ToPlot = tp;
    
    %and smooth a bit
    Bad = find(isnan(ToPlot));
    ToPlot = inpaint_nans(ToPlot);
    ToPlot = smoothn(ToPlot,[1,1,].*5);
    ToPlot(Bad) = NaN;
    
    %minor bug with ECMWF
    if strcmp(Settings.Instrument,'ECMWF') || strcmp(Settings.Instrument,'ECMWFpv')
      ToPlot = inpaint_nans(ToPlot);
    end
       
    
    %create panel
    subplot(3,NPlots,iPlot+iPanel.*NPlots)
    cla
    hold on
    
    %title
    if iPanel == 0;
      title({[datestr(Settings.PlotTimes(iPlot),'dd/mmm'),' - ',datestr(Settings.PlotTimes(iPlot)+Settings.NDaysPerPlot-1,'dd/mmm')],['Climatology, ',num2str(Settings.Height),'km']})
    elseif iPanel == 1
      title(['2002, ',num2str(Settings.Height),'km'])
    elseif iPanel == 2
      title(['2019, ',num2str(Settings.Height),'km'])      
    end
    
    %colours and colour/line values
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %colours and colour/line values
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if     strcmp(Settings.Var, 'U') == 1; CLevels = -80:10:80; LLevels = -210:20:200;
    elseif strcmp(Settings.Var, 'T') == 1; CLevels = 200:2:250; LLevels = 0:10:1000;
    elseif strcmp(Settings.Var,'O3') == 1; CLevels = 1.5:0.1:3; LLevels = (0:0.2:5);
    elseif strcmp(Settings.Var,'Mz') == 1; CLevels = -15:2:15;  LLevels = -500:4:500;
    elseif strcmp(Settings.Var,'Mm') == 1; CLevels = -15:2:15;  LLevels = -500:4:500;
    elseif strcmp(Settings.Var,'Lh') == 1; CLevels = 0:20:300;  LLevels = 0:100:300;
    elseif strcmp(Settings.Var,'Lz') == 1; CLevels = 10:2:30;   LLevels = 0:2:100;
    elseif strcmp(Settings.Var,'PV') == 1; CLevels = -9:.5:-2;  LLevels = -100:2:100;
    elseif strcmp(Settings.Var, 'A') == 1
      if     strcmp(Settings.Instrument,'MLS')  == 1; CLevels = 0:0.5:15; LLevels = 0:2:1000;
      elseif strcmp(Settings.Instrument,'AIRS') == 1; CLevels = 1:0.1:3;  LLevels = 0:0.5:1000;
      end
    elseif strcmp(Settings.Var,'MF') == 1
      if     strcmp(Settings.Instrument,'MLS')  == 1; CLevels = 0:0.1:2; LLevels = 0:.5:1000;
      elseif strcmp(Settings.Instrument,'AIRS') == 1; CLevels = 5:1:25;  LLevels = 0:5:1000;
      end
    end
    
    %colours and labels
    switch Settings.Var
      case 'U';  colormap(cbrew('nph_BlueOrange',numel(CLevels))); Label = 'Zonal Wind [ms^{-1}]';
      case 'O3'; colormap(cbrew('nph_RdBuPastel',numel(CLevels))); Label = 'Ozone Concentration [ppm]';
      case 'Mz'; colormap(cbrew('PRGn',          numel(CLevels))); Label = 'Zonal MF [mPa]';
      case 'Mm'; colormap(cbrew('BrBG',          numel(CLevels))); Label = 'Meridional MF [mPa]'
      case 'Lz'; colormap(cbrew('Purples',       numel(CLevels))); Label = 'Vertical wavelength [km]';
      case 'Lh'; colormap(cbrew('Blues',         numel(CLevels))); Label = 'Horizontal wavelength [km]';
      case 'MF'; colormap(cbrew('RdYlBu',        numel(CLevels))); Label = 'Absolute MF [mPa]';
      case  'A'; colormap(cbrew('Greens',        numel(CLevels))); Label = 'Wave Amplitude [K]';
      case 'PV'; colormap(cbrew('RdYlGn',        numel(CLevels))); Label = 'PV [UNITS]';
      otherwise; colormap(cbrew('RdYlBu',        numel(CLevels))); Label = '[[UNITS]]';
    end
    
    %scalings
    switch Settings.Var
      case 'O3'; ToPlot = ToPlot.*1e6;
      case 'PV'; ToPlot = ToPlot.*1e4;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %create map
    m_proj('stereographic','lat',-90,'radius',45);
    
    %plot data
    
    TP2 = ToPlot; TP2(TP2 < min(CLevels)) = min(CLevels);
    m_contourf(lon,lat,TP2',CLevels,'edgecolor','none');
    shading flat
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
  if iPlot == 1 && iPanel == 0;
    cb = colorbar('eastoutside','position',[0.95 0.40 0.01 0.2]);
    cb.Label.String = Label;
  end    
  end

  
  end

