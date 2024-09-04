local BaseUI3DModelInteractor = require("BaseUI3DModelInteractor")
local Utils = require("Utils")
local UIHelper = require("UIHelper")
local UITroopConst = require("UITroopConst")
local EventConst = require("EventConst")
---@class UI3DTroopModelInteractor : BaseUI3DModelInteractor
local UI3DTroopModelInteractor = class("UI3DTroopModelInteractor", BaseUI3DModelInteractor)

local Vector3 = CS.UnityEngine.Vector3

function UI3DTroopModelInteractor:ctor()
    ---@type CS.UnityEngine.Transform
    self.model = nil
    self.originPos = nil
end

function UI3DTroopModelInteractor:GetSlotType()
    return UITroopConst.TroopSlotType[self.type]
end

---@param model CS.UnityEngine.Transform
function UI3DTroopModelInteractor:BindModel(model)
    self.model = model
end

function UI3DTroopModelInteractor:UnbindModel()
    self.model = nil
end

function UI3DTroopModelInteractor:CanDrag()
    return true
end

function UI3DTroopModelInteractor:CanClick()
    return true
end

---@param delta CS.UnityEngine.Vector3
function UI3DTroopModelInteractor:UpdateModelPosition(delta)
    if self.model then
        self.model.position = self.model.position + delta
    end
end

function UI3DTroopModelInteractor:DoOnClick(eventData)
    g_Game.EventManager:TriggerEvent(EventConst.ON_TROOP_MODEL_CLICK, self.slotIndex, self:GetSlotType())
end

function UI3DTroopModelInteractor:DoOnDragStart(eventData)
    if self.model then
        self.originPos = Utils.DeepCopy(self.model.position)
        self.lastPos = UIHelper.ScreenPos2UIPos(eventData.position)

        g_Game.EventManager:TriggerEvent(EventConst.ON_TROOP_MODEL_DRAG_START, self.slotIndex, self:GetSlotType(), self.model)
    end
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function UI3DTroopModelInteractor:DoOnDrag(eventData)
    if self.originPos then
        local uiPos = UIHelper.ScreenPos2UIPos(eventData.position)
        local delta = uiPos - self.lastPos
        self.lastPos = uiPos
        ---@type CS.UnityEngine.Camera
        local ui3dCam = g_Game.UIManager.ui3DViewManager:UICam3D()
        local Mathf = CS.UnityEngine.Mathf
        local cameraRotationY = (-ui3dCam.transform.localEulerAngles.y) * Mathf.Deg2Rad
        local sin = Mathf.Sin(cameraRotationY)
        local cos = Mathf.Cos(cameraRotationY)
        local deltaX = delta.x * cos - delta.y * sin
        local deltaY = delta.y * cos + delta.x * sin

        local sensitivity = 0.009
        if self.type == "Pet" then
            sensitivity = 0.007
        end
        local transDelta = Vector3(deltaX * sensitivity, 0, deltaY * sensitivity)
        self:UpdateModelPosition(transDelta)
    end
end

function UI3DTroopModelInteractor:DoOnDragEnd()
    if self.model and self.originPos then
        self.model.position = self.originPos
    end
end

return UI3DTroopModelInteractor