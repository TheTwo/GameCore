local CityTileAssetGroupMember = require("CityTileAssetGroupMember")
---@class CityTileAssetRepairBlockPollutedPlus:CityTileAssetGroupMember
---@field new fun():CityTileAssetRepairBlockPollutedPlus
local CityTileAssetRepairBlockPollutedPlus = class("CityTileAssetRepairBlockPollutedPlus", CityTileAssetGroupMember)
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local Quaternion = CS.UnityEngine.Quaternion
local EventConst = require("EventConst")
local Delegate = require("Delegate")

---@param group CityTileAssetRepairBlockGroup
---@param repairBlock CityBuildingRepairBlock
function CityTileAssetRepairBlockPollutedPlus:ctor(group, repairBlock)
    CityTileAssetGroupMember.ctor(self, group)
    self.repairBlock = repairBlock
    self.duration = 2
end

function CityTileAssetRepairBlockPollutedPlus:GetCustomNameInGroup()
    return string.format("polluted_plus_%d", self.repairBlock.id)
end

function CityTileAssetRepairBlockPollutedPlus:GetPrefabName()
    if self:IsPolluted() then
        self.scale = ArtResourceUtils.GetItem(self.repairBlock.cfg:ModelPollutedPlus(), "ModelScale")
        return ArtResourceUtils.GetItem(self.repairBlock.cfg:ModelPollutedPlus())
    end
    return string.Empty
end

function CityTileAssetRepairBlockPollutedPlus:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end

    local tile = self.tileView.tile:GetCell()
    local x, y = tile.x + self.repairBlock.cfg:X(), tile.y + self.repairBlock.cfg:Y()
    local sizeX, sizeY = self.repairBlock.cfg:SizeX(), self.repairBlock.cfg:SizeY()
    local pos = self:GetCity():GetCenterWorldPositionFromCoord(x, y, sizeX, sizeY)
    go.transform:SetPositionAndRotation(pos, Quaternion.identity)

    self.go = go
    if self:IsPolluted() and self.pollutedEnter then
        self.pollutedEnter = nil
        self:PollutedFadeIn(go)
    end
end

function CityTileAssetRepairBlockPollutedPlus:OnAssetUnload()
    if not self:IsPolluted() and self.pollutedExit then
        self.pollutedExit = nil
        self:PollutedFadeOut(self.go)
    end
    self.go = nil
    self.scale = nil
end

function CityTileAssetRepairBlockPollutedPlus:GetScale()
    if self.scale == nil or self.scale == 0 then return 1 end
    return self.scale
end

function CityTileAssetRepairBlockPollutedPlus:IsPolluted()
    return self.repairBlock:IsPolluted()
end

function CityTileAssetRepairBlockPollutedPlus:OnTileViewInit()
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExited))
end

function CityTileAssetRepairBlockPollutedPlus:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExited))
end

function CityTileAssetRepairBlockPollutedPlus:OnPollutedEnter(id)
    if self.repairBlock.building.id ~= id then return end
    self.pollutedEnter = true
    self:Show()
end

function CityTileAssetRepairBlockPollutedPlus:OnPollutedExited(id)
    if self.repairBlock.building.id ~= id then return end
    if Utils.IsNull(self.go) then return end
    self.pollutedExit = true
    self:Hide()
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetRepairBlockPollutedPlus:PollutedFadeIn(go)
    go.transform.localScale = CS.UnityEngine.Vector3(1, 0, 1)
    go.transform:DOScaleY(1, self.duration)
    go.transform.localPosition = go.transform.localPosition - CS.UnityEngine.Vector3.down * 0.5
    go.transform:DOBlendableLocalMoveBy(CS.UnityEngine.Vector3.up * 0.5, self.duration)
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetRepairBlockPollutedPlus:PollutedFadeOut(go)
    go.transform.localScale = CS.UnityEngine.Vector3.one
    go.transform:DOScaleY(0, self.duration)
    go.transform:DOBlendableLocalMoveBy(CS.UnityEngine.Vector3.down * 0.5, self.duration)
end

function CityTileAssetRepairBlockPollutedPlus:GetFadeOutDuration()
    return self.duration
end

return CityTileAssetRepairBlockPollutedPlus