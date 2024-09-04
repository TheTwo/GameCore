local BaseUIMediator = require ('BaseUIMediator')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class UIScienceStageMediator : BaseUIMediator
local UIScienceStageMediator = class('UIScienceStageMediator', BaseUIMediator)

function UIScienceStageMediator:OnCreate()
    self.textTitle = self:Text('p_text_title')
    self.textContent = self:Text('p_text_content')
    self.textHint = self:Text('p_text_hint', I18N.Get("tech_info_close"))
end

function UIScienceStageMediator:OnOpened(stageId)
    local stageCfg = ConfigRefer.CityTechStage:Find(stageId)
    self.textTitle.text = I18N.Get(stageCfg:Name())
    self.textContent.text = I18N.Get(stageCfg:Desc())
end


return UIScienceStageMediator
