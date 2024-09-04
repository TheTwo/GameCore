local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local KingdomMapUtils = require('KingdomMapUtils')
local EventConst = require('EventConst')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local WorldTrendDefine = require("WorldTrendDefine")
local UIHelper = require("UIHelper")
local AllianceTaskOperationParameter = require("AllianceTaskOperationParameter")
local ColorConsts = require('ColorConsts')

---@class WorldTrendAllianceTask : BaseUIComponent
local WorldTrendAllianceTask = class('WorldTrendAllianceTask', BaseUIComponent)


function WorldTrendAllianceTask:ctor()

end

function WorldTrendAllianceTask:OnCreate()
    self.textSubTitle = self:Text('p_text_alliance_subtitle', I18N.Get("WorldStage_info_alliance"))
    self.textTask = self:Text('p_text_alliance_task')

    self.tableviewproRewards = self:TableViewPro('p_table_alliance_rewards')

    self.goFinished = self:GameObject('p_icon_alliance_finished')
    self.textFinishedTime = self:Text('p_text_alliance_time')

    self.btnGotoAlliance = self:Button('p_btn_goto_alliance', Delegate.GetOrCreate(self, self.OnClickGotoAllianceTask))
    self.btnClaimAlliance = self:Button('p_btn_claim_alliance', Delegate.GetOrCreate(self, self.OnClickClaimAllianceTask))
    self.textClaimAlliance = self:Text('p_text_claim_alliance', I18N.Get("task_btn_claim"))
end

function WorldTrendAllianceTask:OnShow()
    g_Game.ServiceManager:AddResponseCallback(AllianceTaskOperationParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
end

function WorldTrendAllianceTask:OnHide()
    g_Game.ServiceManager:RemoveResponseCallback(AllianceTaskOperationParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimReward))
end

---@param param WorldTrendTaskParam
function WorldTrendAllianceTask:OnFeedData(param)
    if not param then
        return
    end

    self.taskID = param.taskID
    self.stage = param.stage
    
    self.taskCfg = ConfigRefer.AllianceTask:Find(self.taskID)
    if not self.taskCfg then
        return
    end
    -- self.textSubTitle.text = I18N.Get(taskProperty:Name())
    local taskDescStr = ModuleRefer.WorldTrendModule:GetTaskDesc(self.taskCfg, WorldTrendDefine.TASK_TYPE.Alliance)
    local cur, total = ModuleRefer.WorldTrendModule:GetAllianceTaskSchedule(self.taskID)
    local curStr = tostring(cur)
    local totalStr = tostring(total)
    if cur < total then
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.warning)
    else
        curStr = UIHelper.GetColoredText(curStr, ColorConsts.quality_green)
    end
    if total == 0 then
        totalStr = "X"
    end
    self.textTask.text = string.format("<b>(%s/%s)</b>%s", curStr, totalStr, taskDescStr)

    self.state = ModuleRefer.WorldTrendModule:GetAllianceTaskState_WorldTrendTaskState(self.taskID)
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

function WorldTrendAllianceTask:OnClickGotoAllianceTask()
    local taskProp = self.taskCfg:Property()
	g_Game.UIManager:Close(self:GetCSUIMediator().RuntimeId)
    require('GuideUtils').GotoByGuide(taskProp:Goto(), true)
end

function WorldTrendAllianceTask:OnClickClaimAllianceTask()
    if self.state ~= WorldTrendDefine.TASK_STATE.CanReward then
        return
    end
    local operationParameter = AllianceTaskOperationParameter.new()
    operationParameter.args.Op = wrpc.TaskOperation.TaskOpGetReward
    operationParameter.args.CID = self.taskID
    operationParameter:Send(self.btnClaimAlliance.transform)
end

function WorldTrendAllianceTask:ShowFinishTime()
    self.goFinished:SetActive(true)
    self.btnClaimAlliance.gameObject:SetActive(false)
    self.btnGotoAlliance:SetVisible(false)
    self.textFinishedTime.text = ModuleRefer.WorldTrendModule:GetAllianceTaskFinishTimeStr(self.taskID)
end

function WorldTrendAllianceTask:ShowRewardIcon()
    self.goFinished:SetActive(false)
    self.btnClaimAlliance.gameObject:SetActive(true)
    self.btnGotoAlliance:SetVisible(false)
end

function WorldTrendAllianceTask:ShowProcessing()
    self.goFinished:SetActive(false)
    self.btnClaimAlliance.gameObject:SetActive(false)
    self.btnGotoAlliance:SetVisible(true)
end

function WorldTrendAllianceTask:OnClaimReward(isSuccess, reply, rpc)
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

function WorldTrendAllianceTask:UpdateReward()
    if self.rewardData then
        for k, v in ipairs(self.rewardData) do
            v.received = self.state == WorldTrendDefine.TASK_STATE.Rewarded
            self.tableviewproRewards:UpdateData(v)
        end
    end
end

return WorldTrendAllianceTask
