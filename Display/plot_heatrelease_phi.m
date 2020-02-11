function plot_heatrelease_phi(strR,strP,phi)
linewidth = 2;
fontsize = 24;
f = figure;
set(f,'units','normalized','innerposition',[0.05 0.05 0.9 0.9],...
        'outerposition',[0.05 0.05 0.9 0.9]);
set(axes,'LineWidth',linewidth-0.2,'FontSize',fontsize+2,'BoxStyle','full')
grid on; box on; hold on; axis tight
xlabel('Equivalence Ratio, $\phi$','FontSize',fontsize+10,'interpreter','latex');
ylabel('Heat release, $q\ [kJ/kg]$','FontSize',fontsize+10,'interpreter','latex');

Nstruct = length(strR);
for i=Nstruct:-1:1
    mR(i)    = strR{i}.mi;
    dhR(i)   = strR{i}.DhT*1e3/mR(i); %J/kg == m^2/s^2
    uR(i)    = strR{i}.u;
    mP(i)    = strR{i}.mi;
    dhP(i)   = strP{i}.DhT*1e3/mP(i); %J/kg == m^2/s^2
    uP(i)    = strP{i}.u;
%     aR(i)    = strR{i}.sound;
%     gamma(i) = strP{i}.gamma;
end
q = (dhP-dhR+0.5*(uP.^2-uR.^2))*1e-3; % kJ/kg == m^2/s^2 * 1e-3 --> J/kg
% q = q.*(gamma.^2-1)./(2*aR.^2)*1e3; ylabel('Heat release, $q*$','FontSize',fontsize+10,'interpreter','latex');
plot(phi,q,'LineWidth',linewidth);