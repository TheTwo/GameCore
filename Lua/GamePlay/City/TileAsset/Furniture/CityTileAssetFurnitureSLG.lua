local CityTileAssetFurniture = require("CityTileAssetFurniture")
---@class CityTileAssetFurnitureSLG:CityTileAssetFurniture
---@field new fun():CityTileAssetFurnitureSLG
local CityTileAssetFurnitureSLG = class("CityTileAssetFurnitureSLG", CityTileAssetFurniture)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local Utils = require("Utils")
local TimerUtility = require("TimerUtility")
local ModuleRefer = require("ModuleRefer")

function CityTileAssetFurnitureSLG:SkipForSLGAsset()
    return not CityTileAssetFurniture.SkipForSLGAsset(self)
end

function CityTileAssetFurnitureSLG:OnTileViewInit()
    CityTileAssetFurniture.OnTileViewInit(self)
    g_Game.EventManager:AddListener(EventConst.CITY_SLG_ASSET_ATTACK_TARGET, Delegate.GetOrCreate(self, self.OnAttackTarget))
    g_Game.EventManager:AddListener(EventConst.CITY_SLG_PLAY_SKILL, Delegate.GetOrCreate(self, self.OnPlaySkill))
end

function CityTileAssetFurnitureSLG:OnTileViewRelease()
    CityTileAssetFurniture.OnTileViewRelease(self)
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_ASSET_ATTACK_TARGET, Delegate.GetOrCreate(self, self.OnAttackTarget))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_PLAY_SKILL, Delegate.GetOrCreate(self, self.OnPlaySkill))
end

function CityTileAssetFurnitureSLG:OnAssetLoaded(go, userdata)
    CityTileAssetFurniture.OnAssetLoaded(self, go, userdata)
    self.controller = go:GetComponent(typeof(CS.CitySLGBattleUnitController))

    local id = self.tileView.tile:GetCell().tileId
    local building = self:GetCity().furnitureManager:GetFurnitureById(id)
    if building and building:IsInBattleState() then
        self:EnterFocusAt(building.targetTrans)
    else
        self:ResetToIdle()
    end
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityTileAssetFurnitureSLG:OnAssetUnload()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
    CityTileAssetFurniture.OnAssetUnload(self)
    self:ResetToIdle()
    self.controller = nil
    self.targetTrans = nil
end

function CityTileAssetFurnitureSLG:OnTick()
    if Utils.IsNull(self.controller) then return end
    local cell = self.tileView.tile:GetCell()
    if cell == nil then return end
    
    if Utils.IsNull(self.targetTrans) then
        -- local troop = ModuleRefer.SlgModule.troopManager:FindFurnitureCtrlByFunitureId(cell.singleId)
        -- if not troop then return end
        -- self.controller:SetForward(troop._direction)
    else
        self.controller:LookAt(self.targetTrans.position)
    end
end

function CityTileAssetFurnitureSLG:OnAttackTarget(typ, id)
    if typ ~= wds.CityBattleObjType.CityBattleObjTypeFurniture then return end

    local cell = self.tileView.tile:GetCell()
    if cell == nil or cell.singleId ~= id then return end

    local furniture = self:GetCity().furnitureManager:GetFurnitureById(id)
    if furniture:IsInBattleState() then
        self:EnterFocusAt(furniture.targetTrans)
    else
        self:ResetToIdle()
    end
end

---@param transform CS.UnityEngine.Transform
function CityTileAssetFurnitureSLG:EnterFocusAt(transform)
    self.targetTrans = transform    
    if Utils.IsNull(transform) then
        -- self:ResetToIdle()
        return
    end
    
    if Utils.IsNull(self.controller) then return end
    self.controller:LookAt(transform.position)
end

function CityTileAssetFurnitureSLG:ResetToIdle()
    if not self.controller then return end
    self.controller:Reset()
end

---@param targetPos CS.UnityEngine.Vector3
---@param animName string
---@param animDuration number
function CityTileAssetFurnitureSLG:OnPlaySkill(typ, id, targetPos, animName, animDuration)
    if typ ~= wds.CityBattleObjType.CityBattleObjTypeFurniture then return end

    local cell = self.tileView.tile:GetCell()
    if cell == nil or cell.singleId ~= id then return end

    self:PlaySkillImp(targetPos, animName, animDuration)
end

function CityTileAssetFurnitureSLG:PlaySkillImp(targetPos, animName, animDuration)
    if not self.controller then return end

    self.controller:LookAt(targetPos)
    self.controller:PlayAnimState(animName)
end

return CityTileAssetFurnitureSLG