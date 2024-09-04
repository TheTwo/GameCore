local KingdomEntityDataWrapper = require("KingdomEntityDataWrapper")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceUIConsts = require("ArtResourceUIConsts")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomTouchInfoFactory = require("KingdomTouchInfoFactory")
local KingdomDataWrapperHelper = require("KingdomDataWrapperHelper")

local Vector2Short = CS.DragonReborn.Vector2Short

local BUILDING_ICON_INDEX = 0
local BUILDING_LEVEL_TEXT_INDEX = 1
local BUILDING_LEVEL_BACKGROUND_INDEX = 2
local BUILDING_NAME_TEXT_INDEX = 3
local BUILDING_NAME_BACKGROUND_INDEX = 4
local BUILDING_LEVEL_SINGLE_TEXT_INDEX = 5
local BUILDING_LEVEL_SINGLE_BACKGROUND_INDEX = 6

---@class KingdomCastleDataWrapper : KingdomEntityDataWrapper
---@field iconMine string
---@field iconAlliance string
local KingdomCastleDataWrapper = class("KingdomCastleDataWrapper", KingdomEntityDataWrapper)

function KingdomEntityDataWrapper:ctor()
    self.iconMine = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_slg_home_1)
    self.iconAlliance = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_slg_home_3)
    self.iconHostile = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_slg_home_2)
    self.iconAllianceDot = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_slg_home_dot_2)
    self.iconAllianceLeaderDot = ArtResourceUtils.GetUIItem(ArtResourceUIConsts.sp_icon_slg_home_dot_2_leader)
    self.CastleDotIconLod = ConfigRefer.ConstBigWorld:CastleDotIconLod()
    self.PlayerModule = ModuleRefer.PlayerModule
    self.AllianceModule = ModuleRefer.AllianceModule
end

---@param brief wds.MapEntityBrief
function KingdomCastleDataWrapper:GetLodPrefab(brief, lod)
    local tileX, tileZ = self:GetCenterCoordinate(brief)
    if not ModuleRefer.MapFogModule:IsFogUnlocked(tileX, tileZ) then
        return string.Empty
    end

    return require("KingdomEntityDataWrapperFactory").GetPrefabName(brief.ObjectType)
end

---@param refreshData KingdomRefreshData
---@param data wds.AllianceMember
function KingdomCastleDataWrapper:FeedData(refreshData, data)
    local id = self:GetID(data)
    local icon = self:GetIcon(data)
    refreshData:SetSprite(id, BUILDING_ICON_INDEX, icon)
    refreshData:SetClick(id, BUILDING_ICON_INDEX)
end

---@param refreshData KingdomRefreshData
---@param data wds.AllianceMember
function KingdomCastleDataWrapper:OnShow(refreshData, delayInvoker, lod, data)
    local id = self:GetID(data)
    refreshData:SetActive(id, BUILDING_LEVEL_TEXT_INDEX, false)
    refreshData:SetActive(id, BUILDING_LEVEL_BACKGROUND_INDEX, false)
    refreshData:SetActive(id, BUILDING_NAME_TEXT_INDEX, false)
    refreshData:SetActive(id, BUILDING_NAME_BACKGROUND_INDEX, false)
    refreshData:SetActive(id, BUILDING_LEVEL_SINGLE_TEXT_INDEX, false)
    refreshData:SetActive(id, BUILDING_LEVEL_SINGLE_BACKGROUND_INDEX, false)

    refreshData:SetActive(id, BUILDING_ICON_INDEX, true)
    refreshData:SetSpriteStay(id, BUILDING_ICON_INDEX)
end

---@param data wds.AllianceMember
function KingdomCastleDataWrapper:GetCenterCoordinate(data)
    local pos = self:GetPos(data)
    return Vector2Short(KingdomMapUtils.ParseBuildingPos(pos))
end

---@param data wds.AllianceMember
function KingdomCastleDataWrapper:GetCenterPosition(data)
    local pos = self:GetPos(data)
    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(pos)
    return KingdomDataWrapperHelper.CalculateCenterPosition(tileX, tileZ, 4, 4, KingdomMapUtils.GetStaticMapData())
end

---@param data wds.AllianceMember|wds.MapEntityBrief
function KingdomCastleDataWrapper:GetIcon(data)
    local AllianceModule = ModuleRefer.AllianceModule
    local PlayerModule = ModuleRefer.PlayerModule

    local playerId = self:GetPlayerID(data)
    if PlayerModule:IsMineById(playerId) then
        return self.iconMine
    elseif self:IsFriendly(data) then
        if KingdomMapUtils.GetLOD() >= self.CastleDotIconLod then
            if AllianceModule:IsInAlliance() and AllianceModule:GetAllianceLeaderInfo().PlayerID == playerId then
                return self.iconAllianceLeaderDot
            else
                return self.iconAllianceDot
            end
        end
        return self.iconAlliance
    else
        return self.iconHostile
    end
end

---@param data wds.AllianceMember
function KingdomCastleDataWrapper:GetName(data)
    return data.Name or string.Empty
end

---@param data wds.AllianceMember
function KingdomCastleDataWrapper:GetLevel(data)
    return string.Empty
    --return data.CommanderLevel and tostring(data.CommanderLevel) or 0
end

---@param data wds.AllianceMember
function KingdomCastleDataWrapper:OnIconClick(data)
    local coord = self:GetCenterCoordinate(data)
    local name = self:GetName(data)
    local level = self:GetLevel(data)
    local touchData = KingdomTouchInfoFactory.CreateEntityHighLod(coord.X, coord.Y, name, level)
    ModuleRefer.KingdomTouchInfoModule:Hide()
    ModuleRefer.KingdomTouchInfoModule:Show(touchData)
end

---@param data wds.AllianceMember|wds.MapEntityBrief
---@return number
function KingdomCastleDataWrapper:GetID(data)
    if data.TypeHash == wds.AllianceMember.TypeHash then
        ---@type wds.AllianceMember
        local member = data
        return member.PlayerID
    end
    if data.TypeHash == wds.MapEntityBrief.TypeHash then
        ---@type wds.MapEntityBrief
        local brief = data
        return brief.ObjectId
    end
    return 0
end

---@param data wds.AllianceMember|wds.MapEntityBrief
---@return number
function KingdomCastleDataWrapper:GetPlayerID(data)
    if data.TypeHash == wds.AllianceMember.TypeHash then
        ---@type wds.AllianceMember
        local member = data
        return member.PlayerID
    end
    if data.TypeHash == wds.MapEntityBrief.TypeHash then
        ---@type wds.MapEntityBrief
        local brief = data
        return brief.PlayerId
    end
    return 0
end

---@param data wds.AllianceMember|wds.MapEntityBrief
---@return wds.Vector3F
function KingdomCastleDataWrapper:GetPos(data)
    if data.TypeHash == wds.AllianceMember.TypeHash then
        ---@type wds.AllianceMember
        local member = data
        return member.BigWorldPosition
    end
    if data.TypeHash == wds.MapEntityBrief.TypeHash then
        ---@type wds.MapEntityBrief
        local brief = data
        return brief.Pos
    end
    return nil
end

---@param data wds.AllianceMember|wds.MapEntityBrief
---@return wds.Vector3F
function KingdomCastleDataWrapper:IsFriendly(data)
    if data.TypeHash == wds.AllianceMember.TypeHash then
        return true
    end
    if data.TypeHash == wds.MapEntityBrief.TypeHash then
        ---@type wds.MapEntityBrief
        local brief = data
        return ModuleRefer.PlayerModule:IsFriendlyById(brief.AllianceId, brief.PlayerId)
    end
    return nil
end


return KingdomCastleDataWrapper