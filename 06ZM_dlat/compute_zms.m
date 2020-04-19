clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%generate zonal mean time series of basic variables, as a function of
%latitude
%
%Corwin Wright, c.wright@bath.ac.uk, 03/MAR/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%where to put the data?
Settings.OutFile = 'zm_data_dlat_E.mat';


%gridding?
Settings.LatScale    = -90:2.5:-30;
Settings.TimeScale   = datenum(2002,1,1):1:datenum(2019,12,31);
Settings.HeightScale = 0:2.5:80;

%data storage
Settings.DataDir.Ecmwf = [LocalDataDir,'/ERA5/'];
Settings.DataDir.Saber = [LocalDataDir,'/SABER/rawnc-v2/'];
Settings.DataDir.Airs  = [LocalDataDir,'/AIRS/3d_airs/'];
Settings.DataDir.Mls   = [LocalDataDir,'/MLS/'];


%variables and sources
%'Instrument','Output Variable Name'
 Settings.Vars{1} = {'ECMWF','U','m/s'};
 Settings.Vars{2} = {'ECMWF','T','K'};
% Settings.Vars{1} = {'SABER','T','K'};
% Settings.Vars{2} = {'SABER','Rho','mol/cm^3'};
% Settings.Vars{3} = {'SABER','O3','no units'};
%  Settings.Vars{6} = {'AIRS', 'T','K'};
% Settings.Vars{1} = {'MLS','T','K'};
% Settings.Vars{2} = {'MLS','O3','no units'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create needed variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Results.Data = NaN(numel(Settings.Vars),        ...
                   numel(Settings.TimeScale),   ...
                   numel(Settings.HeightScale), ...
                   numel(Settings.LatScale));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% loop over and import data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%don't reload a file if it's not necessary
OldFilePath.Ecmwf = '';
OldFilePath.Saber = '';

for iDay=1:1:numel(Settings.TimeScale)
  disp(datestr(Settings.TimeScale(iDay)))
  
  for iVar=1:1:numel(Settings.Vars)
  try
    
    %get variable info
    VarInfo = Settings.Vars{iVar};
    disp(['---> ',VarInfo{1},' - ',VarInfo{2}])
    
    switch VarInfo{1}
      case 'ECMWF';
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %ECMWF
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %get the data
        [yy,~,~] = datevec( Settings.TimeScale(iDay));
        dn       = date2doy(Settings.TimeScale(iDay));
        FilePath = [Settings.DataDir.Ecmwf, ...
                    '/',sprintf('%04d',yy), ...
                    '/era5_',sprintf('%04d',yy),'d',sprintf('%03d',dn),'.nc'];
        if ~exist(FilePath); continue; end
        
        if strcmp(FilePath,OldFilePath.Ecmwf) ~= 1;
          Data.ECMWF = rCDF(FilePath);
          Data.ECMWF.Z = p2h(ecmwf_prs_v2([],137));
          OldFilePath.Ecmwf = FilePath;
        end
        clear FilePath
        
        
        %pull out the var we want
        switch VarInfo{2}
          case 'U'; VarData = Data.ECMWF.u;
          case 'T'; VarData = Data.ECMWF.t;
          otherwise; disp('Variable not specified');stop;
        end
        
        %grid by height and lat
        [xi,zi] = meshgrid(Settings.LatScale,Settings.HeightScale);
        x = Data.ECMWF.latitude;
        z = Data.ECMWF.Z;
        [x,z] = meshgrid(x,z);
        
        sz = size(VarData);
        VarData = reshape(permute(VarData,[3,2,1,4]),sz(3),sz(2),sz(1)*sz(4));
        x = repmat(x,1,1,sz(1)*sz(4));
        z = repmat(z,1,1,sz(1)*sz(4));
        
        zz = inpaint_nans(bin2matN(2,x(:),z(:),VarData(:),xi,zi,'@nanmean'));
        
        %store
        Results.Data(iVar,iDay,:,:) = zz;
        
        clear xi zi x z VarData sz yy dn zz
         
      case 'SABER';
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %SABER
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %find and load file
        [yy,~,~] = datevec(Settings.TimeScale(iDay));
        mmmm = datestr(Settings.TimeScale(iDay),'mmmm');
        FileName = wildcardsearch(Settings.DataDir.Saber,['*',mmmm,sprintf('%04d',yy),'*']);
        clear yy mmmm
        if numel(FileName) == 0; continue; end
        if strcmp(FileName{1},OldFilePath.Saber) ~= 1;
          
          %load file
          Data.SABER = cjw_readnetCDF(FileName{1},1);
          
          %convert timestamps
          Data.SABER.MatlabTime = double(Data.SABER.time .* NaN);
          for iTime=1:1:size(Data.SABER.time,2);
            
            Year    = floor(double(Data.SABER.date(iTime))/1000.);
            Day     = double(Data.SABER.date(iTime))-Year*1000.;
            Seconds = double(Data.SABER.time(:,iTime)/1000.);
            
            Data.SABER.MatlabTime(:,iTime) = datenum(Year,1,Day,0,0,Seconds);
            clear Year Day Seconds
          end; clear iTime
          OldFilePath.Saber = FileName{1};
        end
        
        %find points on this day and in this lat band
        OnThisDay = inrange(Data.SABER.MatlabTime(50,:),Settings.TimeScale(iDay)+[0,1]);
        InThisLat = inrange(Data.SABER.tplatitude(50,:),Settings.LatRange);
        Useful = intersect(OnThisDay,InThisLat);
        clear OnThisDay InThisLat
        if numel(Useful) == 0; clear Useful; continue; end

        %pull out data
        switch VarInfo{2}
          case 'T';   VarData = Data.SABER.ktemp(  :,Useful);
          case 'Rho'; VarData = Data.SABER.density(:,Useful);
          case 'O3';  VarData = Data.SABER.O3_96(:,Useful);  VarData(VarData > 1e-5) = NaN; %bad data            
          otherwise; disp('Variable not specified');stop;
        end
        
        VarData(VarData == -999) = NaN;
        
        %take zonal mean
        VarData = nanmean(VarData,2);
        
        %interpolate to output scale
        Z = double(nanmean(Data.SABER.tpaltitude,2));
        GoodZ = find(Z > 15 & Z < 150);
        Results.Data(iVar,iDay,:) = interp1(Z(GoodZ),VarData(GoodZ),Settings.HeightScale);
        
        clear Z GoodZ VarData Useful
        
        
      case 'AIRS'; 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %AIRS (only T in files)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         
        
        %load all AIRS data for this day
        Data.AIRS.Lat = NaN(240,135,90);
        Data.AIRS.T   = NaN(240,135,90,27);
        
        for iGranule=1:1:240;
          
          %load data
          [Airs,~,Error] = prep_airs_3d(Settings.TimeScale(iDay),iGranule,'LoadOnly',true);
          if Error ~= 0; continue; end
          
          %store data
          Data.AIRS.Lat(iGranule,:,:)   = Airs.l1_lat';
          Data.AIRS.T(  iGranule,:,:,:) = permute(Airs.ret_temp,[3,2,1]); 
          Data.AIRS.Z = [0;3;6;9;12;15;18;21;24;27;30;33;36;39;42;45;48;51;54;57;60;65;70;75;80;85;90];
          
        end; clear iGranule Airs Error
       
        if nansum(Data.AIRS.T(:)) == 0; continue; end
       
        %reshape
        sz = size(Data.AIRS.T);
        Data.AIRS.T   = reshape(Data.AIRS.T,  sz(1)*sz(2)*sz(3),sz(4));
        Data.AIRS.Lat = reshape(Data.AIRS.Lat,sz(1)*sz(2)*sz(3),1);
        clear sz
        
        %pull out region and take zonal mean
        T = nanmean(Data.AIRS.T(inrange(Data.AIRS.Lat,Settings.LatRange),:),1);
        
        %store
        Results.Data(iVar,iDay,:) = interp1(Data.AIRS.Z,T,Settings.HeightScale);
        
        clear T
        
        
      case 'MLS'; 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %MLS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%          
        
        %find file for this day
        [yy,~,~] = datevec(Settings.TimeScale(iDay));
        dn = date2doy(Settings.TimeScale(iDay));
        Path = [Settings.DataDir.Mls,'/',sprintf('%04d',yy),'/'];
        File = wildcardsearch(Path,['*d',sprintf('%03d',dn),'*']);
        clear yy dn
        if numel(File) == 0; continue; end
        
        %identify product
        switch VarInfo{2}
          case 'T';  Var = 'Temperature-StdProd';
          case 'O3'; Var = 'O3-StdProd';
          otherwise; disp('Variable not specified');stop;
        end
        
        %load file
        Data = get_MLS(File{1},Var);
        
        
        %pull out region and take zonal mean
        InRegion = inrange(Data.Latitude,Settings.LatRange);
        Z = p2h(Data.Pressure);
        Data = nanmean(Data.L2gpValue(:,InRegion),2);
        
        %interp and store
        Results.Data(iVar,iDay,:) = interp1(Z,Data,Settings.HeightScale); 
        clear InRegion Data Z Var File

        
      otherwise; disp('Dataset not specified');stop;
    end
    
    clear VarInfo

  catch;end
  end; clear iVar
  
  if mod(iDay,30) == 0;
    save(Settings.OutFile,'Results','Settings')
    disp('==========Saved!============')
  end
  
end; clear iDay

save(Settings.OutFile,'Results','Settings')
disp('Complete')
