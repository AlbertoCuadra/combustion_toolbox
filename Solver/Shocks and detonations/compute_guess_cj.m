function [P, T, M1, R] = compute_guess_cj(self, str1, phi)
    % Paramenters
    gamma = str1.gamma;
    a1    = str1.sound;
    P     = 15;
    % Compute moles considering complete combustion
    [N_2, species] = complete_combustion(self, str1, phi);
    % Get enthalpy of formation [J/kg]
    hfi_2 = get_hf0(N_2, species, self.strThProp);
    % Compute heat release
    q = sum(N_2 .* hfi_2) - str1.hf / str1.mi * 1e3;
    % Compute dimensionless heat release
    Q = (gamma^2 - 1) / (2*a1^2) * q;
    % Compute minimum upstream Mach number (CJ condition)
    Mcj = sqrt(1 + Q) + sqrt(Q);
    % Compute jump relations and upstream Mach number (M1 >= Mcj)
    x = compute_M1_R1(P, gamma, Q, Mcj);
    M1 = x(1); R = x(2);
    % Check M1 >= Mcj
    [P, R, M1] = check_CJ_condition(self, P, R, gamma, Q, M1, Mcj);
    T = P / R;
end

% NESTED FUNCTIONS
function hfi = get_hf0(N0, species, strThProp)
    for i = length(N0):-1:1
        mi = N0(i) * strThProp.(species{i}).mm;   % [kg]
        hfi(i) = strThProp.(species{i}).hf ./ mi; % [J/kg]
    end
    hfi(isnan(hfi)) = 0;
    hfi(isinf(hfi)) = 0;
end

function [P, R, M1] = check_CJ_condition(self, P, R, gamma, Q, M1, Mcj)
    if M1 < Mcj || sctrmpi(self.PD.ProblemType, 'DET')
        M1 = Mcj;
        P  = real(compute_P(gamma, Q, M1));
        R  = real(compute_R(gamma, Q, M1));
    end
end

function P = compute_P(gamma, Q, M1)
    P = (gamma * M1^2 + 1 + gamma * ((M1^2 - 1)^2 - 4*Q*M1^2)^(1/2)) / (gamma + 1);
end

function R = compute_R(gamma, Q, M1)
    R = ((gamma + 1) * M1^2) / (gamma * M1^2 + 1 - ((M1^2 - 1)^2 - 4*Q*M1^2)^(1/2));
end

function x = compute_M1_R1(P, gamma, Q, Mcj)
    Rcj = compute_R(gamma, Q, Mcj);   
    x = fsolve(@(x) root2d(x, P, gamma, Q), [Mcj, Rcj]);
end

function F = root2d(x, P, gamma, Q)
    %    F == lhs - rhs = 0
    % x(1) == M1; x(2) == R
    F(1) = x(2) - ((gamma + 1) * x(1)^2) / (gamma * x(1)^2 + 1 - ((x(1)^2 - 1)^2 - 4*Q*x(1)^2)^(1/2));
    F(2) = x(1) - (P - 1) * (1 - x(2)^(-1)) / gamma;
end