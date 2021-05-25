function self = Species()
    self.description = "Data of the chemical species";
    self.namespecies = []; % List species Database
    self.Nspecies = []; % Number species Database
    self.NG = []; % Number gaseous species
    self.NS = []; % Number species
    self.LS = []; % List of species
    self.LS_fixed = {'CO2','CO','H2O','H2','O2','N2','He','Ar','Cbgrb'};
    self.NS_fixed = length(self.LS_fixed); % number fixed species
    self.ind_nswt = []; % index gaseous species
    self.ind_swt = [];  % index condensed species
    self.ind_CO2 = [];
    self.ind_CO = [];
    self.ind_Cgr = [];
    self.ind_H2O = [];
    self.ind_H2 = [];
    self.ind_O2 = [];
    self.ind_N2 = [];
    self.ind_He = [];
    self.ind_Ar = [];
    self.ind_fixed = [];
    self.ind_all = [];
end