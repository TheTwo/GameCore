local UI3DTroopModelInteractor = require("UI3DTroopModelInteractor")
local UIHelper = require("UIHelper")
local Utils = require("Utils")
---@class UI3DTroopUIInteractor : UI3DTroopModelInteractor
local UI3DTroopUIInteractor = class("UI3DTroopUIInteractor", UI3DTroopModelInteractor)

local Vector3 = CS.UnityEngine.Vector3

function UI3DTroopUIInteractor:CanClick()
    return false
end

function UI3DTroopUIInteractor:DoOnClick(eventData)

end

function UI3DTroopUIInteractor:DoOnDragStart(eventData)
    if self.model then
        self.originPos = Utils.DeepCopy(self.model.position)
        self.lastPos = UIHelper.ScreenPos2UIPos(eventData.position)
    end
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function UI3DTroopUIInteractor:DoOnDrag(eventData)
    if self.originPos then
        local uiPos = UIHelper.ScreenPos2UIPos(eventData.position)
        local delta = uiPos - self.lastPos
        self.lastPos = uiPos
        delta = Vector3(delta.x * 0.009, delta.y * 0.009, 0)
        self:UpdateModelPosition(delta)
    end
end

function UI3DTroopUIInteractor:UpdateModelPosition(delta)
    if self.model then
        self.model.position = self.model.position + delta
    end
end

return UI3DTroopUIInteractor