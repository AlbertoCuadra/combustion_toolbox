function [str1,str2] = shock_incident(self, str1, u1)
% Abbreviations ---------------------
C = self.C;
TN = self.TN;
% -----------------------------------
R0 = C.R0;           % Universal gas constant [J/(mol-K)]
gamma1 = str1.gamma; % adiabatic index  [-]
str1.u = u1;         % velocity preshock [m/s]
M1 = u1/str1.sound;  % Mach number preshock [-]
% Miscelaneous
it = 0;
itMax = 50;
STOP = 1.;
% Initial estimates of p2/p1 and T2/T1
p2p1 = (2*gamma1 * M1^2 - gamma1 + 1) / (gamma1 + 1);
T2T1 = p2p1 * (2/M1^2 + gamma1 - 1) / (gamma1 + 1);
p2 = p2p1 * str1.p * 1e5; % [Pa]
T2 = T2T1 * str1.T;
while STOP > TN.tol_shocks && it < itMax
    it = it + 1;
    % Construction of the Jacobian matrix and vector b
    [J, b] = update_system(self, str1, p2, T2, R0);
    % Solve of the linear system A*x = b
    x = J\b;
    % Calculate correction factor
    lambda = relax_factor(x);
    % Apply correction
    [log_p2p1, log_T2T1] = apply_correction(x, p2p1, T2T1, lambda);
    % Apply antilog
    [p2, T2] = apply_antilog(str1, log_p2p1, log_T2T1); % [Pa] and [K]
    % Update ratios
    p2p1 = p2 / (str1.p * 1e5);
    T2T1 = T2 / str1.T;
    % Compute STOP criteria
    STOP = compute_STOP(x);
end

% Save state
str2 = save_state(self, str1, T2, p2, STOP);
end
% NESTED FUNCTIONS
function [J, b] = update_system(self, str1, p2, T2, R0)
    % Update Jacobian matrix and vector b
    r1 = str1.rho;
    p1 = str1.p *1e5; % [Pa]
    T1 = str1.T;
    u1 = str1.u;
    W1 = str1.W * 1e-3; % [kg/mol]
    h1 = str1.h / str1.mi * 1e3; % [J/kg]
    % Calculate frozen state given T & p
    [str2, r2, dVdT_p, dVdp_T] = state(self, str1, T2, p2);
    
    W2 = str2.W * 1e-3;
    h2 = str2.h / str2.mi * 1e3; % [J/kg]
    cP2 = str2.cP / str2.mi; % [J/(K-kg)]
    
    alpha = (W1 * u1^2) / (R0 * T1);
    J1 = -r1 / r2 * alpha * dVdp_T - p2 / p1;
    J2 = -r1 / r2 * alpha * dVdT_p;
    b1 = p2 / p1 - 1 + alpha * (r1 / r2 - 1);
    
    J3 = -u1^2 / R0 * (r1 / r2)^2 * dVdp_T + T2 / W2 * (dVdT_p - 1);
    J4 = -u1^2 / R0 * (r1 / r2)^2 * dVdT_p - T2 * cP2 / R0;
    b2 = (h2 - h1) / R0 - u1^2 / (2*R0) * (1 - (r1 / r2)^2);
    
    J = [J1 J2; J3 J4];
    b = [b1; b2];
end

function [str2, r2, dVdT_p, dVdp_T]= state(self, str1, T, p)
    % Calculate frozen state given T & p
    self.PD.ProblemType = 'TP';
    p = p*1e-5; % [bar]
    str2 = equilibrate_T(self, str1, p, T);
    r2 = str2.rho;
    dVdT_p = str2.dVdT_p;
    dVdp_T = str2.dVdp_T;
end

function relax = relax_factor(x)
    % Compute relaxation factor
%     factor = [0.40546511; 0.04879016];
    factor = [0.40546511; 0.40546511];
    lambda = factor ./ abs(x);
    relax = min(1, min(lambda));  
end

function [log_p2p1, log_T2T1] = apply_correction(x, p2p1, T2T1, lambda)
    % Compute new estimates
    log_p2p1 = log(p2p1) + lambda * x(1);
    log_T2T1 = log(T2T1) + lambda * x(2);
end

function [p2, T2] = apply_antilog(str1, log_p2p1, log_T2T1)
    % compute p2 and T2
    p2 = exp(log_p2p1) * str1.p * 1e5; % [Pa]
    T2 = exp(log_T2T1) * str1.T;
end

function STOP = compute_STOP(x)
    % compute stop condition
    STOP = max(abs(x));
end

function str2 = save_state(self, str1, T2, p2, STOP)
    str2 = state(self, str1, T2, p2);
    str2.u = str1.u - str1.u * str1.rho / str2.rho; % velocity of the gases in the shock tube
    str2.error_problem = STOP;
end
