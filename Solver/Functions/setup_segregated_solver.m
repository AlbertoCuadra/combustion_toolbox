function C = setup_segregated_solver(self, LS)
    % Get additional inputs necessary to use the segregated model
    
    % Element_matrix
    for i = length(LS):-1:1
        % Compute element matrix
        txFormula = self.DB.(LS{i}).txFormula;
        Element_matrix = set_element_matrix(txFormula, self.E.elements);
        % Compute CHON atoms contained in each species
        [C.alpha(i, 1),...
         C.beta(i, 1),...
         C.gamma(i, 1),...
         C.omega(i, 1)] = set_alpha_beta_gamma_omega(Element_matrix,...
                                                  self.E.ind_C,...
                                                  self.E.ind_H,...
                                                  self.E.ind_O,...
                                                  self.E.ind_N);
    end
end