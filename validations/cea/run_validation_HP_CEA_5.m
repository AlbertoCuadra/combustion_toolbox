function run_validation_HP_CEA_5
    % Run test validation_HP_CEA_5:
    % Contrasted with: NASA's Chemical Equilibrium with Applications software
    % Problem type: Adiabatic T and composition at constant p
    % Temperature [K]   = 300;
    % Pressure    [bar] = 1;
    % Equivalence ratio [-] = 0.5:0.01:4
    % Initial mixture: NATURAL GAS (85% CH4 + 10% C2H6 + 0.5% CO2) + AIR (78.084% N2 + 20.9476% O2 + 0.9365% Ar + 0.0319% CO2)
    % List of species considered: list_species('Soot Formation Extended')

    % Import packages
    import combustiontoolbox.databases.NasaDatabase
    import combustiontoolbox.core.*
    import combustiontoolbox.equilibrium.*
    import combustiontoolbox.utils.display.*
    
    % Benchmark?
    FLAG_BENCHMARK = false;

    % Definitions
    prefixDataName = 'Natural-gas_2_air1_HP';

    for i = 2:-1:1
        filename{i} = sprintf('%s%d.out', prefixDataName, i);
    end

    listSpecies =  'Soot Formation Extended';
    displaySpecies = {'CO2', 'CO', 'H2O', 'H2', 'O2', 'N2',...
                      'HCN','H','OH','O','CN','NH3','CH4','C2H4','CH3',...
                      'NO','HCO','NH2','NH','N','CH','Cbgrb'};
    tolMoles = 1e-18;

    % Get Nasa database
    DB = NasaDatabase('FLAG_BENCHMARK', FLAG_BENCHMARK);
    
    % Define chemical system
    system = ChemicalSystem(DB, listSpecies);
    
    % Initialize mixture
    mix = Mixture(system);
    
    % Define chemical state
    set(mix, {'CH4', 'C2H6', 'CO2'}, 'fuel', [0.85, 0.1, 0.05]);
    set(mix, {'N2', 'O2', 'Ar', 'CO2'}, 'oxidizer', [78.084, 20.9476, 0.9365, 0.0319] / 20.9476);

    % Define properties
    mixArray = setProperties(mix, 'temperature', 300, 'pressure', 1, 'equivalenceRatio', 0.5:0.01:4);
    
    % Initialize solver
    solver = EquilibriumSolver('problemType', 'HP', 'tolMoles', tolMoles, 'FLAG_RESULTS', false);
    
    % Solve problem
    solver.solveArray(mixArray);
    
    if FLAG_BENCHMARK
        return
    end

    % Load results CEA 
    resultsCEA = data_CEA(filename, displaySpecies);
    
    % Plot molar fractions
    plotComposition(mixArray(1), mixArray, 'equivalenceRatio', 'Xi', 'displaySpecies', displaySpecies, 'mintol', 1e-14, 'validation', resultsCEA);
    
    % Plot molar fractions
    fig1 = plotComposition(mixArray(1), mixArray, 'equivalenceRatio', 'Xi', 'displaySpecies', displaySpecies, 'mintol', 1e-14, 'validation', resultsCEA);

    % Plot properties
    fig2 = plotProperties(repmat({'equivalenceRatio'}, 1, 9), mixArray, {'T', 'rho', 'h', 'e', 'g', 'cp', 's', 'gamma_s', 'sound'}, mixArray, 'basis', {[], [], 'mi', 'mi', 'mi', 'mi', 'mi', [], []}, 'validation', resultsCEA);

    % Save plots
    folderpath = fullfile(pwd, 'validations', 'figures');
    stack_trace = dbstack;
    filename = stack_trace.name;
    saveas(fig1, fullfile(folderpath, strcat(filename, '_molar')), 'svg');
    saveas(fig2, fullfile(folderpath, strcat(filename, '_properties')), 'svg');
end