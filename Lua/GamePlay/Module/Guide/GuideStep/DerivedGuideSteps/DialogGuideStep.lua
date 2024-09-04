local BaseGuideStep = require('BaseGuideStep')
local ModuleRefer = require('ModuleRefer')
---@class DialogGuideStep : BaseGuideStep
local DialogGuideStep = class('DialogGuideStep', BaseGuideStep)

function DialogGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_Dialog: %d)', self.id)
    g_Game.UIManager:CloseAllExceptByType({
        g_Game.UIManager.CSUIMediatorType.Hud,
        g_Game.UIManager.CSUIMediatorType.SystemMsg,
    })
    ModuleRefer.StoryModule:StoryStart(self.cfg:Dialog(), function ()
        self:End()
    end)
end

return DialogGuideStep