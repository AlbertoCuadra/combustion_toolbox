function position = get_monitor_positions(varargin)
    % Routine that gets the position in pixels of the monitor(s) connected
    % to the device
    %
    % Optional Args:
    %    monitor_id (float): Get position in pixels for the given monitor
    %
    % Returns:
    %    position (float): Position of the monitor(s)
    
    position_monitors = get(0, 'MonitorPositions');
    if nargin
        % Get position for the given monitor
        try
            monitor_id = varargin{1};
        catch
            monitor_id = 1;
        end
        position = position_monitors(monitor_id, :);
    else
        % Find main monitor
        ind_main = find(position_monitors == 1, 1);
        position = position_monitors(ind_main, :);
    end
end