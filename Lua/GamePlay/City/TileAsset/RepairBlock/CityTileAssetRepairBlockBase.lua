local CityTileAssetPollutedGroupMember = require("CityTileAssetPollutedGroupMember")
---@class CityTileAssetRepairBlockBase:CityTileAssetPollutedGroupMember
---@field new fun():CityTileAssetRepairBlockBase
---@field parent CityTileAssetRepairBlockGroup
local CityTileAssetRepairBlockBase = class("CityTileAssetRepairBlockBase", CityTileAssetPollutedGroupMember)
local Utils = require("Utils")
local ArtResourceUtils = require("ArtResourceUtils")
local Quaternion = CS.UnityEngine.Quaternion
local EventConst = require("EventConst")
local Delegate = require("Delegate")

---@param group CityTileAssetRepairBlockGroup
---@param repairBlock CityBuildingRepairBlock
function CityTileAssetRepairBlockBase:ctor(group, repairBlock)
    CityTileAssetPollutedGroupMember.ctor(self, group)
    self.repairBlock = repairBlock
    self.allowSelected = true
end

function CityTileAssetRepairBlockBase:GetCustomNameInGroup()
    return string.format("base_%d", self.repairBlock.id)
end

function CityTileAssetRepairBlockBase:GetPrefabName()
    if not self.repairBlock:IsValid() then
        return string.Empty
    end

    if self.repairBlock:IsBaseRepaired() then
        return ArtResourceUtils.GetItem(self.repairBlock.cfg:ModelFixed())
    end
    return ArtResourceUtils.GetItem(self.repairBlock.cfg:Model())
end

function CityTileAssetRepairBlockBase:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end

    local tile = self.tileView.tile:GetCell()
    local x, y = tile.x + self.repairBlock.cfg:X(), tile.y + self.repairBlock.cfg:Y()
    local sizeX, sizeY = self.repairBlock.cfg:SizeX(), self.repairBlock.cfg:SizeY()
    local pos = self:GetCity():GetCenterWorldPositionFromCoord(x, y, sizeX, sizeY)
    go.transform:SetPositionAndRotation(pos, Quaternion.identity)
    CityTileAssetPollutedGroupMember.OnAssetLoaded(self, go, userdata)
end

function CityTileAssetRepairBlockBase:OnTileViewInit()
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_BASE_HIGHLIGHT, Delegate.GetOrCreate(self, self.OnHighlight))
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_BASE_FLASH, Delegate.GetOrCreate(self, self.OnFlash))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExited))
end

function CityTileAssetRepairBlockBase:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_BASE_HIGHLIGHT, Delegate.GetOrCreate(self, self.OnHighlight))
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_BASE_FLASH, Delegate.GetOrCreate(self, self.OnFlash))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExited))
end

---@param repairBlock CityBuildingRepairBlock
---@param flag boolean
function CityTileAssetRepairBlockBase:OnHighlight(repairBlock, flag)
    if self.repairBlock.id ~= repairBlock.id then return end
    self:SetSelected(flag)
end

---@param repairBlock CityBuildingRepairBlock
---@param flag boolean
function CityTileAssetRepairBlockBase:OnFlash(repairBlock, flag)
    if self.repairBlock.id ~= repairBlock.id then return end
    if flag then
        self:GetCity().flashMatController:StartFlash(self.handle.Asset)
    else
        self:GetCity().flashMatController:StopFlash(self.handle.Asset)
    end
end

function CityTileAssetRepairBlockBase:IsPolluted()
    return self.repairBlock:IsPolluted()
end

function CityTileAssetRepairBlockBase:IsMine(buildingId)
    return self.repairBlock.building.id == buildingId
end

return CityTileAssetRepairBlockBase