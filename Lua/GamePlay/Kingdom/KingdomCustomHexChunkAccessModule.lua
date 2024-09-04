local BaseModule = require("BaseModule")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local Utils = require("Utils")

---@class KingdomCustomHexChunkAccessModule:BaseModule
---@field new fun():BaseModule
---@field super BaseModule
local KingdomCustomHexChunkAccessModule = class('KingdomCustomHexChunkAccessModule', BaseModule)

KingdomCustomHexChunkAccessModule.BehemothGate = "p_behemoth_gate"

function KingdomCustomHexChunkAccessModule:ctor()
    KingdomCustomHexChunkAccessModule.super.ctor(self)
    ---@private
    ---@type table<number, CS.UnityEngine.GameObject>
    self._customHexChunkMap = {}
end

function KingdomCustomHexChunkAccessModule:ClearUp()
    table.clear(self._customHexChunkMap)
end

---@return CS.UnityEngine.GameObject
function KingdomCustomHexChunkAccessModule:QueryCustomHexChunkByTerritoryId(territoryId)
    return self._customHexChunkMap[territoryId]
end

---@return fun(go:CS.UnityEngine.GameObject,object:any)
function KingdomCustomHexChunkAccessModule:GetOnShowCallback()
    return Delegate.GetOrCreate(self, self.OnCustomHexChunkShow)
end

---@return fun(go:CS.UnityEngine.GameObject,object:any)
function KingdomCustomHexChunkAccessModule:GetOnHideCallback()
    return Delegate.GetOrCreate(self, self.OnCustomHexChunkHide)
end

---@private
---@param go CS.UnityEngine.GameObject
---@param object any @current CS.System.Object > int territoryId
function KingdomCustomHexChunkAccessModule:OnCustomHexChunkShow(go, object)
    if UNITY_DEBUG then
        if self._customHexChunkMap[object] then
            g_Logger.Error(("territoryId:%s override existed!"):format(object))
        end
        if Utils.IsNull(go) then
            g_Logger.Error(("territoryId:%s show nil go!"):format(object))
        end
    end
    self._customHexChunkMap[object] = go
    g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_CUSTOM_HEX_CHUNK_SHOW, object, go)
end

---@private
---@param go CS.UnityEngine.GameObject
---@param object any @current CS.System.Object > int territoryId
function KingdomCustomHexChunkAccessModule:OnCustomHexChunkHide(go, object)
    if UNITY_DEBUG then
        if not self._customHexChunkMap[object] then
            g_Logger.Error(("territoryId:%s hide go but not show!"):format(object))
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_CUSTOM_HEX_CHUNK_PRE_HIDE, object, self._customHexChunkMap[object])
    self._customHexChunkMap[object] = nil
    g_Game.EventManager:TriggerEvent(EventConst.KINGDOM_CUSTOM_HEX_CHUNK_HIDE, object)
end

return KingdomCustomHexChunkAccessModule