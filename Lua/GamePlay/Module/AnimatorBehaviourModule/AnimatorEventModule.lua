local BaseModule = require("BaseModule")
local Utils = require("Utils")
local Delegate = require("Delegate")

---@class AnimatorEventModule : BaseModule
local AnimatorEventModule = class("AnimatorEventModule", BaseModule)

function AnimatorEventModule:ctor()
    self.groups = {}
end

function AnimatorEventModule:OnRegister()
    g_Game.EventManager:AddListener("LuaStateMachineBehaviour", Delegate.GetOrCreate(self, self.OnEvent))
end

function AnimatorEventModule:OnRemove()
    g_Game.EventManager:RemoveListener("LuaStateMachineBehaviour", Delegate.GetOrCreate(self, self.OnEvent))
end

---@param animator CS.UnityEngine.Animator
---@param layerIndex number
---@param eventId number
---@param callback fun(instanceId:number, layerIndex:number)
function AnimatorEventModule:AddListener(animator, layerIndex, eventId, callback)
    if Utils.IsNull(animator) then
        return
    end

    local instanceId = animator:GetInstanceID()
    local group = self.groups[instanceId]
    if group == nil then
        group = {}
        self.groups[instanceId] = group
    end

    local layers = group[layerIndex]
    if layers == nil then
        layers = {}
        group[layerIndex] = layers
    end

    local listeners = layers[eventId]
    if listeners == nil then
        listeners = {}
        layers[eventId] = listeners
    end

    table.insert(listeners, callback)
end

---@param animator CS.UnityEngine.Animator
---@param layerIndex number
---@param eventId number
---@param callback fun(instanceId:number)
function AnimatorEventModule:RemoveListener(animator, layerIndex, eventId, callback)
    if Utils.IsNull(animator) then
        return
    end

    local instanceId = animator:GetInstanceID()
    local group = self.groups[instanceId]
    if group == nil then
        return
    end

    local layers = group[layerIndex]
    if layers == nil then
        return
    end

    local listeners = layers[eventId]
    if listeners == nil then
        return
    end

    table.removebyvalue(listeners, callback)
end

function AnimatorEventModule:OnEvent(evt)
    local instanceId = evt.instanceId
    local group = self.groups[instanceId]
    if group == nil then
        return
    end

    local layerIndex = evt.layerIndex
    local layers = group[layerIndex]
    if layers == nil then
        return
    end

    local eventId = evt.eventId
    local listeners = layers[eventId]
    if listeners == nil then
        return
    end

    local length = #listeners
    for i = 1, length do
        local listener = listeners[i]
        if listener then
            listener(instanceId, evt)
        end
    end
end

return AnimatorEventModule