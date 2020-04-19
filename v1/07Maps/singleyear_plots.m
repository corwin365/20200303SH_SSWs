for MasterHeight = 30;%[30,40,20]
  
  for MasterYear = [0,2002,2019,2018:-1:2003];%[2019,2002];%,0,2003:1:2018];
    
    for iCombo =20:-1:1

      clearvars -except MasterYear iCombo MasterHeight;

      
      switch iCombo
        case 1
          Settings.Instrument  = 'ECMWFdpv';
          Settings.Var         = 'dPV';
        case 2;
          Settings.Instrument  = 'ECMWFpv';
          Settings.Var         = 'PV';
        case 3;
          Settings.Instrument  = 'ECMWF';
          Settings.Var         = 'U';
        case 4;
          Settings.Instrument  = 'ECMWF';
          Settings.Var         = 'T';
        case 5;
          Settings.Instrument  = 'MLS';
          Settings.Var         = 'O3';
        case 6;
          Settings.Instrument  = 'MLS';
          Settings.Var         = 'MF';
        case 7;
          Settings.Instrument  = 'MLS';
          Settings.Var         = 'A';    
        case 8;
          Settings.Instrument  = 'SABER';
          Settings.Var         = 'MF';
        case 9;
          Settings.Instrument  = 'SABER';
          Settings.Var         = 'A';  
        case 10;
          Settings.Instrument  = 'AIRS';
          Settings.Var         = 'MF';
        case 11;
          Settings.Instrument  = 'AIRS';
          Settings.Var         = 'A';   
        case 12;
          Settings.Instrument  = 'MLS';
          Settings.Var         = 'T';  
        case 13;
          Settings.Instrument  = 'AIRS';
          Settings.Var         = 'Mz';
        case 14;
          Settings.Instrument  = 'AIRS';
          Settings.Var         = 'Mm';          
        case 15;
          Settings.Instrument  = 'MLSpw';
          Settings.Var         = 'PW mode 1';    
        case 16;
          Settings.Instrument  = 'MLSpw';
          Settings.Var         = 'PW mode 2';
        case 17;
          Settings.Instrument  = 'MLSpw';
          Settings.Var         = 'PW mode 3';          
        case 18;
          Settings.Instrument  = 'SABERpw';
          Settings.Var         = 'PW mode 1';    
        case 19;
          Settings.Instrument  = 'SABERpw';
          Settings.Var         = 'PW mode 2';
        case 20;
          Settings.Instrument  = 'SABERpw';
          Settings.Var         = 'PW mode 3';          
      end
      
      
      OutFile = ['out/',Settings.Instrument,'_',Settings.Var,'/',num2str(MasterHeight),'km_',sprintf('%04d',MasterYear),'_',Settings.Instrument,'-',Settings.Var];
      OutFile(OutFile == ' ') = [] ;      



      if exist([OutFile,'.png']);
        file=dir([OutFile,'.png']);
        datemodified = datenum(file.date);
        if datemodified > datenum(2020,4,14,0,0,0); continue; end
      end
      
      disp(OutFile)
      Settings.SpecialYear = MasterYear;
      Settings.Height = MasterHeight;
      plot_single_series;
      export_fig(OutFile,'-png','-m1.5','-a4');
      disp('done')

    end
  end
  
end
  