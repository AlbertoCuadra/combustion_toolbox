function species_with = name_with_parenthesis(species)
    % Update the name of the given char with parenthesis. The character b
    % if comes in pair represents parenthesis in the NASA's database
    %
    % Args:
    %     species (char): Chemical species in NASA's Database format
    %
    % Returns:
    %     species_with (char): Chemical species with parenthesis
    %
    % Example:
    %    species_with = name_with_parenthesis('Cbgrb')

    j = find(species(:) == 'b');

    if length(j) == 2
        species(j(1)) = '(';
        species(j(2)) = ')';
    end

    if (length(j) == 3)

        if (j(3) - j(1) == 2) || ((j(2) - j(1) == 1) && (j(1) > 2))
            species(j(1)) = '(';
            species(j(3)) = ')';
        elseif (j(2) - j(1) == 2) && (j(1) > 2)
            species(j(1)) = '(';
            species(j(2)) = ')';
        else
            species(j(2)) = '(';
            species(j(3)) = ')';
        end

    end

    if (length(j) == 4)

        if j(4) - j(2) == 2
            species(j(2)) = '(';
            species(j(4)) = ')';
        else
            species(j(1)) = '(';
            species(j(2)) = ')';
            species(j(3)) = '(';
            species(j(4)) = ')';
        end

    end

    species_with = species;
end
