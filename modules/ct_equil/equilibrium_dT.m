function [dNi_T, dN_T] = equilibrium_dT(self, moles, T, A0, temp_NG, temp_NS, temp_NE, temp_ind, temp_ind_nswt, temp_ind_swt, temp_ind_E)
    % Obtain thermodynamic derivative of the moles of the species and of the moles of the mixture
    % respect to temperature from a given composition [moles] at equilibrium
    %
    % Args:
    %     self (struct): Data of the mixture, conditions, and databases
    %     moles (float): Equilibrium composition [moles]
    %     T (float): Temperature [K]
    %     A0 (float): Stoichiometric matrix
    %     temp_NG (float): Temporal total number of gaseous species
    %     temp_NS (float): Temporal total number of species
    %     temp_NE (float): Temporal total number of elements
    %     temp_ind (float): Temporal index of species in the final mixture
    %     temp_ind_nswt (float): Temporal index of gaseous species in the final mixture
    %     temp_ind_swt (float): Temporal index of condensed species in the final mixture
    %     temp_ind_E (float): Temporal index of elements in the final mixture
    %
    % Returns:
    %     Tuple containing
    %
    %     * dNi_T (float): Thermodynamic derivative of the moles of the species respect to temperature
    %     * dN_T (float):  Thermodynamic derivative of the moles of the mixture respect to temperature

    % Abbreviations ---------------------
    S = self.S;
    C = self.C;
    % -----------------------------------
    R0TP = C.R0 * T; % [J/mol]
    % Initialization
    NP = sum(moles(temp_ind_nswt, 1));
    dNi_T = zeros(length(moles), 1);
    % Dimensionless Standard-state enthalpy [J/mol]
    h0 = set_h0(S.LS, T, self.DB);
    H0RT = h0 / R0TP;
    % Construction of part of matrix J
    J1 = update_matrix_J1(A0, temp_NG, temp_NS, temp_ind, temp_ind_E);
    J22 = zeros(temp_NE + 1);
    A0_T = A0';
    % Construction of matrix J
    J = update_matrix_J(A0_T, J1, J22, moles, NP, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG, temp_NS);
    % Construction of vector b
    b = update_vector_b(temp_ind, temp_ind_E, H0RT);
    % Solve of the linear system J*x = b
    x = J \ b;
    dNi_T(temp_ind) = x(1:temp_NS);
    dN_T = x(end);
end

% SUB-PASS FUNCTIONS
function J1 = update_matrix_J1(A0, temp_NG, temp_NS, temp_ind, temp_ind_E)
    % Update stoichiometric submatrix J1
    J11 = eye(temp_NS);
    J11(temp_NG + 1:end, temp_NG + 1:end) = 0;
    J12 =- [A0(temp_ind, temp_ind_E), [ones(temp_NG, 1); zeros(temp_NS - temp_NG, 1)]];
    J1 = [J11, J12];
end

function J2 = update_matrix_J2(A0_T, J22, moles, NP, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG, temp_NS)
    % Update stoichiometric submatrix J2
    J21_1 = [moles(temp_ind_nswt, 1)' .* A0_T(temp_ind_E, temp_ind_nswt); moles(temp_ind_nswt, 1)'];
    J21_2 = [A0_T(temp_ind_E, temp_ind_swt); zeros(1, temp_NS - temp_NG)];
    J21 = [J21_1, J21_2];
    J22(end, end) = -NP;
    J2 = [J21, J22];
end

function J = update_matrix_J(A0_T, J1, J22, moles, NP, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG, temp_NS)
    % Update stoichiometric matrix J
    J2 = update_matrix_J2(A0_T, J22, moles, NP, temp_ind_nswt, temp_ind_swt, temp_ind_E, temp_NG, temp_NS);
    J = [J1; J2];
end

function b = update_vector_b(temp_ind, temp_ind_E, H0RT)
    % Update coefficient vector b
    b = [H0RT(temp_ind); zeros(length(temp_ind_E) + 1, 1)];
end
