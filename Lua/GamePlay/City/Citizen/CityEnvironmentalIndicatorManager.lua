local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local CityCitizenIndicatorTrigger = require("CityCitizenIndicatorTrigger")

local CityManagerBase = require("CityManagerBase")

---@class IndicatorValue
---@field Id number
---@field Value number
---@field Config CityEnvironmentalIndicatorConfigCell

---@class CityEnvironmentalIndicatorManager:CityManagerBase
---@field new fun():CityEnvironmentalIndicatorManager
---@field super CityManagerBase
local CityEnvironmentalIndicatorManager = class('CityEnvironmentalIndicatorManager', CityManagerBase)

function CityEnvironmentalIndicatorManager:ctor(city, ...)
    CityEnvironmentalIndicatorManager.super.ctor(self, city, ...)
    ---@type table<number, IndicatorValue>
    self.Indicators = {}
    for _, v in ConfigRefer.CityEnvironmentalIndicator:pairs() do
        ---@type IndicatorValue
        local value = {}
        value.Id = v:Id()
        value.Value = v:InitValue()
        value.Config = v
        self.Indicators[value.Id] = value
    end
    ---@type table<CityUnitCitizen, {current:CityCitizenIndicatorTrigger, cdEndTime:number, triggers:CityCitizenIndicatorTrigger[], context:{enterAction:table<number, number>,exitAction:table<number, number>}}>
    self._citizen2TriggerSet = {}
end

function CityEnvironmentalIndicatorManager:NeedLoadData()
    return true
end

function CityEnvironmentalIndicatorManager:DoDataLoad()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.GlobalData.AiData.MsgPath, Delegate.GetOrCreate(self, self.OnAIDataChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_ACTION_GROUP_ENTER, Delegate.GetOrCreate(self, self.OnCitizenActionGroupEnter))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_ACTION_GROUP_EXIT, Delegate.GetOrCreate(self, self.OnCitizenActionGroupExit))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_ACTION_GROUP_MODIFY_INDICATOR, Delegate.GetOrCreate(self, self.OnCitizenActionGroupModifyIndicator))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    local castle = self.city:GetCastleBrief()
    self._castleBriefId = castle.ID
    self:OnAIDataChanged(castle)
    return CityEnvironmentalIndicatorManager.super.DoDataLoad(self)
end

function CityEnvironmentalIndicatorManager:DoDataUnload()
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for citizen, v in pairs(self._citizen2TriggerSet) do
        if v.current then
            v.cdEndTime = v.current:Exit(nowTime, citizen)
            v.current = nil
        end
    end
    table.clear(self._citizen2TriggerSet)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.GlobalData.AiData.MsgPath, Delegate.GetOrCreate(self, self.OnAIDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_ACTION_GROUP_ENTER, Delegate.GetOrCreate(self, self.OnCitizenActionGroupEnter))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_ACTION_GROUP_EXIT, Delegate.GetOrCreate(self, self.OnCitizenActionGroupExit))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_ACTION_GROUP_MODIFY_INDICATOR, Delegate.GetOrCreate(self, self.OnCitizenActionGroupModifyIndicator))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    CityEnvironmentalIndicatorManager.super.DoDataUnload(self)
end

---@param entity wds.CastleBrief
function CityEnvironmentalIndicatorManager:OnAIDataChanged(entity, _)
    if entity.ID ~= self._castleBriefId then
        return
    end
    for id, value in pairs(entity.Castle.GlobalData.AiData) do
        if self.Indicators[id] then
            self.Indicators[id].Value = value
        end
    end
end

function CityEnvironmentalIndicatorManager:GetIndicatorValue(id)
    local i = self.Indicators[id]
    return i and i.Value or 0
end

function CityEnvironmentalIndicatorManager:NotifyIndicatorChanged(id, newValue)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ENVIRONMENTAL_INDICATOR_CHANGE, id, newValue)
end

function CityEnvironmentalIndicatorManager:StepCitizenIndicatorValue(value, inc, dec, gValueId)
    local indicator = self.Indicators[gValueId]
    local gValue = indicator and indicator.Value or 0
    local v = value - gValue
    if v > 0.01 then
        value = value - dec * 0.5 * math.log(math.abs(value - math.max(gValue, 100)))
    elseif v < -0.01 then
        value = value + inc * 0.5 * math.log(math.abs(value - math.max(gValue, 100)))
    end
    return value
end

---@param citizen CityUnitCitizen
function CityEnvironmentalIndicatorManager:RegisterCitizenIndicatorTriggerEmoji(citizen)
    if self._citizen2TriggerSet[citizen] then
        return
    end
    local count = citizen._data._config:EmojiTriggerLength()
    local propCount = citizen._data._config:EmojiProbabilityLength()
    ---@type {current:CityCitizenIndicatorTrigger, cdEndTime:number, triggers:CityCitizenIndicatorTrigger[], context:{enterAction:table<number, number>,exitAction:table<number, number>}}
    local set = {}
    set.triggers = {}
    set.context = {
        enterAction = {},
        exitAction = {}
    }
    local CitizenEmojiTrigger = ConfigRefer.CitizenEmojiTrigger
    for i = 1, count do
        if i > propCount then
            break
        end
        local p = citizen._data._config:EmojiProbability(i)
        local trigger = CityCitizenIndicatorTrigger.new()
        trigger:InitWithConfig(CitizenEmojiTrigger:Find(citizen._data._config:EmojiTrigger(i)), p)
        table.insert(set.triggers, trigger)
    end
    self._citizen2TriggerSet[citizen] = set
end

---@param citizen CityUnitCitizen
function CityEnvironmentalIndicatorManager:UnRegisterCitizenIndicatorTriggerEmoji(citizen)
    local set = self._citizen2TriggerSet[citizen]
    if not set then
        return
    end
    if set.current then
        set.current:Exit(g_Game.ServerTime:GetServerTimestampInSecondsNoFloor(), citizen)
    end
    self._citizen2TriggerSet[citizen] = nil
end

function CityEnvironmentalIndicatorManager:Tick(dt)
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for citizen, v in pairs(self._citizen2TriggerSet) do
        local lastTrigger = v.current
        if v.current and v.current:Tick(dt, nowTime) then
            v.cdEndTime = v.current:Exit(nowTime, citizen)
            v.current = nil
        end
        if not v.current then
            if not v.cdEndTime or nowTime >= v.cdEndTime then
                for _, trigger in ipairs(v.triggers) do
                    if trigger:Check(v.context, lastTrigger, citizen) then
                        v.current = trigger
                        trigger:Enter(nowTime, citizen)
                        break
                    end
                end
            end
        end
        table.clear(v.context.enterAction)
        table.clear(v.context.exitAction)
    end
end

function CityEnvironmentalIndicatorManager:OnCitizenActionGroupEnter(citizen, id)
    local set =  self._citizen2TriggerSet[citizen]
    if not set then return end
    set.context.enterAction[id] = id
end

function CityEnvironmentalIndicatorManager:OnCitizenActionGroupExit(citizen, id)
    local set =  self._citizen2TriggerSet[citizen]
    if not set then return end
    set.context.exitAction[id] = id
end

---@param citizen CityUnitCitizen
---@param id number
---@param value number
function CityEnvironmentalIndicatorManager:OnCitizenActionGroupModifyIndicator(citizen, id, value)
    citizen._citizenBubble:PushQueueModifyIndicatorNotify(id, value)
end

return CityEnvironmentalIndicatorManager