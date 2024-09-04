local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local Delegate = require("Delegate")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local Utils = require("Utils")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")

local CityTileAssetBubble = require("CityTileAssetBubble")

---@class CityTileAssetCitizenSpawnPlaceBubble:CityTileAssetBubble
---@field new fun():CityTileAssetCitizenSpawnPlaceBubble
---@field super CityTileAssetBubble
local CityTileAssetCitizenSpawnPlaceBubble = class('CityTileAssetCitizenSpawnPlaceBubble', CityTileAssetBubble)

function CityTileAssetCitizenSpawnPlaceBubble:ctor()
    CityTileAssetBubble.ctor(self)
    ---@type boolean
    self._isShow = false
    ---@type number
    self._uid = nil
    ---@type number
    self._furnitureId = nil
    self.isUI = true
    ---@type number
    self._waitCitizenIconId = nil
    ---@type BasicCamera
    self._cityCamera = nil
    ---@type CityTileAssetNpcBubbleInteractBehaviour
    self._bubble = nil
end

function CityTileAssetCitizenSpawnPlaceBubble:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    local cell = self.tileView.tile:GetCell()
    local city = self:GetCity()
    self._uid = city.uid
    self._furnitureId = cell:UniqueId()
    self._cityCamera = city:GetCamera()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnCastleFurnitureDataChanged))
end

function CityTileAssetCitizenSpawnPlaceBubble:OnTileViewRelease()
    self._cityCamera = nil
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnCastleFurnitureDataChanged))
    CityTileAssetBubble.OnTileViewRelease(self)
end

function CityTileAssetCitizenSpawnPlaceBubble:ShouldShow()
    self._waitCitizenIconId = nil
    if not self._uid or not self._furnitureId then
        return false
    end
    ---@type wds.CastleBrief
    local castleBrief = g_Game.DatabaseManager:GetEntity(self._uid, DBEntityType.CastleBrief)
    local furniture = castleBrief.Castle.CastleFurniture[self._furnitureId]
    if not furniture or table.isNilOrZeroNums(furniture.WaitingCitizens) then
        return false
    end
    if self.tileView.tile.inMoveState then
        return false
    end
    self._waitCitizenIconId = furniture.WaitingCitizens[1]
    return true
end

function CityTileAssetCitizenSpawnPlaceBubble:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if self:ShouldShow() then
        return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_interact)
    end
    return string.Empty
end

function CityTileAssetCitizenSpawnPlaceBubble:OnCastleFurnitureDataChanged()
    local shouldShow = self:ShouldShow()
    local isShow = self:IsLoadedOrEmpty() and self.loaded > 0
    if isShow ~= shouldShow then
        if shouldShow then
            self:Show()
        else
            self:Hide()
        end
    else
        if isShow then
            self:UpdateIcon()
        end
    end
end

function CityTileAssetCitizenSpawnPlaceBubble:OnAssetLoaded(go, userdata)
    CityTileAssetBubble.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end
    local cell = self.tileView.tile:GetCell()
    local suggestLocalPos = CityTileAssetBubble.SuggestBubblePosition(cell, go)
    go.transform.localPosition = suggestLocalPos

    ---@type CityTileAssetNpcBubbleInteractBehaviour
    self._bubble = go:GetLuaBehaviour("CityTileAssetNpcBubbleInteractBehaviour").Instance
    self._bubble:ResetToNormal()
    self._bubble:SetupTrigger(Delegate.GetOrCreate(self, self.OnClickIcon), self.tileView.tile)
    self:UpdateIcon()
end

function CityTileAssetCitizenSpawnPlaceBubble:UpdateIcon()
    if self._waitCitizenIconId and Utils.IsNotNull(self._bubble) then
        local citizenCfg = ConfigRefer.Citizen:Find(self._waitCitizenIconId)
        if citizenCfg then
            self._bubble:SetupIcon(citizenCfg:Icon())
        end
    end
end

function CityTileAssetCitizenSpawnPlaceBubble:OnAssetUnload(go, fade)
    self._bubble = nil
end

function CityTileAssetCitizenSpawnPlaceBubble:OnClickIcon()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SPAWN_CLICK, self._uid, self._furnitureId)
end

function CityTileAssetCitizenSpawnPlaceBubble:OnMoveBegin()
    self:Hide()
end

function CityTileAssetCitizenSpawnPlaceBubble:OnMoveEnd()
    if self:ShouldShow() then
        self:Show()
    end
end

return CityTileAssetCitizenSpawnPlaceBubble