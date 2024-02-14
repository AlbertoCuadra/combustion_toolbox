function website_CT()
    % Open Combustion Toolbox's website in default web browser
    website = 'https://combustion-toolbox-website.readthedocs.io/';

    if ispc
        system(['start ', website]);
        return
    end

    web(website);
end
