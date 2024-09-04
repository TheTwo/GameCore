local OnChangeHelper = {}

---@generic T
---@param changeTable table
---@param _ T
---@return table<number, T>|nil,table<number, T>|nil,table<number, T[]>|nil
function OnChangeHelper.GenerateMapFieldChangeMap(changeTable, _)
    if not changeTable or (not changeTable.Add and not changeTable.Remove) then
        return nil
    end

    local AddMap, RemoveMap, ChangedMap
    if changeTable.Add and type(changeTable.Add) == 'table' then
        AddMap = {}
        for k, v in pairs(changeTable.Add) do
            AddMap[k] = v
        end
    end

    if changeTable.Remove and type(changeTable.Remove) == 'table' then
        RemoveMap = {}
        for k, v in pairs(changeTable.Remove) do
            RemoveMap[k] = v
        end
    end

    if AddMap and RemoveMap then
        ChangedMap = {}
        for k, v in pairs(AddMap) do
            if RemoveMap[k] then
                ChangedMap[k] = {RemoveMap[k], v}
                AddMap[k] = nil
                RemoveMap[k] = nil
            end
        end
    end

    return AddMap, RemoveMap, ChangedMap
end

---@generic T
---@param changeTable table
---@param _ T
---@return table<number, T>|nil, table<number, T>|nil, table<number, T>|nil
function OnChangeHelper.GenerateMapComponentFieldChangeMap(changeTable, _)
    if not changeTable then
        return nil, nil, nil
    end

    local AddMap, RemoveMap, ChangedMap
    if changeTable.Add and type(changeTable.Add) == 'table' then
        AddMap = {}
        for k, v in pairs(changeTable.Add) do
            AddMap[k] = v
        end
    end

    if changeTable.Remove and type(changeTable.Remove) == 'table' then
        RemoveMap = {}
        for k, v in pairs(changeTable.Remove) do
            RemoveMap[k] = v
        end
    end

    for k, v in pairs(changeTable) do
        if k ~= "Add" and k ~= "Remove" then
            if not ChangedMap then
                ChangedMap = {}
            end
            ChangedMap[k] = v
        end
    end

    return AddMap, RemoveMap, ChangedMap
end

function OnChangeHelper.PostFixChangeMap(dataMap, RemoveMap, ChangeMap)
    if not ChangeMap then
        return RemoveMap, ChangeMap
    end

    if not RemoveMap then
        RemoveMap = {}
    end
    for k, v in pairs(ChangeMap) do
        if not dataMap[k] then
            RemoveMap[k] = v[1]
            ChangeMap[k] = nil
        end
    end
    return RemoveMap, ChangeMap
end

return OnChangeHelper