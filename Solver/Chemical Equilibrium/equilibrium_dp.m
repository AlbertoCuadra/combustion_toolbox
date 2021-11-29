function [dNi_p, dN_p] = equilibrium_dp(self, N0, strR)
% Generalized Gibbs minimization method

% Abbreviations ---------------------
S = self.S;
C = self.C;
TN = self.TN;
% -----------------------------------
A0 = C.A0.value;
% Initialization
% NatomE = N_CC(:,1)' * A0;
NatomE = strR.NatomE;
NP = sum(N0(:, 1));
dNi_p = zeros(length(N0), 1);

SIZE = -log(TN.tolN);
% Find indeces of the species/elements that we have to remove from the stoichiometric matrix A0
% for the sum of elements whose value is <= tolN
ind_A0_E0 = remove_elements(NatomE, A0, TN.tolN);
% List of indices with nonzero values
[temp_ind_nswt, temp_ind_swt, temp_ind_cryogenic, temp_ind_E, temp_NE] = temp_values(S, NatomE, TN.tolN);
% Update temp values
[temp_ind, temp_ind_swt, temp_ind_nswt, temp_NG, temp_NS] = update_temp(N0, N0(ind_A0_E0, 1), ind_A0_E0, temp_ind_swt, temp_ind_nswt, temp_ind_cryogenic, TN.tolN, SIZE);
temp_NS0 = temp_NS + 1;
% Construction of part of matrix A (complete)
[A1, ~] = update_matrix_A1(A0, [], temp_NG, temp_NS, temp_NS0, temp_ind, temp_ind_E);
A22 = zeros(temp_NE + 1);
A0_T = A0';
% Construction of matrix A
A = update_matrix_A(A0_T, A1, A22, N0, NP, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG, temp_NS);
% Construction of vector b            
b = update_vector_b(temp_NG, temp_NS, temp_ind_E);
% Solve of the linear system A*x = b
x = A\b;
dNi_p(temp_ind) = x(1:temp_NS);
dN_p = x(end);
end

% SUB-PASS FUNCTIONS
function ind_A = find_ind_Matrix(A, bool)
    ls = find(bool>0);
%     ind_A = zeros(1, length(ls));
    ind_A = [];
    i = 1;
    for ind = ls
        ind_A = [ind_A, find(A(:, ind) > 0)'];
        i = i + 1;
    end
end

function ind_A0_E0 = remove_elements(NatomE, A0, tol)
    % Find zero sum elements
    bool_E0 = NatomE <= tol;
    ind_A0_E0 = find_ind_Matrix(A0, bool_E0);
end

function [temp_ind_nswt, temp_ind_swt, temp_ind_cryogenic, temp_ind_E, temp_NE] = temp_values(S, NatomE, tol)
    % List of indices with nonzero values and lengths
    temp_ind_E = find(NatomE > tol);
    temp_ind_nswt = S.ind_nswt;
    temp_ind_swt = S.ind_swt;
    temp_ind_cryogenic = S.ind_cryogenic;
    temp_NE = length(temp_ind_E);
end

function [ls1, ls2] = remove_item(N0, n, ind, ls1, ls2, NP, SIZE)
    % Remove species from the computed indeces list of gaseous and condensed
    % species and append the indeces of species that we have to remove
    for i=1:length(n)
        if log(n(i)/NP) < -SIZE
            if N0(ind(i), 2)
                ls1(ls1==ind(i)) = [];
            else
                ls2(ls2==ind(i)) = [];
            end
        end
    end
end

function [temp_ind, temp_ind_swt, temp_ind_nswt, temp_NG, temp_NS] = update_temp(N0, zip1, zip2, ls1, ls2, temp_ind_cryogenic, NP, SIZE)
    % Update temp items
    [temp_ind_swt, temp_ind_nswt] = remove_item(N0, zip1, zip2, ls1, ls2, NP, SIZE);
    temp_ind = [temp_ind_nswt, temp_ind_swt];
    [temp_ind, temp_ind_swt] = check_cryogenic(temp_ind, temp_ind_swt, temp_ind_cryogenic);
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
    try
        temp_ind = setdiff(temp_ind, temp_ind_cryogenic);
        temp_ind_swt = setdiff(temp_ind_swt, temp_ind_cryogenic);
        try
            temp_ind_swt(1);
        catch
            temp_ind_swt = [];
        end
    catch
        % do nothing
    end
end

function A2 = update_matrix_A2(A0_T, A22, N0, NP, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG, temp_NS)
    % Update stoichiometric submatrix A2
    A21_1 = [N0(temp_ind_nswt, 1)' .* A0_T(temp_ind_E, temp_ind_nswt); N0(temp_ind_nswt, 1)'];
    A21_2 = [A0_T(temp_ind_E, temp_ind_swt); zeros(1, temp_NS-temp_NG)];
    A21 = [A21_1, A21_2];
    A22(end, end) = -NP;
    A2 = [A21, A22];
end

function A = update_matrix_A(A0_T, A1, A22, N0, NP, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG, temp_NS)
    % Update stoichiometric matrix A
    A2 = update_matrix_A2(A0_T, A22, N0, NP, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG, temp_NS);
    A = [A1; A2];
end

function b = update_vector_b(temp_NG, temp_NS, temp_ind_E)
    % Update coefficient vector b
    b = [-ones(temp_NG,1); zeros(temp_NS - temp_NG + length(temp_ind_E) + 1, 1)];
end