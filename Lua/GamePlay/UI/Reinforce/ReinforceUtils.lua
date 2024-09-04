local ModuleRefer = require("ModuleRefer")

---@class ReinforceListData
---@field guid number
---@field sortKey number
---@field member wds.ArmyMemberInfo
---@field fold number @折叠状态 0：展开；1：折叠
---@field arrived boolean
---
---@class ReinforceUtils
local ReinforceUtils = {}

---@param army wds.Army
---@return boolean
function ReinforceUtils.HasMyReinforceTroop(army)
    local playerId = ModuleRefer.PlayerModule:GetPlayerId()
    for _, member in pairs(army.PlayerTroopIDs) do
        if member.PlayerId == playerId then
            return true
        end
    end

    for _, member in pairs(army.PlayerOnRoadTroopIDs) do
        if member.PlayerId == playerId then
            return true
        end
    end

    return false
end

---@param index number
---@param arrived boolean
---@return number
function ReinforceUtils.MakeSortKey(index, arrived)
    local sortKey = arrived and index or ((1 << 16) | index)
    return sortKey
end

---@param guid number
---@param member wds.ArmyMemberInfo
---@param arrived boolean
---@return ReinforceListData
function ReinforceUtils.CreateListData(guid, member, arrived)
    local data = {guid = guid, sortKey = ReinforceUtils.MakeSortKey(member.Index, arrived), member = member, fold = 1, arrived = arrived}
    return data
end

---@param guid number
---@param change table
---@param field string
---@return boolean
function ReinforceUtils.DoesChangeFieldContain(guid, change, field)
    if change == nil then
        return false
    end

    local map = change[field]
    if map == nil then
        return false
    end

    local data = map[guid]
    return data ~= nil
end

return ReinforceUtils