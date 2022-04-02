function name = FullName2name(species)
    % Get full name of the given species
    %
    % Args: 
    %     species (str): Chemical species
    %
    % Return:
    %     name (str): Full name of the given species
    
    name = species;
    if isempty(name)
        return
    end
    if name(end)=='+'
        name=[name(1:end-1) 'plus'];
    elseif name(end)=='-'
        name=[name(1:end-1) 'minus'];
    end
    ind=regexp(name,'[()]');
    name(ind)='b';
    ind=regexp(name,'[.,+-]');
    name(ind)='_';
    if regexp(name(1),'[0-9]')
        name=['num_' name];
    end
    ind=regexp(name,'\x27');
    name(ind)='_';
end
