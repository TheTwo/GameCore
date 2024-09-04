local UnitCitizenConfigWrapper = require("UnitCitizenConfigWrapper")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local CityWorkType = require("CityWorkType")
local ArtResourceUtils = require("ArtResourceUtils")
local CityCitizenDefine = require("CityCitizenDefine")
local ModuleRefer = require("ModuleRefer")
local CityWorkTargetType = require("CityWorkTargetType")

---@class CityCitizenData
---@field new fun():CityCitizenData
local CityCitizenData = class('CityCitizenData')

CityCitizenData.EnvIndicatorsUpdateTime = 60

---@param manager CityCitizenManager
---@param Id number
---@param serverData wds.Citizen
---@return CityCitizenData
function CityCitizenData.CreateWithServerData(manager, Id, serverData)
    local ret = CityCitizenData.new()
    ret._id = Id
    ret._config = ConfigRefer.Citizen:Find(serverData.ConfigId)
    ret._status = serverData.Status or 0
    ret._workId = serverData.WorkId or 0
    ret._houseId = serverData.HouseId or 0
    ret._infectionProgress = serverData.InfectionProgress or 0
    ret._infectionCapacity = serverData.InfectionCapacity or 0
    ret._faintTime = serverData.FaintRecoverTime or 0
    ret._workPos = serverData.WorkPos
    ret._mgr = manager
    local asset,scale = CityCitizenDefine.GetCitizenModelAndScaleByDeviceLv(ret._config)
    local cityConfig = ConfigRefer.CityConfig
    ret._unitConfig = UnitCitizenConfigWrapper.new(asset, UnitCitizenConfigWrapper.WrapSpeedValue(cityConfig:CitizenSpeedWalk()), UnitCitizenConfigWrapper.WrapSpeedValue(cityConfig:CitizenSpeedRun()), scale)
    for i = 1, ret._config:EnvironmentalIndicatorsLength() do
        local c = ConfigRefer.CitizenEnvironmentalIndicator:Find(ret._config:EnvironmentalIndicators(i))
        local initValue = 0
        if c:InitValueLength() > 1 then
            local startValue = c:InitValue(1)
            local endValue = c:InitValue(2)
            if math.floor(startValue + 0.5) == startValue and math.floor(endValue + 0.5) == endValue then
                initValue =  math.random(c:InitValue(1), c:InitValue(2))
            else
                initValue = math.random() * (c:InitValue(2) - c:InitValue(1))
            end
        elseif c:InitValueLength() > 0 then
            initValue = c:InitValue(1)
        end
        ret._envIndicators[c:IndicatorId()] = { 
            Id = c:IndicatorId(),
            value = initValue,
            inc = c:IncModifier(),
            dec = c:DecModifier(),
        }
    end
    ret._envIndicatorsNextUpdateTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + CityCitizenData.EnvIndicatorsUpdateTime
    return ret
end

---@param manager CityCitizenManager
---@param Id number
---@param configId number
function CityCitizenData.CreateLocalDebugData(manager, Id, configId, houseId)
    local ret = CityCitizenData.new()
    ret._id = Id
    ret._config = ConfigRefer.Citizen:Find(configId)
    ret._status = 0
    ret._workId = 0
    ret._houseId = houseId or 0
    ret._infectionProgress = 0
    ret._infectionCapacity =  0
    ret._faintTime = 0
    ret._mgr = manager
    local asset,scale = CityCitizenDefine.GetCitizenModelAndScaleByDeviceLv(ret._config)
    local cityConfig = ConfigRefer.CityConfig
    ret._unitConfig = UnitCitizenConfigWrapper.new(asset, UnitCitizenConfigWrapper.WrapSpeedValue(cityConfig:CitizenSpeedWalk()), UnitCitizenConfigWrapper.WrapSpeedValue(cityConfig:CitizenSpeedRun()), scale)
    return ret
end

function CityCitizenData:ctor()
    self._id = 0
    ---@type CitizenConfigCell
    self._config = nil
    ---@type wds.CitizenStatus
    self._status = 0
    self._houseId = 0
    self._workId = 0
    self._mgr = nil
    ---@type number @integer
    self._infectionProgress = 0
    ---@type number @integer
    self._infectionCapacity = 0
    ---@type number @timestamp in second
    self._faintTime = 0
    ---@type wds.Vector2F
    self._workPos = nil
    ---@type table<number, {Id:number,inc:number, dec:number, value:number}>
    self._envIndicators = {}
    self._envIndicatorsNextUpdateTime = nil
end

function CityCitizenData:ModelAsset()
    return CityCitizenDefine.GetCitizenModelByDeviceLv(self._config)
end

function CityCitizenData:UnitActorConfigWrapper()
    return self._unitConfig
end

---@param pathFinder CityPathFinding
function CityCitizenData:SpawnPosition(pathFinder, x, y, sx, sy)
    if self._houseId ~= 0 then
        local x,z,sX,sZ,areaMak = self._mgr:GetAssignedArea(self)
        if x and z and sX and sZ and areaMak then
            return pathFinder:RandomPositionInRange(x,z,sX, sZ, areaMak)
        end
    end
    if x and y and sx and sy then
        local px = x - 1
        local py = y - 1
        local sX = sx + 2
        local sY = sy + 2
        return pathFinder:RandomPositionInRange(px, py, sX, sY, pathFinder.AreaMask.CityGround)
    end
    return pathFinder:RandomPositionInExploredZoneWithInSafeArea(pathFinder.AreaMask.CityGround)
end

function CityCitizenData:WalkSpeed()
    return self._unitConfig:WalkSpeed()
end

function CityCitizenData:RunSpeed()
    return self._unitConfig:RunSpeed()
end

function CityCitizenData:IsAssignedHouse()
    return self._houseId ~= 0
end

function CityCitizenData:GetCitizenIcon()
    return ArtResourceUtils.GetUIItem(self._config:Icon()) or "sp_icon_missing"
end

---@return number,number,number,number,number @x,z,sX,sZ,areaMask
function CityCitizenData:GetAssignedArea()
    return self._mgr:GetAssignedArea(self)
end

--CityCitizenData.isFainting = false

function CityCitizenData:IsFainting()
    return self._infectionCapacity > 0 and self._infectionProgress >= self._infectionCapacity
end

function CityCitizenData:IsReadyForWeakUp()
    return self:IsFainting() and self._faintTime ~= 0 and self._faintTime <= g_Game.ServerTime:GetServerTimestampInSeconds()
end

---@param id number
function CityCitizenData:GetPositionById(id, targetType)
    local work = self:GetWorkData()
    local reason = nil
    if work and work._config then
        reason = CityCitizenDefine.WorkTargetReason.Base
        local workType = work._config:Type()
        if workType ~= CityWorkType.FurnitureLevelUp then
            reason = CityCitizenDefine.WorkTargetReason.Operate
        end
    end
    return self._mgr:GetWorkTargetPosition(id, targetType, false, reason)
end

---@return CityInteractPoint_Impl|nil
function CityCitizenData:AcquireInteractPointById(id, targetType)
    local work = self:GetWorkData()
    local reason = nil
    if work and work._config then
        reason = CityCitizenDefine.WorkTargetReason.Base
        local workType = work._config:Type()
        if workType ~= CityWorkType.FurnitureLevelUp then
            reason = CityCitizenDefine.WorkTargetReason.Operate
        end
    end
    return self._mgr:AcquireWorkTargetInteractPoint(id, targetType, reason)
end

function CityCitizenData:GetDirPositionById(id, targetType)
    local work = self:GetWorkData()
    local reason = nil
    if work and work._config then
        reason = CityCitizenDefine.WorkTargetReason.Base
        local workType = work._config:Type()
        if workType ~= CityWorkType.FurnitureLevelUp then
            reason = CityCitizenDefine.WorkTargetReason.Operate
        end
    end
    if targetType == CityWorkTargetType.Furniture then
        local cell = self._mgr.city.furnitureManager:GetFurnitureById(id)
        if cell then
            local x = cell.x
            local y = cell.y
            local oX,oY = cell:GetCollectPosDirPos(reason)
            x,y = x + oX, y + oY
            return self._mgr.city:GetWorldPositionFromCoord(x, y)
        end
    end
    return self._mgr:GetWorkTargetPosition(id, targetType, true, reason)
end

function CityCitizenData:GetCastleInProgressResourceByWorkId(workId)
    local progressMap = self._mgr.city:GetCastle().CastleElements.InProgressResource
    for i, v in pairs(progressMap) do
        if v.WorkId == workId then
            return i
        end
    end
    return nil
end

function CityCitizenData:HasWork()
    return self._workId ~= 0
end

---@return CityCitizenWorkData
function CityCitizenData:GetWorkData()
    if self._workId == 0 then
        return nil
    end
    return self._mgr:GetWorkData(self._workId)
end

function CityCitizenData:GetCurrentTargetWorkTime()
    if self._workId == 0 then
        return nil,nil
    end
    local index,_,workTime = self:GetWorkData():GetCurrentTargetIndexGoToTimeLeftTime()
    return index,workTime
end

---@param citizenData wds.Citizen
function CityCitizenData:UpdateWithServerData(citizenData)
    self._status = citizenData.Status or 0
    self._workId = citizenData.WorkId or 0
    self._houseId = citizenData.HouseId or 0
    self._infectionProgress = citizenData.InfectionProgress or 0
    self._infectionCapacity = citizenData.InfectionCapacity or 0
    self._faintTime = citizenData.FaintRecoverTime or 0
    self._workPos = citizenData.WorkPos
end

function CityCitizenData:GetWorkName()
    local workData = self:GetWorkData()
    if not workData then
        return I18N.Get("city_work_unknown")
    end
    local cityWorkType = workData._config:Type()
    if CityWorkType.BldConstruct == cityWorkType then
        return I18N.Get("city_construct")
    elseif CityWorkType.BldLvUp == cityWorkType then
        return I18N.Get("city_building_upgrade")
    else
        return I18N.Get("city_work_unknown")
    end
end

function CityCitizenData:IsWorkingWithInfection()
    local workData = self:GetWorkData()
    if not workData then
        return false
    end
    local totalPlanWorkTime = workData:GetTargetWorkTime(2)
    if not totalPlanWorkTime or totalPlanWorkTime < 0 or math.Approximately(totalPlanWorkTime, 0) then
        return false
    end
    local index,_,workLeftTime = workData:GetCurrentTargetIndexGoToTimeLeftTime()
    if not index then
        return false
    end
    local targetId, targetType = workData:GetTarget()
    if not self._mgr:IsTargetInfection(targetId, targetType) then
        return false
    end
    return true,index,totalPlanWorkTime,workLeftTime
end

function CityCitizenData:CalculateInfectionValueLocal()
    local baseValue = self._infectionProgress
    if baseValue > self._infectionCapacity or math.Approximately(baseValue, self._infectionCapacity) then
        return baseValue
    end
    local isWorkingWithInfection,index,totalPlanWorkTime,workLeftTime = self:IsWorkingWithInfection()
    if not isWorkingWithInfection then
        return baseValue
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local lastUpdateTime = self._mgr:GetCitizenDataLastUpdateTime(self._id)
    local needLocalCalculateTime = nowTime - lastUpdateTime
    if needLocalCalculateTime < 0 or math.Approximately(needLocalCalculateTime, 0) then
        return baseValue
    end
    local workTime = 0
    if index == 2 and workLeftTime then
        workTime = math.min(totalPlanWorkTime - workLeftTime, needLocalCalculateTime)
    elseif index > 2 then
        workTime = math.min(totalPlanWorkTime, needLocalCalculateTime)
    end
    if workTime < 0 or math.Approximately(workTime, 0) then
        return baseValue
    end
    workTime = math.max(0, workTime)
    return workTime * ConfigRefer.CityConfig:CitizenInfectivity() + baseValue
end

---@return CityCitizenDefine.HealthStatus
function CityCitizenData:GetHealthStatusLocal()
    if self._infectionCapacity < 0 or math.Approximately(self._infectionCapacity, 0) then
        return CityCitizenDefine.HealthStatus.Health
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if self._infectionProgress > self._infectionCapacity or math.Approximately(self._infectionProgress, self._infectionCapacity) then
        if self._faintTime < nowTime or math.Approximately(self._faintTime, nowTime) then
            return CityCitizenDefine.HealthStatus.FaintingReadyWakeUp
        else
            return CityCitizenDefine.HealthStatus.Fainting
        end
    end
    if (self._infectionProgress > 0 and not math.Approximately(self._infectionProgress, 0)) or self:CalculateInfectionValueLocal() > 0 then
        return CityCitizenDefine.HealthStatus.UnHealth
    end
    return CityCitizenDefine.HealthStatus.Health
end

function CityCitizenData:GetInfectionPercentLocal()
    if self._infectionCapacity <= 0 then
        return 0.0
    end
    if self._infectionProgress >= self._infectionCapacity then
        return 1.0
    end
    local localV = self:CalculateInfectionValueLocal()
    return math.clamp01(localV / self._infectionCapacity)
end

function CityCitizenData:GetCitizenQuality()
    return self:GetHeroCfg():Quality()
end

function CityCitizenData:GetHeroCfg()
    local heroId = self._config:HeroId()
    local heroInfo = ModuleRefer.HeroModule:GetHeroByCfgId(heroId)
    return heroInfo.configCell
end

function CityCitizenData:TickIndicators(nowTime)
    local passTime = nowTime - self._envIndicatorsNextUpdateTime
    local globalMgr = self._mgr.city.cityEnvironmentalIndicatorManager
    if passTime < 0 then
        return
    end
    repeat
        for _, v in pairs(self._envIndicators) do
            v.value = globalMgr:StepCitizenIndicatorValue(v.value, v.inc, v.dec, v.Id)
        end
        passTime = passTime - CityCitizenData.EnvIndicatorsUpdateTime
    until passTime <= 0
    self._envIndicatorsNextUpdateTime = nowTime + CityCitizenData.EnvIndicatorsUpdateTime
end

return CityCitizenData

