local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require('KingdomMapUtils')
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local Delegate = require("Delegate")
local EventConst = require("EventConst")

---@class PvPTileAssetDefenceTower : PvPTileAssetUnit
---@field super PvPTileAssetUnit
local PvPTileAssetDefenceTower = class("PvPTileAssetDefenceTower", PvPTileAssetUnit)

function PvPTileAssetDefenceTower:ctor()
    PvPTileAssetDefenceTower.super.ctor(self)
    ---@type MapUITrigger
    self._touchTrigger = nil
end

---@return wds.DefenceTower
function PvPTileAssetDefenceTower:GetEntity()
    if not self.entity then
        self.entity =  g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    end
    return self.entity
end
function PvPTileAssetDefenceTower:OnShow()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnFrameUpdate))
end

function PvPTileAssetDefenceTower:OnHide()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnFrameUpdate))
end

function PvPTileAssetDefenceTower:OnFrameUpdate()
    if self.controller and self.targetTrans then
        self.controller:LookAt(self.targetTrans.position)
    end
end

---@return string
function PvPTileAssetDefenceTower:GetLodPrefabName(lod)
    ---@type wds.DefenceTower
    local entity = self:GetEntity()
    if not entity then
        return string.Empty
    end
    local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
    if not KingdomMapUtils.CheckIsEnterOrHigherIconLodFlexible(entity.MapBasics.ConfID, lod) then
        if entity.Construction.Status == wds.BuildingConstructionStatus.BuildingConstructionStatusProcessing then
            return ArtResourceUtils.GetItem(buildingConfig:InConstructionModel())
        else
            return ArtResourceUtils.GetItem(buildingConfig:Model())
        end
    end
    return string.Empty
end

function PvPTileAssetDefenceTower:OnConstructionSetup()
    PvPTileAssetDefenceTower.super.OnConstructionSetup(self)
    local asset = self:GetAsset()
    if Utils.IsNull(asset) then
        return
    end
    local trigger = asset:GetLuaBehaviourInChildren("MapUITrigger", true)
    if Utils.IsNull(trigger) then
        return
    end
    self._touchTrigger = trigger.Instance
    if self._touchTrigger then
        self._touchTrigger:SetTrigger(Delegate.GetOrCreate(self, self.OnClickSelfTrigger))
    end
    self.ID = self:GetUniqueId()
    ---@type CS.CitySLGBattleUnitController
    self.controller = asset:GetComponent(typeof(CS.CitySLGBattleUnitController))
    if self.controller then
        ---@type wds.DefenceTower
        local entity = self:GetEntity()        
        local forward = entity and CS.UnityEngine.Vector3(entity.MapBasics.Direction.X,0,entity.MapBasics.Direction.Y) or CS.UnityEngine.Vector3.forward
        self.controller:SetForward(forward)
        self.controller:PlayAnimState("idle")
    end
    g_Game.EventManager:AddListener(EventConst.KINGDOM_BUILDING_SLG_BATTLE_STATE, Delegate.GetOrCreate(self, self.OnBuildingBattleState))
    g_Game.EventManager:AddListener(EventConst.KINGDOM_BUILDING_SLG_ATTACK_STATE, Delegate.GetOrCreate(self, self.OnBuildingAttackState))
    g_Game.EventManager:AddListener(EventConst.KINGDOM_BUILDING_SLG_PLAY_ANIM, Delegate.GetOrCreate(self, self.OnBuildingPlayAnimation))
end

function PvPTileAssetDefenceTower:OnConstructionShutdown()
    if self._touchTrigger then
        self._touchTrigger:SetTrigger(nil)
    end    
    self._touchTrigger = nil
    g_Game.EventManager:RemoveListener(EventConst.KINGDOM_BUILDING_SLG_BATTLE_STATE, Delegate.GetOrCreate(self, self.OnBuildingBattleState))
    g_Game.EventManager:RemoveListener(EventConst.KINGDOM_BUILDING_SLG_ATTACK_STATE, Delegate.GetOrCreate(self, self.OnBuildingAttackState))
    g_Game.EventManager:RemoveListener(EventConst.KINGDOM_BUILDING_SLG_PLAY_ANIM, Delegate.GetOrCreate(self, self.OnBuildingPlayAnimation))
end

function PvPTileAssetDefenceTower:OnClickSelfTrigger()
    local x, y = self:GetServerPosition()
    if x <= 0 or y <= 0 then
        return
    end
    local scene = KingdomMapUtils.GetKingdomScene()
    local coord = CS.DragonReborn.Vector2Short(math.floor(x + 0.5), math.floor(y + 0.5))
    scene.mediator:ChooseCoordTile(coord)
end

function PvPTileAssetDefenceTower:OnBuildingBattleState(id, isBattle)
    if id ~= self.ID or not self.controller then
        return
    end
    -- g_Logger.LogChannel("PvPTileAssetDefenceTower", "OnBuildingBattleState[%d]-Battleing:[%s]", id, tostring(isBattle))

end

---@param id number
---@param isaAttacking boolean
---@param targetTrans CS.UnityEngine.Transform
function PvPTileAssetDefenceTower:OnBuildingAttackState(id, isAttacking, targetTrans)
    if id ~= self.ID or not self.controller then
        return
    end    

    if isAttacking and targetTrans then
        self.targetTrans = targetTrans        
    else
        self.targetTrans = nil
    end
end

function PvPTileAssetDefenceTower:OnBuildingPlayAnimation(id, targetPosition,animName)
    if id ~= self.ID or not self.controller then
        return
    end
    -- g_Logger.LogChannel("PvPTileAssetDefenceTower", "OnBuildingPlayAnimation[%d]-AnimName:[%s]", id, animName)
    self.controller:LookAt(targetPosition)
    self.controller:PlayAnimState(animName)
end



return PvPTileAssetDefenceTower