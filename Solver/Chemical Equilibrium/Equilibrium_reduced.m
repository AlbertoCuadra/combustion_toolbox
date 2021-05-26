function [N0, STOP] = Equilibrium_reduced(app, pP, TP, strR)
% Generalized Gibbs minimization method

% Abbreviations ---------------------
S = app.S;
C = app.C;
strThProp = app.strThProp;
% -----------------------------------

N0 = C.N0.value;
A0 = C.A0.value;
R0TP = C.R0 * TP; % [J/(mol)]
% Initialization
% NatomE = N_CC(:,1)' * A0;
NatomE = strR.NatomE;
NP_0 = 0.1;
NP = NP_0;

it = 0;
itMax = 500;
% itMax = 50 + round(S.NS/2);
SIZE = -log(C.tolN);
STOP = 1.;

% Find indeces of the species/elements that we have to remove from the stoichiometric matrix A0
% for the sum of elements whose value is <= tolN
ind_A0_E0 = remove_elements(NatomE, A0, C.tolN);
% List of indices with nonzero values
[temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NE] = temp_values(S, NatomE, C.tolN);
% Update temp values
[temp_ind, temp_ind_swt, temp_ind_nswt, temp_NS] = update_temp(N0, N0(ind_A0_E0, 1), ind_A0_E0, temp_ind_swt, temp_ind_nswt, C.tolN, SIZE);
% Initialize species vector N0 
N0(temp_ind, 1) = 0.1/temp_NS;
% Dimensionless Standard Gibbs free energy 
g0 = set_g0(S.LS, TP, strThProp);
G0RT = g0/R0TP;

while STOP > C.tolN && it < itMax
    it = it + 1;
    % Gibbs free energy
    G0RT(temp_ind_nswt) =  g0(temp_ind_nswt) / R0TP + log(N0(temp_ind_nswt, 1) / NP) + log(pP);
    % Construction of matrix A
    A = update_matrix_A(A0, N0, NP, temp_ind, temp_ind_E);
    % Construction of vector b            
    b = update_vector_b(A0, N0, NP, NatomE, temp_ind, temp_ind_E, G0RT);
    % Solve of the linear system A*x = b
    x = A\b;
    % Compute log variation of moles
    DeltaNi_log = x(end) + sum(A0(temp_ind, temp_ind_E)' .* x(1:end-1))' - G0RT(temp_ind);
    % Calculate correction factor
    % update_SIZE(N0, A0, temp_ind, temp_ind_E, C.tolN)
    e = relax_factor(NP, N0(temp_ind, 1), DeltaNi_log, x(end), SIZE);
    % Apply correction
    N0_log = log(N0(temp_ind, 1)) + e * DeltaNi_log;
    NP_log = log(NP) + e * x(end);
    % Apply antilog
    [N0, NP] = apply_antilog(N0, N0_log, NP_log, temp_ind);
    % Compute STOP criteria
    STOP = compute_STOP(NP_0, NP, x(end), N0(temp_ind, 1), DeltaNi_log);
end
end
% NESTED FUNCTIONS
function g0 = set_g0(ls, TP, strThProp)
    for i=length(ls):-1:1
        species = ls{i};
        g0(i, 1) = species_g0(species, TP, strThProp)* 1e3;
    end
end

function ind_A = find_ind_Matrix(A, bool)
    ls = find(bool>0);
    ind_A = zeros(1, length(ls));
    i = 1;
    for ind = ls
        ind_A(i) = find(A(:, ind) > 0);
        i = i + 1;
    end
end

function ind_A0_E0 = remove_elements(NatomE, A0, tol)
    % Find zero sum elements
    bool_E0 = NatomE <= tol;
    ind_A0_E0 = find_ind_Matrix(A0, bool_E0);
end

function [temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NE] = temp_values(S, NatomE, tol)
    % List of indices with nonzero values and lengths
    temp_ind_E = find(NatomE > tol);
    temp_ind_nswt = S.ind_nswt;
    temp_ind_swt = S.ind_swt;
    temp_NE = length(temp_ind_E);
end

function [ls1, ls2] = remove_item(N0, zip1, zip2, ls1, ls2, NP, SIZE)
    % Remove species from the computed indeces list of gaseous and condensed
    % species and append the indeces of species that we have to remove
    for i=1:length(zip1)
        n = zip1(i);
        ind = zip2(i);
        if log(n/NP) < -SIZE
            if N0(ind, 2)
                ls1(ls1==ind) = [];
            else
                ls2(ls2==ind) = [];
            end
        end
    end
end

function [temp_ind, temp_ind_swt, temp_ind_nswt, temp_NS] = update_temp(N0, zip1, zip2, ls1, ls2, NP, SIZE)
    % Update temp items
    [temp_ind_swt, temp_ind_nswt] = remove_item(N0, zip1, zip2, ls1, ls2, NP, SIZE);
    temp_ind = sort([temp_ind_nswt, temp_ind_swt]);
    temp_NS = length(temp_ind);
end
function [A1, A12] = update_matrix_A1(A0, N0, temp_ind, temp_ind_E)
    % Update stoichiometric submatrix A1
    for i=length(temp_ind_E):-1:1
        A11(temp_ind_E, i) = sum(A0(temp_ind, temp_ind_E) .* A0(temp_ind, temp_ind_E(i)) .* N0(temp_ind, 1));
    end
    A12 = sum(A0(temp_ind, temp_ind_E) .* N0(temp_ind, 1));
    A1 = [A11(temp_ind_E, :); A12];
end
function A2 = update_matrix_A2(A12, N0, NP, temp_ind)
    % Update stoichiometric submatrix A2
    A2 = [A12'; sum(N0(temp_ind, 1) .* (1.0 - N0(temp_ind, 2)) - NP)];
end

function A = update_matrix_A(A0, N0, NP, temp_ind, temp_ind_E)
    % Update stoichiometric matrix A
    [A1, A12] = update_matrix_A1(A0, N0, temp_ind, temp_ind_E);
    A2 = update_matrix_A2(A12, N0, NP, temp_ind);
    A = [A1, A2];
end

function b = update_vector_b(A0, N0, NP, NatomE, temp_ind, temp_ind_E, G0RT)
    % Update coefficient vector b
    bi_0 = (NatomE(temp_ind_E) - sum(N0(temp_ind, 1) .* A0(temp_ind, temp_ind_E) .* (1.0 - G0RT(temp_ind))))';
    NP_0 = NP - sum(N0(temp_ind, 1) .* (1.0 - N0(temp_ind, 2))) + sum(N0(temp_ind, 1) .* G0RT(temp_ind));
    b = [bi_0; NP_0];
end

function relax = relax_factor(NP, n, n_log_new, DeltaNP, SIZE)
    % Compute relaxation factor
    bool = log(n)/log(NP) <= -SIZE & n_log_new >= 0;
    e = ones(length(n), 1);
    e(bool) = abs(-log(n(bool)/NP) - 9.2103404 ./ (n_log_new(bool) - DeltaNP));
    e(~bool) = min(2./max(5*abs(DeltaNP), abs(n_log_new(~bool))));          
    relax = min(1, min(e));  
end

function [N0, NP] = apply_antilog(N0, N0_log, NP_log, temp_ind)
    N0(temp_ind, :) = [exp(N0_log), N0(temp_ind, 2)];
    NP = exp(NP_log);
end

function DeltaN = compute_STOP(NP_0, NP, DeltaNP, zip1, zip2)
    DeltaN1 = max(max(zip1 .* abs(zip2) / NP));
    DeltaN3 = NP_0 * abs(DeltaNP) / NP;
    % Deltab = [abs(bi - sum(N0[:, 0] * A0[:, i])) for i, bi in enumerate(x[S.NS:-1]) if bi > 1e-6]
    DeltaN = max(DeltaN1, DeltaN3);
end