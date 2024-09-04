local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class UISkillDetailCellComponent : BaseUIComponent
local UISkillDetailCellComponent = class('UISkillDetailCellComponent', BaseUIComponent)

function UISkillDetailCellComponent:ctor()

end

function UISkillDetailCellComponent:OnCreate()
    
    self.imgLogo = self:Image('p_icon_skll')
    self.textLeagueName = self:Text('p_text_league_name')
    self.textLeagueDetail = self:Text('p_text_league_detail')
end


function UISkillDetailCellComponent:OnShow(param)
end

function UISkillDetailCellComponent:OnHide(param)
end

function UISkillDetailCellComponent:OnOpened(param)
end

function UISkillDetailCellComponent:OnClose(param)
end

function UISkillDetailCellComponent:OnFeedData(param)
    local skillId = param
    local skillCfgCell = ConfigRefer.KheroSkillLogical:Find(skillId)
    if skillCfgCell then
        local skillIconId = skillCfgCell:SkillPic()
        if skillIconId > 0 then
            self:LoadSprite(skillIconId,self.imgLogo)
        end
        self.textLeagueName.text = I18N.Get(skillCfgCell:NameKey())
        self.textLeagueDetail.text = I18N.Get(skillCfgCell:IntroductionKey())
    end
end




return UISkillDetailCellComponent
