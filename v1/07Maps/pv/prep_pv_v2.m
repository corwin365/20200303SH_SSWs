clearvars

DataDir = [LocalDataDir,'/ERA5/pv'];
SpecialYears = [];%[2002,2010,2019];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 'metadata'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Meta.DataSet = 'ECMWFpv';
Meta.TimeScale = 1:1:365;
Meta.HeightScale = p2h([1,2,10,50,250]); %km, approximately
Meta.Vars{1} = {'ECMWF','PV','UNITS'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load, grid and store data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Years = 2018:2019;%2002:1:2019;

for iYear=1:1:numel(Years);
  disp(Years(iYear))
  
  %loop over days and create data
  clear PVDATA
  for iDay = 1:1:365;  
    FileName = [DataDir,'/era5_pv_',num2str(Years(iYear)),'d',sprintf('%03d',iDay),'.nc'];
    if ~exist(FileName); continue; end
    dat = rCDF(FileName);
    
    %take daily mean
    dat.pv = nanmean(dat.pv,4);
    
    %store
    if ~exist('PVDATA');
      Meta.LonScale         = dat.longitude;
      Meta.LatScale         = dat.latitude;
      PVDATA.pv(iDay,:,:,:) = dat.pv;
    else
      PVDATA.pv(iDay,:,:,:) = dat.pv;
    end
    

    
  end
  if size(PVDATA.pv,1) < 365;
    PVDATA.pv(365,:,:,:) = NaN;
  end
  
  %create annual file
  Settings = Meta;
  Settings.Year = Years(iYear);
  Settings.TimeScale = datenum(Settings.Year,1,1:1:365);
  
  Results.Data = permute(PVDATA.pv,[5,1,4,2,3]);
  Results.Data(2,:,:,:,:) = NaN; %dummy

  
  %store
  save(['../data/rawmaps_ECMWFpv_',num2str(Settings.Year),'.mat'], ...
       'Settings','Results')

  %climatology?
  if any(SpecialYears == Years(iYear)); continue; end
  
  if ~exist('AllStore');
    AllStore = Results.Data;
    AllDays  = 1:1:365;
  else
    AllStore = cat(2,AllStore,Results.Data);
    AllDays  = cat(2,AllDays,1:1:365);
  end
  
  clear ThisYear ddY PV iDay idx xi yi Settings Results
     
end


%climatology!
for iDay=1:1:365;
  AllStore(:,iDay,:,:,:) = nanmean(AllStore(:,AllDays == iDay,:,:,:),2);
end
AllStore = AllStore(:,1:1:365,:,:,:);

%create file
Settings = Meta;
Settings.Year = 999;
Settings.TimeScale = 1:1:365;

Results.Data = AllStore;
  
%store
save(['../data/rawmaps_ECMWFpv_clim.mat'], ...
      'Settings','Results')

