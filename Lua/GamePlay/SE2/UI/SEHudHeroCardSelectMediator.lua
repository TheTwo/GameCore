local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local GotoUtils = require('GotoUtils')
local Utils = require("Utils")
local SpecialDamageType = require("SpecialDamageType")
local UIHelper = require("UIHelper")

---@class SEHudHeroCardSelectMediator : BaseUIMediator
local SEHudHeroCardSelectMediator = class('SEHudHeroCardSelectMediator', BaseUIMediator)

local MAX_CARD_COUNT = 5
local MAX_SELECTED_CARD_COUNT = 3
local MIN_SELECTED_CARD_COUNT = 0

function SEHudHeroCardSelectMediator:ctor()
    self._skillCards = {}
    self._skillCardMap = {}
    self._skillItems = {}
    self._heroCardConfigIdList = {}
    self._heroSelectedCardIdMap = {}
    self._selectedGroupIndex = 0
    self._selectedHeroCfg = nil
    self._selectedHeroIndex = 0
    self._selectedCardCount = 0
    self._onCloseCallback = nil
    if (ConfigRefer.ConstSe.SEPresetHeroCardMinCount) then
        MIN_SELECTED_CARD_COUNT = ConfigRefer.ConstSe:SEPresetHeroCardMinCount()
    end
end

function SEHudHeroCardSelectMediator:OnCreate(param)
    self._selectedGroupIndex = param.selectedGroupIndex
    self._selectedHeroCfg = param.selectedHeroCfg
    self._selectedHeroIndex = param.selectedHeroIndex
    self._onCloseCallback = param.onClose
    self:InitObjects()
end

function SEHudHeroCardSelectMediator:OnShow(param)
	self:InitData()
    self:Refresh()
end

function SEHudHeroCardSelectMediator:OnHide(param)
end

function SEHudHeroCardSelectMediator:OnClose(param)
    if (self._onCloseCallback) then
        self._onCloseCallback(param)
    end
end

---@param self SEHudHeroCardSelectMediator
function SEHudHeroCardSelectMediator:InitObjects()
    self._skillCards = {}
    self._skillCardMap = {}
    self._skillItems = {}
    for i = 1, MAX_CARD_COUNT do
        self._skillCards[#self._skillCards + 1] = self:LuaObject('child_card_skill_editor_' .. i)
        self._skillItems[#self._skillItems + 1] = self:GameObject('child_card_skill_editor_' .. i)
    end
    self._skillNameText = self:Text("p_text_skill_name_1")
    --self._skillTag = self:LuaBaseComponent('child_tag_skill_type_1')
    self._skillAttrTable = self:TableViewPro("p_table")
    -- self._injureItem = self:GameObject("p_addition_injure_1")
    -- self._injureIcon = self:Image("p_icon_injure_1")
    -- self._injureText = self:Text('p_text_injure_1')
    -- self._injureRatioText = self:Text('p_text_num_injure_1')
    -- self._injureFixedText = self:Text('p_text_add_1')
    -- self._additionLiftItem = self:GameObject("p_addition_life_1")
    -- self._lifeIcon = self:Image("p_icon_life_1")
    -- self._lifeText = self:Text('p_text_life_1')
    -- self._lifeNum = self:Text('p_text_num_life_1')
    self._skillDetails = self:Text('p_text_detail_1')
    --self._confirmBtn = self:Button("p_comp_btn_a_l_editor", Delegate.GetOrCreate(self, self.OnBtnConfirmClicked))
	self._confirmBtn = self:LuaObject("child_comp_btn_b")
    --self._confirmText = self:Text("p_text")
end

function SEHudHeroCardSelectMediator:InitData()
	self._confirmBtn:FeedData({
		onClick = Delegate.GetOrCreate(self, self.OnBtnConfirmClicked),

	})
end

---@param self SEHudHeroCardSelectMediator
function SEHudHeroCardSelectMediator:Refresh()
    self:RefreshData()
    self:RefreshUI()
end

---@param self SEHudHeroCardSelectMediator
function SEHudHeroCardSelectMediator:RefreshData()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    --print(player.Hero.HeroInfos)
    if (not player or not self._selectedHeroCfg) then
        self:CloseSelf()
        return
    end

    -- 所有卡牌
    self._heroCardConfigIdList = {}
    for i = 1, self._selectedHeroCfg:CardsLength() do
        local cardId = self._selectedHeroCfg:Cards(i)
        self._skillCardMap[cardId] = self._skillCards[i]
        table.insert(self._heroCardConfigIdList, cardId)
    end

    -- 选定卡牌
    self._heroSelectedCardIdMap = {}
    self._selectedCardCount = 0
    local cardList = player.PlayerWrapper2.PlayerPresetCardGroup.Groups[self._selectedGroupIndex].HeroList[self._selectedHeroIndex].HeroCardIdList
    if (cardList) then
        for _, id in ipairs(cardList) do
            if (id > 0) then
                self._heroSelectedCardIdMap[id] = true
            end
        end
    end
end

---@param self SEHudHeroCardSelectMediator
function SEHudHeroCardSelectMediator:RefreshUI()
    for i = 1, MAX_CARD_COUNT do
        local cardId = self._heroCardConfigIdList[i]
        if (cardId) then
            self._skillItems[i]:SetActive(true)
			local available = ModuleRefer.HeroModule:CheckCardUnlock(self._selectedHeroCfg:Id(), cardId)
            self._skillCards[i]:FeedData({
                cardId = cardId,
                onClick = Delegate.GetOrCreate(self, self.OnCardClick),
                onSelected = Delegate.GetOrCreate(self, self.OnCardToggleChange),
                isGray = not available,
				isShowToggle = available,
                isToggleOn = self._heroSelectedCardIdMap[cardId],
            })
        else
            self._skillItems[i]:SetActive(false)
        end
    end
    self:OnCardClick(self._heroCardConfigIdList[1])
end

---@param self SEHudHeroCardSelectMediator
---@param cardId number
function SEHudHeroCardSelectMediator:RefreshSkillInfo(cardId)
    local cardCfg = ConfigRefer.Card:Find(cardId)
    if not cardCfg then
        return
    end
    local skillId = cardCfg:Skill()
    local skillCfgCell = ConfigRefer.KheroSkillLogicalSe:Find(skillId)
    self._skillNameText.text = I18N.Get(skillCfgCell:NameKey())
    self._skillDetails.text = I18N.Get(skillCfgCell:IntroductionKey())

    -- 属性
    self._skillAttrTable:Clear()
    for i = 1, skillCfgCell:TipsContentLength(), 2 do
        local text = I18N.Get(skillCfgCell:TipsContent(i))
        local num = skillCfgCell:TipsContent(i + 1)
        self._skillAttrTable:AppendData({
            text = text,
            number = num,
        })
    end
    self._skillAttrTable:RefreshAllShownItem()
end

---@param self SEHudHeroCardSelectMediator
---@param cardId number
function SEHudHeroCardSelectMediator:OnCardClick(cardId)
    local cardItem = self._skillCardMap[cardId]
    if (cardItem) then
        cardItem:ChangeSelectState(true)
    end
    for i = 1, MAX_CARD_COUNT do
        local card = self._skillCards[i]
        if (card ~= cardItem) then
            card:ChangeSelectState(false)
        end
    end
    self:RefreshSkillInfo(cardId)
end

---@param self SEHudHeroCardSelectMediator
function SEHudHeroCardSelectMediator:GetSelectedCardCount()
    local count = 0
    for i = 1, MAX_CARD_COUNT do
        if (self._skillCards[i].selectToggle.isOn) then
            count = count + 1
        end
    end
    return count
end

---@param self SEHudHeroCardSelectMediator
---@param selected boolean
---@param cardId number
function SEHudHeroCardSelectMediator:OnCardToggleChange(selected, cardId)
    if (selected) then
        self._selectedCardCount = self._selectedCardCount + 1
    else
        self._selectedCardCount = self._selectedCardCount - 1
    end
    self:RefreshCardToggles()
    self:RefreshConfirmButtonText()
end

---@param self SEHudHeroCardSelectMediator
function SEHudHeroCardSelectMediator:RefreshCardToggles()
    for i = 1, MAX_CARD_COUNT do
        if (not ModuleRefer.HeroModule:CheckCardUnlock(self._selectedHeroCfg:Id(), self._heroCardConfigIdList[i])
            or self._selectedCardCount >= MAX_SELECTED_CARD_COUNT and not self._skillCards[i].selectToggle.isOn) then
            self._skillCards[i].toggleItem:SetActive(false)
        else
            self._skillCards[i].toggleItem:SetActive(true)
        end
    end
end

---@param self SEHudHeroCardSelectMediator
function SEHudHeroCardSelectMediator:RefreshConfirmButtonText()
	self._confirmBtn:SetButtonText(string.format(I18N.Get("setroop_btn_check"), self._selectedCardCount , MAX_SELECTED_CARD_COUNT))
	self._confirmBtn:SetEnabled(self._selectedCardCount >= MIN_SELECTED_CARD_COUNT)
    --self._confirmText.text = string.format(I18N.Get("setroop_btn_check"), self._selectedCardCount , MAX_SELECTED_CARD_COUNT)
    --UIHelper.SetGray(self._confirmBtn.gameObject, self._selectedCardCount < MIN_SELECTED_CARD_COUNT)
end

---@param self SEHudHeroCardSelectMediator
function SEHudHeroCardSelectMediator:OnBtnConfirmClicked()
    if (self._selectedCardCount >= MIN_SELECTED_CARD_COUNT) then
        local selectedCardList = {}
        for i = 1, MAX_CARD_COUNT do
            if (self._skillCards[i].selectToggle.isOn) then
                table.insert(selectedCardList, self._heroCardConfigIdList[i])
            end
        end

        -- 发送协议
        local msg = require("ModifyPresetHeroCardParameter").new()
        msg.args.Group = self._selectedGroupIndex - 1
        msg.args.HeroIndex = self._selectedHeroIndex - 1
        for _, v in ipairs(selectedCardList) do
            msg.args.CfgIdList:Add(v)
        end
        --print(msg.args.Group, msg.args.HeroIndex, msg.args.CfgIdList)
        msg:Send()

        self:CloseSelf(selectedCardList)
    end
end

return SEHudHeroCardSelectMediator
