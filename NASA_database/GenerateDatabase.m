function strThProp = GenerateDatabase(strMaster)
if ~exist('strThProp', 'var')
    if exist('strThProp.mat', 'file')
        fprintf('NASA short database loaded from main path ... ')
        load('strThProp.mat', 'strThProp');
    else
        strThProp = get_Database(strMaster); % struct with tabulated data of selected species.
    end
    fprintf('OK!\n');
else
    fprintf('NASA short database already loaded\n')
end
end

% NESTED FUNCTIONS
function strThProp = get_Database(strMaster)

LS = fieldnames(strMaster);

%%% gri30-x.cti except 'CH2(s)' + others
% LS = {'H2', 'H', 'O', 'O2', 'O3', 'OH', 'H2O', 'HO2', 'H2O2', 'C',...
%     'CH', 'CH2', 'CH3', 'CH4', 'CO', 'CO2', 'HCO',...
%     'CH2OH', 'CH3O', 'CH3OH', 'C2H', 'C2H4',...
%     'C2H5', 'C2H6', 'HCCO', 'N', 'NH', 'NH2', 'NH3', 'N2H4',...
%     'NO', 'NO2', 'NO3', 'N2O', 'N2O3', 'N2O4', 'HNO', 'CN', 'HCN',...
%     'NCO', 'N2', 'N3', 'Ar', 'C3H8','C2','C2H2_acetylene','C6H6',...
%     'C8H18_isooctane','C2H5OH','He','Cbgrb'};

% LS = {'O2','N2','O','O3','N','NO','NO2','NO3','N2O','N2O3','N2O4','N3', ...
%     'eminus', 'Arplus', 'Nminus', 'Nplus', 'NOplus', 'NO2minus', 'NO3minus', 'N2plus', 'N2minus', 'N2Oplus', ...
%      'Oplus', 'Ominus', 'O2plus', 'O2minus'};
 

% LS = {'O2','N2','O','N'};

% LS = {'N2', 'N', 'N3', 'eminus', 'N2plus', 'N2minus', 'Nplus', 'Nplus'};

% LS = {'N2', 'N', 'N3'};

% LS = {'O3', 'O2', 'O', 'Oplus', 'Ominus', 'O2plus', 'O2minus', 'eminus'};

% LS = {'H2', 'H', 'Hplus', 'Hminus', 'H2plus', 'H2minus', 'eminus'};

% LS = {'CO2', 'CO', 'H2O', 'H2', 'O2', 'N2', 'He', 'Ar',...
%                 'OH','H','O','HO2','NO','HCO','CH4','CH3',...
%                 'NO2','NH3','NH2','N','HCN','CN','N2O','C2','CH',...
%                 'H2bLb','O2bLb','RP_1'};

%  NASA *: CH4 + 2O2 + 7.52N2
% LS = {'C','CN','CO2','H','O2','CH','C3','C5','NH','O','CO',...
%     'C2','C4','H2','N','NO','N2','OH','CH4','H2O','He','Ar','Cbgrb'};


% NASA ALL: CH4 + 2O2 + 7.52N2
% EXCEPTIONS: 'THDCPD_exo', 'C6H14bLb_n_hexa','H2Obcrb','bHCOOHb2' ,'bCH3COOHb2'
% LS = {'C','CH3','CH4','CN','CO2','C2H','CH2CO_ketene',...
%     'C2H3_vinyl','C2H4','CH3COOH','C2H6','CH3OCH3','CNC','C2O',...
%     'C3H3_2_propynl','C3H6O_propanal',...
%     'C3H8','CNCOCN','C4H2_butadiyne','C4H6_1butyne','C4H8_1_butene',...
%     'C4H8_isobutene','C4H9_n_butyl','C4H9_t_butyl','C4N2',...
%     'C5H11_pentyl','C5H12_i_pentane','C6H5_phenyl','C6H5OH_phenol',...
%     'C7H7_benzyl','C7H14_1_heptene','C7H16_2_methylh',...
%     'C8H16_1_octene','C8H18_isooctane','C10H21_n_decyl','H','HCCN','HNCO',...
%     'HNO3','HCHO_formaldehy','H2O2','NCO','NH3','NO2','N2O','NH2NO2','N2O4',...
%     'N3H','O2','Cbgrb','C2H5OHbLb','C6H6bLb','H2ObLb','CH','CH2OH','CH3OH',...
%     'CNN','COOH','C2H2_acetylene','ObCHb2O','CH3CN','C2H4O_ethylen_o',...
%     'OHCH2COOH','CH3N2CH3','CH3O2CH3','OCCN','C3','C3H4_allene','C3H5_allyl',...
%     'C3H6O_propylox','C3H7_n_propyl','C3H8O_1propanol','C3O2',...
%     'C4H6_2butyne','C4H8_cis2_buten',...
%     'C4H9_i_butyl','C4H10_n_butane','C5','C5H10_1_pentene','C5H11_t_pentyl',...
%     'CH3CbCH3b2CH3','C6H5O_phenoxy','C6H13_n_hexyl','C7H8',...
%     'C7H15_n_heptyl','C8H8_styrene','C8H17_n_octyl','C9H19_n_nonyl','C12H9_o_bipheny',...
%     'HCN','HCCO','HNO','HO2','HCOOH','NH','NH2OH','NO3','NCN','N2H4',...
%     'N2O5','O','O3','N2H4bLb','CH2',...
%     'CH3O','CH3OOH','CO','C2','C2H2_vinylidene','HObCOb2OH','CH3CO_acetyl',...
%     'CH3CHO_ethanal','C2H5','C2H5OH','CCN','C2N2','C3H3_1_propynl','C3H4_propyne',...
%     'C3H6_propylene','C3H6O_acetone','C3H7_i_propyl','C3H8O_2propanol',...
%     'C4','C4H6_butadiene','C4H8_tr2_butene',...
%     'C4H9_s_butyl','C4H10_isobutane',...
%     'C5H12_n_pentane','C6H2','C6H6','C6H12_1_hexene','C6H14_n_hexane',...
%     'C7H8O_cresol_mx','C7H16_n_heptane','C8H10_ethylbenz','C8H18_n_octane',...
%     'C10H8_naphthale','C12H10_biphenyl','HCO','HNC','HNO2','H2','H2O',...
%     'N','NH2','NO','N2','N2H2','N2O3','N3','OH','CH3OHbLb','C6H5NH2bLb',...
%     'He','Ar','Cbgrb'};

% SHOCK NASA O2+N2 + OTHERS
% LS = {'O2','N2','O','O3','N','NO','NO2','NO3','N2O','N2O3','N2O4','N3',...
%     'C','C2','CO','CO2','CN','Ar','CH4','H2O','H2','H','He','OH','Cbgrb'};

% HYDROGEN
% LS = {'H','HNO','HNO3','H2O','NH','NH2OH','NO3','N2H2','N2O3','N3','OH','HNO2',...
%                 'H2','N','NH3','NO2','N2O','N2H4','N2O5','O','O3','O2','N2','HO2','NH2','H2O2',...
%                 'N3H','NH2NO2'};

% LS = {'RP_1'};

% LS = {'O2','N2','O','O3','N','NO','NO2','NO3','N2O','N2O3','N2O4','N3'};

% LS = {'O2','N2','O','O3','N','NO','NO2','NO3','N2O','N2O3','N2O4','N3',...
%     'C','C2','CO','CO2','CN','Ar','CH4','H2O','H2','H','He','OH','Cbgrb','F','F2'};

fprintf('Generating short NASA database ... ')
for i = 1:length(LS)
    species = FullName2name(LS{i});
    if isfield(strMaster,species)
        
        ctTInt = strMaster.(species).ctTInt;
        tRange = strMaster.(species).tRange;
        swtCondensed = sign(strMaster.(species).swtCondensed);
        
        if ctTInt > 0
            
            [txFormula, mm, Cp0, Cv0, Hf0, H0, Ef0, E0, S0, DfG0] = SpeciesThermProp(strMaster,LS{i},298.15,'molar',0);
            
            strThProp.(species).name = species;
            strThProp.(species).FullName = LS{i};
            strThProp.(species).txFormula = txFormula;
            strThProp.(species).mm = mm;
            strThProp.(species).hf = Hf0;
            strThProp.(species).ef = Ef0;
            strThProp.(species).swtCondensed = swtCondensed;
            
            NT   = 100;
            Tmin = max(tRange{1}(1), 200);
            Tmax = min(tRange{ctTInt}(2), 20000);
            T_vector = linspace(Tmin, Tmax, NT);

            for j = NT:-1:1
                [~, ~, Cp0, Cv0, Hf0, H0, Ef0, E0, S0, ~] = SpeciesThermProp(strMaster, LS{i}, T_vector(j), 'molar', 0);
                DhT_vector(j) = H0 - Hf0;
                DeT_vector(j) = E0 - Ef0;
                h0_vector(j)  = H0;
                s0_vector(j)  = S0;
                cp_vector(j)  = Cp0;
                cv_vector(j)  = Cv0;
                g0_vector(j)  = H0 - T_vector(j) * S0;
            end
            
            strThProp.(species).T = T_vector;

            % INTERPOLATION CURVES
            strThProp.(species).cPcurve  = griddedInterpolant(T_vector, cp_vector, 'pchip', 'linear');
            strThProp.(species).cVcurve  = griddedInterpolant(T_vector, cv_vector, 'pchip', 'linear');
            strThProp.(species).DhTcurve = griddedInterpolant(T_vector, DhT_vector, 'pchip', 'linear');
            strThProp.(species).DeTcurve = griddedInterpolant(T_vector, DeT_vector, 'pchip', 'linear');
            strThProp.(species).h0curve  = griddedInterpolant(T_vector, h0_vector, 'pchip', 'linear');
            strThProp.(species).s0curve  = griddedInterpolant(T_vector, s0_vector, 'pchip', 'linear');
            strThProp.(species).g0curve  = griddedInterpolant(T_vector, g0_vector, 'pchip', 'linear');
            
            % DATA COEFFICIENTS NASA 9 POLYNOMIAL (ONLY GASES)
            strThProp.(species).ctTInt = strMaster.(species).ctTInt;
            strThProp.(species).tRange = strMaster.(species).tRange;
            strThProp.(species).tExponents = strMaster.(species).tExponents;
            strThProp.(species).ctTInt = strMaster.(species).ctTInt;
            strThProp.(species).a = strMaster.(species).a;
            strThProp.(species).b  = strMaster.(species).b;
        else
            
            Tref = tRange(1);
            
            [txFormula, mm, Cp0, Cv0, Hf0, H0, Ef0, E0, S0, DfG0] = SpeciesThermProp(strMaster,LS{i},Tref,'molar',0);
            
            strThProp.(species).name = species;
            strThProp.(species).FullName = LS{i};
            strThProp.(species).txFormula = txFormula;
            strThProp.(species).mm  = mm;
            strThProp.(species).hf  = Hf0;
            strThProp.(species).ef  = Hf0;
            strThProp.(species).swtCondensed = swtCondensed;
            strThProp.(species).T   = Tref;
            strThProp.(species).DhT = 0;
            strThProp.(species).DeT = 0;
            strThProp.(species).h0  = H0;
            strThProp.(species).s0  = S0;
            strThProp.(species).cp  = Cp0;
            strThProp.(species).cv  = Cv0;
            strThProp.(species).g0  = DfG0;
            
            strThProp.(species).ctTInt = 0;
        end
    else
        fprintf(['\n- Species ''', LS{i}, ''' does not exist as a field in strMaster structure ... '])
    end
    
end
end