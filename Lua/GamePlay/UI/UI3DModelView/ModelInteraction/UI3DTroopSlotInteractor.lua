local BaseUI3DModelInteractor = require("BaseUI3DModelInteractor")
local UITroopConst = require("UITroopConst")
local EventConst = require("EventConst")
---@class UI3DTroopSlotInteractor : BaseUI3DModelInteractor
local UI3DTroopSlotInteractor = class("UI3DTroopSlotInteractor", BaseUI3DModelInteractor)

function UI3DTroopSlotInteractor:GetSlotType()
    return UITroopConst.TroopSlotType[self.type]
end

function UI3DTroopSlotInteractor:CanClick()
    return true
end

function UI3DTroopSlotInteractor:CanDrag()
    return false
end

function UI3DTroopSlotInteractor:ReactToDrag()
    return true
end

function UI3DTroopSlotInteractor:DoOnDrag()
    -- todo: playVfx
end

function UI3DTroopSlotInteractor:DoOnDragEnd()
    g_Game.EventManager:TriggerEvent(EventConst.ON_TROOP_MODEL_DRAG_END, self.slotIndex, self:GetSlotType())
end

function UI3DTroopSlotInteractor:DoOnMoveIn()
    g_Game.EventManager:TriggerEvent(EventConst.ON_TROOP_SLOT_DRAG_MOVE_IN, self.slotIndex, self:GetSlotType())
end

function UI3DTroopSlotInteractor:DoOnMoveOut()
    g_Game.EventManager:TriggerEvent(EventConst.ON_TROOP_SLOT_DRAG_MOVE_OUT, self.slotIndex, self:GetSlotType())
end

function UI3DTroopSlotInteractor:DoOnClick()
    g_Game.EventManager:TriggerEvent(EventConst.ON_TROOP_SLOT_CLICK, self.slotIndex, self:GetSlotType())
end

return UI3DTroopSlotInteractor