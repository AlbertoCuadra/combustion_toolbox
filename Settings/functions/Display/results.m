function results(self, i)
    % Display results in the command window
    if self.Misc.FLAG_RESULTS
        if ~strcmpi(self.PD.ProblemType, 'SHOCK_R') && ~strcmpi(self.PD.ProblemType, 'ROCKET') 
            displayresults(self.PS.strR{i}, self.PS.strP{i}, self.PD.ProblemType, self.C.mintol_display, self.S.LS);
        elseif strcmpi(self.PD.ProblemType, 'ROCKET') 
            displayresults(self.PS.strR{i}, self.PS.str2{i}, self.PS.strP{i}, self.PD.ProblemType, self.C.mintol_display, self.S.LS);
        else
            % Display all results SHOCK_R
            displayresults(self.PS.strR{i}, self.PS.str2{i}, self.PS.strP{i}, self.PD.ProblemType, self.C.mintol_display, self.S.LS);
        end
    end
end