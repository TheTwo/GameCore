local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIHeroAssociateHelper = require('UIHeroAssociateHelper')
local UIHeroLocalData = require('UIHeroLocalData')
local TagType = require('TagType')

---@class UIHeroAssociateMediator : BaseUIMediator
local UIHeroAssociateMediator = class('UIHeroAssociateMediator', BaseUIMediator)

function UIHeroAssociateMediator:ctor()

end

function UIHeroAssociateMediator:OnCreate()    
    self.textTitle = self:Text('p_text_title', 'formation_tagcountertitle')    
    self.textDetail = self:Text('p_text_detail', 'formation_tagcountertips')
    self.compIconStrategy = self:LuaBaseComponent('p_icon_strategy')    
    self.compIconStrength = self:LuaBaseComponent('p_icon_strength')    
    self.compIconSkill = self:LuaBaseComponent('p_icon_skill')
    self.textStrength = self:Text('p_text_strength')
    self.textStrategy = self:Text('p_text_strategy')
    self.textSkill = self:Text('p_text_skill')

    -- self.content = self:GameObject('content_relation')
end


function UIHeroAssociateMediator:OnShow(param)
    self:RefreshInfo(param)    
end

function UIHeroAssociateMediator:OnHide(param)
end

function UIHeroAssociateMediator:OnOpened(param)
end

function UIHeroAssociateMediator:OnClose(param)
end

function UIHeroAssociateMediator:RefreshInfo(param)
    self.cfgData = ModuleRefer.TroopModule:GetRelationConfigData()
    if not self.cfgData then
        return
    end

    --TagType.TagTypeStrength = 1,
    local strengthCfg = self.cfgData.tagCfg[TagType.TagTypeStrength]
    if strengthCfg then
        self.textStrength.text = I18N.Get("formation_powertag")       
        self.compIconStrength:FeedData({
            cfgData = self.cfgData,
            tagType = TagType.TagTypeStrength,
        })

    end
    --TagType.TagTypeIntelligence = 2,
    local strategyCfg = self.cfgData.tagCfg[TagType.TagTypeIntelligence]
    if strategyCfg then
        self.textStrategy.text = I18N.Get("formation_intelltag")        
        self.compIconStrategy:FeedData({
            cfgData = self.cfgData,
            tagType = TagType.TagTypeIntelligence,
        })
        
    end
    --TagType.TagTypeSkill = 3,
    local skillCfg = self.cfgData.tagCfg[TagType.TagTypeSkill]
    if skillCfg then
        self.textSkill.text = I18N.Get("formation_skilltag")
        self.compIconSkill:FeedData({
            cfgData = self.cfgData,
            tagType = TagType.TagTypeSkill,
        })
    end
end

return UIHeroAssociateMediator
