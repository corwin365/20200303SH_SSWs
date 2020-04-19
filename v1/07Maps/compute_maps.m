% clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%generate maps of basic variables
%
%Corwin Wright, c.wright@bath.ac.uk, 08/APR/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%which year?
Settings.Year = 2002;

%which dataset?

Settings.DataSet = 'ECMWF';

%gridding?
Settings.LatScale    = -90:1.5:-30;
Settings.LonScale    = -180:1.5:180;
Settings.TimeScale   = datenum(Settings.Year,1,1):1:datenum(Settings.Year,12,31);
Settings.HeightScale = 20:10:60;

%data storage
Settings.DataDir.Ecmwf = [LocalDataDir,'/ERA5/'];
Settings.DataDir.Saber = [LocalDataDir,'/SABER/rawnc-v2/'];
Settings.DataDir.Airs  = [LocalDataDir,'/AIRS/3d_airs/'];
Settings.DataDir.Mls   = [LocalDataDir,'/MLS/'];


%variables and sources
if strcmp(Settings.DataSet,'ECMWF')
  %'Instrument','Output Variable Name'
  Settings.Vars{1} = {'ECMWF','U','m/s'};
  Settings.Vars{2} = {'ECMWF','T','K'};
elseif strcmp(Settings.DataSet,'SABER')
  Settings.Vars{1} = {'SABER','T','K'};
  Settings.Vars{2} = {'SABER','Rho','mol/cm^3'};
  Settings.Vars{3} = {'SABER','O3','no units'};
elseif strcmp(Settings.DataSet,'AIRS')
  Settings.Vars{1} = {'AIRS', 'T','K'};
elseif strcmp(Settings.DataSet,'MLS')
  Settings.Vars{1} = {'MLS','T','K'};
  Settings.Vars{2} = {'MLS','O3','no units'};
else
  stop
end
  
%'Instrument','Output Variable Name'





  
%where to put the data?
Settings.OutFile = ['data/rawmaps_',Settings.DataSet,'_',num2str(Settings.Year),'.mat']



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create needed variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Results.Data = NaN(numel(Settings.Vars),        ...
                   numel(Settings.TimeScale),   ...
                   numel(Settings.HeightScale), ...
                   numel(Settings.LonScale),    ...
                   numel(Settings.LatScale));

[xi,yi] = meshgrid(Settings.LonScale,Settings.LatScale);                 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% loop over and import data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%don't reload a file if it's not necessary
OldFilePath.Ecmwf = '';
OldFilePath.Saber = '';

for iDay=1:1:numel(Settings.TimeScale)
  disp(datestr(Settings.TimeScale(iDay)))
  
  for iVar=1:1:numel(Settings.Vars)
%   try
    
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

        %take daily mean
        VarData = nanmean(VarData,4);
        
        %loop over levels and grid data
        for iLevel=1:1:numel(Settings.HeightScale);
          zidx = closest(Settings.HeightScale(iLevel),Data.ECMWF.Z);
          
          
          x = Data.ECMWF.longitude;
          y = Data.ECMWF.latitude;
          v = squeeze(VarData(:,:,zidx))';
          
          zz = interp2(x,y,v,xi,yi);

          %and store
          Results.Data(iVar,iDay,iLevel,:,:) = zz';
        end
      
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
        Useful = inrange(Data.SABER.MatlabTime(50,:),Settings.TimeScale(iDay)+[0,1]);
        if numel(Useful) == 0; clear Useful; continue; end

        %pull out data
        switch VarInfo{2}
          case 'T';   VarData = Data.SABER.ktemp(  :,Useful);
          case 'Rho'; VarData = Data.SABER.density(:,Useful);
          case 'O3';  VarData = Data.SABER.O3_96(:,Useful);  VarData(VarData > 1e-5) = NaN; %bad data            
          otherwise; disp('Variable not specified');stop;
        end
        
        VarData(VarData == -999) = NaN;
        
        
        
        %loop over levels and grid data
        for iLevel=1:1:numel(Settings.HeightScale);
          zidx = closest(Settings.HeightScale(iLevel),nanmean(Data.SABER.tpaltitude,2));
          
          
          x = Data.SABER.tplatitude( zidx,Useful);
          y = Data.SABER.tplongitude(zidx,Useful);
          y(y > 180) = y(y > 180)-360;
          v = squeeze(VarData(zidx,:));
          
          zz = bin2mat(double(x),double(y),double(v),xi,yi);

          %and store
          Results.Data(iVar,iDay,iLevel,:,:) = zz';

        end        
        
        
      case 'AIRS'; 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %AIRS 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         
   
        %load all AIRS data for this day
        Data.AIRS.Lat = NaN(240,135,90);
        Data.AIRS.Lon = NaN(240,135,90);        
        Data.AIRS.T   = NaN(240,135,90,27);
        
        for iGranule=1:1:240;
          
          %load data
          [Airs,~,Error] = prep_airs_3d(Settings.TimeScale(iDay),iGranule,'LoadOnly',true);
          if Error ~= 0; continue; end
          
          %store data
          Data.AIRS.Lat(iGranule,:,:)   = Airs.l1_lat';
          Data.AIRS.Lon(iGranule,:,:)   = Airs.l1_lon';          
          Data.AIRS.T(  iGranule,:,:,:) = permute(Airs.ret_temp,[3,2,1]); 
          Data.AIRS.Z = [0;3;6;9;12;15;18;21;24;27;30;33;36;39;42;45;48;51;54;57;60;65;70;75;80;85;90];
          
        end; clear iGranule Airs Error
       
        if nansum(Data.AIRS.T(:)) == 0; continue; end
       
        %reshape
        sz = size(Data.AIRS.T);
        Data.AIRS.T   = reshape(Data.AIRS.T,  sz(1)*sz(2)*sz(3),sz(4));
        Data.AIRS.Lat = reshape(Data.AIRS.Lat,sz(1)*sz(2)*sz(3),1);
        Data.AIRS.Lon = reshape(Data.AIRS.Lon,sz(1)*sz(2)*sz(3),1);        
        clear sz

        
        %loop over levels and grid data
        for iLevel=1:1:numel(Settings.HeightScale);
          zidx = closest(Settings.HeightScale(iLevel),Data.AIRS.Z(1,:,1,1));

          
          x = Data.AIRS.Lon;
          y = Data.AIRS.Lat;
          v = squeeze(Data.AIRS.T(:,zidx));
          

          %and store
          Results.Data(iVar,iDay,iLevel,:,:) = bin2mat(double(x),double(y),double(v),xi,yi,'@nanmean')';
        end
        clear iLevel zidx Night x y v VarData



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
        
        %loop over levels and grid data
        for iLevel=1:1:numel(Settings.HeightScale);
          zidx = closest(Settings.HeightScale(iLevel),p2h(Data.Pressure));
          
          
          x = Data.Longitude;
          y = Data.Latitude;
          v = squeeze(Data.L2gpValue(zidx,:));
          

          %and store
          Results.Data(iVar,iDay,iLevel,:,:) = bin2mat(double(x),double(y),double(v),xi,yi,'@nanmean')';
        end
        clear x y v VarData iLevel zidx
        

        
        
      otherwise; disp('Dataset not specified');stop;
    end
    
    clear VarInfo

%   catch;end
  end; clear iVar

  
end; clear iDay

save(Settings.OutFile,'Results','Settings')
disp('Complete')
