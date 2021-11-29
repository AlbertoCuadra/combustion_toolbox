function gui_ReactionValueChanged(obj)
    % Update List of species considered as Products
    try
        temp_app = ListSpecies(obj, obj.Reaction.Value);
        obj.listbox_Products.Items = temp_app.S.LS;
    catch
        obj.listbox_Products.Items = {};
    end
end