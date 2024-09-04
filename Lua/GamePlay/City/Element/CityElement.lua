---@class CityElement
---@field new fun():CityElement
local CityElement = class("CityElement")
local EventConst = require("EventConst")

---@param mgr CityElementManager
function CityElement:ctor(mgr)
    self.mgr = mgr
	self.interactPoints = {}
end

---@param cfg CityElementDataConfigCell
function CityElement:FromElementDataCfg(cfg)
    --- 由于可生成资源点的存在，现在CityElementData表的Id有着类似于资源唯一Id的作用，所以这里配置Id同样是唯一Id
    self.id = cfg:Id()
    self.configId = cfg:Id()
    local coord = cfg:Pos()
    self.x = coord:X()
    self.y = coord:Y()
    self.battleState = false
end

function CityElement:FromManualData(id, x, y)
    self.id = id
    self.configId = -1
    self.x = x
    self.y = y
    self.battleState = false
end

function CityElement:IsNpc()
    return false
end

function CityElement:IsResource()
    return false
end

function CityElement:IsSpawner()
    return false
end

function CityElement:IsHidden()
    return self.mgr:IsHidden(self.id)
end

function CityElement:SetBattleState(inBattle)
    self.battleState = inBattle
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_ASSET_UPDATE, wds.CityBattleObjType.CityBattleObjTypeElement, self.id)
end

function CityElement:SetAttackingState(inAttacking, targetTrans)
    if inAttacking and not self.battleState then
        self:SetBattleState(true)
    end

    local name = targetTrans == nil and "empty" or targetTrans.gameObject.name
    self.inAttacking = inAttacking
    self.targetTrans = targetTrans
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_ASSET_ATTACK_TARGET, wds.CityBattleObjType.CityBattleObjTypeElement, self.id)
end

function CityElement:UpdateHP(hp, maxhp)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_HP_UPDATE, wds.CityBattleObjType.CityBattleObjTypeElement, self.id)
end

---@param targetPos CS.UnityEngine.Vector3
---@param animName string
---@param animDuration number
function CityElement:PlaySkill(targetPos, animName, animDuration)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SLG_PLAY_SKILL, wds.CityBattleObjType.CityBattleObjTypeElement, self.id, targetPos, animName, animDuration)
end

function CityElement:IsInBattleState()
    return self.battleState
end

function CityElement:GetWorldPosition()
    return self.mgr.city:GetWorldPositionFromCoord(self.x, self.y)
end

function CityElement:ForceShowLifeBar()
    return false
end

function CityElement:RegisterInteractPoints()

end

function CityElement:UnRegisterInteractPoints()
    
end

return CityElement
