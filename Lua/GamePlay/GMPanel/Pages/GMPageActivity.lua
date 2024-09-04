local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local ModuleRefer = require("ModuleRefer")

local GMPageActivity = class('GMPageActivity', GMPage)

function GMPageActivity:ctor()
end

function GMPageActivity:OnGUI()
    GUILayout.BeginHorizontal()
    local gmOpenAllActivity = GUILayout.Toggle(ModuleRefer.ActivityCenterModule:GMOpenAllActivity(), "本地开启所有活动")
    GUILayout.EndHorizontal()

    if ModuleRefer.ActivityCenterModule:GMOpenAllActivity() ~= gmOpenAllActivity then
        ModuleRefer.ActivityCenterModule:GMOpenAllActivity(gmOpenAllActivity)
    end
end

return GMPageActivity