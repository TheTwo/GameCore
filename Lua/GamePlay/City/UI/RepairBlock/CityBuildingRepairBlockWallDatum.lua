local CityBuildingRepairBlockDatum = require("CityBuildingRepairBlockDatum")

---@class CityBuildingRepairBlockWallDatum:CityBuildingRepairBlockDatum
---@field new fun(repairBlock:CityBuildingRepairBlock, wallIdx:number):CityBuildingRepairBlockWallDatum
local CityBuildingRepairBlockWallDatum = class("CityBuildingRepairBlockWallDatum", CityBuildingRepairBlockDatum)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local AudioConsts = require("AudioConsts")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

---@param repairBlock CityBuildingRepairBlock
---@param wallIdx number
function CityBuildingRepairBlockWallDatum:ctor(repairBlock, wallIdx)
    self.repairBlock = repairBlock
    self.wallIdx = wallIdx
    self.wallCfg = self.repairBlock.cfg:RepairWalls(wallIdx)
    self.flashing = false
end

function CityBuildingRepairBlockWallDatum:GetCostItemIconData()
    return self.repairBlock:GetRepairWallCostItemIconData(self.wallIdx)
end

function CityBuildingRepairBlockWallDatum:GetRepairBlock()
    return self.repairBlock
end

function CityBuildingRepairBlockWallDatum:RequestCost(itemId)
    self.repairBlock.building.mgr:RequestAddMatToRepairWall(self.repairBlock.building.id, self.repairBlock.id, self.wallIdx, itemId)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_repairwall)
    self:PlayVfx()
end

function CityBuildingRepairBlockWallDatum:AddEventListener()
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_UPDATE, Delegate.GetOrCreate(self, self.OnBlockChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_REMOVE, Delegate.GetOrCreate(self, self.OnBlockRemoved))
end

function CityBuildingRepairBlockWallDatum:RemoveEventListener()
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_UPDATE, Delegate.GetOrCreate(self, self.OnBlockChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_REMOVE, Delegate.GetOrCreate(self, self.OnBlockRemoved))
end

---@param building CityBuilding
function CityBuildingRepairBlockWallDatum:OnBlockChanged(building, blockId)
    if self.repairBlock ~= building:GetRepairBlockByCfgId(blockId) then return end
    
    if self.repairBlock:IsWallRepaired(self.wallIdx) then
        g_Game.UIManager:UIMediatorCloseSelfByName(UIMediatorNames.CityBuildingRepairBlockBaseUIMediator)
    end
end

function CityBuildingRepairBlockWallDatum:OnBlockRemoved(building, blockId)
    if self.repairBlock.building == building and self.repairBlock.id == blockId then
        g_Game.UIManager:UIMediatorCloseSelfByName(UIMediatorNames.CityBuildingRepairBlockBaseUIMediator)
    end
end

function CityBuildingRepairBlockWallDatum:TriggerFlashEvent(flag)
    if self.flashing ~= flag then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_WALL_FLASH, self.repairBlock, self.wallIdx, flag)
    end
    self.flashing = flag
end

function CityBuildingRepairBlockWallDatum:PlayVfx()
    local city = self.repairBlock.building.mgr.city
    city.createHelper:Create(ManualResourceConst.vfx_common_build_repair, city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnVfxCreated))
end

---@param go CS.UnityEngine.GameObject
function CityBuildingRepairBlockWallDatum:OnVfxCreated(go, userdata, handle)
    if Utils.IsNull(go) then
        handle:Delete()
        return
    end

    go:SetLayerRecursively("City")
    local trans = go.transform
    local building = self.repairBlock.building
    local offsetX, offsetY = self.wallCfg:OffsetX(), self.wallCfg:OffsetY()
    local x, y = building.x + self.repairBlock.cfg:X() + offsetX, building.y + self.repairBlock.cfg:Y() + offsetY
    local isVertical = self.wallCfg:IsVertical()
    local size = isVertical and self.repairBlock.cfg:SizeY() or self.repairBlock.cfg:SizeX()
    local position = self.repairBlock.building.mgr.city:GetWorldPositionFromCoord(x, y)
    local rotation = isVertical and CS.UnityEngine.Quaternion.Euler(0, 90, 0) or CS.UnityEngine.Quaternion.identity
    trans:SetPositionAndRotation(position, rotation)
    trans.localScale = {x = size / 10, y = 1, z = size / 10}
    handle:Delete(5)
end

return CityBuildingRepairBlockWallDatum