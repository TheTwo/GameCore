local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local UIHelper = require('UIHelper')
local UIHeroLocalData = require('UIHeroLocalData')
local NumberFormatter = require("NumberFormatter")
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local EventConst = require('EventConst')
local NumberFormatter = require("NumberFormatter")
local HeroUIUtilities = require('HeroUIUtilities')
local HeroCancelBindPetParameter = require("HeroCancelBindPetParameter")
local ItemType = require('ItemType')
local UIMediatorNames = require("UIMediatorNames")
local HeroPieceToHeroParameter = require('HeroPieceToHeroParameter')
local HeroType = require("HeroType")
local NotificationType = require("NotificationType")
local HeroEquipType = require("HeroEquipType")
local AudioConsts = require("AudioConsts")
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local QualityColorHelper = require('QualityColorHelper')
local ColorConsts = require('ColorConsts')

local BASIC = 0
local SKILL = 1

local EQUIP_SHOW_TYPE = {HeroEquipType.Head, HeroEquipType.Clothes, HeroEquipType.Belt, HeroEquipType.Shoes, HeroEquipType.Weapon}
---@class UIHeroInfoComponent : BaseUIComponent
---@field module HeroModule
---@field parentMediator UIHeroMainUIMediator
---@field heroList table<number,HeroConfigCache>
---@field selectHeroData HeroConfigCache
local UIHeroInfoComponent = class('UIHeroInfoComponent', BaseUIComponent)

local SP_PET_FRAME_PREFIX = "sp_item_frame_circle_"

local SP_HERO_NAME_BASE_ICON = {
    [1] = "sp_pet_base_frame_06",
    [2] = "sp_pet_base_frame_06",
    [3] = "sp_pet_base_frame_06",
    [4] = "sp_pet_base_frame_07",
    [5] = "sp_pet_base_frame_08"
}

function UIHeroInfoComponent:ctor()
    self.module = ModuleRefer.HeroModule
end

function UIHeroInfoComponent:OnCreate()
    self.recordRoot = self:BindComponent('', typeof(CS.StatusRecordParent))
    self.imgBaseQuality = self:Image('p_base_quality')
    self.compChildTagPosition = self:LuaObject('child_tag_position')
    self.goTagStyle = self:GameObject("child_tag_style")
    self.imgIconStyle = self:Image('p_icon_style')
    self.textStyle = self:Text('p_text_style')
    self.btnStyle = self:Button('p_btn_style', Delegate.GetOrCreate(self, self.OnBtnStyleClicked))
    self.textUpgrade1 = self:Text('p_text_upgrade_1')
    self.goTopStatueB = self:GameObject("p_top_status_b")
    self.textHeroNameB = self:Text('p_text_name_b')
    self.goTopStatueA = self:GameObject("p_top_status_a")
    self.textHeroName = self:Text('p_text_a')
    self.textLv = self:Text('p_text_lv')
    self.textLvNumber = self:Text('p_text_lv_number')
    self.btnDetailBreal = self:Button('p_btn_detail_break', Delegate.GetOrCreate(self, self.OnBtnDetailBreakClicked))
    self.textExp = self:Text('p_text_exp', I18N.Get('*EXP:'))
    self.textExpNumber = self:Text('p_text_exp_number')
    self.goProgress = self:GameObject("p_progress")
    self.sliderProgressLv = self:Slider('p_progress_lv')
    self.btnStrengthen = self:Button('p_btn_strengthen_enter', Delegate.GetOrCreate(self, self.OnBtnStrengthenClicked))
    self.child_strengthen_hero_group = self:LuaObject('child_strengthen_hero_group')
    self.imgBaseStrengthen = self:Image('p_base_strengthen')
    self.goStrengthen = self:GameObject("p_strengthen")
    -- self.imageLvStrength = self:Image('p_icon_lv_strengthen')

    self.goIconSatr1 = self:GameObject('p_icon_satr_1')
    self.goIconSatr2 = self:GameObject('p_icon_satr_2')
    self.goIconSatr3 = self:GameObject('p_icon_satr_3')
    self.goIconSatr4 = self:GameObject('p_icon_satr_4')
    self.goIconSatr5 = self:GameObject('p_icon_satr_5')
    self.goIconSatr6 = self:GameObject('p_icon_satr_6')

    self.imgIconSatr1 = self:Image('p_icon_satr_1')
    self.imgIconSatr2 = self:Image('p_icon_satr_2')
    self.imgIconSatr3 = self:Image('p_icon_satr_3')
    self.imgIconSatr4 = self:Image('p_icon_satr_4')
    self.imgIconSatr5 = self:Image('p_icon_satr_5')
    self.imgIconSatr6 = self:Image('p_icon_satr_6')

    self.goIconArrow = self:GameObject("p_icon_arrow")
    self.compEquipRedDot = self:LuaObject('child_reddot_default')
    self.btnEquipmentEntrance = self:Button('p_btn_equipment_entrance', Delegate.GetOrCreate(self, self.OnBtnEquipmentEntranceClicked))
    self.goHead = self:GameObject('p_head')
    self.imgFrameHead = self:Image('p_frame_head')
    self.imgIconHead = self:Image('icon_head')
    self.goClothes = self:GameObject('p_clothes')
    self.imgFrameClothes = self:Image('p_frame_clothes')
    self.imgIconClothes = self:Image('icon_clothes')
    self.goBelt = self:GameObject('p_belt')
    self.imgFrameBelt = self:Image('p_frame_belt')
    self.imgIconBelt = self:Image('icon_belt')
    self.goShoes = self:GameObject('p_shoes')
    self.imgFrameShoes = self:Image('p_frame_shoes')
    self.imgIconShoes = self:Image('icon_shoes')
    self.goWeapon = self:GameObject('p_weapon')
    self.imgFrameWeapon = self:Image('p_frame_weapon')
    self.imgIconWeapon = self:Image('icon_weapon')
    self.compEquipRedDot1 = self:LuaObject('child_reddot_default_1')

    self.goToggle = self:GameObject('p_toggle')
    self.btnToggleLeft = self:Button('p_base_n_l', Delegate.GetOrCreate(self, self.OnBtnToggleLeftClicked))
    self.goBaseNL = self:GameObject('p_base_n_l')
    self.goBaseSelectL = self:GameObject('p_base_select_l')
    self.textTitleBasice = self:Text('p_text_title_basice', I18N.Get("hero_base_attribute"))
    self.textTitleBasiceN = self:Text('p_text_title_basice_n', I18N.Get("hero_base_attribute"))
    self.btnToggleRight = self:Button('p_base_n', Delegate.GetOrCreate(self, self.OnBtnToggleRightClicked))
    self.goBaseN = self:GameObject('p_base_n')
    self.goBaseSelect = self:GameObject('p_base_select')
    self.textTitle = self:Text('p_text_title', I18N.Get("hero_card"))
    self.textTitleN = self:Text('p_text_title_n', I18N.Get("hero_card"))

    self.goTableBasicsShort = self:GameObject('p_table_basics_short')
    self.tableviewproTableBasicsShort = self:TableViewPro('p_table_basics_short')
    self.goTableBasicsLong = self:GameObject('p_table_basics_long')
    self.tableviewproTableBasicsLong = self:TableViewPro('p_table_basics_long')
    self.goOpen = self:GameObject('p_btn_open')
    self.btnOpen = self:Button('p_btn_open', Delegate.GetOrCreate(self, self.OnBtnOpenClicked))
    self.goClose = self:GameObject('p_btn_close')
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.goGroupSkill = self:GameObject('p_group_skill')
    self.textSe = self:Text('p_text_se', I18N.Get("skill_se"))
    self.textSlg = self:Text('p_text_slg', I18N.Get("skill_slg"))
    self.compChildItemSkill1 = self:LuaObject('child_item_skill_1')
    self.compChildItemSkill2 = self:LuaObject('child_item_skill_2')
    self.compChildItemSkill3 = self:LuaObject('child_item_skill_3')
    self.goGroupSkillCitizen = self:GameObject('p_group_skill_citizen')
    self.textLosistics = self:Text('p_text_losistics', I18N.Get("hero_type_city"))
    self.compChildItemSkillSe1 = self:LuaObject('child_item_skill_se_1')
    self.compChildItemSkillSe2 = self:LuaObject('child_item_skill_se_2')
    self.compChildItemSkillSe3 = self:LuaObject('child_item_skill_se_3')

    self.btnRecruit = self:Button('p_btn_recruit', Delegate.GetOrCreate(self, self.OnBtnRecruitClicked))
    self.statusBtnSummon = self:StatusRecordParent('p_group_btn_summon')
    self.btnCompSummon = self:Button('p_comp_btn_summon', Delegate.GetOrCreate(self, self.OnBtnCompSummonClicked))
    self.goNumberBl = self:GameObject('p_number_bl')
    self.imgIconItemBl = self:Image('p_icon_item_bl')
    self.textNumGreenBl = self:Text('p_text_num_green_bl')
    self.textNumRedBl = self:Text('p_text_num_red_bl')
    self.textNumWilthBl = self:Text('p_text_num_wilth_bl')
    self.textSummon = self:Text('p_text_summon', I18N.Get("hero_spiece_combine"))
    self.btnCompGain = self:Button('p_comp_btn_gain', Delegate.GetOrCreate(self, self.OnBtnCompGainClicked))
    self.textGain = self:Text('p_text_gain', I18N.Get("hero_spiece_combine"))

    self.goCostItems = self:GameObject('p_layout_cost_items')
    self.compItemSummon = self:LuaObject('p_item_summon')
    self.compItemSummon1 = self:LuaObject('p_item_summon_1')

    self.btnUpgrade = self:Button('p_btn_upgrade', Delegate.GetOrCreate(self, self.OnBtnCompLvupClicked))
    self.textBtnUpgrade = self:Text('p_text_upgrade', I18N.Get("hero_city_type_5"))

    self.goBottom = self:GameObject('p_bottom')
    self.textMax = self:Text('p_text_max', I18N.Get("hero_level_full"))
    self.compChildCompBreak = self:LuaObject('p_comp_btn_break')
    self.goLvUp = self:GameObject("p_lvup")
    self.compChildCompB = self:LuaObject('p_comp_btn_lvup')
    self.upgradeNodeCom = self:LuaObject('child_reddot_default_upgrade')
    self.btnStory = self:Button('p_btn_story', Delegate.GetOrCreate(self, self.OnBtnStoryClicked))
    self.btnRed = self:Button('p_btn_reddot_switch', Delegate.GetOrCreate(self, self.OnBtnRedClicked))
    self.imgIconOn = self:Image('p_icon_on')
    self.imgIconOff = self:Image('p_icon_off')
    self.btnCg = self:Button('p_btn_cg', Delegate.GetOrCreate(self, self.OnBtnCgClicked))
    self.btnPet = self:Button('p_btn_pet', Delegate.GetOrCreate(self, self.OnBtnPetClicked))
    self.goStatusEmpty = self:GameObject('p_status_empty')
    self.btnStatusEmpty = self:Button('p_status_empty', Delegate.GetOrCreate(self, self.OnBtnStatusEmptyClicked))
    self.goStatusNomal = self:GameObject('p_status_nomal')
    self.imgImgPet = self:Image('p_img_pet')
    self.imgBaseFrame = self:Image('p_base_frame')
    self.compEquipRedDotPet = self:LuaObject('child_reddot_default_pet')
    self.btnDelete = self:Button('p_btn_delete', Delegate.GetOrCreate(self, self.OnBtnDeleteClicked))
    self.goBaseLV = self:GameObject('base_lv')
    self.textPetLv = self:Text('p_text_pet_lv')

    self.parentMediator = self:GetParentBaseUIMediator()
    self.compItemSummon:SetVisible(false)
    self.compItemSummon1:SetVisible(false)
    self.compEquipRedDotPet:SetVisible(false)
    self.compEquipRedDot:SetVisible(false)
    self.selectShowGos = {self.goWeapon, self.goHead, self.goClothes, self.goBelt, self.goShoes}
    self.qualityFrames = {self.imgFrameWeapon, self.imgFrameHead, self.imgFrameClothes, self.imgFrameBelt, self.imgFrameShoes}
    self.itemIcons = {self.imgIconWeapon, self.imgIconHead, self.imgIconClothes, self.imgIconBelt, self.imgIconShoes}
    self.heroSlgSkills = {self.compChildItemSkill1, self.compChildItemSkill2, self.compChildItemSkill3}
    self.citizenSkills = {self.compChildItemSkillSe1, self.compChildItemSkillSe2, self.compChildItemSkillSe3}
    self.strengthIcons = {self.goIconSatr1, self.goIconSatr2, self.goIconSatr3, self.goIconSatr4, self.goIconSatr5, self.goIconSatr6}
    self.strengthIconImages = {self.imgIconSatr1, self.imgIconSatr2, self.imgIconSatr3, self.imgIconSatr4, self.imgIconSatr5, self.imgIconSatr6}
    self.goOpen:SetVisible(false)
    self.goClose:SetVisible(false)

    self.p_resonated = self:GameObject('p_resonated')
    self.p_text_resonated = self:Text('p_text_resonated', "pet_level_sync_name")

    -- self.btnStrengthen:SetVisible(false)
    self.p_group_hint = self:GameObject('p_group_hint')
    self.p_text_hint = self:Text('p_text_hint')
    self.p_btn_hint_goto = self:Button('p_btn_hint_goto', Delegate.GetOrCreate(self, self.OnClickHintGoto))

    -- 突破隐藏
    self.btnDetailBreal:SetVisible(true)
    self.compChildCompBreak:SetVisible(false)
    -- 英雄升级不再使用原来的按钮
    self.goLvUp:SetActive(false)

    self.goToggle:SetActive(false)

    self.p_btn_info = self:Button('p_btn_info', Delegate.GetOrCreate(self, self.OnClickResonateDetails))
    self.p_power = self:GameObject('p_power')

    self.textPowerHint = self:Text('p_text_power_hint', '/*全部英雄等级共鸣')

    self.luaItemUpgrade = self:LuaObject('p_item_upgrade_1')
    self.luaItemUpgrade1 = self:LuaObject('p_item_upgrade_2')

    self.textTitleEquip = self:Text('p_title_equipment', 'hero_equip')
    self.textTitleStrengthen = self:Text('p_title_strengthen', 'hero_star')
    self.textTitleLvl = self:Text('p_title_lv', 'hero_lv')

    self.luaCostItems = {self.luaItemUpgrade, self.luaItemUpgrade1}
end

function UIHeroInfoComponent:OnBtnStyleClicked(args)
    --- 2024.04.05 屏蔽点击后弹出的tips 【【英雄】战术风格相关优化】https://www.tapd.cn/31821045/prong/stories/view/1131821045001424005
    if true then return end
    local heroConfig = self.selectHeroData.configCell
    local associatedTagInfo = heroConfig:AssociatedTagInfo()
    local cfg = ConfigRefer.AssociatedTag:Find(associatedTagInfo)
    local content = I18N.Get("hero_skill_tip_title") .. I18N.Get(cfg:Name()) .. "\n" .. I18N.Get(cfg:Des()) .. "\n"
    for i = 1, cfg:TagTiesRelationshipsLength() do
        local ships = cfg:TagTiesRelationships(i)
        local ties = ships:Ties()
        local tiesCfg = ConfigRefer.TagTies:Find(ties)
        local addNum
        if ships:TiesTagLength() == 2 then
            addNum = I18N.Get("hero_skill_tip_bihero") .. "+" .. I18N.Get(tiesCfg:Value()) .. "\n"
        elseif ships:TiesTagLength() == 3 then
            addNum = I18N.Get("hero_skill_tip_trihero") .. "+" .. I18N.Get(tiesCfg:Value()) .. "\n"
        end
        content = content .. addNum
    end
    --- 2024.04.05 屏蔽点击后弹出的tips 【【英雄】战术风格相关优化】https://www.tapd.cn/31821045/prong/stories/view/1131821045001424005
    -- ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnStyle.transform, content = content})
end

function UIHeroInfoComponent:OnShow(param)
    self.selectHeroData = self.parentMediator:GetSelectHero()

    -- 英雄养成通知
    local isOpen = ModuleRefer.HeroModule:HeroRedDotIsOpen(self.selectHeroData.id)
    self.imgIconOn.gameObject:SetVisible(isOpen)
    self.imgIconOff.gameObject:SetVisible(not isOpen)
    if not self.selectHeroData then
        g_Logger.ErrorChannel('Hero Window', 'Hero data is nil')
    end
    self.imgBaseQuality.gameObject:SetVisible(true)
    -- 英雄名称、背景及战斗位置、风格
    local heroConfig = self.selectHeroData.configCell
    local heroQuality = heroConfig:Quality()
    local offsetQuality = QualityColorHelper.GetOffsetQuality(heroQuality, QualityColorHelper.Type.Hero)
    local nameBaseImgStr = SP_HERO_NAME_BASE_ICON[offsetQuality]
    g_Game.SpriteManager:LoadSprite(nameBaseImgStr, self.imgBaseQuality)
    self.isHero = ModuleRefer.HeroModule:GetHeroSelectType() == HeroType.Heros
    self.compChildTagPosition:SetVisible(self.isHero)
    if self.isHero then
        self.compChildTagPosition:FeedData({battleType = heroConfig:BattleType()})
    end
    local associatedTagInfo = heroConfig:AssociatedTagInfo()
    local cfg = ConfigRefer.AssociatedTag:Find(associatedTagInfo)
    self.goTagStyle:SetVisible(cfg ~= nil)
    if cfg then
        self:LoadSprite(cfg:Icon(), self.imgIconStyle)
        self.textStyle.text = I18N.Get(cfg:Name())
    end
    self.textHeroName.text = I18N.Get(heroConfig:Name())
    self.textHeroNameB.text = I18N.Get(heroConfig:Name())

    -- 英雄获得状态切换
    local hasHero = self.selectHeroData:HasHero()
    self.recordRoot:Play(hasHero and 0 or 1)
    self.goTopStatueA:SetVisible(hasHero)
    self.goTopStatueB:SetVisible(not hasHero)
    self:OnBtnOpenClicked()
    self.btnRecruit.gameObject:SetVisible(not hasHero)
    self.p_power:SetVisible(hasHero)

    -- 共鸣标记
    if not hasHero then
        self.p_resonated:SetVisible(false)
    end

    self.btnPet.gameObject:SetVisible(false)
    self:OnBtnToggleLeftClicked()
    if self.isHero then
        self:RefreshHeroSkill(self.selectHeroData)
    else
        self:RefreshCitizenSkill(heroConfig)
    end
    local power = self.module:CalcHeroPower(self.selectHeroData.id)
    self.textUpgrade1.text = NumberFormatter.Normal(power)
    local resCell = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())
    self.btnCg.gameObject:SetVisible(resCell:ShowTimeline() and resCell:ShowTimeline() ~= "")
    self:RefreshAttrList()
    self:RefreshUpgrade(hasHero)
    -- 未获得英雄时下面的组件都会被隐藏
    if not hasHero then
        self.btnEquipmentEntrance.gameObject:SetVisible(false)
        self.goBottom:SetVisible(false)
        local has = ModuleRefer.InventoryModule:GetAmountByConfigId(heroConfig:PieceId())
        local cost = heroConfig:ComposeNeedPiece()
        local isEnough = has >= cost
        self.btnCompSummon.gameObject:SetVisible(isEnough)
        self.btnCompGain.gameObject:SetVisible(not isEnough)

        local itemCfg = ConfigRefer.Item:Find(heroConfig:PieceId())
        self.goNumberBl:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgIconItemBl)
        self.textNumGreenBl.gameObject:SetVisible(isEnough)
        self.textNumRedBl.gameObject:SetVisible(not isEnough)
        if isEnough then
            self.textNumGreenBl.text = has
        else
            self.textNumRedBl.text = has
        end
        self.textNumWilthBl.text = "/" .. cost
        self.textMax.gameObject:SetVisible(false)
        return
    end
    local level = self.selectHeroData.dbData.Level
    local expPercent, expValue, expMax = self.module:GetExpPercent(self.selectHeroData.id)
    self.textExpNumber.text = string.format('%d/%d', expValue, expMax)
    self.sliderProgressLv.value = math.clamp01(expPercent)
    self.textLv.text = I18N.Get("hero_level") .. " " .. string.format("%d", level)

    self.goBottom:SetVisible(true)


    local strengthLv = self.selectHeroData.dbData.StarLevel or 0
    self.child_strengthen_hero_group:FeedData(strengthLv)
    local isShow = hasHero and strengthLv > 0
    if isShow then
        local stageLevel = math.floor(strengthLv / ModuleRefer.HeroModule.STRENGTH_COUNT)
        local showIndex = strengthLv % ModuleRefer.HeroModule.STRENGTH_COUNT
        if strengthLv == 0 or showIndex ~= 0 then
            stageLevel = stageLevel + 1
            for index, icon in ipairs(self.strengthIconImages) do
                g_Game.SpriteManager:LoadSprite("sp_common_icon_strong_" .. stageLevel .. "_star", icon)
                icon.gameObject:SetVisible(index <= showIndex)
            end
        else
            for _, icon in ipairs(self.strengthIconImages) do
                g_Game.SpriteManager:LoadSprite("sp_common_icon_strong_" .. stageLevel .. "_star", icon)
                icon.gameObject:SetVisible(true)
            end
        end
    else
        for _, icon in ipairs(self.strengthIconImages) do
            icon.gameObject:SetVisible(false)
        end
    end
    self.btnEquipmentEntrance.gameObject:SetVisible(self.isHero)
    if self.isHero then
        self:RefreshEquipInfos()
    end

    local petId = ModuleRefer.HeroModule:GetHeroLinkPet(self.selectHeroData.id, self.parentMediator.isPvP)
    if petId and petId > 0 then
        self.goStatusNomal:SetVisible(true)
        self.goStatusEmpty:SetVisible(false)
        local petInfo = ModuleRefer.PetModule:GetPetByID(petId)
        local petCfg = ConfigRefer.Pet:Find(petInfo.ConfigId)
        self:LoadSprite(petCfg:Icon(), self.imgImgPet)
        g_Game.SpriteManager:LoadSprite(SP_PET_FRAME_PREFIX .. (petCfg:Quality() + 2), self.imgBaseFrame)
        self.textPetLv.text = petInfo.Level
    else
        self.goStatusNomal:SetVisible(false)
        self.goStatusEmpty:SetVisible(true)
    end

    local upgradeNode = ModuleRefer.NotificationModule:GetDynamicNode("HeroUpgradeNode" .. self.selectHeroData.id, NotificationType.HERO_UPGRADE_BTN)
    ModuleRefer.NotificationModule:AttachToGameObject(upgradeNode, self.upgradeNodeCom.go, self.upgradeNodeCom.redDot)
    local equipTabNode = ModuleRefer.NotificationModule:GetDynamicNode("HeroEquipTab" .. self.selectHeroData.id, NotificationType.EQUIP_TAB)
    ModuleRefer.NotificationModule:AttachToGameObject(equipTabNode, self.compEquipRedDot1.go, self.compEquipRedDot1.redDot)

    self:ChangeStrengthArrow(ModuleRefer.HeroModule:CanStrengthen(heroConfig:Id()))
end

function UIHeroInfoComponent:OnOpened(param)
    g_Game.EventManager:AddListener(EventConst.HERO_CAN_STRENGTH, Delegate.GetOrCreate(self, self.RefreshStrength))
    ModuleRefer.InventoryModule:AddCountChangeByTypeListener(ItemType.Cultivate, Delegate.GetOrCreate(self, self.OnShow))
    ModuleRefer.InventoryModule:AddCountChangeByTypeListener(ItemType.HeroPiece, Delegate.GetOrCreate(self, self.OnShow))
    ModuleRefer.InventoryModule:AddCountChangeByTypeListener(ItemType.HeroEquip, Delegate.GetOrCreate(self, self.OnShow))
    g_Game.ServiceManager:AddResponseCallback(HeroPieceToHeroParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnHeroCraftSucc))
end

function UIHeroInfoComponent:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.HERO_CAN_STRENGTH, Delegate.GetOrCreate(self, self.RefreshStrength))
    ModuleRefer.InventoryModule:RemoveCountChangeByTypeListener(ItemType.Cultivate, Delegate.GetOrCreate(self, self.OnShow))
    ModuleRefer.InventoryModule:RemoveCountChangeByTypeListener(ItemType.HeroPiece, Delegate.GetOrCreate(self, self.OnShow))
    ModuleRefer.InventoryModule:RemoveCountChangeByTypeListener(ItemType.HeroEquip, Delegate.GetOrCreate(self, self.OnShow))
    g_Game.ServiceManager:RemoveResponseCallback(HeroPieceToHeroParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnHeroCraftSucc))
end

function UIHeroInfoComponent:ChangeStrengthArrow(isCanStrength)
    self.goIconArrow:SetVisible(isCanStrength)
end

function UIHeroInfoComponent:RefreshStrength(info)
    if info.heroId == self.selectHeroData.id then
        self:ChangeStrengthArrow(info.isCanStrength)
    end
end

function UIHeroInfoComponent:OnBtnRedClicked()
    if ModuleRefer.HeroModule:HeroRedDotIsOpen(self.selectHeroData.id) then
        ModuleRefer.HeroModule:RecordHeroRedDotOpenState(0, self.selectHeroData.id)
        self.imgIconOn.gameObject:SetVisible(false)
        self.imgIconOff.gameObject:SetVisible(true)
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("hero_redpoint_close"))
    else
        ModuleRefer.HeroModule:RecordHeroRedDotOpenState(1, self.selectHeroData.id)
        self.imgIconOn.gameObject:SetVisible(true)
        self.imgIconOff.gameObject:SetVisible(false)
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("hero_redpoint_open"))
    end
end

function UIHeroInfoComponent:SwitchToDetailPage(page)
    if (page == BASIC) then
        self.goBaseNL:SetVisible(false)
        self.goBaseSelectL:SetVisible(true)
        self.textTitleBasice.gameObject:SetVisible(true)
        self.goBaseN:SetVisible(true)
        self.goBaseSelect:SetVisible(false)
        self.textTitle.gameObject:SetVisible(false)
        self.goToggle:SetVisible(false)
        self.goGroupSkill:SetVisible(true)
        self.goGroupSkillCitizen:SetVisible(false)
        self.goTableBasicsLong:SetVisible(false)
        self.goClose:SetVisible(false)
    elseif (page == SKILL) then
        self.goBaseNL:SetVisible(true)
        self.goBaseSelectL:SetVisible(false)
        self.textTitleBasice.gameObject:SetVisible(false)
        self.goBaseN:SetVisible(false)
        self.goBaseSelect:SetVisible(true)
        self.textTitle.gameObject:SetVisible(true)
        self.goToggle:SetVisible(false)
        self.goGroupSkill:SetVisible(self.isHero)
        self.goGroupSkillCitizen:SetVisible(not self.isHero)
        self.goTableBasicsShort:SetVisible(false)
        self.goTableBasicsLong:SetVisible(false)
        self.goOpen:SetVisible(false)
        self.goClose:SetVisible(false)
    end
end

function UIHeroInfoComponent:OnBtnToggleLeftClicked()
    self:SwitchToDetailPage(BASIC, true)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_mail_individual)
end

function UIHeroInfoComponent:OnBtnToggleRightClicked()
    self:SwitchToDetailPage(SKILL, true)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_mail_individual)
end

function UIHeroInfoComponent:RefreshAttrList()
    self.attrList = {}
    local isHero = self.selectHeroData.configCell:Type() == HeroType.Heros
    local props
    if self.selectHeroData:HasHero() then
        props = self.selectHeroData.dbData.Props
    else
        if isHero then
            props = ModuleRefer.HeroModule:GetHeroDisplayAttribute(ModuleRefer.HeroModule:GetHeroBaseAttribute(self.selectHeroData.id, 1) or {})
        else
            props = ModuleRefer.HeroModule:GetCityHeroDisplayAttribute(ModuleRefer.HeroModule:GetHeroBaseAttribute(self.selectHeroData.id, 1) or {})
        end
    end
    if isHero then
        for i = 1, ConfigRefer.ConstMain:HeroSESubAttrTypeLength() do
            local displayKey = ConfigRefer.ConstMain:HeroSESubAttrType(i)
            local clientKey = ModuleRefer.HeroModule:GetAttrDiaplayRelativeAttrType(displayKey)
            local attrCell = ConfigRefer.AttrElement:Find(clientKey)
            local value = props[displayKey] or 0
            if value > 0 then
                local single = {}
                single.icon = attrCell:Icon()
                single.name = I18N.Get(attrCell:Name())
                single.num = NumberFormatter.RemoveTrailingZeros(ModuleRefer.AttrModule:GetAttrValueShowTextByType(attrCell, value))
                self.attrList[#self.attrList + 1] = single
            end
        end
    else
        for i = 1, ConfigRefer.ConstMain:HeroCitySubAttrTypeLength() do
            local displayKey = ConfigRefer.ConstMain:HeroCitySubAttrType(i)
            local clientKey = ModuleRefer.HeroModule:GetAttrDiaplayRelativeAttrType(displayKey)
            local attrCell = ConfigRefer.AttrElement:Find(clientKey)
            local value = props[displayKey] or 0
            if value > 0 then
                local single = {}
                single.icon = attrCell:Icon()
                single.name = I18N.Get(attrCell:Name())
                single.num = NumberFormatter.RemoveTrailingZeros(ModuleRefer.AttrModule:GetAttrValueShowTextByType(attrCell, value))
                self.attrList[#self.attrList + 1] = single
            end
        end
    end
    self.tableviewproTableBasicsShort:Clear()
    self.tableviewproTableBasicsLong:Clear()
    for i = 1, #self.attrList do
        local single = self.attrList[i]
        if i <= 4 then
            self.tableviewproTableBasicsShort:AppendData(single)
        end
        single.showBase = i % 2 == 0
        self.tableviewproTableBasicsLong:AppendData(single)
    end
end

---@param heroData HeroConfigCache
function UIHeroInfoComponent:RefreshHeroSkill(heroData)
    local heroCfg = heroData.configCell
    local strengthenCfg = ConfigRefer.HeroStrengthen:Find(heroCfg:StrengthenCfg())
    local strengthenLvl = (heroData.dbData or {}).StarLevel or 0
    local skillLvl
    if strengthenLvl == 0 then
        skillLvl = 1
    else
        skillLvl = strengthenCfg:StrengthenInfoList(strengthenLvl):SkillLevel()
    end
    local petId = ModuleRefer.HeroModule:GetHeroLinkPet(self.selectHeroData.id)
    local isHasPet = petId and petId > 0
    for i = 1, #self.heroSlgSkills do
        local isShow = i <= heroCfg:SlgSkillDisplayLength()
        self.heroSlgSkills[i]:SetVisible(isShow)
        if isShow then
            local slgSkillId = heroCfg:SlgSkillDisplay(i)
            local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(slgSkillId)
            local seSkillId = heroCfg:CardsDisplay(i)
            local seSkillCell = ConfigRefer.Card:Find(seSkillId)
            local skillParam = {}
            skillParam.skillId = slgSkillCell:SkillId()
            skillParam.index = i
            skillParam.isSlg = true
            skillParam.skillLevel = skillLvl
            skillParam.isLock = i > 1 and (not self.selectHeroData:HasHero() or self.selectHeroData.dbData.Level < heroCfg:SkillUnlockLevel(i - 1))
            skillParam.showLvl = true
            skillParam.cardId = seSkillId
            skillParam.onGoto = function()
                g_Game.UIManager:CloseByName(UIMediatorNames.UISkillCommonTipMediator)
                self:OnBtnStrengthenClicked()
            end
            skillParam.clickCallBack = function()
                ---@type UISkillCommonTipMediatorParameter
                local param = {}
                param.ShowHeroSkillTips = {
                    slgSkillId = skillParam.skillId,
                    cardId = skillParam.cardId,
                    isLock = skillParam.isLock,
                    skillLevel = skillParam.skillLevel,
                    slgSkillCell = slgSkillCell,
                    onGoto = skillParam.onGoto,
                    hasHero = self.selectHeroData:HasHero()
                }
                g_Game.UIManager:Open(UIMediatorNames.UISkillCommonTipMediator, param)
            end
            self.heroSlgSkills[i]:FeedData(skillParam)
        else
            if heroCfg:SlgPartnerSkillCfg(1) > 0 then
                local slgSkillId = heroCfg:SlgPartnerSkillCfg(1)
                local slgSkillCell = ConfigRefer.SlgSkillInfo:Find(slgSkillId)
                local seSkillId = heroCfg:CardsDisplay(heroCfg:CardsDisplayLength())
                local skillParam = {}
                skillParam.skillId = slgSkillCell:SkillId()
                skillParam.cardId = seSkillId
                skillParam.index = i
                skillParam.isSlg = true
                skillParam.skillLevel = skillLvl
                skillParam.isLock = not self.selectHeroData:HasHero() or self.selectHeroData.dbData.Level < heroCfg:PartnerSkillUnlockLevel(1)
                skillParam.showLvl = true
                skillParam.onGoto = function()
                    g_Game.UIManager:CloseByName(UIMediatorNames.UISkillCommonTipMediator)
                    self:OnBtnStrengthenClicked()
                end
                skillParam.clickCallBack = function()
                    ---@type UISkillCommonTipMediatorParameter
                    local param = {}
                    param.ShowHeroSkillTips = {
                        slgSkillId = skillParam.skillId,
                        cardId = skillParam.cardId,
                        isLock = skillParam.isLock,
                        skillLevel = skillParam.skillLevel,
                        slgSkillCell = slgSkillCell,
                        onGoto = skillParam.onGoto,
                        hasHero = self.selectHeroData:HasHero()
                    }
                    g_Game.UIManager:Open(UIMediatorNames.UISkillCommonTipMediator, param)
                end
                self.heroSlgSkills[i]:FeedData(skillParam)
                self.heroSlgSkills[i]:SetVisible(true)
            else
                self.heroSlgSkills[i]:SetVisible(false)
            end
        end
    end
end

function UIHeroInfoComponent:RefreshCitizenSkill(heroCfg)
    for i = 1, #self.citizenSkills do
        local isShow = i <= heroCfg:CitizenSkillCfgLength()
        self.citizenSkills[i]:SetVisible(isShow)
        if isShow then
            local citizenSkillId = heroCfg:CitizenSkillCfg(i)
            local citizenSkillCfg = ConfigRefer.CitizenSkillInfo:Find(citizenSkillId)
            local data = {}
            data.icon = citizenSkillCfg:Icon()
            data.name = I18N.Get(citizenSkillCfg:Name())
            data.clickCallBack = function()
                ---@type UISkillCommonTipMediatorParameter
                local param = {}
                param.ShowSocSkillTips = {socSkillId = citizenSkillId, skillLevel = nil}
                g_Game.UIManager:Open(UIMediatorNames.UISkillCommonTipMediator, param)
            end
            self.citizenSkills[i]:FeedDataCustomData(data)
        end
    end
end

function UIHeroInfoComponent:NeedBreak()
    if self.selectHeroData then
        return self.module:NeedBreak(self.selectHeroData.id)
    end
    return false
end

function UIHeroInfoComponent:OnBtnCompBreakClicked()
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_SELECT_MAINPAGE, UIHeroLocalData.MainUIPageType.BREAK_PAGE)
end

function UIHeroInfoComponent:RefreshEquipInfos()
    for index, equipType in ipairs(EQUIP_SHOW_TYPE) do
        self:RefreshSingleEquip(index, equipType)
    end
end

function UIHeroInfoComponent:RefreshSingleEquip(index, equipType)
    local equipInfo = ModuleRefer.HeroModule:GetEquipByType(self.selectHeroData.id, equipType)
    local isHasEquip = equipInfo and next(equipInfo)
    local selectIndex = EQUIP_SHOW_TYPE[index]
    self.selectShowGos[selectIndex]:SetVisible(isHasEquip)
    if isHasEquip then
        local equipId = equipInfo.ConfigId
        local equipCfg = ConfigRefer.HeroEquip:Find(equipId)
        self:LoadSprite(equipCfg:BaseMap(), self.qualityFrames[selectIndex])
        self:LoadSprite(equipCfg:Icon(), self.itemIcons[selectIndex])
    end
end

function UIHeroInfoComponent:OnBtnItemLvupClicked()
    ModuleRefer.InventoryModule:OpenExchangePanel({{id = self.module:GetUpgradeItems(self.selectHeroData.id)[1]}})
end

function UIHeroInfoComponent:OnClosePopupItemDetailsUIMediator()
    g_Game.UIManager:CloseByName(UIMediatorNames.PopupItemDetailsUIMediator)
end

function UIHeroInfoComponent:RefreshUpgrade(hasHero)
    if not hasHero then
        self.btnUpgrade.gameObject:SetActive(false)
        for i = 1, #self.luaCostItems do
            self.luaCostItems[i]:SetVisible(false)
        end
        return
    end
    self.upgradeItems = self.module:GetUpgradeItems(self.selectHeroData.id)
    local costItems, delta = self:GetUpgradeCostItems()

    self.upgradeNodeCom:SetVisible(true)
    self.textLvNumber.text = "/" .. self.selectHeroData.dbData.LevelUpperLimit

    self.isLimited = self.module:IsHeroLevelLimited()
    self.btnUpgrade.gameObject:SetActive(not self.isLimited)
    if self.p_group_hint then
        self.p_group_hint:SetVisible(self.isLimited)
    end

    --满级英雄
    if ModuleRefer.HeroModule:IsMaxLevel(self.selectHeroData.id) then
        self.p_text_hint.text = I18N.Get("hero_level_full")
        self.p_btn_hint_goto:SetVisible(false)
    elseif self.isLimited then
        self.p_text_hint.text = I18N.Get("mentor_tips02")
        self.p_btn_hint_goto:SetVisible(true)
    elseif delta <= 0 then
        -- self.btnUpgrade.interactable = true
    else
        -- self.btnUpgrade.interactable = false
    end
    for _ , item in ipairs(self.luaCostItems) do
        item:SetVisible(false)
    end

    local i = 1
    local totalCost = self:GetTotalCost()
    for id, num in pairs(costItems) do
        local item = self.luaCostItems[i]
        item:SetVisible(true)
        ---@type CommonPairsQuantityParameter
        local data = {}
        data.itemId = id
        data.itemIcon = ConfigRefer.Item:Find(id):Icon()
        data.num1 = ModuleRefer.InventoryModule:GetAmountByConfigId(id)
        data.num2 = totalCost
        data.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
        item:FeedData(data)
        if data.num2 <= data.num1 then
            item:SetCustomLeftNumberColor(ColorConsts.army_green)
        end
    end
end

function UIHeroInfoComponent:CanBreak()
    if self.selectHeroData then
        return self.module:CanBreak(self.selectHeroData.id)
    end
    return false
end

function UIHeroInfoComponent:CanLevelUp()
    if self.selectHeroData then
        return self.module:CanLevelUpgrade(self.selectHeroData.id)
    end
    return false
end

function UIHeroInfoComponent:OnBtnStrengthenClicked()
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
    g_Game.EventManager:TriggerEvent(EventConst.HERO_SELECT_MAINPAGE, UIHeroLocalData.MainUIPageType.MAIN_PAGE, UIHeroLocalData.MainUITabType.STRENGTH)
end

function UIHeroInfoComponent:OnBtnEquipmentEntranceClicked()

    -- local isOpen = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(EQUIP_ENTRY_ID)
    -- if not isOpen then
    --     ModuleRefer.toastModule:AddSimpleToast(I18N.Get(ConfigRefer.SystemEntry:Find(EQUIP_ENTRY_ID):LockedTips()))
    --     return
    -- end

    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
    -- ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("see_you_next_time"))
    g_Game.EventManager:TriggerEvent(EventConst.HERO_SELECT_MAINPAGE, UIHeroLocalData.MainUIPageType.MAIN_PAGE, UIHeroLocalData.MainUITabType.EQUIP)
end

function UIHeroInfoComponent:OnBtnCompLvupLimitClicked()
    local totalCost = self:GetTotalCost()
    local itemId = self.upgradeItems[1]
    local curNum = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)

    ModuleRefer.InventoryModule:OpenExchangePanel({{id = self.upgradeItems[1], num = totalCost - curNum}})
    -- ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("errCode_23001"))
end

function UIHeroInfoComponent:OnBtnCompLvupClicked(args)
    if self.selectHeroData == nil or not self.selectHeroData:HasHero() then
        return
    end
    if ModuleRefer.HeroModule:IsMaxLevel(self.selectHeroData.id) then
        return
    end
    local addItems, delta = self:GetUpgradeCostItems()
    if table.nums(addItems) < 1 then
        return
    end
    if delta <= 0 then
        g_Game.EventManager:TriggerEvent(EventConst.HERO_LEVEL_UP)
    end

    self:UpgradeHero(addItems)
end

function UIHeroInfoComponent:UpgradeHero(addItems)
    self.module:AddExp(nil, self.compChildCompB.button.gameObject.transform, addItems)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_upgrade)
end

function UIHeroInfoComponent:GetTotalCost()
    local id = self.upgradeItems[1]
    local expValue = self.module:GetUpgradeItemExp(id)
    local _, curExp, maxExp = self.module:GetExpPercent(self.module:GetSystemHeroId())
    local delta = maxExp - curExp
    return math.ceil(delta / expValue)
end

function UIHeroInfoComponent:GetUpgradeCostItems()
    local id = self.module:GetSystemHeroId()
    return self.module:GetHeroUpgradeCost(id)
end

function UIHeroInfoComponent:OnBtnRecruitClicked(args)
    -- body
end

function UIHeroInfoComponent:OnBtnCompSummonClicked(args)
    local param = HeroPieceToHeroParameter.new()
    param.args.HeroCfgId = self.selectHeroData.configCell:Id()
    param:SendWithFullScreenLock()
end

function UIHeroInfoComponent:OnBtnCompGainClicked(args)
    local sysIndex = 1
    local cfg = ConfigRefer.SystemEntry:Find(sysIndex)
    if not cfg then
        return
    end
    if not ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysIndex) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(cfg:LockedTips()))
        return
    end
    g_Game.UIManager:CloseByName(UIMediatorNames.UIHeroMainUIMediator)
    g_Game.UIManager:Open(UIMediatorNames.HeroCardMediator)
end

function UIHeroInfoComponent:OnBtnDetailBreakClicked()
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
    -- g_Game.UIManager:Open(require('UIMediatorNames').HeroBreakPreviewMediator, self.selectHeroData)
    ---@type UIPetMainPopupMediatorParameter
    local data = {}
    data.attrList = self.attrList
    g_Game.UIManager:Open(UIMediatorNames.UIPetMainPopupMediator, data)
end

function UIHeroInfoComponent:OnBtnStoryClicked(args)
    local resCell = ConfigRefer.HeroClientRes:Find(self.selectHeroData.configCell:ClientResCfg())
    ModuleRefer.ToastModule:ShowTextToast({clickTransform = self.btnStory.transform, content = I18N.Get(resCell:HeroStory())})
end

function UIHeroInfoComponent:OnBtnCgClicked()
    local heroCfg = ConfigRefer.Heroes:Find(self.selectHeroData.id)
    local resCell = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
    if resCell:ShowTimeline() and resCell:ShowTimeline() ~= "" then
        if self.parentMediator.ui3dModel then
            self.parentMediator.ui3dModel.curModelGo:SetVisible(false)
            self.parentMediator.ui3dModel.curEnvGo:SetVisible(false)
            self.parentMediator.ui3dModel:ChangeCameraState(false)
        end
        local callback = function()
            if self.parentMediator.ui3dModel then
                self.parentMediator.ui3dModel.curModelGo:SetVisible(true)
                self.parentMediator.ui3dModel.curEnvGo:SetVisible(true)
                self.parentMediator.ui3dModel:ChangeCameraState(true)
            end
            self.parentMediator.goStatus:SetVisible(true)
            self.parentMediator.ui3dModel:InitVirtualCameraSetting(self.parentMediator:GetCameraSetting())
        end
        self.parentMediator.goStatus:SetVisible(false)
        ModuleRefer.HeroModule:LoadTimeline(resCell:ShowTimeline(), self.parentMediator.ui3dModel.moduleRoot, callback)
    end
end

function UIHeroInfoComponent:OnBtnDeleteClicked(args)
    local petId = ModuleRefer.HeroModule:GetHeroLinkPet(self.selectHeroData.id, self.parentMediator.isPvP)
    if self.parentMediator.isPvP then
        if self.parentMediator.onPetModified then
            self.parentMediator.onPetModified(self.selectHeroData.id, 0)
            self.goStatusNomal:SetVisible(false)
            self.goStatusEmpty:SetVisible(true)
            return
        end
    else
        local param = HeroCancelBindPetParameter.new()
        param.args.HeroTid = self.selectHeroData.id
        param.args.PetId = petId
        param:Send()
    end
end

function UIHeroInfoComponent:OnBtnPetClicked(args)
    local typeList = ModuleRefer.PetModule:GetTypeList()
    local hasPet = false
    if typeList then
        for _, typeId in ipairs(typeList) do
            local count = ModuleRefer.PetModule:GetPetCountByType(typeId)
            if count and count > 0 then
                hasPet = true
            end
        end
    end
    if not hasPet then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("hero_pet_nopet"))
        return
    end
    ModuleRefer.HeroModule:SkipTimeline()
    local petId = ModuleRefer.HeroModule:GetHeroLinkPet(self.selectHeroData.id, self.parentMediator.isPvP)
    g_Game.UIManager:Open(UIMediatorNames.UIPetCarryMediator, {petId = petId, heroId = self.selectHeroData.id, isPvP = self.parentMediator.isPvP})
end

function UIHeroInfoComponent:OnBtnStatusEmptyClicked(args)
    local typeList = ModuleRefer.PetModule:GetTypeList()
    local hasPet = false
    if typeList then
        for _, typeId in ipairs(typeList) do
            local count = ModuleRefer.PetModule:GetPetCountByType(typeId)
            if count and count > 0 then
                hasPet = true
            end
        end
    end
    if not hasPet then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("hero_pet_nopet"))
        return
    end
    ModuleRefer.HeroModule:SkipTimeline()
    g_Game.UIManager:Open(UIMediatorNames.UIPetCarryMediator, {heroId = self.selectHeroData.id, isPvP = self.parentMediator.isPvP})
end

function UIHeroInfoComponent:OnBtnOpenClicked(args)
    self.goTableBasicsShort:SetVisible(false)
    self.goTableBasicsLong:SetVisible(true)
    self.goOpen:SetVisible(false)
    -- self.goClose:SetVisible(true)
end

function UIHeroInfoComponent:OnBtnCloseClicked(args)
    -- self.goTableBasicsShort:SetVisible(true)
    -- self.goTableBasicsLong:SetVisible(false)
    -- self.goOpen:SetVisible(true)
    self.goClose:SetVisible(false)
end

function UIHeroInfoComponent:OnHeroCraftSucc(isSuccess, reply, rpc)
    if not isSuccess then
        return
    end
    local request = rpc.request
    local heroId = request.HeroCfgId
    g_Game.UIManager:Open(UIMediatorNames.UIOneDaySuccessMediator, {heroId = heroId})
end

function UIHeroInfoComponent:OnClickHintGoto(args)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonConfirmPopupMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.UIHeroMainUIMediator)
    -- goto
    local city = ModuleRefer.CityModule.myCity
    local furnitureTypeId = ConfigRefer.CityConfig:TrainingDummyFurniture()
    city:LookAtTargetFurnitureByTypeCfgId(furnitureTypeId, 0.8,nil,true)

    -- -- 英雄等级受家具限制
    -- if self.isLimited then
    --     ---@type CommonConfirmPopupMediatorParameter
    --     local confirmParameter = {}
    --     confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
    --     confirmParameter.confirmLabel = I18N.Get("hero_btn_confirm")
    --     confirmParameter.cancelLabel = I18N.Get("cancle")
    --     confirmParameter.content = I18N.GetWithParams("#再升级需要家具升级")
    --     confirmParameter.title = I18N.Get("se_quit_title")
    --     confirmParameter.onConfirm = function()
    --         g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonConfirmPopupMediator)
    --         g_Game.UIManager:CloseAllByName(UIMediatorNames.UIHeroMainUIMediator)
    --         -- goto
    --         local city = ModuleRefer.CityModule.myCity
    --         local furnitureTypeId = ConfigRefer.CityConfig:TrainingDummyFurniture()
    --         city:LookAtTargetFurnitureByTypeCfgId(furnitureTypeId, 0.8)
    --         return true
    --     end
    --     g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
    -- end
end

function UIHeroInfoComponent:OnClickResonateDetails(args)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local heros = player.Hero.SystemLevelHero
    local targetLevel = player.Hero.SystemLevel.SystemLevel

    local name = I18N.Get(ConfigRefer.Heroes:Find(heros[3]):Name())
    ---@type TextToastMediatorParameter
    local toastParameter = {}
    toastParameter.clickTransform =  self.p_btn_info.transform
    toastParameter.content = I18N.GetWithParams("animal_work_fur_desc_02", targetLevel, name)
    ModuleRefer.ToastModule:ShowTextToast(toastParameter)
end

return UIHeroInfoComponent
