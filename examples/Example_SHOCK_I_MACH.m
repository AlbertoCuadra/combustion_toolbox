% -------------------------------------------------------------------------
% EXAMPLE: SHOCK_I_MACH
%
% Compute pre-shock and post-shock state for a planar incident shock wave
% at standard conditions, a set of 51 species considered and a set of
% pre-shock Machn numbers (M1) contained in (1, 40)
%    
% Air_ions == {'eminus', 'Ar', 'Arplus', 'C', 'Cplus', 'Cminus', ...
%              'CN', 'CNplus', 'CNminus', 'CNN', 'CO', 'COplus', ...
%              'CO2', 'CO2plus', 'C2', 'C2plus', 'C2minus', 'CCN', ...
%              'CNC', 'OCCN', 'C2N2', 'C2O', 'C3', 'C3O2', 'N', ...
%              'Nplus', 'Nminus', 'NCO', 'NO', 'NOplus', 'NO2', ...
%              'NO2minus', 'NO3', 'NO3minus', 'N2', 'N2plus', ...
%              'N2minus', 'NCN', 'N2O', 'N2Oplus', 'N2O3', 'N2O4', ...
%              'N2O5', 'N3', 'O', 'Oplus', 'Ominus', 'O2', 'O2plus', ...
%              'O2minus', 'O3'}
%   
% See wiki or list_species() for more predefined sets of species
%
% @author: Alberto Cuadra Lara
%          PhD Candidate - Group Fluid Mechanics
%          Universidad Carlos III de Madrid
%                 
% Last update Apr 06 2023
% -------------------------------------------------------------------------

%% INITIALIZE
self = App('Air_ions');
self.PD.FLAG_TCHEM_FROZEN = false; % calorically perfect gas (thermochemically frozen)
%% INITIAL CONDITIONS
self = set_prop(self, 'TR', 300, 'pR', 1 * 1.01325);
self.PD.S_Oxidizer = {'N2', 'O2', 'Ar', 'CO2'};
self.PD.N_Oxidizer = [3.7276, 1.0000, 0.0447, 0.0015];
%% ADDITIONAL INPUTS (DEPENDS OF THE PROBLEM SELECTED)
self = set_prop(self, 'M1', 1:0.1:40);
%% SOLVE PROBLEM
self = solve_problem(self, 'SHOCK_I');
%% DISPLAY RESULTS (PLOTS)
post_results(self);