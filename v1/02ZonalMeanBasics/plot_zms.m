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
% merge;Settings.InFile = 'merged_zm.mat';
Settings.InFile = 'data/zm_data_polar_A.mat';

%which years are special?
SpecialYears = [2002,2010,2019];%,2010];

%point out the minimum U time
Minima(1) = 731486;
Minima(3) = 731473;
Minima(2) = 731426;

%and what are their colours?
SpecialColours(1,:) = [0.8,0,0];
SpecialColours(3,:) = [0,0,1];
SpecialColours(2,:) = [255,128,0]./255;

%what height level?
Settings.HeightLevel =  ceil(p2h(10));%30;

%what percentiles for the background shading? 
Settings.Percentiles = linspace(0,100,10);
Settings.PCColours   = colorGradient([1,1,1].*0.8,[1,1,1].*0.25,(numel(Settings.Percentiles))./2);
% Settings.PCColours   = colorGradient([229,204,255]./255,[76,0,153]./255,(numel(Settings.Percentiles))./2);


%how many days to smooth by?
Settings.SmoothDays = 1; %main time series
Settings.ClimSmooth = 5; %climatology bands


% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and prep data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = load(Settings.InFile);
Data.Data = Data.Results.Data; Data = rmfield(Data,'Results');

Z = Data.Settings.HeightScale;
t = Data.Settings.TimeScale;

[yy,~,~] = datevec(t);
Years = unique(yy);
dd = date2doy(t);

if numel(Data.Settings.LatRange) == 2;
  a = Data.Settings.LatRange;
  Data.Settings = rmfield(Data.Settings,'LatRange');
  for iV=1:1:numel(Data.Settings.Vars)
    Data.Settings.LatRange{iV} = a;
  end
  clear iV a
  
end


stop
%order of plots on page relative to input data
Settings.VarOrder = [1,5,2,4,6,-999];
% Settings.VarOrder = 1:1:numel(Data.Settings.Vars);
% Settings.VarOrder = [1,4,2,3,5,-999];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% remap data onto annual cycle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%drop day 366
Data.Data = Data.Data(:,dd ~=366,:);

%pad out to be full years
if numel(Years).*365 ~= size(Data.Data,2); stop; end %fix this later if needed

%smooth in time
Data.Data = smoothn(Data.Data,[1,Settings.SmoothDays,1]);

%reshape into years
Data.Data = permute(Data.Data,[1,3,2]);
sz = size(Data.Data);
Data.Data = reshape(Data.Data,sz(1),sz(2),365,numel(Years));

%find height level
zidx = closest(Data.Settings.HeightScale,Settings.HeightLevel);
Data.Data = squeeze(Data.Data(:,zidx,:,:));
clear zidx sz dd yy t Z

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Letters = 'abcdefghijklmnopqrstuvwxyz';

%prepare figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clf
set(gcf,'color','w')

for jVar=1:1:numel(Settings.VarOrder)
  
  %order how I want them on the page
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  iVar = Settings.VarOrder(jVar);
  
  if iVar == -999; continue; end
  
  
  %prep
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  VarData = squeeze(Data.Data(iVar,:,:));
  TimeScale = datenum(2002,1,1:1:365);
  VarInfo = Data.Settings.Vars{iVar};
  
  %classier/better names
  VarInfo{1} = strrep(VarInfo{1},'ECMWF','ERA5');     
  
  VarInfo{2} = strrep(VarInfo{2},'Rho','\rho');    
  VarInfo{2} = strrep(VarInfo{2},'O3','O_3');    
  
  VarInfo{4} = VarInfo{2};
  VarInfo{4} = strrep(VarInfo{4},'T','Temperature');  
  VarInfo{4} = strrep(VarInfo{4},'U','Zonal Wind');    
  VarInfo{4} = strrep(VarInfo{4},'O_3','Ozone Mixing Ratio');
  VarInfo{4} = strrep(VarInfo{4},'\rho','air density');
  
  if strcmp(VarInfo{2},'O_3')
    VarData = VarData.*1e6;
    VarInfo{3} = 'ppm';
  end
  
  
  %vertical axis range
  if nansum(VarData(:)) == 0; continue; end
  YLim = [min(VarData(:)),max(VarData(:))];
  YLim = YLim + [-1,1].*0.02.*range(YLim(:));
  
  
  %exclude special years from climatological calculations
  VarData2 = VarData;
  for iYear=1:1:numel(SpecialYears)
    yidx = closest(SpecialYears(iYear),Years);
    VarData(:,yidx) = NaN;
  end
  
  %for some variable,s we need to shif the labelling
  LabelShift = -0.15;
  if strcmp(VarInfo{1},'ERA5') && strcmp(VarInfo{2},'U'); LabelShift = 0.55;end
%   if strcmp(VarInfo{1},'SABER') == 1;  YLim = [190 260]; end 
  
  
  %prepare panel
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  subplot(ceil(numel(Data.Settings.Vars)./2),2,jVar)
%   subplot(numel(Data.Settings.Vars),1,jVar)
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
    Percentiles(:,iDay) = prctile(VarData(iDay,:),Settings.Percentiles);
  end; clear iDay
 
  %median
  TheMedian = smoothn(nanmedian(VarData,2),Settings.ClimSmooth);
  
% % %   %mean
% % %   TheMean = nanmean(VarData,2);
  

  %plot background stats
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
  %percentiles
  for iPair=1:1:floor(numel(Settings.Percentiles)/2)
    
    %check for discontinuous sections and plot them separately
    %this is primarily necessary due to the SABER yaw cycle
    LineData = sum([Percentiles(iPair,1:end);Percentiles(end-iPair+1,end:-1:1)],1);
    Good = find(~isnan(LineData));
    if numel(Good) == 0; continue; end
    dGood = sort([1,find(diff(Good) > 1),find(diff(Good) > 1)+1,],'asc');
    Discon = [Good(dGood),max(Good)];
    Discon = reshape(Discon,2,numel(Discon)./2);
     
    for iChunk=1:1:size(Discon,2);

      %get start and end of segment
      Start = Discon(1,iChunk);
      End   = Discon(2,iChunk);
      
      %extract the data for the segment
      y1 = Percentiles(iPair,      Start:End);
      y2 = Percentiles(end-iPair+1,Start:End);
      if nansum(y1+y2) == 0; continue; end
      
      %plot the data
      x = [TimeScale(Start:1:End),TimeScale(End:-1:Start)];
      y = smoothn([y1,y2(end:-1:1)],Settings.ClimSmooth);
      
      patch(x,y,Settings.PCColours(iPair,:),'edgecolor','none');
      
      
    end; clear iChunk Start End y1 y2 x y
    clear Good Discon dGood LineData
  end; clear iPair
 
  %median
  plot(TimeScale,TheMedian,'k-','linewi',1)
  
% % %   %mean
% % %   plot(TimeScale,TheMean,'k--','linewi',1)
  
  %zero line
  plot(TimeScale([1,end]),[0,0],'k--')

  %plot and mark special years
  for iYear=1:1:numel(SpecialYears)
    
    if SpecialYears(iYear) == 2002 & strcmp(VarInfo{1},'MLS') == 1; continue; end
    
    ThisYear = find(Years == SpecialYears(iYear));
    plot(TimeScale,VarData2(:,ThisYear),'-','color',SpecialColours(iYear,:),'linewi',1)

    
    ypos = 0.9.*range(YLim)+YLim(1); %LabelShift.*(YLim(2)-YLim(1))+YLim(2)-(YLim(2)-YLim(1)).*0.1.*iYear - 0.65.*(YLim(2)-YLim(1));
    
    
    text(datenum(2002,5,2)+(iYear-1).*20,ypos,num2str(SpecialYears(iYear)),'color',SpecialColours(iYear,:),'fontweight','bold')
    
    plot(Minima(iYear),YLim(1)-0.03.*range(YLim), ...
         '^','MarkerSize',8, ...
         'color','k','markerfacecolor',SpecialColours(iYear,:),'clipping','off')
    plot(Minima(iYear),YLim(2)-0.*range(YLim), ...
         'v','MarkerSize',8, ...
         'color','k','markerfacecolor',SpecialColours(iYear,:)) 
%     plot(Minima(iYear).*[1,1],YLim,':','color',SpecialColours(iYear,:),'linewi',.5)
  end
  
  %other labelling
  LatCentre = mean(Data.Settings.LatRange{iVar});
  if LatCentre > 0; LatCentre = [num2str(abs(LatCentre)),'\pm',num2str(range(Data.Settings.LatRange{iVar})./2),'N'];
  else              LatCentre = [num2str(abs(LatCentre)),'\pm',num2str(range(Data.Settings.LatRange{iVar})./2),'S'];
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
  Title = ['(',Letters(jVar),') ',VarInfo{1},' ',VarInfo{4}];
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