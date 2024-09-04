local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local PlayerTaskOperationParameter = require("PlayerTaskOperationParameter")
local GuideUtils = require('GuideUtils')
local NoviceConst = require('NoviceConst')
---@class NoviceTaskItemCell : BaseTableViewProCell
local NoviceTaskItemCell = class('NoviceTaskItemCell', BaseTableViewProCell)

function NoviceTaskItemCell:OnCreate()
    self.tableRewards = self:TableViewPro('p_table_rewards')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.textGoto = self:Text('p_text_goto', NoviceConst.I18NKeys.BTN_GOTO)
    self.btnClaim = self:Button('p_btn_claim', Delegate.GetOrCreate(self, self.OnBtnClaimClicked))
    self.textClaim = self:Text('p_text_claim', NoviceConst.I18NKeys.BTN_CLAIM)
    self.btnGray = self:Button('p_btn_gray', Delegate.GetOrCreate(self, self.OnBtnGrayClicked))
    self.textGray = self:Text('p_text_gray', NoviceConst.I18NKeys.BTN_CLAIM)
    self.imgClaimed = self:Image('p_claimed')

    self.btnVisibleControl = {}
    self.btnVisibleControl[wds.TaskState.TaskStateReceived] = {self.btnGoto.gameObject, self.btnGray.gameObject}
    self.btnVisibleControl[wds.TaskState.TaskStateCanFinish] = {self.btnClaim.gameObject}
    self.btnVisibleControl[wds.TaskState.TaskStateFinished] = {self.imgClaimed.gameObject}

end

function NoviceTaskItemCell:OnFeedData(param)
    if not param then
        return
    end
    self.taskId = param.taskId
    self.taskCfg = ConfigRefer.Task:Find(self.taskId)
    local btnVisionControlSubStatus = 1
    local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(self.taskId)
    if self.taskCfg:Property():Goto() == 0 then
        btnVisionControlSubStatus = 2
    end
    self:SetBtnVisible(taskState, btnVisionControlSubStatus)

    local rewardList = ModuleRefer.QuestModule.Chapter:GetQuestRewards(self.taskCfg)
    self.tableRewards:Clear()
    for _, reward in ipairs(rewardList) do
        local data = {}
        data.configCell = ConfigRefer.Item:Find(reward:Items())
        data.count = reward:Nums()
        data.showTips = true
        self.tableRewards:AppendData(data)
    end
end

function NoviceTaskItemCell:SetBtnVisible(taskState, btnType)
    for state, btns in pairs(self.btnVisibleControl) do
        if #btns <= 1 then
            btns[1]:SetActive(taskState == state)
        else
            for i = 1, #btns do
                btns[i]:SetActive(taskState == state and i == btnType)
            end
        end
    end
end

function NoviceTaskItemCell:OnBtnGotoClicked()
    local taskProp = self.taskCfg:Property()
	g_Game.UIManager:Close(self:GetCSUIMediator().RuntimeId)
    GuideUtils.GotoByGuide(taskProp:Goto(), true)
end

function NoviceTaskItemCell:OnBtnClaimClicked()
    local operationParameter = PlayerTaskOperationParameter.new()
	operationParameter.args.Op = wrpc.TaskOperation.TaskOpGetReward
	operationParameter.args.CID = self.taskId
	operationParameter:Send(self.btnClaim.transform)
end

return NoviceTaskItemCell