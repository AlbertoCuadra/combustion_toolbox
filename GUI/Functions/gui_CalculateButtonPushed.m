function obj = gui_CalculateButtonPushed(obj, event)
    % Solve selected problem, update GUI with the results and generate
    % predefined plots.
    try
        % Set lamp to Working color
        obj.Lamp.Color = obj.color_lamp_working;
        % Get List of Species considered (reactants + products)
        obj = get_listSpecies_gui(obj);
        % Initialize variable app
        app = App('fast', obj.DB_master, obj.DB, obj.LS);
        % Set FLAG GUI
        app.Misc.FLAG_GUI = true;
        % Get tolerances and tunning values
        app = get_tunning_values(obj, app);
        % Get initial conditions
        app = get_input_constrains(obj, app);
        app = gui_get_reactants(obj, event, app);
        % Solve selected problem
        app = SolveProblem(app, app.PD.ProblemType);
        % Save results
        results = save_results(obj, app);
        % Update GUI with the last results of the set
        obj = gui_update_results(obj, results);
        % Display results (plots)
        postResults(app);
        % Set lamp to Done color
        obj.Lamp.Color = obj.color_lamp_done;
    catch ME
        % Set lamp to Error color
        obj.Lamp.Color = obj.color_lamp_error;
        % Print error
        message = {sprintf('Error in function %s() at line %d.\n\nError Message:\n%s', ...
        ME.stack(1).name, ME.stack(1).line, ME.message)};
        uialert(obj.UIFigure, message, 'Warning', 'Icon', 'warning');
    end
end

% SUB-PASS FUNCTIONS
function app = get_tunning_values(obj, app)
    % Get tolerances and tunning values from GUI and set into app
    app.TN.tolN = obj.TraceoptionEditField.Value;
    app.TN.tol0 = obj.RootFindingMethodEditField.Value;
    app.TN.tol_shocks = obj.ShocksandDetonationsEditField.Value;
    app.C.mintol_display = obj.DisplaySpeciesEditField.Value;
    
    app.TN.itMax = obj.MaxiterationsRFMEditField.Value;
    app.TN.it_shocks = obj.MaxiterationsSDEditField.Value;
    app.TN.root_T0_l = obj.RFMT0_LEditField.Value;
    app.TN.root_T0_r = obj.RFMT0_REditField.Value;
    app.TN.root_T0 = obj.RFMT0EditField.Value;
end

function obj = gui_update_results(obj, results)
    % Update:
    %  1. GUI with the last results computed
    %  2. GUI-UITree with all the results
    
    % Update GUI with the last result computed
    gui_write_results(obj, results, 1);
    % Update UITree with all the results
    gui_add_nodes(obj.Node_Results, results)
end

function obj = get_listSpecies_gui(obj)
    obj.LS = obj.listbox_Products.Items;
    if isempty(obj.LS)
        % Get default value
        obj.LS = ListSpecies([], 'Soot Formation');
    end
end
function results = save_results(obj, app)
    % Save results
    N = length(app.PS.strR);
    for i = N:-1:1
        results(i).mix1 = app.PS.strR{i};
        results(i).mix2 = app.PS.strP{i};
        results(i).ProblemType = obj.ProblemType.Value;
        results(i).Reactants = obj.Reactants.Items{sscanf(obj.Reactants.Value, '%d')};
        results(i).Products = obj.Products.Value;
        if isempty(results(i).Products)
            results(i).Products = 'Default';   
        end
        results(i).LS = app.S.LS;
        results(i).LS_products = obj.LS;
        results(i).UITable_R_Data = obj.UITable_R.Data;
    end
end

function app = get_input_constrains(obj, app)
    [app.PD.TR.value, app.FLAG_PR1] = gui_get_prop(obj, 'TR', obj.PR1.Value);
    [app.PD.pR.value, app.FLAG_PR2] = gui_get_prop(obj, 'pR', obj.PR2.Value);
    [app.PD.phi.value, app.FLAG_phi] = gui_get_prop(obj, 'phi', obj.edit_phi.Value);
    app.PD.ProblemType = obj.ProblemType.Value;
    switch app.PD.ProblemType
        case 'TP' % * TP: Equilibrium composition at defined T and p
            [app.PD.TP.value, app.FLAG_PP1] = gui_get_prop(obj, 'TP', obj.PP1.Value);
            [app.PD.pP.value, app.FLAG_PP2] = gui_get_prop(obj, 'pP', obj.PP2.Value);
        case 'HP' % * HP: Adiabatic T and composition at constant p
            [app.PD.pP.value, app.FLAG_PP2] = gui_get_prop(obj, 'pP', obj.PP2.Value);
        case 'SP' % * SP: Isentropic (i.e., adiabatic) compression/expansion to a specified p
            [app.PD.pP.value, app.FLAG_PP2] = gui_get_prop(obj, 'pP', obj.PP2.Value);
            app.PD.phi.value = 1*ones(1, length(app.PD.pP.value));
        case 'TV' % * TV: Equilibrium composition at defined T and constant v
            [app.PD.TP.value, app.FLAG_PP1] = gui_get_prop(obj, 'TP', obj.PP1.Value);
            [app.PD.pP.value, app.FLAG_PP2] = gui_get_prop(obj, 'pP', obj.PP2.Value);
        case 'EV' % * EV: Equilibrium composition at Adiabatic T and constant v
            [app.PD.pP.value, app.FLAG_PP2] = gui_get_prop(obj, 'pP', obj.PP2.Value);
        case 'SV' % * SV: Isentropic (i.e., fast adiabatic) compression/expansion to a specified v
            app.PD.vP_vR.value = gui_get_prop(obj, 'vP_vR', obj.PP2.Value);
            app.PD.phi.value = 1*ones(1, length(app.PD.vP_vR.value));
        case 'SHOCK_I' % * SHOCK_I: CALCULATE PLANAR INCIDENT SHOCK WAVE
            [app.PD.u1.value, app.FLAG_PR3] = gui_get_prop(obj, 'u1', obj.PR3.Value);
            app.PD.phi.value = 1*ones(1, length(app.PD.u1.value));
        case 'SHOCK_R' % * SHOCK_R: CALCULATE PLANAR POST-REFLECTED SHOCK STATE
            [app.PD.u1.value, app.FLAG_PR3] = gui_get_prop(obj, 'u1', obj.PR3.Value);
            app.PD.phi.value = 1*ones(1, length(app.PD.u1.value));
        case 'DET' % * DET: CALCULATE CHAPMAN-JOUGET STATE (CJ UPPER STATE)
            % No additional constrains
        case 'DET_OVERDRIVEN' % * DET_OVERDRIVEN: CALCULATE OVERDRIVEN DETONATION
            [app.PD.overdriven.value, app.FLAG_PR3] = gui_get_prop(obj, 'overdriven', obj.PR3.Value);
            app.PD.phi.value = 1*ones(1, length(app.PD.overdriven.value));
    end
end