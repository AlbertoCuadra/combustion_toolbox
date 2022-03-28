function [mix1, mix2] = shock_oblique_beta(varargin)
    % Solve oblique shock for a given shock wave angle
    
    % Unpack input data
    [self, mix1, mix2] = unpack(varargin);
    % Definitions
    a1 = soundspeed(mix1);     % [m/s]
    u1 = mix1.u;               % [m/s]
    M1 = u1 / a1;              % [-]
    beta = mix1.beta * pi/180; % [rad]
    beta_min = asin(1/M1);     % [rad]
    beta_max = pi/2;           % [rad]
    u1n = u1 * sin(beta);       % [m/s]
    % Check range beta
    if beta < beta_min || beta > beta_max
        error(['\nERROR! The given wave angle beta = %.2g is not in the '...
               'range of possible solutions [%.2g, %2.g]'], mix1.beta,...
               beta_min * 180/pi, beta_max * 180/pi);
    end
    
    % Obtain deflection angle, pre-shock state and post-shock states for
    % an oblique shock
    [~, mix2] = shock_incident(self, mix1, u1n, mix2);
    
    u2n = mix2.v_shock;
    theta = beta - atan(u2n / (u1 .* cos(beta)));
    u2 = u2n * csc(beta - theta);
    % Save results
    mix2.beta = beta * 180/pi;   % [deg]
    mix2.theta = theta * 180/pi; % [deg]
    mix2.beta_min = beta_min * 180/pi; % [deg]
    mix2.beta_max = beta_max * 180/pi; % [deg]
    mix2.u = u2; % [m/s]
    mix2.u2n = u2n; % [m/s]
    mix2.v_shock = u2; % [m/s]
end

% SUB-PASS FUNCTIONS
function [self, str1, str2] = unpack(x)
    % Unpack input data
    self  = x{1};
    str1  = x{2};
    u1    = x{3};
    beta = x{4};       
    str1.u = u1;        % velocity preshock [m/s] - laboratory fixed
    str1.v_shock = u1;  % velocity preshock [m/s] - shock fixed
    str1.beta = beta;   % wave angle  [deg]
    if length(x) > 4
        str2 = x{5};
    else
        str2 = [];
    end
end