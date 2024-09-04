local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local GuideUtils = require('GuideUtils')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')

---@class TouchMenuCellNpcTask:BaseUIComponent
local TouchMenuCellNpcTask = class('TouchMenuCellNpcTask', BaseUIComponent)

function TouchMenuCellNpcTask:OnCreate()
    self.textMission = self:Text('p_text_mission')
    self.goIconFinish = self:GameObject('p_icon_finish')
    self.goBase = self:GameObject('base')
    self.goIconItem = self:GameObject('icon_item')
    self.goBaseNum = self:GameObject('base_num')
    self.textNumber = self:Text('p_text_number')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
end

---@param data TouchMenuCellNpcTaskDatum
function TouchMenuCellNpcTask:OnFeedData(data)
    self.taskId = data.taskId
    local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(self.taskId)
    local isFinished = taskState == wds.TaskState.TaskStateFinished
    self.goIconFinish:SetActive(isFinished)
    self.textMission.text = ModuleRefer.QuestModule:GetTaskDescWithProgress(self.taskId)
    local count = ModuleRefer.QuestModule.Chapter:GetItemRewardCountById(self.taskId, ConfigRefer.ConstMain:CityExpItem())
    self.goBase:SetActive(count > 0)
    self.goIconItem:SetActive(count > 0)
    self.goBaseNum:SetActive(count > 0)
    self.textNumber.gameObject:SetActive(count > 0)
    self.textNumber.text = count
    self.gotoId = ModuleRefer.QuestModule:GetTaskGotoID(self.taskId)
    self.btnGoto.gameObject:SetActive(self.gotoId and self.gotoId > 0 and not isFinished)
end

function TouchMenuCellNpcTask:OnBtnGotoClicked(args)
    local UIMediatorNames = require('UIMediatorNames')
    g_Game.UIManager:CloseByName(UIMediatorNames.TouchMenuUIMediator)
    GuideUtils.GotoByGuide(self.gotoId,true)
end

return TouchMenuCellNpcTask