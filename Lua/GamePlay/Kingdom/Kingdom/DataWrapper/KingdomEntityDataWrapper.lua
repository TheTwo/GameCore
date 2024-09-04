local KingdomMapUtils = require("KingdomMapUtils")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local KingdomRefreshData = require("KingdomRefreshData")

local Vector3 = CS.UnityEngine.Vector3


---@class KingdomEntityDataWrapper
---@field data any
local KingdomEntityDataWrapper = class("KingdomEntityDataWrapper")

---@param brief wds.MapEntityBrief
---@param delayInvoker KingdomDelayInvoker
function KingdomEntityDataWrapper:OnShow(refreshData, delayInvoker, lod, brief)
    local id = brief.ObjectId
    local buildingConfigID = brief.CfgId
    local isMyAllianceCenter = (brief.IsAllianceCenter and ModuleRefer.PlayerModule:IsFriendlyById(brief.AllianceId, brief.PlayerId))
    local iconVisible = isMyAllianceCenter or KingdomMapUtils.CheckIconLodByFixedConfig(buildingConfigID, lod)
    if iconVisible then
        self:OnShowIcon(refreshData, delayInvoker, id)
    else
        self:OnHideIcon(refreshData, delayInvoker, id, true)
    end

    local nameVisible = isMyAllianceCenter or KingdomMapUtils.CheckNameLodByFixedConfig(buildingConfigID, lod)
    local levelVisible = isMyAllianceCenter or KingdomMapUtils.CheckLevelOnlyLodByFixedConfig(buildingConfigID, lod)
    if nameVisible then
        self:OnShowName(refreshData, delayInvoker, id)
        self:OnHideLevel(refreshData, delayInvoker, id, true)
    elseif levelVisible then
        self:OnHideName(refreshData, delayInvoker, id, true)
        self:OnShowLevel(refreshData, delayInvoker, id)
    else
        self:OnHideName(refreshData, delayInvoker, id, true)
        self:OnHideLevel(refreshData, delayInvoker, id, true)
    end
end

---@param brief wds.MapEntityBrief
---@param delayInvoker KingdomDelayInvoker
function KingdomEntityDataWrapper:OnHide(refreshData, delayInvoker, lod, brief)
    local id = brief.ObjectId
    local buildingConfigID = brief.CfgId
    local isMyAllianceCenter = (brief.IsAllianceCenter and ModuleRefer.PlayerModule:IsFriendlyById(brief.AllianceId, brief.PlayerId))
    local iconVisible = isMyAllianceCenter or KingdomMapUtils.CheckIconLodByFixedConfig(buildingConfigID, lod)
    local nameVisible = isMyAllianceCenter or KingdomMapUtils.CheckNameLodByFixedConfig(buildingConfigID, lod)
    local levelVisible = isMyAllianceCenter or KingdomMapUtils.CheckLevelOnlyLodByFixedConfig(buildingConfigID, lod)

    if iconVisible then
        self:OnHideIcon(refreshData, delayInvoker, id)
    end

    if nameVisible then
        self:OnHideName(refreshData, delayInvoker, id)
    elseif levelVisible then
        self:OnHideLevel(refreshData, delayInvoker, id)
    end

    delayInvoker:AddCallback(KingdomRefreshData.RemoveHUD, id, 0)
end

---@param brief wds.MapEntityBrief
---@param delayInvoker KingdomDelayInvoker
function KingdomEntityDataWrapper:OnLodChanged(refreshData, delayInvoker, oldLod, newLod, brief)
    local id = brief.ObjectId
    local buildingConfigID = brief.CfgId
    local isMyAllianceCenter = (brief.IsAllianceCenter and ModuleRefer.PlayerModule:IsFriendlyById(brief.AllianceId, brief.PlayerId))
    local iconVisibleInOld = isMyAllianceCenter or KingdomMapUtils.CheckIconLodByFixedConfig(buildingConfigID, oldLod)
    local iconVisibleInNew = isMyAllianceCenter or KingdomMapUtils.CheckIconLodByFixedConfig(buildingConfigID, newLod)
    local showIcon = iconVisibleInNew and not iconVisibleInOld
    local hideIcon = iconVisibleInOld and not iconVisibleInNew

    if showIcon then
        self:OnShowIcon(refreshData, delayInvoker, id)
    elseif hideIcon then
        self:OnHideIcon(refreshData, delayInvoker, id)
    end

    local nameVisibleInOld = isMyAllianceCenter or KingdomMapUtils.CheckNameLodByFixedConfig(buildingConfigID, oldLod)
    local nameVisibleInNew = isMyAllianceCenter or KingdomMapUtils.CheckNameLodByFixedConfig(buildingConfigID, newLod)
    local showName = nameVisibleInNew and not nameVisibleInOld
    local hideName = nameVisibleInOld and not nameVisibleInNew

    local levelVisibleInOld = isMyAllianceCenter or KingdomMapUtils.CheckLevelOnlyLodByFixedConfig(buildingConfigID, oldLod)
    local levelVisibleInNew = isMyAllianceCenter or KingdomMapUtils.CheckLevelOnlyLodByFixedConfig(buildingConfigID, newLod)
    local showLevel = levelVisibleInNew and not levelVisibleInOld
    local hideLevel = levelVisibleInOld and not levelVisibleInNew

    if showName then
        self:OnShowName(refreshData, delayInvoker, id)
    elseif hideName then
        self:OnHideName(refreshData, delayInvoker, id)
    end

    if showLevel then
        self:OnShowLevel(refreshData, delayInvoker, id)
    elseif hideLevel then
        self:OnHideLevel(refreshData, delayInvoker, id)
    end

end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomEntityDataWrapper:OnShowIcon(refreshData, delayInvoker, id)
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomEntityDataWrapper:OnHideIcon(refreshData, delayInvoker, id)
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomEntityDataWrapper:OnShowName(refreshData, delayInvoker, id)
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomEntityDataWrapper:OnHideName(refreshData, delayInvoker, id)
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomEntityDataWrapper:OnShowLevel(refreshData, delayInvoker, id)
end

---@param refreshData KingdomRefreshData
---@param delayInvoker KingdomDelayInvoker
function KingdomEntityDataWrapper:OnHideLevel(refreshData, delayInvoker, id)
end

---@param refreshData KingdomRefreshData
---@param brief wds.MapEntityBrief
function KingdomEntityDataWrapper:FeedData(refreshData, brief)
end

---@param brief wds.MapEntityBrief
---@return CS.DragonReborn.Vector2Short
function KingdomEntityDataWrapper:GetCenterCoordinate(brief)
end

---@param brief wds.MapEntityBrief
---@return CS.UnityEngine.Vector3
function KingdomEntityDataWrapper:GetCenterPosition(brief)
end

---@param brief wds.MapEntityBrief
function KingdomEntityDataWrapper:GetIcon(brief)
end

---@param brief wds.MapEntityBrief
function KingdomEntityDataWrapper:GetFrame(brief)
end

---@param brief wds.MapEntityBrief
function KingdomEntityDataWrapper:GetName(brief)
end

---@param brief wds.MapEntityBrief
function KingdomEntityDataWrapper:GetLevel(brief)
end

---@param brief wds.MapEntityBrief
function KingdomEntityDataWrapper:OnIconClick(brief)
end


return KingdomEntityDataWrapper