local ConfigRefer = require('ConfigRefer')
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local AbstractCtrl = require('AbstractCtrl')
---@class KBuildingTroopCtrl
---@field new fun(data:wds.DefenceTower, dbEntityPath)
---@field _data wds.DefenceTower
---@field TypeHash number
---@field ID number
local KBuildingTroopCtrl = class('KBuildingTroopCtrl',AbstractCtrl)

---@param data wds.DefenceTower
function KBuildingTroopCtrl:ctor( data,dbEntityPath)    
    self._module = ModuleRefer.SlgModule;
    
    if data then
        self._data = data
        self.TypeHash = data.TypeHash
        self.ID = data.ID
        self._radius = data.Battle.Radius        
    end
    self._dbEntityPath = dbEntityPath   
    self._initBattleStatus = data and data.MapStates and data.MapStates.Battling
end

function KBuildingTroopCtrl:DoOnNewEntity()    
    self:CreateECSViewEntity()
    self._isValid = true
    if self._data then
        self._position = self._module:ServerCoordinate2Vector3(self._data.MapBasics.Position)
        self._direction = CS.UnityEngine.Vector3(self._data.MapBasics.Direction.X, 0, self._data.MapBasics.Direction.Y)
        local heroes = self._data.Battle.Group.Heros
        if heroes and heroes:Count() > 0 and heroes[0] ~= nil then
            local mainHero = heroes[0]
            local heroConfig = ConfigRefer.Heroes:Find(mainHero.HeroID)
            if heroConfig then
                ---@type HeroClientResConfigCell
                local heroClientConfig = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())
                if heroClientConfig then
                    self.normalAttId = heroClientConfig:NormalAttAsset()                        
                end
            end    
        end
    else
        self._position = CS.UnityEngine.Vector3.zero
        self._direction = CS.UnityEngine.Vector3.forward
    end
    self:SetBattleState(self._initBattleStatus)
end

function KBuildingTroopCtrl:CreateECSViewEntity()   
    local troopData = self._module.troopManager:CreateECSTroopData(self._data)    
    if troopData  then
        g_Game.TroopViewManager:CreateTroopViewEntity(troopData)        
    end
end

function KBuildingTroopCtrl:DoOnDestroyEntity()
    self._isValid = false
    g_Game.TroopViewManager:DelTroopViewEntity(self._data.ID)
end

---@param data wds.DefenceTower
---@param change wds.Battle
function KBuildingTroopCtrl:OnBattleChanged(data,change)
    if data.ID ~= self.ID  then return end    
    if change and (change.Durability or change.MaxDurability)then
        self:UpdateHP(data.Battle.Durability,data.Battle.MaxDurability)
    end
    
    if change.TargetUID then
        local targetCtrl = self._module:GetTroopCtrl(data.Battle.TargetUID)
        local targetTrans = (targetCtrl ~= nil and targetCtrl:IsValid() ) and targetCtrl:GetTransform() or nil
        g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_BUILDING_SLG_ATTACK_STATE,self.ID,targetTrans ~= nil,targetTrans)
    end
end

---@param data wds.DefenceTower
---@param change wds.MapEntityState
function KBuildingTroopCtrl:OnMapStateChanged(data,change)
    if data.ID ~= self.ID then return end       
    if change ~= nil  then
        if change.Battling then
            self:SetBattleState(change.Battling)
        end
        if change.Attacking then
            self:SetAttackingState(data,change.Attacking)
        end
    end
end
---@param data wds.DefenceTower
---@param change wds.MapEntityBasicInfo
function KBuildingTroopCtrl:OnMapBasicsChanged(data,change)
    if data.ID ~= self.ID then return end        
    if change and (change.Position or change.Direction)then
        self._position = self._module:ServerCoordinate2Vector3(self._data.MapBasics.Position)
    end
end

function KBuildingTroopCtrl:SetBattleState(inBattle)   
    g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_BUILDING_SLG_BATTLE_STATE,self.ID,inBattle)
end
---@param data wds.DefenceTower
function KBuildingTroopCtrl:SetAttackingState(data,inAttacking)    
    if inAttacking then
        local targetCtrl = self._module:GetTroopCtrl(data.Battle.TargetUID)
        local targetTrans = (targetCtrl ~= nil) and targetCtrl:GetTransform() or nil                
        g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_BUILDING_SLG_ATTACK_STATE,self.ID,targetTrans ~= nil,targetTrans)
    else        
        g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_BUILDING_SLG_ATTACK_STATE,self.ID,false,nil)
    end
end

function KBuildingTroopCtrl:UpdateHP(hp,maxhp)
   
end

function KBuildingTroopCtrl:GetPosition()
    if self:IsValid() then
        return self._position
    end
    return CS.UnityEngine.Vector3.zero
end

function KBuildingTroopCtrl:GetForward()
    if self:IsValid() then
        return self._direction
    end
    return CS.UnityEngine.Vector3.forward
end

function KBuildingTroopCtrl:GetID()
    return self._data.ID
end

function KBuildingTroopCtrl:IsValid()
    return self._isValid
end

function KBuildingTroopCtrl:IsNotValid()
    return not self._isValid
end

function KBuildingTroopCtrl:IsSelf()
    return self._module:IsMyTroop(self._data)
end

function KBuildingTroopCtrl:GetHeroIndex(skillId)
    return 1
end

---@param skillCastInfo SkillCastInfo
---@param dataCache SlgDataCacheModule
function KBuildingTroopCtrl:PlaySkill(skillId,targetPos,dataCache)
    if not targetPos or not dataCache then       
        return
    end
   
    local skillConfig = dataCache:GetSkillAssetCache(skillId)
    local animName = skillConfig.animName
    local animDuration = 1 --skillConfig.animDuration
    
    if animName and animDuration and animDuration > 0 then
        if targetPos then
            self._direction = (targetPos - self._position).normalized
        end
        g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_BUILDING_SLG_PLAY_ANIM,self.ID,targetPos,animName)
    end
    
end

---@param targetPos CS.UnityEngine.Vector3
---@param dataCache SlgDataCacheModule
function KBuildingTroopCtrl:PlayNormalAtt(targetPos,dataCache)
    if not self.normalAttId then
        return
    end
    local skillConfig = dataCache:GetSkillAssetCache(self.normalAttId)
    local animName = skillConfig.animName
    local animDuration = 1 --skillConfig.animDuration
    
    if animName and animDuration and animDuration > 0 then
        if targetPos then
            self._direction = (targetPos - self._position).normalized
        end
        g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_BUILDING_SLG_PLAY_ANIM,self.ID,targetPos,animName)
    end
end


return KBuildingTroopCtrl