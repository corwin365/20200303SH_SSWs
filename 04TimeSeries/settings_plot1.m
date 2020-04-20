clearvars


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%zonal mean plot settings file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% datasets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataSets{ 1} = 'ECMWF';
Settings.InstName{ 1} = 'ERA5';
Settings.Variables{1} = 'U';
Settings.Units{    1} = 'm/s';
Settings.FullName{ 1} = 'Zonal Wind Speed';
Settings.LatRange{ 1} = [-65,-55];
Settings.Label{    1} = 'top';
Settings.Height{   1} = 30;

Settings.DataSets{ 2} = 'MLS';
Settings.InstName{ 2} = 'MLS';
Settings.Variables{2} = 'O3';
Settings.Units{    2} = 'ppm';
Settings.FullName{ 2} = 'Ozone Mixing Ratio';
Settings.Scale{    2} = 1e6;
Settings.LatRange{ 2} = [-65,-55];
Settings.Label{    2} = 'bottom';
Settings.Height{   2} = 30;

Settings.DataSets{ 3} = 'ECMWF';
Settings.InstName{ 3} = 'ERA5';
Settings.Variables{3} = 'T';
Settings.Units{    3} = 'K';
Settings.FullName{ 3} = 'Temperature';
Settings.LatRange{ 3} = [-65,-55];
Settings.Label{    3} = 'bottom';
Settings.Height{   3} = 30;

Settings.DataSets{ 4} = 'MLS';
Settings.InstName{ 4} = 'MLS';
Settings.Variables{4} = 'T';
Settings.Units{    4} = 'K';
Settings.FullName{ 4} = 'Temperature';
Settings.LatRange{ 4} = [-65,-55];
Settings.Label{    4} = 'bottom';
Settings.Height{   4} = 30;

Settings.DataSets{ 5} = 'AIRS';
Settings.InstName{ 5} = 'AIRS';
Settings.Variables{5} = 'T';
Settings.Units{    5} = 'K';
Settings.FullName{ 5} = 'Temperature';
Settings.LatRange{ 5} = [-65,-55];
Settings.Label{    5} = 'bottom';
Settings.Height{   5} = 30;

Settings.DataSets{ 6} = 'SABER';
Settings.InstName{ 6} = 'SABER';
Settings.Variables{6} = 'T';
Settings.Units{    6} = 'K';
Settings.FullName{ 6} = 'Temperature';
Settings.LatRange{ 6} = [-50,-45];
Settings.Label{    6} = 'top';
Settings.Height{   6} = 30;


%% special years
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%which years are special?
%all other years from 2002 to 2019 that we have data for locally will be the background
Settings.SpecialYears = 2010;%[2002,2010,2019];

%point out the minimum U time for each year
Settings.Minima(1) = 731486;
Settings.Minima(2) = 731426;
Settings.Minima(3) = 731473;

%and what are their colours?
Settings.SpecialColours(1,:) = [0.8,0,0];
Settings.SpecialColours(2,:) = [255,128,0]./255;
Settings.SpecialColours(3,:) = [0,0,1];

%% other
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%what percentiles for the background shading? 
Settings.Percentiles = linspace(0,100,10);
Settings.PCColours   = colorGradient([1,1,1].*0.8,  ...
                                     [1,1,1].*0.25, ...
                                     (numel(Settings.Percentiles))./2);

%how many days to smooth by?
Settings.SmoothDays = 3; %main time series
Settings.ClimSmooth = 3; %climatology bands


%% run
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

plot_zms