function self = list_species(varargin)
    % Set list of species in the mixture (reactants and products)
    %
    % Predefined list of species:
    %     * SOOT FORMATION (default)
    %     * COMPLETE
    %     * HC/O2/N2 EXTENDED
    %     * SOOT FORMATION EXTENDED
    %     * NASA ALL
    %     * AIR, DISSOCIATED AIR
    %     * AIR IONS, AIR_IONS
    %     * IDEAL_AIR, AIR_IDEAL
    %     * HYDROGEN
    %     * HYDROGEN_L, HYDROGEN (L)
    %     * HC/O2/N2 PROPELLANTS
    %     * SI/HC/O2/N2 PROPELLANTS
    %
    % Args:
    %     empty (none): return default list of species (soot formation)
    % 
    % Optional Args:
    %     - self (struct): Data of the mixture, conditions, and databases 
    %     - LS (cell): Name list species / list of species
    %     - EquivalenceRatio (float): Equivalence ratio
    %     - EquivalenceRatio_soot (float): Equivalence ratio in which theoretically appears soot
    %
    % Returns:
    %     self (struct): Data of the mixture, conditions, and databases
    
    % Default values
    LS = 'SOOT FORMATION'; % Default list of species
    % Unpack inputs
    if nargin < 2
        FLAG = true; % Return variable "LS"
        self = struct();
        if nargin
            [self, LS] = unpack_LS(self, varargin{1});
        end
    else
        FLAG = false; % Return variable "self"
        self = varargin{1};
        [self, LS] = unpack_LS(self, varargin{2});
    end
    
    if ~isempty(LS)
        switch upper(LS)
            case 'COMPLETE'
                self.S.FLAG_COMPLETE = true;
                if nargin > 2
                    EquivalenceRatio = varargin{1,3};
                    EquivalenceRatio_soot = varargin{1,4};
                    if EquivalenceRatio < 1
                        self.S.LS = self.S.LS_lean;
                    elseif EquivalenceRatio >= 1 && EquivalenceRatio < EquivalenceRatio_soot
                        self.S.LS = self.S.LS_rich;
                    else
                        self.S.LS = self.S.LS_soot;
                    end
                else
                    self.S.LS = {'CO2','CO','H2O','H2','O2','N2','He','Ar','Cbgrb'};
                end

            case 'HC/O2/N2 EXTENDED'
                self.S.LS = {'CO2','CO','H2O','H2','O2','N2','He','Ar','C2',...
                    'CH','CH3','CH4','CN','H','HCN','HCO','HO2','N','N2O',...
                    'NH2','NH3','NO','NO2','O','OH'};
                    
            case 'HC/O2/N2'
                self.S.LS = {'CO2','CO','H2O','H2','O2','N2','He','Ar'};
                
            case 'HC/O2/N2 RICH'
                self.S.LS = {'CO2','CO','H2O','H2','O2','N2','He','Ar',...
                            'C2H4','CH','CH3','CH4','CN','H','HCN','HCO',...
                            'N','NH','NH2','NH3','NO','O','OH'};
                        
            case 'SOOT FORMATION'
                self.S.LS = {'CO2','CO','H2O','H2','O2','N2','He','Ar','Cbgrb',...
                            'C2','C2H4','CH','CH','CH3','CH4','CN','H',...
                            'HCN','HCO','N','NH','NH2','NH3','NO','O','OH'};
                        
            case 'SOOT FORMATION EXTENDED'
                self.S.LS = {'CO2','CO','H2O','H2','O2','N2','He','Ar','Cbgrb',...
                            'C2','C2H','C2H2_acetylene','C2H2_vinylidene',...
                            'C2H3_vinyl','C2H4','C2H5','C2H5OH','C2H6',...
                            'C2N2','C2O','C3','C3H3_1_propynl',...
                            'C3H3_2_propynl','C3H4_allene','C3H4_propyne',...
                            'C3H5_allyl','C3H6O_acetone','C3H6_propylene',...
                            'C3H8','C4','C4H2_butadiyne','C5','C6H2','C6H6',...
                            'C8H18_isooctane','CH','CH2','CH2CO_ketene',...
                            'CH2OH','CH3','CH3CHO_ethanal','CH3CN',...
                            'CH3COOH','CH3O','CH3OH','CH4','CN','COOH','H',...
                            'H2O2','HCCO','HCHO_formaldehy','HCN','HCO',...
                            'HCOOH','HNC','HNCO','HNO','HO2','N','N2O',...
                            'NCO','NH','NH2','NH2OH','NH3','NO','NO2',...
                            'O','OCCN','OH','C3O2','C4N2','CH3CO_acetyl',...
                            'C4H6_butadiene','C4H6_1butyne','C4H6_2butyne',...
                            'C2H4O_ethylen_o','CH3OCH3','C4H8_1_butene',...
                            'C4H8_cis2_buten','C4H8_isobutene',...
                            'C4H8_tr2_butene','C4H9_i_butyl','C4H9_n_butyl',...
                            'C4H9_s_butyl','C4H9_t_butyl','C6H5OH_phenol',...
                            'C6H5O_phenoxy','C6H5_phenyl','C7H7_benzyl',...
                            'C7H8','C8H8_styrene','C10H8_naphthale'};

            case 'NASA ALL'
                self.S.LS = {'CO2','CO','H2O','H2','O2','N2','He','Ar',...
                            'C','C10H21_n_decyl','C10H8_naphthale',...
                            'C12H10_biphenyl','C12H9_o_bipheny','C2','C2H',...
                            'C2H2_acetylene','C2H2_vinylidene','C2H3_vinyl',...
                            'C2H4','C2H4O_ethylen_o','C2H5','C2H5OH',...
                            'C2H5OHbLb','C2H6','C2N2','C2O','C3',...
                            'C3H3_1_propynl','C3H3_2_propynl','C3H4_allene',...
                            'C3H4_propyne','C3H5_allyl','C3H6O_acetone',...
                            'C3H6O_propanal','C3H6O_propylox',...
                            'C3H6_propylene','C3H7_i_propyl',...
                            'C3H7_n_propyl','C3H8','C3H8O_1propanol',...
                            'C3H8O_2propanol','C3O2','C4',...
                            'C4H10_isobutane','C4H10_n_butane',...
                            'C4H2_butadiyne','C4H6_1butyne','C4H6_2butyne',...
                            'C4H6_butadiene','C4H8_1_butene',...
                            'C4H8_cis2_buten','C4H8_isobutene',...
                            'C4H8_tr2_butene','C4H9_i_butyl','C4H9_n_butyl',...
                            'C4H9_s_butyl','C4H9_t_butyl','C4N2','C5',...
                            'C5H10_1_pentene','C5H11_pentyl',...
                            'C5H11_t_pentyl','C5H12_i_pentane',...
                            'C5H12_n_pentane','C6H12_1_hexene',...
                            'C6H13_n_hexyl','C6H14_n_hexane','C6H2',...
                            'C6H5NH2bLb','C6H5OH_phenol','C6H5O_phenoxy',...
                            'C6H5_phenyl','C6H6','C6H6bLb','C7H14_1_heptene'};
                        
            case {'AIR', 'DISSOCIATED AIR'}
                self.S.LS = {'CO2','CO','H2O','H2','O2','N2','He','Ar',...
                    'O','O3','N','NO','NO2','NO3','N2O','N2O3','N2O4','N3',...
                    'C','H'};
                
            case {'AIR_IONS', 'AIR IONS'}
                self.S.LS = {'eminus','Ar','Arplus','C','Cplus','Cminus',...
                             'CN','CNplus','CNminus','CNN','CO','COplus',...
                             'CO2','CO2plus','C2','C2plus','C2minus','CCN',...
                             'CNC','OCCN','C2N2','C2O','C3','C3O2','N',...
                             'Nplus','Nminus','NCO','NO','NOplus','NO2',...
                             'NO2minus','NO3','NO3minus','N2','N2plus',...
                             'N2minus','NCN','N2O','N2Oplus','N2O3','N2O4',...
                             'N2O5','N3','O','Oplus','Ominus','O2','O2plus',...
                             'O2minus','O3'};
            
            case {'IDEAL_AIR', 'AIR_IDEAL'}
                self.S.LS = {'O2','N2','O','O3','N','NO','NO2','NO3','N2O',...
                    'N2O3','N2O4','N3'};
                
            case 'HYDROGEN'
                self.S.LS = {'H2O','H2','O2','N2','He','Ar','H','HNO',...
                    'HNO3','NH','NH2OH','NO3','N2H2','N2O3','N3','OH',...
                    'HNO2','N','NH3','NO2','N2O','N2H4','N2O5','O','O3',...
                    'HO2','NH2','H2O2','N3H','NH2NO2'};
            
            case {'HYDROGEN_IONS', 'HYDROGEN IONS'}
                self.S.LS = {'H2O','H2','O2','N2','H','OH','H2O2','H2Oplus',...
                    'H2minus','H2plus','H3Oplus','HNO','HNO2','HNO3','HO2',...
                    'HO2minus','Hminus','Hplus','N','N2H2','N2H4','N2O','N2O3',...
                    'N2O5','N2Oplus','N2minus','N2plus','N3','N3H','NH','NH2',...
                    'NH2NO2','NH2OH','NH3','NO2','NO2minus','NO3','NO3minus',...
                    'NOplus','Nminus','Nplus','O','O2minus','O2plus','O3',...
                    'Ominus','Oplus','eminus'};
            
            case  {'HYDROGEN_L', 'HYDROGEN (L)'}
                self.S.LS = {'H2O','H2','O2','H','OH','O','O3','HO2',...
                    'H2O2','H2bLb','O2bLb'};
                
            case 'HC/O2/N2 PROPELLANTS'
                self.S.LS = {'CO2','CO','H2O','H2','O2','N2','He','Ar','Cbgrb',...
                            'C2','C2H','C2H2_acetylene','C2H2_vinylidene',...
                            'C2H3_vinyl','C2H4','C2H5','C2H5OH','C2H6',...
                            'C2N2','C2O','C3','C3H3_1_propynl',...
                            'C3H3_2_propynl','C3H4_allene','C3H4_propyne',...
                            'C3H5_allyl','C3H6O_acetone','C3H6_propylene',...
                            'C3H8','C4','C4H2_butadiyne','C5','C6H2','C6H6',...
                            'C8H18_isooctane','CH','CH2','CH2CO_ketene',...
                            'CH2OH','CH3','CH3CHO_ethanal','CH3CN',...
                            'CH3COOH','CH3O','CH3OH','CH4','CN','COOH','H',...
                            'H2O2','HCCO','HCHO_formaldehy','HCN','HCO',...
                            'HCOOH','HNC','HNCO','HNO','HO2','N','N2O',...
                            'NCO','NH','NH2','NH2OH','NH3','NO','NO2',...
                            'O','OCCN','OH','C3O2','C4N2','RP_1','H2bLb',...
                            'O2bLb'};
    
            case 'SI/HC/O2/N2 PROPELLANTS'
                self.S.LS = {'CO2','CO','H2O','H2','O2','N2','He','Ar','Cbgrb',...
                             'C2','C2H4','CH','CH','CH3','CH4','CN','H',...
                             'H2O2','HCN','HCO','N','NH','NH2','NH3','NO','O','OH',...
                             'O2bLb','Si','SiH','SiH2','SiH3','SiH4','SiO2','SiO',...
                             'SibLb','SiO2bLb','Si2'};
            otherwise
                self.S.LS = LS;
        end
    end
    
    self.S.LS = unique(self.S.LS, 'stable');
    
    if FLAG
        self = self.S.LS;
        return
    end
    
    self.S.NS = length(self.S.LS);
    self.S.LS_formula = get_formula(self.S.LS, self.DB);
    
    if any(get_index_ions(self.S.LS))
        self.PD.FLAG_ION = true;
    end

    % Find index O2
    self.S.ind_O2 = find_ind(self.S.LS, 'O2');
end

% SUB-PASS FUNCTIONS
function LS_formula = get_formula(LS, DB)
    % Get chemical formula from the database (DB)
    for i=length(LS):-1:1
        LS_formula{i} = DB.(LS{i}).txFormula;
    end
end

function [self, LS] = unpack_LS(self, variable)
    % Unpack list of species (LS)
    LS = [];
    if iscell(variable)
        self.S.LS = variable;
    else
        LS = variable;
    end
end