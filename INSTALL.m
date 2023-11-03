function INSTALL(varargin)
    % This function installs the Combustion Toolbox repository from local
    % files. It adds all subfolders to the MATLAB path and installs the
    % Combustion Toolbox app.
    %
    % Optional Args:
    %     * action (char): 'install' or 'uninstall' (default: 'install')
    %     * type (char): 'path' or 'all' (default: 'all')
    %
    % Examples:
    %     * INSTALL();                  % Installs the Combustion Toolbox
    %     * INSTALL('uninstall');       % Uninstalls the Combustion Toolbox
    %     * INSTALL('install', 'path'); % Installs the Combustion Toolbox (only MATLAB path)
    %     * INSTALL('install', 'all');  % Installs the Combustion Toolbox (only MATLAB path, GUI is not compatible for MATLAB2015a)
    %
    % Notes:
    %     The code is available in:
    %     * GitHub - https://github.com/AlbertoCuadra/combustion_toolbox
    %     * MATLAB File Exchange - https://in.mathworks.com/matlabcentral/fileexchange/101088-combustion-toolbox
    %     * Zenodo - https://doi.org/10.5281/zenodo.5554911
    %
    % Website: https://combustion-toolbox-website.readthedocs.io/ 
    %          or type "run website_CT"
    %
    % @author: Alberto Cuadra Lara
    %          PhD Candidate - Group Fluid Mechanics
    %          Universidad Carlos III de Madrid
    
    % Default
    action = 'install';
    type = 'all';
    
    % Definitions
    name = 'Combustion Toolbox';
    app_name = 'combustion_toolbox_app';
    dir_code = get_dir_code();

    % Unpack
    if nargin
        action = varargin{1};
    end

    if nargin > 1
        type = varargin{2};
    end
    
    % Get type of installation/uninstallation
    FLAG_PATH = get_type(type);
    
    % Install/Uninstall Combustion Toolbox
    action_code(action);
    
    % NESTED FUNCTIONS
    function action_code(action)
        % Install or uninstall the Combustion Toolbox
        %
        % Args:
        %     action (char): 'install' or 'uninstall'
    
        % Definitions
        switch lower(action)
            case 'install'
                f_path = @addpath;
                message = 'Installing';
                
            case 'uninstall'
                f_path = @rmpath;
                message = 'Uninstalling';

            otherwise
                error('Invalid action specified. Please use ''install'' or ''uninstall''.');
        end
        
        % Install/Uninstall path
        action_path(f_path, message);
    end
    
    function action_path(f_path, message)
        % Install/Uninstall path
        %
        % Args:
        %     f_path (function): Function to add or remove the path
        %     message (char): Message to display

        if ~FLAG_PATH
            return
        end

        % Add the code directory to the MATLAB path
        fprintf('%s %s path... ', message, name);
        f_path(dir_code);
        
        % Get subfolders (except '.git' and '.github')
        d = dir(dir_code);
        subfolders = d([d(:).isdir]);
        subfolders = subfolders(~ismember({subfolders(:).name}, {'.', '..', '.git', '.github'}));
        
        % Add all subfolders to the MATLAB path
        for i = length(subfolders):-1:1
            dir_subfolders = fullfile(dir_code, subfolders(i).name);
            genpath_subfolders = genpath(dir_subfolders);
            f_path(genpath_subfolders);
        end
        
        % Save the path permanently
        if strcmpi(action, 'install')
            savepath;
        end

        fprintf('OK!\n')
    end

end

% SUB-PASS FUNCTIONS
function dir_code = get_dir_code()
    % Get the directory where the code is located
    %
    % Returns:
    %     dir_code (char): Directory where the code is located
    
    % Check if user is running an executable in standalone mode
    if isdeployed
        [~, result] = system('set PATH');
        dir_code = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
        return
    end
    
    % Get current folder if the user is running an m-file from the
    % MATLAB integrated development environment (regular MATLAB)
    dir_code = pwd;
end

function FLAG_PATH = get_type(type)
    % Get the type of installation/uninstallation
    %
    % Args:
    %     type (char): 'path' or 'all'
    %
    % Returns:
    %     * FLAG_PATH (bool): True if the path is installed/uninstalled

    switch lower(type)
        case {'all', 'path'}
            FLAG_PATH = true;
        otherwise
            error('Invalid type specified. Please use ''path'' or ''all''.');
    end

end