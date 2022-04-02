function speciesLatex = species2latex(species)
    % Convert string of a species into latex
    
    % Check numbers
    index = regexp(species, '[0-9]');
    N = length(index);
    if ~N
        speciesLatex = species;
    else
        speciesLatex = [];
        pos1 = 1;
        for i=1:N
            pos2 = index(i) - 1;
            speciesLatex = strcat(speciesLatex, species(pos1:pos2), '$_', species(pos2 + 1), '$');
            pos1 = pos2 + 2;
        end
        if pos1 < length(species) + 1
            if isletter(species(pos1))
                aux = 0;
            else
                aux = 1;
            end
            speciesLatex = [speciesLatex, species(pos1+aux:end)];
        end
    end
    % Check if ions
    speciesLatex = strrep(speciesLatex, 'plus','$^+$');
    speciesLatex = strrep(speciesLatex, 'minus','$^-$');
    % Check if is a condensed species
    speciesLatex = strrep(speciesLatex, 'bgrb','$_{(gr)}$');
    speciesLatex = strrep(speciesLatex, 'bLb','$_{(L)}$');
    % Check concatenate $$
    speciesLatex = strrep(speciesLatex, '$$','');
end