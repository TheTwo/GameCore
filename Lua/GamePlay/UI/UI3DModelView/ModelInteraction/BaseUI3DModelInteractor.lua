local UITroopConst = require("UITroopConst")
---@class BaseUI3DModelInteractor
local BaseUI3DModelInteractor = class("BaseUI3DModelInteractor")

function BaseUI3DModelInteractor:ctor()
    self.canInteract = nil
end

function BaseUI3DModelInteractor:Release()
    self.canInteract = nil
end

function BaseUI3DModelInteractor:OnEnable()
    self.canInteract = true
end

function BaseUI3DModelInteractor:OnDisable()
    self.canInteract = false
end

function BaseUI3DModelInteractor:CanInteract()
    return self.canInteract
end

function BaseUI3DModelInteractor:CanClick()
    return false
end

---可作为拖拽对象（作为拖拽起点）
function BaseUI3DModelInteractor:CanDrag()
    return false
end

---可以响应拖拽（作为拖拽路径点）
function BaseUI3DModelInteractor:ReactToDrag()
    return false
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function BaseUI3DModelInteractor:DoOnPress(eventData)
    g_Logger.ErrorChannel("BaseUI3DModelInteractor", "DoOnPress not implemented")
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function BaseUI3DModelInteractor:DoOnClick(eventData)
    g_Logger.ErrorChannel("BaseUI3DModelInteractor", "DoOnClick not implemented")
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function BaseUI3DModelInteractor:DoOnDragStart(eventData)
    g_Logger.ErrorChannel("BaseUI3DModelInteractor", "DoOnDragStart not implemented")
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function BaseUI3DModelInteractor:DoOnDrag(eventData)
    g_Logger.ErrorChannel("BaseUI3DModelInteractor", "DoOnDrag not implemented")
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function BaseUI3DModelInteractor:DoOnDragEnd(eventData)
    g_Logger.ErrorChannel("BaseUI3DModelInteractor", "DoOnDragEnd not implemented")
end

function BaseUI3DModelInteractor:DoOnMoveIn()
end

function BaseUI3DModelInteractor:DoOnMoveOut()
end

return BaseUI3DModelInteractor
