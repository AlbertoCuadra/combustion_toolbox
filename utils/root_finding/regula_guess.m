function x0 = regula_guess(self, mix1, pP, field)
    % Find a estimate of the temperature for the set chemical equilibrium
    % transformation using the regula falsi method
    %
    % Args:
    %     self (struct): Data of the mixture, conditions, and databases
    %     mix1 (struct): Properties of the initial mixture
    %     pP (float):    Pressure [bar]
    %     field (str):   Fieldname in Problem Description (PD)
    %
    % Returns:
    %     x0 (float):    Guess temperature [K]
    
    % Initialization
    guess_moles = [];
    
    % Define branch
    x_l = self.TN.root_T0_l;
    x_r = self.TN.root_T0_r;
    
    % Compute f(x) = f2(x) - f1 at the branch limits
    g_l = get_gpoint(self, mix1, pP, field, x_l, guess_moles);
    g_r = get_gpoint(self, mix1, pP, field, x_r, guess_moles);
    
    % Update estimate based on the region
    if g_l * g_r < 0
        x0 = get_point([x_l, x_r], [g_l, g_r]);
    elseif g_l * g_r > 0 && abs(g_l) < abs(g_r)
        x0 = x_l - 50;
    elseif g_l * g_r > 0 || (isnan(g_l) && isnan(g_r))
        x0 = x_r + 50;
    elseif isnan(g_l) && ~isnan(g_r)
        x0 = x_r - 100;
    elseif ~isnan(g_l) && isnan(g_r)
        x0 = x_l + 100;
    else
        x0 = self.TN.root_T0;
    end

end