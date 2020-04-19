clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%generate maps of PW mode amplitudes
%
%Corwin Wright, c.wright@bath.ac.uk, 15/APR/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%where's the data
SABER = load('pws_maps_SABER.mat');
MLS   = load('pws_maps_MLS.mat');

%what modes?
Modes = [1,2,3]; 

%longitude grid?
Lon = -180:5:180;

%levels?
Levels = [30,40];

%latitude range?
LatRange = [-90,-20];

%which years are special?
SpecialYears = [2002,2010,2019];%,2010];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% processing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  
  for iInst=1:1:2;
    
    
    for Year=2002:1:2019;
      
      %get data
      switch iInst
        case 1; Data = SABER; InstName = 'SABER';
        case 2; Data = MLS;   InstName = 'MLS';
      end
      
      disp([InstName,' ' ,num2str(Year)])
      
      %split out year
      [yy,~,~] = datevec(Data.Settings.TimeScale);
      ThisYear = find(yy == Year);
      Data.Results = Data.Results(:,:,:,ThisYear,:);
      clear ThisYear yy
      
      %pull out desired modes
      Amplitude = squeeze(Data.Results(:,:,Modes+1,:,1));
      Phase     = squeeze(Data.Results(:,:,Modes+1,:,2));
      
      %and levels
      levidx = NaN(numel(Levels),1);
      for iLevel=1:1:numel(Levels);
        levidx(iLevel) = closest(Levels(iLevel),Data.Settings.Heights);
      end
      
      Amplitude = Amplitude(levidx,:,:,:,:);
      Phase     = Phase(    levidx,:,:,:,:);
      clear levidx
      
      
      %expand out in longitude
      sz = size(Amplitude);
      Lons = repmat(Lon',[1,sz]);
      
      Amp = permute(repmat(Amplitude,1,1,1,1,numel(Lon)),[5,1,2,3,4]);
      Pha = permute(repmat(Phase,    1,1,1,1,numel(Lon)),[5,1,2,3,4]);
      
      sz = size(Amp);
      ModeN = permute(repmat(Modes',[1,sz([1:3,5])]),[2,3,4,1,5]);
      
      
      %produce waves
      Waves = -Amp .* cosd(ModeN.*Lons + Pha);
      clear sz Lons Amp Pha Amplitude Phase ModeN
      
      
      %cut out desired region
      Waves = Waves(:,:,inrange(Data.Settings.Lats,LatRange),:,:);
      
      %reformat and store
      clear Settings
      
      Settings.Year        = Year;
      Settings.DataSet     = InstName;
      Settings.LatScale    = Data.Settings.Lats(inrange(Data.Settings.Lats,LatRange));
      Settings.LonScale    = Lon;
      Settings.TimeScale   = datenum(Year,1,1:1:365);
      Settings.HeightScale = Levels;
      Settings.OutFile = ['../07Maps/data/rawmaps_',InstName,'pw_',num2str(Year),'.mat'];
      for iMode=1:1:numel(Modes);
        Settings.Vars{iMode} = {InstName,['PW mode ',num2str(Modes(iMode))],'K'};
      end;
      Settings.Vars{numel(Modes)+1} = {InstName,['Sum of PWs'],'K'};
      
      
      Results.Data = permute(Waves,[4,5,2,1,3]);
      Results.Data(end+1,:,:,:,:) = nansum(Results.Data,1); %sum of modes
      
      
      save(Settings.OutFile,'Settings','Results')
      
      
      %retain data for climatology
      if any(Year == SpecialYears); continue;
      else
        if ~exist('All');
          All.Data = Results.Data(:,1:365,:,:,:);
        else
          All.Data = cat(6,All.Data,Results.Data(:,1:365,:,:,:));
        end
      end
      
    end; clear Year
    
    
    %instrument complete: store climatology

    All.StD  = nanstd(All.Data,[],6);
    All.Data = nanmean(All.Data,6);
    Results.Data = All.Data;
    Results.StD  = All.StD;
    Settings.TimeScale = 1:1:365;
    Settings.Year = 'clim';
    Settings.OutFile = ['../07Maps/data/rawmaps_',InstName,'pw_clim.mat'];
    save(Settings.OutFile,'Settings','Results')
    clear All
    
  end; clear iInst