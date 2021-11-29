function ind = find_ind(S, species)
    % Find index of the species in the list S
    NS = length(S);
    if ischar(species)
        Nspecies = 1;
        species = {species};
    else
        Nspecies = length(species);
    end
    ind = [];
    for j=1:Nspecies
        i = 0;
        while i < NS
            i = i + 1;
            if strcmp(species{j}, S{i})
                ind = [ind, i];
                break
            end 
        end
    end
end
