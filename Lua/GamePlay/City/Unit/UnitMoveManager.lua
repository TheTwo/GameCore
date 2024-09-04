local UnitMoveAgent = require("UnitMoveAgent")

---@class UnitMoveManager
---@field new fun():UnitMoveManager
local UnitMoveManager = class('UnitMoveManager')

function UnitMoveManager:ctor()
    ---@type table<number, UnitMoveAgent>
    self._agents = {}
    ---@type table<number, boolean>
    self._agentsId = {}
end

function UnitMoveManager:Init()

end

---@param unitId number
---@param pos CS.UnityEngine.Vector3
---@param dir CS.UnityEngine.Quaternion
---@param speed number
---@return UnitMoveAgent
function UnitMoveManager:Create(unitId, pos, dir, speed)
    if self._agentsId[unitId] then
        return self._agents[unitId]
    end
    local ret = UnitMoveAgent.new(unitId, self)
    self._agentsId[unitId] = true
    self._agents[unitId] = ret
    ret:Init(pos, dir, speed)
    return ret
end

function UnitMoveManager:Destroy()
    for _, v in pairs(self._agents) do
        v:Release()
    end
    table.clear(self._agentsId)
    table.clear(self._agents)
end

---@param unitId number
function UnitMoveManager:RemoveAgent(unitId)
    if not self._agentsId[unitId] then
        return
    end

    self._agentsId[unitId] = nil
    self._agents[unitId]:Release()
    self._agents[unitId] = nil
end

function UnitMoveManager:Tick(deltaTimeSec)
    for _, agnet in pairs(self._agents) do
        agnet:Move(deltaTimeSec)
    end
end

return UnitMoveManager