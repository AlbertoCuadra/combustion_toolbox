function [N, dNi_T, dN_T, dNi_p, dN_p, index, STOP, STOP_ions, h0] = equilibriumGibbs(obj, system, p, T, mix, guess_moles)
    % Obtain equilibrium composition [moles] for the given temperature [K] and pressure [bar].
    % The code stems from the minimization of the free energy of the system by using Lagrange
    % multipliers combined with a Newton-Raphson method, upon condition that initial gas
    % properties are defined by temperature and pressure.
    %
    % The algorithm implemented take advantage of the sparseness of the
    % upper left submatrix obtaining a matrix J of size NE + NS - NG + 1. 
    %
    % This function is based on the method outlined in Gordon, S., & McBride,
    % B. J. (1994). NASA reference publication, 1311 and in Leal, A. M., Kulik, D. A.,
    % Kosakowski, G., & Saar, M. O. (2016). Computational methods for reactive transport
    % modeling: An extended law of mass-action, xLMA, method for multiphase equilibrium
    % calculations. Advances in Water Resources, 96, 405-422.
    %
    % Args:
    %     obj (EquilibriumSolver):
    %     system (ChemicalSystem):
    %     p (float): Pressure [bar]
    %     T (float): Temperature [K]
    %     mix1 (struct): Properties of the initial mixture
    %     guess_moles (float): Mixture composition [mol] of a previous computation
    %
    % Returns:
    %     Tuple containing
    %
    %     * N (float): Composition matrix [n_i, FLAG_CONDENSED_i] for the given temperature [K] and pressure [bar] at equilibrium
    %     * dNi_T (float): Thermodynamic derivative of the moles of the species respect to temperature
    %     * dN_T (float): Thermodynamic derivative of the moles of the mixture respect to temperature
    %     * dNi_p (float): Thermodynamic derivative of the moles of the species respect to pressure
    %     * dN_p (float): Thermodynamic derivative of the moles of the mixture respect to pressure
    %     * index (float): List of chemical species indices
    %     * STOP (float): Relative error in moles of species [-]
    %     * h0 (float): Molar enthalpy [J/mol]
    %
    % Examples:
    %     * N = EquilibriumSolver().equilibriumGibbs(1.01325, 3000, mix, [])
    %     * [N, dNi_T, dN_T, dNi_p, dN_p, index, STOP, STOP_ions, h0] = EquilibriumSolver().equilibriumGibbs(1.01325, 3000, mix, [])

    % Generalized Gibbs minimization method (reduced)
    
    % Constants
    R0 = combustiontoolbox.common.Constants.R0; % Universal gas constant [J/(K mol)]

    % Definitions
    % CHECK: ERROR IN N(:, 2) FOR CONDENSED SPECIES.
    N = system.molesPhaseMatrix;       % Composition matrix [moles_i, phase_i]
    A0 = system.stoichiometricMatrix;  % Stoichiometric matrix [a_ij]
    RT = R0 * T;                       % [J/(mol)]
    tau0RT = 1e-25 / RT;
    opts.SYM = true; % Options linsolve method: real symmetric
    
    % Initialization
    NatomE = mix.natomElementsReact;
    max_NatomE = max(NatomE);
    NP = 0.1;
    SIZE = -log(obj.tolMoles);
    FLAG_CONDENSED = false;

    % Set moles from guess_moles (if it was given) to 1e-6 to avoid singular matrix
    guess_moles(guess_moles < obj.tolMolesGuess) = obj.tolMolesGuess;
    
    % Find indeces of the species/elements that we have to remove from the stoichiometric matrix A0
    % for the sum of elements whose value is <= tolMoles
    [A0, indexRemoveSpecies, ind_E, NatomE] = remove_elements(NatomE, A0, system.ind_E, obj.tolMoles);
    
    % List of indices with nonzero values
    [index, indexGas, indexCondensed, indexIons, indexElements, NE, NG, NS] = temp_values(system, NatomE);
    
    % Update temp values
    if ~isempty(indexRemoveSpecies)
        [index, indexCondensed, indexGas, indexIons, NG, NS] = update_temp(N, indexRemoveSpecies, indexCondensed, indexGas, indexIons, NP, SIZE);
    end
    
    % Remove condensed species with temperature out of bounds
    indexCondensed = check_temperature_range(system, T, indexCondensed, NS - NG, false);

    % Remove gas species with temperature out of bounds
    [indexGas, NG] = check_temperature_range(obj, T, indexGas, NG, obj.FLAG_EXTRAPOLATE);

    % First, compute chemical equilibrium with only gaseous species
    indexGas_0 = indexGas;
    indexCondensed_0 = indexCondensed;
    indexCondensed = [];
    index = [indexGas, indexCondensed];
    NS = length(index);
    
    % Initialize vectors g0 (molar Gibbs energy) and h0 (molar enthalpy) with zeros
    g0 = N(:, 1);
    h0 = N(:, 1);

    % Initialize composition matrix N [mol, FLAG_CONDENSED]    
    [N, NP] = initialize_moles(N, NP, indexGas, NG, guess_moles);
    
    % Molar Gibbs energy [J/mol]
    g0([indexGas_0, indexCondensed_0]) = set_g0(system.listSpecies([indexGas_0, indexCondensed_0]), T, system.species);
    
    % Dimensionless chemical potential
    muRT = g0/RT;
    
    % Construction of part of matrix J
    J22 = zeros(NS - NG + 1);
    A0_T = A0';

    % Initialization 
    psi_j = system.molesPhaseMatrix(:, 1);
    tauRT = tau0RT .* min(NatomE);

    % Solve system
    x = equilibrium_loop;

    % Compute chemical equilibrium with condensed species
    x = equilibrium_loop_condensed(x);
    
    % Update matrix J (jacobian) to compute the thermodynamic derivatives
    J = update_matrix_J(A0_T(indexElements, :), J22, N(:, 1), NP, indexGas, indexCondensed, NE, NS - NG, psi_j);
    J(end, end) = 0;

    % Molar enthalpy [J/mol]
    h0(index) = set_h0(system.listSpecies(index), T, system.species);
    
    % Dimensionless enthalpy
    H0RT = h0 / RT;

    % Compute thermodynamic derivates
    [dNi_T, dN_T, dNi_p, dN_p] = obj.equilibriumDerivatives(J, N, A0, NE, indexGas, indexCondensed, indexElements, H0RT);

    % NESTED FUNCTION
    function x = equilibrium_loop
        % Calculate composition at chemical equilibrium
        
        % persistent totalIterations
        % 
        % if isempty(totalIterations)
        %     totalIterations = 0;
        % end

        % Initialization
        it = 0; counter_errors = 0;
        itMax = obj.itMaxGibbs;
        STOP = 1.0;
        FLAG_UNSTABLE = false;
        delta_j0 = ones(NS - NG, 1);

        % Calculations
        while STOP > obj.tolGibbs && it < itMax
            it = it + 1;
            % Chemical potentials
            muRT(indexGas) =  g0(indexGas) / RT + log(N(indexGas, 1) / NP) + log(p);
            
            % Construction of matrix J
            J = update_matrix_J(A0_T, J22, N(:, 1), NP, indexGas, indexCondensed, NE, NS - NG, psi_j);
            
            % Construction of vector b      
            b = update_vector_b(A0, N(:, 1), NP, NatomE, ind_E, index, indexGas, indexCondensed, indexIons, muRT, tauRT, psi_j);

            % Solve the linear system J*x = b
            x = linsolve(J, b, opts);
            
            % Check singular matrix
            if any(isnan(x) | isinf(x))

                % Update temp indeces
                indexGas = indexGas_0;
                indexCondensed = indexCondensed_0;
                index = [indexGas, indexCondensed];

                NG = length(indexGas);
                NS = length(index);

                % Reset removed species to 1e-6 to try the avoid singular matrix
                N( N(index, 1) < obj.tolMoles, 1) = 1e-6;
                psi_j = tauRT ./ N(indexCondensed, 1);

                if counter_errors > 2
                    x = NaN;
                    return
                end

                counter_errors = counter_errors + 1;
                continue
            end
            
            % Extract solution
            pi_i = x(1:NE);
            Delta_nj = x(NE+1:end-1);
            Delta_ln_NP = x(end);

            % Compute correction moles of gases
            Delta_ln_nj = update_Delta_ln_nj(A0, pi_i, Delta_ln_NP, muRT, indexGas);
            
            % Calculate correction factor
            delta = relax_factor(NP, N(index, 1), [Delta_ln_nj; Delta_nj], Delta_ln_NP, NG);

            % Apply correction gaseous species and total moles in the mixture
            N(indexGas, 1) = N(indexGas, 1) .* exp(delta * Delta_ln_nj);
            NP = NP * exp(delta * Delta_ln_NP);

            % Apply correction condensed species
            if NS - NG > 0
                delta0 = 0.9999;

                delta_j = delta_j0 * delta; 
                FLAG_DELTA = N(indexCondensed, 1) + Delta_nj < 0;
                delta_j(FLAG_DELTA) = -delta0 * N(indexCondensed(FLAG_DELTA), 1) ./ Delta_nj(FLAG_DELTA);
                N(indexCondensed, 1) = N(indexCondensed, 1) + delta_j .* Delta_nj; % N(indexCondensed, 1) + min(delta_j) * Delta_nj
                
                delta_j = delta_j0 * delta;
                Delta_psi_j = (tauRT - psi_j(indexCondensed) .* Delta_nj) ./ N(indexCondensed, 1) - psi_j(indexCondensed);
                FLAG_DELTA = psi_j(indexCondensed) + Delta_psi_j < 0;
                delta_j(FLAG_DELTA) = -delta0 * psi_j(indexCondensed(FLAG_DELTA)) ./ Delta_psi_j(FLAG_DELTA);
                psi_j(indexCondensed) = psi_j(indexCondensed) + delta_j .* Delta_psi_j; % psi_j + min(delta_j) * Delta_psi_j;
                
                FLAG_UNSTABLE = (N(indexCondensed, 1) / NP < exp(-SIZE)) | (psi_j(indexCondensed) > 1e-2);
                N(indexCondensed(FLAG_UNSTABLE), 1) = -1;
            end

            % Compute STOP criteria
            STOP = compute_STOP(NP, Delta_ln_NP, N(index, 1), [Delta_ln_nj; Delta_nj], NG, A0(index, :), NatomE, max_NatomE, obj.tolE);

            % Update temp values in order to remove species with moles < tolerance
            [index, indexCondensed, indexGas, indexIons, NG, NS, N] = update_temp(N, index, indexCondensed, indexGas, indexIons, NP, SIZE);
            
            % Update psi_j vector
            if sum(FLAG_UNSTABLE)
                J22 = zeros(NS - NG + 1);
                FLAG_UNSTABLE(:) = false;
                delta_j0 = ones(NS - NG, 1);
            end

            % Debug 
            % aux_delta(it) = delta;
            % aux_STOP(it) = STOP;
        end

        % totalIterations = totalIterations + it;
        
        % Check convergence of charge balance (ionized species)
        [N, STOP_ions, FLAG_ION] = check_convergence_ions(N, A0, ind_E, indexGas, indexIons, obj.tolMoles, obj.tolMultiplierIons, obj.itMaxIons);
        
        % Additional checks in case there are ions in the mixture
        if ~FLAG_ION
            return
        end
        
        % Check that there is at least one species with n_i > tolerance 
        if any(N(indexIons) > obj.tolMoles)
            return
        end
        
        % Remove ionized species that do not satisfy n_i > tolerance
        [index, indexCondensed, indexGas, indexIons, NG, NS] = update_temp(N, index, indexCondensed, indexGas, indexIons, NP, SIZE);
        
        % If none of the ionized species satisfy n_i > tolerance, remove
        % electron "element" from the stoichiometric matrix
        if ~isempty(indexIons)
            return
        end
        
        % Remove element E from matrix
        indexElements(ind_E) = [];
        NE = NE - 1;

        % Debug
        % debug_plot_error(it, aux_STOP, aux_delta);
    end

    function x = equilibrium_loop_condensed(x)
        % Calculate composition at chemical equilibrium with condensed
        % species

        if isempty(indexCondensed_0)
            return
        end

        % Update list possible gaseous species (in case singular matrix)
        indexGas_0 = indexGas;
        
        % Set list with indeces of the condensed species to be checked
        indexCondensed_check = indexCondensed_0;

        % Get molecular weight species [kg/mol]
        W = system.molesPhaseMatrix(:, 1);
        W(indexCondensed_check) = set_prop_DB(system.listSpecies(indexCondensed_check), 'W', system.species) * 1e-3; % * 1e-3;

        % Definitions
        NC_max = NE - 1;
        FLAG_ALL = false;
        
        % Initialization
        j = 0;
        while indexCondensed_check
            j = j + 1;

            % Check Gibbs phase rule
            if length(indexCondensed) > NC_max
                break;
            end

            % Check condensed species
            [indexCondensed_add, FLAG_CONDENSED] = check_condensed_species(A0, x(1:NE), W(indexCondensed_check), indexCondensed_check, muRT, NC_max);
            
            if ~FLAG_CONDENSED
                break
            end

            NC_add = length(indexCondensed_add);

            % Update indeces
            if FLAG_ALL
                indexCondensed = indexCondensed_check;
                indexCondensed_check = [];
            else
                % indexCondensed_check(indexCondensed_check == indexCondensed_add) = [];
                indexCondensed_check(ismember(indexCondensed_check, indexCondensed_add)) = [];
                indexCondensed = [indexCondensed, indexCondensed_add];
            end

            % indexCondensed_check = [];
            index = [indexGas, indexCondensed];
            indexCondensed_0 = indexCondensed;

            % Initialization
            STOP = 1;

            % Update lenght
            NS = length(index);
            
            % Update J matrix
            J22 = zeros(NS - NG + 1);

            % Save backup
            N_backup = N;

            % Initialize condensed composition and Lagrange multiplier vector psi
            N(indexCondensed_add, 1) = sqrt(tauRT);
            psi_j(indexCondensed_add) = N(indexCondensed_add, 1);
            
            % Compute chemical equilibrium considering condensed species
            x0 = equilibrium_loop;

            % Update solution vector
            if ~isnan(x0(1))
                x = x0;
                indexGas_0 = indexGas;
                continue
            end

            % Singular matrix: remove last added condensed species
            indexGas = indexGas_0;
            N = N_backup;
            N(indexCondensed(1:end-1)) = 1;
            N(indexCondensed(end)) = -1;
            [~, indexCondensed, indexGas, indexIons, NG, NS] = update_temp(N, index, indexCondensed, indexGas, indexIons, NP, SIZE);
            N(indexCondensed(1:end-1)) = 0;
            indexCondensed_check = indexCondensed;
        end

    end

end

% SUB-PASS FUNCTIONS
function [N, NP] = initialize_moles(N, NP, indexGas, NG, guess_moles)
    % Initialize composition from a previous calculation or using an
    % uniform distribution [mol]

    if isempty(guess_moles)
        N(indexGas, 1) = NP/NG;
    else
        N(indexGas, 1) = guess_moles(indexGas);
        NP = sum(guess_moles(indexGas));
    end

end

function [indexCondensed, FLAG_CONDENSED] = check_condensed_species(A0, pi_i, W, indexCondensed, muRT, NC_max)
    % Check condensed species
    
    % Initialization
    FLAG_CONDENSED = false;

    % Get length condensed species
    NC = length(indexCondensed);

    for i = NC:-1:1
        % Only check if there were atoms of the species in the initial
        % mixture
        if ~sum(A0(indexCondensed(i), :))
            continue
        end

        % Calculate dLdnj of the condensed species
        dL_dn(i) = (muRT(indexCondensed(i)) - dot(pi_i, A0(indexCondensed(i), :))) / W(i); % / W(i);
    end
    
    % Get condensed species that may appear at chemical equilibrium
    FLAG = dL_dn < 0;

    % Check if any condensed species have to be considered
    if ~sum(FLAG)
        indexCondensed = [];
        return
    end

    % Get index of the condensed species to be added to the system
    indexCondensed = indexCondensed(FLAG);
    dL_dn = dL_dn(FLAG);
    
    % Gibbs phase rule
    if NC > NC_max
        [~, indexSort] = sort(dL_dn);
        indexCondensed = indexCondensed(indexSort(1:NC_max));
    end

    % Update flag
    FLAG_CONDENSED = true;
end

function indexRemoveSpecies = findIndexRemoveSpecies(A0, FLAG_REMOVE_ELEMENTS)
    % Get flag of species to be removed from stoichiometrix matrix A0
    indexRemoveSpecies = find(sum(A0(:, FLAG_REMOVE_ELEMENTS) > 0, 2) > 0);
end

function [A0, indexRemoveSpecies, ind_E, NatomE] = remove_elements(NatomE, A0, ind_E, tol)
    % Find zero sum elements

    % Define temporal fictitious value if there are ionized species
    temp_NatomE = NatomE;
    temp_NatomE(ind_E) = 1;

    % Get flag of elements to be removed from stoichiometrix matrix
    FLAG_REMOVE_ELEMENTS = temp_NatomE' <= tol;
    
    % Get the species to be removed from stoichiometrix matrix
    indexRemoveSpecies = findIndexRemoveSpecies(A0, FLAG_REMOVE_ELEMENTS);

    % Update stoichiometrix matrix
    A0(:, FLAG_REMOVE_ELEMENTS) = [];

    % Set number of atoms
    NatomE(FLAG_REMOVE_ELEMENTS) = [];
    
    % Check position "element" electron
    if ind_E
        ind_E = ind_E - sum(FLAG_REMOVE_ELEMENTS(1:ind_E-1));
    end

end

function [index, indexGas, indexCondensed, indexIons, indexElements, NE, NG, NS] = temp_values(system, NatomE)
    % List of indices with nonzero values and lengths
    indexElements = 1:length(NatomE);
    indexGas = system.indexGas;
    indexCondensed = system.indexCondensed;
    indexIons = system.indexGas(system.indexIons);
    indexCryogenic = system.indexCryogenic;
    index = [indexGas, indexCondensed];
    [index, indexCondensed] = check_cryogenic(index, indexCondensed, indexCryogenic);

    % Update lengths
    NE = length(NatomE);
    NG = length(indexGas);
    NS = length(index);
end

function [indexCondensed, indexGas, indexIons, n] = remove_item(n, index, indexCondensed, indexGas, indexIons, NP, SIZE)
    % Remove species from the computed indeces list of gaseous and condensed
    % species and append the indeces of species that we have to remove
    for i=1:length(n)
        if n(i) / NP < exp(-SIZE)
            n(i) = 0;
            indexCondensed(indexCondensed==index(i)) = [];
            indexGas(indexGas==index(i)) = [];
            indexIons(indexIons==index(i)) = [];
        end
        
    end

end

function [index, indexCondensed, indexGas, indexIons, NG, NS, N] = update_temp(N, index, indexCondensed, indexGas, indexIons, NP, SIZE)
    % Update temp items
    [indexCondensed, indexGas, indexIons, n] = remove_item(N(index, 1), index, indexCondensed, indexGas, indexIons, NP, SIZE);
    N(index, 1) = n;
    index = [indexGas, indexCondensed];
    NG = length(indexGas);
    NS = length(index);
end

function [index, indexCondensed] = check_cryogenic(index, indexCondensed, indexCryogenic)
    % Remove cryogenic species from calculations
    for i = 1:length(indexCryogenic)
        index(index == indexCryogenic(i)) = [];
        indexCondensed(indexCondensed == indexCryogenic(i)) = [];
    end

end

function delta = relax_factor(NP, ni, eta, Delta_ln_NP, NG)
    % Compute relaxation factor
    FLAG = eta(1:NG) > 0;
    FLAG_MINOR = ni(1:NG) / NP <= 1e-8 & FLAG;
    delta1 = 2./max(5*abs(Delta_ln_NP), abs(eta(FLAG)));
    delta2 = min(abs((-log(ni(FLAG_MINOR)/NP) - 9.2103404) ./ (eta(FLAG_MINOR) - Delta_ln_NP)));
    delta = min([1; delta1; delta2]);
end

function STOP = compute_STOP(NP, deltaNP, N, deltaN, NG, A0, NatomE, max_NatomE, tolE)
    % Compute stop criteria
    NPi = sum(N);
    deltaN1 = N .* abs(deltaN) / NPi;
    deltaN1(NG + 1:end) = abs(deltaN(NG + 1:end)) / NPi;
    deltaN2 = NP * abs(deltaNP) / NPi;
    deltab = abs(NatomE - sum(N .* A0, 1)) / max_NatomE;
    deltab = max(deltab(NatomE > tolE));
    STOP = max(max(max(deltaN1), deltaN2), deltab);
end

function J11 = update_matrix_J11(A0_T, N, indexGas, NE)
    % Compute submatrix J11
    for k = NE:-1:1
        J11(:, k) = sum(A0_T(k, indexGas) .* A0_T(:, indexGas) .* N(indexGas)', 2);
    end
end

function J12 = update_matrix_J12(A0_T, N, indexGas, indexCondensed)
    % Compute submatrix J12
    J12_1 = A0_T(:, indexCondensed);
    J12_2 = (N(indexGas)' * A0_T(:, indexGas)')';
    J12 = [J12_1, J12_2];
end

function J22 = update_matrix_J22(J22, N, NP, indexGas)
    % Compute submatrix J22
    J22(end, end) = sum(N(indexGas, 1)) - NP;
end

function J = update_matrix_J(A0_T, J22, N, NP, indexGas, indexCondensed, NE, NC, psi_j)
    % Compute matrix J
    J11 = update_matrix_J11(A0_T, N, indexGas, NE);
    J12 = update_matrix_J12(A0_T, N, indexGas, indexCondensed);
    J22(1:NC, 1:NC) = - diag(psi_j(indexCondensed) ./ N(indexCondensed));
    J22 = update_matrix_J22(J22, N, NP, indexGas);
    J = [J11, J12; J12', J22];
end

function b = update_vector_b(A0, N, NP, NatomE, ind_E, index, indexGas, indexCondensed, indexIons, muRT, tauRT, psi_j) 
    % Compute vector b
    bi = N(index)' * A0(index, :);

    if any(indexIons)
        bi(ind_E) = NatomE(ind_E);
    end
    
    b1 = (NatomE - bi + sum(A0(indexGas, :) .* N(indexGas, 1) .* muRT(indexGas)))';
    b2 = muRT(indexCondensed) - tauRT ./ N(indexCondensed);
    b3 = NP + sum(N(indexGas) .* muRT(indexGas) - N(indexGas));
    
    b = [b1; b2; b3];
end

function Delta_ln_nj = update_Delta_ln_nj(A0, pi_i, Delta_NP, muRT, indexGas)
    % Compute correction moles of gases
    Delta_ln_nj = sum(A0(indexGas, :)' .* pi_i, 1)' + Delta_NP - muRT(indexGas);
end

function [N, STOP, FLAG_ION] = check_convergence_ions(N, A0, ind_E, indexGas, indexIons, TOL, TOL_pi, itMax)
    % Check convergence of ionized species
    
    % Initialization
    STOP = 0;

    % Check if there are ionized species
    if ~any(indexIons)
        FLAG_ION = false;
        return
    end
    
    % Update FLAG_ION
    FLAG_ION = true;

    % Get error in the electro-neutrality of the mixture
    [delta_ions, ~] = ions_factor(N, A0, ind_E, indexGas, indexIons);
    
    % Reestimate composition of ionized species
    if abs(delta_ions) > TOL_pi
        [N, STOP] = recompute_ions(N, A0, ind_E, indexGas, indexIons, delta_ions, TOL, TOL_pi, itMax);
    end
    
end

function [N, STOP] = recompute_ions(N, A0, ind_E, indexGas, indexIons, delta_ions, TOL, TOL_pi, itMax)
    % Reestimate composition of ionized species
    
    % Initialization
    A0_ions = A0(indexIons, ind_E);
    STOP = 1;
    it = 0;
    % Reestimate composition of ionized species
    while STOP > TOL_pi && it < itMax
        it = it + 1;
        % Apply correction
        N(indexIons, 1) = N(indexIons, 1) .* exp(A0_ions * delta_ions);
        % Compute correction of the Lagrangian multiplier for ions divided by RT
        [delta_ions, ~] = ions_factor(N, A0, ind_E, indexGas, indexIons);
        STOP = abs(delta_ions);
    end   
    
    Xi_ions = N(indexIons, 1) / sum(N(:, 1));

    % Set error to zero if molar fraction of ionized species are below
    % tolerance
    if ~any(Xi_ions > TOL)
        STOP = 0;
    end

end

function [delta, deltaN3] = ions_factor(N, A0, ind_E, indexGas, indexIons)
    % Compute relaxation factor for ionized species
    
    if ~any(indexIons)
        delta = [];
        deltaN3 = 0;
        return
    end

    delta = -sum(A0(indexGas, ind_E) .* N(indexGas, 1))/ ...
             sum(A0(indexGas, ind_E).^2 .* N(indexGas, 1));
    deltaN3 = abs(sum(N(indexGas, 1) .* A0(indexGas, ind_E)));
end