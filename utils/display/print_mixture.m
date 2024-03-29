function print_mixture(self, varargin)
    % Print properties and composition of the given mixtures in the command
    % window
    %
    % Args:
    %     self (struct): Data of the mixture, conditions, and databases
    %
    % Optional Args:
    %     * mix1 (struct): Struct with the properties of the mixture
    %     * mix2 (struct): Struct with the properties of the mixture
    %     * mixi (struct): Struct with the properties of the mixture
    %     * mixN (struct): Struct with the properties of the mixture
    %
    % Examples:
    %     * print_mixture(self, mix1)
    %     * print_mixture(self, mix1, mix2)
    %     * print_mixture(self, mix1, mix2, mix3)
    %     * print_mixture(self, mix1, mix2, mix3, mix4)

    % Definitions
    Nmixtures = nargin - 1;
    % Unpack cell with mixtures
    mix = varargin;
    % Start
    fprintf('************************************************************************************************************\n');
    % Print header
    header_composition = print_header(self.PD.ProblemType, Nmixtures, mix);
    % Print properties
    print_properties(self.PD.ProblemType, Nmixtures, mix);
    % Print composition
    for i = 1:nargin - 1
        print_composition(mix{i}, self.S.LS, self.C.composition_units, header_composition{i}, self.C.mintol_display);
    end

    % End
    fprintf('************************************************************************************************************\n\n\n');
end

% SUB-PASS FUNCTIONS
function value = get_properties(property, Nmixtures, mix)
    % Get properties of the given mixtures
    %
    % Args:
    %     property (function/char): Function/char to get the property
    %     Nmixtures (float): Number of mixtures
    %     mix (cell): Cell with the properties of the N mixtures
    %
    % Returns:
    %     value (float): Value of the property
    %
    % Examples:
    %     * get_properties(@temperature, 1, mix)
    %     * get_properties('v_shock', 1, mix)

    if ischar(property)
        value = cell2vector(mix, property);
        return
    end

    for i = Nmixtures:-1:1
        value(i) = property(mix{i});
    end

end

function line = set_string_value(Nmixtures)
    % Set the char to print the properties
    %
    % Args:
    %     Nmixtures (float): Number of mixtures
    %
    % Returns:
    %     line (char): Char to print the properties
    
    line_body = '   %12.4f  |';
    line_end = '   %12.4f\n';
    line = [repmat(line_body, 1, Nmixtures - 1), line_end];
end

function print_properties(ProblemType, Nmixtures, mix)
    % Print properties of the mixture in the command window
    %
    % Args:
    %     ProblemType (char): Type of problem
    %     Nmixtures (float): Number of mixtures
    %     mix (cell): Cell with the properties of the N mixtures

    % Definitions
    string_value = set_string_value(Nmixtures);
    string_value_2 = set_string_value(Nmixtures - 1);
    
    % Print properties
    fprintf(['T [K]          |', string_value], get_properties(@temperature, Nmixtures, mix));
    fprintf(['p [bar]        |', string_value], get_properties(@pressure, Nmixtures, mix));
    fprintf(['r [kg/m3]      |', string_value], get_properties(@density, Nmixtures, mix));
    fprintf(['h [kJ/kg]      |', string_value], get_properties(@enthalpy_mass, Nmixtures, mix));
    fprintf(['e [kJ/kg]      |', string_value], get_properties(@intEnergy_mass, Nmixtures, mix));
    fprintf(['g [kJ/kg]      |', string_value], get_properties(@gibbs_mass, Nmixtures, mix));
    fprintf(['s [kJ/(kg-K)]  |', string_value], get_properties(@entropy_mass, Nmixtures, mix));
    fprintf(['W [g/mol]      |', string_value], get_properties(@MolecularWeight, Nmixtures, mix));

    if Nmixtures > 1
        fprintf(['(dlV/dlp)T [-] |                 |', string_value_2], get_properties('dVdp_T', Nmixtures - 1, mix(2:end)));
        fprintf(['(dlV/dlT)p [-] |                 |', string_value_2], get_properties('dVdT_p', Nmixtures - 1, mix(2:end)));
    end

    fprintf(['cp [kJ/(kg-K)] |', string_value], get_properties(@cp_mass, Nmixtures, mix));
    fprintf(['gamma [-]      |', string_value], get_properties(@adiabaticIndex, Nmixtures, mix));
    fprintf(['gamma_s [-]    |', string_value], get_properties(@adiabaticIndex_sound, Nmixtures, mix));
    fprintf(['sound vel [m/s]|', string_value], get_properties(@soundspeed, Nmixtures, mix));

    if contains(ProblemType, 'SHOCK') || contains(ProblemType, 'DET')
        fprintf(['u [m/s]        |', string_value], [get_properties(@velocity_relative, 1, mix(1)), get_properties('v_shock', Nmixtures - 1, mix(2:end))]);
        fprintf(['Mach number [-]|', string_value], [get_properties(@velocity_relative, 1, mix(1)), get_properties('v_shock', Nmixtures - 1, mix(2:end))] ./ get_properties(@soundspeed, Nmixtures, mix));
    end

    if contains(ProblemType, '_OBLIQUE') || contains(ProblemType, '_POLAR')
        fprintf('------------------------------------------------------------------------------------------------------------\n');
        fprintf('PARAMETERS\n');
        fprintf(['min wave  [deg]|                 |', string_value_2], get_properties('beta_min', Nmixtures - 1, mix(2:end)));
        fprintf(['wave angle[deg]|                 |', string_value_2], get_properties('beta', Nmixtures - 1, mix(2:end)));
        fprintf(['deflection[deg]|                 |', string_value_2], get_properties('theta', Nmixtures - 1, mix(2:end)));

        if contains(ProblemType, '_POLAR')
            fprintf(['max def.  [deg]|                 |', string_value_2], get_properties('theta_max', Nmixtures - 1, mix(2:end)));
            fprintf(['sonic def.[deg]|                 |', string_value_2], get_properties('theta_sonic', Nmixtures - 1, mix(2:end)));
        end

    elseif contains(ProblemType, 'ROCKET')
        string_value_3 = set_string_value(Nmixtures - 2);

        fprintf('------------------------------------------------------------------------------------------------------------\n');
        fprintf('PERFORMANCE PARAMETERS\n');
        fprintf(['A/At [-]       |                 |                 |', string_value_3], get_properties('Aratio', Nmixtures - 2, mix(3:end)));
        fprintf(['CSTAR [m/s]    |                 |                 |', string_value_3], get_properties('cstar', Nmixtures - 2, mix(3:end)));
        fprintf(['CF [-]         |                 |                 |', string_value_3], get_properties('cf', Nmixtures - 2, mix(3:end)));
        fprintf(['Ivac [s]       |                 |                 |', string_value_3], get_properties('I_vac', Nmixtures - 2, mix(3:end)));
        fprintf(['Isp  [s]       |                 |                 |', string_value_3], get_properties('I_sp', Nmixtures - 2, mix(3:end)));
    end

    fprintf('------------------------------------------------------------------------------------------------------------\n');
end

function print_composition(mix, LS, units, header, mintol_display)
    % Print composition of the mixture in the command window
    %
    % Args:
    %     mix (struct): Struct with the properties of the mixture
    %     LS (cell): Cell with the names of the species
    %     units (char): Units of the composition
    %     header (char): Header of the composition
    %     mintol_display (double): Minimum value to be displayed

    switch lower(units)
        case 'mol'
            variable = moles(mix);
            short_label = 'Ni [mol]\n';
        case 'molar fraction'
            variable = moleFractions(mix);
            short_label = '  Xi [-]\n';
        case 'mass fraction'
            variable = massFractions(mix);
            short_label = '  Yi [-]\n';
    end

    fprintf([header, short_label]);
    %%%% SORT SPECIES COMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [variable, ind_sort] = sort(variable, 'descend');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    j = variable > mintol_display;
    minor = sum(variable(~j));

    for i = 1:length(j)

        if j(i)
            fprintf('%-20s %1.4e\n', LS{ind_sort(i)}, variable(i));
        end

    end

    Nminor = length(variable) - sum(j);
    s_space_Nminor = char(32 * ones(1, 4 - numel(num2str(Nminor))));
    fprintf('MINORS[+%d] %s     %12.4e\n\n', Nminor, s_space_Nminor, minor);
    fprintf('TOTAL            %14.4e\n', sum(variable));
    fprintf('------------------------------------------------------------------------------------------------------------\n');
end

function header_composition = print_header(ProblemType, Nmixtures, mix)
    % Print header in the command window
    %
    % Args:
    %     ProblemType (char): Type of the problem
    %     Nmixtures (float): Number of mixtures
    %     mix (cell): Cell with the properties of the N mixtures
    %
    % Returns:
    %     header_composition (cell): Cell with the header indicating the type/state of the mixture

    fprintf('------------------------------------------------------------------------------------------------------------\n');
    fprintf('Problem type: %s  | phi = %4.4f\n', ProblemType, equivalenceRatio(mix{1}));
    fprintf('------------------------------------------------------------------------------------------------------------\n');

    if contains(ProblemType, '_OBLIQUE') || contains(ProblemType, '_POLAR')

        if Nmixtures == 2
            header_composition = {'STATE 1               ', 'STATE 2               '};
            fprintf('               |     STATE 1     |     STATE 2\n');
        elseif Nmixtures == 3
            header_composition = {'STATE 1               ', 'STATE 2-W             ', 'STATE 2-S             '};
            fprintf('               |     STATE 1     |     STATE 2-W   |     STATE 2-S\n');
        elseif Nmixtures == 4
            header_composition = {'STATE 1               ', 'STATE 2               ', 'STATE 3-W             ', 'STATE 3-S             '};
            fprintf('               |     STATE 1     |     STATE 2     |     STATE 3-W   |     STATE 3-S\n');
        end

    elseif contains(ProblemType, '_R')
        header_body = '     STATE %d     |';
        header_end = '     STATE %d\n';
        header = [repmat(header_body, 1, Nmixtures - 1), header_end];
        value = 1:Nmixtures;
        fprintf(['               |', header], value);

        header_composition = {'STATE 1               ', ...
                              'STATE 2               ', ...
                              'STATE 3               ', ...
                              'STATE 4               ', ...
                              'STATE 5               ', ...
                              'STATE 6               ', ...
                              'STATE 7               ', ...
                              'STATE 8               '};
    elseif contains(ProblemType, 'ROCKET')

        if Nmixtures == 3
            header_composition = {'INLET CHAMBER         ', ...
                                  'OUTLET CHAMBER        ', ...
                                  'THROAT                '};
            fprintf('               |  INLET CHAMBER  | OUTLET CHAMBER  |      THROAT \n');
        elseif Nmixtures > 3

            if Nmixtures > 4
                header_exit_prop_last = '|      EXIT\n';
            else
                header_exit_prop_last = [];
            end

            if mix{3}.Aratio == 1
                header_exit = repmat({'EXIT                  '}, 1, Nmixtures - 3);
                header_composition = {'INLET CHAMBER         ', ...
                                      'OUTLET CHAMBER        ', ...
                                      'THROAT                ', ...
                                    header_exit{1:end}};

                if Nmixtures > 4
                    header_exit_prop = [repmat({'|      EXIT       |'}, 1, Nmixtures - 5), header_exit_prop_last];
                    fprintf(['               |  INLET CHAMBER  | OUTLET CHAMBER  |     THROAT      ', header_exit_prop{1:end}]);
                else
                    fprintf('               |  INLET CHAMBER  | OUTLET CHAMBER  |     THROAT      |      EXIT\n');
                end

            else
                header_exit = repmat({'EXIT                  '}, 1, Nmixtures - 4);
                header_composition = {'INLET CHAMBER         ', ...
                                      'INJECTOR              ', ...
                                      'OUTLET CHAMBER        ', ...
                                      'THROAT                ', ...
                                    header_exit{1:end}};

                if Nmixtures > 4
                    header_exit_prop = [repmat({'|      EXIT       |'}, 1, Nmixtures - 5), header_exit_prop_last];
                    fprintf(['               |  INLET CHAMBER  |     INJECTOR    | OUTLET CHAMBER  |     THROAT      ', header_exit_prop{1:end}]);
                else
                    fprintf('               |  INLET CHAMBER  |     INJECTOR    | OUTLET CHAMBER  |     THROAT \n');
                end

            end

        end

    elseif Nmixtures == 2
        header_composition = {'REACTANTS             ', ...
                        'PRODUCTS              '};
        fprintf('               |    REACTANTS    |      PRODUCTS\n');
    elseif Nmixtures == 1
        header_composition = {'MIXTURE               '};
        fprintf('               |     MIXTURE\n');
    end

end
