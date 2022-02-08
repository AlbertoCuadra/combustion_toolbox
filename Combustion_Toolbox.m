% -------------------------------------------------------------------------
% COMBUSTION TOOLBOX @v0.4.07
% A MATLAB-GUI based open-source tool for solving gaseous combustion problems.
%
% Type of problems:
%   * TP -----------------> Equilibrium composition at defined T and p
%   * HP -----------------> Adiabatic T and composition at constant p
%   * SP -----------------> Isentropic compression/expansion to a specified p
%   * TV -----------------> Equilibrium composition at defined T and constant v
%   * EV -----------------> Adiabatic T and composition at constant v
%   * SV -----------------> Isentropic compression/expansion to a specified v
%   * SHOCK_I ------------> Planar incident shock wave
%   * SHOCK_R ------------> Planar reflected shock wave
%   * DET ----------------> Chapman-Jouget Detonation
%   * DET_OVERDRIVEN -----> Overdriven Detonation    
%
% SEE THE EXAMPLES OR WIKI TO KNOW HOW TO START USING COMBUSTION TOOLBOX 
% LIST OF TUTORIAL SCRIPTS:
%   * Example_TP
%   * Example_HP
%   * Example_SP (not yet)
%   * Example_TV
%   * Example_EV
%   * Example_SV (not yet)
%   * Example_SHOCK_I
%   * Example_SHOCK_I_IONIZATION
%   * Example_SHOCK_R
%   * Example_DET
%   * Example_DET_OVERDRIVEN
%
% Please to send feedback or inquiries run uifeedback
% Thank you for testing Combustion Toolbox!
%
% @author: Alberto Cuadra Lara
%          PhD Candidate - Group Fluid Mechanics
%          Universidad Carlos III de Madrid
%                  
% Last update Feb 08 2022
% -------------------------------------------------------------------------
help Combustion_Toolbox.m

% INDICATE FILES ON PATH
Combustion_Toolbox_setPath;