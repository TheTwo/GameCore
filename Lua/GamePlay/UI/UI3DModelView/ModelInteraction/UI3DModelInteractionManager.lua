local physics = physics
local Delegate = require("Delegate")
---@class UI3DModelInteractionManager
local UI3DModelInteractionManager = class("UI3DModelInteractionManager")

---@param uiComponent BaseUIComponent
---@param widgetName string
function UI3DModelInteractionManager:ctor(uiComponent, widgetName)
    self.uiComponent = uiComponent
    self.widgetName = widgetName
    ---@type BaseUI3DModelInteractor[]
    self.draggingInteractors = {}

    self.reactingInteractors = {}

    self.clickBlocker = false

    self.onClickEmpty = nil
end

function UI3DModelInteractionManager:Init()
    self.uiComponent:PointerClick(self.widgetName, Delegate.GetOrCreate(self, self.OnClick))
    self.uiComponent:DragEvent(self.widgetName, Delegate.GetOrCreate(self, self.OnDragStart), Delegate.GetOrCreate(self, self.OnDrag), Delegate.GetOrCreate(self, self.OnDragEnd))
end

--- life cycle release, has nothing to do with the onRelease gesture
function UI3DModelInteractionManager:Release()
    self.uiComponent = nil
    self.widgetName = nil
    self.draggingInteractors = nil
end

function UI3DModelInteractionManager:SetOnClickEmpty(func)
    self.onClickEmpty = func
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function UI3DModelInteractionManager:OnClick(go, eventData)
    if self.clickBlocker then
        return
    end
    local interactors = self:GetInteractor(eventData.position)
    for _, interactor in ipairs(interactors) do
        if interactor:CanInteract() and interactor:CanClick() then
            interactor:DoOnClick(eventData)
        end
    end
    if #interactors == 0 and self.onClickEmpty then
        self.onClickEmpty()
    end
end

function UI3DModelInteractionManager:OnDragStart(go, eventData)
    self.clickBlocker = true
    local interactors = self:GetInteractor(eventData.position)
    for _, interactor in ipairs(interactors) do
        if interactor:CanInteract() and interactor:CanDrag() then
            interactor:DoOnDragStart(eventData)
            table.insert(self.draggingInteractors, interactor)
        end
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function UI3DModelInteractionManager:OnDrag(go, eventData)
    local interactors = self:GetInteractor(eventData.position)
    for _, interactor in ipairs(interactors) do
        if interactor:CanInteract() and interactor:ReactToDrag() and interactor ~= self.draggingInteractor then
            if not table.ContainsValue(self.reactingInteractors, interactor) then
                table.insert(self.reactingInteractors, interactor)
                interactor:DoOnMoveIn()
            end
            interactor:DoOnDrag(eventData)
        end
    end
    for _, interactor in ipairs(self.reactingInteractors) do
        if not table.ContainsValue(interactors, interactor) then
            interactor:DoOnMoveOut()
            table.removebyvalue(self.reactingInteractors, interactor)
        end
    end
    for _, interactor in ipairs(self.draggingInteractors) do
        interactor:DoOnDrag(eventData)
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function UI3DModelInteractionManager:OnDragEnd(go, eventData)
    local interactors = self:GetInteractor(eventData.position)
    for _, interactor in ipairs(interactors) do
        if interactor:CanInteract() and interactor:ReactToDrag() and interactor ~= self.draggingInteractor then
            interactor:DoOnDragEnd(eventData)
        end
    end
    for _, interactor in ipairs(self.draggingInteractors) do
        interactor:DoOnDragEnd(eventData)
    end
    table.clear(self.draggingInteractors)
    self.clickBlocker = false
end

---@param screenPos CS.UnityEngine.Vector2
---@return BaseUI3DModelInteractor[]
function UI3DModelInteractionManager:GetInteractor(screenPos)
    local ret = {}
    local interactors3D = self:Get3DInteractor(screenPos)
    for _, interactor in ipairs(interactors3D) do
        table.insert(ret, interactor)
    end

    local interactorsUI = self:GetUIInteractor(screenPos)
    for _, interactor in ipairs(interactorsUI) do
        table.insert(ret, interactor)
    end

    return ret
end

---@param screenPos CS.UnityEngine.Vector2
---@return BaseUI3DModelInteractor[]
function UI3DModelInteractionManager:Get3DInteractor(screenPos)
    local ret = {}
    ---@type CS.UnityEngine.Camera
    local camera = g_Game.UIManager.ui3DViewManager:UICam3D()
    local pos = CS.UnityEngine.Vector3(screenPos.x, screenPos.y)
    local ray = camera:ScreenPointToRay(pos)
    local result, retArray = physics.raycastnonalloc(ray, 1000, -1)
    if result > 0 then
        for i = 1, result do
            local behaviours = {}
            retArray[i]:GetLuaBehaviours("BaseUI3DModelInteractor", behaviours)
            for _, comp in ipairs(behaviours) do
                table.insert(ret, comp.Instance)
            end
        end
    end
    return ret
end

---@param screenPos CS.UnityEngine.Vector2
---@return BaseUI3DModelInteractor[]
function UI3DModelInteractionManager:GetUIInteractor(screenPos)
    local ret = {}
    local camera = g_Game.UIManager:GetUICamera()
    local pos = CS.UnityEngine.Vector3(screenPos.x, screenPos.y)
    local ray = camera:ScreenPointToRay(pos)
    local result, retArray = physics.raycastnonalloc(ray, 1000, -1)
    if result > 0 then
        for i = 1, result do
            local comp = retArray[i]:GetLuaBehaviourInParent("BaseUI3DModelInteractor", true)
            if comp ~= nil then
                table.insert(ret, comp.Instance)
            end
        end
    end
    return ret
end

return UI3DModelInteractionManager