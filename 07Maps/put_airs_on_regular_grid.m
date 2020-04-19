

% put AIRS on a regular distance grid, same size as input.
% expect t to be XTxAT or XTxATxZ

% [lonout,latout,Tg,xt_spacing,at_spacing] = put_airs_on_regular_grid(lon,lat,t);

function varargout = put_airs_on_regular_grid(lon,lat,t)

% t = nc.Data.bt_4mu_pt(:,1:135);
% lon = nc.Data.lon(:,1:135);
% lat = nc.Data.lat(:,1:135);

type = length(size(t));

xt_mid = ceil(size(t,1)/2);

% first get ALONG TRACK spacing and azimuth:
[d_at,az_at] = distance(lat(xt_mid,1:end-1),lon(xt_mid,1:end-1),lat(xt_mid,2:end),lon(xt_mid,2:end));
az_at(end+1) = az_at(end);
d_at(end+1) = d_at(end);
at_spacing = mean(deg2km(d_at));
d_at = 0:at_spacing:(at_spacing*(size(t,2)-1));

% now get CROSS TRACK spacing:
[d_xt,az_xt] = distance(repmat(lat(xt_mid,:),size(t,1),1),repmat(lon(xt_mid,:),size(t,1),1),lat,lon);
d_xt = deg2km(mean(d_xt,2))';
d_xt(1:(xt_mid-1)) = -d_xt(1:(xt_mid-1));

% define new grid you want:
xt_vec = linspace(min(d_xt),max(d_xt),size(t,1));
at_vec = d_at;
[XT,AT] = ndgrid(xt_vec,at_vec);
xt_spacing = mean(diff(xt_vec));

% use reckon to find new lats and lons:
[latout,lonout] = reckon(repmat(lat(xt_mid,:),size(t,1),1),repmat(lon(xt_mid,:),size(t,1),1),km2deg(XT),repmat(az_at+90,size(t,1),1));

% interp each level:
ti = nan(size(t));
for z = 1:size(t,3)
    F = griddedInterpolant({d_xt,d_at},t(:,:,z),'linear','none');
    ti(:,:,z) = F({xt_vec,at_vec});
end

% send to outputs:
varargout{1} = lonout;
varargout{2} = latout;
varargout{3} = ti;
varargout{4} = xt_spacing;
varargout{5} = at_spacing;


end


