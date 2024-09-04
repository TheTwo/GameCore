local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local KingdomMapUtils = require('KingdomMapUtils')
local EventConst = require('EventConst')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local WorldTrendDefine = require("WorldTrendDefine")
local TaskOperationParameter = require("PlayerTaskOperationParameter")
local UIHelper = require("UIHelper")
local PlayerTaskFinishTimeParameter = require("PlayerTaskFinishTimeParameter")
local TimeFormatter = require("TimeFormatter")
local ColorConsts = require('ColorConsts')

---@class WorldTrendPersonalTask : BaseUIComponent
local WorldTrendPersonalTask = class('WorldTrendPersonalTask', BaseUIComponent)

---@class WorldTrendTaskParam
---@field taskID number
---@field stage number


function WorldTrendPersonalTask:ctor()

end

function WorldTrendPersonalTask:OnCreate()
    self.textSubTitle = self:Text('p_text_personal_subtitle', I18N.Get("WorldStage_info_personal"))
    self.textTask = self:Text('p_text_personal_task')

    self.tableviewproRewards = self:TableViewPro('p_table_personnal_rewards')

    self.goFinished = self:GameObject('p_icon_personal_finished')
    self.textFinishedTime = self:Text('p_text_personnal_time')

    self.btnGotoPersonal = self:Button('p_btn_goto_personal', Delegate.GetOrCreate(self, self.OnClickGotoPersonalTask))
    self.btnClaimPersonal = self:Button('p_btn_claim_personal', Delegate.GetOrCreate(self, self.OnClickClaimPersonalTask))
    self.textClaimPersonal = self:Text('p_text_claim_personal', I18N.Get("task_btn_claim"))
end

function WorldTrendPersonalTask:OnShow()
    g_Game.ServiceManager:AddResponseCallback(TaskOperationParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
    
    if ModuleRefer.WorldTrendModule:GetPersonalTaskFinishTimeStr(self.taskID) == nil then
        g_Game.ServiceManager:AddResponseCallback(PlayerTaskFinishTimeParameter.GetMsgId(), Delegate.GetOrCreate(self, self.UpdateRewardTime))
    end
end

function WorldTrendPersonalTask:OnHide()
    g_Game.ServiceManager:RemoveResponseCallback(TaskOperationParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
    g_Game.ServiceManager:RemoveResponseCallback(PlayerTaskFinishTimeParameter.GetMsgId(), Delegate.GetOrCreate(self, self.UpdateRewardTime))
end

---@param param WorldTrendTaskParam
function WorldTrendPersonalTask:OnFeedData(param)
    if not param then
        return
    end

    self.taskID = param.taskID
    self.stage = param.stage
    self.taskCfg = ConfigRefer.Task:Find(self.taskID)
    if not self.taskCfg then
        return
    end
    -- self.textSubTitle.text = I18N.Get(taskProperty:Name())
    local taskDescStr = ModuleRefer.WorldTrendModule:GetTaskDesc(self.taskCfg, WorldTrendDefine.TASK_TYPE.Personal)
    local cur, total = ModuleRefer.WorldTrendModule:GetPersonalTaskSchedule(self.taskID)
    local curStr = tostring(cur)
    local totalStr = tostring(total)
    if cur < total then
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.warning)
    else
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.quality_green)
    end
    self.textTask.text = string.format("<b>(%s/%s)</b>%s", curStr, totalStr, taskDescStr)

    self.state = ModuleRefer.WorldTrendModule:GetPersonalTaskState(self.taskID)
    if self.state == WorldTrendDefine.TASK_STATE.Rewarded then
        self:ShowFinishTime()
    elseif self.state == WorldTrendDefine.TASK_STATE.CanReward then
        self:ShowRewardIcon()
    else
        self:ShowProcessing()
    end

    local rewardList = ModuleRefer.WorldTrendModule:GetTaskRewards(self.taskCfg)
    if not rewardList then
        return
    end
    self.tableviewproRewards:Clear()
    self.rewardData = {}
    for _, reward in ipairs(rewardList) do
        local data = {}
        data.configCell = ConfigRefer.Item:Find(reward:Items())
        data.count = reward:Nums()
        data.showTips = true
        data.received = self.state == WorldTrendDefine.TASK_STATE.Rewarded
        table.insert(self.rewardData, data)
        self.tableviewproRewards:AppendData(data)
    end

    --TODO ShowLine
end

function WorldTrendPersonalTask:OnClickGotoPersonalTask()
    local taskProp = self.taskCfg:Property()
	g_Game.UIManager:Close(self:GetCSUIMediator().RuntimeId)
    require('GuideUtils').GotoByGuide(taskProp:Goto(), true)
end

function WorldTrendPersonalTask:OnClickClaimPersonalTask()
    if self.state ~= WorldTrendDefine.TASK_STATE.CanReward then
        return
    end
    local operationParameter = TaskOperationParameter.new()
    operationParameter.args.Op = wrpc.TaskOperation.TaskOpGetReward
    operationParameter.args.CID = self.taskID
    operationParameter:Send(self.btnClaimPersonal.transform)
end

function WorldTrendPersonalTask:ShowFinishTime()
    self.goFinished:SetActive(true)
    self.btnClaimPersonal.gameObject:SetActive(false)
    self.btnGotoPersonal:SetVisible(false)
    local parameter = PlayerTaskFinishTimeParameter.new()
    parameter.args.TaskID = self.taskID
    parameter:Send()
    self.textFinishedTime.text = ModuleRefer.WorldTrendModule:GetPersonalTaskFinishTimeStr(self.taskID)
end

function WorldTrendPersonalTask:ShowRewardIcon()
    self.goFinished:SetActive(false)
    self.btnClaimPersonal.gameObject:SetActive(true)
    self.btnGotoPersonal:SetVisible(false)
end

function WorldTrendPersonalTask:ShowProcessing()
    self.goFinished:SetActive(false)
    self.btnClaimPersonal.gameObject:SetActive(false)
    self.btnGotoPersonal:SetVisible(true)
end

function WorldTrendPersonalTask:OnClaimReward(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    if rpc.request and rpc.request.CID == self.taskID then
        if self.state == WorldTrendDefine.TASK_STATE.CanReward then
            self.state = WorldTrendDefine.TASK_STATE.Rewarded
            self:ShowFinishTime()
            self:UpdateReward()
            g_Game.EventManager:TriggerEvent(EventConst.WORLD_TREND_REWARD, self.stage)
        end
    end
end

function WorldTrendPersonalTask:UpdateRewardTime(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    if rpc.request and rpc.request.TaskID == self.taskID then
        if reply and reply.FinishTimestamp > 0 then
            local res = TimeFormatter.TimeToDateTimeStringUseFormat(reply.FinishTimestamp, "yyyy/MM/dd")
            ModuleRefer.WorldTrendModule:SetPersonalTaskFinishTimeStr(self.taskID,res)
            self.textFinishedTime.text = res
        end
    end
end

function WorldTrendPersonalTask:UpdateReward()
    if self.rewardData then
        for k, v in ipairs(self.rewardData) do
            v.received = self.state == WorldTrendDefine.TASK_STATE.Rewarded
            self.tableviewproRewards:UpdateData(v)
        end
    end
end

return WorldTrendPersonalTask
