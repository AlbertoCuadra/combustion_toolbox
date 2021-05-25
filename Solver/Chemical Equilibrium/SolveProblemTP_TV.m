function [strP] = SolveProblemTP_TV(app, i)
% CALCULATE EQUILIBRIUM AT DEFINED T AND P (TP)
%                       OR
% CALCULATE EQUILIBRIUM AT DEFINED T AND CONSTANT V (TV)
% INPUT:
%   strR  = Prop. of reactives (phi,species,...)
%   i     = case
% OUTPUT:
%   strP  = Prop. of products (phi,species,...)

% Abbreviations ---------------------
E = app.E;
S = app.S;
C = app.C;
M = app.M;
PD = app.PD;
PS = app.PS;
TN = app.TN;
strThProp = app.strThProp;
strR = PS.strR{i};
phi = PD.phi.value(i);
TP = PD.TP.value;
pR = PD.pR.value;
pP = pR;
% -----------------------------------
[N_CC, phi_c0, FLAG_SOOT] = CalculateProductsCC(app, i);
P = SetSpecies(C.M0.value, S.LS, N_CC', TP, S.ind_fixed, strThProp);
if strcmpi(PD.CompleteOrIncomplete,'INCOMPLETE')
    % Compute number of moles of M.minor_products                                         
    [P,DeltaNP] = CalculateProductsIC(P,TP,pP,strR.v,phi,M.minors_products,phi_c0,FLAG_SOOT,C.M0.value,C.A0.value,E,S,C,M,PD,TN,strThProp);
%     [N_IC, DeltaNP] = Equilibrium(app, N_CC, phi, pP, TP, strR.v);
    % Compute properties of all species
    P = SetSpecies(C.M0.value,S.LS,P(S.ind_all,1),TP,S.ind_all,strThProp);
else
    DeltaNP = 0;
end

if strfind(PD.ProblemType,'P') == 2 % PD.ProblemType = 'TP', 'HP', or 'SP'
    strP = ComputeProperties(C.A0.value,P,pP,TP,E.ind_C,E.ind_H);
elseif strfind(PD.ProblemType,'V') == 2 % PD.ProblemType = 'TV', 'EV', or 'SV'
    NP = sum(P(:,1).*(1-P(:,10)));
    pP = (NP*TP*8.3144598/(strR.v/1000))/1e5;
    strP = ComputeProperties(C.A0.value,P,pP,TP,E.ind_C,E.ind_H);
end
strP.phi_c = phi_c0;
strP.error_moles = DeltaNP;
end
