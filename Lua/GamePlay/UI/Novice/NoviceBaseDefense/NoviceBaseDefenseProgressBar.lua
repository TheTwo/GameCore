local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
---@class NoviceBaseDefenseComponent : BaseUIComponent
local NoviceBaseDefenseProgressBar = class('NoviceBaseDefenseProgressBar', BaseUIComponent)

function NoviceBaseDefenseProgressBar:OnCreate()
    self.textProgressReward = self:Text('p_text_progress_reward', I18N.Get('*达成进度可得奖励'))
    self.btnRewardUp = self:Button('child_comp_btn_e_l', Delegate.GetOrCreate(self, self.OnBtnChildCompELClicked))
    self.textRewardUp = self:Text('p_text_e', I18N.Get('*奖励升级'))
    self.tableviewproRewardUp = self:TableViewPro('p_table_reward')
    self.sliderProgress = self:Slider('p_progress')
end

function NoviceBaseDefenseProgressBar:OnShow()
    -- body
end

function NoviceBaseDefenseProgressBar:OnBtnChildCompELClicked(args)
    -- body
end

return NoviceBaseDefenseProgressBar