local CitizenBTDefine = require("CitizenBTDefine")
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionGroupSubGroup
---@field config CitizenBTActionGroupConfigCell
---@field indicators table<number, {op:number, value:number, selfId:number}>
---@field action CitizenBTActionNode
---@field weight number
---@field exitModifyIndicators table<number, number>
---@field overrideTags number[]

---@class CitizenBTActionGroup:CitizenBTActionNode
---@field new fun():CitizenBTActionGroup
---@field super CitizenBTActionNode
local CitizenBTActionGroup = class('CitizenBTActionGroup', CitizenBTActionNode)

function CitizenBTActionGroup:ctor()
    CitizenBTActionGroup.super.ctor(self)
    ---@type CitizenBTActionGroupSubGroup[]
    self._group = {}
    ---@type CitizenBTActionGroupSubGroup
    self._currentRunGroup = nil
    ---@type CitizenBTActionGroupSubGroup[]
    self._tempRandomGroups = {}
    self._runTimeMin = 0
    self._runTimeMax = 0
    self._timeEnd = nil
end

---@param groupConfig CitizenBTActionGroupConfigCell
---@param groupNode CitizenBTActionNode
function CitizenBTActionGroup:AddGroupItem(groupConfig, groupNode)
    ---@type CitizenBTActionGroupSubGroup
    local g = {}
    g.config = groupConfig
    g.indicators = {}
    g.exitModifyIndicators = {}
    g.action = groupNode
    g.overrideTags = {}
    g.weight = groupConfig:Weight()
    for i = 1, groupConfig:TagsLength() do
        g.overrideTags[i] = groupConfig:Tags(i)
    end
    for i = 1, groupConfig:IndicatorsLength() do
        local iId = groupConfig:Indicators(i)
        local citizenIndicatorConfig = ConfigRefer.CitizenEnvironmentalIndicator:Find(iId)
        local indicatorOp = groupConfig:Operator(i)
        local indicatorValue = groupConfig:Values(i)
        ---@type {op:number, value:number, selfId:number}
        local indicatorStub = {}
        indicatorStub.op = indicatorOp
        indicatorStub.value = indicatorValue
        indicatorStub.selfId = iId
        g.indicators[citizenIndicatorConfig:IndicatorId()] = indicatorStub
    end
    for i = 1, groupConfig:OnExitModifyIndicatorsLength() do
        local citizenIndicatorConfig = ConfigRefer.CitizenEnvironmentalIndicator:Find(groupConfig:OnExitModifyIndicators(i))
        g.exitModifyIndicators[citizenIndicatorConfig:IndicatorId()] = groupConfig:OnExitModifyValues(i)
    end
    table.insert(self._group, g)
    self._runTimeMin = groupConfig:TimeRange(1)
    self._runTimeMax = groupConfig:TimeRangeLength() > 1 and groupConfig:TimeRange(2) or self._runTimeMin
end

---@param a CitizenBTActionGroupSubGroup
---@param b CitizenBTActionGroupSubGroup
---@return boolean
function CitizenBTActionGroup.SortGroup(a, b)
   return a.weight < b.weight 
end

function CitizenBTActionGroup:GroupItemEnd()
    table.sort(self._group, CitizenBTActionGroup.SortGroup)
end

function CitizenBTActionGroup:Run(context, gContext)
    if #self._group <= 0 then
        return false
    end
    if not self._currentRunGroup then
        table.clear(self._tempRandomGroups)
        ---@type table<number, number>
        local lastFailAction = context:Read(CitizenBTDefine.ContextKey.LastFailAction)
        local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        if lastFailAction then
            for key, value in pairs(lastFailAction) do
                if value < nowTime then
                    lastFailAction[key] = nil
                end
            end
        end
        local totalWeight = 0
        local forceId = context:Read(CitizenBTDefine.ContextKey.ForcePerformanceActionGroupId)
        if forceId then
            for i, v in pairs(self._group) do
                if v.config:Id() == forceId then
                    totalWeight = v.weight + 1
                    table.insert(self._tempRandomGroups, v)
                    goto RandomGroups_set
                end
            end
        end
        for _, v in ipairs(self._group) do
            for id, compare in pairs(v.indicators) do
                local currentV = context:GetCurrentIndicator(id)
                if not currentV or not CitizenBTDefine.OpIndicatorValue(currentV.value, compare.op, compare.value) then
                    goto continue
                end
            end
            if lastFailAction and lastFailAction[v.config:Id()] then
                -- g_Logger.Warn("Action group:%s is skip by last fail CD", v.config:Id())
                goto continue
            end
            totalWeight = totalWeight + v.weight
            table.insert(self._tempRandomGroups, v)
            ::continue::
        end
        ::RandomGroups_set::
        if #self._tempRandomGroups > 0 then
            local rD = math.random(1, math.max(1, totalWeight))
            local rBase = 0
            for _, v in ipairs(self._tempRandomGroups) do
                rBase = rBase + v.weight
                self._currentRunGroup = v
                if rBase >= rD then
                    break
                end
            end
            self._timeEnd = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + math.random(self._runTimeMin, self._runTimeMax)
            context:Write(CitizenBTDefine.ContextKey.PreferRun, self._currentRunGroup.config:Run())
            context:Write(CitizenBTDefine.ContextKey.OverrideTagsMask, nil)
            if #self._currentRunGroup.overrideTags > 0 then
                local tagMask = 0
                for i = 1, #self._currentRunGroup.overrideTags do
                    tagMask = tagMask | (1 << (self._currentRunGroup.overrideTags[i]))
                end
                context:Write(CitizenBTDefine.ContextKey.OverrideTagsMask, tagMask)
            end
        end
    end
    if not self._currentRunGroup then
        return false
    end
    return CitizenBTActionGroup.super.Run(self, context, gContext)
end

function CitizenBTActionGroup:Enter(context, gContext)
    if self._currentRunGroup then
        self._enterTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        -- g_Logger.Log("citizen:%s CitizenBTActionGroup enter:%s", context:DumpCitizenInfo() ,self._currentRunGroup.config:Id())
        context:Write(CitizenBTDefine.ContextKey.CurrentActionGroupId, self._currentRunGroup.config:Id())
        self._currentRunGroup.action:Enter(context, gContext)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_ACTION_GROUP_ENTER, context:GetCitizen(), self._currentRunGroup.config:Id())
    end
end

function CitizenBTActionGroup:Exit(context, gContext)
    if self._currentRunGroup then
        context:Write(CitizenBTDefine.ContextKey.CurrentActionGroupId, nil)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_ACTION_GROUP_EXIT, context:GetCitizen(), self._currentRunGroup.config:Id())
        self._currentRunGroup.action:Exit(context, gContext)
        local lastFailAction = context:Read(CitizenBTDefine.ContextKey.LastFailAction)
        if not lastFailAction or not lastFailAction[self._currentRunGroup.config:Id()] then
            for id, v in pairs(self._currentRunGroup.exitModifyIndicators) do
                context:ModifyIndicator(id, v)
                g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_ACTION_GROUP_MODIFY_INDICATOR, context:GetCitizen(), id, v)
            end
        end
        -- g_Logger.Log("citizen:%s CitizenBTActionGroup Exit:%s, time:%s", context:DumpCitizenInfo(), self._currentRunGroup.config:Id(), self._enterTime and (g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() - self._enterTime) or nil)
    end
    self._currentRunGroup = nil
end

function CitizenBTActionGroup:Tick(dt, nowTime, context, gContext)
    if self._timeEnd and self._timeEnd <= nowTime then
        return true
    end
    if self._currentRunGroup then
        return self._currentRunGroup.action:Tick(dt, nowTime, context, gContext)
    end
    return true
end

return CitizenBTActionGroup