local ManualResourceConst = require("ManualResourceConst")
local Utils = require("Utils")
local Delegate = require("Delegate")

local CityTileAssetBubble = require("CityTileAssetBubble")

---@class CityTileAssetSafeAreaWallSLGUnitLifeBarTemp:CityTileAssetBubble
---@field new fun():CityTileAssetSafeAreaWallSLGUnitLifeBarTemp
---@field super CityTileAssetBubble
local CityTileAssetSafeAreaWallSLGUnitLifeBarTemp = class('CityTileAssetSafeAreaWallSLGUnitLifeBarTemp', CityTileAssetBubble)

function CityTileAssetSafeAreaWallSLGUnitLifeBarTemp:ctor()
    CityTileAssetBubble.ctor(self)
    self.isUI = true
end

function CityTileAssetSafeAreaWallSLGUnitLifeBarTemp:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    ---@type CitySafeAreaWallDoor
    local cell = self.tileView.tile:GetCell()
    self._ctrl = self.tileView.tile:GetCity().safeAreaWallMgr:GetBattleViewWall(cell:UniqueId())
    if self._ctrl then
        self._ctrl:RegChangeNotify(Delegate.GetOrCreate(self, self.Refresh))
    end
end

function CityTileAssetSafeAreaWallSLGUnitLifeBarTemp:OnTileViewRelease()
    CityTileAssetBubble.OnTileViewRelease(self)
    if self._ctrl then
        self._ctrl:ClearChangeNotify()
    end
    self._ctrl = nil
end

function CityTileAssetSafeAreaWallSLGUnitLifeBarTemp:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if not self:ShouldShow() then
        return string.Empty
    end

    return ManualResourceConst.ui3d_progress_building
end

function CityTileAssetSafeAreaWallSLGUnitLifeBarTemp:ShouldShow()
    if not self._ctrl or not self._ctrl.battleState then
        return false
    end
    return self._ctrl.battleState and self._ctrl.hp and self._ctrl.hpMax or false
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetSafeAreaWallSLGUnitLifeBarTemp:OnAssetLoaded(go, userdata)
    CityTileAssetBubble.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then return end

    local rootTransform = go.transform
    local rotationTrans = rootTransform:Find("p_rotation")
    local positionTrans = rotationTrans:Find("p_progress")
    local facingCamera = rotationTrans:GetComponent(typeof(CS.U2DFacingCamera))
    local frameTrans = positionTrans:Find("Frame")
    local lifeBarTrans = frameTrans:Find("p_bar_full")
    local lifeBarSpriteMesh = lifeBarTrans:GetComponent(typeof(CS.U2DSpriteMesh))

    local city = self:GetCity()
    facingCamera.FacingCamera = city:GetCamera().mainCamera
    rotationTrans.localScale = CS.UnityEngine.Vector3.one
    positionTrans.position = self.tileView:GetAssetAttachTrans(self.isUI).position + CS.UnityEngine.Vector3.up * city.scale * 5
    frameTrans.localPosition = CS.UnityEngine.Vector3(-(lifeBarSpriteMesh.width * lifeBarSpriteMesh.pixelSize), 0, 0)
    self.lifeBarSlider = lifeBarTrans:GetComponent(typeof(CS.U2DSlider))
    self:UpdateLifeBar()
end

function CityTileAssetSafeAreaWallSLGUnitLifeBarTemp:OnAssetUnload()
    self.lifeBarSlider = nil
    CityTileAssetBubble.OnAssetUnload(self)
end

function CityTileAssetSafeAreaWallSLGUnitLifeBarTemp:UpdateLifeBar()
    if not self._ctrl or not self._ctrl.hp then
        return
    end
    self.lifeBarSlider.progress = self:GetProgress(self._ctrl.hp, self._ctrl.hpMax)
end

function CityTileAssetSafeAreaWallSLGUnitLifeBarTemp:GetProgress(cur, max)
    if max <= 0 then return 0 end
    return math.clamp01(cur / max)
end

function CityTileAssetSafeAreaWallSLGUnitLifeBarTemp:Refresh()
    local shouldShow = self:ShouldShow()
    if shouldShow and not self.handle then
        self:Hide()
        self:Show()
    elseif not shouldShow and self.handle then
        self:Hide()
    elseif Utils.IsNotNull(self.lifeBarSlider) then
        self:UpdateLifeBar()
    end
end

return CityTileAssetSafeAreaWallSLGUnitLifeBarTemp