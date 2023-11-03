function ax = plot_figure_set(range_name, range, properties, mix, varargin)
    % Plot a set of properties in a tiled layout figure
    %
    % Args:
    %     range_name (char): Variable name of the x-axis parameter
    %     range (float): Vector x-axis values
    %     properties (cell): Cell array of properties to plot
    %     mix (struct): Mixture
    %
    % Optional Args:
    %     * ax (handle): Handle to the main axis
    %     * config (struct): Configuration settings for the figure
    %     * basis (cell): Cell array with the basis for each property
    %
    % Returns:
    %     * main_ax (obj): Handle to the main axis
    %
    % Examples:
    %     * plot_figure_set('T', 300:100:1000, {'cp', 'cv', 'h', 's'}, mix)
    %     * plot_figure_set('T', 300:100:1000, {'cp', 'cv', 'h', 's'}, mix, 'config', config)
    %     * plot_figure_set('T', 300:100:1000, {'cp', 'cv', 'h', 's'}, mix, 'config', config, 'basis', {'', '', 'mi', 'mi'});
    %     * plot_figure_set('T', 300:100:1000, {'cp', 'cv', 'h', 's'}, mix, 'config', config, 'basis', {'', '', 'mi', 'mi'}, 'ax', ax);
    
    % Defaults
    basis = [];
    ax = [];
    FLAG_AX = false;
    Misc = Miscellaneous;
    config = Misc.config;

    % Unpack
    for i = 1:2:nargin-4
        switch lower(varargin{i})
            case 'ax'
                ax = varargin{i + 1}; FLAG_AX = true;
            case 'config'
                config = varargin{i + 1};
            case 'basis'
                basis = varargin{i + 1};
        end

    end
    
    % Definitions
    N_properties = length(properties);
    if isempty(basis)
        basis = double.empty(N_properties);
    end

    % Plot properties
    for i = 1:N_properties
        % Create figure
        if ~FLAG_AX
            main_figure = figure;
            set(main_figure,...
                'units', 'normalized',...
                'outerposition', config.outerposition);
            ax = gca;
            
            % Set title
            set_title(ax, config)
            config.title = [];
        end

        set_figure(ax, config);

        plot_figure(range_name, range, properties{i}, mix, 'config', config, 'ax', ax, 'basis', basis{i});
    end

end