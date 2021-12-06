function self = Miscellaneous()
    self.description = "Constants and tolerances";
    self.config.linewidth = 1.8;
    self.config.fontsize = 22;
    self.config.colorpalette = 'Spectral';
    self.config.colorpaletteLenght = 12;
    self.FLAG_FIRST = true;
    self.FLAG_FOI = true;
    self.FLAG_ADDED_SPECIES = false; % FLAG: added reactants species that were not considered as products. Reason: computations with stochiometric matrix
    self.index_LS_original = [];     % Indexes original list of products
    self.FLAG_N_Fuel = true;
    self.FLAG_N_Oxidizer = true;
    self.FLAG_N_Inert = true;
    self.FLAG_RESULTS = true; % Show result in the command window
    self.FLAG_CHECK_INPUTS = false;
    self.FLAG_GUI = false;
    self.FLAG_LABELS = false;
    self.FLAG_PROP = [];
    self.save_Excel = false;
    self.timer_0 = [];
    self.display_species = {};
    self.i = [];
end