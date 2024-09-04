local CityTileAssetNpc = require("CityTileAssetNpc")
---@class CityTileAssetNpcSLG:CityTileAssetNpc
---@field new fun():CityTileAssetNpcSLG
local CityTileAssetNpcSLG = class("CityTileAssetNpcSLG", CityTileAssetNpc)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local Utils = require("Utils")
local TimerUtility = require("TimerUtility")
local ModuleRefer = require("ModuleRefer")

function CityTileAssetNpcSLG:SkipForSLGAsset()
    return not CityTileAssetNpc.SkipForSLGAsset(self)
end

function CityTileAssetNpcSLG:OnTileViewInit()
    CityTileAssetNpc.OnTileViewInit(self)
    g_Game.EventManager:AddListener(EventConst.CITY_SLG_ASSET_ATTACK_TARGET, Delegate.GetOrCreate(self, self.OnAttackTarget))
    g_Game.EventManager:AddListener(EventConst.CITY_SLG_PLAY_SKILL, Delegate.GetOrCreate(self, self.OnPlaySkill))
end

function CityTileAssetNpcSLG:OnTileViewRelease()
    CityTileAssetNpc.OnTileViewRelease(self)
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_ASSET_ATTACK_TARGET, Delegate.GetOrCreate(self, self.OnAttackTarget))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_PLAY_SKILL, Delegate.GetOrCreate(self, self.OnPlaySkill))
end

function CityTileAssetNpcSLG:OnAssetLoaded(go, userdata)
    CityTileAssetNpc.OnAssetLoaded(self, go, userdata)
    self.controller = go:GetComponent(typeof(CS.CitySLGBattleUnitController))

    local id = self.tileView.tile:GetCell().tileId
    local element = self:GetCity().elementManager:GetElementById(id)
    if element and element:IsInBattleState() then
        self:EnterFocusAt(element.targetTrans)
    else
        self:ResetToIdle()
    end
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityTileAssetNpcSLG:OnAssetUnload()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
    CityTileAssetNpc.OnAssetUnload(self)
    self:ResetToIdle()
    self.controller = nil
    self.targetTrans = nil
end

function CityTileAssetNpcSLG:OnTick()
    if Utils.IsNull(self.controller) then return end
    local cell = self.tileView.tile:GetCell()
    if cell == nil then return end
    
    if Utils.IsNull(self.targetTrans) then
        local troop = ModuleRefer.SlgModule.troopManager:FindElementCtrlByConfigId(cell.configId)
        if not troop then return end
        self.controller:SetForward(troop._direction)
    else
        self.controller:LookAt(self.targetTrans.position)
    end
end

function CityTileAssetNpcSLG:OnAttackTarget(typ, id)
    if typ ~= wds.CityBattleObjType.CityBattleObjTypeElement then return end

    local cell = self.tileView.tile:GetCell()
    if cell == nil or cell.configId ~= id then return end
    local element = self:GetCity().elementManager:GetElementById(id)
    if element:IsInBattleState() then
        self:EnterFocusAt(element.targetTrans)
    else
        self:ResetToIdle()
    end
end


---@param transform CS.UnityEngine.Transform
function CityTileAssetNpcSLG:EnterFocusAt(transform)
    self.targetTrans = transform
    if Utils.IsNull(transform) then
        self:ResetToIdle()
        return
    end
    
    if Utils.IsNull(self.controller) then return end
    self.controller:LookAt(transform.position)
end

function CityTileAssetNpcSLG:ResetToIdle()
    if Utils.IsNull(self.controller) then return end
    self.controller:Reset()
end

---@param targetPos CS.UnityEngine.Vector3
---@param animName string
---@param animDuration number
function CityTileAssetNpcSLG:OnPlaySkill(typ, id, targetPos, animName, animDuration)
    if typ ~= wds.CityBattleObjType.CityBattleObjTypeElement then return end

    local cell = self.tileView.tile:GetCell()
    if cell == nil or cell.configId ~= id then return end

    self:PlaySkillImp(targetPos, animName, animDuration)
end

function CityTileAssetNpcSLG:PlaySkillImp(targetPos, animName, animDuration)
    if Utils.IsNull(self.controller) then return end

    self.controller:LookAt(targetPos)
    self.controller:PlayAnimState(animName)
end

return CityTileAssetNpcSLG