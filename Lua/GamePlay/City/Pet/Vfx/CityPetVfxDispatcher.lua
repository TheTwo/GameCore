---@class CityPetVfxDispatcher
---@field new fun():CityPetVfxDispatcher
local CityPetVfxDispatcher = class("CityPetVfxDispatcher")
local Utils = require("Utils")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local CityPetAnimTriggerEvent = require("CityPetAnimTriggerEvent")

function CityPetVfxDispatcher:ctor()
    ---@type table<string, table<string, CS.DragonReborn.VisualEffect.VisualEffectHandle>>
    self._effectHandleMap = {}
end

function CityPetVfxDispatcher:Start()
    self.attachPointHolder = self.behaviour.gameObject:GetComponentInParent(typeof(CS.FXAttachPointHolder))
    g_Game.EventManager:AddListener(EventConst.CITY_PET_CLEAR_DISPATCH_VFX_SFX, Delegate.GetOrCreate(self, self.ClearSelfVfx))
end

function CityPetVfxDispatcher:OnDisable()
    g_Game.EventManager:RemoveListener(EventConst.CITY_PET_CLEAR_DISPATCH_VFX_SFX, Delegate.GetOrCreate(self, self.ClearSelfVfx))
    self:ClearVfx()
end

function CityPetVfxDispatcher:ClearSelfVfx(instanceId)
    if Utils.IsNull(self.attachPointHolder) then return end
    if instanceId ~= self.attachPointHolder:GetInstanceID() then return end

    self:ClearVfx()
end

function CityPetVfxDispatcher:ClearVfx()
    for _, map in pairs(self._effectHandleMap) do
        for _, handle in pairs(map) do
            handle:Delete()
        end
    end
    table.clear(self._effectHandleMap)
end

---@param param string
function CityPetVfxDispatcher:OnAnimationEvent(param)
    if string.IsNullOrEmpty(param) then return end
    if Utils.IsNull(self.attachPointHolder) then return end

    local paramGroup = param:split("|")
    for _, param in ipairs(paramGroup) do
        self:Dispatch(param)
    end
end

function CityPetVfxDispatcher:Dispatch(param)
    local paramGroup = param:split(":")
    if #paramGroup < 2 then
        g_Logger.WarnChannel("CityPetVfxDispatcher", "参数格式错误: " .. param)
        return
    end

    if paramGroup[1] == "playvfx" and #paramGroup == 3 then
        local vfxPrefabName = paramGroup[2]
        if string.IsNullOrEmpty(vfxPrefabName) then
            g_Logger.WarnChannel("CityPetVfxDispatcher", "特效名为空")
            return
        end
        local attachPointName = paramGroup[3]

        local attachPoint = self.attachPointHolder:GetAttachPoint(attachPointName)
        if Utils.IsNull(attachPoint) then
            g_Logger.WarnChannel("CityPetVfxDispatcher", "找不到挂点: " .. attachPointName)
            return
        end
        ---@type table<string, CS.DragonReborn.VisualEffect.VisualEffectHandle>
        local map = table.getOrCreate(self._effectHandleMap, attachPointName)
        local handle = map[vfxPrefabName]
        if handle then
            handle:Delete()
        end
        handle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
        map[vfxPrefabName] = handle
        handle:Create(vfxPrefabName, "CityPetVfxDispatcher", attachPoint, Delegate.GetOrCreate(self, self.OnVfxCreated))

        ---TODO:临时处理，当遇到砍树特效时，广播一个树被砍了的信息
        if vfxPrefabName == "vfx_w_fuzi" then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_PET_ANIM_EVENT_TRIGGER, self.attachPointHolder, CityPetAnimTriggerEvent.WOOD_CUTTING)
        end
    elseif paramGroup[1] == "playsound" and #paramGroup == 2 then
        local soundName = paramGroup[2]
        if string.IsNullOrEmpty(soundName) then
            g_Logger.WarnChannel("CityPetVfxDispatcher", "音效名为空")
            return
        end

        g_Game.SoundManager:Play(soundName, self.behaviour.gameObject)
    end
end

function CityPetVfxDispatcher:OnVfxCreated(isSuccess, userdata, handle)
    if not isSuccess then return end
    if Utils.IsNull(self.behaviour) then return end
    
    local gameObject = handle.Effect.gameObject
    if Utils.IsNull(gameObject) then return end

    gameObject:SetLayerRecursively("City")

    local transform = gameObject.transform
    transform.localPosition = CS.UnityEngine.Vector3.zero
    transform.localRotation = CS.UnityEngine.Quaternion.identity
    transform.localScale = CS.UnityEngine.Vector3.one
end

return CityPetVfxDispatcher