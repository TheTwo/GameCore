local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local UIHelper = require('UIHelper')
local NotificationType = require('NotificationType')
local ConfigRefer = require('ConfigRefer')
local ItemType = require('ItemType')
local GuideUtils = require("GuideUtils")
local AudioConsts = require('AudioConsts')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local UIMediatorNames = require("UIMediatorNames")
---@class UIHeroBreakComponent : BaseUIComponent
local UIHeroBreakComponent = class('UIHeroPropertyListComponent', BaseUIComponent)

function UIHeroBreakComponent:ctor()
    self.module = ModuleRefer.HeroModule
    self.Inventory = ModuleRefer.InventoryModule
end

function UIHeroBreakComponent:OnCreate()
    self.textTitle = self:Text('p_text_title', I18N.Get("hero_breakthrough_effect"))
    self.textLvInfo = self:Text('p_text_lvInfo', I18N.Get("hero_upper_level_limit_improve"))
    self.textLvInfo1 = self:Text('p_text_lvInfo_1', I18N.Get("hero_upper_level_limit_improve"))
    self.textNum1 = self:Text('p_text_num_1')
    self.textAdd1 = self:Text('p_text_add_1')
    self.goSkill = self:GameObject('p_skill')
    self.textSkill = self:Text('p_text_skill')
    self.textSkillName = self:Text('p_text_skill_name')
    self.imgImgSkill = self:Image('p_img_skill')
    self.goFunction = self:GameObject('p_function')
    self.textFunction = self:Text('p_text_function')
    self.textFunctionlName = self:Text('p_text_functionl_name')
    self.textTitle1 = self:Text('p_text_title_1', I18N.Get("hero_breakthrough_item_tips"))
    self.tableviewproNeedItem = self:TableViewPro('p_need_item')
    self.goHeroMark = self:GameObject('hero_mark')
    self.compBreak = self:LuaObject('p_comp_btn_break')
    self.breakNodeCom = self:LuaObject('child_reddot_default')

    self.goState = self:GameObject('p_state_goto')
    self.textConditions = self:Text('p_text_conditions')
	self.buttonBreakGoto = self:Button("p_btn_break_goto", Delegate.GetOrCreate(self, self.OnGotoClick))
    self.textGoto = self:Text('p_text_goto', I18N.Get("alliance_bj_qianwang"))
    self.parentMediator = self:GetParentBaseUIMediator()
end

function UIHeroBreakComponent:OnShow(param)
    self.selectHero = self.parentMediator:GetSelectHero()
    if not self.selectHero:HasHero() then
        return
    end
    local buttonBreak = {}
    buttonBreak.onClick = Delegate.GetOrCreate(self, self.OnBtnCompBreakClicked)
    buttonBreak.buttonText = I18N.Get("hero_btn_breakthrough")
    self.compBreak:OnFeedData(buttonBreak)
    self.textNum1.text = tostring(self.selectHero.dbData.LevelUpperLimit)
    self.nextBreakConfig = self.module:FindBreakConfig(self.selectHero.configCell,self.selectHero.dbData.LevelUpperLimit+1)
    self.textAdd1.text = tostring(self.nextBreakConfig:LevelUpperLimit())
    self.goSkill:SetVisible(false)
    self.goFunction:SetVisible(false)

    local itemGroupConfig = ConfigRefer.ItemGroup:Find(self.nextBreakConfig:CostItemGroupCfgId())
    self.costItemsData = {}
    ---@type table<ItemConfigCell.Quality,table>

    for i = 1, itemGroupConfig:ItemGroupInfoListLength() do
        local info = itemGroupConfig:ItemGroupInfoList(i)
        local itemId = info:Items()
        local hasNum = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
        self.costItemsData[itemId] = {
            itemId = itemId,
            need = info:Nums(),
            has = hasNum,
        }
    end
    self:RefreshBreakNeedItem()
    local breakNode = ModuleRefer.NotificationModule:GetDynamicNode("HeroBreakNode" .. self.selectHero.id, NotificationType.HERO_BREAK_BTN)
    ModuleRefer.NotificationModule:AttachToGameObject(breakNode, self.breakNodeCom.go, self.breakNodeCom.redDot)

    local taskId = self.nextBreakConfig:BreakThroughCondition()
    if taskId and taskId > 0 then
        local status = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
        local isTaskFinished = status == wds.TaskState.TaskStateFinished or status == wds.TaskState.TaskStateCanFinish
        self.compBreak:SetVisible(isTaskFinished)
        self.goState:SetActive(not isTaskFinished)
        if not isTaskFinished then
            self.textConditions.text = ModuleRefer.QuestModule:GetTaskDesc(taskId)
        end
    end
end

function UIHeroBreakComponent:OnGotoClick()
    local taskId = self.nextBreakConfig:BreakThroughCondition()
    if taskId and taskId > 0 then
        local gotoId = ModuleRefer.QuestModule:GetTaskGotoID(taskId)
        if gotoId > 0 then
            GuideUtils.GotoByGuide(gotoId)
        end
    end
end

function UIHeroBreakComponent:OnBtnCompBreakLimitClicked()
    local isCanBreak, list = self:CheckCanBerak()
    if not isCanBreak then
        ModuleRefer.InventoryModule:OpenExchangePanel(list)
    end
end

function UIHeroBreakComponent:OnBtnCompBreakClicked()
    local isCanBreak, _ = self:CheckCanBerak()
    if not isCanBreak then
        self:OnBtnCompBreakLimitClicked()
        return
    end
    local heroCfg = ConfigRefer.Heroes:Find(self.selectHero.id)
    local resCell = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg())
    g_Game.SoundManager:PlayAudio(resCell:StrengthVoiceRes())
    self.module:BreakThrough(self.selectHero.id)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
end

function UIHeroBreakComponent:CheckCanBerak()
    local enough = true
    local lackList = {}
    for _, v in pairs(self.costItemsData) do
        if v.need > v.has then
            enough = false
            lackList[#lackList + 1] = {id = v.itemId, num = v.need - v.has}
        end
    end
    return enough, lackList
end

function UIHeroBreakComponent:OnOpened(param)
end

function UIHeroBreakComponent:OnClose(param)
end

function UIHeroBreakComponent:NeedBreak()
    if self.selectHeroData then
        return self.module:NeedBreak(self.selectHero.id)
    end
    return false
end

function UIHeroBreakComponent:RefreshBreakNeedItem()
    if not self.costItemsData then
        return
    end
    self.tableviewproNeedItem:Clear()
    for _, info in pairs(self.costItemsData) do
        local param = {}
        param.itemId = info.itemId
        param.num1 = info.has
        param.num2 = info.need
        param.useColor2 = true
        param.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
        self.tableviewproNeedItem:AppendData(param)
    end
end

function UIHeroBreakComponent:ClickItem(info)
    if info.has >= info.need then
        local param = {
            itemId = info.config:Id(),
            itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM,
        }
        g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
    else
        ModuleRefer.InventoryModule:OpenExchangePanel({{id = info.config:Id()}})
    end
end


return UIHeroBreakComponent;
