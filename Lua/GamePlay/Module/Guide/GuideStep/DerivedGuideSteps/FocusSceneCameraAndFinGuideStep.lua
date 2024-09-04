local BaseGuideStep = require('BaseGuideStep')
local GuideUtils = require('GuideUtils')
local UIMediatorNames = require('UIMediatorNames')
---@class FocusSceneCameraAndFinGuideStep : BaseGuideStep
local FocusSceneCameraAndFinGuideStep = class('FocusSceneCameraAndFinGuideStep', BaseGuideStep)

function FocusSceneCameraAndFinGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_FocusSceneCameraAndFin: %d)', self.id)
    GuideUtils.FocusSceneCamera(self, function()
        g_Logger.LogChannel('GuideModule','FocusSceneCameraAndFin CallBack: %d)', self.id)
        g_Game.UIManager:CloseAllByName(UIMediatorNames.UIGuideFingerMediator)
        self:ShowGuideFinger()
    end)
end

return FocusSceneCameraAndFinGuideStep