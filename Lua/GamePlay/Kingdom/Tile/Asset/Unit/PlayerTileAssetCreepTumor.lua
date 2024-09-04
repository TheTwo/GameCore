local PvPTileAssetUnit = require("PvPTileAssetUnit")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")

local Vector3 = CS.UnityEngine.Vector3

---@class PlayerTileAssetCreepTumor : PvPTileAssetUnit
---@field isAlive boolean
---@field creepData wds.PlayerMapCreep
---@field config SlgCreepTumorConfigCell
---@field animator CS.UnityEngine.Animator
local PlayerTileAssetCreepTumor = class("PlayerTileAssetCreepTumor", PvPTileAssetUnit)

function PlayerTileAssetCreepTumor:CanShow()
    if not self.creepData then
        return false
    end

    self.isAlive = ModuleRefer.MapCreepModule:IsTumorAlive(self.creepData)
    if not self.isAlive then
        return false
    end

    return true
end

function PlayerTileAssetCreepTumor:GetPosition()
    return self:CalculateCenterPosition()
end

function PlayerTileAssetCreepTumor:GetScale()
    if self.config then
        return ArtResourceUtils.GetScale(self.config:CenterModel()) * Vector3.one
    end
    return Vector3.one
end

--function PlayerTileAssetCreepTumor:GetEnableFadeOut()
--    return true
--end
--
--function PlayerTileAssetCreepTumor:GetFadeOutDuration()
--    return 1.5
--end

---@return string
function PlayerTileAssetCreepTumor:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) or KingdomMapUtils.InMapLowLod(lod) then
        if self.config then
            return ArtResourceUtils.GetItem(self.config:CenterModel())
        end
    end
    return string.Empty
end

function PlayerTileAssetCreepTumor:OnShow()
    PvPTileAssetUnit.OnShow(self)
    
    self.creepData = self:GetData()
    if not self.creepData then
        return
    end
    self.config = ConfigRefer.SlgCreepTumor:Find(self.creepData.CfgId)
end

function PlayerTileAssetCreepTumor:OnConstructionSetup()
    PvPTileAssetUnit.OnConstructionSetup(self)
    
    local go = self:GetAsset()
    if go then
        self.animator = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
    end
    
    self:OnConstructionUpdate()
end

function PlayerTileAssetCreepTumor:OnHide()
    PvPTileAssetUnit.OnHide(self)
    
    self.isAlive = false
    self.animator = nil
    self.config = nil
end

function PlayerTileAssetCreepTumor:OnConstructionUpdate()
    PvPTileAssetUnit.OnConstructionUpdate(self)
    
    if not self.creepData then
        return
    end

    local isAlive = ModuleRefer.MapCreepModule:IsTumorAlive(self.creepData)

    if self.animator then
        if self.isAlive ~= isAlive then
            self.animator:Play("death")
        else
            self.animator:Play("idle")
        end
    end
    
    if isAlive then
        self:Show()
    else
        self:Hide()
    end

    self.isAlive = isAlive
end

return PlayerTileAssetCreepTumor