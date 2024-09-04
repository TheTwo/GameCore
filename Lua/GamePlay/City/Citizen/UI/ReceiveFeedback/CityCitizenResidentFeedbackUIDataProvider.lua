local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require("ConfigRefer")

---@class CityCitizenResidentFeedbackUIDataProvider
---@field new fun(useInMediatorName:string):CityCitizenResidentFeedbackUIDataProvider
local CityCitizenResidentFeedbackUIDataProvider = class('CityCitizenResidentFeedbackUIDataProvider')

---@class CitizenQueueKeyValePair
---@field Id number
---@field Config CitizenConfigCell
---@field TimeStamp number

---@param useInMediatorName string
function CityCitizenResidentFeedbackUIDataProvider:ctor(useInMediatorName)
    ---@type string
    self._useInMediatorName = useInMediatorName
    ---@type fun(cfg:CitizenConfigCell)
    self._onAddCallback = nil
    ---@type number
    self._cityUid = nil
    ---@type CitizenQueueKeyValePair[]
    self._queue = {}
    ---@type table<number, boolean>
    self._dataDic = {}
    ---@type fun()
    self._endCallback = nil
end

---@param cityId number
---@param initQueue table<number, wds.Citizen>
---@param endCallback fun()
function CityCitizenResidentFeedbackUIDataProvider:Init(cityId, initQueue, endCallback)
    self._cityUid = cityId
    self._endCallback = endCallback
    local citizenConfig = ConfigRefer.Citizen
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    for citizenId, citizenData in pairs(initQueue) do
        local cell = citizenConfig:Find(citizenData.ConfigId)
        if cell then
            ---@type CitizenQueueKeyValePair
            local data = {}
            data.Id = citizenId
            data.Config = cell
            data.TimeStamp = nowTime
            table.insert(self._queue, data)
            self._dataDic[citizenId] = true
        end
    end
    table.sort(self._queue, function(a, b) 
        return a.Id < b.Id
    end)
    self:AddEvents()
end

function CityCitizenResidentFeedbackUIDataProvider:Release()
    self:RemoveEvents()
    self._onAddCallback = nil
    if self._endCallback then
        self._endCallback()
        self._endCallback = nil
    end
end

function CityCitizenResidentFeedbackUIDataProvider:IsEmpty()
    return table.isNilOrZeroNums(self._queue)
end

function CityCitizenResidentFeedbackUIDataProvider:AddEvents()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleCitizens.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
end

function CityCitizenResidentFeedbackUIDataProvider:RemoveEvents()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleCitizens.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
end

---@param entity wds.CastleBrief
---@param changedData table
function CityCitizenResidentFeedbackUIDataProvider:OnCitizenDataChanged(entity, changedData)
    if entity.ID ~= self._cityUid then
        return
    end
    ---@type table<number, wds.Citizen>
    local AddMap = changedData.Add or {}
    ---@type table<number, wds.Citizen>
    local RemoveMap = changedData.Remove or {}

    if not AddMap then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local citizenConfig = ConfigRefer.Citizen
    for id,data in pairs(AddMap) do
        if not RemoveMap[id] and not self._dataDic[id] then
            local cell = citizenConfig:Find(data.ConfigId)
            if cell and not cell:SkipTriggerReceiveUI() then
                ---@type CitizenQueueKeyValePair
                local queueData = {}
                queueData.Id = id
                queueData.Config = cell
                queueData.TimeStamp = nowTime
                table.insert(self._queue, queueData)
                self._dataDic[id] = true
                if self._onAddCallback then
                    self._onAddCallback(cell)
                end
            end
        end
    end
end

---@param callback fun(cfg:CitizenConfigCell)
function CityCitizenResidentFeedbackUIDataProvider:SetOnAddNew(callback)
    self._onAddCallback = callback
end

---@return CityCitizenResidentFeedbackPaperCellParameter|nil
function CityCitizenResidentFeedbackUIDataProvider:Dequeue()
    if #self._queue > 0 then
        ---@type CitizenQueueKeyValePair
        local data = table.remove(self._queue, 1)
        ---@type CityCitizenResidentFeedbackPaperCellParameter
        local ret = {}
        ret.id = data.Id
        ret.citizenConfig = data.Config
        ret.timeStamp = data.TimeStamp
        return ret
    end
    return nil
end

---@return CitizenConfigCell[]
function CityCitizenResidentFeedbackUIDataProvider:CloneQueue()
    local ret = {}
    for _, data in ipairs(self._queue) do
        table.insert(ret, data.Config)
    end
    return ret
end

return CityCitizenResidentFeedbackUIDataProvider

