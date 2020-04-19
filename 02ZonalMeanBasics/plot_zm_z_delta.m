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
Settings.InFile = 'zm_data_polar_A.mat';


%how many colours
Settings.NColours = 32;

%which years are special?
SpecialYears = 2019;%2019;%[2002,2019];

%point out the minimum U time
% Minima(1) = datenum(2002,9,27);
Minima(1) = datenum(2019,9,14);

%and what are their colours?
SpecialColours(1,:) = [0.8,0,0];
% SpecialColours(2,:) = [0,0,1];

%how many days to smooth by?
Settings.SmoothDays = 3; %main time series
Settings.ClimSmooth = 5; %climatology bands



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and prep data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = load(Settings.InFile);
Data.Data = Data.Results.Data; Data = rmfield(Data,'Results');

Z = Data.Settings.HeightScale;
t = Data.Settings.TimeScale;
dd = date2doy(t);

%remove out of range data
for iVar=1:1:numel(Data.Settings.Vars)
  
  VarInfo = Data.Settings.Vars{iVar};
  switch VarInfo{1}
    case 'ECMWF'; Bad = []; 
    case 'SABER'; Bad = find(Z < 15);
    case 'MLS';   Bad = find(Z < 15);
    case 'AIRS';  Bad = find(Z < 20 | Z > 60);
    otherwise; disp('Var error');
  end
  
  Data.Data(iVar,:,Bad) = NaN;
  
  %also "fix" ozone into range
  if strcmp(VarInfo{2},'O3'); Data.Data(iVar,:,:) = Data.Data(iVar,:,:) .* 1e6; end
  
end
clear iVar VarInfo Bad

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% produce climatologies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Clima = Data.Data.*NaN;

for iVar=1:1:numel(Data.Settings.Vars);
  for iDay=1:1:365;
    %find mean over al years for this day of this var
    Clima(iVar,dd == iDay,:) = repmat(squeeze(nanmedian(Data.Data(iVar,dd == iDay,:),2)),1,numel(find(dd == iDay)))';
  end
  
  %smooth
  ThisVar = squeeze(Clima(iVar,:,:));
  Bad = find(isnan(ThisVar));
  ThisVar = smoothn(inpaint_nans(ThisVar),[Settings.ClimSmooth,1]);
  ThisVar(Bad) = NaN;
  Clima(iVar,:,:) = ThisVar;
end
clear iVar iDay dd ThisVar



Delta = (Data.Data - Clima);%./Clima.*100;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

iYear = 1;
Letters = 'abcdefghijklmnopqrstuvwxyz';

clf
set(gcf,'color','w')

for iVar=1:1:6
  
  %prep
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
  
  %%select time period to plot
  XLim = [datenum(SpecialYears(iYear),5,1),datenum(SpecialYears(iYear),12,31)];
  Xidx = inrange(t,XLim);
  
  %get data to plot
  ToPlot = squeeze(Delta(iVar,Xidx,:))';
  
  if nansum(ToPlot(:)) == 0; continue; end
    subplot(3,2,iVar)
  
  %smooth
  Bad = find(isnan(ToPlot));
  ToPlot = smoothn(inpaint_nans(ToPlot),[1,Settings.SmoothDays]);
  ToPlot(Bad) = NaN;
    
  %create axes
  cla
  axis([XLim 10 80])
  hold on
  colormap(cbrew('RdBu',Settings.NColours))
  
  %work out colour levels
  switch VarInfo{2}
    case   'T'; CLevels = -20:1:20;  LLevels = -100:10:100;
    case   'U'; CLevels = -20:1:20;  LLevels = -100:10:100;
    case 'O_3'; CLevels = -1:0.05:1; LLevels = -10:0.5:10;
  end
  caxis(CLevels([1,end]));
  ToPlot2 = ToPlot;  
  ToPlot2(ToPlot2 < min(CLevels)) = min(CLevels);
  
  %plot colour data
  contourf(XLim(1):1:XLim(2),Z,ToPlot2,CLevels,'edgecolor','none')
  
  %plot lines
  [c,h] = contour( XLim(1):1:XLim(2),Z, ToPlot,LLevels(LLevels > 0),'edgecolor',[1,1,1].*0.3,'linestyle', '-','linewi',0.25);
  clabel(c,h,'color','w');
  [c,h] = contour( XLim(1):1:XLim(2),Z, ToPlot,LLevels(LLevels < 0),'edgecolor',[1,1,1].*0.3,'linestyle','--','linewi',0.25);
  clabel(c,h,'color','w');  
  
  %tidy axes
  datetick('x',3)
  box on
  set(gca,'ygrid','on','xgrid','off')
  set(gca,'tickdir','out','xtick',datenum(SpecialYears(iYear),5:1:12,15))
   
  %colourbar
  cb = colorbar;
  cb.Label.String = ['\Delta from median [',VarInfo{3},']'];
  
  %ssw date
  plot(Minima(iYear),10, ...
       '^','MarkerSize',8, ...
       'color','k','markerfacecolor','k','clipping','off')
  plot(Minima(iYear),80, ...
       'v','MarkerSize',8, ...
       'color','k','markerfacecolor','k') 
  plot([1,1].*Minima(iYear),[10,80],'k-')
  
  
  %title
  Title = ['(',Letters(iVar),') ',VarInfo{1},' ',VarInfo{4}];
  title(Title)
  
  %done
  drawnow
  
end; clear iVar
