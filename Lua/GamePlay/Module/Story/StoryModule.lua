local StoryStartParameter = require("StoryStartParameter")
local StoryFinishParameter = require("StoryFinishParameter")
local StoryStepGroupExecutor = require("StoryStepGroupExecutor")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local StoryStepGroup = require("StoryStepGroup")
local StartStoryCallbackResult = require("StartStoryCallbackResult")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local I18N = require("I18N")
local StoryModuleHelper = require("StoryModuleHelper")
local StoryDialogType = require("StoryDialogType")
local UIMediatorNames = require("UIMediatorNames")
local StoryDialogUIMediatorParameter = require("StoryDialogUIMediatorParameter")
local StoryDialogUIMediatorParameterChoiceProvider = require("StoryDialogUIMediatorParameterChoiceProvider")
local StoryDialogUiOptionCellType = require("StoryDialogUiOptionCellType")
local Utils = require("Utils")
local DBEntityPath = require("DBEntityPath")

local BaseModule = require("BaseModule")

---@class StoryModule:BaseModule
---@field new fun():StoryModule
---@field private _executor StoryStepGroupExecutor
local StoryModule = class('StoryModule', BaseModule)

function StoryModule:ctor()
    BaseModule.ctor(self)
    self._executor = StoryStepGroupExecutor.new()
    self._storyTimelinePlaying = false
    self._storyDialogInPlaying = false
    ---@type table<number, boolean>
    self._sendStoryStartId = {}
end

function StoryModule:OnRegister()
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Story.StoryInfo.MsgPath, Delegate.GetOrCreate(self, self.OnStoryRecordChanged))
    g_Game.EventManager:AddListener(EventConst.RELOGIN_START, Delegate.GetOrCreate(self, self.OnReloginStart))
end

function StoryModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Story.StoryInfo.MsgPath, Delegate.GetOrCreate(self, self.OnStoryRecordChanged))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_START, Delegate.GetOrCreate(self, self.OnReloginStart))
end

---@param entity wds.Player
function StoryModule:OnStoryRecordChanged(entity, _)
    if not entity or entity ~= ModuleRefer.PlayerModule:GetPlayer() then return end
    g_Game.EventManager:TriggerEvent(EventConst.STROY_FINISHE_LOG_SERVER_INFO_CHANGED)
end

function StoryModule:OnReloginStart()
    if self._executor then
        self._executor:Release(true)
    end
end

---@return table<number, wds.StoryInfo>|nil
function StoryModule:QueryCurrentStoryInfo()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if player then
        local storyData =  player.Story
        if storyData then
            return storyData.StoryInfo
        end
    end
    return nil
end

---@param _ number
function StoryModule:Tick(_)
    self._executor:OnTick()
end

---@return StoryStepGroup, number
function StoryModule:GetStatus()
    if not self._executor then
        return nil, 0
    end
    return self._executor:GetCurrentGroup()
end

---@param storyId number
---@param callback fun(storyId:number, result:StartStoryCallbackResult)
---@param ignoreLastError boolean
---@return boolean
function StoryModule:DoStartStory(storyId, callback, ignoreLastError)
    local storyTaskConfig = ConfigRefer.StoryTask
    if not storyTaskConfig then
        g_Logger.Error("ConfigRefer.StoryTask is nil!")
        if callback then
            callback(storyId, StartStoryCallbackResult.Error)
        end
        return false
    end
    local taskConfigCell = storyTaskConfig:Find(storyId)
    if not taskConfigCell then
        g_Logger.Error("taskConfigCell is nil! id:%s", storyId)
        if callback then
            callback(storyId, StartStoryCallbackResult.Error)
        end
        return false
    end
    if self._executor:HasGroupInExecutingOrQueue(storyId) then
        g_Logger.Error(("Start a story already in executing or queue:%s"):format(storyId))
        if UNITY_EDITOR then
            require("WarningToolsForDesigner").DisplayEditorDialog("错误", ("触发了一个已经在执行或者在队列中的 story! %s\n检查下触发是不是配置了多处"):format(storyId))
        end
    end
    local dbStory = self:QueryCurrentStoryInfo()
    ---@type wds.StoryInfo|nil
    local serverStoryStepSaveData
    if dbStory and not taskConfigCell:SkipRecordToServer() then
        serverStoryStepSaveData = dbStory[storyId]
    end
    local group = StoryStepGroup.new()
    group:BuildWithConfigAndServerData(taskConfigCell, serverStoryStepSaveData)
    if group.IsDone then
        g_Logger.Log("taskStepGroup:%s already done", storyId)
        if callback then
            callback(storyId, StartStoryCallbackResult.SuccessNotRun)
        end
        return false
    end
    group._callback = function(result)
        if callback then
            callback(storyId, result)
        end
    end
    group.sendStartAtBegining = (serverStoryStepSaveData == nil and not taskConfigCell:SkipRecordToServer()) or false
    self._executor:AddToExecute(group, ignoreLastError)
    return group.sendStartAtBegining
end

---@param storyTaskId number
---@return boolean
function StoryModule:IsPlayerStoryTaskFinished(storyTaskId)
    local taskConfigCell = ConfigRefer.StoryTask:Find(storyTaskId)
    if not taskConfigCell then
        g_Logger.Error("storyTaskId:%s StoryTaskConfig is nil!", storyTaskId)
        return false
    end
    if taskConfigCell:SkipRecordToServer() then
        return false
    end
    local dbStory = self:QueryCurrentStoryInfo()
    if not dbStory then
        return false
    end
    local serverStoryStepSaveData = dbStory[storyTaskId]
    if not serverStoryStepSaveData then
        return false
    end
    local group = StoryStepGroup.new()
    group:BuildWithConfigAndServerData(taskConfigCell, serverStoryStepSaveData)
    local ret = group.IsDone
    group:Release()
    return ret
end

function StoryModule:SetStoryDialogPlaying(isPlaying)
    if self._storyDialogInPlaying == isPlaying then
        return
    end
    local lastIsPlaying = self:IsStoryTimelineOrDialogPlaying()
    self._storyDialogInPlaying = isPlaying
    local nowPlaying = self:IsStoryTimelineOrDialogPlaying()
    if lastIsPlaying ~= nowPlaying then
        g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_HIDE_CITY_BUBBLE_REFRESH, nowPlaying)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    end
end

function StoryModule:SetStoryTimelinePlaying(isPlaying)
    if self._storyTimelinePlaying == isPlaying then
        return
    end
    local lastIsPlaying = self:IsStoryTimelineOrDialogPlaying()
    self._storyTimelinePlaying = isPlaying
    local nowPlaying = self:IsStoryTimelineOrDialogPlaying()
    if lastIsPlaying ~= nowPlaying then
        g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_HIDE_CITY_BUBBLE_REFRESH, nowPlaying)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    end
end

function StoryModule:IsStoryTimelineOrDialogPlaying()
    return self._storyTimelinePlaying or self._storyDialogInPlaying
end

---@param storyId number @int32
---@param callback fun(storyId:number, result:StartStoryCallbackResult)
---@param ignoreLastError boolean
function StoryModule:StoryStart(storyId, callback, ignoreLastError)
    if ignoreLastError == nil then ignoreLastError = true end
    self:DoStartStory(storyId, callback, ignoreLastError)
end

---@param storyId number @int32
function StoryModule:CheckLocalSendFlagAndSendStoryStart(storyId)
    if self._sendStoryStartId[storyId] then return end
    self._sendStoryStartId[storyId] = true
    local dbStory = self:QueryCurrentStoryInfo()
    if dbStory and dbStory[storyId] then
        local info = dbStory[storyId]
        if not table.isNilOrZeroNums(info and info.StoryStepInfo or nil) then
            g_Logger.Warn("story task:%s 已有记录， 跳过发送开始", storyId)
            return
        end
    end
    local request = StoryStartParameter.new()
    request.args.StoryId = storyId
    request:SendOnceCallback(nil,nil, nil, function(_,errorCode,_)
        if errorCode == 85001 then
            g_Logger.Warn("剧情任务已经开始过了 %s", storyId)
            return true
        end
    end)
end

---@param stepId number @int32
---@param choice number @int32
---@param callBack fun(isSuccess:boolean, rsp:table)
function StoryModule:StoryFinish(stepId, choice, callBack)
    local stepIdConfig = ConfigRefer.StoryTaskStep:Find(stepId)
    if not stepIdConfig then
        g_Logger.Error("story step:%s config is nil!", stepId)
        if callBack then
            callBack(false)
        end
        return
    end
    local ownerStoryTaskId = stepIdConfig:StoryTaskStepId()
    self._sendStoryStartId[ownerStoryTaskId] = false
    local storyTask = ConfigRefer.StoryTask:Find(ownerStoryTaskId)
    if storyTask and storyTask:SkipRecordToServer() then
        if callBack then
            callBack(true)
        end
        return
    end
    local dbStory = self:QueryCurrentStoryInfo()
    if dbStory and dbStory[ownerStoryTaskId] then
        local info = dbStory[ownerStoryTaskId]
        if info and info.StoryStepInfo and info.StoryStepInfo[stepId] and info.StoryStepInfo[stepId].State > 0 then
            g_Logger.Warn("story step:%s already finished, skip report!", stepId)
            if callBack then
                callBack(true)
            end
            return
        end
    end
    local request = StoryFinishParameter.new()
    request.args.StepId = stepId
    request.args.Choice = choice
    local acceptError = false
    g_Logger.Log("StoryFinish:Send frameCount:%s", CS.UnityEngine.Time.frameCount)
    request:SendOnceCallback(nil, nil, nil, function(cmd, isSuccess, rsp)
        g_Logger.Log("StoryFinish:Send_End frameCount:%s", CS.UnityEngine.Time.frameCount)
        if not acceptError then
            if callBack then
                callBack(isSuccess, rsp)
            end
        end
    end, function(msgId, errorCode, jsonTable)
        if errorCode == 85004 then
            g_Logger.Warn("上报一个服务器认为已完成的步骤，跳过 认为正常结束即可")
            acceptError = true
            if callBack then
                callBack(true, nil)
            end
            return true
        end
    end)
end

function StoryModule:LocalStart(storyId)
    local storyTaskConfig = ConfigRefer.StoryTask
    if not storyTaskConfig then
        g_Logger.Error("ConfigRefer.StoryTask is nil!")
        return false
    end
    local taskConfigCell = storyTaskConfig:Find(storyId)
    if not taskConfigCell then
        g_Logger.Error("taskConfigCell is nil! id:%s", storyId)
        return false
    end
    if self._executor:HasGroupInExecutingOrQueue(storyId) then
        g_Logger.Error(("Start a story already in executing or queue:%s"):format(storyId))
        if UNITY_EDITOR then
            require("WarningToolsForDesigner").DisplayEditorDialog("错误", ("触发了一个已经在执行或者在队列中的 story! %s\n检查下触发是不是配置了多处"):format(storyId))
        end
    end
    local group = StoryStepGroup.new()
    group.NoReportServerRun = true
    group:BuildWithConfigAndServerData(taskConfigCell, nil)
    if group.IsDone then
        g_Logger.Log("taskStepGroup:%s already done", storyId)
        return false
    end
    group._callback = function(result)
        g_Logger.Log("taskStepGroup:%s end", storyId)
    end
    self._executor:AddToExecute(group, true)
    return true
end

---@return string[], StoryStepGroup, StoryStep
function StoryModule:BuildStorySummary(storyGroupId)
    local ret = {}
    if self._executor and self._executor.IsExecuting  then
        local group,_ = self._executor:GetCurrentGroup()
        if group then
            local match, stopAt =  group:BuildGroupSummary(storyGroupId, ret)
            if match then
                return ret, group, stopAt
            end
        end
    end
    if storyGroupId then
        local config = ConfigRefer.StoryDialogGroup:Find(storyGroupId)
        if config then
            local summaryConfig = ConfigRefer.StoryDialogGroupSummary:Find(config:Summary())
            if summaryConfig then
                table.insert(ret, summaryConfig:Content())
            end
        end
    end
    return ret, nil, nil
end

---@param storyGroup StoryStepGroup
---@param stopAt StoryStep
---@return boolean
function StoryModule:MarkFastForwardStory(storyGroup, stopAt)
    if not storyGroup or not self._executor or not self._executor.IsExecuting then
        return false
    end
    local group = self._executor:GetCurrentGroup()
    if group == storyGroup and group.IsExecuting and not group.IsDone then
        group:MarkFastForwardStory(stopAt)
        return true
    end
    return false
end

---@class StoryDialogRecordCellData
---@field type number @0-StoryDialogRecordChatItemCellData, 1-StoryDialogRecordOptionCellData, 2-StoryDialogRecordSubTitleCellData
---@field textContent string

---@return StoryDialogRecordCellData[]
function StoryModule:BuildStoryRecord(storyGroupId, currentIndex)
    local ret = {}
    if self._executor and self._executor.IsExecuting then
        local group,_ = self._executor:GetCurrentGroup()
        if group then
            group:BuildGroupRecord(storyGroupId, ret)
        end
    end
    StoryModuleHelper.BuildRecordFromDialogGroup(ret, storyGroupId, currentIndex)
    return ret
end

---@param t number @StoryDialogType
---@param parameter StoryDialogUIMediatorParameter
function StoryModule:OpenDialogMediatorByType(t, parameter, notCleanupPre)
    if not notCleanupPre then
        g_Game.UIManager:CloseByName(UIMediatorNames.StoryDialogUIMediator)
        g_Game.UIManager:CloseByName(UIMediatorNames.StoryDialogChatUIMediator)
        g_Game.UIManager:CloseByName(UIMediatorNames.StoryDialogChatThroughUIMediator)
    end
    if not t then
        return nil
    end
    g_Logger.Log("StoryModule:OpenDialogMediatorByType(%s, %s)", t, parameter._dialogGroupConfig:Id())
    if t == StoryDialogType.SmallAvatar then
        return g_Game.UIManager:Open(UIMediatorNames.StoryDialogChatUIMediator, parameter)
    elseif t == StoryDialogType.SmallAvatarThrough then
        return g_Game.UIManager:Open(UIMediatorNames.StoryDialogChatThroughUIMediator, parameter)
    elseif t == StoryDialogType.CharacterDrawing then
        return g_Game.UIManager:Open(UIMediatorNames.StoryDialogUIMediator, parameter)
    end
    g_Logger.Error("Unsupport dialogType:%d in StoryDialogGroup:%d", t, parameter._dialogGroupConfig:Id())
    return g_Game.UIManager:Open(UIMediatorNames.StoryDialogUIMediator, parameter)
end

---@param stageID number
---@param branchSelectID number
function StoryModule:CreateStoryChoiceProviderParamByBranchSelectID(data, vxGo)
    local stageID = ModuleRefer.WorldTrendModule:GetCurStage().Stage
    local branchSelectID =data.branchSelectID
    local boxID = data.RtBoxId
    local worldPos = data.worldPos

    local storyParameter = StoryDialogUIMediatorParameter.new()
    local provider = StoryDialogUIMediatorParameterChoiceProvider.new()
    local branchConfig = ConfigRefer.BranchSelect:Find(branchSelectID)
    if not branchConfig then
        return storyParameter
    end
    local defaultNpcConfig = ConfigRefer.CityElementNpc:Find(20118)
    if not defaultNpcConfig then
        return storyParameter
    end
    -- provider:InitForNpc(defaultNpcConfig)
    provider:InitCharacterImage(branchConfig:Name(), "")
    if branchConfig:HasBranch() then
        provider._dialogText = string.format("(%s)%s", I18N.Get("WorldStage_radartask_tips"), I18N.Get(branchConfig:Question()))
    else
        provider._dialogText = I18N.Get(branchConfig:Question())
    end
    local VoteStageAndRewardParameter = require("VoteStageAndRewardParameter")
    for i = 1, branchConfig:OptionsLength() do
        ---@type StoryDialogUIMediatorParameterChoiceProviderOption
        local option = {}
        option.showNumberPair = false
        option.showIsOnGoing = false
        option.content = I18N.Get(branchConfig:Options(i))
        option.type = StoryDialogUiOptionCellType.enum.Vote
        option.onClickOption = function()
            local msg = VoteStageAndRewardParameter.new()
            msg.args.StageId = stageID
            msg.args.BranchSelectConfigId = branchSelectID
            msg.args.OptionIdx = i
            msg.args.BoxId = boxID
            msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
				if (suc) then
                    --TODO 点赞后表现
                    if (Utils.IsNotNull(vxGo)) then
						vxGo:SetActive(false)
						vxGo.transform.position = worldPos
						vxGo:SetActive(true)
					end
				end
			end)
            
            return true
        end
        provider:AppendOption(option)
    end
    storyParameter:SetDelayTime(0.5)
    storyParameter:SetChoiceProvider(provider)
    return storyParameter
end

function StoryModule:CreateStoryChoiceProviderParam(data, vxGo)
    local boxID = data.RtBoxId
    local worldPos = data.worldPos

    local storyParameter = StoryDialogUIMediatorParameter.new()
    local provider = StoryDialogUIMediatorParameterChoiceProvider.new()
    local configInfo = ConfigRefer.MistEvent:Find(data.ConfigId)
    if not configInfo then
        return storyParameter
    end
    provider:InitCharacterImage(configInfo:Name(), "")
    provider._dialogText = I18N.Get(configInfo:Question())
    local ReceiveMistEventRewardParameter = require("ReceiveMistEventRewardParameter")
    for i = 1, configInfo:OptionsLength() do
        ---@type StoryDialogUIMediatorParameterChoiceProviderOption
        local option = {}
        option.showNumberPair = false
        option.showIsOnGoing = false
        option.content = I18N.Get(configInfo:Options(i))
        option.type = StoryDialogUiOptionCellType.enum.Box
        option.onClickOption = function()
            local msg = ReceiveMistEventRewardParameter.new()
            msg.args.MistId = boxID
            msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
				if (suc) then
                    if (Utils.IsNotNull(vxGo)) then
						vxGo:SetActive(false)
						vxGo.transform.position = worldPos
						vxGo:SetActive(true)
					end
				end
			end)
            
            return true
        end
        provider:AppendOption(option)
    end
    storyParameter:SetDelayTime(0.5)
    storyParameter:SetChoiceProvider(provider)
    return storyParameter
end

return StoryModule