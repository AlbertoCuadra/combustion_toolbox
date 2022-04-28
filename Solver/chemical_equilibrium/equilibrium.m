function [N0, STOP] = equilibrium(self, pP, TP, mix1, guess_moles)
    % Obtain equilibrium composition [moles] for the given temperature [K] and pressure [bar].
    % The code stems from the minimization of the free energy of the system by using Lagrange
    % multipliers combined with a Newton-Raphson method, upon condition that initial gas
    % properties are defined by two functions of states. e.g., temperature and pressure.
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
    %     - N0 (float): Equilibrium composition [moles] for the given temperature [K] and pressure [bar]
    %     - STOP (float): Relative error [-] 

    % Generalized Gibbs minimization method
    
    % Abbreviations ---------------------
    S = self.S;
    C = self.C;
    TN = self.TN;
    % -----------------------------------
    % Definitions
    N0 = C.N0.value;
    A0 = C.A0.value;
    R0TP = C.R0 * TP; % [J/mol]
    % Initialization
    NatomE = mix1.NatomE';
%     A0 = A0(:, NatomE > TN.tolN);
    max_NatomE = max(NatomE);
    NP = 0.1;
    SIZE = -log(TN.tolN);
    % Find indeces of the species/elements that we have to remove from the stoichiometric matrix A0
    % for the sum of elements whose value is <= tolN
    [A0, ind_A0_E0, NatomE] = remove_elements(NatomE, A0, TN.tolN);
    % List of indices with nonzero values
    [temp_ind, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NE, temp_NG, temp_NS] = temp_values(S, NatomE, TN.tolN);
    % Update temp values
    [temp_ind, temp_ind_swt, temp_ind_nswt, temp_NG] = update_temp(N0, N0(ind_A0_E0, 1), ind_A0_E0, temp_ind_swt, temp_ind_nswt, NP, SIZE);
    % Initialize species vector N0    
    [N0, NP] = initialize_moles(N0, NP, temp_ind_nswt, temp_NG, guess_moles);
    % Update temp values
    temp_NS0 = temp_NS + 1;
    
    temp_ind_nswt_0 = temp_ind_nswt;
    temp_ind_swt_0 = temp_ind_swt;
    temp_ind_swt = [];
    temp_ind = [temp_ind_nswt, temp_ind_swt];
    temp_NS = length(temp_ind);
    
    % Standard Gibbs free energy [J/mol]
    g0 = set_g0(S.LS, TP, self.DB);
    % Dimensionless Chemical potential
    muRT_0 = g0/R0TP;
    muRT = muRT_0;
    % Get Molar mass [kg/mol]
    for i = S.NS:-1:1
        W(i) = self.DB.(S.LS{i}).mm * 1e-3;
    end
    lambda_0 = [0.01118, 0.05523, 0.36412, 0.54797, 1, 1, 1, 1, 1, 1, 0.58217, 0.00022, 0.00162, 0.01204, 0.09254, 0.97068, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    % Construction of part of matrix A
    [A1, temp_NS0] = update_matrix_A1(A0, [], temp_NG, temp_NS, temp_NS0, temp_ind, temp_ind_E);
    A22 = zeros(temp_NE + 1);
    A0_T = A0';
    % Solve system
    x = equilibrium_loop;
    % Check condensed species
    [temp_ind, temp_ind_swt, FLAG] = check_condensed_species(A0, x, temp_ind_nswt, temp_ind_swt_0, temp_ind_E, temp_NE, muRT);
    if FLAG
        if any(isnan(x))
            % Update temp values
            [temp_ind, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NE, temp_NG, temp_NS] = temp_values(S, NatomE, TN.tolN);
            % Initialize species vector N0 
            N0(:, 1) = NP/temp_NS;
            % Construction of part of matrix A
            A22 = zeros(temp_NE + 1);
            A0_T = A0';
        end
        STOP = 1;
        temp_NS = length(temp_ind);
        temp_NS0 = temp_NS + 1;
        [A1, temp_NS0] = update_matrix_A1(A0, A1, temp_NG, temp_NS, temp_NS0, temp_ind, temp_ind_E);

        TN.itMax_gibbs = TN.itMax_gibbs / 2;
        equilibrium_loop;
    end
    % NESTED FUNCTION
    function x = equilibrium_loop
        it = 0;
%         itMax = 50 + round(S.NS/2);
        itMax = TN.itMax_gibbs;
        STOP = 1;
        while STOP > TN.tolN && it < itMax
            it = it + 1;
            % Chemical potential
            muRT(temp_ind_nswt) =  muRT_0(temp_ind_nswt) + log(N0(temp_ind_nswt, 1) / NP) + log(pP);
            % Gibbs free energy [cal/g]
            Gibbs(it) = dot(N0(:, 1), muRT * R0TP) / dot(N0(:, 1), W) / 4186.8;
%             fprintf('Gibbs: %f\n', Gibbs(it));
            % Construction of matrix A
            A = update_matrix_A(A0_T, A1, A22, N0, NP, temp_ind, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG);
            % Check singularity
%             A = check_singularity(A, it);
            % Construction of vector b            
            b = update_vector_b(A0, N0, NP, NatomE, temp_ind, temp_ind_nswt, temp_ind_E, muRT);
            % Solve of the linear system A*x = b
            x = A\b;
            % Calculate correction factor
            lambda = relax_factor(NP, N0(temp_ind, 1), x(1:temp_NS), x(end), temp_NG, SIZE);
%             lambda = lambda_0(i);
            % Apply correction
            N0(temp_ind_nswt, 1) = exp(log(N0(temp_ind_nswt, 1)) + lambda * x(1:temp_NG));
            N0(temp_ind_swt, 1) = N0(temp_ind_swt, 1) + lambda * x(temp_NG+1:temp_NS);
            NP = exp(log(NP) + lambda * x(end));
            % Compute STOP criteria
            STOP = compute_STOP(NP, x(end), N0(temp_ind, 1), x(1:temp_NS), temp_NG, A0(temp_ind, temp_ind_E), NatomE, max_NatomE, TN.tolE);
            % Update temp values in order to remove species with moles < tolerance
            [temp_ind, temp_ind_swt, temp_ind_nswt, temp_NG, temp_NS, N0] = update_temp(N0, N0(temp_ind, 1), temp_ind, temp_ind_swt, temp_ind_nswt, NP, SIZE);
            % Update matrix A
            [A1, temp_NS0] = update_matrix_A1(A0, A1, temp_NG, temp_NS, temp_NS0, temp_ind, temp_ind_E);
            % Debug            
%             aux_lambda(it) = min(lambda);
%             aux_STOP(it) = STOP;
        end
%         debug_plot_error(it, aux_STOP, Gibbs);
    end

    function A = check_singularity(A, it)
        % Check if matrix is matrix is singular
        if it > 10*temp_NS
            if cond(A) > exp(0.5 * log(TN.tolN))
                FLAG_OLD = ~ismember(temp_ind_nswt_0, temp_ind_nswt);
                if any(FLAG_OLD)
                    temp_ind_nswt = temp_ind_nswt_0;
                    temp_ind = [temp_ind_nswt, temp_ind_swt];
                    temp_NG = length(temp_ind_nswt);
                    temp_NS = length(temp_ind);
                    N0(temp_ind_nswt(FLAG_OLD)) = TN.tolN * 1e-1;
                    [A1, temp_NS0] = update_matrix_A1(A0, A1, temp_NG, temp_NS, temp_NS0, temp_ind, temp_ind_E);
                    A = update_matrix_A(A0_T, A1, A22, N0, NP, temp_ind, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG);
                    N0(temp_ind_nswt(FLAG_OLD)) = 0;
                end
            end
        end
    end
end

% SUB-PASS FUNCTIONS
function [N0, NP] = initialize_moles(N0, NP, temp_ind_nswt, temp_NG, guess_moles)
    if isempty(guess_moles)
        N0(temp_ind_nswt, 1) = NP/temp_NG;
    else
        N0(temp_ind_nswt, 1) = guess_moles(temp_ind_nswt);
        NP = sum(guess_moles);
    end
end

function [temp_ind, temp_ind_swt, FLAG] = check_condensed_species(A0, x, temp_ind_nswt, temp_ind_swt_0, temp_ind_E, temp_NE, muRT)
    % Check condensed species
    aux = [];
    FLAG = false;
    if any(isnan(x))
        aux = true;
    else
        for i=length(temp_ind_swt_0):-1:1
            dG_dn = muRT(temp_ind_swt_0(i)) - dot(x(end-temp_NE:end-1), A0(temp_ind_swt_0(i), temp_ind_E));
            if dG_dn < 0
                aux = [aux, i];
            end
        end
    end
    if any(aux)
        FLAG = true;
    end
    if ~isempty(temp_ind_swt_0)
        temp_ind_swt = temp_ind_swt_0(aux);
    else
        temp_ind_swt = [];
    end
    temp_ind = [temp_ind_nswt, temp_ind_swt];
end

function ind_A = find_ind_Matrix(A, bool)
    ls = find(bool>0);
    ind_A = [];
    i = 1;
    for ind = ls
        ind_A = [ind_A, find(A(:, ind) > 0)'];
        i = i + 1;
    end
end

function [A0, ind_A0_E0, NatomE] = remove_elements(NatomE, A0, tol)
    % Find zero sum elements
    bool_E0 = NatomE' <= tol;
    ind_A0_E0 = find_ind_Matrix(A0, bool_E0);
    A0 = A0(:, NatomE > tol);
    NatomE = NatomE(NatomE > tol);
end

function [temp_ind, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NE, temp_NG, temp_NS] = temp_values(S, NatomE, tol)
    % List of indices with nonzero values and lengths
    temp_ind_E = find(NatomE > tol);
    temp_ind_nswt = S.ind_nswt;
    temp_ind_swt = S.ind_swt;
    temp_ind = [temp_ind_nswt, temp_ind_swt];
    temp_ind_cryogenic = S.ind_cryogenic;
    [temp_ind, temp_ind_swt] = check_cryogenic(temp_ind, temp_ind_swt, temp_ind_cryogenic);

    temp_NE = length(temp_ind_E);
    temp_NG = length(temp_ind_nswt);
    temp_NS = length(temp_ind);
end

function [ls1, ls2, N0] = remove_item(N0, n, ind, ls1, ls2, NP, SIZE)
    % Remove species from the computed indeces list of gaseous and condensed
    % species and append the indeces of species that we have to remove
    for i=1:length(n)
        if log(n(i)/NP) < -SIZE
            if N0(ind(i), 2)
                ls1(ls1==ind(i)) = [];
            else
                ls2(ls2==ind(i)) = [];
            end
            N0(ind(i), 1) = 0;
        end
    end
end

function [temp_ind, temp_ind_swt, temp_ind_nswt, temp_NG, temp_NS, N0] = update_temp(N0, zip1, zip2, ls1, ls2, NP, SIZE)
    % Update temp items
    [temp_ind_swt, temp_ind_nswt, N0] = remove_item(N0, zip1, zip2, ls1, ls2, NP, SIZE);
    temp_ind = [temp_ind_nswt, temp_ind_swt];
    temp_NG = length(temp_ind_nswt);
    temp_NS = length(temp_ind);
end

function [A1, temp_NS0] = update_matrix_A1(A0, A1, temp_NG, temp_NS, temp_NS0, temp_ind, temp_ind_E)
    % Update stoichiometric submatrix A1
    if temp_NS < temp_NS0
        A11 = eye(temp_NS);
        A11(temp_NG+1:end, temp_NG+1:end) = 0;
        A12 = -[A0(temp_ind, temp_ind_E), [ones(temp_NG, 1); zeros(temp_NS-temp_NG, 1)]];
        A1 = [A11, A12];
        temp_NS0 = temp_NS;
    end
end

function [temp_ind, temp_ind_swt] = check_cryogenic(temp_ind, temp_ind_swt, temp_ind_cryogenic)
    temp_ind = temp_ind(~ismember(temp_ind, temp_ind_cryogenic));
    temp_ind_swt = temp_ind_swt(~ismember(temp_ind_swt, temp_ind_cryogenic));
end

function A2 = update_matrix_A2(A0_T, A22, N0, NP, temp_ind, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG)
    % Update stoichiometric submatrix A2
    A20 = N0(temp_ind, 1)';
    A20(temp_NG+1:end) = 0;
    A21 = [[N0(temp_ind_nswt, 1)' .* A0_T(temp_ind_E, temp_ind_nswt), A0_T(temp_ind_E, temp_ind_swt)]; A20];
    A22(end, end) = -NP;
    A2 = [A21, A22];
end

function A = update_matrix_A(A0_T, A1, A22, N0, NP, temp_ind, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG)
    % Update stoichiometric matrix A
    A2 = update_matrix_A2(A0_T, A22, N0, NP, temp_ind, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG);
    A = [A1; A2];
end

function b = update_vector_b(A0, N0, NP, NatomE, temp_ind, temp_ind_nswt, temp_ind_E, muRT)
    % Update coefficient vector b
    bi = (sum(N0(temp_ind, 1) .* A0(temp_ind, temp_ind_E)))';
    NP_0 = NP - sum(N0(temp_ind_nswt, 1));
    b = [-muRT(temp_ind); NatomE - bi; NP_0];
end

function lambda = relax_factor(NP, ni, ni_log, DeltaNP, temp_NG, SIZE)
    % Compute relaxation factor
    FLAG_MINOR = ni(1:temp_NG) / NP <= 1e-8 & abs(ni_log(1:temp_NG)) > 0;
    lambda = 2./max(5*abs(DeltaNP), abs(ni_log));
    lambda(FLAG_MINOR) = abs((-log(ni(FLAG_MINOR)/NP) - 9.2103404) ./ (ni_log(FLAG_MINOR) - DeltaNP));
    lambda = min(1, min(lambda));
end

function [N0, NP] = apply_antilog(N0, NP_log, temp_ind_nswt)
    N0(temp_ind_nswt, 1) = exp(N0(temp_ind_nswt, 1));
    NP = exp(NP_log);
end

function [STOP, DeltaN1, DeltaN2, Deltab] = compute_STOP(NP, DeltaNP, N0, DeltaN0, temp_NG, A0, NatomE, max_NatomE, tolE)
    NPi = sum(N0);
    DeltaN1 = N0 .* abs(DeltaN0) / NPi;
    DeltaN1(temp_NG+1:end) = abs(DeltaN0(temp_NG+1:end)) / NPi;
    DeltaN2 = NP * abs(DeltaNP) / NPi;
    Deltab = abs(NatomE - sum(N0 .* A0, 1)');
    Deltab = max(Deltab(NatomE > tolE));
%     if max(Deltab) < max_NatomE * tolE
%         Deltab = 0;
%     end
    STOP = max(max(max(DeltaN1), DeltaN2), Deltab);
end