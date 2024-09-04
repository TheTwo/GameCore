local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local KingdomMapUtils = require('KingdomMapUtils')
local EventConst = require('EventConst')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local WorldTrendDefine = require("WorldTrendDefine")
local UIHelper = require("UIHelper")
local KingdomTaskOperationParameter = require("KingdomTaskOperationParameter")
local ColorConsts = require('ColorConsts')

---@class WorldTrendGlobalTask : BaseUIComponent
local WorldTrendGlobalTask = class('WorldTrendGlobalTask', BaseUIComponent)

function WorldTrendGlobalTask:ctor()

end

function WorldTrendGlobalTask:OnCreate()
    self.textSubTitle = self:Text('p_text_global_subtitle')
    self.textTask = self:Text('p_text_global_task')

    self.textSchedule = self:Text('p_text_global_schedule')
    self.tableviewproRewards = self:TableViewPro('p_table_global_rewards')

    self.goFinished = self:GameObject('p_icon_global_finished')
    self.textFinishedTime = self:Text('p_text_global_time')

    self.textGlobalTips = self:Text('p_text_global_tip')

    self.btnGoto = self:Button('p_btn_goto_global_task', Delegate.GetOrCreate(self, self.OnClickGoto))
    self.btnClaim = self:Button('p_btn_claim_global_task', Delegate.GetOrCreate(self, self.OnClickClaimTask))
    self.textClaimAlliance = self:Text('p_text_claim_global_task', I18N.Get("task_btn_claim"))
end

function WorldTrendGlobalTask:OnShow()
    g_Game.ServiceManager:AddResponseCallback(KingdomTaskOperationParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
end

function WorldTrendGlobalTask:OnHide()
    g_Game.ServiceManager:RemoveResponseCallback(KingdomTaskOperationParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
end

---@param param WorldTrendTaskParam
function WorldTrendGlobalTask:OnFeedData(param)
    if not param then
        return
    end

    self.taskID = param.taskID
    self.stage = param.stage

    self.taskCfg = ConfigRefer.KingdomTask:Find(self.taskID)
    if not self.taskCfg then
        return
    end
    self.stageConfig = ConfigRefer.WorldStage:Find(self.stage)
    if not self.stageConfig then
        return
    end
    self.textSubTitle.text = I18N.Get("WorldStage_info_servers")
    if self.stageConfig:OpenAhead() then
        self.textGlobalTips.gameObject:SetActive(true)
        self.textGlobalTips.text = I18N.Get("WorldStage_info_next_stage")
    else
        self.textGlobalTips.gameObject:SetActive(false)
    end
    
    local cur, total = ModuleRefer.WorldTrendModule:GetKingdomTaskSchedule(self.taskID)
    local curStr = tostring(cur)
    local totalStr = tostring(total)
    if cur < total then
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.warning)
    else
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.quality_green)
    end
    local taskDescStr = ModuleRefer.WorldTrendModule:GetTaskDesc(self.taskCfg, WorldTrendDefine.TASK_TYPE.Global)
    self.textSchedule.text = string.format("<b>(%s/%s)</b>%s", curStr, totalStr, taskDescStr)
    self.textTask.text = I18N.Get(param.desc)

    self.state = ModuleRefer.WorldTrendModule:GetKingdomTaskState_WorldTrendTaskState(self.taskID)
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

    -- TODO ShowLine
end

function WorldTrendGlobalTask:ShowFinishTime()
    self.goFinished:SetVisible(true)
    self.btnClaim:SetVisible(false)
    self.btnGoto:SetVisible(false)
    self.textFinishedTime.text = ModuleRefer.WorldTrendModule:GetKingdomTaskFinishTimeStr(self.taskID)
end

function WorldTrendGlobalTask:ShowRewardIcon()
    self.goFinished:SetActive(false)
    self.btnClaim:SetVisible(true)
    self.btnGoto:SetVisible(false)
end

function WorldTrendGlobalTask:ShowProcessing()
    self.goFinished:SetActive(false)
    self.btnClaim:SetVisible(false)
    self.btnGoto:SetVisible(true)
end

function WorldTrendGlobalTask:OnClickGoto()
    local taskProp = self.taskCfg:Property()
	g_Game.UIManager:Close(self:GetCSUIMediator().RuntimeId)
    require('GuideUtils').GotoByGuide(taskProp:Goto(), true)
end

function WorldTrendGlobalTask:OnClickClaimTask()
    if self.state ~= WorldTrendDefine.TASK_STATE.CanReward then
        return
    end
    local operationParameter = KingdomTaskOperationParameter.new()
    operationParameter.args.Op = wrpc.TaskOperation.TaskOpGetReward
    operationParameter.args.CID = self.taskID
    operationParameter:Send(self.btnClaim.transform)
end

function WorldTrendGlobalTask:OnClaimReward(isSuccess, reply, rpc)
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

function WorldTrendGlobalTask:UpdateReward()
    if self.rewardData then
        for k, v in ipairs(self.rewardData) do
            v.received = self.state == WorldTrendDefine.TASK_STATE.Rewarded
            self.tableviewproRewards:UpdateData(v)
        end
    end
end

return WorldTrendGlobalTask
