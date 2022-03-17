function [str1, str2] = shock_oblique(varargin)
    % Solve oblique shock as in Shock and Detonation Toolbox

    % Unpack input data
    [self, str1, str2] = unpack(varargin);
    
    w_min = soundspeed(str1);
    w_max = str1.u;
    w_step = 5;
    w1 = w_min:w_step:w_max;
    N = length(w1);
    beta_min = asin(w_min / w_max);
    beta = asin(w1 ./ w_max);
    v = w_max .* cos(beta);

    % Solve first case for initialization
    [str1, str2] = shock_incident(self, str1, w1(end), str2);
    % Loop
    for i = N:-1:1
        [str1, str2] = shock_incident(self, str1, w1(i), str2);
        a2(i) = soundspeed(str2);
        ratio = density(str1) /density(str2);
        w2(i) = w1(i) * ratio;
        p2(i) = pressure(str2);
        theta(i) = beta(i) - atan(w2(i) / sqrt(w_max^2 - w1(i)^2));
        u2(i) = sqrt(w2(i)^2 + v(i)^2);
    end

    % compute velocity components downstream in lab frame
    u2x = u2 .* cos(theta);
    u2y = u2 .* sin(theta);


    % plot pressure-deflection polar
	figure;
	plot(180*theta/pi, p2,'k:','LineWidth',2); 
    title(['Shock Polar Air, free-stream speed ',num2str(w_max,5),' m/s'],'FontSize', 12);
    xlabel('deflection angle [deg]','FontSize', 12);
    ylabel('pressure [bar]','FontSize', 12);
    set(gca,'FontSize',12,'LineWidth',2);
    % plot pressure-deflection polar
    figure;
    plot(180*theta/pi, 180*beta/pi,'k:','LineWidth',2);  
    title(['Shock Polar Air, free-stream speed ',num2str(w_max,5),' m/s'],'FontSize', 12);
    xlabel('deflection angle [deg]','FontSize', 12);
    ylabel('wave angle [deg]','FontSize', 12);
    set(gca,'FontSize',12,'LineWidth',2);
    % plot velocity polar
    figure;
    plot(u2x(:), u2y(:),'k:','LineWidth',2);  
    title(['Shock Polar Air, free-stream speed ',num2str(w_max,5),' m/s'],'FontSize', 12);
    xlabel('u2x [m/s]','FontSize', 12);
    ylabel('u2y [m/s]','FontSize', 12);
    set(gca,'FontSize',12,'LineWidth',2);
end

% SUB-PASS FUNCTIONS
function [self, str1, str2] = unpack(x)
    % Unpack input data
    self = x{1};
    str1 = x{2};
    u1   = x{3};
    str1.u = u1;       % velocity preshock [m/s] - laboratory fixed
    str1.v_shock = u1; % velocity preshock [m/s] - shock fixed
    if length(x) > 3
        str2 = x{4};
    else
        str2 = [];
    end
end