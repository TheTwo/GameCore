local GUILayout = require("GUILayout")

---@class GMHeader
local GMHeader = class('GMHeader')

function GMHeader:ctor()
    self._useCopyBtn = false
    self._display = false
end

---@param panel GMPanel
function GMHeader:Init(panel)
    self.panel = panel
end

function GMHeader:OnGUI()
    if self._display then
        local s = self:DoText()
        if not string.IsNullOrEmpty(s) then
            if self._useCopyBtn then
                if GUILayout.Button(s, GUILayout.GetButtonLeftSkin(), GUILayout.cs.Height(23)) then
                    CS.UnityEngine.GUIUtility.systemCopyBuffer = s
                end
            else
                GUILayout.BoxLeftAlignment(s, GUILayout.shrinkHeight, GUILayout.shrinkWidth)
            end
        end
    end
end

function GMHeader:DoText()
    return nil
end

function GMHeader:Tick()
    
end

function GMHeader:Release()
    self.panel = nil
end

return GMHeader