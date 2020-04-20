% clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%generate zonal mean time series of GW variables
%
%Corwin Wright, c.wright@bath.ac.uk, 03/MAR/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%which year?
Settings.Year = YEAR;%2002;

%which dataset?
Settings.DataSet = 'MLS';

%gridding?
Settings.LatScale    = -90:5:-40;
Settings.LonScale    = -180:5:180;
Settings.TimeScale   = datenum(Settings.Year,1,1):1:datenum(Settings.Year,12,31);
Settings.HeightScale = 20:10:60;

%data storage
% Settings.DataDir.Ecmwf = [LocalDataDir,'/ERA5/'];
Settings.DataDir.Saber = [LocalDataDir,'/corwin/saber_manfred/'];
Settings.DataDir.Airs  = [LocalDataDir,'/corwin/sh_ssw/'];
Settings.DataDir.Mls   = [LocalDataDir,'/corwin/gws_mls/'];


%variables and sources
if strcmp(Settings.DataSet,'MLS')
  %'Instrument','Output Variable Name'
  Settings.Vars{1} = {'MLS','A','K'};
  Settings.Vars{2} = {'MLS','Lz','km'};
  Settings.Vars{3} = {'MLS','Lh','km'};
  Settings.Vars{4} = {'MLS','MF','mPa'};
elseif strcmp(Settings.DataSet,'AIRS')
  Settings.Vars{1} = {'AIRS','A','K'};
  Settings.Vars{2} = {'AIRS','Lz','km'};
  Settings.Vars{3} = {'AIRS','Lh','km'};
  Settings.Vars{4} = {'AIRS','Mz','mPa'};
  Settings.Vars{5} = {'AIRS','Mm','mPa'};
  Settings.Vars{6} = {'AIRS','MF','mPa'};
elseif strcmp(Settings.DataSet,'SABER')
  Settings.Vars{1} = {'SABER','MF','mPa'};
  Settings.Vars{2} = {'SABER','A','K'};
else
  stop
end
  
  
%where to put the data?
Settings.OutFile = ['../data/maps_',Settings.DataSet,'_',num2str(Settings.Year),'.mat']



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
OldFilePath.Airs = '';
Data = struct(); Data.Saber = struct();

for iDay=1:1:numel(Settings.TimeScale)
  disp(datestr(Settings.TimeScale(iDay)))
  
  for iVar=1:1:numel(Settings.Vars)
%   try
    
    %get variable info
    VarInfo = Settings.Vars{iVar};
    disp(['---> ',VarInfo{1},' - ',VarInfo{2}])
    
    switch VarInfo{1}
        
      case 'SABER';
        
% % % % % % % % % % %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % % % % % % %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % % % % % % %         %SABER
% % % % % % % % % % %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % % % % % % %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % % % % % % %         
% % % % % % % % % % %         %are we in the time range Manfred gave me?
% % % % % % % % % % %         if Settings.TimeScale(iDay) < datenum(2002,8,30) ...
% % % % % % % % % % %          | Settings.TimeScale(iDay) > datenum(2002,10,23)
% % % % % % % % % % %           continue
% % % % % % % % % % % % % % %           %temporary - stick the gracile climatology in if we have no more specific data
% % % % % % % % % % % % % % %           [yy,~,~] = datevec(Settings.TimeScale(iDay));
% % % % % % % % % % % % % % %           if yy > 2014; continue; end
% % % % % % % % % % % % % % %           
% % % % % % % % % % % % % % %           if ~isfield(Data.Saber,'Gracile')
% % % % % % % % % % % % % % %             %load gracile
% % % % % % % % % % % % % % %             Data.Saber.Gracile = rCDF('C:\Data\SABER\GRACILE_HIRDLS_SABER_GW_climatology.nc');
% % % % % % % % % % % % % % %           end
% % % % % % % % % % % % % % %           
% % % % % % % % % % % % % % %            InLatRange = inrange(Data.Saber.Gracile.lat_grid_zav_SABER,Settings.LatRange);
% % % % % % % % % % % % % % %            dn = date2doy(Settings.TimeScale(iDay));
% % % % % % % % % % % % % % %            TimeID = yy + dn./365;
% % % % % % % % % % % % % % %            tidx = closest(TimeID,Data.Saber.Gracile.time_grid_zav_series_SABER);
% % % % % % % % % % % % % % %            if      strcmp(VarInfo{2},'MF') ~= 1
% % % % % % % % % % % % % % %              ThisMonth = squeeze(nanmean(Data.Saber.Gracile.gwmf_zav_series_SABER_Pa(InLatRange,:,tidx),1)).*1000;
% % % % % % % % % % % % % % %            elseif  strcmp(VarInfo{2},'A') ~= 1
% % % % % % % % % % % % % % %              ThisMonth = sqrt(squeeze(nanmean(Data.Saber.Gracile.gw_temp_ampsq_single_zav_series_SABER(InLatRange,:,tidx),1)));
% % % % % % % % % % % % % % %            end
% % % % % % % % % % % % % % %            Results.Data(iVar,iDay,:) = interp1(Data.Saber.Gracile.z_grid_zav_SABER,ThisMonth,Settings.HeightScale);
% % % % % % % % % % % 
% % % % % % % % % % %         end
% % % % % % % % % % %         
% % % % % % % % % % %         %files only contain MF
% % % % % % % % % % %         if strcmp(VarInfo{2},'MF') ~= 1; continue; end
% % % % % % % % % % %         
% % % % % % % % % % %         %manfred gave me five-daily files
% % % % % % % % % % %         %find the most recent of these periods from this date
% % % % % % % % % % %         Files = datenum(2002,8,30):5:datenum(2002,10,19);
% % % % % % % % % % %         Delta = Settings.TimeScale(iDay) - Files;
% % % % % % % % % % %         [~,idx] = min(Delta(Delta > 0));
% % % % % % % % % % %         File  = Files(idx);
% % % % % % % % % % %         [yy,mm,dd] = datevec(File);
% % % % % % % % % % %         FileString = ['*',sprintf('%02d',yy-2000),sprintf('%02d',mm),sprintf('%02d',dd),'*'];
% % % % % % % % % % %         File = wildcardsearch(Settings.DataDir.Saber,FileString);
% % % % % % % % % % %         pause(0.2)
% % % % % % % % % % %         clear Files Delta yy mm dd FileString idx
% % % % % % % % % % %         if numel(File) == 0; clear File; continue; end
% % % % % % % % % % %         
% % % % % % % % % % %         %load file
% % % % % % % % % % %         Data.Saber = rCDF(File{1});
% % % % % % % % % % %         clear File
% % % % % % % % % % %         Data.Saber.z = 30; %km
% % % % % % % % % % %         
% % % % % % % % % % %         %clean up empty vars
% % % % % % % % % % %         Data.Saber.gwmf_saber_mpa(Data.Saber.gwmf_saber_mpa == -999) = NaN;
% % % % % % % % % % %         
% % % % % % % % % % %         %extract zonal mean of interest, interpolate to scale, and store
% % % % % % % % % % %         InLatRange = inrange(Data.Saber.lat,Settings.LatRange);
% % % % % % % % % % %         Line = (nanmean(nanmean(Data.Saber.gwmf_saber_mpa(:,InLatRange,:),2),1));
% % % % % % % % % % %         
% % % % % % % % % % %         
% % % % % % % % % % %         Results.Data(iVar,iDay,:) = repmat(Line,1,numel(Results.Data(iVar,iDay,:)));
        
      case 'AIRS'; 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %AIRS 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         
   
        %load file for this day
        DayFile = [Settings.DataDir.Airs,'/gws_',num2str(Settings.TimeScale(iDay)),'.mat'];
        if strcmp(DayFile,OldFilePath.Airs) ~= 1;
          %load file
          if ~exist(DayFile); continue;end
          Data.Airs = load(DayFile);
          OldFilePath.Airs = DayFile;
          
          
          %prepare data for later use
          sz = size(Data.Airs.Results.A);
          Data.Airs.Results.P  = h2p(Data.Airs.Results.Z);
          Data.Airs.Results.Z  = repmat(permute(Data.Airs.Results.Z,[2,1]),sz(1),1,sz(3),sz(4));
          Data.Airs.Results.P  = repmat(permute(Data.Airs.Results.P,[2,1]),sz(1),1,sz(3),sz(4));       
          clear sz
          
         
        end


        %extract desired vars
        switch VarInfo{2}
          case 'A';   VarData = Data.Airs.Results.A;
          case 'Lz';  VarData = 1./Data.Airs.Results.m;
          case 'Lh';  VarData = 1./quadadd(Data.Airs.Results.k,Data.Airs.Results.l);
          case 'Mz';  VarData = -1000.*cjw_airdensity(Data.Airs.Results.P,Data.Airs.Results.BG)./2  ...
                             .*  (9.81/0.02).^2                             ...
                             .*  (Data.Airs.Results.A./Data.Airs.Results.BG).^2                       ...
                             .*  (Data.Airs.Results.k./Data.Airs.Results.m);
          case 'Mm';  VarData = -1000.*cjw_airdensity(Data.Airs.Results.P,Data.Airs.Results.BG)./2  ...
                             .*  (9.81/0.02).^2                             ...
                             .*  (Data.Airs.Results.A./Data.Airs.Results.BG).^2                       ...
                             .*  (Data.Airs.Results.l./Data.Airs.Results.m);
          case 'MF';  VarData = 1000.*cjw_airdensity(Data.Airs.Results.P,Data.Airs.Results.BG)./2  ...
                             .*  (9.81/0.02).^2                             ...
                             .*  (Data.Airs.Results.A./Data.Airs.Results.BG).^2                       ...
                             .*  (quadadd(Data.Airs.Results.k,Data.Airs.Results.l)./Data.Airs.Results.m);
          otherwise; disp('Variable error'); stop;
        end       

        
        %loop over levels and grid data
        for iLevel=1:1:numel(Settings.HeightScale);
          zidx = closest(Settings.HeightScale(iLevel),Data.Airs.Results.Z(1,:,1,1));
          
          Night = find(Data.Airs.Results.DayNight == 0);
          
          x = Data.Airs.Results.Lon(Night);
          y = Data.Airs.Results.Lat(Night);
          v = squeeze(VarData(:,zidx,:,:)); v = v(Night);
          

          %and store. GEOMETRIC MEAN.
          Results.Data(iVar,iDay,iLevel,:,:) = exp(bin2mat(double(x),double(y),log(double(v)),xi,yi,'@nanmean'))';
        end
        clear iLevel zidx Night x y v VarData



      case 'MLS'; 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %MLS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%          

        %find the file for this day
        InFile = [Settings.DataDir.Mls,'/gws_',num2str(Settings.TimeScale(iDay)),'.mat'];
        if ~exist(InFile); continue; end
        
        %load data
        Data = load(InFile); Data = Data.Store;

        %choose variable
        VarData = Data.(VarInfo{2});
        
        %special case of remove outliers
        if strcmp(VarInfo{2},'Lh') == 1; VarData(VarData > 15000) = NaN; end
        
        %loop over levels and grid data
        for iLevel=1:1:numel(Settings.HeightScale);
          zidx = closest(Settings.HeightScale(iLevel),Data.Z);
          
          
          x = Data.Lon;
          y = Data.Lat;
          v = squeeze(VarData(zidx,:));
          

          %and store
          
          %arithmetic mean
%            Results.Data(iVar,iDay,iLevel,:,:) = bin2mat(double(x),double(y),double(v),xi,yi,'@nanmean')';
          
          %geometric mean
          Results.Data(iVar,iDay,iLevel,:,:) = exp(bin2mat(double(x),double(y),log(double(v)),xi,yi,'@nanmean'))';

          %median
%            Results.Data(iVar,iDay,iLevel,:,:) = bin2mat(double(x),double(y),double(v),xi,yi,'@nanmedian')';
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
