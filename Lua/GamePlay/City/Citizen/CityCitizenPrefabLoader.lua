local CityUtils = require("CityUtils")
local Delegate = require("Delegate")
local Utils = require("Utils")

---@class CityCitizenPrefabLoader
---@field new fun():CityCitizenPrefabLoader
---@field behaviour CS.DragonReborn.LuaBehaviour
---@field p_prefabName string
---@field p_stateName string
local CityCitizenPrefabLoader = class('CityCitizenPrefabLoader')

function CityCitizenPrefabLoader:ctor() 
    self._loadedGo = nil
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._loadHandle = nil
    ---@type number
    self._shortNameHash = nil
end

function CityCitizenPrefabLoader:OnEnable()
    if string.IsNullOrEmpty(self.p_prefabName) then
        return
    end
    if self._loadHandle then
        if self._loadHandle.PrefabName == self.p_prefabName then
            return
        end
        self._loadHandle:Delete()
        self._loadHandle = nil
    end
    local creator = CityUtils.GetPooledGameObjectCreateHelper()
    self._loadHandle = creator:Create(self.p_prefabName, self.behaviour.transform, Delegate.GetOrCreate(self, self.OnAssetLoaded))
end

function CityCitizenPrefabLoader:MatchNameHash(shortNameHash)
    if string.IsNullOrEmpty(self.p_stateName) then return true end
    
    if self._shortNameHash == nil then
        local names = self.p_stateName:split('|')
        self._shortNameHash = {}
        for i, v in ipairs(names) do
            self._shortNameHash[v] = CS.UnityEngine.Animator.StringToHash(v)
        end
    end

    for k, v in pairs(self._shortNameHash) do
        if v == shortNameHash then
            return true
        end
    end

    return false
end

function CityCitizenPrefabLoader:SetLoadedCallbackOnce(callback)
    self.loadedCallbackOnce = callback
end

function CityCitizenPrefabLoader:IsLoaded()
    return self._loadHandle ~= nil and self._loadHandle.Loaded
end

---@param go CS.UnityEngine.GameObject
function CityCitizenPrefabLoader:OnAssetLoaded(go, userData, handle)
    if Utils.IsNull(go) then
        return
    end
    local trans = go.transform
    trans.localEulerAngles = CS.UnityEngine.Vector3.zero
    trans.localScale = CS.UnityEngine.Vector3.one
    trans.localPosition = CS.UnityEngine.Vector3.zero
    go:SetLayerRecursive(self.behaviour.gameObject.layer)

    if self.loadedCallbackOnce then
        self.loadedCallbackOnce(go)
        self.loadedCallbackOnce = nil
    end
end

return CityCitizenPrefabLoader