classdef NasaDatabase < combustiontoolbox.databases.Database
    
    methods (Access = public)
        
        function obj = NasaDatabase(varargin)
            % Constructor
            %
            % Optional Args:
            %   varargin (optional): key-value pairs to initialize the database
            %
            % Returns:
            %     obj (NasaDatabase): Object with NASA's database
            %
            % Examples:
            %     * db = combustiontoolbox.databases.NasaDatabase();
            %     * db = combustiontoolbox.databases.NasaDatabase('filename', 'DB.mat');

            % Call superclass constructor
            obj@combustiontoolbox.databases.Database('name', 'NASA', 'temperatureReference', 298.15, varargin{:});
        end
    
    end

    methods (Access = public, Static)
        
        function [a, b, tRange, tExponents, ctTInt, txFormula, phase] = getCoefficients(species, DB)
            % Unpack NASA's polynomials coefficients from database
            %
            % Args:
            %     species (char): Chemical species
            %     DB (struct): Database with custom thermodynamic polynomials functions generated from NASAs 9 polynomials fits
            %
            % Returns:
            %     Tuple containing
            %
            %     * a (cell): Temperature coefficients
            %     * b (cell): Integration constants
            %     * tRange (cell): Ranges of temperatures [K]
            %     * tExponents (cell): Exponent coefficients
            %     * ctTInt (float): Number of intervals of temperatures
            %     * txFormula (char): Chemical formula
            %     * phase (float): 0 or 1 indicating gas or condensed phase, respectively
            %
            % Example:
            %     [a, b, tRange, tExponents, ctTInt, txFormula, phase] = getCoefficients('H2O', DB)
        
            a = DB.(species).a;
            b = DB.(species).b;
            tRange = DB.(species).tRange;
            tExponents = DB.(species).tExponents;
            ctTInt = DB.(species).ctTInt;
            txFormula = DB.(species).txFormula;
            phase = DB.(species).phase;
        end

        function [cp, cv, h0, DhT, e0, DeT, s0, g0] = speciesThermo(species, temperature, DB)
            % Compute thermodynamic function using NASA's 9 polynomials
            %
            % Args:
            %     species (char): Chemical species
            %     temperature (float): Range of temperatures to evaluate [K]
            %     DB (struct): Database with custom thermodynamic polynomials functions generated from NASAs 9 polynomials fits
            %
            % Returns:
            %     Tuple containing
            %
            %     * cP  (float): Specific heat at constant pressure in molar basis [J/(mol-K)]
            %     * cV  (float): Specific heat at constant volume in molar basis   [J/(mol-K)]
            %     * h0  (float): Enthalpy in molar basis [kJ/mol]
            %     * DhT (float): Thermal enthalpy in molar basis [kJ/mol]
            %     * e0  (float): Internal energy in molar basis [kJ/mol]
            %     * DeT (float): Thermal internal energy in molar basis [kJ/mol]
            %     * s0  (float): Entropy in molar basis [J/(mol-K)]
            %     * g0  (float): Gibbs energy in molar basis [kJ/mol]
            %
            % Example:
            %     [cp, cv, h0, DhT, e0, DeT, s0, g0] = speciesThermo('H2O', 300:100:6000, DB)
        
            % Definitions
            R0 = 8.31446261815324; % Universal Gas Constant [J/(mol-K)];
            hf = DB.(species).hf; % [J/mol];
            Tref = 298.15; % [K]

            % Unpack NASA's polynomials coefficients
            [a, b, Trange, Texponents, Tintervals, formula, phase] = getCoefficients(species, DB);

            % Get elements
            elements = set_elements();

            % Get element matrix of the species
            elementMatrix = set_element_matrix(formula, elements);

            % Compute change in moles of gases during the formation reaction of a
            % mole of that species starting from the elements in their reference state
            Delta_n = compute_change_moles_gas_reaction(elementMatrix, phase);

            % Compute specific enthalpy [kJ/mol]
            for i = length(temperature):-1:1
                T = temperature(i);
        
                if DB.(species).ctTInt > 0
                    % Compute interval temperature
                    tInterval = getIndexTempereratureInterval(species, T, DB, Trange, Tintervals);

                    % Compute thermodynamic function
                    cp(i) = R0 * (sum(a{tInterval} .* T.^Texponents{tInterval}));
                    h0(i) = R0 * T * (sum(a{tInterval} .* T.^Texponents{tInterval} .* [-1 log(T) 1 1/2 1/3 1/4 1/5 0]) + b{tInterval}(1) / T);
                    s0(i) = R0 * (sum(a{tInterval} .* T.^Texponents{tInterval} .* [-1/2 -1 log(T) 1 1/2 1/3 1/4 0]) + b{tInterval}(2));
                    ef = hf - Delta_n * R0 * Tref;
                    e0(i) = (ef + (h0(i) - hf) - (1 - phase) * R0 * (T - Tref));
                    cv(i) = cp(i) - R0;
                    DhT(i) = h0(i) - hf;
                    DeT(i) = e0(i) - ef;
                    % If the species is only a reactant determine it's reference temperature
                    % Tref. For noncryogenic reactants, assigned enthalpies are given at 298.15 K.
                    % For cryogenic liquids, assigned enthalpies are given at their boiling points
                    % instead of 298.15 K
                else
                    Tref = Trange(1);
                    cp = 0;
                    cv = 0;
                    h0(i) = hf;
                    e0(i) = hf - Delta_n * R0 * Tref;
                    g0(i) = DB.(species).Hf0;
                    s0(i) = 0;
                    DhT(i) = 0;
                    DeT(i) = 0;
                end
        
            end
        
            % Change units
            h0 = h0 * 1e-3; % [kJ/mol]
            DhT = DhT * 1e-3; % [kJ/mol]
            e0 = e0 * 1e-3; % [kJ/mol]
            DeT = DeT * 1e-3; % [kJ/mol]
            g0 = g0 * 1e-3; % [kJ/mol]
            s0 = s0 * 1e-3; % [kJ/(mol-K)]
        end
        
        function Tinterval = getIndexTempereratureInterval(species, T, DB, Trange, Tintervals)
            % Compute interval NASA polynomials
            %
            % Args:
            %     species (char) : Chemical species
            %     T (float): Temperature [K]
            %     DB (struct) : Database with custom thermodynamic polynomials functions generated from NASAs 9 polynomials fits
            %     Trange (cell): Ranges of temperatures [K]
            %     Tintervals (float): Number of intervals of temperatures
            %
            % Returns:
            %     Tinterval (float): Index of the interval of temperatures
        
            Tinterval = [];
        
            if DB.(species).Tintervals == 0
                return
            end
        
            for j = 1:Tintervals
                if (T >= Trange{j}(1)) && (T <= Trange{j}(2))
                    Tinterval = j;
                end
        
            end
        
            if ~isempty(Tinterval)
                return
            end
        
            if T > Trange{j}(2)
                Tinterval = Tintervals;
            elseif T < Trange{j}(2)
                Tinterval = 1;
            end
        
        end

    end

end