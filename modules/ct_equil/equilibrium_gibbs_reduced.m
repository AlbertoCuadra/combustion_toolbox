function [N0, dNi_T, dN_T, dNi_p, dN_p, STOP, STOP_ions] = equilibrium_gibbs_reduced(self, pP, TP, mix1, guess_moles)
    % Obtain equilibrium composition [moles] for the given temperature [K] and pressure [bar].
    % The code stems from the minimization of the free energy of the system by using Lagrange
    % multipliers combined with a Newton-Raphson method, upon condition that initial gas
    % properties are defined by temperature and pressure.
    %
    % The algorithm implemented take advantage of the sparseness of the
    % upper left submatrix obtaining a matrix J of size NE + NS - NG + 1. 
    %
    % This method is based on Gordon, S., & McBride, B. J. (1994). NASA reference publication,
    % 1311.
    %
    % Args:
    %     self (struct): Data of the mixture, conditions, and databases
    %     pP (float): Pressure [bar]
    %     TP (float): Temperature [K]
    %     mix1 (struct): Properties of the initial mixture
    %     guess_moles (float): mixture composition [mol] of a previous computation
    %
    % Returns:
    %     Tuple containing
    %
    %     * N0 (float): Equilibrium composition [moles] for the given temperature [K] and pressure [bar]
    %     * dNi_T (float): Thermodynamic derivative of the moles of the species respect to temperature
    %     * dN_T (float): Thermodynamic derivative of the moles of the mixture respect to temperature
    %     * dNi_p (float): Thermodynamic derivative of the moles of the species respect to pressure
    %     * dN_p (float): Thermodynamic derivative of the moles of the mixture respect to pressure
    %     * STOP (float): Relative error in moles of species [-]

    % Generalized Gibbs minimization method (reduced)
    
    % Definitions
    N0 = self.C.N0.value;  % Composition matrix [ni, FLAG_CONDENSED_i]
    A0 = self.C.A0.value;  % Stoichiometric matrix [a_ij]
    R0TP = self.C.R0 * TP; % [J/(mol)]
    
    % Initialization
    NatomE = mix1.NatomE;
    max_NatomE = max(NatomE);
    NP = 0.1;
    SIZE = -log(self.TN.tolN);
    FLAG_CONDENSED = false;
    
    % Set moles from guess_moles (if it was given) to 1e-6 to avoid singular matrix
    guess_moles(guess_moles < self.TN.tolN_guess) = self.TN.tolN_guess;
    
    % Find indeces of the species/elements that we have to remove from the stoichiometric matrix A0
    % for the sum of elements whose value is <= tolN
    [A0, ind_remove_species, self.E.ind_E, NatomE] = remove_elements(NatomE, A0, self.E.ind_E, self.TN.tolN);
    
    % List of indices with nonzero values
    [ind, ind_nswt, ind_swt, ind_ions, ind_elem, NE, NG, NS] = temp_values(self.S, NatomE);
    
    % Update temp values
    [ind, ind_swt, ind_nswt, ind_ions, NG] = update_temp(N0, ind_remove_species, ind_swt, ind_nswt, ind_ions, NP, SIZE);
    
    % First, compute chemical equilibrium with only gaseous species
    ind_nswt_0 = ind_nswt;
    ind_swt_0 = ind_swt;
    ind_swt = [];
    ind = [ind_nswt, ind_swt];
    NS = length(ind);
    
    % Initialize composition matrix N0 [mol, FLAG_CONDENSED]    
    [N0, NP] = initialize_moles(N0, NP, ind_nswt, NG, guess_moles);
    
    % Standard Gibbs free energy [J/mol]
    g0 = set_g0(self.S.LS, TP, self.DB);
    
    % Dimensionless chemical potential
    muRT = g0/R0TP;
    
    % Construction of part of matrix J
    J22 = zeros(NS - NG + 1);
    A0_T = A0';

    % Solve system
    x = equilibrium_loop;

    % Check condensed species
    [ind, ind_swt, FLAG_CONDENSED] = check_condensed_species(A0, x, ind, ind_nswt, ind_swt_0, NE, muRT);
    if FLAG_CONDENSED
        % Initialization
        STOP = 1;
        % Update lenght
        NS = length(ind);
        % Update J matrix
        J22 = zeros(NS - NG + 1);
        % Reduce maximum number of iterations
        self.TN.itMax_gibbs = self.TN.itMax_gibbs / 2;
        % Compute chemical equilibrium considering condensed species
        equilibrium_loop;
    end
    
    % Update matrix J (jacobian) to compute the thermodynamic derivatives
    J = update_matrix_J(A0_T, J22, N0, NP, ind_nswt, ind_swt, NE);
    J(end, end) = 0;
    % Standard-state enthalpy [J/mol]
    h0 = set_h0(self.S.LS, TP, self.DB);
    % Dimensionless standard-state enthalpy
    H0RT = h0 / R0TP;
    % Compute thermodynamic derivates
    [dNi_T, dN_T] = equilibrium_dT_reduced(J, N0, A0, NE, ind_nswt, ind_swt, ind_elem, H0RT);
    [dNi_p, dN_p] = equilibrium_dp_reduced(J, N0, A0, NE, ind_nswt, ind_swt, ind_elem);

    % NESTED FUNCTION
    function x = equilibrium_loop
        % Calculate composition at chemical equilibrium

        % Initialization
        it = 0; counter_errors = 0;
        itMax = self.TN.itMax_gibbs;
        STOP = 1.0;
        
        % Calculations
        while STOP > self.TN.tol_gibbs && it < itMax
            it = it + 1;
            % Chemical potential
            muRT(ind_nswt) =  g0(ind_nswt) / R0TP + log(N0(ind_nswt, 1) / NP) + log(pP);
            
            % Construction of matrix J
            J = update_matrix_J(A0_T, J22, N0, NP, ind_nswt, ind_swt, NE);
            
            % Construction of vector b      
            b = update_vector_b(A0, N0, NP, NatomE, self.E.ind_E, ind, ind_nswt, ind_swt, ind_ions, muRT);
            
            % Solve of the linear system J*x = b
            x = J\b;
            
            % Check singular matrix
            if any(isnan(x)) || any(isinf(x))
                
                % Update temp indeces
                ind_nswt = ind_nswt_0;

                if FLAG_CONDENSED
                    ind_swt = ind_swt_0;
                end

                % Reset removed species to 1e-6 to try the avoid singular matrix
                N0( N0([ind_nswt, ind_swt], 1) < self.TN.tolN, 1) = 1e-6;

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
            Delta_ln_nj = update_Delta_ln_nj(A0, pi_i, Delta_ln_NP, muRT, ind_nswt);
            
            % Calculate correction factor
            delta = relax_factor(NP, N0(ind, 1), [Delta_ln_nj; Delta_nj], Delta_ln_NP, NG);

            % Apply correction
            N0(ind_nswt, 1) = N0(ind_nswt, 1) .* exp(delta * Delta_ln_nj);
            N0(ind_swt, 1) = N0(ind_swt, 1) + delta * Delta_nj;
            NP = sum(N0(ind_nswt, 1)) * exp(delta * Delta_ln_NP);
            
            % Compute STOP criteria
            STOP = compute_STOP(NP, Delta_ln_NP, N0(ind, 1), [Delta_ln_nj; Delta_nj], NG, A0(ind, :), NatomE, max_NatomE, self.TN.tolE);
            
            % Update temp values in order to remove species with moles < tolerance
            [ind, ind_swt, ind_nswt, ind_ions, NG, NS] = update_temp(N0, ind, ind_swt, ind_nswt, ind_ions, NP, SIZE);
            
            % Debug 
            % aux_delta(it) = delta;
            % aux_STOP(it) = STOP;
        end

        % Check convergence of charge balance (ionized species)
        [N0, STOP_ions] = check_convergence_ions(N0, A0, self.E.ind_E, ind_nswt, ind_ions, self.TN.tolN, self.TN.tol_pi_e, self.TN.itMax_ions);
        
        if ~any(N0(ind_ions) > self.TN.tolN) && ~isempty(N0(ind_ions))
            [ind, ind_swt, ind_nswt, ind_ions, NG, NS, N0] = update_temp(N0, ind, ind_swt, ind_nswt, ind_ions, NP, SIZE);
            
            if ~isempty(ind_ions)
                return
            end
            
            % Remove element E from matrix
            ind_elem(self.E.ind_E) = [];
            NE = NE - 1;
        end
        
        % Debug
        % debug_plot_error(it, aux_STOP, aux_delta);
    end

end

% SUB-PASS FUNCTIONS
function [N0, NP] = initialize_moles(N0, NP, ind_nswt, NG, guess_moles)
    % Initialize composition from a previous calculation or using an
    % uniform distribution [mol]

    if isempty(guess_moles)
        N0(ind_nswt, 1) = NP/NG;
    else
        N0(ind_nswt, 1) = guess_moles(ind_nswt);
        NP = sum(guess_moles(ind_nswt));
    end

end

function [ind, ind_swt, FLAG_CONDENSED] = check_condensed_species(A0, x, ind, ind_nswt, ind_swt, NE, muRT)
    % Check condensed species
    
    % Initialization
    FLAG_CONDENSED = false;
    
    % Check if there are condensed species
    if isempty(ind_swt)
        return
    end
    
    % Get length condensed species
    NC = length(ind_swt);
    
    % Initialize false vector
    temp = false(NC, 1);
    
    for i = length(NC):-1:1
        % Only check if there were atoms of the species in the initial
        % mixture
        if ~sum(A0(ind_swt(i), :))
            continue
        end

        dG_dn = muRT(ind_swt(i)) - dot(x(end-NE:end-1), A0(ind_swt(i), :));
        
        if dG_dn < 0
            temp(i) = true;
        end

    end
    
    % Check if any condensed species have to be considered
    if ~sum(temp)
        ind_swt = [];
        return
    end
    
    % Update flag
    FLAG_CONDENSED = true;

    % Update indeces
    ind_swt = ind_swt(temp);
    ind = [ind_nswt, ind_swt];
end

function ind_remove_species = find_remove_species(A0, FLAG_REMOVE_ELEMENTS)
    % Get flag of species to be removed from stoichiometrix matrix A0
    ind_remove_species = find(sum(A0(:, FLAG_REMOVE_ELEMENTS) > 0, 2) > 0);
end

function [A0, ind_remove_species, ind_E, NatomE] = remove_elements(NatomE, A0, ind_E, tol)
    % Find zero sum elements

    % Define temporal fictitious value if there are ionized species
    temp_NatomE = NatomE;
    temp_NatomE(ind_E) = 1;

    % Get flag of elements to be removed from stoichiometrix matrix
    FLAG_REMOVE_ELEMENTS = temp_NatomE' <= tol;

    % Get the species to be removed from stoichiometrix matrix
    ind_remove_species = find_remove_species(A0, FLAG_REMOVE_ELEMENTS);

    % Update stoichiometrix matrix
    A0(:, FLAG_REMOVE_ELEMENTS) = [];

    % Set number of atoms
    NatomE(FLAG_REMOVE_ELEMENTS) = [];

    % Check position "element" electron
    if ind_E
        ind_E = ind_E - sum(FLAG_REMOVE_ELEMENTS(1:ind_E-1));
    end
end

function [ind, ind_nswt, ind_swt, ind_ions, ind_elem, NE, NG, NS] = temp_values(S, NatomE)
    % List of indices with nonzero values and lengths
    ind_elem = 1:length(NatomE);
    ind_nswt = S.ind_nswt;
    ind_swt = S.ind_swt;
    ind_ions = S.ind_nswt(S.ind_ions);
    ind_cryogenic = S.ind_cryogenic;
    ind = [ind_nswt, ind_swt];
    [ind, ind_swt] = check_cryogenic(ind, ind_swt, ind_cryogenic);

    % Update lengths
    NE = length(NatomE);
    NG = length(ind_nswt);
    NS = length(ind);
end

function [ind_swt, ind_nswt, ind_ions] = remove_item(n, ind, ind_swt, ind_nswt, ind_ions, NP, SIZE)
    % Remove species from the computed indeces list of gaseous and condensed
    % species and append the indeces of species that we have to remove
    for i=1:length(n)
        if log(n(i) / NP) < -SIZE
            ind_swt(ind_swt==ind(i)) = [];
            ind_nswt(ind_nswt==ind(i)) = [];
            ind_ions(ind_ions==ind(i)) = [];
        end
        
    end

end

function [ind, ind_swt, ind_nswt, ind_ions, NG, NS] = update_temp(N0, ind, ind_swt, ind_nswt, ind_ions, NP, SIZE)
    % Update temp items
    [ind_swt, ind_nswt, ind_ions] = remove_item(N0(ind, 1), ind, ind_swt, ind_nswt, ind_ions, NP, SIZE);
    ind = [ind_nswt, ind_swt];
    NG = length(ind_nswt);
    NS = length(ind);
end

function [ind, ind_swt] = check_cryogenic(ind, ind_swt, ind_cryogenic)
    % Remove cryogenic species from calculations
    for i = 1:length(ind_cryogenic)
        ind(ind == ind_cryogenic(i)) = [];
        ind_swt(ind_swt == ind_cryogenic(i)) = [];
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

function STOP = compute_STOP(NP, deltaNP, N0, deltaN0, NG, A0, NatomE, max_NatomE, tolE)
    % Compute stop criteria
    NPi = sum(N0);
    deltaN1 = N0 .* abs(deltaN0) / NPi;
    deltaN1(NG + 1:end) = abs(deltaN0(NG + 1:end)) / NPi;
    deltaN2 = NP * abs(deltaNP) / NPi;
    deltab = abs(NatomE - sum(N0 .* A0, 1)) / max_NatomE;
    deltab = max(deltab(NatomE > tolE));
    STOP = max(max(max(deltaN1), deltaN2), deltab);
end

function J11 = update_matrix_J11(A0_T, N0, ind_nswt, NE)
    % Compute submatrix J11
    for k = NE:-1:1
        J11(:, k) = sum(A0_T(k, ind_nswt) .* A0_T(:, ind_nswt) .* N0(ind_nswt), 2);
    end
end

function J12 = update_matrix_J12(A0_T, N0, ind_nswt, ind_swt)
    % Compute submatrix J12
    J12_1 = A0_T(:, ind_swt);
    J12_2 = sum(A0_T(:, ind_nswt) .* N0(ind_nswt), 2);
    J12 = [J12_1, J12_2];
end

function J22 = update_matrix_J22(J22, N0, NP, ind_nswt)
    % Compute submatrix J22
    J22(end, end) = sum(N0(ind_nswt, 1) - NP);
end

function J = update_matrix_J(A0_T, J22, N0, NP, ind_nswt, ind_swt, NE)
    % Compute matrix J
    J11 = update_matrix_J11(A0_T, N0, ind_nswt, NE);
    J12 = update_matrix_J12(A0_T, N0, ind_nswt, ind_swt);
    J22 = update_matrix_J22(J22, N0, NP, ind_nswt);
    J = [J11, J12; J12', J22];
end

function b = update_vector_b(A0, N0, NP, NatomE, ind_E, ind, ind_nswt, ind_swt, ind_ions, muRT) 
    % Compute vector b
    bi = N0(ind, 1)' * A0(ind, :);

    if any(ind_ions)
        bi(ind_E) = NatomE(ind_E);
    end

    NP_0 = NP + sum(N0(ind_nswt, 1) .* muRT(ind_nswt) - N0(ind_nswt, 1));
    b = [(NatomE - bi + sum(A0(ind_nswt, :) .* N0(ind_nswt, 1) .* muRT(ind_nswt)))'; muRT(ind_swt); NP_0];
end

function Delta_ln_nj = update_Delta_ln_nj(A0, pi_i, Delta_NP, muRT, ind_nswt)
    % Compute correction moles of gases
    Delta_ln_nj = sum(A0(ind_nswt, :)' .* pi_i)' + Delta_NP - muRT(ind_nswt);
end

function [N0, STOP] = check_convergence_ions(N0, A0, ind_E, ind_nswt, ind_ions, TOL, TOL_pi, itMax)
    % Check convergence of ionized species

    % Initialization
    STOP = 0;

    % Check if there are ionized species
    if ~any(ind_ions)
        return
    end
    
    % Get error in the electro-neutrality of the mixture
    [delta_ions, ~] = ions_factor(N0, A0, ind_E, ind_nswt, ind_ions);
    
    % Reestimate composition of ionized species
    if abs(delta_ions) > TOL_pi
        [N0, STOP] = recompute_ions(N0, A0, ind_E, ind_nswt, ind_ions, delta_ions, TOL, TOL_pi, itMax);
    end
    
end

function [N0, STOP] = recompute_ions(N0, A0, ind_E, ind_nswt, ind_ions, delta_ions, TOL, TOL_pi, itMax)
    % Reestimate composition of ionized species
    
    % Initialization
    A0_ions = A0(ind_ions, ind_E);
    STOP = 1;
    it = 0;
    % Reestimate composition of ionized species
    while STOP > TOL_pi && it < itMax
        it = it + 1;
        % Apply correction
        N0(ind_ions, 1) = N0(ind_ions, 1) .* exp(A0_ions * delta_ions);
        % Compute correction of the Lagrangian multiplier for ions divided by RT
        [delta_ions, ~] = ions_factor(N0, A0, ind_E, ind_nswt, ind_ions);
        STOP = abs(delta_ions);
    end   
    
    Xi_ions = N0(ind_ions, 1) / sum(N0(:, 1));

    % Set error to zero if molar fraction of ionized species are below
    % tolerance
    if ~any(Xi_ions > TOL)
        STOP = 0;
    end

end

function [delta, deltaN3] = ions_factor(N0, A0, ind_E, ind_nswt, ind_ions)
    % Compute relaxation factor for ionized species
    
    if ~any(ind_ions)
        delta = [];
        deltaN3 = 0;
        return
    end

    delta = -sum(A0(ind_nswt, ind_E) .* N0(ind_nswt, 1))/ ...
             sum(A0(ind_nswt, ind_E).^2 .* N0(ind_nswt, 1));
    deltaN3 = abs(sum(N0(ind_nswt, 1) .* A0(ind_nswt, ind_E)));
end