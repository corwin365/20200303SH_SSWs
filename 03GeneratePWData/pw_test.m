
clearvars

load foom.mat

Field = zeros(37,361,7);
zidx = 10;


for iWave=1:1:7;
  k = (iWave-1);
  for iLat=1:1:size(Field,1);
    Field(iLat,:,iWave) =  PWs.Amp(iWave,zidx,iLat).*cosd(k.*(0:1:360) + PWs.Phase(iWave,zidx,iLat));
  end
end

pc(0:1:360,PWs.Lat,Field(:,:,2))