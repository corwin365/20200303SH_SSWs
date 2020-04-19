clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%get GWs and PWs from MLS data
%Corwin Wright, c.wright@bath.ac.uk, 04/MAR/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataDir     = [LocalDataDir,'/MLS/'];
Settings.TimeScale   = datenum(2004,8,10):1:datenum(2020,12,31);
Settings.HeightScale = 14:2:90;
Settings.OutDir      = [LocalDataDir,'/corwin/gws_mls/'];

Settings.PWs.TimeWindow = 1; %days
Settings.PWs.N          = 6; %mode to go down to
Settings.PWs.Lat        = 2.5; %degrees of lat per band



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    
    %find file for this day
    [yy,~,~] = datevec(Settings.TimeScale(iDay)+jDay);
    dn = date2doy(Settings.TimeScale(iDay)+jDay);
    Path = [Settings.DataDir,'/',sprintf('%04d',yy),'/'];
    File = wildcardsearch(Path,['*d',sprintf('%03d',dn),'*']);
    if numel(File) == 0; continue; end
    Data = get_MLS(File{1},'Temperature-StdProd');
    
    Data.Time = datenum(1993,1,1,0,0,Data.Time);
  
    if ~exist('Store')
      Store.T   = Data.L2gpValue;
      Store.Lat = Data.Latitude;
      Store.Lon = Data.Longitude;
      Store.Z   = p2h(Data.Pressure);
      Store.t   = Data.Time;
    else
      Store.T    = cat(2,Store.T,  Data.L2gpValue);
      Store.Lat  = cat(1,Store.Lat,Data.Latitude);
      Store.Lon  = cat(1,Store.Lon,Data.Longitude); 
      Store.t    = cat(1,Store.t,  Data.Time);       
    end

  end
  if ~exist('Store'); continue; end
  Data = Store;
  clear Store jDay yy dn Path File
   
  %regularise in height
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
  
  %store the planetary waves separately
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  


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
  %cut data down to just this day
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
  
  OnThisDay = find(floor(Data.t) == Settings.TimeScale(iDay));
  Data.T   = Data.T( :,OnThisDay);
  Data.Tp  = Data.Tp(:,OnThisDay);
  Data.BG  = Data.BG(:,OnThisDay);
  Data.Lat = Data.Lat(OnThisDay);
  Data.Lon = Data.Lon(OnThisDay);
  Data.t   = Data.t(  OnThisDay);
  clear OnThisDay
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %s-transform
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
  %create storage arrays for amplitude and phase
  Store.A = NaN(size(Data.T)); %amplitude
  Store.P = Store.A;           %along-track phase change
  Store.L = Store.A;           %vertical wavelength
  
  for iProf=2:1:size(Data.T,2)
    
    %s-transform profile-pair
    STa = nph_ndst(squeeze(Data.Tp(:,iProf-1)));
    STb = nph_ndst(squeeze(Data.Tp(:,iProf  )));
    
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
  %assume no slant - this is reasonable as the MLS retrieval should remove
  %the biggest effects due to this
  a = [Data.Lat,Data.Lon];
  b = circshift(a,[1,0]);
  dX = nph_haversine(a,b);
  dX([1,end]) = NaN;
  
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
