classdef Mixture < handle & matlab.mixin.Copyable

    % properties
    %     T (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     p (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     N (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     hf (1,1) double {mustBeNumeric}
    %     ef (1,1) double {mustBeNumeric}
    %     h (1,1) double {mustBeNumeric}
    %     e (1,1) double {mustBeNumeric}
    %     g (1,1) double {mustBeNumeric}
    %     s (1,1) double {mustBeNumeric}
    %     cp (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     cv (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     gamma (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     gamma_s (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     sound (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     s0 (1,1) double {mustBeNumeric}
    %     DhT (1,1) double {mustBeNumeric}
    %     DeT (1,1) double {mustBeNumeric}
    %     Ds (1,1) double {mustBeNumeric}
    %     rho (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     v (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     W (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     MW (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     mi (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     Xi (:, 1) double {mustBeNumeric, mustBeNonnegative}
    %     Yi (:, 1) double {mustBeNumeric, mustBeNonnegative}
    %     phase (:, 1) logical 
    %     dVdT_p (1,1) double {mustBeNumeric}
    %     dVdp_T (1,1) double {mustBeNumeric}
    %     equivalenceRatio (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     natomElements (1,:) double {mustBeNumeric, mustBeNonnegative}
    %     natomElementsReact (1,:) double {mustBeNumeric, mustBeNonnegative}
    %     errorMoles (1, 1) double {mustBeNumeric}
    %     errorMolesIons (1, 1) double {mustBeNumeric}
    %     errorProblem (1, 1) double {mustBeNumeric}
    %     chemicalSystem combustiontoolbox.core.ChemicalSystem
    %     rangeName (1, :) char {mustBeText}
    %     rangeValue (1, :) double {mustBeNumeric}
    % end

    properties
        T (1,1)               % Temperature [K]
        p (1,1)               % Pressure [bar]
        N                     % Total number of moles [mol]
        hf                    % Enthalpy of formation [J]
        ef                    % Internal energy of formation [J]
        h                     % Enthalpy [J]
        e                     % Internal energy [J]
        g                     % Gibbs energy [J] 
        s                     % Entropy [J/K]
        cp                    % Specific heat at constant pressure [J/K]
        cv                    % Specific heat at constant volume [J/K]
        gamma                 % Adiabatic index [-]
        gamma_s               % Adiabatic index [-]
        sound                 % Speed of sound [m/s]
        s0                    % Entropy (frozen) [J/K]
        DhT                   % Thermal enthalpy [J]
        DeT                   % Thermal internal energy [J]
        Ds                    % Entropy of mixing [J/K]
        rho                   % Density [kg/m3]
        v                     % Volume [m3]
        vSpecific (1,1)       % Specific volume [m3/kg]
        W                     % Molecular weight [kg/mol]
        MW                    % Mean molecular weight [kg/mol]
        mi                    % Mass mixture [kg]
        Xi                    % Molar fractions [-]
        Yi                    % Mass fractions [-]
        phase                 % Phase vector [-]
        dVdT_p                % Derivative of volume with respect to temperature at constant pressure [-]
        dVdp_T                % Derivative of volume with respect to pressure at constant temperature [-]
        equivalenceRatio      % Equivalence ratio [-]
        stoichiometricMoles   % Theoretical moles of the oxidizer of reference for a stoichiometric combustion
        percentageFuel        % Percentage of fuel in the mixture [%]
        fuelOxidizerMassRatio % Mass ratio of oxidizer to fuel [-]
        oxidizerFuelMassRatio % Mass ratio of fuel to oxidizer [-]
        natomElements         % Vector atoms of each element [-]
        natomElementsReact    % Vector atoms of each element without frozen species [-]
        errorMoles            % Relative error in the moles calculation [-]
        errorMolesIons        % Relative error in the moles of ions calculation [-]
        errorProblem          % Relative error in the problem [-]
        chemicalSystem        % Chemical system object
        equationOfState       % Equation of State object
        % Properties from shock and detonation module (CT-SD)
        u                     % Velocity relative to the shock front [m/s]
        uShock                % Velocity in the shock tube [m/s]
        uNormal               % Normal component of u [m/s]
        mach                  % Mach number [-]
        beta                  % Wave angle [deg]
        theta                 % Deflection angle [deg]
        betaMin               % Minimum wave angle [deg]
        betaMax               % Maximum wave angle [deg]
        thetaMax              % Maximum deflection angle [deg]
        betaSonic             % Wave angle at the sonic point [deg]
        thetaSonic            % Deflection angle at the sonic point [deg]
        indexMax              % Index of the maximum deflection angle
        indexSonic            % Index of the sonic point
        polar                 % Properties of the polar solution
        % Properties from rocket module (CT-ROCKET)
        areaRatio
        areaRatioChamber
        cstar
        cf
        I_sp
        I_vac
    end

    properties (Access = private)
        indexGas
        FLAGS_PROP
        FLAG_VOLUME = false
    end

    % properties (Hidden)
    %     cp_f (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     cp_r (1,1) double {mustBeNumeric, mustBeNonnegative}
    %     dNi_T (:, 1) double {mustBeNumeric}
    %     dN_T (1,1) double {mustBeNumeric}
    %     dNi_p (:, 1) double {mustBeNumeric}
    %     dN_p (1,1) double {mustBeNumeric}
    %     FLAG_REACTION = false
    % end
    
    properties (Hidden)
        cp_f
        cp_r
        dNi_T
        dN_T
        dNi_p
        dN_p
        quantity
        listSpecies
        listSpeciesFuel
        listSpeciesOxidizer
        listSpeciesInert
        molesFuel
        molesOxidizer
        molesInert
        chemicalSystemProducts
        problemType
        fuel
        rangeName
        ratioOxidizer % Ratio oxidizer relative to the oxidizer of reference
        FLAG_FUEL = false
        FLAG_OXIDIZER = false
        FLAG_INERT = false
        FLAG_REACTION = false
    end
    
    methods
        
        function obj = Mixture(chemicalSystem, varargin)
            % The chemical system has the database, we only need the properties matrix to perform all the calculations
            % Now to be compatible with all the capabilities of the previous version, we will have to be able to add a
            % list of species for calculations and another list with all the species involved (reactants and products)

            % Definitions
            defaultTemperature = 300; % [K]
            defaultPressure = 1;      % [bar]
            defaultEoS = 'idealGas';

            % Parse inputs
            ip = inputParser;
            addRequired(ip, 'chemicalSystem'); % @(x) isa(x, 'combustiontoolbox.core.ChemicalSystem ')
            addOptional(ip, 'T', defaultTemperature, @(x) isnumeric(x) && x >= 0);
            addOptional(ip, 'p', defaultPressure, @(x) isnumeric(x) && x >= 0);
            addOptional(ip, 'eos', defaultEoS);
            parse(ip, chemicalSystem, varargin{:});
            
            % Assign Equation of State
            obj.equationOfState = combustiontoolbox.core.EquationState(ip.Results.eos);

            % Assign properties matrix
            obj.chemicalSystem = ip.Results.chemicalSystem;
        end

        function obj = setTemperature(obj, T, varargin)
            % Compute thermodynamic properties at temperature T [K]
            
            % Definitions
            defaultUnits = 'K';

            % Parse inputs
            ip = inputParser;
            addRequired(ip, 'T', @(x) isnumeric(x) && x >= 0);
            addOptional(ip, 'units', defaultUnits, @(x) ischar(x));
            parse(ip, T, varargin{:});
            
            % Assign temperature
            obj.T = T;
            
            % Check if initial state is defined (temperature, pressure, and composition)
            if ~sum(obj.quantity) || (~obj.p && ~obj.vSpecific)
                return
            end
            
            % Set equivalence ratio and compute thermodynamic properties
            if ~isempty(obj.equivalenceRatio)
                setEquivalenceRatio(obj, obj.equivalenceRatio);
                return
            end
            
            % Compute pressure if required
            if obj.vSpecific && obj.FLAG_VOLUME
                vMolar = vSpecific2vMolar(obj, obj.vSpecific, obj.quantity, obj.quantity(obj.indexGas));
                obj.p = convert_Pa_to_bar(obj.equationOfState.getPressure(obj.T, vMolar, obj.chemicalSystem.listSpecies, obj.quantity / sum(obj.quantity)));
            end

            % Assign values to the propertiesMatrix
            obj.chemicalSystem.set_propertiesMatrix(obj.listSpecies, obj.quantity, obj.T);

            % Compute thermodynamic properties
            obj.compute_properties(obj.chemicalSystem, T, obj.p);

            % Compute equivalence ratio, percentage Fuel, and Oxidizer/Fuel ratio
            obj.computeEquivalenceRatio();
        end

        function obj = setPressure(obj, p, varargin)
            % Compute thermodynamic properties at pressure p [K]
            
            % Definitions
            defaultUnits = 'bar';

            % Parse inputs
            ip = inputParser;
            addRequired(ip, 'p', @(x) isnumeric(x) && x >= 0);
            addOptional(ip, 'units', defaultUnits, @(x) ischar(x));
            parse(ip, p, varargin{:});
            
            % Assign pressure
            obj.p = p;

            % Check if initial state is defined (temperature, pressure, and composition)
            if ~sum(obj.quantity) || ~obj.T
                return
            end
            
            % Set equivalence ratio and compute thermodynamic properties
            if ~isempty(obj.equivalenceRatio)
                setEquivalenceRatio(obj, obj.equivalenceRatio);
                return
            end

            % Compute thermodynamic properties
            obj.compute_properties(obj.chemicalSystem, obj.T, p);

            % Compute equivalence ratio, percentage Fuel, and Oxidizer/Fuel ratio
            obj.computeEquivalenceRatio();
        end

        function obj = setVolume(obj, vSpecific, varargin)
            % Compute thermodynamic properties at pressure p [K]
            
            % Definitions
            defaultUnits = 'm3/kg';

            % Parse inputs
            ip = inputParser;
            addRequired(ip, 'vSpecific', @(x) isnumeric(x) && x >= 0);
            addOptional(ip, 'units', defaultUnits, @(x) ischar(x));
            parse(ip, vSpecific, varargin{:});
            
            % Assign specific volume
            obj.vSpecific = vSpecific;
            obj.FLAG_VOLUME = true;

            % Check if initial state is defined (temperature, pressure, and composition)
            if ~sum(obj.quantity) || ~obj.T
                return
            end
            
            % Compute pressure
            vMolar = vSpecific2vMolar(obj, obj.vSpecific, obj.quantity, obj.quantity(obj.indexGas));
            obj.p = convert_Pa_to_bar(obj.equationOfState.getPressure(obj.T, vMolar, obj.chemicalSystem.listSpecies, obj.quantity / sum(obj.quantity)));

            % Set equivalence ratio and compute thermodynamic properties
            if ~isempty(obj.equivalenceRatio)
                setEquivalenceRatio(obj, obj.equivalenceRatio);
                return
            end

            % Assign values to the propertiesMatrix
            obj.chemicalSystem.set_propertiesMatrix(obj.listSpecies, obj.quantity, obj.T);

            % Compute thermodynamic properties
            obj.compute_properties(obj.chemicalSystem, obj.T, obj.p);

            % Compute equivalence ratio, percentage Fuel, and Oxidizer/Fuel ratio
            obj.computeEquivalenceRatio();
        end

        function obj = set(obj, listSpecies, varargin)
            % 
            
            % Import packages
            import combustiontoolbox.utils.findIndex

            % Definitions
            quantityDefault = 1;
            unitsDefault = 'mol';

            % 
            if nargin > 3
                type = varargin{1};
                quantity = varargin{2};

                switch lower(type)
                    case 'fuel'
                        obj.listSpeciesFuel = [obj.listSpeciesFuel, listSpecies];
                        obj.molesFuel = [obj.molesFuel, quantity];
                        obj.FLAG_FUEL = true;
                    case 'oxidizer'
                        obj.listSpeciesOxidizer = [obj.listSpeciesOxidizer, listSpecies];
                        obj.molesOxidizer = [obj.molesOxidizer, quantity];
                        % obj.ratioOxidizer = obj.molesOxidizer;
                        obj.FLAG_OXIDIZER = true;
                    case 'inert'
                        obj.listSpeciesInert = [obj.listSpeciesInert, listSpecies];
                        obj.molesInert = [obj.molesInert, quantity];
                        obj.FLAG_INERT = true;
                end

            elseif nargin > 2
                quantity = varargin{1};
            end

            % Update local listSpecies and local quantity
            obj.listSpecies = [obj.listSpecies, listSpecies];
            obj.quantity = [obj.quantity, quantity];
            
            % Check if species are contained in the chemical system
            obj.chemicalSystem.checkSpecies(listSpecies);
            
            % Get indexReact
            obj.chemicalSystem.set_react_index(obj.listSpeciesInert);
            
            % Get indexProducts
            obj.chemicalSystem.indexProducts = findIndex(obj.chemicalSystem.listSpecies, obj.chemicalSystem.listProducts);

            % Get system containing only the list of products
            obj.chemicalSystemProducts = getSystemProducts(obj.chemicalSystem);
            
            % Check phase added species
            obj.indexGas = find(ismember(obj.listSpecies, obj.chemicalSystem.listSpecies(obj.chemicalSystem.indexGas)));

            % Check if initial state is defined (temperature, pressure, and composition)
            if ~obj.T || (~obj.p && ~obj.vSpecific)
                return
            end

            % Compute pressure if required
            if obj.vSpecific && obj.FLAG_VOLUME
                vMolar = vSpecific2vMolar(obj, obj.vSpecific, obj.quantity, obj.quantity(obj.indexGas));
                obj.p = convert_Pa_to_bar(obj.equationOfState.getPressure(obj.T, vMolar, obj.chemicalSystem.listSpecies, obj.quantity / sum(obj.quantity)));
            end

            % Set equivalence ratio and compute thermodynamic properties
            if ~isempty(obj.equivalenceRatio)
                setEquivalenceRatio(obj, obj.equivalenceRatio);
                return
            end
            
            % Assign values to the propertiesMatrix
            obj.chemicalSystem.set_propertiesMatrix(listSpecies, quantity, obj.T);

            % Compute thermodynamic properties
            obj.compute_properties(obj.chemicalSystem, obj.T, obj.p);
            
            % Compute percentage Fuel, Oxidizer/Fuel ratio and equivalence ratio
            obj.compute_ratios_fuel_oxidizer(obj.chemicalSystem.propertiesMatrixFuel, obj.chemicalSystem.propertiesMatrixOxidizer);
        end

        function obj = setEquivalenceRatio(obj, value)
            % 
            obj.equivalenceRatio = value;
            
            % Check if initial state is defined (temperature, pressure, and composition)
            if ~obj.T || (~obj.p && ~obj.vSpecific) || ~obj.FLAG_FUEL || ~obj.FLAG_OXIDIZER
                return
            end
            
            % Get oxidizer of reference
            obj.chemicalSystem.getOxidizerReference(obj.listSpeciesOxidizer);
            
            % Computation of theoretical stoichiometricMoles
            obj.defineF();
            
            % Define moles Oxidizer 
            if isempty(obj.ratioOxidizer), obj.ratioOxidizer = obj.molesOxidizer; end
            obj.molesOxidizer = obj.stoichiometricMoles / obj.equivalenceRatio .* obj.ratioOxidizer;
            
            % Define oxidizer propertiesMatrix
            obj.defineO();
            
            % Create temporal ChemicalSystems
            temp2 = obj.chemicalSystem.copy;

            % Assign values to the propertiesMatrix
            obj.chemicalSystem = obj.chemicalSystem.set_propertiesMatrix(obj.listSpeciesFuel, obj.molesFuel, obj.T) + temp2.set_propertiesMatrix(obj.listSpeciesOxidizer, obj.molesOxidizer, obj.T);
            
            if ~isempty(obj.listSpeciesInert)
                obj.chemicalSystem = obj.chemicalSystem + temp2.set_propertiesMatrix(obj.listSpeciesInert, obj.molesInert, obj.T);
            end

            % Update listSpecies and quantity
            obj.listSpecies = [obj.listSpeciesFuel, obj.listSpeciesOxidizer, obj.listSpeciesInert];
            obj.quantity = [obj.molesFuel, obj.molesOxidizer, obj.molesInert];

            % Compute pressure if required
            if obj.vSpecific && obj.FLAG_VOLUME
                vMolar = vSpecific2vMolar(obj, obj.vSpecific, obj.quantity, obj.quantity(obj.indexGas));
                obj.p = convert_Pa_to_bar(obj.equationOfState.getPressure(obj.T, vMolar, obj.chemicalSystem.listSpecies, obj.quantity / sum(obj.quantity)));
            end

            % Compute thermodynamic properties
            obj.compute_properties(obj.chemicalSystem, obj.T, obj.p);
            
            % Compute percentage Fuel, Oxidizer/Fuel ratio and equivalence ratio
            obj.compute_ratios_fuel_oxidizer(obj.chemicalSystem.propertiesMatrixFuel, obj.chemicalSystem.propertiesMatrixOxidizer);
        end

        function obj = computeEquivalenceRatio(obj)
            
            % Check if initial state is defined (temperature, pressure, and composition)
            if ~obj.T || (~obj.p && ~obj.vSpecific) || ~obj.FLAG_FUEL || ~obj.FLAG_OXIDIZER
                return
            end

            % Get oxidizer of reference
            obj.chemicalSystem.getOxidizerReference(obj.listSpeciesOxidizer);
            
            % Computation of theoretical stoichiometricMoles
            obj.defineF();
            
            % Define oxidizer propertiesMatrix
            obj.defineO();
            
            % Compute percentage Fuel, Oxidizer/Fuel ratio and equivalence ratio
            obj.compute_ratios_fuel_oxidizer(obj.chemicalSystem.propertiesMatrixFuel, obj.chemicalSystem.propertiesMatrixOxidizer);
        end

        function obj = compute_ratios_fuel_oxidizer(obj, propertiesMatrixFuel, propertiesMatrixOxidizer)
            % Compute percentage Fuel, Oxidizer/Fuel ratio and equivalence ratio
            if obj.FLAG_FUEL && obj.FLAG_OXIDIZER
                mass_fuel = obj.getMass(obj.chemicalSystem, propertiesMatrixFuel);
                mass_oxidizer = obj.getMass(obj.chemicalSystem, propertiesMatrixOxidizer);
                mass_mixture = obj.mi;
                obj.percentageFuel = mass_fuel / mass_mixture * 100;
                obj.oxidizerFuelMassRatio = mass_oxidizer / mass_fuel;
                obj.fuelOxidizerMassRatio = 1 / obj.oxidizerFuelMassRatio;
                FO_moles = sum(propertiesMatrixFuel(:, obj.chemicalSystem.ind_ni)) / sum(propertiesMatrixOxidizer(obj.chemicalSystem.oxidizerReferenceIndex, obj.chemicalSystem.ind_ni));
                FO_moles_st = abs(sum(propertiesMatrixFuel(:, obj.chemicalSystem.ind_ni)) / (obj.fuel.x + obj.fuel.x2 + obj.fuel.x3 + obj.fuel.y / 4 - obj.fuel.z / 2) * (0.5 * obj.chemicalSystem.oxidizerReferenceAtomsO));
                obj.equivalenceRatio = FO_moles / FO_moles_st;
            elseif obj.FLAG_FUEL
                obj.percentageFuel = 100;
                obj.fuelOxidizerMassRatio = inf;
                obj.oxidizerFuelMassRatio = 0;
                obj.equivalenceRatio = '-';
            else
                obj.percentageFuel = 0;
                obj.fuelOxidizerMassRatio = 0;
                obj.oxidizerFuelMassRatio = inf;
                obj.equivalenceRatio = '-';
            end
        
        end

        function obj = set_prop(obj, varargin)
            % Assign property values to the respective variables
            %
            % Args:
            %     self (struct): Data of the mixture, conditions, and databases
            %
            % Optional Args:
            %     * field (str): Fieldname in Problem Description (PD)
            %     * value (float): Value/s to assing in the field in Problem Description (PD)
            %
            % Returns:
            %     self (struct): Data of the mixture, conditions, and databases
        
            try
                for i = 1:2:nargin - 1
                    self = set_prop_common(self, varargin{i}, varargin{i + 1});
                end
        
            catch
                error('Error number inputs @set_prop');
            end
        
        end
        
        function obj = set_prop_common(obj, name, value)
            % Assign property values to the given variable name
        
            % If the value is a char, convert it to a float - (GUI)
            if value(1) == '['
                value = sscanf(value, '[%f:%f:%f]');
                value = value(1):value(2):value(3);
            elseif sum(value == ':') == 2
                value = sscanf(value, '%f:%f:%f');
                value = value(1):value(2):value(3);
            elseif ischar(value)
                value = sscanf(value, '%f');
            end
        
            % Define flags
            if length(value) > 1
                obj.FLAGS_PROP.(name) = true;
            else
                obj.FLAGS_PROP.(name) = false;
            end
        
            % Set value
            obj.(name).value = value;
        end

        function objArray = setProperties(obj, property, value, varargin)
            % Obtain properties at equilibrium for the given thermochemical transformation
            %
            % Args:
            %     obj (Mixture): Mixture Object
            %     property (char): Property to be set
            %     value (float): Value of the property
            %
            % Optional Args (key-value pairs):
            %     * property (char): Property to be set
            %     * value (float): Value of the property
            %
            % Returns:
            %     objArray (Mixture): Array of Mixture objects with the computed properties
            %
            % Note:
            %     * Use this method after setting the initial composition of the mixture
            %
            % Examples:
            %     * mixArray = setProperties(mix, 'equivalenceRatio', value)
            %     * mixArray = setProperties(mix, 'equivalenceRatio', value, 'temperature', value)
            %     * mixArray = setProperties(mix, 'equivalenceRatio', value, 'temperature', value, 'pressure', value)
            %     * mixArray = setProperties(mix, 'phi', value, 'T', value, 'p', value)
            
            % Initialization
            FLAG_MACH = false;
            
            % Assign value to the property
            properties = {property, varargin{1:2:end}};
            values = {value, varargin{2:2:end}};
            
            % Definitions
            numProperties = length(properties);

            % Check vectors
            FLAG_VECTOR = cellfun(@(x) numel(x) > 1, values);
            
            if sum(FLAG_VECTOR)
                % Create vectors same size
                FLAG_VECTOR_FIRST = find(FLAG_VECTOR, 1);
                aux = ones(size(values{FLAG_VECTOR_FIRST}));
    
                for i = find(~FLAG_VECTOR)
                    values(i) = {values{i} * aux};
                end
                
                % Define property parametric study
                obj.rangeName = properties{FLAG_VECTOR_FIRST};
                
                % Check rangeName to match Mixture's property
                if any(~strcmpi({'T', 'p', 'vspecific', 'phi', 'u', 'mach', 'beta', 'theta'}, obj.rangeName))

                    switch lower(obj.rangeName)
                        case {'temperature'}
                            obj.rangeName = 'T';
                        case {'pressure'}
                            obj.rangeName = 'p';
                        case {'volume', 'v'}
                            obj.rangeName = 'vSpecific';
                        case {'phi'}
                            obj.rangeName = 'equivalenceRatio';
                        case {'velocity', 'u1'}
                            obj.rangeName = 'u';
                        case {'m1'}
                            obj.rangeName = 'mach';
                        case {'wave angle', 'waveangle', 'wave'}
                            obj.rangeName = 'beta';
                        case {'deflection angle', 'deflectionangle', 'deflection'}
                            obj.rangeName = 'theta';
                    end

                end

            else
                FLAG_VECTOR_FIRST = 1;
            end

            % Get number of cases
            numCases = length(values{FLAG_VECTOR_FIRST});
            
            % Initialization
            objArray = obj.empty(0, numCases);

            % Set properties
            for j = 1:numCases
                % Create a copy of the mixture
                objArray(j) = obj.copyDeep();

                % Set property
                for i = 1:numProperties

                    switch lower(properties{i})
                        case {'temperature', 't'}
                            objArray(j).T = values{i}(j);
                        case {'pressure', 'p'}
                            objArray(j).p = values{i}(j);
                        case {'volume', 'vspecific', 'v'}
                            objArray(j).vSpecific = values{i}(j);
                            objArray(j).FLAG_VOLUME = true;
                        case {'equivalenceratio', 'phi'}
                            objArray(j).equivalenceRatio = values{i}(j);
                        case {'velocity', 'u', 'u1'}
                            objArray(j).u = values{i}(j);
                        case {'mach', 'm1'}
                            objArray(j).mach = values{i}(j);
                            FLAG_MACH = true;
                        case {'wave angle', 'waveangle', 'wave', 'beta'}
                            objArray(j).beta = values{i}(j);
                        case {'deflection angle', 'deflectionangle', 'deflection', 'theta'}
                            objArray(j).theta = values{i}(j);
                        otherwise
                            error('Property not found');
                    end

                end

                % Compute state
                objArray(j).setTemperature(objArray(j).T);

                % Additional inputs
                if FLAG_MACH
                    objArray(j).u = objArray(j).mach * objArray(j).sound;
                end

            end

        end

        function vMolar = vSpecific2vMolar(obj, vSpecific, moles, molesGas, varargin)
            % Compute molar volume [m3/mol] from specific volume [m3/kg]
            
            % Get index specie
            if nargin == 4
                index = combustiontoolbox.utils.findIndex(obj.chemicalSystem.listSpecies, obj.listSpecies);
            else
                index = varargin{1};
            end

            % Compute Mean Molecular Weight [kg/mol]
            MW = computeMeanMolecularWeight(obj, moles, index);

            % Compute specific volume [m3/mol]
            vMolar = vSpecific * MW * sum(moles) / sum(molesGas);
        end
        
        % Add print method
        print(mix, varargin)
    end
    
    methods(Access = protected)
      
      function objCopy = copyElement(obj)
         % Override copyElement method:

         % Make a shallow copy of all properties
         objCopy = copyElement@matlab.mixin.Copyable(obj);
      end

      function objCopy = copyDeep(obj)
         % Make a deep copy of obj

         % Make a shallow copy of all properties
         objCopy = copyElement(obj);

         % Make a deep copy of the ChemicalSystem object
         objCopy.chemicalSystem = obj.chemicalSystem.copy();
      end
      
    end

    methods (Access = private)

        % function obj = plus(obj, obj2)
        %     % Merge two mixtures (operator overloading)

        %     % Define a common chemical system
            
        %     % Merge chemical composition

        %     % Compute common temperature and pressure
            
        %     % Compute properties of the mixture

        % end

        function obj = compute_properties(obj, system, temperature, pressure)
            % Compute properties from the given chemicalSystem at pressure p [bar]
            % and temperature T [K]
            %
            % Args:
            %     obj (Mixture): Mixture class
            %     system (ChemicalSystem): 
            %     temperature (float): Temperature [K]
            %     pressure (float): Pressure [bar]
            %
            % Returns:
            %     obj (Mixture): Mixture class with the computed properties
            %
            % Example:
            %     mix = compute_properties(mix, system, T, p)
            
            % Definitions
            R0 = combustiontoolbox.common.Constants.R0; % Universal gas constant [J/(K mol)]
            propertiesMatrix = system.propertiesMatrix; % Properties matrix

            % Initialization
            obj.errorMoles = 0;
            obj.errorMolesIons = 0;

            % Inputs
            obj.T = temperature; % [K]
            obj.p = pressure; % [bar]

            % Unpack propertiesMatrix
            Ni = propertiesMatrix(:, system.ind_ni); % [mol]
            obj.N = sum(propertiesMatrix(:, system.ind_ni)); % [mol]
            obj.hf = dot(propertiesMatrix(:, system.ind_hfi), Ni); % [J]
            obj.h = dot(propertiesMatrix(:, system.ind_hi), Ni); % [J]
            obj.ef = dot(propertiesMatrix(:, system.ind_efi), Ni); % [J]
            obj.cp = dot(propertiesMatrix(:, system.ind_cpi), Ni); % [J/K]
            obj.s0 = dot(propertiesMatrix(:, system.ind_si), Ni); % [J/K]
            obj.phase = propertiesMatrix(:, system.ind_phase); % [bool]

            % Compute total composition of gas species [mol]
            N_gas = sum(Ni(~obj.phase));

            % Compute molar fractions [-]
            obj.Xi = Ni / obj.N;

            % Compute molecular weight (gases) [kg/mol]
            obj.W = dot(Ni, propertiesMatrix(:, system.ind_W)) / N_gas;

            % Compute mean molecular weight [kg/mol]
            obj.MW = dot(Ni, propertiesMatrix(:, system.ind_W)) / obj.N;

            % Compute mass mixture [kg]
            obj.mi = obj.MW * obj.N; % [kg]

            % Compute mass fractions [-]
            obj.Yi = (Ni .* propertiesMatrix(:, system.ind_W)) ./ obj.mi;

            % Get non zero species
            FLAG_NONZERO = obj.Xi > 0;

            % Compute vector atoms of each element
            obj.natomElements = sum(Ni .* system.stoichiometricMatrix, 1);

            % Compute vector atoms of each element without frozen species
            obj.natomElementsReact = sum(propertiesMatrix(system.indexReact, system.ind_ni) .* system.stoichiometricMatrix(system.indexReact, :), 1);
            
            % Compute volume [m3]
            if N_gas
                obj.v = obj.equationOfState.getVolume(temperature, convert_bar_to_Pa(pressure), obj.chemicalSystem.listSpecies, obj.Xi) * N_gas;
            else
                % Mixture with only have condensed species
                obj.v = obj.vSpecific * obj.mi;
            end

            % Compute specific volume [m3/kg]
            obj.vSpecific = obj.v / obj.mi;

            % Compute density [kg/m3]
            obj.rho = 1 / obj.vSpecific;

            % Compute internal energy [J]
            obj.e = obj.h - N_gas * R0 * temperature;

            % Compute thermal internal energy [J]
            obj.DeT = obj.e - obj.ef;

            % Compute thermal enthalpy [J]
            obj.DhT = obj.h - obj.hf;

            % Compute entropy of mixing [J/K]
            obj.Ds = obj.compute_entropy_mixing(Ni, N_gas, R0, FLAG_NONZERO);

            % Compute entropy [J/K]
            obj.s = obj.s0 + obj.Ds;

            % Compute Gibbs energy [J]
            obj.g = obj.h - obj.T * obj.s;
            
            % Compute thermodynamic derivatives, cp, cv, gamma, and speed
            % of sound considering chemical reaction
            if obj.FLAG_REACTION
                % Set thermodynamic derivatives
                obj.dVdT_p = obj.dN_T + 1; % [-]
                obj.dVdp_T = obj.dN_p - 1; % [-]
        
                if ~any(isnan(obj.dNi_T)) && ~any(isinf(obj.dNi_T))
                    % Definitions
                    delta = ~obj.phase;
                    h0_j = propertiesMatrix(:, system.ind_hi); % [J/mol]

                    % Compute specific heat at constant pressure [J/K]
                    obj.cp_r = sum(h0_j / temperature .* (1 + delta .* (Ni - 1)) .* obj.dNi_T, 'omitnan');
                    obj.cp_f = obj.cp;
                    obj.cp = obj.cp_f + obj.cp_r;

                    % Compute specific heat at constant volume [J/K]
                    obj.cv = obj.cp + (N_gas * R0 * obj.dVdT_p^2) / obj.dVdp_T;

                    % Compute Adibatic index [-]
                    obj.gamma = obj.cp / obj.cv;
                    obj.gamma_s = -obj.gamma / obj.dVdp_T;

                    % Compute sound velocity [m/s]
                    obj.sound = sqrt(obj.gamma_s * convert_bar_to_Pa(pressure) / obj.rho); % [m/s]

                    % Compute Mach number
                    if ~isempty(obj.u)
                        obj.mach = obj.u / obj.sound;
                    end

                    return
                end

                obj.gamma_s = -1 / obj.dVdp_T; % [-]
                
                return
            end
            
            % Compute thermodynamic derivatives, cp, cv, gamma, and speed
            % of sound considering frozen chemistry
            
            % Set thermodynamic derivatives
            obj.dVdT_p = 1;          % [-]
            obj.dVdp_T = -1;         % [-]

            % Compute specific heat at constant volume [J/K]
            obj.cv = obj.cp - R0 * N_gas;

            % Compute Adibatic index [-]
            obj.gamma = obj.cp / obj.cv;
            obj.gamma_s = obj.gamma;

            % Compute sound velocity [m/s]
            obj.sound = sqrt(obj.gamma * convert_bar_to_Pa(pressure) / obj.rho);
            
            % Compute Mach number
            if ~isempty(obj.u)
                obj.mach = obj.u / obj.sound;
            end

        end

        function MW = computeMeanMolecularWeight(obj, moles, index)
            % Compute Mean Molecular Weight [kg/mol]
            MW = dot(moles, obj.chemicalSystem.propertiesMatrix(index, obj.chemicalSystem.ind_W)) / sum(moles);
        end

        function Ds = compute_entropy_mixing(obj, Ni, N_gas, R0, FLAG_NONZERO)
            % Compute entropy of mixing [J/K]
            %
            % Args:
            %     obj (Mixture): Mixture class
            %     Ni (moles): Vector of moles of each species [mol]
            %     N_gas (moles): Total moles of gas species [mol]
            %     R0 (float): Universal gas constant [J/(mol-K)]
            %     FLAG_NONZERO (bool): Vector of nonzero species
            %
            % Returns:
            %     DS (float): Entropy of mixing [J/K]
            %
            % Note: 
            %     only nonzero for gaseous species
            %
            % Example:
            %     Ds = compute_entropy_mixing(mix, Ni, N_gas, R0, FLAG_NONZERO)
        
            Dsi = Ni(FLAG_NONZERO) .* log(Ni(FLAG_NONZERO) / N_gas * obj.p) .* (1 - obj.phase(FLAG_NONZERO));
            Ds = -R0 * sum(Dsi);
        end

        function obj = defineF(obj)
            % Set Fuel of the mixture
            %
            % Args:
            %     obj (Mixture):
            %
            % Returns:
            %     obj (Mixture):

            if obj.FLAG_FUEL
                % Create a copy of chemicalSystem
                system = obj.chemicalSystem.copy();
                % Set temperature-dependent matrix properties to zero
                system.clean();
                % Fill properties matrix with only fuel species
                system.set_propertiesMatrix(obj.listSpeciesFuel, obj.molesFuel, obj.T);
                % Compute thermodynamic properties 
                mixFuel = obj.copyDeep().compute_properties(system, obj.T, obj.p);
                % Assign values elements C, H, O, N, S, and Si
                obj.assign_values_elements(mixFuel.natomElements);
                % Compute theoretical moles of the oxidizer of reference for a stoichiometric combustion
                obj.stoichiometricMoles = abs(obj.fuel.x + obj.fuel.x2 + ...
                                              obj.fuel.x3 + obj.fuel.y / 4 + ...
                                              - obj.fuel.z / 2) / (0.5 * system.oxidizerReferenceAtomsO);
                % Assign propertiesMatrixFuel
                obj.chemicalSystem.propertiesMatrixFuel = system.propertiesMatrix;
            else
                obj.fuel.x = 0;
                obj.fuel.x2 = 0;
                obj.fuel.x3 = 0;
                obj.fuel.y = 0;
                obj.fuel.z = 0;
                obj.fuel.w = 0;
                obj.stoichiometricMoles = 1;
                % obj.FLAG_FUEL = false;
            end

        end

        function obj = defineO(obj)
            % Set Fuel of the mixture
            %
            % Args:
            %     obj (Mixture):
            %
            % Returns:
            %     obj (Mixture):

            if isempty(obj.listSpeciesOxidizer)
                return
            end

            % Create a copy of chemicalSystem
            system = obj.chemicalSystem.copy();
            % Set temperature-dependent matrix properties to zero
            system.clean();
            % Fill properties matrix with only oxidizer species
            system.set_propertiesMatrix(obj.listSpeciesOxidizer, obj.molesOxidizer, obj.T);
            % Assign propertiesMatrixOxidizer
            obj.chemicalSystem.propertiesMatrixOxidizer = system.propertiesMatrix;
        end

        function obj = assign_values_elements(obj, natomElementsFuel)
            % Assign values for C, H, O, N, S, and Si elements
        
            if isempty(obj.chemicalSystem.ind_C), obj.fuel.x = 0; else, obj.fuel.x = natomElementsFuel(obj.chemicalSystem.ind_C); end
            if isempty(obj.chemicalSystem.ind_H), obj.fuel.y = 0; else, obj.fuel.y = natomElementsFuel(obj.chemicalSystem.ind_H); end
            if isempty(obj.chemicalSystem.ind_O), obj.fuel.z = 0; else, obj.fuel.z = natomElementsFuel(obj.chemicalSystem.ind_O); end
            if isempty(obj.chemicalSystem.ind_N), obj.fuel.w = 0; else, obj.fuel.w = natomElementsFuel(obj.chemicalSystem.ind_N); end
            if isempty(obj.chemicalSystem.ind_S), obj.fuel.x2 = 0; else, obj.fuel.x2 = natomElementsFuel(obj.chemicalSystem.ind_S); end
            if isempty(obj.chemicalSystem.ind_Si), obj.fuel.x3 = 0; else, obj.fuel.x3 = natomElementsFuel(obj.chemicalSystem.ind_Si); end
        end

    end
    
    methods (Access = private, Static)

        function mass = getMass(system, propertiesMatrix)
            % Compute mass mixture [kg]
        
            % Compute total number of moles [mol]
            N = sum(propertiesMatrix(:, system.ind_ni));
            % Compute mean molecular weight [kg/mol]
            W = dot(propertiesMatrix(:, system.ind_ni), propertiesMatrix(:, system.ind_W)) / N;
            % Compute mass of the mixture [kg]
            mass = W * N;
        end
    
    end

    methods (Hidden)

        function obj = set_fast(obj, listSpecies, quantity, index, h0)
            % 
           
            % Update local listSpecies and local quantity
            obj.listSpecies = listSpecies;
            obj.quantity = quantity;

            % Assign values to the propertiesMatrix
            obj.chemicalSystem.set_propertiesMatrix(listSpecies, quantity, obj.T, index, h0);

            % Compute thermodynamic properties
            obj.compute_properties(obj.chemicalSystem, obj.T, obj.p);
        end

    end

end