clearvars


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%zonal mean plot settings file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% datasets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataSets{ 1} = 'AIRS';
Settings.InstName{ 1} = 'AIRS';
Settings.Variables{1} = 'MF';
Settings.Units{    1} = 'mPa';
Settings.FullName{ 1} = 'Momentum Flux';
Settings.LatRange{ 1} = [-60,-45]+[-2.5,2.5];
Settings.LonRange{ 1} = [-80,-60]+[-2,2];
Settings.Label{    1} = 'top';
Settings.Height{   1} = 30;

Settings.DataSets{ 2} = 'AIRS';
Settings.InstName{ 2} = 'AIRS';
Settings.Variables{2} = 'A';
Settings.Units{    2} = 'K';
Settings.FullName{ 2} = 'Wave Amplitude';
Settings.LatRange{ 2} = [-60,-45]+[-2.5,2.5];
Settings.LonRange{ 2} = [-80,-60]+[-2,2];
Settings.Label{    2} = 'top';
Settings.Height{   2} = 30;

Settings.DataSets{ 3} = 'MLS';
Settings.InstName{ 3} = 'MLS';
Settings.Variables{3} = 'MF';
Settings.Units{    3} = 'mPa';
Settings.FullName{ 3} = 'Momentum Flux';
Settings.LatRange{ 3} = [-60,-45]+[-2.5,2.5];
Settings.LonRange{ 3} = [-80,-60]+[-2,2];
Settings.Label{    3} = 'top';
Settings.Height{   3} = 30;

Settings.DataSets{ 4} = 'MLS';
Settings.InstName{ 4} = 'MLS';
Settings.Variables{4} = 'A';
Settings.Units{    4} = 'K';
Settings.FullName{ 4} = 'Wave Amplitude';
Settings.LatRange{ 4} = [-60,-45]+[-2.5,2.5];
Settings.LonRange{ 4} = [-80,-60]+[-2,2];
Settings.Label{    4} = 'top';
Settings.Height{   4} = 30;

Settings.DataSets{ 5} = 'AIRS';
Settings.InstName{ 5} = 'AIRS';
Settings.Variables{5} = 'Mz';
Settings.Units{    5} = 'mPa';
Settings.FullName{ 5} = 'Zonal Momentum Flux';
Settings.LatRange{ 5} = [-60,-45]+[-2.5,2.5];
Settings.LonRange{ 5} = [-80,-60]+[-2,2];
Settings.Label{    5} = 'bottom';
Settings.Height{   5} = 30;

Settings.DataSets{ 6} = 'AIRS';
Settings.InstName{ 6} = 'AIRS';
Settings.Variables{6} = 'Mm';
Settings.Units{    6} = 'mPa';
Settings.FullName{ 6} = 'Merid. Momentum Flux';
Settings.LatRange{ 6} = [-60,-45]+[-2.5,2.5];
Settings.LonRange{ 6} = [-80,-60]+[-2,2];
Settings.Label{    6} = 'top';
Settings.Height{   6} = 30;

%% special years
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%which years are special?
%all other years from 2002 to 2019 that we have data for locally will be the background
Settings.SpecialYears = [2002,2010,2019];

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
Settings.SmoothDays = 5; %main time series
Settings.ClimSmooth = 5; %climatology bands


%% run
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

plot_boxes