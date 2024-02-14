function value = get_partial_derivative(self, mix)
    % Get value of the partial derivative for the set problem type [kJ/K] (HP, EV) or [kJ/K^2] (SP, SV)
    %
    % Args:
    %     self (struct): Data of the mixture, conditions, and databases
    %     mix (struct):  Properties of the mixture
    %
    % Returns:
    %     value (float): Value of the partial derivative for the set problem type [kJ/K] (HP, EV) or [kJ/K^2] (SP, SV)
    
    switch upper(self.PD.ProblemType)
        case {'HP'}
            value = mix.cP;
        case {'EV'}
            value = mix.cV;
        case {'SP'}
            value = mix.cP / mix.T;
        case {'SV'}
            value = mix.cV / mix.T;
        case {'GP', 'FV'}
            value = - mix.S * 1e3;
    end

    value = value * 1e-3; % [kJ/K] (HP, EV, GP, FV) or [kJ/K^2] (SP, SV)
end
