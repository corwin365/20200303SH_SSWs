clearvars


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%zonal mean plot settings file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%where's the data
Settings.DataSets{ 1} = 'MLS';
Settings.Variables{1} = 'O3';
Settings.Units{    1} = 'ppm';
Settings.FullName{ 1} = 'Ozone Mixing Ratio';
Settings.Scale{    1} = 1e6;
Settings.LatRange{ 1} = [-65,-55];


Settings.DataSets{ 2} = 'MLSpw';
Settings.Variables{2} = 'Sum of PWs';
Settings.Units{    2} = 'K';
Settings.FullName{ 2} = 'Sum of PWs mode 1-3';
Settings.LatRange{ 2} = [-65,-55];
Settings.Label{    2} = 'top';

Settings.DataSets{ 3} = 'ECMWF';
Settings.Variables{3} = 'T';
Settings.Units{    3} = 'K';
Settings.FullName{ 3} = 'Temperature';
Settings.LatRange{ 3} = [-65,-55];
Settings.Label{    3} = 'bottom';

Settings.DataSets{ 4} = 'ECMWF';
Settings.Variables{4} = 'U';
Settings.Units{    4} = 'm/s';
Settings.FullName{ 4} = 'Zonal Wind Speed';
Settings.LatRange{ 4} = [-65,-55];
Settings.Label{    4} = 'top';

Settings.DataSets{ 5} = 'SABER';
Settings.Variables{5} = 'MF';
Settings.Units{    5} = 'mPa';
Settings.FullName{ 5} = 'Momentum Flux';
Settings.LatRange{ 5} = [-50,-45];
Settings.Label{    5} = 'top';

%which years are special?
%all other years from 2002 to 2019 that we have data for locally will be the background
Settings.SpecialYears = [2002,2010,2019];%,2010];

%point out the minimum U time
Settings.Minima(1) = 731486;
Settings.Minima(2) = 731426;
Settings.Minima(3) = 731473;

%and what are their colours?
Settings.SpecialColours(1,:) = [0.8,0,0];
Settings.SpecialColours(2,:) = [255,128,0]./255;
Settings.SpecialColours(3,:) = [0,0,1];

%what height level?
Settings.HeightLevel =  30;

%what percentiles for the background shading? 
Settings.Percentiles = linspace(0,100,10);
Settings.PCColours   = colorGradient([1,1,1].*0.8,  ...
                                     [1,1,1].*0.25, ...
                                     (numel(Settings.Percentiles))./2);

%how many days to smooth by?
Settings.SmoothDays = 3; %main time series
Settings.ClimSmooth = 3; %climatology bands


%do it!
plot_zms