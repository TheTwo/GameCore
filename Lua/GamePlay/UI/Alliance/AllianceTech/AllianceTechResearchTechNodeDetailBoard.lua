local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local AttrValueType = require("AttrValueType")
local UIHelper = require("UIHelper")
local TimeFormatter = require("TimeFormatter")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local DBEntityPath = require("DBEntityPath")
local ItemType = require("ItemType")
local AllianceTechConditionHelper = require("AllianceTechConditionHelper")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceTechResearchTechNodeDetailBoard:BaseUIComponent
---@field new fun():AllianceTechResearchTechNodeDetailBoard
---@field super BaseUIComponent
local AllianceTechResearchTechNodeDetailBoard = class('AllianceTechResearchTechNodeDetailBoard', BaseUIComponent)

function AllianceTechResearchTechNodeDetailBoard:ctor()
    BaseUIComponent.ctor(self)
    ---@type number|nil
    self._groupId = nil
    ---@type AllianceTechGroup|nil
    self._group = nil
    self._eventAdd = false
    ---@type wds.AllianceTechnologyNode|nil
    self._groupData = nil
    ---@type CS.UnityEngine.GameObject[]
    self._requireCurrencyGoCells = {}
    self._inResearching = false
    self._inNormalProgress = false
    self._canStudy = false
    self._isFirstUnlock = false
    self._donateCurrencyOk = false
    self._donateItemOk = false
    self._donateItemTimesOk = false
    self._assignItems = {}
    self._assignCurrency = {}
    self._currentConfig = nil
    self._gainTechPointNormal  = 0
end

function AllianceTechResearchTechNodeDetailBoard:OnCreate(param)
    self._p_icon_item = self:Image("p_icon_item_1")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_desc = self:Text("p_text_desc")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickBtnDetailTip))
    
    self._p_btn_recommend = self:Button("p_btn_recommend", Delegate.GetOrCreate(self, self.OnClickBtnRecommend))
    self._p_img_back_recommend = self:Image("p_img_back_recommend")
    self._p_text_recommend = self:Text("p_text_recommend", "alliance_tec_tuijian")
    self._p_btn_recommend_trigger = self:AnimTrigger("p_btn_recommend")
    
    self._p_text_level = self:Text("p_text_level", "alliance_tec_dengji")
    self._p_text_num_level = self:StatusRecordParent("p_text_num_level")
    self._p_text_level_a = self:Text("p_text_level_a")
    self._p_text_level_b = self:Text("p_text_level_b")
    
    self._p_text_speed = self:Text("p_text_speed")
    self._p_text_num_speed = self:StatusRecordParent("p_text_num_speed")
    self._p_text_speed_a = self:Text("p_text_speed_a")
    self._p_text_speed_b = self:Text("p_text_speed_b")
    
    self._p_group_progress = self:GameObject("p_group_progress")
    self._p_group_progress_trigger = self:AnimTrigger("p_group_progress")
    self._p_vx_add_start = self:AnimTrigger("p_vx_add_start")
    self._p_progress = self:Slider("p_progress")
    self._p_text_num = self:Text("p_text_num")
    self._p_btn_tech = self:Button("p_btn_tech")
    self._p_vx_crit_x2 = self:AnimTrigger("p_vx_crit_x2")
    self._p_vx_crit_x5 = self:AnimTrigger("p_vx_crit_x5")
    
    self._p_text_star_num = self:Text("p_text_star_num")
    self._p_text_crit = self:Text("p_text_crit")
    
    self._p_resources = self:GameObject("p_resources")
    self._p_text_hine = self:Text("p_text_hine", "alliance_tec_huode")
    self._p_table_resource = self:TableViewPro("p_table_resource")
    
    self._p_need = self:GameObject("p_need")
    self._p_text_hine_1 = self:Text("p_text_hine_1", "alliance_tec_yanjiuxuyao")
    self._p_item_need = self:Transform("p_item_need")
    self._child_common_quantity_l_template = self:GameObject("child_common_quantity_l_template")
    
    self._p_condition_tech = self:GameObject("p_condition_tech")
    self._p_text_hine_skill = self:Text("p_text_hine_skill", "alliance_tec_yanjiuxuyao")
    self._p_table_skill = self:TableViewPro("p_table_skill")
    
    self._p_img_mastered = self:GameObject("p_img_mastered")
    self._p_text_achieved = self:Text("p_text_achieved", "alliance_tec_wancheng")
    self._p_researching = self:GameObject("p_researching")
    self._p_text_researching = self:Text("p_text_researching", "alliance_tec_yanjiuzhong")
    ---@see CommonTimer
    self._child_research_time = self:LuaBaseComponent("child_research_time")
    self._p_progress_1 = self:Slider("p_progress_1")
    
    self._p_btns = self:GameObject("p_btns")
    ---@see CommonTimer
    self._child_time = self:LuaBaseComponent("child_time")
    ---@type BistateButton
    self._p_comp_btn_a_l_u2 = self:LuaObject("p_comp_btn_a_l_u2")
    self._p_donate = self:GameObject("p_donate")
    self._p_text_refresh = self:Text("p_text_refresh")
    self._p_text_times_1 = self:Text("p_text_times_1")

	self.p_text_lv = self:Text("p_text_lv")
    
    self._child_comp_btn_b_l = self:Button("child_comp_btn_b_l", Delegate.GetOrCreate(self, self.OnClickDonate))
    self._p_text_1 = self:Text("p_text_1", "alliance_tec_juanxian")
    self._p_number_bl = self:GameObject("p_number_bl")
    self._p_icon_item_bl = self:Image("p_icon_item_bl")
    self._p_text_num_green_bl = self:Text("p_text_num_green_bl")
    self._p_text_num_red_bl = self:Text("p_text_num_red_bl")
    self._p_text_num_wilth_bl = self:Text("p_text_num_wilth_bl")

	self._p_popup_btns = self:GameObject("p_popup_btns")
	
    self._p_btn_one = self:Button("p_btn_one", Delegate.GetOrCreate(self, self.OnClickDonateOne))
    self._p_text = self:Text("p_text", "alliance_tec_juanxian")
    self._p_number_al = self:GameObject("p_number_al")
    self._p_icon_item_al = self:Image("p_icon_item_al")
    self._p_text_num_green_al = self:Text("p_text_num_green_al")
    self._p_text_num_red_al = self:Text("p_text_num_red_al")
    self._p_text_num_wilth_al = self:Text("p_text_num_wilth_al")

	self._p_btn_ten = self:Button("p_btn_ten", Delegate.GetOrCreate(self, self.OnClickDonateTen))
	self._p_text_ten = self:Text("p_text_ten", "#全部捐献")
	self._p_number_al_ten = self:GameObject("p_number_al_ten")
	self._p_icon_item_al_ten = self:Image("p_icon_item_al_ten")
	self._p_text_num_green_al_ten = self:Text("p_text_num_green_al_ten")
	self._p_text_num_red_al_ten = self:Text("p_text_num_red_al_ten")
	self._p_text_num_wilth_al_ten = self:Text("p_text_num_wilth_al_ten")
end

function AllianceTechResearchTechNodeDetailBoard:OnShow(param)
    self.donateTimes = 0
    self._p_vx_add_start:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._p_vx_crit_x2:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._p_vx_crit_x5:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self:SetupEvent(true)
end

function AllianceTechResearchTechNodeDetailBoard:OnHide(param)
    self.donateTimes = 0
    self:SetupEvent(false)
end

function AllianceTechResearchTechNodeDetailBoard:OnClose(param)
    self:SetupEvent(false)
end

---@param groupId number @tech groupId
function AllianceTechResearchTechNodeDetailBoard:OnFeedData(groupId)
    table.clear(self._assignItems)
    table.clear(self._assignCurrency)
    self._p_vx_add_start:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._p_vx_crit_x2:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._p_vx_crit_x5:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self:SetupEvent(true)
    self:DoFeedData(groupId)
end


function AllianceTechResearchTechNodeDetailBoard:DoFeedData(groupId)
    self._inNormalProgress = false
    self._inResearching = false
    self._canStudy = false
    self._isFirstUnlock = false
    self._groupId = groupId
    self._group = ModuleRefer.AllianceTechModule:GetTechGroupByGroupId(groupId)
    self._groupData = ModuleRefer.AllianceTechModule:GetTechGroupStatus(groupId)
    
    local dataLv = math.clamp(self._groupData and self._groupData.Level or 0, 0,  #self._group)
    local configIndex = math.clamp(dataLv, 1, #self._group)
    local config = self._group[configIndex]
    local nextLvConfig = self._group[dataLv + 1]
    self._currentConfig = config

    g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(config:Icon()), self._p_icon_item)
    self._p_text_name.text = I18N.Get(config:Name())
    self._p_text_desc.text = I18N.Get(config:Desc())
    self.p_text_lv.text = I18N.GetWithParams("alliance_technology_rank_button",dataLv.. "/" .. #self._group)

    self:SetupLvUpInfo(dataLv, dataLv > 0 and config or nil, nextLvConfig)

    local point = self._groupData and self._groupData.Point or 0
    local needPoint = nextLvConfig and nextLvConfig:RequireTechPoint() or 0
    local inNormalProgress = self._groupData and self._groupData.Status <= wds.AllianceTechnologyNodeStatus.AlisTechStatusNormal and point < needPoint
    local canStudy = self._groupData and self._groupData.Status <= wds.AllianceTechnologyNodeStatus.AlisTechStatusNormal and point >= needPoint and nextLvConfig and self._groupData.UnlockNextLevel
    local isFirstUnlock = false--self._groupData and self._groupData.Status == wds.AllianceTechnologyNodeStatus.AlisTechStatusNotWorked and nextLvConfig and self._groupData.UnlockNextLevel
    local groupFinished = inNormalProgress and config ~= nil and nextLvConfig == nil
    local inResearching = self._groupData and self._groupData.Status == wds.AllianceTechnologyNodeStatus.AlisTechStatusInStudy
    local isTechPreNodeReady = true
    if nextLvConfig then
        local requireTechCondition = ConfigRefer.AllianceTechConditions:Find(nextLvConfig:Id())
        if requireTechCondition then
            for i = 1, requireTechCondition:ConditionsLength() do
                local condition = requireTechCondition:Conditions(i)
                if not AllianceTechConditionHelper.Parse(condition) then 
                    isTechPreNodeReady = false 
                    break 
                end
            end
        end
    end
    
    if canStudy or isFirstUnlock or not self._groupData or not self._groupData.UnlockNextLevel then
        inNormalProgress = false
    end
    self._canStudy = canStudy
    self._isFirstUnlock = isFirstUnlock
    self._inNormalProgress = inNormalProgress
    self._inResearching = inResearching

    self._p_group_progress:SetVisible(inNormalProgress)
    self._p_resources:SetVisible(inNormalProgress)
    self._p_need:SetVisible(canStudy or isFirstUnlock)
    self._p_img_mastered:SetVisible(groupFinished)
    self._p_researching:SetVisible(inResearching)
    self._p_btns:SetVisible(not inResearching and not groupFinished)
    self._p_donate:SetVisible(inNormalProgress)
    self._p_comp_btn_a_l_u2:SetVisible(canStudy or isFirstUnlock)
    self._child_time:SetVisible(canStudy or isFirstUnlock)
    self._p_condition_tech:SetVisible(not (inNormalProgress or canStudy or isFirstUnlock or inResearching) and nextLvConfig)
    if inNormalProgress then
        self:SetupDonate(config, needPoint, point)
    elseif canStudy or isFirstUnlock then
        self:SetupStudy(nextLvConfig)
    elseif not inResearching and nextLvConfig then
        self._p_table_skill:Clear()
        local requireTechCondition = ConfigRefer.AllianceTechConditions:Find(nextLvConfig:Id())
        if requireTechCondition then
            for i = 1, requireTechCondition:ConditionsLength() do
                local condition = requireTechCondition:Conditions(i)
                self._p_table_skill:AppendData(condition)
            end
        end
    end
    self:SetupRecommend(true)
    self:Tick(0)
	
	self:OnSwitchDonateButton()
end

---@param dataLv number
---@param currentShowConfig AllianceTechnologyConfigCell
---@param nextLvConfig AllianceTechnologyConfigCell
function AllianceTechResearchTechNodeDetailBoard:SetupLvUpInfo(dataLv, currentShowConfig, nextLvConfig)
    local upAttrInfo = self:ParseUpLvAttrChange(currentShowConfig, nextLvConfig)
    self._p_text_num_level:SetVisible((nextLvConfig or currentShowConfig) ~= nil)
    self._p_text_num_speed:SetVisible((nextLvConfig or currentShowConfig) ~= nil)
    if nextLvConfig then
        self._p_text_num_level:SetState(0)
        self._p_text_num_speed:SetState(0)
        self._p_text_level_a.text = tostring(dataLv)
        self._p_text_level_b.text = tostring(dataLv + 1)
        local hasContent = false
        for i, v in pairs(upAttrInfo) do
            if v.after then
                hasContent = true
                local attrElement = ConfigRefer.AttrElement:Find(i)

                local name = nextLvConfig:AllianceAttrLabelName()
                if name  ~= "" then
                    self._p_text_speed.text = I18N.Get(name)
                else
                    self._p_text_speed.text = I18N.Get(attrElement:Name())
                end
                self:SetAttrValue(self._p_text_speed_a, attrElement:ValueType(), v.before or 0)
                self:SetAttrValue(self._p_text_speed_b, attrElement:ValueType(), v.after)
                break
            end
        end
        self._p_text_speed:SetVisible(hasContent)
        self._p_text_num_speed:SetVisible(hasContent)
    elseif currentShowConfig then
        self._p_text_num_level:SetState(1)
        self._p_text_num_speed:SetState(1)
        self._p_text_level_a.text = tostring(dataLv)
        local hasContent = false
        for i, v in pairs(upAttrInfo) do
            if v.before then
                hasContent = true
                local attrElement = ConfigRefer.AttrElement:Find(i)

                if currentShowConfig:AllianceAttrLabelName() then
                    self._p_text_speed.text = I18N.Get(currentShowConfig:AllianceAttrLabelName())
                else
                    self._p_text_speed.text = I18N.Get(attrElement:Name())
                end
                self:SetAttrValue(self._p_text_speed_a, attrElement:ValueType(), v.before)
                break
            end
        end
        self._p_text_speed:SetVisible(hasContent)
        self._p_text_num_speed:SetVisible(hasContent)
    end
end

---@param config AllianceTechnologyConfigCell
---@param needPoint number
---@param point number
function AllianceTechResearchTechNodeDetailBoard:SetupDonate(config, needPoint, point)
    if needPoint <= 0 then
        self._p_progress.value = 0
    else
        self._p_progress.value = math.inverseLerp(0, needPoint, point)
    end
    self._p_text_num.text = ("%d/%d"):format(point, needPoint)
    self._p_table_resource:Clear()
--[[    if config:GainCurrencyPerDonate() > 0 and config:GainCurrencyCountPerDonate() > 0 then
        local currency = ConfigRefer.AllianceCurrency:Find(config:GainCurrencyPerDonate())
        if currency then
            ---@type ItemIconData
            local iconData = {}
            iconData.customImage = currency:Icon()
            iconData.customQuality = 0
            iconData.count = config:GainCurrencyCountPerDonate()
            iconData.hideBtnDelete = true
            self._p_table_resource:AppendData(iconData)
        end
    end
    local otherLength = config:GainOtherCurrenciesPerDonateLength()
    local otherCountLength = config:GainOtherCurrenciesCountPerDonateLength()
    for i = 1, math.min(otherLength, otherCountLength) do
        local count = config:GainOtherCurrenciesCountPerDonate(i)
        if count > 0 then
            local currency = ConfigRefer.AllianceCurrency:Find(config:GainOtherCurrenciesPerDonate(i))
            if currency then
                ---@type ItemIconData
                local iconData = {}
                iconData.customImage = currency:Icon()
                iconData.customQuality = 0
                iconData.count = count
                iconData.hideBtnDelete = true
                self._p_table_resource:AppendData(iconData)
            end
        end
    end]]
    local gainItem = config:GainItems()
    local itemGroup = ConfigRefer.ItemGroup:Find(gainItem)
    if itemGroup then
        for i = 1, itemGroup:ItemGroupInfoListLength() do
            local item = itemGroup:ItemGroupInfoList(i)
            local itemConfig = ConfigRefer.Item:Find(item:Items())
            if itemConfig and item:Nums() > 0 then
                ---@type ItemIconData
                local iconData = {}
                iconData.configCell = itemConfig
                iconData.count = item:Nums()
                iconData.hideBtnDelete = true
                self._p_table_resource:AppendData(iconData)
            end
        end
    end
    self._gainTechPointNormal = config:GainTechPointPerDonate()
    self:UpdateDonateButtons(config)
end

---@param config AllianceTechnologyConfigCell
function AllianceTechResearchTechNodeDetailBoard:UpdateDonateButtons(config)
    self._donateCurrencyOk = false
    self._donateItemOk = false
    self._donateItemTimesOk = false

    local playerAlliance = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance
    local times = playerAlliance.NormalDonateTimes
    local limitTimes = ConfigRefer.AllianceConsts:AllianceItemDonateLimit()
    local leftTimes = math.max(0, limitTimes - times)
    local leftTimesStr = leftTimes > 0 and tostring(leftTimes) or ("<color=red>%d</color>"):format(leftTimes)
    self._p_text_times_1.text = I18N.GetWithParams("alliance_tec_jihui03", leftTimesStr, tostring(limitTimes))
    self._donateItemTimesOk = leftTimes > 0

    table.clear(self._assignItems)
    table.clear(self._assignCurrency)
    -- currency donate
    local currencyDonateCost, currencyCount = ModuleRefer.AllianceTechModule:GetCurrentDonateCost()
    if not currencyDonateCost then
        self._donateCurrencyOk = true
        self._p_number_bl:SetVisible(false)
    else
        self._p_number_bl:SetVisible(true)
        local item = ConfigRefer.Item:Find(currencyDonateCost:RelItem())
        if item then
            if item:Type() == ItemType.Currency then
                for i = 1, item:TagLength() do
                    local currencyId = tonumber(item:Tag(i))
                    if currencyId then
                        self._assignCurrency[currencyId] = true
                    end
                end
            else
                self._assignItems[item:Id()] = true
            end
        end
        g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(item and item:Icon() or nil), self._p_icon_item_bl)
        local hasCount = ModuleRefer.InventoryModule:GetAmountByConfigId(item:Id())
        local enough = hasCount >= currencyCount and hasCount > 0
        self._p_text_num_green_bl:SetVisible(enough)
        self._p_text_num_red_bl:SetVisible(not enough)
        if enough then
            self._donateCurrencyOk = true
            self._p_text_num_green_bl.text = tostring(hasCount)
        else
            self._p_text_num_red_bl.text = tostring(hasCount)
        end
        self._p_text_num_wilth_bl.text = ("/%d"):format(currencyCount)
    end
    
    -- item donate
    local costItemGroupId = config:DonateCostItem()
    local costItemGroup = ConfigRefer.ItemGroup:Find(costItemGroupId)
    local costItem= costItemGroup and costItemGroup:ItemGroupInfoList(1):Items() or 0
	local costCount = config:CostItemCountPerDonate() * (costItemGroup and costItemGroup:ItemGroupInfoList(1):Nums() or 1)
	local allCostCount = config:CostItemCountPerDonate() * (costItemGroup and costItemGroup:ItemGroupInfoList(1):Nums() or 1) * leftTimes
    local hasCount = ModuleRefer.InventoryModule:GetAmountByConfigId(costItem)
    local itemConfig = ConfigRefer.Item:Find(costItem)
    if itemConfig then
        if itemConfig:Type() == ItemType.Currency then
            for i = 1, itemConfig:TagLength() do
                local currencyId = tonumber(itemConfig:Tag(i))
                if currencyId then
                    self._assignCurrency[currencyId] = true
                end
            end
        else
            self._assignItems[costItem] = true
        end
    end
	--one
    g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(itemConfig and itemConfig:Icon() or nil), self._p_icon_item_al)
    local enough = hasCount >= costCount and hasCount > 0
    self._p_text_num_green_al:SetVisible(enough)
    self._p_text_num_red_al:SetVisible(not enough)
    if enough then
        self._donateItemOk = true
        self._p_text_num_green_al.text = tostring(hasCount)
    else
        self._p_text_num_red_al.text = tostring(hasCount)
    end
    self._p_text_num_wilth_al.text = ("/%d"):format(costCount)
	--all
	g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(itemConfig and itemConfig:Icon() or nil), self._p_icon_item_al_ten)
	local allEnough = hasCount >= allCostCount and hasCount > 0
	self._p_text_num_green_al_ten:SetVisible(allEnough)
	self._p_text_num_red_al_ten:SetVisible(not allEnough)
	if allEnough then
		self._donateItemOk = true
		self._p_text_num_green_al_ten.text = tostring(hasCount)
	else
		self._p_text_num_red_al_ten.text = tostring(hasCount)
	end
	self._p_text_num_wilth_al_ten.text = ("/%d"):format(allCostCount)
end

---@param nextLvConfig AllianceTechnologyConfigCell
function AllianceTechResearchTechNodeDetailBoard:SetupStudy(nextLvConfig)
    local upResOk = true
    local hasAuthority = true
    local researchIdle = true
    local currency = ConfigRefer.AllianceCurrency:Find(nextLvConfig:RequireAllianceCurrency())
    if currency and nextLvConfig:RequireAllianceCurrencyCount() > 0 then
        ---@type CS.UnityEngine.GameObject
        local cell
        if #self._requireCurrencyGoCells > 0 then
            cell = self._requireCurrencyGoCells[1]
            for i = 2, #self._requireCurrencyGoCells do
                self._requireCurrencyGoCells[i]:SetVisible(false)
            end
        else
            self._child_common_quantity_l_template:SetVisible(true)
            cell = UIHelper.DuplicateUIGameObject(self._child_common_quantity_l_template, self._p_item_need)
            self._child_common_quantity_l_template:SetVisible(false)
            table.insert(self._requireCurrencyGoCells, cell)
        end
        ---@type CS.UnityEngine.UI.Image
        local frame = cell.transform:Find("icon_item/p_base_farme"):GetComponent(typeof(CS.UnityEngine.UI.Image))
        ---@type CS.UnityEngine.UI.Image
        local icon = cell.transform:Find("icon_item/p_icon_item"):GetComponent(typeof(CS.UnityEngine.UI.Image))
        ---@type CS.UnityEngine.UI.Text
        local numText = cell.transform:Find("lyt/p_text_01"):GetComponent(typeof(CS.UnityEngine.UI.Text))
        numText.text = tostring(ModuleRefer.AllianceTechModule:CalculateTechRequireAllianceCurrencyCount(nextLvConfig))
        g_Game.SpriteManager:LoadSprite("sp_item_frame_circle_0", frame)
        g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(currency:Icon()), icon)
    else
        self._p_need:SetVisible(false)
    end
    ---@type CommonTimerData
    local timerData = {}
    timerData.fixTime = ModuleRefer.AllianceTechModule:CalculateTechCostTime(nextLvConfig)
    timerData.needTimer = false
    self._child_time:FeedData(timerData)
    ---@type BistateButtonParameter
    local researchBtnData = {}
    researchBtnData.buttonText = I18N.Get("alliance_tec_yanjiu")
    researchBtnData.onClick = Delegate.GetOrCreate(self, self.OnClickResearch)
    researchBtnData.disableClick = Delegate.GetOrCreate(self, self.OnClickResearch)
    self._p_comp_btn_a_l_u2:FeedData(researchBtnData)
    self._p_comp_btn_a_l_u2:SetEnabled(upResOk and hasAuthority and researchIdle and ModuleRefer.AllianceTechModule:GetResearchIdleStatus())
end

---@param text CS.UnityEngine.UI.Text
---@param valueType number AttrValueType
---@param value number
function AllianceTechResearchTechNodeDetailBoard:SetAttrValue(text, valueType, value)
    if AttrValueType.Percentages == valueType then
        text.text = ("%s%%"):format(value)
    elseif AttrValueType.OneTenThousand == valueType then
        text.text = ("%d%%"):format(math.floor(value / 100))
    else
        text.text = tostring(value)
    end
end

---@param currentShowConfig AllianceTechnologyConfigCell
---@param nextLvConfig AllianceTechnologyConfigCell
---@return table<number, {before:number, after:number}>
function AllianceTechResearchTechNodeDetailBoard:ParseUpLvAttrChange(currentShowConfig, nextLvConfig)
    local ret = {}
    if nextLvConfig then
        local attrUp = ConfigRefer.AttrGroup:Find(nextLvConfig:Attr())
        if attrUp then
            for i = 1, attrUp:AttrListLength() do
                local attr = attrUp:AttrList(i)
                ret[attr:TypeId()] = {after = attr:Value()}
            end
        end
    end
    if currentShowConfig then
        local attrNow = ConfigRefer.AttrGroup:Find(currentShowConfig:Attr())
        if attrNow then
            for i = 1, attrNow:AttrListLength() do
                local attr = attrNow:AttrList(i)
                local v = ret[attr:TypeId()]
                if v then
                    v.before = attr:Value()
                else
                    ret[attr:TypeId()] = {before = attr:Value()}
                end
            end
        end
    end
    return ret
end

function AllianceTechResearchTechNodeDetailBoard:SetupRecommend(skipAni)
    local hasAuthority = ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.UpgradeTech)
    local isRecommend = ModuleRefer.AllianceTechModule:GetRecommendTech() == self._groupId
    if not hasAuthority then
        if not isRecommend then
            self._p_btn_recommend:SetVisible(false)
        else
            self._p_btn_recommend:SetVisible(true)
            self._p_text_recommend.text = I18N.Get("alliance_tec_tuijiankeji")
            if skipAni then
                self._p_btn_recommend_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
            else
                self._p_btn_recommend_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
            end
        end
    else
        self._p_btn_recommend:SetVisible(true)
        if not isRecommend then
            self._p_text_recommend.text = I18N.Get("alliance_tec_shezhituijian")
            -- self._p_btn_recommend_trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
            self._p_img_back_recommend.color = CS.UnityEngine.Color(1,1,1,1)
        else
            self._p_text_recommend.text = I18N.Get("alliance_tec_tuijiankeji")
            if skipAni then
                self._p_btn_recommend_trigger:FinishAll(CS.FpAnimation.CommonTriggerType.Custom1)
            else
                self._p_btn_recommend_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
            end
        end
    end
end

function AllianceTechResearchTechNodeDetailBoard:OnClickBtnDetailTip()
    if not self._currentConfig then
        
    end
    g_Game.UIManager:Open(UIMediatorNames.AllianceTechPromptMediator,{groupId = self._groupId})

    -- ---@type TextToastMediatorParameter
    -- local param = {}
    -- param.content = I18N.Get(self._currentConfig:Tip())
    -- param.clickTransform = self._p_btn_detail:GetComponent(typeof(CS.UnityEngine.RectTransform))
    -- ModuleRefer.ToastModule:ShowTextToast(param)
end

function AllianceTechResearchTechNodeDetailBoard:OnClickBtnRecommend()
    if not self._groupId then
        return
    end
    local hasAuthority = ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.MarkTech)
    local isRecommend = ModuleRefer.AllianceTechModule:GetRecommendTech() == self._groupId
    if not hasAuthority or isRecommend then
        return
    end
    -- self._p_btn_recommend_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    ModuleRefer.AllianceTechModule:SetRecommendTech(self._p_btn_recommend.transform, self._groupId)
end

function AllianceTechResearchTechNodeDetailBoard:OnClickResearch()
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.UpgradeTech) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_tec_meiyouquanxian"))
        return
    end
    if not ModuleRefer.AllianceTechModule:GetResearchIdleStatus() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_tec_toast01"))
        return
    end
    
    g_Game.UIManager:CloseByName(UIMediatorNames.CommonConfirmPopupMediator)

    local nextLv = self._groupData and self._groupData.Level + 1 or 1
    local nextLvConfig = self._group[nextLv]
    local currency = ConfigRefer.AllianceCurrency:Find(nextLvConfig:RequireAllianceCurrency())
    if currency and nextLvConfig:RequireAllianceCurrencyCount() > 0 then
        local hasCount = ModuleRefer.AllianceModule:GetAllianceCurrencyById(currency:Id())
        local requireCurrencyCount = ModuleRefer.AllianceTechModule:CalculateTechRequireAllianceCurrencyCount(nextLvConfig)
        if hasCount < requireCurrencyCount then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_tec_toast02"))
            return
        end
        ---@type CommonConfirmPopupMediatorParameter
        local confirmParameter = {}
        confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.WithItems
        confirmParameter.content =I18N.Get("alliance_tec_toast03")
        ---@type CommonPairsQuantityParameter
        local iconInfo = {}
        iconInfo.customQuality = 0
        iconInfo.itemIcon = UIHelper.IconOrMissing(currency:Icon())
        iconInfo.num2 = requireCurrencyCount
        iconInfo.num1 = hasCount
        iconInfo.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
        confirmParameter.items = {iconInfo}
        confirmParameter.onConfirm = function()
            ModuleRefer.AllianceTechModule:SendStartResearchTech(nil, self._groupId)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
    else
        ModuleRefer.AllianceTechModule:SendStartResearchTech(nil, self._groupId)
    end
end

function AllianceTechResearchTechNodeDetailBoard:OnSwitchDonateButton()
	self._p_popup_btns:SetVisible(self.donateTimes >= 5)
end

function AllianceTechResearchTechNodeDetailBoard:OnClickDonate()
    if not self._donateCurrencyOk then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_tec_nomoney"))
        return
    end
    ModuleRefer.AllianceTechModule:DonateAllianceTech(nil, self._groupId, true, false, Delegate.GetOrCreate(self, self.OnDonateCallback), self._gainTechPointNormal)
end

function AllianceTechResearchTechNodeDetailBoard:OnClickDonateOne()
    if not self._donateItemTimesOk then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_tec_toast04"))
        return
    end
    if not self._donateItemOk then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_tec_toast05"))
        return
    end
    ModuleRefer.AllianceTechModule:DonateAllianceTech(nil, self._groupId, false, false, Delegate.GetOrCreate(self, self.OnDonateCallback), self._gainTechPointNormal)

    --点击五次显示捐献全部
    self.donateTimes = self.donateTimes + 1

    self:OnSwitchDonateButton()
end

function AllianceTechResearchTechNodeDetailBoard:OnClickDonateTen()
	if not self._donateItemTimesOk then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_tec_toast04"))
		return
	end
	if not self._donateItemOk then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_tec_toast05"))
		return
	end
	ModuleRefer.AllianceTechModule:DonateAllianceTech(nil, self._groupId, false, true, Delegate.GetOrCreate(self, self.OnDonateCallback), self._gainTechPointNormal)

    self.donateTimes = 0
    self:OnSwitchDonateButton()
end

---@param cmd DonateAllianceParameter
---@param isSuccess boolean
---@param rsp wrpc.DonateAllianceReply
function AllianceTechResearchTechNodeDetailBoard:OnDonateCallback(cmd, isSuccess, rsp)
    if isSuccess then
        if cmd.msg.userdata and type(cmd.msg.userdata) == 'number' then
            if rsp and rsp.GainTimes > 1 then
                self._p_text_star_num.text = ("+%d"):format(cmd.msg.userdata * rsp.GainTimes)
                self._p_vx_add_start:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
                self._p_vx_add_start:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
                self._p_text_crit.text = ("x%d"):format(rsp.GainTimes)
                if rsp.GainTimes >= 5 then
                    self._p_vx_crit_x5:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
                    self._p_vx_crit_x5:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
                else
                    self._p_vx_crit_x2:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
                    self._p_vx_crit_x2:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
                end
            else
                self._p_text_star_num.text = ("+%d"):format(cmd.msg.userdata)
                self._p_vx_add_start:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
                self._p_vx_add_start:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
            end
        end
    end
end

function AllianceTechResearchTechNodeDetailBoard:SetupEvent(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_TECH_RECOMMEND_UPDATED, Delegate.GetOrCreate(self, self.SetupRecommend))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_TECH_NODE_UPDATED, Delegate.GetOrCreate(self, self.OnNodeUpdated))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_TECH_RESEARCH_IDLE_STATUS_UPDATED, Delegate.GetOrCreate(self, self.OnTechResearchIdleStatusChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnItemsChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Currency.Values.MsgPath, Delegate.GetOrCreate(self, self.OnCurrencyValuesChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerAlliance.LastRecoverNormalDonateTime.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerAllianceDonateTimesRefresh))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_TECH_RECOMMEND_UPDATED, Delegate.GetOrCreate(self, self.SetupRecommend))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_TECH_NODE_UPDATED, Delegate.GetOrCreate(self, self.OnNodeUpdated))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_TECH_RESEARCH_IDLE_STATUS_UPDATED, Delegate.GetOrCreate(self, self.OnTechResearchIdleStatusChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnItemsChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Currency.Values.MsgPath, Delegate.GetOrCreate(self, self.OnCurrencyValuesChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerAlliance.LastRecoverNormalDonateTime.MsgPath, Delegate.GetOrCreate(self, self.OnPlayerAllianceDonateTimesRefresh))
    end
end

function AllianceTechResearchTechNodeDetailBoard:Tick(dt)
    if not self._groupData then
        return
    end
    if self._inNormalProgress then
        local playerAlliance = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance
        local timesFull = playerAlliance.NormalDonateTimes <= 0
        local donateRecoverTime = playerAlliance.LastRecoverNormalDonateTime.Seconds + ConfigRefer.AllianceConsts:AllianceItemDonateRecoverTime()
        local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        local leftTime = donateRecoverTime - nowTime
        if leftTime > 0 and not timesFull then
            self._p_text_refresh:SetVisible(true)
            self._p_text_refresh.text = I18N.GetWithParams("alliance_tec_juanxianhuifu", TimeFormatter.SimpleFormatTime(leftTime))
        else
            self._p_text_refresh:SetVisible(false)
        end
    elseif self._inResearching then
        local nextLvConfig = self._group[self._groupData.Level + 1]
        if not nextLvConfig then
            return
        end
        local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        local startTime = self._groupData.LevelUpTime.Seconds
        local costTime = ModuleRefer.AllianceTechModule:CalculateTechCostTime(nextLvConfig)
        local endTime = startTime + costTime
        local leftTime = endTime - nowTime
        ---@type CommonTimerData
        local timeParameter = {}
        timeParameter.fixTime = leftTime
        timeParameter.needTimer = false
        self._child_research_time:FeedData(timeParameter)
        local progress = costTime > 0 and math.inverseLerp(startTime, endTime, nowTime) or 0
        self._p_progress_1.value = progress
    end
end

function AllianceTechResearchTechNodeDetailBoard:OnTechResearchIdleStatusChanged(_, _)
    if not self._groupData or (not self._canStudy and not self._isFirstUnlock) then
        return
    end
    self:DoFeedData(self._groupId)
end

function AllianceTechResearchTechNodeDetailBoard:OnNodeUpdated(groupIds)
    if not self._groupId or not groupIds[self._groupId] then
        return
    end
    self:DoFeedData(self._groupId)
end

function AllianceTechResearchTechNodeDetailBoard:OnItemsChanged(entity, changedData)
    if not self._groupId or not self._currentConfig or not self._inNormalProgress or not changedData then
        return
    end
    if changedData.Add then
        for _, item in pairs(changedData.Add) do
            if self._assignItems[item.ConfigId] then
                self:UpdateDonateButtons(self._currentConfig)
                return
            end
        end
    end
    if changedData.Remove then
        for _, item in pairs(changedData.Remove) do
            if self._assignItems[item.ConfigId] then
                self:UpdateDonateButtons(self._currentConfig)
                return
            end
        end
    end
end

---@param entity wds.Player
function AllianceTechResearchTechNodeDetailBoard:OnCurrencyValuesChanged(entity, changedData)
    if not self._groupId or not self._currentConfig or not self._inNormalProgress or not changedData then
        return
    end
    if entity.ID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    if changedData.Add then
        for tagId, _ in pairs(changedData.Add) do
            if self._assignCurrency[tagId] then
                self:UpdateDonateButtons(self._currentConfig)
                return
            end
        end
    end
    if changedData.Remove then
        for tagId, _ in pairs(changedData.Remove) do
            if self._assignCurrency[tagId] then
                self:UpdateDonateButtons(self._currentConfig)
                return
            end
        end
    end
end

---@param entity wds.Player
function AllianceTechResearchTechNodeDetailBoard:OnPlayerAllianceDonateTimesRefresh(entity, changedData)
    if entity.ID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    if not self._groupData or not self._inNormalProgress or not self._currentConfig then
        return
    end
    self:UpdateDonateButtons(self._currentConfig)
end

return AllianceTechResearchTechNodeDetailBoard
