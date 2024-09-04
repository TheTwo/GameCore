local CityTileAssetBuilding = require("CityTileAssetBuilding")
---@class CityTileAssetBuildingSLG:CityTileAssetBuilding
---@field new fun():CityTileAssetBuildingSLG
local CityTileAssetBuildingSLG = class("CityTileAssetBuildingSLG", CityTileAssetBuilding)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")

function CityTileAssetBuildingSLG:SkipForSLGAsset()
    return not CityTileAssetBuilding.SkipForSLGAsset(self)
end

function CityTileAssetBuildingSLG:OnTileViewInit()
    CityTileAssetBuilding.OnTileViewInit(self)
    g_Game.EventManager:AddListener(EventConst.CITY_SLG_ASSET_ATTACK_TARGET, Delegate.GetOrCreate(self, self.OnAttackTarget))
    g_Game.EventManager:AddListener(EventConst.CITY_SLG_PLAY_SKILL, Delegate.GetOrCreate(self, self.OnPlaySkill))
end

function CityTileAssetBuildingSLG:OnTileViewRelease()
    CityTileAssetBuilding.OnTileViewRelease(self)
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_ASSET_ATTACK_TARGET, Delegate.GetOrCreate(self, self.OnAttackTarget))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_PLAY_SKILL, Delegate.GetOrCreate(self, self.OnPlaySkill))
end

function CityTileAssetBuildingSLG:OnAssetLoaded(go, userdata)
    CityTileAssetBuilding.OnAssetLoaded(self, go, userdata)
    self.controller = go:GetComponent(typeof(CS.CitySLGBattleUnitController))

    local id = self.tileView.tile:GetCell().tileId
    local building = self:GetCity().buildingManager:GetBuilding(id)
    if building:IsInBattleState() then
        self:EnterFocusAt(building.targetTrans)
    else
        self:ResetToIdle()
    end
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityTileAssetBuildingSLG:OnAssetUnload()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
    CityTileAssetBuilding.OnAssetUnload(self)
    self:ResetToIdle()
    self.controller = nil
    self.targetTrans = nil
end

function CityTileAssetBuildingSLG:OnTick()
    if Utils.IsNull(self.controller) then return end
    local cell = self.tileView.tile:GetCell()
    if cell == nil then return end
    
    if Utils.IsNull(self.targetTrans) then
        local troop = ModuleRefer.SlgModule.troopManager:FindBuldingCtrlByViewId(cell.tileId)
        if not troop then return end
        self.controller:SetForward(troop._direction)
    else
        self.controller:LookAt(self.targetTrans.position)
    end
end

function CityTileAssetBuildingSLG:OnAttackTarget(typ, id)
    if typ ~= wds.CityBattleObjType.CityBattleObjTypeBuilding then return end

    local cell = self.tileView.tile:GetCell()
    if cell == nil or cell.tileId ~= id then return end

    local building = self:GetCity().buildingManager:GetBuilding(id)
    if building:IsInBattleState() then
        self:EnterFocusAt(building.targetTrans)
    else
        self:ResetToIdle()
    end
end

---@param transform CS.UnityEngine.Transform
function CityTileAssetBuildingSLG:EnterFocusAt(transform)
    self.targetTrans = transform
    if Utils.IsNull(transform) then
        self:ResetToIdle()
        return
    end
    
    if Utils.IsNull(self.controller) then return end
    self.controller:LookAt(transform.point)
end

function CityTileAssetBuildingSLG:ResetToIdle()
    if not self.controller then return end
    self.controller:Reset()
end

---@param targetPos CS.UnityEngine.Vector3
---@param animName string
---@param animDuration number
function CityTileAssetBuildingSLG:OnPlaySkill(typ, id, targetPos, animName, animDuration)
    if typ ~= wds.CityBattleObjType.CityBattleObjTypeBuilding then return end

    local cell = self.tileView.tile:GetCell()
    if cell == nil or cell.tileId ~= id then return end

    self:PlaySkillImp(targetPos, animName, animDuration)
end

function CityTileAssetBuildingSLG:PlaySkillImp(targetPos, animName, animDuration)
    if not self.controller then return end

    self.controller:LookAt(targetPos)
    self.controller:PlayAnimState(animName)
end

return CityTileAssetBuildingSLG