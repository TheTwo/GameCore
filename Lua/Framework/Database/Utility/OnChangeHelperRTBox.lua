local OnChangeHelperRTBox = {}

---@generic T
---@param changeTable table
---@param _ T
---@return table<number, T>|nil,table<number, T>|nil,table<number, T[]>|nil
function OnChangeHelperRTBox.GenerateMapFieldChangeMap(changeTable, _)
    if not changeTable or (not changeTable.Add and not changeTable.Remove) then
        return nil
    end

    local AddMap, RemoveMap
    if changeTable.Add then
        AddMap = {}
        for k, v in pairs(changeTable.Add) do
            AddMap[k] = v
        end
    end

    if changeTable.Remove then
        RemoveMap = {}
        for k, v in pairs(changeTable.Remove) do
            RemoveMap[k] = v
        end
    end

    return AddMap, RemoveMap
end

return OnChangeHelperRTBox