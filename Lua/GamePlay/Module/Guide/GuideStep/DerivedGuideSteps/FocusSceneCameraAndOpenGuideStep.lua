local BaseGuideStep = require('BaseGuideStep')
local GuideUtils = require('GuideUtils')
local UIMediatorNames = require('UIMediatorNames')
local GuideZoneType = require('GuideZoneType')
local ModuleRefer = require('ModuleRefer')
---@class FocusSceneCameraAndOpenGuideStep : BaseGuideStep
local FocusSceneCameraAndOpenGuideStep = class('FocusSceneCameraAndOpenGuideStep', BaseGuideStep)

function FocusSceneCameraAndOpenGuideStep:ExecuteImpl()
    if self.cfg:Zone() and self.cfg:Zone():Type() == GuideZoneType.KingdomMistCell then
        ModuleRefer.MapFogModule:GotoCastleNearestMist()
        self:End()
        return
    end
    g_Logger.LogChannel('GuideModule','ExeGuideStep_FocusSceneCameraAndOpen: %d)', self.id)
    if self.guideCallCfg
        and self.guideCallCfg:CityExplorMode()
        and GuideUtils.IsInMyCityExplorMode()
        and GuideUtils.NeedFocus(self.target, self.dragTarget)
    then
        local focusPosWs,focusTarget = GuideUtils.GetTargetFocusPosWS(self.target, self.dstTarget)
        ---@type KingdomScene
        local kingdomScene = g_Game.SceneManager.current
        if focusPosWs and focusTarget then
            --探索模式 视野内引导点击 视野外自动点击
            if CS.Grid.CameraUtils.IsPointInCameraFrustumPlanes(kingdomScene.basicCamera:GetUnityCamera(), focusPosWs) then
                self:ShowGuideFinger()
            else
                local uiPos = GuideUtils.GetTargetUIPos(focusTarget)
                GuideUtils.SimulatClickTarget(focusTarget.type,nil,uiPos, focusTarget.offset)
                self:End()
            end
            return
        end
    end
    GuideUtils.FocusSceneCamera(self, function()
        g_Logger.LogChannel('GuideModule','FocusSceneCameraAndOpen CallBack: %d)', self.id)
        g_Game.UIManager:CloseAllByName(UIMediatorNames.UIGuideFingerMediator)
        self:ShowGuideFinger()
    end)
end

function FocusSceneCameraAndOpenGuideStep:NeedTarget()
    if not BaseGuideStep.NeedTarget(self) then
        return false
    end
    return self.cfg:Zone():Type() ~= GuideZoneType.KingdomMistCell
end

return FocusSceneCameraAndOpenGuideStep