local ModuleRefer = require('ModuleRefer')

---@class wds.BasicMapEntity
---@field public ID number
---@field public MapBasics wds.MapEntityBasicInfo
---@field public MapStates wds.MapEntityState
---@field public MovePathInfo wds.MovePathInfo
---@field public Battle wds.Battle
---@field public Skill wds.Skill
---@field public Owner wds.Owner
---@field public V wds.Vault
---@field public viewTypeCount number

---@class AbstractCtrl
---@field new fun(data:table, dbEntityPath)
---@field _data wds.BasicMapEntity
---@field TypeHash number
---@field ID number
---@field _module SlgModule
local AbstractCtrl = class('AbstractCtrl')

---@param data wds.BasicMapEntity
function AbstractCtrl:ctor( data,dbEntityPath)    
    self._module = ModuleRefer.SlgModule    
    if data then
        self._data = data
        self.TypeHash = data.TypeHash
        self.ID = data.ID
    end
    self._dbEntityPath = dbEntityPath
end

function AbstractCtrl:DoOnNewEntity()  
end

function AbstractCtrl:DoOnDestroyEntity()  
end


function AbstractCtrl:GetPosition()   
    return CS.UnityEngine.Vector3.zero
end

function AbstractCtrl:GetForward()   
    return CS.UnityEngine.Vector3.forward
end

function AbstractCtrl:GetID()
    return self.ID
end

function AbstractCtrl:IsValid()
    return false
end

function AbstractCtrl:IsNotValid()
    return true
end

function AbstractCtrl:IsSelf()
    return self._module:IsMyTroop(self._data)
end

function AbstractCtrl:GetHeroIndex(skillId)
    return 1
end

---@param targetCtrlsInfo SkillCastInfo
---@param dataCache SlgDataCacheModule
function AbstractCtrl:PlaySkill(skillId,targetCtrlsInfo,dataCache)   
end

---@param targetCtrl TroopCtrl
---@param dataCache SlgDataCacheModule
function AbstractCtrl:PlayNormalAtt(targetCtrl,dataCache)    
end


---@param data wds.Troop | wds.MapMob | wds.MobileFortress
---@param change wds.MovePathInfo
function AbstractCtrl:OnMovePathInfoChanged(data,change)
  
end

---@param data wds.Troop | wds.MapMob | wds.MobileFortress
---@param change wds.Battle
function AbstractCtrl:OnBattleChanged(data,change)
   
end
---@param data wds.Troop | wds.MapMob | wds.MobileFortress
---@param change wds.MapEntityState
function AbstractCtrl:OnMapStateChanged(data,change)
    
end
---@param data wds.Troop | wds.MapMob | wds.MobileFortress
---@param change wds.MapEntityBasicInfo
function AbstractCtrl:OnMapBasicsChanged(data,change)
   
end
---@param data wds.Troop | wds.MapMob | wds.MobileFortress
---@param change table<number, wds.BuffInfo>
function AbstractCtrl:OnBuffChanged(data,change)
   
end


function AbstractCtrl:IsVisible()   
    return true
end

return AbstractCtrl