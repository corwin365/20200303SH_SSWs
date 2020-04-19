clearvars


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.Instrument = 'MLS';
Settings.TimeScale  = datenum(2002,1,1):1:datenum(2019,12,31);
Settings.Lat        = -60;
Settings.Heights    = 10:10:90;
Settings.Modes      = 0:1:6;
Settings.OutFile    = ['pws_',Settings.Instrument,'.mat'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create results arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Results = NaN(numel(Settings.Heights),   ...
              numel(Settings.Modes),     ...
              numel(Settings.TimeScale), ...
              2);  %amplitude, phase

            
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
  
  %find latitude
  latidx = closest(Data.PWs.Lat,Settings.Lat);
  
  %loop over heights
  for iLevel=1:1:numel(Settings.Heights)
    
    %find level
    zidx = closest(Data.PWs.Z,Settings.Heights(iLevel));

    %pull out and store amplitude and phase
    Results(iLevel,:,iDay,1) = Data.PWs.Amp(  :,zidx,latidx);
    Results(iLevel,:,iDay,2) = Data.PWs.Phase(:,zidx,latidx);

    
  end; clear iLevel
  
  
  clear Data DayFile
  
  
end; clear iDay
textprogressbar(100); textprogressbar('!')

save(Settings.OutFile,'Settings','Results')
