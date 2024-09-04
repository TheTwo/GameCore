local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local I18N = require('I18N')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local NodeConditionCell = class('NodeConditionCell',BaseTableViewProCell)

function NodeConditionCell:OnCreate(param)
    self.btnItemSkill = self:Button('', Delegate.GetOrCreate(self, self.OnBtnItemSkillClicked))
    self.imgIconSkill = self:Image('p_icon_skill')
    self.textNameSkill = self:Text('p_text_name_skill')
    self.goReach = self:GameObject('p_icon_reach')
    self.goImg = self:GameObject('img')
    self.compProgress = self:LuaObject('p_text_progress')
end

function NodeConditionCell:OnFeedData(data)
    self.data = data
    g_Game.SpriteManager:LoadSprite(data.icon, self.imgIconSkill)
    self.textNameSkill.text = I18N.Get(data.name)
    local isFinish = data.curNum >= data.totalNum
    self.goReach:SetActive(isFinish)
    self.goImg:SetActive(not isFinish)

    local temp = {}
    temp.num1 = data.curProgess
    temp.num2 = data.totalProgress
    temp.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
    self.compProgress:FeedData(temp)
end

function NodeConditionCell:OnBtnItemSkillClicked(args)
    if self.data.onClick then
        self.data.onClick()
    end
end

return NodeConditionCell
