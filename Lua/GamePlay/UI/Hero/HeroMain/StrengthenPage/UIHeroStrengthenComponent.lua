local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require("I18N")
local NotificationType = require("NotificationType")
local EventConst = require('EventConst')
local UIMediatorNames = require('UIMediatorNames')
local AttrValueType = require('AttrValueType')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local AudioConsts = require("AudioConsts")
local UIHelper = require("UIHelper")

---@class UIHeroStrengthenComponent : BaseUIComponent
---@field parentMediator UIHeroMainUIMediator
---@field heroList table<number,HeroConfigCache>
---@field compGroupLv UIHeroStrengthenSlotComponent
local UIHeroStrengthenComponent = class('UIHeroUpgradeComponent', BaseUIComponent)

function UIHeroStrengthenComponent:ctor()
    self.module = ModuleRefer.HeroModule
    self.inventory = ModuleRefer.InventoryModule

    self.duplicatedSkillIcons = {}
end

function UIHeroStrengthenComponent:OnCreate()

    self.stateCtrl = self:BindComponent('', typeof(CS.StatusRecordParent))
    self.compGroupLv = self:LuaObject('group_lv')

    self.goPower = self:GameObject('power')
    self.goArrow = self:GameObject('p_icon_arrow')
    self.textTitlePower = self:Text('p_text_title_power', I18N.Get("hero_power"))

    self.textPower = self:Text('p_text_power')
    self.textStrengthen = self:Text('p_text_strengthen')

    self.goTableBasicsShort = self:GameObject('p_table_basics_short')
    self.tableviewproTableBasicsShort = self:TableViewPro('p_table_basics_short')
    self.goTableBasicsLong = self:GameObject('p_table_basics_long')
    self.tableviewproTableBasicsLong = self:TableViewPro('p_table_basics_long')
    self.goOpen = self:GameObject('p_btn_open')
    self.btnOpen = self:Button('p_btn_open', Delegate.GetOrCreate(self, self.OnBtnOpenClicked))
    self.goClose = self:GameObject('p_btn_close')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))

    self.btnExchange = self:Button('p_btn_exchange', Delegate.GetOrCreate(self, self.OnBtnExchangeClicked))
    self.textQuantity = self:Text('p_text_quantity')
    self.textExchange = self:Text('p_text_exchange', I18N.Get("hero_piece_exchange"))


    --need Items
    self.goNeed = self:GameObject("p_need")
    self.textTitleNeed = self:Text('p_text_title_need', I18N.Get("hero_strengthen_item"))

    --Button States
    --state 0
    self.compChildCompB = self:LuaObject('p_comp_btn_strengthen')
    --state 1
    self.goStateB = self:GameObject('p_state_b')
    self.textB = self:Text('p_text_b', I18N.Get("hero_strengthen_full"))
    --state 2
    self.breakNodeCom = self:LuaObject('child_reddot_default')
    self.goStateA = self:GameObject('p_state_a')

    self.compChildCommonQuantity = self:LuaObject('child_common_quantity_l')
    self.goLv = self:GameObject('lv')
    self.textTitleNeed1 = self:Text('p_text_title_need_1', I18N.Get("hero_need_condition"))
    self.goLv:SetActive(false)
    self.goImgCheckLv = self:GameObject('p_img_check_lv')
    self.btnGoto = self:Button('p_btn_goto', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
    self.animationTrigger = self:AnimTrigger("trigger_strengthen")
    self.parentMediator = self:GetParentBaseUIMediator()
    self.goOpen:SetActive(false)
    self.goClose:SetActive(false)

    self.child_strengthen_hero_group = self:LuaObject('child_strengthen_hero_group')

    -- skill
    self.goSkill = self:GameObject('skill')
    ---@see BaseSkillIcon
    self.luaSkillIconTemplate = self:LuaBaseComponent('child_item_skill')
    self.textSkillLvBefore = self:Text('p_text_skill_before')
    self.textSkillLvAfter = self:Text('p_text_skill_after')
end

function UIHeroStrengthenComponent:OnBtnOpenClicked(args)
    self.isOpen = true
    self:ChangeState()
end

function UIHeroStrengthenComponent:OnBtnCloseClicked(args)
    self.isOpen = false
    self:ChangeState()
end

function UIHeroStrengthenComponent:ChangeState()
    --self.goTableBasicsShort:SetActive(not self.isOpen)
    --self.goTableBasicsLong:SetActive(self.isOpen)
    --self.goOpen:SetActive(not self.isOpen)
   -- self.goClose:SetActive(self.isOpen)
   --self.goNeed:SetActive(not (self.isMax or self.isOpen))
    self.goTableBasicsShort:SetActive(false)
   self.goTableBasicsLong:SetActive(true)
   self.goNeed:SetActive(not self.isMax)
end

function UIHeroStrengthenComponent:OnBtnExchangeClicked(args)
    g_Game.UIManager:Open(UIMediatorNames.ExchangeHeroDebrisMediator, {curHero= self.selectHero})
end

-- function UIHeroStrengthenComponent:OnAllVxObjectLoaded()

-- end


function UIHeroStrengthenComponent:OnShow()
    g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RefreshItems))
    local buttonBreak = {}
    buttonBreak.onClick = Delegate.GetOrCreate(self, self.OnBtnCompStrengthenClicked)
    buttonBreak.buttonText = I18N.Get("hero_btn_strengthen")

    buttonBreak.disableClick = Delegate.GetOrCreate(self, self.OnBtnCompBreakLimitClicked)
    self.compChildCompB:OnFeedData(buttonBreak)
    local selectHero = self.parentMediator:GetSelectHero()
    local isHasHero = selectHero:HasHero()
    local strengthLv = isHasHero and selectHero.dbData.StarLevel or 0
    self.child_strengthen_hero_group:FeedData(strengthLv)
    if self.selectHero and self.selectLv and self.selectLv == strengthLv and selectHero.id == self.selectHero.id then
        return
    end
    self.compChildCompB:SetEnabled(isHasHero)
    self.selectLv = strengthLv
    self.selectHero = selectHero
    self.strengthenConfig = ConfigRefer.HeroStrengthen:Find(self.selectHero.configCell:StrengthenCfg())
    local maxLevel = self.strengthenConfig:StrengthenInfoListLength()
    self.isMax = strengthLv >= maxLevel
    -- if self.loadedAllVx then
        self.compGroupLv:FeedData({
            strengthConfig = self.strengthenConfig,
            strengthLv = self.selectLv,
            animationTrigger = self.animationTrigger,
            needPlayNPropEffect = self.needPlayNPropEffect,
        })
        self:OnLevelSelect(self.selectLv)
    -- end

    local strengthNode = ModuleRefer.NotificationModule:GetDynamicNode("HeroStrengthNode" .. self.selectHero.id, NotificationType.HERO_STRENGTH_BTN)
    ModuleRefer.NotificationModule:AttachToGameObject(strengthNode, self.breakNodeCom.go, self.breakNodeCom.redDot)
    self.goStateA:SetActive(not self.isMax)
    self.goStateB:SetActive(self.isMax)
    self.btnExchange.gameObject:SetActive(not self.isMax)
    self:RefreshItems()

    -- 技能信息更新
    for _, icon in ipairs(self.duplicatedSkillIcons) do
        UIHelper.DeleteUIComponent(icon)
    end
    table.clear(self.duplicatedSkillIcons)
    local skillLvlBefore
    if self.selectLv == 0 then
        skillLvlBefore = 1
    else
        skillLvlBefore = self.strengthenConfig:StrengthenInfoList(self.selectLv):SkillLevel()
    end
    if self.isMax then
        self.goSkill:SetActive(false)
        self.luaSkillIconTemplate:SetVisible(false)
        return
    end
    local skillLvlAfter = self.strengthenConfig:StrengthenInfoList(self.selectLv + 1):SkillLevel()

    self.goSkill:SetActive(skillLvlBefore ~= skillLvlAfter)
    self.luaSkillIconTemplate:SetVisible(true)
    if skillLvlBefore == skillLvlAfter then
        return
    end
    for i = 1, selectHero.configCell:SlgSkillDisplayLength() do
        local icon = UIHelper.DuplicateUIComponent(self.luaSkillIconTemplate)
        local dispSkillId = selectHero.configCell:SlgSkillDisplay(i)
        local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(dispSkillId)
        local seSkillId = selectHero.configCell:CardsDisplay(i)
        ---@type BaseSkillIconData
        local skillData = {}
        skillData.skillId = slgSkillCell:SkillId()
        skillData.skillLevel = skillLvlBefore
        skillData.isSlg = true
        skillData.showLvl = true
        skillData.cardId = seSkillId
        skillData.index = i
        skillData.clickCallBack = function()
            ---@type UISkillCommonTipMediatorParameter
            local param = {}
            param.ShowHeroSkillTips = {
                slgSkillId = skillData.skillId,
                cardId = skillData.cardId,
                isLock = skillData.isLock,
                skillLevel = skillData.skillLevel,
                slgSkillCell = slgSkillCell,
                onGoto = skillData.onGoto,
                hasHero = false
            }
            g_Game.UIManager:Open(UIMediatorNames.UISkillCommonTipMediator, param)
        end
        icon:FeedData(skillData)
        self.duplicatedSkillIcons[#self.duplicatedSkillIcons + 1] = icon
        local pos = self.luaSkillIconTemplate.transform.localPosition
        pos.x = pos.x + 160 * (i - 1)
        icon.transform.localPosition = pos
    end

    if selectHero.configCell:SlgPartnerSkillCfg(1) > 0 then
        local icon = UIHelper.DuplicateUIComponent(self.luaSkillIconTemplate)
        local dispSkillId = selectHero.configCell:SlgPartnerSkillCfg(1)
        local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(dispSkillId)
        local seSkillId = selectHero.configCell:CardsDisplay(selectHero.configCell:CardsDisplayLength())
        ---@type BaseSkillIconData
        local skillData = {}
        skillData.skillId = slgSkillCell:SkillId()
        skillData.skillLevel = skillLvlBefore
        skillData.isSlg = true
        skillData.showLvl = true
        skillData.cardId = seSkillId
        skillData.index = i
        skillData.clickCallBack = function()
            ---@type UISkillCommonTipMediatorParameter
            local param = {}
            param.ShowHeroSkillTips = {
                slgSkillId = skillData.skillId,
                cardId = skillData.cardId,
                isLock = skillData.isLock,
                skillLevel = skillData.skillLevel,
                slgSkillCell = slgSkillCell,
                onGoto = skillData.onGoto,
                hasHero = false
            }
            g_Game.UIManager:Open(UIMediatorNames.UISkillCommonTipMediator, param)
        end
        icon:FeedData(skillData)
        self.duplicatedSkillIcons[#self.duplicatedSkillIcons + 1] = icon
        local pos = self.luaSkillIconTemplate.transform.localPosition
        pos.x = pos.x + 160 * 2
        icon.transform.localPosition = pos
    end

    self.textSkillLvBefore.text = skillLvlBefore
    self.textSkillLvAfter.text = skillLvlAfter
end

function UIHeroStrengthenComponent:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RefreshItems))
end

function UIHeroStrengthenComponent:RefreshItems()
    if self.isMax then
        self:OnBtnOpenClicked()
    else
        --self:OnBtnCloseClicked()
        self:OnBtnOpenClicked()
        local strengthenConfig = ConfigRefer.HeroStrengthen:Find(self.selectHero.configCell:StrengthenCfg())
        local info = strengthenConfig:StrengthenInfoList(self.selectLv + 1)
        local itemGroupId = info:CostItemGroupCfgId()
        local itemGroup = ConfigRefer.ItemGroup:Find(itemGroupId)
        local itemInfo = itemGroup:ItemGroupInfoList(1)
        local heroPieceId = itemInfo:Items()
        local heroPieceCfg = ConfigRefer.Item:Find(heroPieceId)
        local getMoreCfg = ConfigRefer.GetMore:Find(heroPieceCfg:GetMoreConfig())
        local costItemId = getMoreCfg:Exchange():Currency()
        local commonNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItemId)
        self.textQuantity.text = "x" .. commonNum
        self:FeedNeedItems(self.selectLv + 1)
    end
end

function UIHeroStrengthenComponent:OnLevelSelect(strengthLv)
    local powerIndexs = {1, 2, 3}
    self.attrList = {}
    self.goNeed:SetActive(not (self.isMax or self.isOpen))
    local heroId = self.selectHero.configCell:Id()
    if strengthLv == 0 then
        self.textPower.text = 0
    else
        local curPower = self.module:GetHeroStarAttributePowerByLevel(heroId, strengthLv)
        self.textPower.text = curPower
    end
    self.goArrow:SetActive(not self.isMax)
    self.textStrengthen.gameObject:SetActive(not self.isMax)
    local curStarAttr = self.module:GetHeroStarAttributeByLevel(heroId, strengthLv)
    if self.isMax then
        if curStarAttr then
            for _, data in pairs(curStarAttr.attributes) do
                if not table.ContainsValue(powerIndexs, data.typeInfo:Id()) then
                    local single = {}
                    single.needPlayNPropEffect = self.needPlayNPropEffect
                    single.icon = data.typeInfo:Icon()
                    single.name = I18N.Get(data.typeInfo:Name())
                    single.num = ModuleRefer.AttrModule:GetAttrPercentValueByType(data.typeInfo, data.value)
                    single.isPer = data.typeInfo:ValueType() ~= AttrValueType.Fix
                    self.attrList[#self.attrList + 1] = single
                end
            end
        end
    else
        local nextLevel = strengthLv + 1
        self:FeedNeedItems(nextLevel)
        local totalPower = self.module:GetHeroStarAttributePowerByLevel(heroId, nextLevel)
        self.textStrengthen.text = totalPower
        local nextStarAttr = self.module:GetHeroStarAttributeByLevel(heroId, nextLevel)
        if nextStarAttr then
            for _, data in pairs(nextStarAttr.attributes) do
                if not table.ContainsValue(powerIndexs, data.typeInfo:Id()) then
                    local single = {}
                    single.icon = data.typeInfo:Icon()
                    single.name = I18N.Get(data.typeInfo:Name())
                    local addValue = data.value
                    single.isPer = data.typeInfo:ValueType() ~= AttrValueType.Fix
                    single.showArrow = true
                    single.needPlayNPropEffect = self.needPlayNPropEffect
                    local numValue
                    local curValue
                    if strengthLv == 0 then
                        numValue = addValue
                        curValue = 0
                    else
                        if curStarAttr.attributes[data.type] then
                            curValue = curStarAttr.attributes[data.type].value
                            numValue= curValue + addValue
                        else
                            numValue = addValue
                            curValue = 0
                        end
                    end
                    single.num = ModuleRefer.AttrModule:GetAttrPercentValueByType(data.typeInfo, curValue)
                    single.add = ModuleRefer.AttrModule:GetAttrPercentValueByType(data.typeInfo, data.value)
                    if addValue - curValue > 0 then
                        self.attrList[#self.attrList + 1] = single
                    end
                end
            end
        end
    end
    self.needPlayNPropEffect = false
    self.tableviewproTableBasicsShort:Clear()
    self.tableviewproTableBasicsLong:Clear()
    for i = 1, #self.attrList do
        local single = self.attrList[i]
        single.index = i
        if i <= 3 then
            self.tableviewproTableBasicsShort:AppendData(single)
        end
        single.showBase = i % 2 == 0
        self.tableviewproTableBasicsLong:AppendData(single)
    end
    self.stateCtrl:Play(0)
    self:ChangeState()
end

function UIHeroStrengthenComponent:FeedNeedItems(lvl)
    local info = self.strengthenConfig:StrengthenInfoList(lvl)
    local itemGroupId = info:CostItemGroupCfgId()
    local itemGroup = ConfigRefer.ItemGroup:Find(itemGroupId)

    self.lackList = {}
    local itemInfo = itemGroup:ItemGroupInfoList(1)
    local itemId = itemInfo:Items()
    local itemHas = self.inventory:GetAmountByConfigId(itemId)
    local isLack = itemHas < itemInfo:Nums()
    if itemHas < itemInfo:Nums() then
        self.lackList = {{id = itemId, num = itemInfo:Nums() - itemHas}}
    end
    local param = {}
    param.itemId = itemId
    param.num1 = itemHas
    param.num2 = itemInfo:Nums()
    param.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
    param.useColor2 = true
    self.compChildCommonQuantity:FeedData(param)
    self.compChildCompB:SetEnabled(not isLack)
end

function UIHeroStrengthenComponent:OnBtnCompBreakLimitClicked()
    if #self.lackList > 0 then
        ModuleRefer.InventoryModule:OpenExchangePanel(self.lackList)
    end
end

function UIHeroStrengthenComponent:OnBtnCompStrengthenClicked(args)
    self.needPlayNPropEffect = true
    self.module:StrengthenHero(self.selectHero.id)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_promotion)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_STRENGTH_LEVEL_UP)
end

return UIHeroStrengthenComponent;
