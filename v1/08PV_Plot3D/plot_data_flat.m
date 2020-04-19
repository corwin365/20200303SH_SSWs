

clear all; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and prep data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

File = 'winter2002.nc';
Data = rCDF(File);

Var = Data.pv;
Lon = Data.longitude;
Lat = Data.latitude;
Z   = p2h(Data.level);
Time = datenum(1900,1,1,Data.time,0,0);

clear Data

% get height axis and choose range
InHeightRange = find(Z > 15 & Z < 45);
Var = squeeze(Var(:,:,InHeightRange,:));
Z = Z(InHeightRange);

%timestep
TimeStep = closest(Time,datenum(2006,9,1))
Var = squeeze(Var(:,:,:,TimeStep));

%duplicate end element
Lon(end+1) = Lon(1);
Var(end+1,:,:) = Var(1,:,:);

clear File InHeightRange TimeStep 

%compute distance and angle from pole, as this is a better coord than lat
%and lon for a region like this
[xi,yi] = meshgrid(Lon,Lat);

[dx,th] = distance(ones(size(xi)).*0,ones(size(xi)).*-90,xi,yi);
% clear xi yi

figure(1)
pc(dx,th,squeeze(Var(:,:,5))')

figure(2)
pc(xi,yi,squeeze(Var(:,:,5))')


