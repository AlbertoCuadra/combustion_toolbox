function [mix1, mix2, mix3] = rocket_performance(self, mix1, varargin)
    % Routine that computes the propellant rocket performance
    %
    % Methods implemented:
    %   * Infinite-Area-Chamber (IAC) 
    %   * Finite-Area-Chamber (FAC) - NOT YET
    %
    % This method is based on Gordon, S., & McBride, B. J. (1994). NASA reference publication,
    % 1311.
    %
    % Args:
    %     self (struct): Data of the mixture, conditions, and databases
    %     mix1 (struct): Properties of the initial mixture
    %
    % Optional Args:
    %     - mix2 (struct): Properties of the mixture at the outlet of the chamber (previous calculation)
    %     - mix3 (struct): Properties of the mixture at the throat (previous calculation)
    %
    % Returns:
    %     Tuple containing
    %
    %     - mix1 (struct): Properties of the initial mixture
    %     - mix2 (struct): Properties of the mixture at the outlet of the chamber
    %     - mix3 (struct): Properties of the mixture at the throat
    %     - mix4 (struct): Properties of the mixture at the given exit points

    % Assign values
    if nargin > 2, mix2 = get_struct(varargin{1}); else, mix2 = []; end
    if nargin > 3, mix3 = get_struct(varargin{2}); else, mix3 = []; end
    % Compute chemical equilibria at the exit of the chamber (HP)
    mix2 = compute_chamber(self, mix1, mix2);
    % Compute chemical equilibria at throat (SP)
    mix3 = compute_throat(self, mix2, mix3);
    % Compute chemical equilibria at different area ratios (SP)
    mix4 = compute_exit(self, mix2, mix3, [], 1.5);
    % Velocity at the inlet and outlet of the chamber
    mix1.u = 0; mix1.v_shock = 0;
    mix2.u = 0; mix2.v_shock = 0;
    % Compute rocket parameters
    [mix3, mix4] = compute_rocket_parameters(mix2, mix3, mix4);
end

% SUB-PASS FUNCTIONS
function str = get_struct(var)
    try
        str = var{1,1};
    catch
        str = var;
    end
end

function mix2 = compute_chamber(self, mix1, mix2)
    % Compute chemical equilibria at the exit of the chamber (HP)
    self.PD.ProblemType = 'HP';
    mix2 = compute_chemical_equilibria(self, mix1, mix1.p, mix2);
end

function mix3 = compute_throat(self, mix2, mix3)
    % Compute chemical equilibria at the throat (SP)
    self.PD.ProblemType = 'SP';
    mix3 = compute_IAC_model(self, mix2, mix3);
end

function mix4 = compute_exit(self, mix2, mix3, mix4, Aratio)
    % Compute chemical equilibria at the throat (SP)
    self.PD.ProblemType = 'SP';
    mix4 = compute_exit_IAC(self, mix2, mix3, mix4, Aratio);
end

function value = characteristic_velocity(mix2, mix3)
    % Compute characteristic velocity Cstar [-]
    value = pressure(mix2) * area_per_mass_flow_rate(mix3) * 1e5;
end