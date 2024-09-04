local BaseGuideStep = require("BaseGuideStep")
---@class CloseAllWindowGuideStep : BaseGuideStep
local CloseAllWindowGuideStep = class("CloseAllWindowGuideStep", BaseGuideStep)

function CloseAllWindowGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_CloseAllWindow: %d)', self.id)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Tip)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.SceneUI)
    g_Logger.LogChannel('GuideModule','ExeGuideStep_CloseAllWindow Finished')
    self:End()
end

return CloseAllWindowGuideStep