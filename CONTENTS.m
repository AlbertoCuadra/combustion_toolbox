% -------------------------------------------------------------------------
% COMBUSTION TOOLBOX @v1.0.6
% A MATLAB-GUI based open-source tool for solving gaseous combustion problems
%
% Type of problems:
%   * TP -----------------> Equilibrium composition at defined T and p
%   * HP -----------------> Adiabatic T and composition at constant p
%   * SP -----------------> Isentropic compression/expansion to a specified p
%   * GP -----------------> Equilibrium composition at defined G and p
%   * TV -----------------> Equilibrium composition at defined T and constant v
%   * EV -----------------> Adiabatic T and composition at constant v
%   * SV -----------------> Isentropic compression/expansion to a specified v
%   * FV -----------------> Equilibrium composition at defined F and p
%   * SHOCK_I ------------> Planar incident shock wave
%   * SHOCK_R ------------> Planar reflected shock wave
%   * SHOCK_OBLIQUE ------> Oblique incident shock wave
%   * SHOCK_OBLIQUE_R ----> Oblique incident and reflected states
%   * SHOCK_POLAR --------> Shock polar diagrams
%   * SHOCK_POLAR_R ------> Shock polar diagrams for incident and reflected states
%   * SHOCK_IDEAL_GAS ----> Planar incident shock wave for a fixed adiabatic index
%   * DET ----------------> Chapman-Jouguet Detonation
%   * DET_R --------------> Reflected Chapman-Jouguet Detonation
%   * DET_OBLIQUE --------> Oblique Detonation
%   * DET_POLAR ----------> Detonation polar diagrams
%   * DET_OVERDRIVEN -----> Over-driven Detonation    
%   * DET_OVERDRIVEN_R ---> Over-driven reflected Detonation
%   * DET_UNDERDRIVEN ----> Under-driven Detonation
%   * DET_UNDERDRIVEN_R --> Under-driven reflected Detonation
%   * ROCKET -------------> Propellant rocket performance   
%
% SEE THE EXAMPLES OR WEBSITE TO KNOW HOW TO START USING THE COMBUSTION TOOLBOX
%
% WEBSITE: https://combustion-toolbox-website.readthedocs.io/ 
%          or type in the promt "website_CT".
%
% Please to send feedback or inquiries type in the promt "uifeedback".
%
% Thank you for using the Combustion Toolbox!
%
% Citing:
%     Cuadra, A., Huete, C., & Vera, M. (2024). Combustion Toolbox: A
%     MATLAB-GUI based open-source tool for solving gaseous combustion
%     problems. (v1.0.6). Zenodo. https://doi.org/10.5281/zenodo.5554911.
%
% @author: Alberto Cuadra Lara
%          Postdoctoral researcher - Group Fluid Mechanics
%          Universidad Carlos III de Madrid
%                  
% Last update Feb 09 2024
% -------------------------------------------------------------------------
help CONTENTS.m

% Set path
INSTALL();
% Display splash
gui_display_splash('pause', 2);
% Check for updates
check_update();