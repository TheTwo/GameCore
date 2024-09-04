local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local GuideUtils = require("GuideUtils")
local LayoutRebuilder = CS.UnityEngine.UI.LayoutRebuilder

local PetCollectionPhotoDetailStudyComp = class('PetCollectionPhotoDetailStudyComp', BaseTableViewProCell)

function PetCollectionPhotoDetailStudyComp:OnCreate()
    self.p_text_study_name = self:Text('p_text_study_name')
    self.p_text_goal_now = self:Text('p_text_goal_now')

    self.p_text_goal_1 = self:Text('p_text_goal_1')
    self.p_text_goal_2 = self:Text('p_text_goal_2')
    self.p_text_goal_3 = self:Text('p_text_goal_3')
    self.p_text_goal_4 = self:Text('p_text_goal_4')
    self.p_text_goal_5 = self:Text('p_text_goal_5')

    self.p_icon_check_1 = self:GameObject('p_icon_check_1')
    self.p_icon_check_2 = self:GameObject('p_icon_check_2')
    self.p_icon_check_3 = self:GameObject('p_icon_check_3')
    self.p_icon_check_4 = self:GameObject('p_icon_check_4')
    self.p_icon_check_5 = self:GameObject('p_icon_check_5')

    self.p_goal_1 = self:GameObject('p_goal_1')
    self.p_goal_2 = self:GameObject('p_goal_2')
    self.p_goal_3 = self:GameObject('p_goal_3')
    self.p_goal_4 = self:GameObject('p_goal_4')
    self.p_goal_5 = self:GameObject('p_goal_5')

    self.p_text_study_name_1 = self:Text('p_text_study_name_1')
    self.p_progress = self:Slider('p_progress')
    self.textGoals = {self.p_text_goal_1, self.p_text_goal_2, self.p_text_goal_3, self.p_text_goal_4, self.p_text_goal_5}
    self.iconChecks = {self.p_icon_check_1, self.p_icon_check_2, self.p_icon_check_3, self.p_icon_check_4, self.p_icon_check_5}
    self.goals = {self.p_goal_1, self.p_goal_2, self.p_goal_3, self.p_goal_4, self.p_goal_5}

end

function PetCollectionPhotoDetailStudyComp:OnShow()
end

function PetCollectionPhotoDetailStudyComp:OnHide()
end

function PetCollectionPhotoDetailStudyComp:OnFeedData(param)
    if not param then
        return
    end
    self.researchType = param:Typo()
    self.p_text_study_name.text = I18N.Get(param.desc)
    self.p_text_goal_now.text = param.ResearchValue

    local maxAddPoint = 0
    local curAddPoint = 0

    local count = 0
    -- local progressMax = 0
    local curMaxProgress = 0

    local num = param:ItemsLength()
    for i = 1, 5 do
        self.goals[i]:SetVisible(i <= num)
    end

    for i = 1, num do
        local need = param:Items(i):Need()
        local addPoint = param:Items(i):AddPoint()
        self.textGoals[i].text = need
        local isComplete = param.ResearchProcess and param.ResearchProcess.TopicProcess[i - 1] or false
        self.iconChecks[i]:SetVisible(isComplete)
        maxAddPoint = maxAddPoint + addPoint
        if isComplete then
            curAddPoint = curAddPoint + addPoint
            count = count + 1
            curMaxProgress = need
        end
    end

    local maxProgress = param:Items(num):Need()
    self.p_text_study_name_1.text = curAddPoint .. "/" .. maxAddPoint
    local progress = (count - 1) / (num - 1)
    local div = param.ResearchValue - curMaxProgress
    progress = progress + div / maxProgress
    self.p_progress.value = progress

end

return PetCollectionPhotoDetailStudyComp
