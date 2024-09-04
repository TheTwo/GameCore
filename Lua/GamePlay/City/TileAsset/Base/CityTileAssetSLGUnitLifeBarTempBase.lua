local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetSLGUnitLifeBarTempBase:CityTileAssetBubble
---@field new fun():CityTileAssetSLGUnitLifeBarTempBase
local CityTileAssetSLGUnitLifeBarTempBase = class("CityTileAssetSLGUnitLifeBarTempBase", CityTileAssetBubble)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local Utils = require("Utils")
local ManualResourceConst = require("ManualResourceConst")

function CityTileAssetSLGUnitLifeBarTempBase:ctor()
    CityTileAssetBubble.ctor(self)
    self.isUI = true
end

function CityTileAssetSLGUnitLifeBarTempBase:GetPrefabName()
    if not self:ShouldShow() then
        return string.Empty
    end
    return ManualResourceConst.ui3d_progress_building
end

function CityTileAssetSLGUnitLifeBarTempBase:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    g_Game.EventManager:AddListener(EventConst.CITY_SLG_ASSET_UPDATE, Delegate.GetOrCreate(self, self.OnSlgAssetUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_SLG_HP_UPDATE, Delegate.GetOrCreate(self, self.OnHpUpdate))
end

function CityTileAssetSLGUnitLifeBarTempBase:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_ASSET_UPDATE, Delegate.GetOrCreate(self, self.OnSlgAssetUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_HP_UPDATE, Delegate.GetOrCreate(self, self.OnHpUpdate))
    CityTileAssetBubble.OnTileViewRelease(self)
end

function CityTileAssetSLGUnitLifeBarTempBase:ShouldShow()
    if not CityTileAssetBubble.CheckCanShow(self) then
        return false
    end
    local body = self:GetBody()
    if body == nil then
        return false
    end
    if body:IsInBattleState() then
        return true
    end
    if body:ForceShowLifeBar() then
        return true
    end
    local troop = self:GetBuildingTroopCtrl()
    if troop == nil then
        return false
    end
    return troop._data.Battle.Durability < troop._data.Battle.MaxDurability 
end

function CityTileAssetSLGUnitLifeBarTempBase:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end

    local rootTransform = go.transform
    local rotationTrans = rootTransform:Find("p_rotation")
    local positionTrans = rotationTrans:Find("p_progress")
    local facingCamera = rotationTrans:GetComponent(typeof(CS.U2DFacingCamera))
    local frameTrans = positionTrans:Find("Frame")
    local lifeBarTrans = frameTrans:Find("p_bar_full")

    local city = self:GetCity()
    facingCamera.FacingCamera = city:GetCamera().mainCamera
    rotationTrans.localScale = CS.UnityEngine.Vector3.one
    if not self:TrySetPosToMainAssetAnchor(rootTransform) then
        self:SetPosToTileWorldCenter(go)
    end
    self.lifeBarSlider = lifeBarTrans:GetComponent(typeof(CS.U2DSlider))
    self:UpdateLifeBar()
end

function CityTileAssetSLGUnitLifeBarTempBase:OnAssetUnload()
    self.lifeBarSlider = nil
end

function CityTileAssetSLGUnitLifeBarTempBase:UpdateLifeBar(elementId)
    local troop = self:GetBuildingTroopCtrl()
    if not troop then return end

    local fight = troop._data.Battle
    local cur, max = fight.Durability, fight.MaxDurability
    self.lifeBarSlider.progress = self:GetProgress(cur, max)
end

function CityTileAssetSLGUnitLifeBarTempBase:GetProgress(cur, max)
    if max <= 0 then return 0 end

    return math.clamp01(cur / max)
end

function CityTileAssetSLGUnitLifeBarTempBase:OnSlgAssetUpdate(typ, uniqueId)
    if typ ~= self:SlgUnitType() then return end
    
    local id = self:BodyUniqueId()
    if id ~= uniqueId then return end

    self:ForceRefresh()
end

function CityTileAssetSLGUnitLifeBarTempBase:OnHpUpdate(typ, uniqueId)
    if typ ~= self:SlgUnitType() then return end

    local id = self:BodyUniqueId()
    if id ~= uniqueId then return end
    
    if Utils.IsNull(self.lifeBarSlider) then
        self:ForceRefresh()
        return
    end
    self:UpdateLifeBar()
end

function CityTileAssetSLGUnitLifeBarTempBase:Refresh()
    if Utils.IsNotNull(self.lifeBarSlider) then
        self:UpdateLifeBar()
    end
end

---@return CityElement|CityBuilding|CityFurniture
function CityTileAssetSLGUnitLifeBarTempBase:GetBody()
    ---override this
    return nil
end

function CityTileAssetSLGUnitLifeBarTempBase:GetBuildingTroopCtrl()
    ---override this
    return nil
end

function CityTileAssetSLGUnitLifeBarTempBase:SlgUnitType()
    ---override this
    return nil
end

function CityTileAssetSLGUnitLifeBarTempBase:BodyUniqueId()
    ---override this
    return nil
end

return CityTileAssetSLGUnitLifeBarTempBase