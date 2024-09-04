local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local UIHeroLocalData = require('UIHeroLocalData')
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require('ModuleRefer')
local NotificationType = require("NotificationType")
local UIHeroLocalData = require('UIHeroLocalData')
local SpecialDamageType = require("SpecialDamageType")
local HeroModifyDefaultCardsParameter = require("HeroModifyDefaultCardsParameter")
local I18N = require("I18N")

---@class UIHeroSESkillComponent : BaseUIComponent
---@field parentMediator UIHeroMainUIMediator
---@field heroList table<number,HeroConfigCache>
local UIHeroSESkillComponent = class('UIHeroSESkillComponent', BaseUIComponent)

function UIHeroSESkillComponent:ctor()

end

function UIHeroSESkillComponent:OnCreate()
    self.passiveSkillBtn = self:Button("p_btn_skill", Delegate.GetOrCreate(self, self.OnClickPassiveSkill))
    self.passiveSelectImg = self:Image("p_img_select")
    self.skillCards = {}
    self.skillItems = {}
    for i = 1, 5 do
        self.skillCards[#self.skillCards + 1] = self:LuaBaseComponent('child_card_skill_editor_' .. i)
        self.skillItems[#self.skillItems + 1] = self:GameObject('child_card_skill_editor_' .. i)
    end
    self.skillNameText = self:Text("p_text_skill_name_1")
    self.skillTag = self:LuaBaseComponent('child_tag_skill_type_1')
    self.skillAttrTable = self:TableViewPro("p_table")
    self.skillDetails = self:Text('p_text_detail_1')
    self.lockCardText = self:Text("p_text_lock_card")
    self.changeCardBtn = self:Button("p_btn_all_card", Delegate.GetOrCreate(self, self.OnBtnChangeSelectedClicked))
    self.textChangeCard = self:Text('p_text_all_card', I18N.Get("hero_default_skill"))
    self.compChildCompB = self:LuaObject('child_comp_btn_b')
    self.confirmHintText = self:Text("p_text_hint_card", I18N.Get("hero_card_default"))
    self.notifyNode1 = self:LuaObject('child_reddot_default_3')
    self.notifyNode2 = self:LuaObject('child_reddot_default_4')
    self.notifyNode3 = self:LuaObject('child_reddot_default_5')
    self.parentMediator = self:GetParentBaseUIMediator()
end

function UIHeroSESkillComponent:OnShow()
    local buttonParamStartWork = {}
    buttonParamStartWork.onClick = Delegate.GetOrCreate(self, self.OnBtnConfirmClicked)
    buttonParamStartWork.buttonText = ""

    self.compChildCompB:OnFeedData(buttonParamStartWork)
    self:ChangeState(false)
    if self.selectHero ~= self.parentMediator:GetSelectHero() then
        self.selectedCardId = nil
    end
    self.selectHero = self.parentMediator:GetSelectHero()
    self.curUseSkillCards = {}
    if self.selectHero:HasHero() then
        for _, cardId in pairs(self.selectHero.dbData.DefaultCards) do
            self.curUseSkillCards[cardId] = true
        end
    end
    local cardLengths = self.selectHero.configCell:CardsLength()
    for i = 1,  #self.skillCards do
        if i <= cardLengths then
            local cardDetailsParam = {}
            local id = self.selectHero.configCell:Cards(i)
            cardDetailsParam.cardId = id
            cardDetailsParam.onClick = function(cardId) self:OnClickSkillCard(cardId) end
            cardDetailsParam.getSelectCount = function() return self:GetSelectUseListInfo() end
            cardDetailsParam.onSelected = function(isSelected, cardId)
                self:OnSelectCard(isSelected, cardId)
            end
            cardDetailsParam.maxSelectCount = ConfigRefer.ConstMain:HeroDefaultCardCount()
            self.skillCards[i]:FeedData(cardDetailsParam)
            self.skillCards[i].Lua:RefreshSkillStatus(self:CheckIsSelected(id), self.selectHero.id)
            self.skillItems[i]:SetActive(true)
        else
            self.skillItems[i]:SetActive(false)
        end
    end
    local isHas = self.selectHero:HasHero()
    self.changeCardBtn.gameObject:SetActive(isHas)
    if not self.selectedCardId then
        self:OnClickSkillCard(self.selectHero.configCell:Cards(1))
    else
        self:OnClickSkillCard(self.selectedCardId)
    end
    self.passiveSkillBtn.gameObject:SetActive(false)
    --local seSkillNodeOne = ModuleRefer.NotificationModule:GetDynamicNode("HeroSeSkillNodeOne" .. self.selectHero.id, NotificationType.HERO_NEW_CARD1)
    local seSkillNodeTwo = ModuleRefer.NotificationModule:GetDynamicNode("HeroSeSkillNodeTwo" .. self.selectHero.id, NotificationType.HERO_NEW_CARD2)
    --ModuleRefer.NotificationModule:AttachToGameObject(seSkillNodeOne, self.notifyNode1.go, self.notifyNode1.redDot)
    ModuleRefer.NotificationModule:AttachToGameObject(seSkillNodeTwo, self.notifyNode2.go, self.notifyNode2.redDot)
end

function UIHeroSESkillComponent:CheckIsSelected(selectCardId)
    self.selectHero = self.parentMediator:GetSelectHero()
    if self.selectHero:HasHero() then
        for _, cardId in pairs(self.selectHero.dbData.DefaultCards) do
            if cardId == selectCardId then
                return true
            end
        end
    end
    return false
end

function UIHeroSESkillComponent:RefreshSkillDown(cardId, skillId)
    if not skillId then
        local cardCfg = ConfigRefer.Card:Find(cardId)
        if not cardCfg then
            return
        end
        skillId = cardCfg:Skill()
    end
    local skillCfgCell = ConfigRefer.KheroSkillLogicalSe:Find(skillId)
    self.skillNameText.text = I18N.Get(skillCfgCell:NameKey())
    local skillTagParam = {}
    skillTagParam.text = I18N.Get(skillCfgCell:CategoryTextKey())
    self.skillTag:FeedData(skillTagParam)
    self.skillAttrTable:Clear()
    for i = 1, skillCfgCell:TipsContentLength(), 2 do
        local text = I18N.Get(skillCfgCell:TipsContent(i))
        local num = skillCfgCell:TipsContent(i + 1)
        self.skillAttrTable:AppendData({
            text = text,
            number = num,
            icon = skillCfgCell:SkillPic()
        })
    end
    self.skillDetails.text = I18N.Get(skillCfgCell:IntroductionKey())
    self.selectHero = self.parentMediator:GetSelectHero()
    local isHas = self.selectHero:HasHero()
    if isHas and cardId then
        local isUnlock = ModuleRefer.HeroModule:CheckCardUnlock(self.selectHero.id, cardId)
        self.lockCardText.gameObject:SetActive(not isUnlock)
        if not isUnlock then
            local cardCfg = ConfigRefer.Card:Find(cardId)
            local unlockLevel = cardCfg:BreakThroughLevel()
            self.lockCardText.text =I18N.GetWithParams("hero_se_skill1_unlock", unlockLevel)
        end
    else
        self.lockCardText.gameObject:SetActive(false)
    end
    self:RefreshUseSkillBtnState()
end

function UIHeroSESkillComponent:ChangeState(isSelect)
    self.lockCardText.gameObject:SetActive(not isSelect)
    self.changeCardBtn.gameObject:SetActive(not isSelect)
    self.compChildCompB:SetVisible(isSelect)
    self.confirmHintText.gameObject:SetActive(isSelect)
end

function UIHeroSESkillComponent:OnClickSkillCard(cardId)
    self.selectedCardId = cardId
    self:RefreshSkillDown(self.selectedCardId, nil)
    self.passiveSelectImg.gameObject:SetActive(false)
    local index = 0
    for i = 1, #self.skillCards do
        local isSelected = self.skillCards[i].Lua.cardId == cardId
        self.skillCards[i].Lua:ChangeSelectState(isSelected)
        if isSelected then
            index = i
        end
    end
    if index == 3 then
        ModuleRefer.HeroModule:SyncHeroRedDot(self.selectHero.id, ModuleRefer.HeroModule.HeroRedDotMask.SeCard1)
    elseif index == 4 then
        ModuleRefer.HeroModule:SyncHeroRedDot(self.selectHero.id, ModuleRefer.HeroModule.HeroRedDotMask.SeCard2)
    end
end

function UIHeroSESkillComponent:OnClickPassiveSkill()
    -- self.selectedCardId = nil
    -- self:RefreshSkillDown(nil, 20046)
    -- self.passiveSelectImg.gameObject:SetActive(true)
    -- for i = 1, #self.skillCards do
    --     self.skillCards[i].Lua:ChangeSelectState(false)
    -- end
end

function UIHeroSESkillComponent:OnBtnChangeSelectedClicked()
    if not self.selectHero:HasHero() then
        return
    end
    self:ChangeState(true)
    self.selectHero = self.parentMediator:GetSelectHero()
    self.initToggleState = true
    for i = 1, #self.skillCards do
        local id = self.selectHero.configCell:Cards(i)
        self.skillCards[i].Lua:ChangeToSelectStatus(self:CheckIsSelected(id), self.selectHero.id)
    end
    self.initToggleState = false
    self.passiveSkillBtn.gameObject:SetActive(false)
    self:RefreshUseSkillBtnState()
end

function UIHeroSESkillComponent:OnSelectCard(isUse, cardId)
    self.curUseSkillCards[cardId] = isUse
    self:RefreshUseSkillBtnState()
end

function UIHeroSESkillComponent:RefreshUseSkillBtnState()
    local useCount, _ = self:GetSelectUseListInfo()
    local isCanClick = useCount == ConfigRefer.ConstMain:HeroDefaultCardCount()
    self.compChildCompB:SetEnabled(isCanClick)
    self.compChildCompB:SetButtonText(string.format(I18N.Get("setroop_btn_check"), useCount, ConfigRefer.ConstMain:HeroDefaultCardCount()))
end

function UIHeroSESkillComponent:GetSelectUseListInfo()
    if self.initToggleState then
        return 0
    end
    local useCount = 0
    local useCards = {}
    for cardId, isUse in pairs(self.curUseSkillCards) do
        if isUse then
            useCount = useCount + 1
            useCards[#useCards + 1] = cardId
        end
    end
    return useCount, useCards
end

function UIHeroSESkillComponent:OnBtnConfirmClicked()
    self.selectHero = self.parentMediator:GetSelectHero()
    local useCount, useCards = self:GetSelectUseListInfo()
    if useCount == ConfigRefer.ConstMain:HeroDefaultCardCount() then
        local param = HeroModifyDefaultCardsParameter.new()
        param.args.HeroCfgId = self.selectHero.configCell:Id()
        for _, cardId in pairs(useCards) do
            param.args.Cards:Add(cardId)
        end
        param:Send()
        self:ChangeState(false)
    end
end

function UIHeroSESkillComponent:OnOpened(param)
end

function UIHeroSESkillComponent:OnClose()
end

function UIHeroSESkillComponent:OnFeedData(param)
end

return UIHeroSESkillComponent
