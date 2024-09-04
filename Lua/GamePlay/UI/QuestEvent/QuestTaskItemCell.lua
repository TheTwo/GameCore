local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local GuideUtils = require('GuideUtils')
local Delegate = require('Delegate')

local QuestTaskItemCell = class('QuestTaskItemCell',BaseTableViewProCell)

function QuestTaskItemCell:OnCreate(param)
    self.animationTrigger = self:AnimTrigger("p_root")
    self.textItem = self:Text('p_text_item')
    self.compChildItemStandardS = self:LuaObject('child_item_standard_s')
    self.goClaimed = self:GameObject('p_claimed')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
end

function QuestTaskItemCell:OnFeedData(data)
    self.data = data
    self.textItem.text = ModuleRefer.QuestModule:GetTaskDescWithProgress(self.data.taskId)
    self.goClaimed:SetActive(data.isFinished)
    self.isNew = data.isNew
    if self.isNew then
        self.isNew = false
        self.animationTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
    local itemId = ConfigRefer.ConstMain:CityExpItem()
    local number = ModuleRefer.QuestModule.Chapter:GetItemRewardCountById(self.data.taskId, itemId)
    self.compChildItemStandardS:SetVisible(number > 0)
    if number > 0 then
        local itemData = {}
        itemData.configCell = ConfigRefer.Item:Find(itemId)
        itemData.count = number
        self.compChildItemStandardS:FeedData(itemData)
    end
    self.gotoId = ModuleRefer.QuestModule:GetTaskGotoID(self.data.taskId)
    self.btnGoto.gameObject:SetActive(self.gotoId and self.gotoId > 0 and not data.isFinished)
end

function QuestTaskItemCell:OnBtnGotoClicked(args)
    self:GetParentBaseUIMediator():BackToPrevious()
    GuideUtils.GotoByGuide(self.gotoId,true)
end

return QuestTaskItemCell
