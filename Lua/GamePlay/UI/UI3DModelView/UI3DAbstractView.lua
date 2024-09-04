local Utils = require("Utils")
---@class UI3DAbstractView
local UI3DAbstractView = class('UI3DAbstractView')


---@param root UI3DRoot
---@param callback fun(go:CS.UnityEngine.GameObject)
function UI3DAbstractView.CreateViewer(root,callback)
end

function UI3DAbstractView:GetType()
    return 0
end

function UI3DAbstractView:Clear()
end

---@param visible boolean
function UI3DAbstractView:SetVisible(visible)
    if Utils.IsNull(self.behaviour) or  Utils.IsNull(self.behaviour.gameObject) then return end
    if self.behaviour.gameObject.activeSelf ~= visible then
        self.behaviour.gameObject:SetActive(visible)
    end
end

---@param root UI3DRoot
function UI3DAbstractView:Init(root)
end

function UI3DAbstractView:FeedData(data)
end

return UI3DAbstractView