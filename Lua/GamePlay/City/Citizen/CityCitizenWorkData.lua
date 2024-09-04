local ConfigRefer = require("ConfigRefer")
local CityWorkHelper = require("CityWorkHelper")
local CityWorkTargetType = require("CityWorkTargetType")

---@class CityCitizenWorkData
---@field new fun():CityCitizenWorkData
local CityCitizenWorkData = class('CityCitizenWorkData')

function CityCitizenWorkData:ctor()
    self._id = 0
    self._status = 0
    self._configId = 0
    self._target = 0
    self._targetsPathTime = 0
    self._targetType = 0
    ---@type CityWorkConfigCell
    self._config = nil
    self._startTime = 0
    self._realWorkTime = 0
    self._beginProgress = 0
    self._isInfinity = false
end

function CityCitizenWorkData:FillTargetWithConfigServerData(targets, timeSegments)
    self._target = targets
    self._targetsPathTime = (timeSegments[1] or 0) / 1000.0
end

---@param id number
---@param workData wds.CastleWork
function CityCitizenWorkData.CreateWithServerData(id, workData)
    local ret = CityCitizenWorkData.new()
    ret._id = id
    ret._status = workData.Status
    ret._configId = workData.ConfigId
    ret._startTime = workData.BeginTime / 1000.0
    ret._realWorkTime = workData.RealWorkTime / 1000.0
    ret._config = ConfigRefer.CityWork:Find(ret._configId)
    ret._beginProgress = workData.BeginProgress
    ret._isInfinity = workData.Infinity
    ret._targetType = CityWorkHelper.GetWorkTargetTypeByCfg(ret._config)
    ret:FillTargetWithConfigServerData(workData.WorkTarget, workData.TimeSegments)
    return ret
end

---@param workData wds.CastleWork
---@param city MyCity
function CityCitizenWorkData:UpdateWithServerData(workData)
    self._status = workData.Status
    self._beginProgress = workData.BeginProgress
    self._realWorkTime = workData.RealWorkTime / 1000.0
    self:FillTargetWithConfigServerData(workData.WorkTarget, workData.TimeSegments)
end

---@return number, number
function CityCitizenWorkData:GetTarget()
    return self._target, self._targetType
end

---@return number,number,number @index,gotoTime,workTime
function CityCitizenWorkData:GetCurrentTargetIndexGoToTimeLeftTime()
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local passTime = nowTime - self._startTime
    if self._targetsPathTime > passTime then
        return 1, self._targetsPathTime-passTime, nil
    end

    passTime = passTime - self._targetsPathTime
    local needTime = self:GetTargetWorkTime()
    if needTime > passTime then
        return 1, nil, needTime - passTime
    end
    return nil,nil,nil
end

function CityCitizenWorkData:GetCurrentTargetIndexGoAndWorkLeftTime()
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local passTime = nowTime - self._startTime
    local leftForWork = passTime - self._targetsPathTime
    local needTime = self:GetTargetWorkTime()
    if self._targetsPathTime > passTime or needTime > leftForWork then
        return 1,math.max(0, self._targetsPathTime-passTime) + math.max(0, needTime - leftForWork)
    end
    return nil,nil
end

---@param mgr CityCitizenManager
function CityCitizenWorkData:GetTargetWorkTime()
    return self._realWorkTime
end

---@return number,number @float [0,1], leftTime
function CityCitizenWorkData:GetMakeProgress(nowTime)
    if self._realWorkTime == 0 then return 1, 0 end
    if nowTime < self._startTime then return 0, self._realWorkTime end

    local passTime = nowTime - self._startTime
    local progress = math.clamp01(passTime / self._realWorkTime)
    local remainTime = math.max(0, self._realWorkTime - passTime)
    return progress, remainTime
end

return CityCitizenWorkData

