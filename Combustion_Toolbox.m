%{ 
COMBUSTION TOOLBOX @v0.3.52

Type of problems:
    * TP ------> Equilibrium composition at defined T and p
    * HP ------> Adiabatic T and composition at constant p
    * SP ------> Isentropic compression/expansion to a specified p
    * TV ------> Equilibrium composition at defined T and constant v
    * EV ------> Adiabatic T and composition at constant v
    * SV ------> Isentropic compression/expansion to a specified v
    * SHOCK_I -> Planar incident shock wave
    * SHOCK_R -> Planar reflected shock wave
    * DET -----> Chapman-Jouget Detonation (CJ upper state)
    * DET_OVERDRIVEN -----> Overdriven Detonation    
    

@author: Alberto Cuadra Lara
         PhD Candidate - Group Fluid Mechanics
         Universidad Carlos III de Madrid
                  
Last update Oct 04 2021
---------------------------------------------------------------------- 
%}
addpath(genpath(pwd));

%% INITIALIZE
app = App('Soot formation');
% app = App('HC/02/N2');
% app = App('HC/02/N2 extended');
% app = App('HC/02/N2 rich');
% app = App('HC/02/N2 propellants');
% app = App('Ideal_air');
% app = App('Hydrogen_l');
% app = App({'O2','N2','O','O3','N','NO','NO2','NO3','N2O','N2O3','N2O4','N3', ...
%     'eminus', 'Nminus', 'Nplus', 'NOplus', 'NO2minus', 'NO3minus', 'N2plus', 'N2minus', 'N2Oplus', ...
%      'Oplus', 'Ominus', 'O2plus', 'O2minus'});
% app = App({'H2bLb', 'O2bLb'});
%% PROBLEM CONDITIONS
app.PD.TR.value  = 300;
app.PD.pR.value  = 1 * 1.01325;
app.PD.phi.value = 0.25:0.01:5;
% app.PD.phi.value = 1;
%% PROBLEM TYPE
switch app.PD.ProblemType
    case 'TP' % * TP: Equilibrium composition at defined T and p
        app.PD.ProblemType = 'TP';
        app.PD.pP.value = app.PD.pR.value;
        app.PD.TP.value = 3000;
    case 'HP' % * HP: Adiabatic T and composition at constant p
        app.PD.ProblemType = 'HP';
        app.PD.pP.value = app.PD.pR.value;
    case 'SP' % * SP: Isentropic (i.e., adiabatic) compression/expansion to a specified p
        app.PD.ProblemType = 'SP';
        app.PD.pP.value = 10:1:50; app.PD.phi.value = 1*ones(1,length(app.PD.pP.value));
%         app.PD.pP.value = 10*ones(1,length(app.PD.phi.value));
    case 'TV' % * TV: Equilibrium composition at defined T and constant v
        app.PD.ProblemType = 'TV';
        app.PD.TP.value = 2000;
        app.PD.pP.value = app.PD.pR.value; % guess
    case 'EV' % * EV: Equilibrium composition at Adiabatic T and constant v
        app.PD.ProblemType = 'EV';
        app.PD.pP.value = app.PD.pR.value;
        % app.PD.pR.value = logspace(0,2,20); app.PD.phi.value = 1*ones(1,length(app.PD.pR.value));
    case 'SV' % * SV: Isentropic (i.e., fast adiabatic) compression/expansion to a specified v
        app.PD.ProblemType = 'SV';
        % REMARK! vP_vR > 1 --> expansion, vP_vR < 1 --> compression
        app.PD.vP_vR.value = 0.5:0.01:2; app.PD.phi.value = 1*ones(1,length(app.PD.vP_vR.value));
    case 'SHOCK_I' % * SHOCK_I: CALCULATE PLANAR INCIDENT SHOCK WAVE
        app.PD.ProblemType = 'SHOCK_I';
        u1 = logspace(2, 5, 500);
        u1 = u1(u1<20000); u1 = u1(u1>=360);
%         u1 = [356,433,534,658,811,1000,1233,1520,1874,2310,2848,3511,4329,5337,6579,8111,9500,12328,15999,18421,21210,24421,28118,32375,37276,42919,49417,56899,65513];
%         u1 = linspace(360, 9000, 1000);
%         u1 = 20000;
        app.PD.u1.value = u1; app.PD.phi.value = ones(1,length(app.PD.u1.value));
    case 'SHOCK_R' % * SHOCK_R: CALCULATE PLANAR POST-REFLECTED SHOCK STATE
        app.PD.ProblemType = 'SHOCK_R';
        u1 = linspace(400, 6000, 1000);
%         u1 = 2000;
        app.PD.u1.value = u1; app.PD.phi.value = ones(1,length(app.PD.u1.value));
    case 'DET' % * DET: CALCULATE CHAPMAN-JOUGET STATE (CJ UPPER STATE)
        app.PD.ProblemType = 'DET';
%         app.PD.TR_vector.value = app.PD.TR.value;
    case 'DET_OVERDRIVEN' % * DET_OVERDRIVEN: CALCULATE OVERDRIVEN DETONATION
        app.PD.ProblemType = 'DET_OVERDRIVEN';  
        app.PD.overdriven.value  = 1:1:5;
end
%% LOOP
app.C.l_phi = length(app.PD.phi.value);
tic
for i=app.C.l_phi:-1:1
% DEFINE FUEL
app.PD.S_Fuel = {'H2'}; app.PD.N_Fuel = 1;
app = Define_F(app);
% DEFINE OXIDIZER
app.PD.S_Oxidizer = {'O2'}; app.PD.N_Oxidizer = app.PD.phi_t/app.PD.phi.value(i);
app = Define_O(app);
% DEFINE DILUENTS/INERTS
app.PD.proportion_N2_O2 = 79/21;
app.PD.S_Inert = {'N2'}; app.PD.N_Inert = app.PD.phi_t/app.PD.phi.value(i) * app.PD.proportion_N2_O2;
app = Define_I(app);
% COMPUTE PROPERTIES
app = Define_FOI(app, i);
% PROBLEM TYPE
app = SolveProblem(app, i);
% DISPLAY RESULTS COMMAND WINDOW
results(app, i);
end
toc
%% DISPLAY RESULTS (PLOTS)
app.Misc.display_species = {};
% app.Misc.display_species = {'CO','CO2','H','HO2','H2','H2O','NO','NO2','N2','O','OH','O2','Cbgrb'};
closing(app);