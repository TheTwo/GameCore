local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local GuideUtils = require('GuideUtils')
local Delegate = require('Delegate')

local QuestTaskNeedCell = class('QuestTaskNeedCell',BaseTableViewProCell)

function QuestTaskNeedCell:OnCreate(param)
    self.textItem = self:Text('p_text_item')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.goClaimed = self:GameObject('p_claimed')
    self.animationTrigger = self:AnimTrigger("trigger_need")
end

function QuestTaskNeedCell:OnHide()
    self.playedShow = false
end


function QuestTaskNeedCell:OnFeedData(data)
    self.taskId = data.taskId
    self.textItem.text = ModuleRefer.QuestModule:GetTaskDescWithProgress(self.taskId)
    local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(self.taskId)
    local isFinished = taskState == wds.TaskState.TaskStateFinished
    self.btnGoto.gameObject:SetActive(not isFinished)
    self.goClaimed:SetActive(isFinished)
    if not self.playedShow then
        self.playedShow = true
        self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
end

function QuestTaskNeedCell:OnBtnGotoClicked(args)
    self:GetParentBaseUIMediator():BackToPrevious()
    local gotoId = ModuleRefer.QuestModule:GetTaskGotoID(self.taskId)
    GuideUtils.GotoByGuide(gotoId,true)
end

return QuestTaskNeedCell
