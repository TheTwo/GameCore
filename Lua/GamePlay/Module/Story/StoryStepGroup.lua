local ConfigRefer = require("ConfigRefer")
local StoryStep = require("StoryStep")
local StartStoryCallbackResult = require("StartStoryCallbackResult")
local StoryModuleHelper = require("StoryModuleHelper")
local ModuleRefer = require("ModuleRefer")

---@class StoryStepGroup
---@field new fun():StoryStepGroup
---@field IsDone boolean
---@field HasError boolean
---@field IsExecuting boolean
---@field NoReportServerRun boolean
---@field private _steps StoryStep[]
---@field private _current number
---@field private _objects table<string, CS.UnityEngine.GameObject>
local StoryStepGroup = class('StoryStepGroup')
StoryStepGroup.FIRST_INDEX = 1
StoryStepGroup.DEFAULT_INDEX = 0

function StoryStepGroup:ctor()
    self.IsDone = false
    self.HasError = false
    self.IsExecuting = false
    ---@private
    ---@type table<string, any>
    self.ContextForSteps = {}
    
    self._id = 0
    self._name = ""
    self._steps = {}
    self._current = StoryStepGroup.DEFAULT_INDEX
    self._objects = {}

    ---@type fun(result:StartStoryCallbackResult)
    self._callback = nil
    self._fastForwardStopAt = nil
    self._fastForwardFlag = false
    self.sendStartAtBegining = false
    self.startSend = false
end

---@param storyTaskStepConfig StoryTaskStepConfig
---@param stepId number
---@param addTable table<StoryStep, number[]>[]
---@param indexTable table<number, number>
---@param stepIds table<number, boolean>
local function MakeStepSeq(storyTaskStepConfig, stepId, addTable, indexTable, stepIds)
    if stepIds[stepId] then
        return
    end
    stepIds[stepId] = true
    local storyTaskStepCell = storyTaskStepConfig:Find(stepId)
    if not storyTaskStepCell then
        g_Logger.Error("storyTaskStepCell is nil! id:%s", stepId)
        return
    end
    local step = StoryStep.new()
    local nextJumps = {}
    step:LoadConfig(storyTaskStepCell)
    table.insert(addTable, {step, nextJumps})
    indexTable[stepId] = #addTable
    local nextStepChoiceCount = storyTaskStepCell:NextStepIdLength()
    if nextStepChoiceCount >= 1 then
        for i = 1, nextStepChoiceCount do
            local nextStepId = storyTaskStepCell:NextStepId(i)
            table.insert(nextJumps, nextStepId)
            MakeStepSeq(storyTaskStepConfig, nextStepId, addTable, indexTable, stepIds)
        end
    end
end

---@param taskConfigCell StoryTaskConfigCell
---@param serverRecord wds.StoryInfo
function StoryStepGroup:BuildWithConfigAndServerData(taskConfigCell, serverRecord)
    self:ClearSteps()
    local storyTaskStepId = taskConfigCell:StoryTaskStepId()
    self._id = taskConfigCell:Id()
    self._name= taskConfigCell:Name()
    local storyTaskDescription= taskConfigCell:Description()
    g_Logger.TraceChannel(nil, "taskConfigCell startStep:%s, Name:%s, des:%s", storyTaskStepId, self._name, storyTaskDescription)
    local storyTaskStepConfig = ConfigRefer.StoryTaskStep
    if not storyTaskStepConfig then
        g_Logger.Error("ConfigRefer.StoryTaskStep is nil!")
        return
    end
    ---@type table<StoryStep, number[]>[]
    local addTable = {}
    ---@type table<number, number>
    local indexTable = {}
    ---@type table<number, boolean>
    local stepIds = {}
    MakeStepSeq(storyTaskStepConfig, storyTaskStepId, addTable, indexTable, stepIds)
    for index, step in ipairs(addTable) do
        ---@type StoryStep
        local s = step[1]
        ---@type number[]
        local jumpToIds = step[2]
        for _, jumpToId in ipairs(jumpToIds) do
            s:AddNextStepOffset(indexTable[jumpToId] - index)
        end
        s:CreateActions()
        self:AddStep(s)
    end
    if serverRecord then
        ---@type table<number, wds.StoryStepInfo>
        local stepInfos = serverRecord.StoryStepInfo
        if stepInfos then
            for _, step in ipairs(self._steps) do
                step:InitActionWithServerData(stepInfos[step.StepId])
            end
        end
    end
    if self:IsEmpty() then
        self.IsDone = true
        return
    end
    local checkIndex = StoryStepGroup.FIRST_INDEX
    local checkStep = self._steps[checkIndex]
    local selfIsDone = false
    while checkStep.IsDone do
        local nextJump = checkStep:GetTranslateOffset(true)
        if 0 == nextJump then
            selfIsDone = true
            break
        end
        checkIndex = checkIndex + nextJump
        checkStep = self._steps[checkIndex]
    end
    if selfIsDone then
        self.IsDone = true
    end
end

---@param step StoryStep
function StoryStepGroup:AddStep(step)
    if not step then
        return
    end
    if self.IsExecuting or self.IsDone then
        g_Logger.ErrorChannel("StoryStepGroup", "StoryStepGroup not editable for AddStep:%s", GetClassOf(step))
        return
    end
    step:AttachGroup(self)
    table.insert(self._steps, step)
end

function StoryStepGroup:ClearSteps()
    if self.IsExecuting then
        g_Logger.ErrorChannel("StoryStepGroup", "StoryStepGroup not editable for ClearSteps")
    end
    for _,step in ipairs(self._steps) do
        step:DetachGroup()
    end
    table.clear(self._steps)
end

function StoryStepGroup:Release(fromRelogin)
    for _, v in ipairs(self._steps) do
        v:ReleaseActions(fromRelogin)
    end
    self:ClearSteps()
end

function StoryStepGroup:Enter()
    if not self.startSend and self.sendStartAtBegining then
        self.startSend = true
        ModuleRefer.StoryModule:CheckLocalSendFlagAndSendStoryStart(self._id)
    end
    g_Logger.TraceChannel(nil, "StepGroupEnter")
    self.IsExecuting = true
    self:FastForwardStepThenStart()
end

---@return fun()[] @delayCleanUpFun
function StoryStepGroup:Leave()
    self.IsExecuting = false
    g_Logger.TraceChannel(nil, "StepGroupLeave")
    return self:LeaveCurrentStep()
end

function StoryStepGroup:Reset()
    for _,step in ipairs(self._steps) do
        step:Reset()
    end
end

function StoryStepGroup:FastForwardStepThenStart()
    local current = StoryStepGroup.FIRST_INDEX
    local step = self._steps[current]
    while step.IsDone do
        step:SetEndStatus(true)
        local offset = step:GetTranslateOffset(true)
        if 0 == offset then
            self.IsDone = true
            break
        else
            current = current + offset
            step = self._steps[current]
        end
    end
    self._current = current
    if not self.IsDone then
        self:TranslateStep(self._current)
    end
end

function StoryStepGroup:Execute()
    if self.IsDone or self.HasError then
        return
    end
    if StoryStepGroup.FIRST_INDEX  > self._current then
        g_Logger.ErrorChannel("StoryStepGroup", "error step Index:%d", self._current)
        return
    end
    local step = self._steps[self._current]
    if step.IsDone then
        step:SetEndStatus(false)
        local offset = step:GetTranslateOffset(true)
        if 0 == offset or nil == offset then
            self.IsDone = true
        else
            if self._fastForwardFlag then
                self:TryFastForwardTo(self._fastForwardStopAt, self._current + offset)
            else
                self:TranslateStep(self._current + offset)
            end
        end
    elseif step.IsFailure or step.HashError then
        local offset = step:GetTranslateOffset(false)
        if 0 == offset or nil == offset then
            self.HasError = true
        else
            self:TranslateStep(self._current + offset)
        end
    else
        step:Execute()
        if step.IsDone then
            g_Logger.Log("step Done fast forward next")
            step:SetEndStatus(false)
            local offset = step:GetTranslateOffset(true)
            if 0 == offset or nil == offset then
                self.IsDone = true
            else
                if self._fastForwardFlag then
                    self:TryFastForwardTo(self._fastForwardStopAt, self._current + offset)
                else
                    self:TranslateStep(self._current + offset)
                end
            end
        end
    end
end

---@param isRestore boolean
function StoryStepGroup:SetEndStatus(isRestore)
    if not self.IsDone then
        return
    end
    if not isRestore then
        return
    end
    for _, step in ipairs(self._steps) do
        step:SetEndStatus(true)
    end
end

function StoryStepGroup:FireEndCallback()
    g_Logger.Log("[%s]StoryStepGroup:FireEndCallback:%s", CS.UnityEngine.Time.renderedFrameCount ,self:Id())
    local callback = self._callback
    self._callback = nil
    if self.HasError then
        if callback then
            callback(StartStoryCallbackResult.Error)
        end
        return
    end
    if self.IsDone then
        if callback then
            callback(StartStoryCallbackResult.Success)
        end
    end
end

---@param index number
function StoryStepGroup:TranslateStep(index)
    local delayCleanUps = self:LeaveCurrentStep()
    self._current = index
    if StoryStepGroup.FIRST_INDEX <= self._current and self._current <= #self._steps then
        self._steps[self._current]:Enter()
    else
        self.HasError = true
    end
    for _, callback in ipairs(delayCleanUps) do
        callback()
    end
end

function StoryStepGroup:TryFastForwardTo(stopAt, startAt)
    local delayCleanUps = self:LeaveCurrentStep()
    for _, callback in ipairs(delayCleanUps) do
        callback()
    end
    self._current = startAt
    while StoryStepGroup.FIRST_INDEX <= self._current and self._current <= #self._steps do
        local step = self._steps[self._current]
        if step == stopAt then
            self._fastForwardFlag = false
            self._fastForwardStopAt = nil
            step:Enter()
            return
        end
        step:EndStep(true)
        if not self.NoReportServerRun then
            return
        end
        local offset = step:GetTranslateOffset(true)
        if not offset or offset == 0 then
            self.IsDone = true
            break
        end
        self._current = self._current + offset
    end
    self._fastForwardFlag = false
    self._fastForwardStopAt = nil
end

---@return fun()[] @delayCleanUpFun
function StoryStepGroup:LeaveCurrentStep()
    local ret = {}
    if StoryStepGroup.FIRST_INDEX <= self._current and self._current <= #self._steps then
        table.addrange(ret, self._steps[self._current]:Leave())
    end
    self._current = StoryStepGroup.DEFAULT_INDEX
    return ret
end

function StoryStepGroup:IsEmpty()
    return (not self._steps) or (#self._steps <= 0)
end

---@return number
function StoryStepGroup:Id()
    return self._id
end

---@return string
function StoryStepGroup:Name()
    return self._name
end

---@return StoryStep
function StoryStepGroup:GetCurrentStep()
    if self._steps and self._current > 0 and self._current <= #self._steps then
        return self._steps[self._current]
    end
    return nil
end

---@param key string
---@param target CS.UnityEngine.GameObject
function StoryStepGroup:AssignObject(key, target)
    self._objects[key] = target
end

---@param key string
---@return CS.UnityEngine.GameObject
function StoryStepGroup:RemoveObject(key)
    local ret = self._objects[key]
    self._objects[key] = nil
    return ret
end

---@param key StoryActionConst.StepContextKey
---@param value any
---@return any
function StoryStepGroup:WriteContext(key, value)
    local last = self.ContextForSteps[key]
    self.ContextForSteps[key] = value
    return last
end

---@param key StoryActionConst.StepContextKey
---@param keep boolean
---@return any
function StoryStepGroup:ReadContext(key, keep)
    local last = self.ContextForSteps[key]
    if not keep then
        self.ContextForSteps[key] = nil
    end
    return last
end

---@return boolean, StoryStep
function StoryStepGroup:BuildGroupSummary(storyDialogGroupId, arrayToAdd)
    if not self._steps then
        return false, nil
    end
    local movieType = require("StoryStepActionMovie")
    local dialogType = require("StoryStepActionDialog")
    local findInStep = false
    local tempArray = {}
    local stopAtStep = nil
    local index = 1
    local stepCount = #self._steps
    local loopCount = 0
    while index > StoryStepGroup.DEFAULT_INDEX and index <= stepCount and loopCount <= loopCount do
        loopCount = loopCount + 1
        local step = self._steps[index]
        local stopLoop = false
        step:ForeachAction(function(action)
            if action:IsType(movieType) then
                stopLoop = true
                stopAtStep = step
                return false
            end
            if action:IsType(dialogType) then
                ---@type StoryStepActionDialog
                local dAction = action
                local dialogGroupId = dAction:GetDialogGroupId()
                if dialogGroupId then
                    if dialogGroupId == storyDialogGroupId then
                        findInStep = true
                    end
                    table.insert(tempArray, dialogGroupId)
                    return false
                end
            end
            return true
        end)
        if stopLoop then
            break
        end
        local offset = step:GetTranslateOffset(true)
        if not offset or offset == 0 then
            break
        end
        index = index + offset
    end
    if not findInStep then
        return false, nil
    end
    for _, v in ipairs(tempArray) do
        local dialogGroupConfig = ConfigRefer.StoryDialogGroup:Find(v)
        if dialogGroupConfig then
            local config = ConfigRefer.StoryDialogGroupSummary:Find(dialogGroupConfig:Summary())
            if config then
                table.insert(arrayToAdd, config:Content())
            end
        end
    end
    return true, stopAtStep
end

function StoryStepGroup:MarkFastForwardStory(stopAt)
    self._fastForwardStopAt = stopAt
    self._fastForwardFlag = true
end

---@param storyDialogGroupId number
---@param arrayToAdd StoryDialogRecordCellData[]
---@return boolean
function StoryStepGroup:BuildGroupRecord(storyDialogGroupId, arrayToAdd)
    if not self._steps then
        return false, nil
    end
    local dialogType = require("StoryStepActionDialog")
    local captionType = require("StoryStepActionCaption")
    local choiceType = require("StoryStepActionChoice")
    local findInStep = false
    ---@type StoryDialogRecordCellData[]
    local tempArray = {}
    local index = 1
    local stepCount = #self._steps
    local loopCount = 0
    while index > StoryStepGroup.DEFAULT_INDEX and index <= stepCount and loopCount <= stepCount do
        loopCount = loopCount + 1
        local step = self._steps[index]
        local stopLoop = false
        step:ForeachAction(function(action)
            if action:IsType(dialogType) then
                ---@type StoryStepActionDialog
                local dAction = action
                local dialogGroupId = dAction:GetDialogGroupId()
                if dialogGroupId then
                    if dialogGroupId == storyDialogGroupId then
                        stopLoop = true
                        findInStep = true
                        return false
                    end
                    return not StoryModuleHelper.BuildRecordFromDialogGroup(tempArray, dialogGroupId, 99999)
                end
            end
            if action:IsType(choiceType) then
                ---@type StoryStepActionChoice
                local cAction = action
                return not StoryModuleHelper.BuildRecordFromChoice(tempArray, cAction:GetChoiceConfigId(), cAction:GetChoice())
            end
            if action:IsType(captionType) then
                ---@type StoryStepActionCaption
                local cAction = action
                local captionConfigId = cAction:GetCaptionConfigId()
                return not StoryModuleHelper.BuildRecordFromCaptionConfig(tempArray, captionConfigId)
            end
            return true
        end)
        if stopLoop then
            break
        end
        local offset = step:GetTranslateOffset(true)
        if not offset or offset == 0 then
            break
        end
        index = index + offset
    end
    if not findInStep then
        return false
    end
    for _, v in ipairs(tempArray) do
        table.insert(arrayToAdd, v)
    end
    return true
end

return StoryStepGroup