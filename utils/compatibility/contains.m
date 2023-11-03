function value = contains(str, pat, varargin)
    % Funtion that Mimics function contains introduced in MATLAB 2016
    
    % Definitions
    FLAG_IGNORECASE = false;
    
    % Check if str is a cell
    if ~iscell(str)
        str = {str};
    end
    
    for i = 1:2:nargin-2
        
        switch lower(varargin{i})
            case 'ignorecase'
                FLAG_IGNORECASE = varargin{i + 1};    
        end
        
    end
    
    if FLAG_IGNORECASE
        str = lower(str);
    end
    
    value = cellfun(@(x) ~isempty(strfind(x, pat)), str);
end