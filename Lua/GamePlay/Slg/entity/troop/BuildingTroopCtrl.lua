local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local AbstractCtrl = require('AbstractCtrl')

---@class BuildingTroopCtrl : AbstractCtrl
local BuildingTroopCtrl = class('BuildingTroopCtrl',AbstractCtrl)

---@param data wds.MapBuilding
function BuildingTroopCtrl:ctor( data,dbEntityPath)    
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

function BuildingTroopCtrl:DoOnNewEntity()    
    self:FindBuildView()
    if self.viewType then
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
    end
    if self.buildView and self.buildView.SetBattleState then
        self.buildView:SetBattleState(self._initBattleStatus)
    end
end

function BuildingTroopCtrl:FindBuildView()
    ---@type City
    local myCity = self._module.curScene and self._module.curScene.GetCurrentViewedCity and self._module.curScene:GetCurrentViewedCity()
    if not myCity then
        return
    end
    
    local uniqueId = self._data.Base.CityBrief.EntityCityId
    self.viewType = self._data.Base.CityBrief.cityType
    if self.viewType == wds.CityBattleObjType.CityBattleObjTypeBuilding then
        self.buildView = myCity.buildingManager:GetBuilding(uniqueId)    
        self:CreateECSViewEntity()
    elseif self.viewType == wds.CityBattleObjType.CityBattleObjTypeFurniture then
        self.buildView = myCity.furnitureManager:GetFurnitureById(uniqueId)
        self:CreateECSViewEntity()
    elseif self.viewType == wds.CityBattleObjType.CityBattleObjTypeWall then
        self.buildView = myCity.safeAreaWallMgr:GetBattleViewWall(uniqueId)
    elseif self.viewType == wds.CityBattleObjType.CityBattleObjTypeElement then
        self.buildView = myCity.elementManager:GetElementById(uniqueId)        
        self:CreateECSViewEntity()
    end  
end

function BuildingTroopCtrl:CreateECSViewEntity() 
    if not self.buildView then
    end
    local troopData = self._module.troopManager:CreateECSTroopData(self._data)    
    if troopData  then
        g_Game.TroopViewManager:CreateTroopViewEntity(troopData)        
    end
end

function BuildingTroopCtrl:DoOnDestroyEntity()
    self._isValid = false
    g_Game.TroopViewManager:DelTroopViewEntity(self._data.ID)
end

---@param data wds.MapBuilding
---@param change wds.Battle
function BuildingTroopCtrl:OnBattleChanged(data,change)
    if data.ID ~= self.ID  then return end    
    if change and (change.Durability or change.MaxDurability)then
        self:UpdateHP(data.Battle.Durability,data.Battle.MaxDurability)
    end
    
    if change.TargetUID and self.buildView and self.buildView.SetAttackingState then
        local targetCtrl = self._module:GetTroopCtrl(data.Battle.TargetUID)
        local targetTrans = (targetCtrl ~= nil and targetCtrl:IsValid() ) and targetCtrl:GetTransform() or nil
        if targetTrans then
            self._direction = (targetTrans.position - self._position).normalized
        end
        self.buildView:SetAttackingState(targetTrans ~= nil,targetTrans)
    end
end

---@param data wds.MapBuilding
---@param change wds.MapEntityState
function BuildingTroopCtrl:OnMapStateChanged(data,change)
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
---@param data wds.MapBuilding
---@param change wds.MapEntityBasicInfo
function BuildingTroopCtrl:OnMapBasicsChanged(data,change)
    if data.ID ~= self.ID then return end        
    if change and change.Position then
        self._position = self._module:ServerCoordinate2Vector3(self._data.MapBasics.Position)
        g_Game.TroopViewManager:SyncViewPosition(self.ID,self._position)
    end
end

function BuildingTroopCtrl:SetBattleState(inBattle)
    if not self.buildView or not self.buildView.SetBattleState then
        -- self:FindBuildView()
        -- if not self.buildView then return end
        return
    end
    self.buildView:SetBattleState(inBattle)
end
---@param data wds.MapBuilding
function BuildingTroopCtrl:SetAttackingState(data,inAttacking)
    if not self.buildView or not self.buildView.SetAttackingState then
        -- self:FindBuildView()
        -- if not self.buildView then return end
        return
    end    
    if inAttacking then
        local targetCtrl = self._module:GetTroopCtrl(data.Battle.TargetUID)
        local targetTrans = (targetCtrl ~= nil) and targetCtrl:GetTransform() or nil        
        if targetTrans then
            self._direction = (targetTrans.position - self._position).normalized
        end
        self.buildView:SetAttackingState(targetTrans ~= nil,targetTrans)
    else
        self.buildView:SetAttackingState(false,nil)
    end
end

function BuildingTroopCtrl:UpdateHP(hp,maxhp)
    if not self.buildView then
        -- self:FindBuildView()
        -- if not self.buildView then return end
        return
    end
    if self.buildView.UpdateHP then
        self.buildView:UpdateHP(hp,maxhp)
    end
end

function BuildingTroopCtrl:GetPosition()
    if self:IsValid() then
        return self._position
    end
    return CS.UnityEngine.Vector3.zero
end

function BuildingTroopCtrl:GetForward()
    if self:IsValid() then
        return self._direction
    end
    return CS.UnityEngine.Vector3.forward
end

function BuildingTroopCtrl:GetID()
    return self._data.ID
end

function BuildingTroopCtrl:IsValid()
    return self._isValid
end

function BuildingTroopCtrl:IsNotValid()
    return not self._isValid
end

function BuildingTroopCtrl:IsSelf()
    return self._module:IsMyTroop(self._data)
end

function BuildingTroopCtrl:GetHeroIndex(skillId)
    return 1
end

---@param skillCastInfo SkillCastInfo
---@param dataCache SlgDataCacheModule
function BuildingTroopCtrl:PlaySkill(skillId,targetPos,dataCache)
    if not self.buildView or not targetPos or not dataCache then       
        return
    end
    if self.buildView.PlaySkill then
        -- local targetPos
        -- if skillCastInfo.targetCtrl then
        --     targetPos = skillCastInfo.targetCtrl:GetPosition()
        -- elseif skillCastInfo.targetPos then
        --     targetPos = skillCastInfo.targetPos
        -- end
    
        local skillConfig = dataCache:GetSkillAssetCache(skillId)
        local animName = skillConfig.animName
        local animDuration = skillConfig.animDuration
       
        if animName and animDuration and animDuration > 0 then
            if targetPos then
                self._direction = (targetPos - self._position).normalized
            end
            self.buildView:PlaySkill(targetPos,animName,animDuration)
        end
    end
end

---@param targetPos CS.UnityEngine.Vector3
---@param dataCache SlgDataCacheModule
function BuildingTroopCtrl:PlayNormalAtt(targetPos,dataCache)
    if not self.normalAttId then
        return
    end

    local skillConfig = dataCache:GetSkillAssetCache(self.normalAttId)
    local animName = skillConfig.animName
    local animDuration = skillConfig.animDuration
    
    if animName and animDuration and animDuration > 0 then
        if targetPos then
            self._direction = (targetPos - self._position).normalized
        end
        self.buildView:PlaySkill(targetPos,animName,animDuration)
    end
end


return BuildingTroopCtrl