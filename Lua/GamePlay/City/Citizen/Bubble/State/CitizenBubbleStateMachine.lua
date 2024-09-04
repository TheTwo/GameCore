local StateMachine = require("StateMachine")
local CitizenBubbleStateNone = require("CitizenBubbleStateNone")
local CitizenBubbleStateTask = require("CitizenBubbleStateTask")
local CitizenBubbleStateEscape = require("CitizenBubbleStateEscape")
local CitizenBubbleStateNormal = require("CitizenBubbleStateNormal")
local CitizenBubbleStateIndicator = require("CitizenBubbleStateIndicator")
local CitizenBubbleStateEmoji = require("CitizenBubbleStateEmoji")
local CitizenBubbleStateService = require("CitizenBubbleStateService")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local NpcServiceObjectType = require("NpcServiceObjectType")
local CityCitizenDefine = require("CityCitizenDefine")
local DBEntityPath = require("DBEntityPath")

local EventConst = require("EventConst")
local Delegate = require("Delegate")

---@class CitizenBubbleStateMachine
---@field new fun(citizen:CityUnitCitizen):CitizenBubbleStateMachine
local CitizenBubbleStateMachine = class('CitizenBubbleStateMachine')

---@param citizen CityUnitCitizen
function CitizenBubbleStateMachine:ctor(citizen)
    self._start = false
    self._hasTask = false
    self._TaskCanShow = false
    self._citizenTaskInitStoryId = nil
    self._hasService = false
    self._inEscape = false
    ---@type {icon:string, changeValue:number}[]
    self._indicator = {}
    ---@type {icon:string}
    self._emoji = nil
    self._forceClear = false
    self._lod = nil
    self._delayCheckTask = false
    self._delayCheckService = false
    self._timelineHideBubble = false

    ---@type table<number, string>
    self._indicatorId2Icon = {}
    
    self._citizen = citizen
    self._stateMachine = StateMachine.new()
    self._stateMachine.allowReEnter = true
    local host = self
    self._stateMachine:AddState("CitizenBubbleStateNone", CitizenBubbleStateNone.new(citizen,host))
    self._stateMachine:AddState("CitizenBubbleStateTask", CitizenBubbleStateTask.new(citizen,host))
    self._stateMachine:AddState("CitizenBubbleStateEscape", CitizenBubbleStateEscape.new(citizen,host))
    self._stateMachine:AddState("CitizenBubbleStateNormal", CitizenBubbleStateNormal.new(citizen,host))
    self._stateMachine:AddState("CitizenBubbleStateIndicator", CitizenBubbleStateIndicator.new(citizen,host))
    self._stateMachine:AddState("CitizenBubbleStateEmoji", CitizenBubbleStateEmoji.new(citizen,host))
    self._stateMachine:AddState("CitizenBubbleStateService", CitizenBubbleStateService.new(citizen,host))
    
    self._stateMachine:ChangeState("CitizenBubbleStateNone")
end

function CitizenBubbleStateMachine:Tick(dt)
    local citizenAssetReady = self._citizen:IsModelReady()
    if self._forceClear then
        self._forceClear = false
        self._stateMachine:ChangeState("CitizenBubbleStateNone")
    elseif self._timelineHideBubble then
        self._stateMachine:ChangeState("CitizenBubbleStateNone")
    elseif self._hasTask and self._TaskCanShow and citizenAssetReady then
        self._stateMachine:ChangeState("CitizenBubbleStateTask")
    elseif not self._hasTask and self._hasService and citizenAssetReady then
        self._stateMachine:ChangeState("CitizenBubbleStateService")
    elseif self._inEscape and citizenAssetReady and self._lod and self._lod < CityCitizenDefine.CitizenCameraLodLevel.High then
        self._stateMachine:ChangeState("CitizenBubbleStateEscape")
    elseif #self._indicator > 0 and citizenAssetReady and self._lod == CityCitizenDefine.CitizenCameraLodLevel.Low then
        self._stateMachine:ChangeState("CitizenBubbleStateIndicator")
    elseif self._emoji and citizenAssetReady and self._lod and self._lod < CityCitizenDefine.CitizenCameraLodLevel.High then
        self._stateMachine:ChangeState("CitizenBubbleStateEmoji")
    elseif citizenAssetReady and self._lod and self._lod < CityCitizenDefine.CitizenCameraLodLevel.High then
        self._stateMachine:ChangeState("CitizenBubbleStateNormal")
    else
        self._stateMachine:ChangeState("CitizenBubbleStateNone")
    end
    self._stateMachine:Tick(dt)
    if self._delayCheckTask then
        self._delayCheckTask = false
        self:CheckHasTask()
    end
    if self._delayCheckService then
        self._delayCheckService = false
        self:CheckHasService()
    end
end

function CitizenBubbleStateMachine:Start()
    if self._start then return end
    self._start = true
    self._stateMachine:ChangeState("CitizenBubbleStateNone")
    g_Game.EventManager:AddListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self, self.CheckHasTask))
    ModuleRefer.PlayerServiceModule:AddServicesChanged(NpcServiceObjectType.Citizen, Delegate.GetOrCreate(self, self.OnCitizenServiceChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleCitizens.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
    self:CheckHasTask()
    self:CheckHasService()
end

function CitizenBubbleStateMachine:End()
    if not self._start then return end
    self._start = false
    ModuleRefer.PlayerServiceModule:RemoveServicesChanged(NpcServiceObjectType.Citizen, Delegate.GetOrCreate(self, self.OnCitizenServiceChanged))
    g_Game.EventManager:RemoveListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self, self.CheckHasTask))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleCitizens.MsgPath, Delegate.GetOrCreate(self, self.OnCitizenDataChanged))
    self._stateMachine:ChangeState("CitizenBubbleStateNone")
end

function CitizenBubbleStateMachine:CheckHasTask()
    self._TaskCanShow = false
    self._hasTask,self._citizenTaskInitStoryId = ModuleRefer.QuestModule.Chapter:CheckIsShowCitizenHeadIcon(self._citizen._data._id)
    if self._citizenTaskInitStoryId and self._citizenTaskInitStoryId ~= 0 and not ModuleRefer.StoryModule:IsPlayerStoryTaskFinished(self._citizenTaskInitStoryId) then
        self._TaskCanShow = true
    end
end

function CitizenBubbleStateMachine:CheckHasService()
    self._hasService = ModuleRefer.PlayerServiceModule:HasInteractableServiceOnObject(NpcServiceObjectType.Citizen, self._citizen._data._id)
end

function CitizenBubbleStateMachine:OnCitizenServiceChanged(entity, changedData)
    if not changedData then return end
    local add = changedData.Add
    if add and add[self._citizen._data._id] then
        self:CheckHasService()
        return
    end
    if changedData.Remove and changedData.Remove[self._citizen._data._id] then
        self:CheckHasService()
        return
    end
    if changedData[self._citizen._data._id] then
        self:CheckHasService()
        return
    end
end

function CitizenBubbleStateMachine:OnCitizenDataChanged(entity, changedData)
    if not changedData then return end
    local inChange = false
    if changedData[self._citizen._data._id] then
        inChange = true
    end
    if not inChange and changedData.Add and type(changedData.Add) == 'table' and changedData.Add[self._citizen._data._id] then
        inChange = true
    end
    if not inChange and changedData.Remove and type(changedData.Remove) == 'table' and changedData.Remove[self._citizen._data._id] then
        inChange = true
    end
    if not inChange then return end
    self:CheckHasTask()
    self:CheckHasService()
    self._delayCheckService = true
    self._delayCheckTask = true
end

function CitizenBubbleStateMachine:SetIsHide(isHide)
    if self._timelineHideBubble == isHide then return end
    self._timelineHideBubble = isHide
    if not self._timelineHideBubble then
        self._delayCheckService = true
        self._delayCheckTask = true
    else
        self:Tick(0)
    end
end

---@param id number
---@param value number
function CitizenBubbleStateMachine:PushQueueModifyIndicatorNotify(id, value)
    local icon = self._indicatorId2Icon[id]
    if not icon then
        ---@type CityEnvironmentalIndicatorConfigCell
        local config = ConfigRefer.CityEnvironmentalIndicator:Find(id)
        icon = config and config:Icon() or string.Empty
        self._indicatorId2Icon[id] = icon
    end
    table.insert(self._indicator, {icon = icon, changeValue = value})
end

---@param newLod CityCitizenDefine.CitizenCameraLodLevel
function CitizenBubbleStateMachine:OnLodChanged(newLod)
    if self._lod == newLod then return end
    self._lod = newLod
end

return CitizenBubbleStateMachine