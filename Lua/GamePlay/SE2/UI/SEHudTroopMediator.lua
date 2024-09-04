local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local GotoUtils = require('GotoUtils')
local UIMediatorNames = require("UIMediatorNames")
local DBEntityPath = require("DBEntityPath")
---@type NotificationModule
local NotificationModule = ModuleRefer.NotificationModule
---@type CardModule
local CardModule = ModuleRefer.CardModule
local CardType = require("CardType")
---@type HeroModule
local HeroModule = ModuleRefer.HeroModule

local MODE_CARD_EDIT = 0
--local MODE_HERO_SELECT = 1

local HERO_INDEX_MIDDLE = 1
local HERO_INDEX_LEFT = 2
local HERO_INDEX_RIGHT = 3

local MAX_GROUP_COUNT = 3
local MAX_HERO_COUNT = 3
local MAX_HERO_CARD_COUNT = 3
-- local MAX_PET_CARD_COUNT = 3

local PANEL_TRANSITION_TIME = 0.5
local HERO_PANEL_FROM_X = 0
local HERO_PANEL_TO_X = 0 --389
local CARD_PANEL_FROM_X = 0
local CARD_PANEL_TO_X = 0 --404
local HERO_PANEL_FROM_Y = 0
local HERO_PANEL_TO_Y = 130
local CARD_PANEL_FROM_Y = 0
local CARD_PANEL_TO_Y = 130
local HERO_PANEL_FROM_SCALE = 1
local HERO_PANEL_TO_SCALE = 1 --0.9
local CARD_PANEL_FROM_SCALE = 1
local CARD_PANEL_TO_SCALE = 1 --0.9
local HERO_LEFT_FROM_SCALE = 0.85
local HERO_LEFT_TO_SCALE = 0.85 --1
local HERO_RIGHT_FROM_SCALE = 0.85
local HERO_RIGHT_TO_SCALE = 0.85 --1
local CARD_LEFT_FROM_SCALE = 0.94
local CARD_LEFT_TO_SCALE = 0.94 --1
local CARD_RIGHT_FROM_SCALE = 0.94
local CARD_RIGHT_TO_SCALE = 0.94 --1

---@class SEHudTroopMediatorParameter
---@field IsEnterSEMode boolean
---@field OverrideEnterBtnClickCallback fun(seId:number,heroIds):boolean @此项非nil 时 点击进入按钮 调用此函数， 返回值为true 时关闭界面
---@field SeId number
---@field fromType SEHudTroopMediatorDefine.FromType
---@field fromPosX number
---@field fromPosY number

---@class SEHudTroopMediator : BaseUIMediator
local SEHudTroopMediator = class('SEHudTroopMediator', BaseUIMediator)

function SEHudTroopMediator:ctor()
    self._mode = MODE_CARD_EDIT
    self._groupIndex = 1
    self._selectedHeroIndex = 0
    self._cardGroupList = {}

    self._statusRecordParent = nil
    self._pageSwitcher = nil
    self._usableHeroCount = 0
    self._heroAreas = {}
    self._heroButtons = {}
    self._heroImages = {}
    self._heroSelected = {}
    self._heroStatus = {}
    ---@type table<number, NotificationNode>
    self._heroRedDots = {}
    self._heroAdds = {}
    self._heroUsableCardCount = {}
    self._heroUsedCardCount = {}
    self._petCards = {}
    self._heroLevelTexts = {}
    self._heroStrongLevels = {}
    self._heroStrongLevelImages = {}
    self._heroNameTexts = {}
    self._heroRemoveButtons = {}
    self._heroCardInfos = {}
    ---@type table<number, table<number, CommonSkillCard>>
    self._heroCards = {}
    self._usedHeroCount = {}
    -- self._petCardSelectedCount = 0
    -- self._petCardTotalCount = 0

    ---@type SEHudTroopMediatorParameter
    self._param = {}

    self._draggingHeroIndex = -1
    self._cardSelectParam = {
        selectedGroupIndex = 0,
        selectedHeroIndex = 0,
        selectedHeroCfg = nil,
        onClose = Delegate.GetOrCreate(self, self.OnCardSelectPanelClose),
    }
end

function SEHudTroopMediator:OnCreate(param)
    self._param = param or {}
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPresetCardGroup.MsgPath, Delegate.GetOrCreate(self, self.Refresh))
    self:InitObjects()
end

function SEHudTroopMediator:OnShow(param)
    self:InitData()
    self:Refresh()
    ModuleRefer.GuideModule:CallGuide(require('GuideConst').CallID.SEHudTroopShow)
end

function SEHudTroopMediator:OnHide(param)

end

function SEHudTroopMediator:OnClose(data)
    if (self._param and self._param.onClose) then
        self._param.onClose(self._param.closeParam)
    end
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPresetCardGroup.MsgPath, Delegate.GetOrCreate(self, self.Refresh))
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:InitObjects()
    self._enterButtonNode = self:GameObject("p_btn_enter")
    self._enterButton = self:Button("p_comp_btn_a_l_u2_editor", Delegate.GetOrCreate(self, self.EnterSE))
    self._enterButtonText = self:Text("p_btn_enter_text", "setroop_instance_entrance")
    self._backButton = self:LuaObject("child_common_btn_back")
    self._statusRecordParent = self:BindComponent("content", typeof(CS.StatusRecordParent))
    self._heroArea = self:GameObject("p_group_heroes")
    self._cardArea = self:GameObject("p_group_cards")
    self._heroAreas[HERO_INDEX_LEFT] = self:GameObject("p_group_hero_l")
    self._heroAreas[HERO_INDEX_MIDDLE] = self:GameObject("p_group_hero")
    self._heroAreas[HERO_INDEX_RIGHT] = self:GameObject("p_group_hero_r")
    self._heroButtons[HERO_INDEX_LEFT] = self:Button("p_hero_l", Delegate.GetOrCreate(self, self.HeroClickLeft))
    self._heroButtons[HERO_INDEX_MIDDLE] = self:Button("p_hero", Delegate.GetOrCreate(self, self.HeroClickMiddle))
    self._heroButtons[HERO_INDEX_RIGHT] = self:Button("p_hero_r", Delegate.GetOrCreate(self, self.HeroClickRight))
    self._heroImages[HERO_INDEX_LEFT] = self:Image("p_hero_l")
    self._heroSelected[HERO_INDEX_LEFT] = self:GameObject("p_hero_select_l")
    self._heroStatus[HERO_INDEX_LEFT] = self:GameObject("p_status_b_l")
    self._heroRedDots[HERO_INDEX_LEFT] = self:LuaObject("p_hero_reddot_l")
    self._heroAdds[HERO_INDEX_LEFT] = self:Button("p_btn_hero_none_l", Delegate.GetOrCreate(self, self.HeroClickLeft))
    self._heroImages[HERO_INDEX_MIDDLE] = self:Image("p_hero")
    self._heroSelected[HERO_INDEX_MIDDLE] = self:GameObject("p_hero_select")
    self._heroStatus[HERO_INDEX_MIDDLE] = self:GameObject("p_status_b")
    self._heroRedDots[HERO_INDEX_MIDDLE] = self:LuaObject("p_hero_reddot")
    self._heroAdds[HERO_INDEX_MIDDLE] = self:Button("p_btn_hero_none", Delegate.GetOrCreate(self, self.HeroClickMiddle))
    self._heroImages[HERO_INDEX_RIGHT] = self:Image("p_hero_r")
    self._heroSelected[HERO_INDEX_RIGHT] = self:GameObject("p_hero_select_r")
    self._heroStatus[HERO_INDEX_RIGHT] = self:GameObject("p_status_b_r")
    self._heroRedDots[HERO_INDEX_RIGHT] = self:LuaObject("p_hero_reddot_r")
    self._heroAdds[HERO_INDEX_RIGHT] = self:Button("p_btn_hero_none_r", Delegate.GetOrCreate(self, self.HeroClickRight))
    self._pageSwitcher = self:BindComponent("group_pointer", typeof(CS.StatusRecordParent))
    self._groupPrevButton = self:Button("p_btn_left", Delegate.GetOrCreate(self, self.PrevGroup))
    self._groupNextButton = self:Button("p_btn_right", Delegate.GetOrCreate(self, self.NextGroup))
    self._petCardsText = self:Text("p_text_common_cards", "setroop_petcard_group")
    self._petCardAreaButton = self:Button("p_common_card", Delegate.GetOrCreate(self, self.SelectPetCards))
    self._petCards[1] = self:LuaObject("common_card_1")
    self._petCards[2] = self:LuaObject("common_card_2")
    self._petCards[3] = self:LuaObject("common_card_3")
    self._heroStrongLevels[HERO_INDEX_LEFT] = self:GameObject("p_icon_strong_l")
    self._heroStrongLevels[HERO_INDEX_MIDDLE] = self:GameObject("p_icon_strong")
    self._heroStrongLevels[HERO_INDEX_RIGHT] = self:GameObject("p_icon_strong_r")
    self._heroStrongLevelImages[HERO_INDEX_LEFT] = self:Image("p_icon_strengthen_l")
    self._heroStrongLevelImages[HERO_INDEX_MIDDLE] = self:Image("p_icon_strengthen")
    self._heroStrongLevelImages[HERO_INDEX_RIGHT] = self:Image("p_icon_strengthen_r")
    self._heroLevelTexts[HERO_INDEX_LEFT] = self:Text("p_text_lv_l")
    self._heroLevelTexts[HERO_INDEX_MIDDLE] = self:Text("p_text_lv")
    self._heroLevelTexts[HERO_INDEX_RIGHT] = self:Text("p_text_lv_r")
    self._heroNameTexts[HERO_INDEX_LEFT] = self:Text("p_text_hero_name_l")
    self._heroNameTexts[HERO_INDEX_MIDDLE] = self:Text("p_text_hero_name")
    self._heroNameTexts[HERO_INDEX_RIGHT] = self:Text("p_text_hero_name_r")
    self._heroRemoveButtons[HERO_INDEX_LEFT] = self:Button("p_btn_detail_l", Delegate.GetOrCreate(self, self.RemoveHeroLeft))
    self._heroRemoveButtons[HERO_INDEX_RIGHT] = self:Button("p_btn_detail_r", Delegate.GetOrCreate(self, self.RemoveHeroRight))
    self._heroCardInfos[HERO_INDEX_LEFT] = self:GameObject("p_card_a_l")
    self._heroCardInfos[HERO_INDEX_MIDDLE] = self:GameObject("p_card_a")
    self._heroCardInfos[HERO_INDEX_RIGHT] = self:GameObject("p_card_a_r")
    self._heroCards[HERO_INDEX_LEFT] = {}
    for i = 1, MAX_HERO_CARD_COUNT do
        self._heroCards[HERO_INDEX_LEFT][i] = self:LuaObject("hero_card_l_" .. i)
    end
    self._heroCards[HERO_INDEX_MIDDLE] = {}
    for i = 1, MAX_HERO_CARD_COUNT do
        self._heroCards[HERO_INDEX_MIDDLE][i] = self:LuaObject("hero_card_" .. i)
    end
    self._heroCards[HERO_INDEX_RIGHT] = {}
    for i = 1, MAX_HERO_CARD_COUNT do
        self._heroCards[HERO_INDEX_RIGHT][i] = self:LuaObject("hero_card_r_" .. i)
    end
    self._groupNameText = self:Text("p_text_troop_name")
    self._groupGeneralText = self:Text("p_text_general", "setroop_leader")
    self._groupLeaderNameText = self:Text("p_text_leader_name")
    self._groupBuffText = self:Text("p_text_buff")
    self._costText = self:Text("p_text_fee")
    ---@type NotificationNode
    self._petCardsRedDot = self:LuaObject("common_cards_reddot")
    self._textBuff = self:Text("p_text_buff")
    self._powerEnough = self:GameObject("p_power_enough")
    self._powerNotEnough = self:GameObject("p_power_not_enough")
    self._textPowerEnough = self:Text("p_text_power_enough")
    self._textPowerNotEnough = self:Text("p_text_power_not_enough")
    self._textPowerRecommend = self:Text("p_text_power_recommend")

    -- 拖动事件
    self:DragEvent("p_hero_l",
        Delegate.GetOrCreate(self, self.OnHeroLeftDragStart),
        Delegate.GetOrCreate(self, self.OnHeroDrag),
        Delegate.GetOrCreate(self, self.OnHeroDragEnd),
        false)
    self:DragEvent("p_hero",
        Delegate.GetOrCreate(self, self.OnHeroMiddleDragStart),
        Delegate.GetOrCreate(self, self.OnHeroDrag),
        Delegate.GetOrCreate(self, self.OnHeroDragEnd),
        false)
    self:DragEvent("p_hero_r",
        Delegate.GetOrCreate(self, self.OnHeroRightDragStart),
        Delegate.GetOrCreate(self, self.OnHeroDrag),
        Delegate.GetOrCreate(self, self.OnHeroDragEnd),
        false)
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:InitData()
    self._backButton:FeedData({title = I18N.Get("setroop_system_name")})
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:Refresh()
    self:RefreshData()
    self:RefreshUI()
end

function SEHudTroopMediator:RefreshData()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    --g_Logger.Log("*** PlayerPresentCardGroup: %s", player.PlayerWrapper2.PlayerPresetCardGroup)
    --g_Logger.Log("PlayerHero: %s", player.Hero)
    self._usableHeroCount = 0
    if (player.Hero and player.Hero.HeroInfos) then
        for _, _ in pairs(player.Hero.HeroInfos) do
            self._usableHeroCount = self._usableHeroCount + 1
        end
    end

    -- 统计伙伴卡
    -- self._petCardTotalCount = 0
    -- self._petCardSelectedCount = 0
    -- for _, cell in ConfigRefer.Card:ipairs() do
    --     if (cell:CardTypeEnum() == CardType.Pet) then
    --         if (player.PlayerWrapper.PlayerCard.CardInfos[cell:Id()]) then
    --             self._petCardTotalCount = self._petCardTotalCount + 1
    --         end
    --     end
    -- end

    -- 遍历卡组
    for i = 1, MAX_GROUP_COUNT do
        local cardGroup = player.PlayerWrapper2.PlayerPresetCardGroup.Groups[i]
        if (cardGroup) then
            self._cardGroupList[i] = {}
            self._cardGroupList[i].name = cardGroup.Name
            self._cardGroupList[i].heroConfigList = {}
            self._cardGroupList[i].heroInfoList = {}
            self._cardGroupList[i].heroCardConfigIdList = {}
            self._cardGroupList[i].petCardConfigIdList = {}
            self._cardGroupList[i].totalHeroPower = 0
            self._usedHeroCount[i] = 0
            self._heroUsableCardCount[i] = {}
            self._heroUsedCardCount[i] = {}

            -- 英雄列表
            if (cardGroup.HeroList) then
                for j = 1, MAX_HERO_COUNT do
                    if (cardGroup.HeroList[j]) then
                        local heroInfo = player.Hero and player.Hero.HeroInfos and player.Hero.HeroInfos[cardGroup.HeroList[j].CfgId] or nil
                        local heroCfg = ConfigRefer.Heroes:Find(cardGroup.HeroList[j].CfgId)
                        if (heroCfg) then
                            self._heroUsableCardCount[i][j] = 0
                            self._heroUsedCardCount[i][j] = 0
                            self._usedHeroCount[i] = self._usedHeroCount[i] + 1
                            self._cardGroupList[i].heroConfigList[j] = heroCfg
                            self._cardGroupList[i].totalHeroPower =
                                self._cardGroupList[i].totalHeroPower
                                + HeroModule:CalcHeroPower(cardGroup.HeroList[j].CfgId)
                            self._cardGroupList[i].heroInfoList[j] = heroInfo
                            self._cardGroupList[i].heroCardConfigIdList[j] = {}

                            -- 英雄卡牌
                            for k = 1, heroCfg:CardsLength() do
                                local cardId = heroCfg:Cards(k)
                                if (ModuleRefer.HeroModule:CheckCardUnlock(heroCfg:Id(), cardId)) then
                                    self._heroUsableCardCount[i][j] = self._heroUsableCardCount[i][j] + 1
                                end
                            end
                            if (cardGroup.HeroList[j].HeroCardIdList) then
                                for k = 1, MAX_HERO_CARD_COUNT do
                                    self._cardGroupList[i].heroCardConfigIdList[j][k] = cardGroup.HeroList[j].HeroCardIdList[k]
                                    if (cardGroup.HeroList[j].HeroCardIdList[k] and cardGroup.HeroList[j].HeroCardIdList[k] > 0) then
                                        self._heroUsedCardCount[i][j] = self._heroUsedCardCount[i][j] + 1
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- 伙伴卡牌
            -- if (cardGroup.PetCardList) then
            --     for j = 1, MAX_PET_CARD_COUNT do
            --         self._cardGroupList[i].petCardConfigIdList[j] = cardGroup.PetCardList[j]

            --         local card = CardModule:GetCardByCfgId(cardGroup.PetCardList[j])
            --         if (card) then
            --             self._petCardSelectedCount = self._petCardSelectedCount + 1
            --             -- 已经上阵的伙伴卡取消新卡状态
            --             if (CardModule:IsNewCard(card)) then
            --                 CardModule:SetIsNewCard(card, false, true)
            --             end
            --         end
            --     end
            --     -- 排序(伙伴卡是有序的，不再排序)
            --     --table.sort(self._cardGroupList[i].petCardConfigIdList, self.SortPetCard)
            -- end
        end
    end
end

-- function SEHudTroopMediator.SortPetCard(a, b)
--     local acfg = ConfigRefer.Card:Find(a)
--     local bcfg = ConfigRefer.Card:Find(b)
--     if (acfg and not bcfg) then return true end
--     if (not acfg and bcfg) then return false end
--     if (acfg:Energy() ~= bcfg:Energy()) then
--         return acfg:Energy() < bcfg:Energy()
--     end
--     return a < b
-- end

function SEHudTroopMediator:GetHeroConfig(index)
    return self._cardGroupList[self._groupIndex]
        and self._cardGroupList[self._groupIndex].heroConfigList
        and self._cardGroupList[self._groupIndex].heroConfigList[index]
        or nil
end

function SEHudTroopMediator:GetHeroInfo(index)
    return self._cardGroupList[self._groupIndex]
        and self._cardGroupList[self._groupIndex].heroInfoList
        and self._cardGroupList[self._groupIndex].heroInfoList[index]
        or nil
end

function SEHudTroopMediator:RefreshUI()
    self._enterButtonNode:SetActive(self._param.IsEnterSEMode == true)
    self._groupNameText.text = I18N.Get(self._cardGroupList[self._groupIndex].name)
    self._statusRecordParent:SetState(self._mode)

    local totalEnergy = 0
    local totalCardCount = 0

    -- 英雄
    for i = 1, MAX_HERO_COUNT do
        self._heroSelected[i]:SetActive(self._selectedHeroIndex == i)
        local heroCfg = self:GetHeroConfig(i)
        local heroInfo = self:GetHeroInfo(i)
        local heroResCfg = heroCfg and ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg()) or nil
        local heroAvailable = heroCfg and heroResCfg
        self._heroStatus[i]:SetActive(not heroAvailable)
        if (not heroAvailable) then
            self._heroRedDots[i]:SetVisible(false)
            self._heroRedDots[i].redDot:SetActive(self._usedHeroCount[self._groupIndex] < self._usableHeroCount)
        end
        self._heroImages[i].gameObject:SetActive(heroAvailable)
        self._heroCardInfos[i]:SetActive(heroAvailable)
        if (heroAvailable) then
            -- 英雄图片
            self:LoadSprite(heroResCfg:BodyPaint(), self._heroImages[i])

            -- 英雄信息
            self._heroNameTexts[i].text = I18N.Get(heroCfg:Name())
            if (i == HERO_INDEX_MIDDLE) then
                self._groupLeaderNameText.text = I18N.Get(heroCfg:Name())
            end
            if (heroInfo) then
                self._heroLevelTexts[i].text = tostring(heroInfo.Level)
                self._heroStrongLevels[i]:SetActive(heroInfo.StarLevel and heroInfo.StarLevel > 0)
                HeroModule:LoadHeroStarLevelImage(heroInfo.StarLevel, self._heroStrongLevelImages[i])
            end

            -- 英雄卡牌
            local clickCallback
            if (i == HERO_INDEX_LEFT) then
                clickCallback = Delegate.GetOrCreate(self, self.OnClickCardsLeft)
            elseif (i == HERO_INDEX_MIDDLE) then
                clickCallback = Delegate.GetOrCreate(self, self.OnClickCardsMiddle)
            else
                clickCallback = Delegate.GetOrCreate(self, self.OnClickCardsRight)
            end
            for j = 1, MAX_HERO_CARD_COUNT do
                local cardId = self._cardGroupList[self._groupIndex].heroCardConfigIdList[i][j]
                if (not cardId or cardId <= 0) then
                    --self._heroCards[i][j].CSComponent.gameObject:SetActive(false)
                    self._heroCards[i][j]:FeedData({
                        showAddNode = true,
                        onClick = clickCallback,
                    })
                    self._heroCards[i][j].notification:SetVisible(true)
                    self._heroCards[i][j].notification.redDot:SetVisible(self._heroUsedCardCount[self._groupIndex][i] < self._heroUsableCardCount[self._groupIndex][i])
                else
                    --self._heroCards[i][j].CSComponent.gameObject:SetActive(true)
                    self._heroCards[i][j]:FeedData({
                        cardId = cardId,
                        onClick = clickCallback
                    })
                    self._heroCards[i][j].notification:SetVisible(false)
                    totalEnergy = totalEnergy + self._heroCards[i][j]:GetEnergy()
                    totalCardCount = totalCardCount + 1
                end
            end
        end
    end

    -- 伙伴卡牌
    -- for i = 1, MAX_PET_CARD_COUNT do
    --     local cardCfgId = self._cardGroupList[self._groupIndex].petCardConfigIdList[i]
    --     if (cardCfgId and cardCfgId > 0) then
    --         --self._petCards[i].CSComponent.gameObject:SetActive(true)
    --         self._petCards[i]:FeedData({cardId = cardCfgId})
    --         self._petCards[i].notification.redDot:SetActive(false)
    --         totalEnergy = totalEnergy + self._petCards[i]:GetEnergy()
    --         totalCardCount = totalCardCount + 1
    --     else
    --         --self._petCards[i].CSComponent.gameObject:SetActive(false)
    --         self._petCards[i]:FeedData({
    --             showAddNode = true,
    --             onClick = Delegate.GetOrCreate(self, self.SelectPetCards),
    --         })
    --         self._petCards[i].notification.redDot:SetActive(self._petCardSelectedCount < self._petCardTotalCount)
    --     end
    -- end
    -- NotificationModule:AttachToGameObject(CardModule:GetPetCardListRedDotData(), self._petCardsRedDot.go)

    -- 页码状态
    self._pageSwitcher:SetState(self._groupIndex - 1)

    -- 平均费用
    local averageCost = totalEnergy / totalCardCount
    self._costText.text = averageCost * 100 // 10 / 10

    -- 战力
    if (self._param.IsEnterSEMode == true) then
        local mapCell = ConfigRefer.MapInstance:Find(self._param.SeId)
        if (not mapCell) then
            self._powerEnough:SetActive(false)
            self._powerNotEnough:SetActive(false)
            return
        end
        self._textPowerRecommend.text = I18N.GetWithParams(I18N.Temp().text_power_recommended, mapCell:Power())
        local power = self._cardGroupList[self._groupIndex].totalHeroPower
        if (power >= mapCell:Power()) then
            self._powerEnough:SetActive(true)
            self._powerNotEnough:SetActive(false)
            self._textPowerEnough.text = I18N.GetWithParams(I18N.Temp().text_power_current, power)
        else
            self._powerEnough:SetActive(false)
            self._powerNotEnough:SetActive(true)
            self._textPowerNotEnough.text = I18N.GetWithParams(I18N.Temp().text_power_current, power)
        end
    else
        self._powerEnough:SetActive(false)
        self._powerNotEnough:SetActive(false)
    end
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:HeroClickLeft()
    if (self._draggingHeroIndex > 0) then return end
    if (self._selectedHeroIndex ~= HERO_INDEX_LEFT) then
        self._selectedHeroIndex = HERO_INDEX_LEFT
        self:RefreshUI()
    end
    self:SelectHero()
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:HeroClickMiddle()
    if (self._draggingHeroIndex > 0) then return end
    if (self._selectedHeroIndex ~= HERO_INDEX_MIDDLE) then
        self._selectedHeroIndex = HERO_INDEX_MIDDLE
        self:RefreshUI()
    end
    self:SelectHero()
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:HeroClickRight()
    if (self._draggingHeroIndex > 0) then return end
    if (self._selectedHeroIndex ~= HERO_INDEX_RIGHT) then
        self._selectedHeroIndex = HERO_INDEX_RIGHT
        self:RefreshUI()
    end
    self:SelectHero()
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:PrevGroup()
    self._groupIndex = self._groupIndex - 1
    if (self._groupIndex < 1) then
        self._groupIndex = MAX_GROUP_COUNT
    end
    self:RefreshUI()
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:NextGroup()
    self._groupIndex = self._groupIndex + 1
    if (self._groupIndex > MAX_GROUP_COUNT) then
        self._groupIndex = 1
    end
    self:RefreshUI()
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:RemoveHeroLeft()
    local cfg = self:GetHeroConfig(HERO_INDEX_LEFT)
    if (not cfg) then return end

    self:SendModifyHero(self._groupIndex - 1, HERO_INDEX_LEFT - 1, 0)
    self._usedHeroCount[self._groupIndex] = self._usedHeroCount[self._groupIndex] - 1
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:RemoveHeroRight()
    local cfg = self:GetHeroConfig(HERO_INDEX_RIGHT)
    if (not cfg) then return end

    self:SendModifyHero(self._groupIndex - 1, HERO_INDEX_RIGHT - 1, 0)
    self._usedHeroCount[self._groupIndex] = self._usedHeroCount[self._groupIndex] - 1
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:SelectPetCards()
    g_Game.UIManager:Open(UIMediatorNames.SEHudCommonCardSelectMediator, {
        selectedGroupIndex = self._groupIndex,
        onClose = Delegate.GetOrCreate(self, self.OnCommonCardSelectPanelClose),
    })
end

---@param self SEHudTroopMediator
---@param selectedCards table<number>
function SEHudTroopMediator:OnCommonCardSelectPanelClose(selectedCards)
    self._cardGroupList[self._groupIndex].petCardConfigIdList = selectedCards
    table.sort(self._cardGroupList[self._groupIndex].petCardConfigIdList, self.SortPetCard)
    self:RefreshUI()
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:HideAllHeroCardInfos()
    self._heroCardInfos[HERO_INDEX_LEFT]:SetActive(false)
    self._heroCardInfos[HERO_INDEX_MIDDLE]:SetActive(false)
    self._heroCardInfos[HERO_INDEX_RIGHT]:SetActive(false)
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:ShowAllHeroCardInfos()
    if (self:GetHeroConfig(HERO_INDEX_LEFT)) then self._heroCardInfos[HERO_INDEX_LEFT]:SetActive(true) end
    if (self:GetHeroConfig(HERO_INDEX_MIDDLE)) then self._heroCardInfos[HERO_INDEX_MIDDLE]:SetActive(true) end
    if (self:GetHeroConfig(HERO_INDEX_RIGHT)) then self._heroCardInfos[HERO_INDEX_RIGHT]:SetActive(true) end
end

function SEHudTroopMediator:OnHeroLeftDragStart(go, data)
    self._draggingHeroIndex = HERO_INDEX_LEFT
    self:HideAllHeroCardInfos()
    go.transform.parent:SetAsLastSibling()
    self:OnHeroDrag(go, data)
end

function SEHudTroopMediator:OnHeroMiddleDragStart(go, data)
    self._draggingHeroIndex = HERO_INDEX_MIDDLE
    self:HideAllHeroCardInfos()
    go.transform.parent:SetAsLastSibling()
    self:OnHeroDrag(go, data)
end

function SEHudTroopMediator:OnHeroRightDragStart(go, data)
    self._draggingHeroIndex = HERO_INDEX_RIGHT
    self:HideAllHeroCardInfos()
    go.transform.parent:SetAsLastSibling()
    self:OnHeroDrag(go, data)
end

function SEHudTroopMediator:OnHeroDrag(go, data)
    -- 移动英雄
    go.transform.position =
        g_Game.UIManager:GetUICamera():ScreenToWorldPoint(
            CS.UnityEngine.Vector3(data.position.x, data.position.y, 0))
end

function SEHudTroopMediator:OnHeroDragEnd(go, data)
    -- 判定落点区域
    local leftRect = self._heroButtons[HERO_INDEX_LEFT].gameObject.transform:GetScreenRect(g_Game.UIManager:GetUICamera())
    local middleRect = self._heroButtons[HERO_INDEX_MIDDLE].gameObject.transform:GetScreenRect(g_Game.UIManager:GetUICamera())
    local rightRect = self._heroButtons[HERO_INDEX_RIGHT].gameObject.transform:GetScreenRect(g_Game.UIManager:GetUICamera())
    local screenPos = CS.UnityEngine.Vector2(data.position.x, CS.UnityEngine.Screen.height - data.position.y)
    local inLeft = leftRect:Contains(screenPos)
    local inMiddle = middleRect:Contains(screenPos)
    local inRight = rightRect:Contains(screenPos)
    local targetIndex

    go.transform.localPosition = CS.UnityEngine.Vector3.zero
    self:ShowAllHeroCardInfos()

    if (self._draggingHeroIndex == HERO_INDEX_LEFT) then
        if (inMiddle) then
            targetIndex = HERO_INDEX_MIDDLE
        elseif (inRight) then
            targetIndex = HERO_INDEX_RIGHT
        else
            self._draggingHeroIndex = 0
            return
        end
    elseif (self._draggingHeroIndex == HERO_INDEX_MIDDLE) then
        if (inLeft) then
            targetIndex = HERO_INDEX_LEFT
        elseif (inRight) then
            targetIndex = HERO_INDEX_RIGHT
        else
            self._draggingHeroIndex = 0
            return
        end
    else
        if (inMiddle) then
            targetIndex = HERO_INDEX_MIDDLE
        elseif (inLeft) then
            targetIndex = HERO_INDEX_LEFT
        else
            self._draggingHeroIndex = 0
            return
        end
    end
    local targetHeroCfg = self:GetHeroConfig(targetIndex)

    -- 队长不能替换为空
    if (self._draggingHeroIndex == HERO_INDEX_MIDDLE and not targetHeroCfg) then
        self._draggingHeroIndex = 0
        return
    end

    g_Logger.Log("swap hero %s for %s", self._draggingHeroIndex, targetIndex)

    -- 交换
    self:SwapHero(self._draggingHeroIndex, targetIndex)
    self._draggingHeroIndex = 0
end

--- 交换两个英雄
---@param self SEHudTroopMediator
---@param index1 number
---@param index2 number
function SEHudTroopMediator:SwapHero(index1, index2)
    -- 发送协议
    local msg = require("ExchangePresetHeroParameter").new()
    msg.args.Group = self._groupIndex - 1
    msg.args.Index1 = index1 - 1
    msg.args.Index2 = index2 - 1
    msg:Send()
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:OnClickCardsLeft()
    self:SelectCards(HERO_INDEX_LEFT)
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:OnClickCardsMiddle()
    self:SelectCards(HERO_INDEX_MIDDLE)
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:OnClickCardsRight()
    self:SelectCards(HERO_INDEX_RIGHT)
end

---@param self SEHudTroopMediator
---@param index number
function SEHudTroopMediator:SelectCards(index)
    self._selectedHeroIndex = index
    self:RefreshUI()
    self._cardSelectParam.selectedGroupIndex = self._groupIndex
    self._cardSelectParam.selectedHeroIndex = index
    self._cardSelectParam.selectedHeroCfg = self:GetSelectedHeroConfig()
    g_Game.UIManager:Open(UIMediatorNames.SEHudHeroCardSelectMediator, self._cardSelectParam)
end

---@param self SEHudTroopMediator
---@param selectedCardList table
function SEHudTroopMediator:OnCardSelectPanelClose(selectedCardList)
    -- 刷新数据
    if (selectedCardList) then
        self._cardGroupList[self._groupIndex].heroCardConfigIdList[self._selectedHeroIndex] = selectedCardList
    end
    self._selectedHeroIndex = 0
    self:RefreshUI()
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:MovePanelToRight()
    self._petCardAreaButton.gameObject:SetActive(false)
    
    self._heroArea.transform:DOLocalMoveX(HERO_PANEL_TO_X, PANEL_TRANSITION_TIME)
    self._heroArea.transform:DOLocalMoveY(HERO_PANEL_TO_Y, PANEL_TRANSITION_TIME)
    self._heroArea.transform:DOScale(HERO_PANEL_TO_SCALE, PANEL_TRANSITION_TIME)
    self._cardArea.transform:DOLocalMoveX(CARD_PANEL_TO_X, PANEL_TRANSITION_TIME)
    self._cardArea.transform:DOLocalMoveY(CARD_PANEL_TO_Y, PANEL_TRANSITION_TIME)
    self._cardArea.transform:DOScale(CARD_PANEL_TO_SCALE, PANEL_TRANSITION_TIME)

    self._heroAreas[HERO_INDEX_LEFT].transform:DOScale(HERO_LEFT_TO_SCALE, PANEL_TRANSITION_TIME)
    self._heroAreas[HERO_INDEX_RIGHT].transform:DOScale(HERO_RIGHT_TO_SCALE, PANEL_TRANSITION_TIME)
    self._heroCardInfos[HERO_INDEX_LEFT].transform:DOScale(CARD_LEFT_TO_SCALE, PANEL_TRANSITION_TIME)
    self._heroCardInfos[HERO_INDEX_RIGHT].transform:DOScale(CARD_RIGHT_TO_SCALE, PANEL_TRANSITION_TIME)
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:RestorePanelPosition()
    self._petCardAreaButton.gameObject:SetActive(true)

    self._heroArea.transform:DOLocalMoveX(HERO_PANEL_FROM_X, PANEL_TRANSITION_TIME)
    self._heroArea.transform:DOLocalMoveY(HERO_PANEL_FROM_Y, PANEL_TRANSITION_TIME)
    self._heroArea.transform:DOScale(HERO_PANEL_FROM_SCALE, PANEL_TRANSITION_TIME)
    self._cardArea.transform:DOLocalMoveX(CARD_PANEL_FROM_X, PANEL_TRANSITION_TIME)
    self._cardArea.transform:DOLocalMoveY(CARD_PANEL_FROM_Y, PANEL_TRANSITION_TIME)
    self._cardArea.transform:DOScale(CARD_PANEL_FROM_SCALE, PANEL_TRANSITION_TIME)

    self._heroAreas[HERO_INDEX_LEFT].transform:DOScale(HERO_LEFT_FROM_SCALE, PANEL_TRANSITION_TIME)
    self._heroAreas[HERO_INDEX_RIGHT].transform:DOScale(HERO_RIGHT_FROM_SCALE, PANEL_TRANSITION_TIME)
    self._heroCardInfos[HERO_INDEX_LEFT].transform:DOScale(CARD_LEFT_FROM_SCALE, PANEL_TRANSITION_TIME)
    self._heroCardInfos[HERO_INDEX_RIGHT].transform:DOScale(CARD_RIGHT_FROM_SCALE, PANEL_TRANSITION_TIME)
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:SelectHero()
    self:MovePanelToRight()
    local teamHeroList = {}
    for _, heroCfg in pairs(self._cardGroupList[self._groupIndex].heroConfigList) do
        teamHeroList[heroCfg:Id()] = heroCfg
    end
    g_Game.UIManager:Open(UIMediatorNames.SEHudHeroSelectMediator, {
        selectedHeroIndex = self._selectedHeroIndex,
        selectedHeroConfig = self:GetSelectedHeroConfig(),
        teamHeroList = teamHeroList,
        onClose = Delegate.GetOrCreate(self, self.OnHeroSelectPanelClose),
    })
end

---@param self SEHudTroopMediator
---@param heroCfg HeroesConfigCell
function SEHudTroopMediator:OnHeroSelectPanelClose(heroCfg)
    self:RestorePanelPosition()

    -- 设置英雄
    if (heroCfg) then
        local selectedCfg = self:GetSelectedHeroConfig()
        
        -- 未改动
        if (selectedCfg and selectedCfg:Id() == heroCfg:Id()) then
            self._selectedHeroIndex = 0
            self:RefreshUI()
            return
        end

        -- 队长与空位不能交换
        local leaderCfg = self:GetHeroConfig(HERO_INDEX_MIDDLE)
        if (not selectedCfg and leaderCfg:Id() == heroCfg:Id()) then
            self._selectedHeroIndex = 0
            self:RefreshUI()
            return
        end

        -- 交换
        local newIndex = self:GetIndexByConfig(heroCfg)
        if (newIndex > 0) then
            self:SwapHero(self._selectedHeroIndex, newIndex)
            self._selectedHeroIndex = 0
            return
        end

        -- 设置新英雄
        self:SendModifyHero(self._groupIndex - 1, self._selectedHeroIndex - 1, heroCfg:Id())
        self._usedHeroCount[self._groupIndex] = self._usedHeroCount[self._groupIndex] + 1
    end
    self._selectedHeroIndex = 0
    self:RefreshUI()
end

---@param self SEHudTroopMediator
function SEHudTroopMediator:GetSelectedHeroConfig()
    return self:GetHeroConfig(self._selectedHeroIndex)
end

---@param self SEHudTroopMediator
---@param heroCfg HeroesConfigCell
function SEHudTroopMediator:GetIndexByConfig(heroCfg)
    if (not heroCfg) then return 0 end
    
    local middleCfg = self:GetHeroConfig(HERO_INDEX_MIDDLE)
    if (middleCfg:Id() == heroCfg:Id()) then return HERO_INDEX_MIDDLE end
    
    local leftCfg = self:GetHeroConfig(HERO_INDEX_LEFT)
    if (leftCfg and leftCfg:Id() == heroCfg:Id()) then return HERO_INDEX_LEFT end

    local rightCfg = self:GetHeroConfig(HERO_INDEX_RIGHT)
    if (rightCfg and rightCfg:Id() == heroCfg:Id()) then return HERO_INDEX_RIGHT end

    return 0
end

---@param self SEHudTroopMediator
---@param group number
---@param index number
---@param cfgId number
function SEHudTroopMediator:SendModifyHero(group, index, cfgId)
    local msg = require("ModifyPresetHeroParameter").new()
    msg.args.Group = group
    msg.args.Index = index
    msg.args.CfgId = cfgId
    msg:Send()
end

function SEHudTroopMediator:EnterSE()
    local heroIds = {}
    local heroCfgList = self._cardGroupList[self._groupIndex].heroConfigList
    for _, cfg in ipairs(heroCfgList) do
        table.insert(heroIds, cfg:Id())
    end

    -- 英雄卡牌数量检查
    local heroCardCount = 0
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local cardGroup = player.PlayerWrapper2.PlayerPresetCardGroup.Groups[self._groupIndex]
    if (cardGroup and cardGroup.HeroList) then
        for i = 1, MAX_HERO_COUNT do
            if (cardGroup.HeroList[i] and cardGroup.HeroList[i].HeroCardIdList) then
                for j= 1, MAX_HERO_CARD_COUNT do
                    if (cardGroup.HeroList[i].HeroCardIdList[j] and cardGroup.HeroList[i].HeroCardIdList[j] > 0) then
                        heroCardCount = heroCardCount + 1
                    end
                end
            end
        end
    end
    local mapConf = ConfigRefer.MapInstance:Find(self._param.SeId)
    if (not mapConf) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("se_mapenter_defaulterror"))
        return
    else
        local mapNeedCount = mapConf:FightEffectiveCardCount()
        local needCardCount = mapNeedCount
        if (mapNeedCount <= 0) then
            needCardCount = ConfigRefer.ConstSe:SeFightCardGroupEffectCount()
        end
        needCardCount = needCardCount + ConfigRefer.ConstSe:SeFightCardGroupCandidateCount()
        g_Logger.Trace("*** 该副本需要最少有%s张英雄卡才能进入, 当前有%s张", needCardCount, heroCardCount)
        if (heroCardCount < needCardCount) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("se_mapenter_cardlack", needCardCount))
            return
        end
    end

    if (self._param.OverrideEnterBtnClickCallback) then
        if (self._param.OverrideEnterBtnClickCallback(self._param.SeId, heroIds)) then
            self:CloseSelf()
        end
    else
        GotoUtils.GotoSceneSe(self._param.SeId, heroIds)
        self:CloseSelf()
    end
end

return SEHudTroopMediator
