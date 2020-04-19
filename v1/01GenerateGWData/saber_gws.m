clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%get GWs from SABER data
%Corwin Wright, c.wright@bath.ac.uk, 12/APR/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataDir     = [LocalDataDir,'/SABER/rawnc-v2'];
Settings.TimeScale   = datenum(2002,1,1):1:datenum(2019,12,31);
Settings.HeightScale = 10:1:70;
Settings.OutDir      = [LocalDataDir,'/corwin/gws_saber/'];

Settings.PWs.TimeWindow = 1; %days
Settings.PWs.N          = 6; %mode to go down to
Settings.PWs.Lat        = 5; %degrees of lat per band



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OldData.Name = ''; %avoid duplicate loading

for iDay=1:1:numel(Settings.TimeScale)
  try
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %done already?
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  disp(datestr(Settings.TimeScale(iDay)))
  OutFile = [Settings.OutDir,'/gws_',num2str(Settings.TimeScale(iDay)),'.mat'];
%    if exist(OutFile); disp('Already done'); continue;end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %get data in time window
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  clear Store
  for jDay=-floor(Settings.PWs.TimeWindow./2):1:floor(Settings.PWs.TimeWindow./2)
    
    %find file for this month
    ThisMonthDay = wildcardsearch(Settings.DataDir,['*',datestr(Settings.TimeScale(iDay)+jDay,'mmmmyyyy'),'*']);
    if strcmp(ThisMonthDay,OldData.Name) ~=1;
      
      %record
      OldData.Name = ThisMonthDay{1};
      
      %load the file
      MonthData = rCDF(ThisMonthDay{1},1);
      
      
      %convert the data to useful units
      MonthData.date = double(MonthData.date);
      MonthData.time = double(MonthData.time);
      sz = size(MonthData.time,1);
      yyyy = repmat(floor(MonthData.date./1000)',sz,1);
      ddd  = repmat((MonthData.date)',sz,1) - yyyy.*1000;
      ss   = MonthData.time./1000;
      MonthData.Time = datenum(yyyy,1,ddd,0,0,ss);
      clear yyyy ddd ss
      
      %fix longitudes
      MonthData.tplongitude(MonthData.tplongitude > 180) = MonthData.tplongitude(MonthData.tplongitude > 180)-360;
      
      %remove bad data
      MonthData.tplatitude( MonthData.tplatitude  <  -90) = NaN;
      MonthData.tplongitude(MonthData.tplongitude < -180) = NaN;  
      MonthData.tplatitude( MonthData.tplatitude  >   90) = NaN;
      MonthData.tplongitude(MonthData.tplongitude >  180) = NaN; 
      MonthData.tpaltitude(  MonthData.tpaltitude >  150) = NaN;
      MonthData.tpaltitude(  MonthData.tpaltitude <    0) = NaN;
      MonthData.ktemp(       MonthData.ktemp      >  500) = NaN;
      MonthData.ktemp(       MonthData.ktemp      <    0) = NaN;      
      
      %tidy up variable space
      MonthData = rmfield(MonthData,{'tpgpaltitude','orbit','date','time','tpSolarLT','tpSolarZen','MetaData'});
    end
    
    %pull out the data for this period
    OnThisDay = find(nanmean(MonthData.Time,1) >= Settings.TimeScale(iDay) - floor(Settings.PWs.TimeWindow./2) ...
                   & nanmean(MonthData.Time,1) <  Settings.TimeScale(iDay) + floor(Settings.PWs.TimeWindow./2) +1);

                     
    if numel(OnThisDay) == 0; continue; end

    Data = struct();
    Fields = fieldnames(MonthData);
    for iField=1:1:numel(Fields);
      Field = MonthData.(Fields{iField});
      Field = Field(:,OnThisDay);
      Data.(Fields{iField}) = Field;
    end
    clear iField Field Fields OnThisDay
     
    if ~exist('Store')
      Store.T   = Data.ktemp;
      Store.Lat = nanmean(Data.tplatitude,1)';
      Store.Lon = nanmean(Data.tplongitude,1)';
      Store.Z   = nanmean(Data.tpaltitude,2);
      Store.t   = nanmean(Data.Time,1)';
    else
      Store.T    = cat(2,Store.T,  Data.ktemp);
      Store.Lat  = cat(1,Store.Lat,nanmean(Data.tplatitude,1));
      Store.Lon  = cat(1,Store.Lon,nanmean(Data.tplongitude,1)); 
      Store.t    = cat(1,Store.t,  Data.Time);       
    end

  end
  if ~exist('Store'); continue; end
  Data = Store;
  clear Store jDay yy dn Path File
   
  
  %regularise in height
  Data.Z = inpaint_nans(double(Data.Z));
  Data.T = interp1(Data.Z,Data.T,Settings.HeightScale);
  Data.Z = Settings.HeightScale';
  

  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %remove PWs
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  %produce PW map
  %%%%%%%%%%%%%%%%%%
    
  
  %produce mesh
  [xi,yi] = meshgrid(-180:30:180,-90:Settings.PWs.Lat:90);
  Store = NaN([size(xi),numel(Data.Z)]);
  
  %produce storage array
  PWs.Lat   = yi(:,1);
  PWs.Z     = Settings.HeightScale;
  PWs.Modes = 0:1:Settings.PWs.N;
  PWs.Amp   = NaN(numel(PWs.Modes),numel(PWs.Z),numel(PWs.Lat));
  PWs.Phase = PWs.Amp;
  
  for iLevel=1:1:numel(Data.Z);
    
    %produce map
    zz = bin2mat(Data.Lon,Data.Lat,double(Data.T(iLevel,:)),xi,yi,'@nanmean');

    %find top fourier modes
    zzF = fft(inpaint_nans(zz),[],2);
    Amp = abs(zzF(:,1:Settings.PWs.N+1)./size(zz,2));
    Pha = rad2deg(angle(zzF(:,1:Settings.PWs.N+1)));
    clear zzF

    %if a latitude circle is completely empty, then remove the data we
    %interpolated into it
    Empty = find(nansum(zz,2) == 0);
    Amp(Empty,:) = NaN;
    Pha(Empty,:) = NaN;
    clear Empty
    
    %store
    PWs.Amp(  :,iLevel,:) = Amp';
    PWs.Phase(:,iLevel,:) = Pha';


    %reconstruct the PW field
    Field = zz.*0; 
    for iWave=1:1:Settings.PWs.N+1;
      k = (iWave-1);
      for iLat=1:1:size(Field,1);     
        Field(iLat,:) = Field(iLat,:) + Amp(iLat,iWave).*cosd(k.*(0:30:360) + Pha(iLat,iWave));
      end
    end
    
    %fill any NaNs (they'll be in regions with no profiles anywya - jsut
    %makes the computational logic simpler)
    Field = inpaint_nans(Field);
    
    Store(:,:,iLevel) = Field;
    
  end


  %interpolate back to profiles and remove
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  [xi,yi,zi] =ndgrid(-180:30:180,-90:Settings.PWs.Lat:90,Data.Z);
  I = griddedInterpolant(xi,yi,zi,permute(Store,[2,1,3]));
  Tpw = I(repmat(Data.Lon,[1,size(Data.Z)]), ...
          repmat(Data.Lat,[1,size(Data.Z)]), ...
          single(repmat(Data.Z,[1,size(Data.Lat)]))')';
        
  Data.Tp = Data.T - Tpw;
  Data.BG = Tpw;

  %tidy up
  clear xi yi zi I Tpw Field Store iWave iLevel zz Amp Pha k iLat

    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %s-transform
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
  %create storage arrays for amplitude and phase
  Store.A = NaN(size(Data.T)); %amplitude
  Store.P = Store.A;           %along-track phase change
  Store.L = Store.A;           %vertical wavelength
  
  for iProf=2:1:size(Data.T,2)
    
    %s-transform profile-pair
    STa = nph_ndst(inpaint_nans(double(squeeze(Data.Tp(:,iProf-1)))));
    STb = nph_ndst(inpaint_nans(double(squeeze(Data.Tp(:,iProf  )))));
    
    %find complex cospectrum
    STcc = STa.ST .* conj(STb.ST);
    
    %find amplitude distribution and delta-phase distribution
    A = sqrt(abs(STcc));
    P = angle(STcc);
    
    %find maximum amplitude at each height
    [~,idx] = max(A,[],1);
    
    %hence, pull out relvant amplitude and phase change
    for iLevel=1:1:size(Store.A,1);
      Store.A( iLevel,iProf) = A(idx(iLevel),iLevel);
      Store.P( iLevel,iProf) = P(idx(iLevel),iLevel);
      Store.Lz(iLevel,iProf) = 1./STa.freqs(idx(iLevel));
    end
    

  end
  clear iProf STa STb STcc A P idx iLevel

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %convert to gephysical properties
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
  
  %find along-track distance between profiles
  %assume no slant - not the best assumption...
  a = [Data.Lat,Data.Lon];
  b = circshift(a,[1,0]);
  dX = nph_haversine(a,b);
  dX([1,end]) = NaN;
  
  %if the difference is more than 300km, then we can't use the MF or Lh
  Bad = find(dX > 300);
  dX(Bad) = NaN;
  
  
  %hence, convert phase change to wavelength
  Store.P = Store.P ./ (2*pi);
%   Store.P(abs(Store.P) < Settings.MinP) = NaN;
  Store.Lh = abs(repmat(dX,[1,size(Store.P,1)])' ./ Store.P);
  Store = rmfield(Store,'P');
  clear dX a b
  
  %MF
  Store.MF = cjw_airdensity(h2p(Data.Z),Data.BG)./2  ...
         .*  (9.81/0.02).^2                             ...
         .*  (Store.A./Data.BG).^2                       ...
         .*  (Store.Lz./Store.Lh);
       
  Store.Lon = Data.Lon;
  Store.Lat = Data.Lat;
  Store.Z   = Data.Z;
       
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %save!
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
  

  save(OutFile,'Store','PWs')
  clear OutFile Data
  catch;end
end
