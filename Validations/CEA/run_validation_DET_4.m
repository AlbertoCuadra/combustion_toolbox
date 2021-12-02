function run_validation_DET_4
    % Run test validation_DET_4:
    % Contrasted with: NASA's Chemical Equilibrium with Applications software
    % Problem type: Chapman-Jouget Detonation
    % Temperature [K]   = 300;
    % Pressure    [bar] = 1;
    % Equivalence ratio [-] = 0.5:0.01:4
    % Initial mixture: CH4 + O2
    % List of species considered: ListSpecies('Soot Formation Extended')
    
    % Inputs
    Fuel = 'CH4';
    prefixDataName = Fuel;
    filename = {strcat(prefixDataName, '_O2_detonations.out'), strcat(prefixDataName, '_O2_detonations2.out'), strcat(prefixDataName, '_O2_detonations3.out')};
    LS =  'Soot Formation Extended';
    DisplaySpecies = {'CO2', 'CO', 'H2O', 'H2', 'O2', 'N2', 'He', 'Ar',...
                      'HCN','H','OH','O','CN','NH3','CH4','C2H4','CH3',...
                      'NO','HCO','NH2','NH','N','CH','Cbgrb'};
    % Combustion Toolbox
    results_CT = run_CT('ProblemType', 'DET', 'ListSpecies', LS,...
        'S_Fuel', Fuel, 'S_Oxidizer', 'O2', 'S_Inert', [],...
        'EquivalenceRatio', 0.5:0.01:4);
    % Load results CEA 
    results_CEA = data_CEA(filename, DisplaySpecies);
    % Display validation (plot)
    fig1 = plot_molar_fractions_validation(results_CT, results_CEA, 'phi', 'Xi', DisplaySpecies);
    % Save plots
    folderpath = strcat(pwd,'\Validations\Figures\');
    filename = 'validation_DET_4';
    saveas(fig1, strcat(folderpath, filename, '_molar'), 'svg');
end