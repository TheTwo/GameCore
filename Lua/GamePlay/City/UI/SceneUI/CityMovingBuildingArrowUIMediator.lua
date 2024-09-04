---Scene Name : scene_city_bubble_remove
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
---@type CS.DG.Tweening.Ease
local Ease = CS.DG.Tweening.Ease
local CityConst = require("CityConst")

---@class CityMovingBuildingArrowUIMediator:BaseUIMediator
local CityMovingBuildingArrowUIMediator = class('CityMovingBuildingArrowUIMediator', BaseUIMediator)

---@class CityMovingBuildingArrowUIParameter
---@field worldPos CS.UnityEngine.Vector3
---@field camera BasicCamera
---@field duration number

function CityMovingBuildingArrowUIMediator:OnCreate()
    self._p_arrow = self:Transform("p_arrow")
    self._p_progress = self:Image("p_progress")
end

---@param param CityMovingBuildingArrowUIParameter
function CityMovingBuildingArrowUIMediator:OnOpened(param)
    self.worldPos = param.worldPos
    self.camera = param.camera
    self.duration = param.duration
    self._p_progress.fillAmount = 0

    self:UpdateScreenPosition()
    self.tweener = self._p_progress:DOFillAmount(1, self.duration):OnComplete(function()
        self:FadeOutClose()
    end):SetEase(Ease.InOutQuad)
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.UpdateScreenPosition))
end

function CityMovingBuildingArrowUIMediator:OnClose(param)
    self.tweener:Kill()
    if self.scaleTween then
        self.scaleTween:Kill()
    end
    self.tweener = nil
    self.scaleTween = nil
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.UpdateScreenPosition))
end

function CityMovingBuildingArrowUIMediator:UpdateScreenPosition()
    local unityCamera = self.camera:GetUnityCamera()
    local screenPos = unityCamera:WorldToScreenPoint(self.worldPos)
    screenPos.z = 0
    screenPos.y = screenPos.y + 150
    local worldPos = g_Game.UIManager:GetUICamera():ScreenToWorldPoint(screenPos)
    self._p_arrow.position = worldPos
end

function CityMovingBuildingArrowUIMediator:FadeOutClose()
    local curScale = self._p_arrow.localScale
    self.scaleTween = self._p_arrow:DOScale(curScale * 1.15, CityConst.CITY_FADE_OUT_DURATION):OnComplete(function()
        self._p_arrow.localScale = curScale
        self:CloseSelf()
    end):SetEase(Ease.OutElastic)
end

return CityMovingBuildingArrowUIMediator