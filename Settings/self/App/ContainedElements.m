function self = ContainedElements(self)
    L_formula = [];
    for k = self.S.NS:-1:1
        L_E1 = []; L_E2 = []; 
        formula = self.S.LS_formula{k};
        
        [idx0,idxf] = regexp(formula,"[A-Z]{2,}");
        for j=length(idxf):-1:1
            L_E2{j} = formula(idx0(j):idxf(j));
            formula(idx0(j):idxf(j)) = ' ';
            if isempty(L_E2)
                L_E2{j} = [];
            end
        end
        
        [~, idxf] = regexp(formula,"[A-Z]{1}");
        for j=length(idxf):-1:1
            L_E1{j} = formula(idxf(j));
        end
        
        L_formula = [L_formula, L_E1, L_E2];
    end
    aux = unique(L_formula);
    n_pass = [];
    for n=length(aux):-1:1
        if any(strcmpi(aux(n), self.E.elements)) % Check Element existence
            n_pass = [n_pass, n];
        end
    end   
    self.E.elements = aux(n_pass);
    self.E.NE = numel(self.E.elements);
    self.E.ind_C = find(strcmp(self.E.elements,'C'));
    self.E.ind_H = find(strcmp(self.E.elements,'H'));
    self.E.ind_O = find(strcmp(self.E.elements,'O'));
    self.E.ind_N = find(strcmp(self.E.elements,'N'));
    self.E.ind_E = find(strcmp(self.E.elements,'E'));
end