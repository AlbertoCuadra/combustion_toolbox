function self = App(varargin)
    % Generate self variable with all the data required to initialize the computations
    %
    % Args:
    %     empty (none):       Generate default self variable assuming as products LS = Soot formation     
    %
    % Optional Args:
    %     - LS (cell):          List of species
    %     - obj (class):        Class combustion_toolbox_app (GUI)
    %     - type (str):         If value is fast initialize from the given Databases
    %     - DB_master (struct): Master database
    %     - DB (struct) :       Database with custom thermodynamic polynomials functions generated from NASAs 9 polynomials fits
    % 
    % Returns:
    %     self (struct): Data of the mixture (initialization - empty), conditions, and databases 

    try
        [self, LS, FLAG_FAST, FLAG_COPY] = initialize(varargin);
        if ~FLAG_COPY
            self.E = Elements();
            self.S = Species();
            self.C = Constants();
            self.Misc = Miscellaneous();
            self.PD = ProblemDescription();
            self.PS = ProblemSolution();
            self.TN = TuningProperties();
        else
            self = reset_copy(self);
        end
        self = constructor(self, LS, FLAG_FAST);
        if ~nargin || ~isa(varargin{1,1}, 'combustion_toolbox_app') || (~strcmpi(varargin{1,1}, 'fast') && nargin < 4) || (~strcmpi(varargin{1,1}, 'copy') && nargin < 3) 
            self = Initialize(self);
        end
    catch ME
      errorMessage = sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ...
      ME.stack(1).name, ME.stack(1).line, ME.message);
      fprintf('%s\n', errorMessage);
      uiwait(warndlg(errorMessage));
    end
end

% SUB-PASS FUNCTIONS
function [self, LS, FLAG_FAST, FLAG_COPY] = initialize(varargin)
    varargin = varargin{1,1};
    nargin = length(varargin); % If varargin is empty, by default nargin will return 1, not 0.
    self = struct();
    LS = [];
    FLAG_FAST = false;
    FLAG_COPY = false;
    if nargin
        if strcmpi(varargin{1,1}, 'fast')
            FLAG_FAST = true;
            self.DB_master = varargin{1,2};
            self.DB = varargin{1,3};
            if nargin == 4
                LS = varargin{1,4};
            end
            return
        elseif strcmpi(varargin{1,1}, 'copy')
            FLAG_FAST = true;
            FLAG_COPY = true;
            self = varargin{1,2};
            if nargin == 3
                LS = varargin{1,3};
            end
            return
        end
        if isa(varargin{1,1}, 'combustion_toolbox_app')
            self = varargin{1,1};
            if nargin == 2
                LS = varargin{1,2};
            end
        else
            LS = varargin{1,1};
        end
    end
end

function self = constructor(self, LS, FLAG_FAST)
    % FLAG_GUI
    self = check_GUI(self);
    % Set Database
    FLAG_REDUCED_DB = false;
    self = set_DB(self, FLAG_REDUCED_DB, FLAG_FAST);
    % Set ListSpecies
    if ~isempty(LS)
        self = ListSpecies(self, LS);
    else
        self = ListSpecies(self);
    end
    % Set Contained elements
    self = ContainedElements(self);
    % Timer
    self.Misc.timer_0 = tic;
end

function self = check_GUI(self)
    if isa(self, 'combustion_toolbox_app')
        self.Misc.FLAG_GUI = true;
    end
end

function self = reset_copy(self)
    % In case we want to solve the same base problem from a given self
    % variable, we have to reset several values
    
    % Reset check reactants (FOI): Fuel, Oxidizer, Inert
    self.Misc.FLAG_FOI = true;
    % Reset moles of oxidizer and inerts in case they are computed from the
    % equivalence ratio
    if ~isempty(self.PD.phi.value)
        self.PD.N_Oxidizer = [];
        if ~isempty(self.PD.ratio_inerts_O2)
            self.PD.N_Inert = [];
        end
    end
end