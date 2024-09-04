local EventConst = require("EventConst")

---@class AllianceTechResearchHostProvider
---@private
---@field new fun():AllianceTechResearchHostProvider
local AllianceTechResearchHostProvider = sealedClass('AllianceTechResearchHostProvider')

---@private
---@type AllianceTechResearchHostProvider
AllianceTechResearchHostProvider._instance = nil

---@return AllianceTechResearchHostProvider
function AllianceTechResearchHostProvider.Instance()
    if not AllianceTechResearchHostProvider._instance then
        AllianceTechResearchHostProvider._instance = AllianceTechResearchHostProvider.new()
    end
    return AllianceTechResearchHostProvider._instance
end

function AllianceTechResearchHostProvider:ctor()
    ---@private
    self._selectedGroupId = nil
    ---@private
    ---@type CS.UnityEngine.Vector3
    self._selectedMaxPos = nil
end

function AllianceTechResearchHostProvider:GetSelectedGroup()
    return self._selectedGroupId
end

function AllianceTechResearchHostProvider:GetSelectedGroupMaxPos()
    return self._selectedMaxPos
end

---@param groupId number
---@param maxPos CS.UnityEngine.Vector3
function AllianceTechResearchHostProvider:SetSelectedGroup(groupId, maxPos)
    if self._selectedGroupId == groupId then
        return
    end
    self._selectedGroupId = groupId
    self._selectedMaxPos = maxPos
    g_Game.EventManager:TriggerEvent(EventConst.UI_ALLIANCE_TECH_GROUP_SELECTED, self._selectedGroupId, self._selectedMaxPos)
end

return AllianceTechResearchHostProvider