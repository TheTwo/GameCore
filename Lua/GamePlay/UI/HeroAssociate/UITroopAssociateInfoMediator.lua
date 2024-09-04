local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local NumberFormatter = require('NumberFormatter')
local UIHeroAssociateHelper = require('UIHeroAssociateHelper')  

---@class UITroopAssociateInfoMediator : BaseUIMediator
local UITroopAssociateInfoMediator = class('UITroopAssociateInfoMediator', BaseUIMediator)

function UITroopAssociateInfoMediator:ctor()

end

function UITroopAssociateInfoMediator:OnCreate()    
    self.textTitle = self:Text('p_text_title', 'formation_title')
    self.textDetail = self:Text('p_text_detail', 'formation_tagtips')
    -- self.textHero = self:Text('p_text_hero', 'formation_taghero')
    -- self.textStyle = self:Text('p_text_style','formation_tagstyle')
    -- self.textBuff = self:Text('p_text_buff','formation_tagattr')

    self.textEmpty = {}    
    ---@type HeroInfoItemSmallComponent[]
    self.compHero = {}     
    self.textStyle = {}    
    ---@type UIHeroAssociateIconComponent[]
    self.compIconStyle = {}
    self.textBuff = {}     
    self.activeLits = {}

    self.textEmpty[1]     = self:Text('p_text_empty_1', 'formation_tagnohero')
    self.compHero[1]      = self:LuaObject('p_hero_1')
    self.textStyle[1]     = self:Text('p_text_style_1')
    self.compIconStyle[1] = self:LuaObject('p_icon_style_1')
    self.activeLits[1]    = self:GameObject('p_base_lighten_1')
    -- self.textBuff[1]      = self:Text('p_text_buff_1')

    self.textStyle[2]     = self:Text('p_text_style_2')
    self.compIconStyle[2] = self:LuaObject('p_icon_style_2')
    self.textEmpty[2] = self:Text('p_text_empty_2', 'formation_tagnohero')
    self.compHero[2] = self:LuaObject('p_hero_2')
    self.activeLits[2]    = self:GameObject('p_base_lighten_2')
    -- self.textBuff[2]      = self:Text('p_text_buff_2')
    
    self.textStyle[3] = self:Text('p_text_style_3')
    self.compIconStyle[3] = self:LuaObject('p_icon_style_3')
    self.textEmpty[3] = self:Text('p_text_empty_3', 'formation_tagnohero')
    self.compHero[3] = self:LuaObject('p_hero_3')
    self.activeLits[3]    = self:GameObject('p_base_lighten_3')
    -- self.textBuff[3] = self:Text('p_text_buff_3')

    self.goAddition = self:GameObject('addition')
    self.textAddition = self:Text('p_text_addition', 'formation_addon')
    self.textAdditionNumber = self:Text('p_text_addition_number')
    self.goAdd1 = self:GameObject('add_1')
    self.textEvaluate = self:Text('p_text_evaluate', 'formation_evaluation')
    self.textEvaluateDetail = self:Text('p_text_evaluate_detail')
    
end


function UITroopAssociateInfoMediator:OnShow(param)
    if not param then
        self:CloseSelf()
        return
    end
    ---@type number[]
    local heroIds = param.heroIds
    ---@type HeroAssociateData
    local tagInfoData = param.associateData
    if heroIds == nil or #heroIds == 0 then
        self:CloseSelf()
        return
    end

    if not tagInfoData then
        tagInfoData = ModuleRefer.TroopModule:GetRelationConfigData()
    end

    for i = 1, 3 do
        self.textEmpty[i]:SetVisible(true)
        self.compHero[i]:SetVisible(false)
        self.textStyle[i]:SetVisible(true)
        self.compIconStyle[i]:SetVisible(false)
        -- self.textBuff[i]:SetVisible(true)
        self.textStyle[i].text = "--"
        -- self.textBuff[i].text = "--"
    end
    local tagIndex = {}
    local heroTags = {}
    -- local heroTagTable = {}
    for i = 1, 3 do
        local id = heroIds[i]
        if not id then
            goto continue
        end
        local heroData = ModuleRefer.HeroModule:GetHeroByCfgId(id)
        if not heroData then
            goto continue        
        end

        self.textEmpty[i]:SetVisible(false)
        self.compHero[i]:SetVisible(true)
        self.compHero[i]:OnFeedData({heroData = heroData, hideJobIcon = true,hideExtraInfo = true})
        local tagType = heroData.configCell:AssociatedTagInfo()
        table.insert(heroTags,tagType)
        tagIndex[i] = tagType
        -- heroTagTable[i] = tagType
        self.textStyle[i].text = I18N.Get(tagInfoData.tagCfg[tagType].name)
        self.compIconStyle[i]:SetVisible(true)
        self.compIconStyle[i]:FeedData({
            cfgData = tagInfoData,
            tagType = tagType
        })
        ::continue::
    end

    local relationCfg = UIHeroAssociateHelper.FindRelation(heroTags,tagInfoData)
    if not relationCfg then
        self.goAddition:SetVisible(false)
        self.goAdd1:SetActive(false)
        for i = 1, 3 do
            self.activeLits[i]:SetActive(false)
        end
        return
    end

    for i = 1, 3 do
        if table.ContainsValue(relationCfg.tags,tagIndex[i]) then
            self.activeLits[i]:SetActive(true)
        else
            self.activeLits[i]:SetActive(false)
        end        
    end

    self.goAddition:SetVisible(true)
    self.goAdd1:SetActive(true)
    local addedDesc = I18N.Get(relationCfg.displayValue)   
    self.textAdditionNumber.text = addedDesc
    
    if not relationCfg.tags or #relationCfg.tags < 1 then
        self.textEvaluateDetail.text = I18N.Get('formation_taglevel1')
    elseif #relationCfg.tags == 2 then
        self.textEvaluateDetail.text = I18N.Get('formation_taglevel2')    
    else
        self.textEvaluateDetail.text = I18N.Get('formation_taglevel3')
    end

end

function UITroopAssociateInfoMediator:OnHide(param)
end

function UITroopAssociateInfoMediator:OnOpened(param)
end

function UITroopAssociateInfoMediator:OnClose(param)
end

return UITroopAssociateInfoMediator
