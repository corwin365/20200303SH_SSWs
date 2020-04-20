%  clearvars


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%  Settings.Instrument = 'MLS';
Settings.TimeScale  = datenum(2002,1,1):1:datenum(2019,12,31);
Settings.Heights    = 0:5:60;
Settings.Modes      = 0:1:3;
Settings.OutFile    = ['pws_maps_',Settings.Instrument,'.mat'];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% core loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

textprogressbar(['Merging ',Settings.Instrument,' data '])
for iDay=1:1:numel(Settings.TimeScale)
  if mod(iDay,100) == 0; textprogressbar(iDay./numel(Settings.TimeScale).*100);end
  
  %identify file
  DayFile = [LocalDataDir,'/corwin/gws_',lower(Settings.Instrument),'/gws_',num2str(Settings.TimeScale(iDay)),'.mat'];

  if ~exist(DayFile,'file'); clear DayFile; continue; end
  
  %load file
  Data = load(DayFile);
  
  
  %if first loop, extract lat scale and create results arrays
  if ~exist('Results')
  
    Settings.Lats = Data.PWs.Lat;
    Results = NaN(numel(Settings.Heights),   ...
                  numel(Settings.Lats),      ...
                  numel(Settings.Modes),     ...
                  numel(Settings.TimeScale), ...
                  2);  %amplitude, phase
  end

  
  
  %loop over heights
  for iLevel=1:1:numel(Settings.Heights)
    
    %find level
    zidx = closest(Data.PWs.Z,Settings.Heights(iLevel));

    %pull out and store amplitude and phase
    Results(iLevel,:,:,iDay,1) = squeeze(Data.PWs.Amp(  Settings.Modes+1,zidx,:))';
    Results(iLevel,:,:,iDay,2) = squeeze(Data.PWs.Phase(Settings.Modes+1,zidx,:))';

    
  end; clear iLevel
  
  clear Data DayFile
  
  
end; clear iDay
textprogressbar(100); textprogressbar('!')

save(Settings.OutFile,'Settings','Results')
