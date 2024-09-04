local CityBuildingRepairBlockDatum = require("CityBuildingRepairBlockDatum")

---@class CityBuildingRepairBlockBaseDatum:CityBuildingRepairBlockDatum
---@field new fun(repairBlock:CityBuildingRepairBlock):CityBuildingRepairBlockBaseDatum
local CityBuildingRepairBlockBaseDatum = class("CityBuildingRepairBlockBaseDatum", CityBuildingRepairBlockDatum)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local AudioConsts = require("AudioConsts")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

---@param repairBlock CityBuildingRepairBlock
function CityBuildingRepairBlockBaseDatum:ctor(repairBlock)
    self.repairBlock = repairBlock
    self.flashing = false
end

function CityBuildingRepairBlockBaseDatum:GetCostItemIconData()
    return self.repairBlock:GetRepairBaseCostItemIconData()
end

function CityBuildingRepairBlockBaseDatum:GetRepairBlock()
    return self.repairBlock
end

function CityBuildingRepairBlockBaseDatum:RequestCost(itemId)
    self.repairBlock.building.mgr:RequestAddMatToRepairBase(self.repairBlock.building.id, self.repairBlock.id, itemId)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_sweepfloor)
    self:PlayAddMatVfx()
    if self.repairBlock:IsLastBaseRepairCost() then
        self.waitFinishVfx = true
    end
end

function CityBuildingRepairBlockBaseDatum:AddEventListener()
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_UPDATE, Delegate.GetOrCreate(self, self.OnBlockChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_REPAIR_BLOCK_REMOVE, Delegate.GetOrCreate(self, self.OnBlockRemoved))
end

function CityBuildingRepairBlockBaseDatum:RemoveEventListener()
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_UPDATE, Delegate.GetOrCreate(self, self.OnBlockChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_REPAIR_BLOCK_REMOVE, Delegate.GetOrCreate(self, self.OnBlockRemoved))
end

---@param building CityBuilding
function CityBuildingRepairBlockBaseDatum:OnBlockChanged(building, blockId)
    if self.repairBlock ~= building:GetRepairBlockByCfgId(blockId) then return end

    if self.waitFinishVfx then
        self.waitFinishVfx = nil
        self:PlayFinishVfx()
    end
    
    if self.repairBlock:IsBaseRepaired() then
        g_Game.UIManager:UIMediatorCloseSelfByName(UIMediatorNames.CityBuildingRepairBlockBaseUIMediator)
    end
end

function CityBuildingRepairBlockBaseDatum:OnBlockRemoved(building, blockId)
    if self.repairBlock.building == building and self.repairBlock.id == blockId then
        g_Game.UIManager:UIMediatorCloseSelfByName(UIMediatorNames.CityBuildingRepairBlockBaseUIMediator)
    end
end

function CityBuildingRepairBlockBaseDatum:TriggerFlashEvent(flag)
    if self.flashing ~= flag then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_BASE_FLASH, self.repairBlock, flag)
    end
    self.flashing = flag
end

function CityBuildingRepairBlockBaseDatum:PlayAddMatVfx()
    local city = self.repairBlock.building.mgr.city
    city.createHelper:Create(ManualResourceConst.vfx_common_build_sweep, city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnAddMatVfxCreated))
end

function CityBuildingRepairBlockBaseDatum:PlayFinishVfx()
    local city = self.repairBlock.building.mgr.city
    city.createHelper:Create(ManualResourceConst.vfx_common_build_sweep_01, city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnFinishVfxCreated))
end

---@param go CS.UnityEngine.GameObject
function CityBuildingRepairBlockBaseDatum:OnAddMatVfxCreated(go, userdata, handle)
    if Utils.IsNull(go) then
        handle:Delete()
        return
    end

    go:SetLayerRecursively("City")
    local trans = go.transform
    local building = self.repairBlock.building
    local x, y = building.x + self.repairBlock.cfg:X(), building.y + self.repairBlock.cfg:Y()
    local sizeX, sizeY = self.repairBlock.cfg:SizeX(), self.repairBlock.cfg:SizeY()
    trans.position = self.repairBlock.building.mgr.city:GetCenterWorldPositionFromCoord(x, y, sizeX, sizeY)
    trans.localScale = {x = sizeX / 10, y = 1, z = sizeY / 10}
    handle:Delete(5)
end

---@param go CS.UnityEngine.GameObject
function CityBuildingRepairBlockBaseDatum:OnFinishVfxCreated(go, userdata, handle)
    if Utils.IsNull(go) then
        handle:Delete()
        return
    end

    go:SetLayerRecursively("City")
    local trans = go.transform
    local building = self.repairBlock.building
    local x, y = building.x + self.repairBlock.cfg:X(), building.y + self.repairBlock.cfg:Y()
    local sizeX, sizeY = self.repairBlock.cfg:SizeX(), self.repairBlock.cfg:SizeY()
    trans.position = self.repairBlock.building.mgr.city:GetCenterWorldPositionFromCoord(x, y, sizeX, sizeY)
    trans.localScale = {x = sizeX / 10, y = 1, z = sizeY / 10}
    handle:Delete(5)
end

return CityBuildingRepairBlockBaseDatum