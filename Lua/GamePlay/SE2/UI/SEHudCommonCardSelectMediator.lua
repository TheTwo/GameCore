local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local SpecialDamageType = require("SpecialDamageType")
local CardType = require("CardType")
local UIHelper = require("UIHelper")
---@type CardModule
local CardModule = ModuleRefer.CardModule

---@class SEHudCommonCardSelectMediator : BaseUIMediator
local SEHudCommonCardSelectMediator = class('SEHudCommonCardSelectMediator', BaseUIMediator)

local MAX_SELECTED_CARD_COUNT = 3
local MIN_SELECTED_CARD_COUNT = 0

function SEHudCommonCardSelectMediator:ctor()
    self._petCardList = {}
    self._petCardSortList = {}
    self._petCardSelectedList = {}
    self._petCardSelectedIndexList = {}
    self._cardTableDataMap = {}
    self._unlockedCardList = {}
    self._lockedCardList = {}
    self._selectedCardCount = 0
    self._selectedCardId = 0
    self._onCloseCallback = nil
    self._refreshing = false
    if (ConfigRefer.ConstSe.SEPresetPetCardMinCount) then
        MIN_SELECTED_CARD_COUNT = ConfigRefer.ConstSe:SEPresetPetCardMinCount()
    end
end

function SEHudCommonCardSelectMediator:OnCreate(param)
    self._selectedGroupIndex = param.selectedGroupIndex
    self._onCloseCallback = param.onClose
    self:InitObjects()
end

function SEHudCommonCardSelectMediator:OnShow(param)
    self:InitData()
    self:Refresh()
end

function SEHudCommonCardSelectMediator:OnHide(param)
end

---@param self SEHudCommonCardSelectMediator
function SEHudCommonCardSelectMediator:InitObjects()
    self._backButton = self:LuaObject("child_common_btn_back")
    self._cardTable = self:TableViewPro("p_table_card")

    self._skillNameText = self:Text("p_text_skill_name")
    self._skillTag = self:LuaBaseComponent('child_tag_skill_type')
    self._injureItem = self:GameObject("p_addition_injure")
    self._injureIcon = self:Image("p_icon_injure")
    self._injureText = self:Text('p_text_injure')
    self._injureRatioText = self:Text('p_text_num_injure')
    self._injureFixedText = self:Text('p_text_add')
    self._additionLiftItem = self:GameObject("p_addition_life")
    self._lifeIcon = self:Image("p_icon_life")
    self._lifeText = self:Text('p_text_life')
    self._lifeNum = self:Text('p_text_num_life')
    self._skillDetails = self:Text('p_text_detail')
    self._confirmBtn = self:Button("p_comp_btn_a_l_u2_editor", Delegate.GetOrCreate(self, self.OnBtnConfirmClicked))
    self._confirmText = self:Text("p_text")
end

---@param self SEHudCommonCardSelectMediator
function SEHudCommonCardSelectMediator:InitData()
    self._backButton:FeedData({
        title = I18N.Get("setroop_petcard_group")
    })
end

---@param self SEHudCommonCardSelectMediator
function SEHudCommonCardSelectMediator:Refresh()
    self:RefreshData()
    self:RefreshUI()
end

---@param self SEHudCommonCardSelectMediator
function SEHudCommonCardSelectMediator:RefreshData()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    if (not player or not player.PlayerWrapper.PlayerCard.CardInfos) then
        g_Logger.Error("Can't get player card info!")
        self:CloseSelf();
        return
    end

    -- 解锁卡牌列表
    self._unlockedCardList = {}
    for id, _ in pairs(player.PlayerWrapper.PlayerCard.CardInfos) do
        self._unlockedCardList[id] = true
    end

    -- 通用卡牌列表
    self._petCardList = {}
    self._lockedCardList = {}
    self._petCardSortList = {}
    for _, cell in ConfigRefer.Card:ipairs() do
        if (cell:CardTypeEnum() == CardType.Pet) then
            local cardId = cell:Id()
            self._petCardList[cardId] = cell
            local sortData = {
                cardId = cardId,
                unlocked = self._unlockedCardList[cardId],
                energy = cell:Energy(),
            }
            table.insert(self._petCardSortList, sortData)
            if (not self._unlockedCardList[cardId]) then
                self._lockedCardList[cardId] = true
            end
        end
    end

    -- 排序
    table.sort(self._petCardSortList, self.SortCard)

    -- 已选通用卡牌列表
    self._petCardSelectedList = {}
    self._petCardSelectedIndexList = {}
    --print(player.PlayerWrapper.PlayerCard.CardInfos)
    local index = 1
    for _, cfgId in pairs(player.PlayerWrapper2.PlayerPresetCardGroup.Groups[self._selectedGroupIndex].PetCardList) do
        self._petCardSelectedList[cfgId] = index
        self._petCardSelectedIndexList[index] = cfgId
        index = index + 1
    end
end

---@param a table
---@param b table
---@return boolean
function SEHudCommonCardSelectMediator.SortCard(a, b)
    -- 已解锁优先
    if (a.unlocked and not b.unlocked) then
        return true
    elseif (not a.unlocked and b.unlocked) then
        return false
    else
        -- 费用由小到大
        if (a.energy ~= b.energy) then
            return a.energy < b.energy
        else
            -- ID由小到大
            return a.cardId < b.cardId
        end
    end
end

---@param self SEHudCommonCardSelectMediator
function SEHudCommonCardSelectMediator:RefreshUI()
    self._refreshing = true

    -- 卡牌列表
    self._cardTableDataMap = {}
    self._cardTable:Clear()
    self._selectedCardId = self._petCardSortList[1].cardId
    for _, sortData in ipairs(self._petCardSortList) do
        local cardId = sortData.cardId
        local notificationDynamicNode = nil
        if (not self._lockedCardList[cardId]) then
            notificationDynamicNode = CardModule:GetPetCardRedDotData(cardId)
        end
        local cardData = {
            nodeName = "child_card_skill",
            data = {
                cardId = cardId,
                onClick = Delegate.GetOrCreate(self, self.OnCardClick),
                onSelected = Delegate.GetOrCreate(self, self.OnCardSelect),
                isSelected = self._selectedCardId == cardId,
                isShowToggle = not self._lockedCardList[cardId],
                isToggleOn = self._petCardSelectedList[cardId],
                isGray = self._lockedCardList[cardId],
                redDotNew = notificationDynamicNode,
            },
            orderName = "p_order",
            orderTextName = "p_text_order",
            showOrder = self._petCardSelectedList[cardId] ~= nil,
            orderText = self._petCardSelectedList[cardId],
        }
        self._cardTableDataMap[cardId] = cardData
        self._cardTable:AppendData(cardData)
    end
    self._cardTable:RefreshAllShownItem(false)
    self:RefreshConfirmText()
    self:RefreshSkillInfo(self._selectedCardId)
    self._refreshing = false
end

---@param self SEHudCommonCardSelectMediator
---@param cardId number
function SEHudCommonCardSelectMediator:UnselectCard(cardId)
    local data = self._cardTableDataMap[cardId]
    if (not data) then return end
    data.showOrder = false
    self._petCardSelectedList[cardId] = nil
    for i = #self._petCardSelectedIndexList, 1, -1 do
        if (self._petCardSelectedIndexList[i] == cardId) then
            table.remove(self._petCardSelectedIndexList, i)
            break
        end
    end
    for index, id in ipairs(self._petCardSelectedIndexList) do
        local tdata = self._cardTableDataMap[id]
        if (tdata) then
            self._petCardSelectedList[id] = index
            tdata.showOrder = true
            tdata.orderText = index
        end
    end
end

---@param self SEHudCommonCardSelectMediator
---@param cardId number
function SEHudCommonCardSelectMediator:SelectCard(cardId)
    local data = self._cardTableDataMap[cardId]
    if (not data) then return end
    local selectedCount = #self._petCardSelectedIndexList
    self._petCardSelectedList[cardId] = selectedCount + 1
    table.insert(self._petCardSelectedIndexList, cardId)
    data.showOrder = true
    data.orderText = selectedCount + 1
end

---@param self SEHudCommonCardSelectMediator
---@param cardId number
function SEHudCommonCardSelectMediator:RefreshSkillInfo(cardId)
    local cardCfg = ConfigRefer.Card:Find(cardId)
    if not cardCfg then
        return
    end
    local skillId = cardCfg:Skill()
    local skillCfgCell = ConfigRefer.KheroSkillLogicalSe:Find(skillId)
    self._skillNameText.text = I18N.Get(skillCfgCell:NameKey())
    local skillTagParam = {}
    skillTagParam.text = skillCfgCell:CategoryTextKey()
    self._skillTag:FeedData(skillTagParam)
    if skillCfgCell:SpecialDamageType() == SpecialDamageType.Heal then
        self._injureText.text = I18N.Get("seskill_damagetype_heal")
    else
        self._injureText.text = I18N.Get("seskill_damagetype_damage")
    end
    local damageFactor = skillCfgCell:DamageFactor()
    local showDamage = damageFactor and damageFactor >= 0.001
    self._injureRatioText.gameObject:SetActive(showDamage)
    self._injureItem.gameObject:SetActive(showDamage)
    if showDamage then
        if damageFactor and damageFactor >= 0 then
            self._injureRatioText.text = string.format("%d", skillCfgCell:DamageFactor() * 100) .. "%"
        end
    end
    local damageValue = skillCfgCell:DamageValue()
    self._injureFixedText.gameObject:SetActive(damageValue and damageValue > 0)
    if damageValue and damageValue >= 0 then
        self._injureFixedText.text = damageValue
    end
    local isHasPuppetId = cardCfg:PuppetHp() and cardCfg:PuppetHp() > 0
    self._additionLiftItem.gameObject:SetActive(isHasPuppetId)
    if isHasPuppetId then
        self._lifeText.text = I18N.Get("seskill_health")
        self._lifeNum.text = cardCfg:PuppetHp()
    end
    self._skillDetails.text = I18N.Get(skillCfgCell:IntroductionKey())
end

---@param self SEHudCommonCardSelectMediator
---@param cardId number
function SEHudCommonCardSelectMediator:OnCardClick(cardId)
    if (cardId == self._selectedCardId) then return end
    local selectedData = self._cardTableDataMap[self._selectedCardId]
    if (selectedData) then
        selectedData.data.isSelected = false
    end
    self._selectedCardId = cardId
    local newData = self._cardTableDataMap[cardId]
    if (newData) then
        newData.data.isSelected = true
    end
    local cardInfo = CardModule:GetCardByCfgId(cardId)
    if (cardInfo and CardModule:IsNewCard(cardInfo)) then
        CardModule:SetIsNewCard(cardInfo, false, true)
    end
    self._cardTable:RefreshAllShownItem(false)
    self:RefreshSkillInfo(cardId)
end

---@param self SEHudCommonCardSelectMediator
---@param selected boolean
---@param cardId number
function SEHudCommonCardSelectMediator:OnCardSelect(selected, cardId)
    local data = self._cardTableDataMap[cardId]
    data.data.isToggleOn = selected
    if (selected) then
        self._selectedCardCount = self._selectedCardCount + 1
        if (self._selectedCardCount > MAX_SELECTED_CARD_COUNT) then
            data.data.isToggleOn = false
            self._cardTable:RefreshAllShownItem()
        elseif (not self._refreshing) then
            self:SelectCard(cardId)
            self._cardTable:RefreshAllShownItem()
        end
    else
        self._selectedCardCount = self._selectedCardCount - 1
        if (not self._refreshing) then
            self:UnselectCard(cardId)
            self._cardTable:RefreshAllShownItem()
        end
    end
    self:RefreshConfirmText()
end

function SEHudCommonCardSelectMediator:RefreshConfirmText()
    self._confirmText.text = string.format(I18N.Get("setroop_btn_check"), self._selectedCardCount, MAX_SELECTED_CARD_COUNT)
    UIHelper.SetGray(self._confirmBtn.gameObject, self._selectedCardCount < MIN_SELECTED_CARD_COUNT)
end

---@param self SEHudCommonCardSelectMediator
function SEHudCommonCardSelectMediator:OnBtnConfirmClicked()
    if (self._selectedCardCount < MIN_SELECTED_CARD_COUNT) then return end

    -- 发送协议
    local msg = require("ModifyPresetNormalCardParameter").new()
    msg.args.Group = self._selectedGroupIndex - 1
    msg.args.CardType = CardType.Pet
    for _, cardId in ipairs(self._petCardSelectedIndexList) do
        msg.args.CfgIdList:Add(cardId)
    end
    msg:Send()

    -- 关闭
    if (self._onCloseCallback) then
        self._onCloseCallback(self._petCardSelectedIndexList)
    end
    self:CloseSelf()
end

return SEHudCommonCardSelectMediator
