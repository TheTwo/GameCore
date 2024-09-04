---
--- Created by wupei. DateTime: 2022/2/24
---

local rapidJson = require("rapidjson")

---@class BuffClientManager
local BuffClientManager = class("BuffClientManager")
local _instance = nil

---@param ... any
---@return BuffClientManager
function BuffClientManager.CreateInstance(...)
    if _instance then
        g_Logger.Error("BuffClientManager has instance")
        return
    end
    _instance = BuffClientManager.new(...)
    return _instance
end

-----@return BuffClientManager
function BuffClientManager.GetInstance()
    return _instance
end

-----@return void
function BuffClientManager.DestroyInstance()
    if _instance ~= nil then
        _instance:OnDestroy()
        _instance = nil
    end
end

---@param self BuffClientManager
---@param nativePath any
---@return void
function BuffClientManager:ctor(nativePath)
    self._buffsMap = nil
    ---@type SESkillClientNative
    self.native = require(nativePath).new()
    self._runners = {}
	---@type table<string, CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper>
	self._createHelperPool = {}

    self:LoadConfig()
end

---@param self BuffClientManager
---@param poolName string
---@return CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
function BuffClientManager:GetCreateHelper(poolName)
	if (not self._createHelperPool[poolName]) then
		self._createHelperPool[poolName] = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper.Create(poolName)
	end
	return self._createHelperPool[poolName]
end

---@param self BuffClientManager
---@return void
function BuffClientManager:LoadConfig()
    local jsonObj = g_Game.AssetManager:LoadTextToJsonObj('buff_client')
    if not jsonObj then
        g_Logger.Error("buff_client.json parse error.")
        return
    end

    local buffs = jsonObj["Buffs"]
    local buffsMap = {}
    if buffs then
        for i = 1, #buffs do
            local buff = buffs[i]
            buffsMap[buff["Id"]] = buff
        end
    end
    self._buffsMap = buffsMap
end

---@param self BuffClientManager
---@return void
function BuffClientManager:OnDestroy()
    for runner, _ in pairs(self._runners) do
        runner:OnFinish()
        self._runners[runner] = nil
    end
	for poolName, helper in pairs(self._createHelperPool) do
		helper:DeleteAll()
	end
end

---@param self BuffClientManager
---@param buffParam BuffClientParam
function BuffClientManager:IsBuffChanged(buffParam)
    for runner, _ in pairs(self._runners) do
        local existBuffParam = runner:GetParam()
        if buffParam:Equal(existBuffParam) then
            return buffParam:GetBuffPerformId() ~= existBuffParam:GetBuffPerformId()
        end
    end

    return false
end

---@param self BuffClientManager
---@param buffParam BuffClientParam
---@return void
function BuffClientManager:Start(buffParam)
    buffParam:SetManager(self)
    local buffPerformId = buffParam:GetBuffPerformId()
    local buff = self._buffsMap[buffPerformId]
    if not buff then
        g_Logger.Error("buffId not found in buff map. buffId: %s", buffPerformId)
        return
    end

    local runner = require("BuffClientRunner").new(buffParam, buff)
    runner:Start()
    self._runners[runner] = true
end

---@param self BuffClientManager
---@param buffParam BuffClientParam
---@return void
function BuffClientManager:End(buffParam)
    for runner, _ in pairs(self._runners) do
        if buffParam:Equal(runner:GetParam()) then
            runner:End()
            self._runners[runner] = nil
        end
    end
end

return BuffClientManager
