

clear all; 


%% load data

File = 'winter2002.nc';
Data = rCDF(File);

Var = Data.pv;
Lon = Data.longitude;
Lat = -Data.latitude;
Z   = p2h(Data.level);
Time = datenum(1900,1,1,Data.time,0,0);

clear Data


%% get height axis and choose range
InHeightRange = find(Z > 15 & Z < 45);
Var = squeeze(Var(:,:,InHeightRange,:));
Z = Z(InHeightRange);

StretchFactor = 30;
Shift = 20;
Z = (Z-Shift).*StretchFactor;

%timestep
TimeStep = closest(Time,datenum(2006,9,1))
Var = squeeze(Var(:,:,:,TimeStep));


%duplicate end element
Lon(end+1) = Lon(1);
Var(end+1,:,:) = Var(1,:,:);



%normalise
for iLevel=1:1:size(Var,3);
  Lev = Var(:,:,iLevel);
  Lev = Lev ./ nanmean(abs(Lev(:)));
  Var(:,:,iLevel) = Lev;
end
clear iLevel Lev

%surface is out by 90 deg, shift atmosphere to compensate
Lon = Lon-90; Lon = wrapTo180(Lon);

%convert to x,y,z
[latg,long,zg] = ndgrid(deg2rad(Lat),deg2rad(Lon),Z.*1000);
[Out.x,Out.y,Out.z] = lla2ecef(latg,long,zg);
clear long zg Prs Lat Lon Z InHeightRange
Var = permute(Var,[2,1,3]);


Out.Var = Var;


%smooth
Out.Var = smoothn(Out.Var,[5,5,1]);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot globe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf

Earth.npanels = 180;   % Number of globe panels around the equator deg/panel = 360/npanels
Earth.alpha   = 1;     % globe transparency level, 1 = opaque, through 0 = invisible
Earth.GMST0   = 4.9;   % Set up a rotatable globe at J2000.0
% Earth.Image = imread('land_ocean_ice_cloud_2048.png');
% Earth.Image = imread('D:\Data\topography\imagery\land_ocean_ice_2048.jpg');
Earth.Image = flipud(imread([LocalDataDir,'/topography/imagery/faded.jpg']));

% Mean spherical earth
Earth.erad    = 6371008.7714; % equatorial radius (meters)
Earth.prad    = 6371008.7714; % polar radius (meters)
Earth.erot    = 7.2921158553e-5; % earth rotation rate (radians/sec)


clf
hold on;
axis([-1 1 -1 1 -1 1].*1e7)
axis vis3d;
set(gcf,'Color','w');
set(gca,'visible','off') % no axes

[x, y, z] = ellipsoid(0, 0, 0, Earth.erad, Earth.erad, Earth.prad, Earth.npanels);
globe = surf(x, y, -z, 'FaceColor', 'none', 'EdgeColor', 0.5*[1 1 1]);
hgx = hgtransform;
set(hgx,'Matrix', makehgtform('zrotate',Earth.GMST0));
set(globe,'Parent',hgx);
clear hgx
set(globe, 'FaceColor', 'texturemap', 'CData', Earth.Image , 'FaceAlpha', Earth.alpha, 'EdgeColor', 'none');

% %mark the poles
% plot3([0,0],[0,0],[-1,1].*1.1.*nanmax(z(:)),'o','markersize',10,'color','k','markerfacecolor','k')



clear x y z

%set terrain to not reflect light specularly
set(globe,'DiffuseStrength',1,'SpecularStrength',0)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%plot
hold on
% view([84.7998046875 72.7998046875])
camlight
view([90 0])
camzoom(1.5)
camlight('right'); camlight('left')
view([30-90 75])


Levels = 0.5:-0.25:-2;%,0.85];
Alpha = ones(size(Levels)).*0.8;%[0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.25]+0.1;
Colours = cbrew('RdYlGn',numel(Levels));
for iLev=1:1:numel(Levels);
  fv = isosurface(Out.x,Out.y,Out.z,Out.Var,Levels(iLev));
  ThePatch = patch(fv);
  ThePatch.FaceColor = Colours(iLev,:);%[65,105,225]./255;  
  ThePatch.EdgeColor = 'none';
  ThePatch.FaceAlpha  = Alpha(iLev);
  ThePatch.FaceLighting = 'gouraud';
  drawnow
end

% % % % Levels = 1.25:0.1:1.35;%0.2:0.1:0.9;
% % % % Alpha = [0.6,0.6,0.6,0.6,0.6,0.6,0.6,0.25]+0.1;
% % % % 
% % % % for iLev=1:1:numel(Levels);
% % % %   fv = isosurface(Out.x,Out.y,Out.z,Out.Var,Levels(iLev));
% % % %   ThePatch = patch(fv);
% % % %   ThePatch.FaceColor = [255,10,0]./255;
% % % %   ThePatch.EdgeColor = 'none';
% % % %   ThePatch.FaceAlpha  = Alpha(iLev);
% % % %   ThePatch.FaceLighting = 'gouraud';
% % % % end
% % % % % view([30 75])
% % % % 
% % % % 
