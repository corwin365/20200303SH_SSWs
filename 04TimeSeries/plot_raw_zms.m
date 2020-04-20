clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot zonal mean time series of basic variables
%
%Corwin Wright, c.wright@bath.ac.uk, 03/MAR/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%where's the data
Settings.DataSets{ 1} = 'MLS';
Settings.Variables{1} = 'O3';
Settings.Units{    1} = 'ppm';
Settings.FullName{ 1} = 'Ozone Mixing Ratio';
Settings.Scale{    1} = 1e6;
Settings.LatRange{ 1} = [-65,-55];

Settings.DataSets{ 2} = 'MLSpw';
Settings.Variables{2} = 'Sum of PWs';
Settings.Units{    2} = 'K';
Settings.FullName{ 2} = 'Sum of PWs mode 1-3';
Settings.LatRange{ 2} = [-65,-55];

Settings.DataSets{ 3} = 'ECMWF';
Settings.Variables{3} = 'T';
Settings.Units{    3} = 'K';
Settings.FullName{ 3} = 'Temperature';
Settings.LatRange{ 3} = [-65,-55];

Settings.DataSets{ 4} = 'ECMWF';
Settings.Variables{4} = 'U';
Settings.Units{    4} = 'm/s';
Settings.FullName{ 4} = 'Zonal Wind Speed';
Settings.LatRange{ 4} = [-65,-55];

Settings.DataSets{ 5} = 'SABERpw';
Settings.Variables{5} = 'Sum of PWs';
Settings.Units{    5} = 'K';
Settings.FullName{ 5} = 'Sum of PWs mode 1-3';
Settings.LatRange{ 5} = [-50,-45];

%which years are special?
%all other years from 2002 to 2019 that we have data for locally will be the background
Settings.SpecialYears = [2002,2010,2019];%,2010];

%point out the minimum U time
Settings.Minima(1) = 731486;
Settings.Minima(2) = 731426;
Settings.Minima(3) = 731473;

%and what are their colours?
Settings.SpecialColours(1,:) = [0.8,0,0];
Settings.SpecialColours(2,:) = [255,128,0]./255;
Settings.SpecialColours(3,:) = [0,0,1];

%what height level?
Settings.HeightLevel =  30;

%what percentiles for the background shading? 
Settings.Percentiles = linspace(0,100,10);
Settings.PCColours   = colorGradient([1,1,1].*0.8,  ...
                                     [1,1,1].*0.25, ...
                                     (numel(Settings.Percentiles))./2);

%how many days to smooth by?
Settings.SmoothDays = 3; %main time series
Settings.ClimSmooth = 3; %climatology bands

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and prep data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Years = 2002:1:2019;
TimeSeries = NaN(numel(Years),365,numel(Settings.DataSets));

for iDS = 1:1:numel(Settings.DataSets)
 
  textprogressbar(['Loading dataset ',num2str(iDS),' '])
  for iYear=1:1:numel(Years)
    textprogressbar(iYear./numel(Years).*100)
  
    %do we have data for this instrument and year?
    DataFile = ['../data/rawmaps_',Settings.DataSets{iDS}, ...
                '_',num2str(Years(iYear)),'.mat'];
    if ~exist(DataFile); clear DataFile; continue; end
    
    %load file
    Data = load(DataFile);
    clear DataFile
    
    %pull out variable
    for iVar=1:1:numel(Data.Settings.Vars)
      a = Data.Settings.Vars{iVar};
      a = a{2};
      if strcmp(a,Settings.Variables{iDS});
        Var = iVar;
      end
    end;
    if ~exist('Var'); stop; end
    Data.Results = Data.Results.Data(Var,:,:,:,:);
    clear Var iVar a
    
    %pull out height level
    zidx = closest(Data.Settings.HeightScale,Settings.HeightLevel);
    Data.Results = Data.Results(:,:,zidx,:,:);
    clear zidx
    
    %pull out lat range and take zonal mean (or max, for PWs)
    if numel(strfind(Settings.Variables{iDS},'PW')) == 0;
      InLatRange = inrange(Data.Settings.LatScale ,Settings.LatRange{iDS});
      Data.Results = nanmean(Data.Results(:,:,:,:,InLatRange),[4,5]);
    else
      InLatRange = inrange(Data.Settings.LatScale ,Settings.LatRange{iDS});
      Data.Results = nanmax(Data.Results(:,:,:,:,InLatRange),[],[4,5]);
    end
    
    %and store (drop day 366 while we're at it)
    TimeSeries(iYear,:,iDS) = squeeze(Data.Results(1:365));
    
  end; clear iYear
  textprogressbar('!')
  
end; clear iDS

%remove extreme outliers
for iDS=1:1:numel(Settings.DataSets)
  TS = TimeSeries(:,:,iDS);
  TS = TS(:);
  CutOff = nanmean(TS) + 5.*nanstd(TS);
  TS(TS > CutOff) = NaN;
  TS(TS < -CutOff) = NaN;  
  TimeSeries(:,:,iDS) = reshape(TS,[],365);
end
clear iDS TS CutOff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Letters = 'abcdefghijklmnopqrstuvwxyz';

%prepare figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clf
set(gcf,'color','w')

for iVar=1:1:numel(Settings.DataSets)
  
  %prep
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  VarData = squeeze(TimeSeries(:,:,iVar));
  TimeScale = datenum(2002,1,1:1:365); %year is arbitrary
  VarInfo = {Settings.DataSets{iVar},Settings.Variables{iVar} ,...
             Settings.Units{iVar},Settings.FullName{iVar}};
 
  %scale?
  if numel(Settings.Scale) >= iVar;
    if numel(Settings.Scale{iVar}) ~= 0;
      VarData = VarData.*Settings.Scale{iVar};
    end
  end
    
  
  %exclude special years from climatological calculations
  VarData2 = smoothn(VarData,[1,Settings.SmoothDays]);
  for iYear=1:1:numel(Settings.SpecialYears)
    yidx = closest(Settings.SpecialYears(iYear),Years);
    VarData(yidx,:) = NaN;
  end
  
  %vertical axis range
  if nansum(VarData(:)) == 0; continue; end
  YLim = [min(VarData(:)),max(VarData(:))];
  YLim = YLim + [-1,1].*0.02.*range(YLim(:));
  
  
  %for some variable,s we need to shif the labelling
  LabelShift = -0.15;
  if strcmp(VarInfo{1},'ERA5') && strcmp(VarInfo{2},'U'); LabelShift = 0.55;end
  
  
  %prepare panel
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  subplot(ceil(numel(Settings.DataSets)./2),2,iVar)
  cla
  hold on
   
  %grid lines
  for iMonth=2:1:12;
    plot(datenum(2002,iMonth,[1,1]),YLim,'-','color',[1,1,1].*0.8)
  end
  
  %compute background stats
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %percentiles
  Percentiles = NaN(numel(Settings.Percentiles),365);
  for iDay=1:1:365;
    Percentiles(:,iDay) = prctile(VarData(:,iDay),Settings.Percentiles);
  end; clear iDay
  
  %median
  TheMedian = smoothn(nanmedian(VarData,1),Settings.ClimSmooth);

  
  %plot background stats
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %percentiles
  for iPair=1:1:floor(numel(Settings.Percentiles)/2)
  
    %extract the data
    y1 = Percentiles(iPair,      :);
    y2 = Percentiles(end-iPair+1,:);
    
    %plot the data
    x = [TimeScale(1:end),TimeScale(end:-1:1)];
    y = smoothn([y1,y2(end:-1:1)],Settings.ClimSmooth);
    
    Good =find(~isnan(x+y));
    
    patch(x(Good),y(Good),Settings.PCColours(iPair,:),'edgecolor','none');
      

  end; clear iPair
  
  %median
  plot(TimeScale,TheMedian,'k-','linewi',1)
  
  %zero line
  plot(TimeScale([1,end]),[0,0],'k--')
  
  %plot and mark special years
  for iYear=1:1:numel(Settings.SpecialYears)

    ThisYear = find(Years == Settings.SpecialYears(iYear));
    if nansum(VarData2(ThisYear,:)) == 0; continue; end
    
    ToPlot = VarData2(ThisYear,:);
    
    plot(TimeScale,ToPlot,'-','color',Settings.SpecialColours(iYear,:),'linewi',1)
    
    ypos = 0.9.*range(YLim)+YLim(1); 
    
    text(datenum(2002,5,2)+(iYear-1).*20,ypos,num2str(Settings.SpecialYears(iYear)),'color',Settings.SpecialColours(iYear,:),'fontweight','bold')
    
    plot(Settings.Minima(iYear),YLim(1)-0.03.*range(YLim), ...
         '^','MarkerSize',8, ...
         'color','k','markerfacecolor',Settings.SpecialColours(iYear,:),'clipping','off')
    plot(Settings.Minima(iYear),YLim(2)-0.*range(YLim), ...
          'v','MarkerSize',8, ...
          'color','k','markerfacecolor',Settings.SpecialColours(iYear,:))
    %     plot(Minima(iYear).*[1,1],YLim,':','color',SpecialColours(iYear,:),'linewi',.5)
  end
  
  %other labelling
  LatCentre = mean(Settings.LatRange{iVar});
  if LatCentre > 0; LatCentre = [num2str(abs(LatCentre)),'\pm',num2str(range(Settings.LatRange{iVar})./2),'N'];
  else;             LatCentre = [num2str(abs(LatCentre)),'\pm',num2str(range(Settings.LatRange{iVar})./2),'S'];
  end
  
  text(datenum(2002,12,30),LabelShift.*(YLim(2)-YLim(1))+YLim(2)-0.65.*(YLim(2)-YLim(1)),[LatCentre,' mean'],'color','k','HorizontalAlignment','right')
  %   text(datenum(2002,12,30),LabelShift.*(YLim(2)-YLim(1))+YLim(2)-0.65.*(YLim(2)-YLim(1)),[num2str(round(Settings.HeightLevel)),'km'],'color','k','HorizontalAlignment','right')
  
  %what years?
  switch VarInfo{1};
    case 'ERA5';  Period = '2002-2019';
    case 'SABER'; Period = '2002-2019';
    case 'AIRS';  Period = '2002-2019';
    case 'MLS';   Period = '2004-2019';
  end
  text(datenum(2002,12,30),LabelShift.*(YLim(2)-YLim(1))+YLim(2)-0.75.*(YLim(2)-YLim(1)),['z=',num2str(round(Settings.HeightLevel)),'km, ',Period],'HorizontalAlignment','right');
  
  %labelling
  ylabel([VarInfo{2},'  [',VarInfo{3},']'])
  
  %tidy axes
  datetick('x',3)
  box on
  set(gca,'ygrid','on','xgrid','off')
  set(gca,'tickdir','out','xtick',datenum(2002,1:1:12,15))
  xlim([datenum(2002,5,1),datenum(2002,12,31)])
  ylim(YLim)
  
  
  %title
  Title = ['(',Letters(iVar),') ',VarInfo{1},' ',VarInfo{4}];
  title(Title)
  
  %done!
  drawnow
  
  
end; clear iVar

%%
%shading colourbar
colormap(cat(1,Settings.PCColours,flipud(Settings.PCColours)))
cb = colorbar('position',[0.92,0.415,0.01,0.2]);
caxis([0,1].*100)
set(cb,'ytick',100.*(0:0.2:1))
% caxis([min(Settings.Percentiles),max(Settings.Percentiles)]./2)
cb.Label.String = 'Position in Climatology [%]';