local CitizenBTDefine = require("CitizenBTDefine")

---@class CitizenBTContext
---@field new fun():CitizenBTContext
local CitizenBTContext = class('CitizenBTContext')

function CitizenBTContext:ctor()
    ---@private
    self._container = {}
    ---@private
    self._dirty = false
    ---@type CityUnitCitizen
    self._citizen = nil
    self._valueStack = {}
end

---@param citizen CityUnitCitizen
function CitizenBTContext:SetCitizen(citizen)
    self._citizen  = citizen
end

function CitizenBTContext:GetCitizenId()
    return self._citizen._data._id
end

function CitizenBTContext:GetCitizen()
    return self._citizen
end

---@return CityCitizenData
function CitizenBTContext:GetCitizenData()
    return self._citizen._data
end

function CitizenBTContext:GetCurrentIndicator(id)
    return self._citizen._data._envIndicators[id]
end

function CitizenBTContext:ModifyIndicator(id, value)
    local v = self._citizen._data._envIndicators[id]
    if not v then
        return
    end
    v.value = v.value + value
end

function CitizenBTContext:CitizenHasTargetPos()
    return self._citizen._hasTargetPos
end

function CitizenBTContext:GetMgr()
    return self._citizen._data._mgr
end

function CitizenBTContext:GetCity()
    return self._citizen._data._mgr.city
end

function CitizenBTContext:GetCurrentPos()
    return self._citizen._moveAgent._currentPosition
end

---@param node CitizenBTActionNode
function CitizenBTContext:SetCurrentNode(node)
    self:Write(CitizenBTDefine.ContextKey.CurrentNode, node)
end

---@return CitizenBTActionNode
function CitizenBTContext:GetCurrentNode()
    return self:Read(CitizenBTDefine.ContextKey.CurrentNode)
end

function CitizenBTContext:BindInteractPoint(point)
    if self._point == point then
        return
    end
    if self._point then
        self._citizen._data._mgr.city.cityInteractPointManager:DismissInteractPoint(self._point)
    end
    self._point = point
end

function CitizenBTContext:Write(name, value)
    if self._container[name] == value then return end
    self._container[name] = value
    self._dirty = true
end

function CitizenBTContext:Read(name)
    return self._container[name]
end

function CitizenBTContext:MarkDirty()
    self._dirty = true
end

function CitizenBTContext:ClearDirty()
    self._dirty = false
end

function CitizenBTContext:IsDirty()
    return self._dirty
end

function CitizenBTContext:PushOp(value, debugContext)
    table.insert(self._valueStack, {index=#self._valueStack, value = value, debugContext = debugContext})
end

function CitizenBTContext:PopOp()
    local s = table.remove(self._valueStack)
    return s and s.value or nil
end

function CitizenBTContext:PeekOp(index)
    index = index or #self._valueStack
    local s = self._valueStack[index]
    return s and s.value or nil
end

function CitizenBTContext:ClearOp()
    table.clear(self._valueStack)
end

function CitizenBTContext:DumpCitizenInfo()
    local id = self._citizen._data._id
    local name= require("I18N").Get(self._citizen._data._config:Name())
    return ("id:%s name:%s"):format(id, name)
end

return CitizenBTContext