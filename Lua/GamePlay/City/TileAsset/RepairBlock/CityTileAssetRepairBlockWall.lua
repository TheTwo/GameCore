local CityTileAssetPollutedGroupMember = require("CityTileAssetPollutedGroupMember")
---@class CityTileAssetRepairBlockWall:CityTileAssetPollutedGroupMember
---@field new fun():CityTileAssetRepairBlockWall
local CityTileAssetRepairBlockWall = class("CityTileAssetRepairBlockWall", CityTileAssetPollutedGroupMember)
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local Quaternion = CS.UnityEngine.Quaternion
local EventConst = require("EventConst")
local Delegate = require("Delegate")

---@param group CityTileAssetRepairBlockGroup
---@param repairBlock CityBuildingRepairBlock
---@param wallIdx number
function CityTileAssetRepairBlockWall:ctor(group, repairBlock, wallIdx)
    CityTileAssetPollutedGroupMember.ctor(self, group)
    self.repairBlock = repairBlock
    self.wallIdx = wallIdx
    self.wallCfg = self.repairBlock.cfg:RepairWalls(wallIdx)
    self.allowSelected = true
end

function CityTileAssetRepairBlockWall:GetCustomNameInGroup()
    return string.format("wall%d_of_%d", self.wallIdx, self.repairBlock.id)
end

function CityTileAssetRepairBlockWall:GetPrefabName()
    if not self.repairBlock:IsBaseRepaired() then
        return string.Empty
    end

    if not self.repairBlock:IsValid() then
        return string.Empty
    end

    if self.repairBlock:IsWallRepaired(self.wallIdx) then
        return ArtResourceUtils.GetItem(self.wallCfg:ModelFixed())
    end
    return ArtResourceUtils.GetItem(self.wallCfg:Model())
end

function CityTileAssetRepairBlockWall:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end

    local tile = self.tileView.tile:GetCell()
    local x, y = tile.x + self.repairBlock.cfg:X() + self.wallCfg:OffsetX(), tile.y + self.repairBlock.cfg:Y() + self.wallCfg:OffsetY()
    local pos = self:GetCity():GetWorldPositionFromCoord(x, y)
    go.transform:SetPositionAndRotation(pos, Quaternion.identity)
    CityTileAssetPollutedGroupMember.OnAssetLoaded(self, go, userdata)
end

function CityTileAssetRepairBlockWall:OnTileViewInit()
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_WALL_HIGHLIGHT, Delegate.GetOrCreate(self, self.OnHighlight))
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_WALL_FLASH, Delegate.GetOrCreate(self, self.OnFlash))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExited))
end

function CityTileAssetRepairBlockWall:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_WALL_HIGHLIGHT, Delegate.GetOrCreate(self, self.OnHighlight))
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_WALL_FLASH, Delegate.GetOrCreate(self, self.OnFlash))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExited))
end

function CityTileAssetRepairBlockWall:OnHighlight(repairBlock, wallIdx, flag)
    if self.repairBlock.id ~= repairBlock.id or self.wallIdx ~= wallIdx then return end
    self:SetSelected(flag)
end

function CityTileAssetRepairBlockWall:OnFlash(repairBlock, wallIdx, flag)
    if self.repairBlock.id ~= repairBlock.id or self.wallIdx ~= wallIdx then return end
    if flag then
        self:GetCity().flashMatController:StartFlash(self.handle.Asset)
    else
        self:GetCity().flashMatController:StopFlash(self.handle.Asset)
    end
end

function CityTileAssetRepairBlockWall:IsPolluted()
    return self.repairBlock:IsPolluted()
end

function CityTileAssetRepairBlockWall:IsMine(buildingId)
    return self.repairBlock.building.id == buildingId
end

return CityTileAssetRepairBlockWall