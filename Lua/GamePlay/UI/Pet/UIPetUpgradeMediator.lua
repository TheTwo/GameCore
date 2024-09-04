local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local ColorUtil = require("ColorUtil")
local EventConst = require("EventConst")

---@class UIPetUpgradeMediator : BaseUIMediator
local UIPetUpgradeMediator = class('UIPetUpgradeMediator', BaseUIMediator)

local ATTR_DISP_ID_SE_ATTACK = 15
local ATTR_DISP_ID_SE_DEFENSE = 18
local ATTR_DISP_ID_SE_HP = 27
local ATTR_DISP_ID_SE_MOVE_SPEED = 39
local ATTR_DISP_ID_SLG_DAMAGE = 111

local I18N_BUTTON_UPGRADE = "pet_uplevel"
local I18N_BUTTON_ADD_EXP = "pet_memo2"

local PREVIEW_LEVEL_COUNT = 5
local COLOR_ADD_EXP = ColorUtil.FromHexNoAlphaString("488a02")
local COLOR_NEED_EXP = ColorUtil.FromHexNoAlphaString("ff0000")

local PAGE_DETAIL_BASIC = 0
local PAGE_DETAIL_WORLD = 1

function UIPetUpgradeMediator:ctor()
	self._petId = -1
	---@type wds.PetInfo
	self._petInfo = nil
	---@type PetConfigCell
	self._petCfg = nil
	---@type table
	self._expItems = {}
	self._expItemDataMap = {}
	self._maxTargetLevel = 0
	self._targetMaxLevel = 0
	self._targetLevel = 0
	---@type AttrDisplayConfigCell
	self._dispConfSeAttack = nil
	---@type AttrDisplayConfigCell
	self._dispConfSeDefense = nil
	---@type AttrDisplayConfigCell
	self._dispConfSeHp = nil
	---@type AttrDisplayConfigCell
	self._dispConfSeSpeed = nil
	---@type AttrDisplayConfig
	self._dispConfSlgDamage = nil
	self._orgSeAttack = 0
	self._orgSeDefense = 0
	self._orgSeHp = 0
	self._orgSeSpeed = 0
	self._orgSlgDamage = 0
	self._attrListTable = {}
	self._closeCallback = nil
	self._orgExpPct = 0
	self._previewMode = false
	self._itemListenerTable = {}
end

function UIPetUpgradeMediator:OnCreate()
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.PetInfos.MsgPath, Delegate.GetOrCreate(self, self.PetInfoChanged))
    self:InitObjects()
end

function UIPetUpgradeMediator:InitObjects()
	---@type CommonBackButtonComponent
	self.backButton = self:LuaObject("child_common_btn_back")

	---@type CS.PageViewController
	self.detailPageController = self:BindComponent("p_scroll", typeof(CS.PageViewController))
	self.detailPageController.onPageChanged = Delegate.GetOrCreate(self, self.OnPageChanged)

	self.buttonDetailBasicToggle = self:Button("p_btn_01", Delegate.GetOrCreate(self, self.OnDetailBasicToggleButtonClick))
	self.buttonDetailBasicSelected = self:GameObject("p_btn_select_01")
	self.buttonDetailWorldToggle = self:Button("p_btn_02", Delegate.GetOrCreate(self, self.OnDetailWorldToggleButtonClick))
	self.buttonDetailWorldSelected = self:GameObject("p_btn_select_02")

	self.textDetailSETitle = self:Text("p_text_title_basice", "pet_attr_se")
	self.tabGeneralLevelNode = self:GameObject("p_addition_lv")
	self.tabGeneralLevelText = self:Text("p_text_level", "pet_param_label_lv")
	self.tabGeneralLevelOldValue = self:Text("p_text_num")
	self.tabGeneralLevelNewValue = self:Text("p_text_num_add")
	self.tabGeneralAttackNode = self:GameObject("p_addition_1")
	self.tabGeneralAttackIcon = self:Image("p_icon_1")
	self.tabGeneralAttackText = self:Text("p_text_lv_1")
	self.tabGeneralAttackOldValue = self:Text("p_text_num_1")
	self.tabGeneralAttackNewValue = self:Text("p_text_num_add_1")
	self.tabGeneralHPNode = self:GameObject("p_addition_2")
	self.tabGeneralHPIcon = self:Image("p_icon_2")
	self.tabGeneralHPText = self:Text("p_text_lv_2")
	self.tabGeneralHPOldValue = self:Text("p_text_num_2")
	self.tabGeneralHPNewValue = self:Text("p_text_num_add_2")
	self.tabGeneralDefenseNode = self:GameObject("p_addition_3")
	self.tabGeneralDefenseIcon = self:Image("p_icon_3")
	self.tabGeneralDefenseText = self:Text("p_text_lv_3")
	self.tabGeneralDefenseOldValue = self:Text("p_text_num_3")
	self.tabGeneralDefenseNewValue = self:Text("p_text_num_add_3")
	self.tabGeneralSeSpeedNode = self:GameObject("p_addition_4")
	self.tabGeneralSeSpeedIcon = self:Image("p_icon_4")
	self.tabGeneralSeSpeedText = self:Text("p_text_lv_4")
	self.tabGeneralSeSpeedOldValue = self:Text("p_text_num_4")
	self.tabGeneralSeSpeedNewValue = self:Text("p_text_num_add_4")

	self.textDetailWorldTitle = self:Text("p_text_title_map", "pet_attr_slg")
	self.tabSlgText = self:Text("p_text_slg")
	self.tabSlgOldValue = self:Text("p_text_slg_num")
	self.tabSlgNewValue = self:Text("p_text_slg_num_add")

	self.tableExpItem = self:TableViewPro("p_table_need_item")

	self.textInst = self:Text("p_text_change")
	self.textLv = self:Text("p_text_lv", "pet_param5")
	self.expCurrentSlider = self:Slider("p_progress_upgrade")
	self.expAddImage = self:Image("p_progress_lv_add")
	self.levelScrollController = self:BindComponent("p_scroll_lv", typeof(CS.PageViewController))
	self.levelScrollController.onPageChanged = Delegate.GetOrCreate(self, self.OnLevelScrollChange)
	self.levelScrollController.onPageChanging = Delegate.GetOrCreate(self, self.OnLevelScrollChange)
	self.levelScrollContent = self:GameObject("p_scroll_lv_content")
	self.levelScrollItemTemplate = self:GameObject("p_item_lv")
	self.textExpCurrent = self:Text("p_text_exp", "pet_param0")
	self.textExpCurrentValue = self:Text("p_text_exp_number")
	self.textExpAddValue = self:Text("p_text_exp_number_add")
	self.textTarget = self:Text("p_text_target", "pet_param_label_target")

	---@type BistateButton
	self.buttonUpgrade = self:LuaObject("child_comp_btn_b")

	-- 模型旋转
	self:DragEvent("p_btn_empty", nil, Delegate.GetOrCreate(self, self.OnModelDrag))
end

function UIPetUpgradeMediator:PetInfoChanged()
	self:UpdateData()
	self:InitUI()
	self:RefreshUI()
end

function UIPetUpgradeMediator:OnShow(param)
	self._param = param
	if (self._param and self._param.closeCallback) then
		self._closeCallback = param.closeCallback
	end
    self:InitData()
	self:RefreshData(param)
    self:InitUI()
    self:RefreshUI()
end

function UIPetUpgradeMediator:OnHide(param)
end

function UIPetUpgradeMediator:OnOpened(param)
end

function UIPetUpgradeMediator:OnClose(param)
	self.levelScrollController.onPageChanging = nil
	self.levelScrollController.onPageChanged = nil
	self.detailPageController.onPageChanged = nil

	local expItemCfgList = ModuleRefer.PetModule:GetPetExpItemCfgList()
	for _, item in pairs(expItemCfgList) do
		ModuleRefer.InventoryModule:RemoveCountChangeListener(item:ItemCfg(), Delegate.GetOrCreate(self, self.PetInfoChanged))
	end

	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPet.PetInfos.MsgPath, Delegate.GetOrCreate(self, self.PetInfoChanged))
	if (self._closeCallback) then
		self._closeCallback()
	end
end

function UIPetUpgradeMediator:UpdateData()
	-- 构建经验物品表并计算最大可能等级
	self._expItems = {}
	local expItemCfgList = ModuleRefer.PetModule:GetPetExpItemCfgList()
	local totalAddExp = 0
	for _, item in pairs(expItemCfgList) do
		local itemCfg = ConfigRefer.Item:Find(item:ItemCfg())
		local amount = ModuleRefer.InventoryModule:GetAmountByConfigId(item:ItemCfg())
		if (itemCfg) then
			table.insert(self._expItems, {
				id = item:Id(),
				itemCfg = itemCfg,
				amount = amount or 0,
				exp = item:Exp() or 0,
			})
			totalAddExp = totalAddExp + amount * item:Exp()
		end
		ModuleRefer.InventoryModule:AddCountChangeListener(item:ItemCfg(), Delegate.GetOrCreate(self, self.PetInfoChanged))
	end
	local targetLevel = ModuleRefer.PetModule:CalcTargetLevel(self._petInfo.ConfigId, self._petInfo.Exp + totalAddExp)

	-- 无经验道具时进入预览模式
	if (totalAddExp <= 0) then
		targetLevel = math.min(self._petInfo.Level + PREVIEW_LEVEL_COUNT, self._petInfo.LevelMax)
		self._previewMode = true
		self.textInst.text = I18N.Get("pet_memo3")
	else
		self.textInst.text = I18N.Get("pet_memo1")
	end
	self._targetMaxLevel = math.min(targetLevel, self._petInfo.LevelMax)

	-- 各级属性列表
	self._attrListTable = {}
	for lv = self._petInfo.Level, self._targetMaxLevel do
		self._attrListTable[lv] = ModuleRefer.AttrModule:CalcAttrGroupByTemplateId(self._petCfg:Attr(), lv)
	end

	-- 计算原始属性
	local attrList = self._attrListTable[self._petInfo.Level]
	self._dispConfeEAttack = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_SE_ATTACK)
	self.tabGeneralAttackText.text = I18N.Get(self._dispConfeEAttack:DisplayAttr())
	self._orgSeAttack = ModuleRefer.AttrModule:GetDisplayValueWithData(self._dispConfeEAttack, attrList)
	self._dispConfSeDefense = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_SE_DEFENSE)
	self.tabGeneralDefenseText.text = I18N.Get(self._dispConfSeDefense:DisplayAttr())
	self._orgSeDefense = ModuleRefer.AttrModule:GetDisplayValueWithData(self._dispConfSeDefense, attrList)
	self._dispConfSeHp = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_SE_HP)
	self.tabGeneralHPText.text = I18N.Get(self._dispConfSeHp:DisplayAttr())
	self._orgSeHp = ModuleRefer.AttrModule:GetDisplayValueWithData(self._dispConfSeHp, attrList)
	self._dispConfSeSpeed = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_SE_MOVE_SPEED)
	self.tabGeneralSeSpeedText.text = I18N.Get(self._dispConfSeSpeed:DisplayAttr())
	self._orgSeSpeed = ModuleRefer.AttrModule:GetDisplayValueWithData(self._dispConfSeSpeed, attrList)
	self._dispConfSlgDamage = ConfigRefer.AttrDisplay:Find(ATTR_DISP_ID_SLG_DAMAGE)
	self.tabSlgText.text = I18N.Get(self._dispConfSlgDamage:DisplayAttr())
	self._orgSlgDamage = ModuleRefer.AttrModule:GetDisplayValueWithData(self._dispConfSlgDamage, attrList)

	-- 原始经验
	self._orgExpPct = ModuleRefer.PetModule:GetExpPercent(self._petInfo.ConfigId, self._petInfo.Level, self._petInfo.Exp)
	self.expCurrentSlider.value = self._orgExpPct
	self.textExpCurrent.text = I18N.GetWithParams("pet_param1", self._petInfo.Exp)
end

--- 刷新数据
---@param self UIPetUpgradeMediator
---@param param table
function UIPetUpgradeMediator:RefreshData(param)
	if (not param or not param.petId) then return end
	self._petId = param.petId
	if (not self._petId) then return end
	self._petInfo = ModuleRefer.PetModule:GetPetByID(self._petId)
	if (not self._petInfo) then return end
	self._petCfg = ModuleRefer.PetModule:GetPetCfg(self._petInfo.ConfigId)
	self:UpdateData()
end

--- 初始化数据
---@param self UIPetUpgradeMediator
function UIPetUpgradeMediator:InitData()
    self.backButton:FeedData({
        title = I18N.Get("pet_uplevel"),
    })

	self.buttonUpgrade:FeedData({
		onClick = Delegate.GetOrCreate(self, self.OnUpgradeButtonClick),
		disableClick = Delegate.GetOrCreate(self, self.OnUpgradeButtonDisabledClick),
	})
	self.buttonUpgrade:SetButtonText(I18N.Get(I18N_BUTTON_UPGRADE))
	self.buttonUpgrade:SetEnabled(false)
end

--- 初始化UI
---@param self UIPetUpgradeMediator
function UIPetUpgradeMediator:InitUI()
	self.tabGeneralAttackOldValue.text = tostring(self._orgSeAttack)
	self.tabGeneralDefenseOldValue.text = tostring(self._orgSeDefense)
	self.tabGeneralHPOldValue.text = tostring(self._orgSeHp)
	self.tabGeneralSeSpeedOldValue.text = tostring(self._orgSeSpeed)
	self.tabSlgOldValue.text = tostring(self._orgSlgDamage)

	-- 创建目标等级条目
	for index = self.levelScrollContent.transform.childCount - 1, 0, -1 do
		local trans = self.levelScrollContent.transform:GetChild(index)
		CS.UnityEngine.Object.Destroy(trans.gameObject)
	end
	local count = 0
	for lv = self._targetMaxLevel, self._petInfo.Level, -1 do
		---@type CS.UnityEngine.GameObject
		local lvItem = CS.UnityEngine.GameObject.Instantiate(self.levelScrollItemTemplate)
		lvItem.transform:SetParent(self.levelScrollContent.transform)
		local lvItemText = lvItem:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text))
		if (lvItemText) then
			lvItemText.text = CS.System.String.Format("{0:00}", lv)
		end
		lvItem.transform.localScale = CS.UnityEngine.Vector3.one
		lvItem:SetActive(true)
		count = count + 1
	end
	self.levelScrollController.pageCount = count
	self.levelScrollController:ScrollToPage(count - 1, false)
	self._targetLevel = self._petInfo.Level
	self:RefreshAttr()
end

--- 刷新UI
---@param self UIPetUpgradeMediator
function UIPetUpgradeMediator:RefreshUI()
	-- 经验物品列表
	self._expItemDataMap = {}
	self.tableExpItem:Clear()
	for _, item in pairs(self._expItems) do
		local data = {
			configCell = item.itemCfg,
			count = item.amount,
			useNoneMask = item.amount <= 0,
			customData = item,
			onClick = Delegate.GetOrCreate(self, self.OnExpItemClick),
			onDelBtnClick = Delegate.GetOrCreate(self, self.OnExpItemRemoveClick),
			addCount = 0,
			showDelBtn = false,
			showSelect = false,
		}
		self.tableExpItem:AppendData(data)
		self._expItemDataMap[item.id] = data
	end
end

--function UIPetUpgradeMediator:OnLeftScrollPageChanged(old, new)
--end

--- 刷新属性
---@param self UIPetUpgradeMediator
function UIPetUpgradeMediator:RefreshAttr()
	local attrList = self._attrListTable[self._targetLevel]
	local attack = ModuleRefer.AttrModule:GetDisplayValueWithData(self._dispConfeEAttack, attrList)
	local defense = ModuleRefer.AttrModule:GetDisplayValueWithData(self._dispConfSeDefense, attrList)
	local hp = ModuleRefer.AttrModule:GetDisplayValueWithData(self._dispConfSeHp, attrList)
	local seSpeed = ModuleRefer.AttrModule:GetDisplayValueWithData(self._dispConfSeSpeed, attrList)
	local slgDamage = ModuleRefer.AttrModule:GetDisplayValueWithData(self._dispConfSlgDamage, attrList)

	self.tabGeneralLevelOldValue.text = I18N.GetWithParams("pet_param4", self._petInfo.Level)

	if (self._targetLevel == self._petInfo.Level) then
		self.expCurrentSlider.value = self._orgExpPct
		self.tabGeneralAttackNewValue.gameObject:SetActive(false)
		self.tabGeneralDefenseNewValue.gameObject:SetActive(false)
		self.tabGeneralHPNewValue.gameObject:SetActive(false)
		self.tabGeneralSeSpeedNewValue.gameObject:SetActive(false)
		self.tabGeneralLevelNewValue.gameObject:SetActive(false)

		self.tabSlgNewValue.gameObject:SetActive(false)
	else
		self.expCurrentSlider.value = 0
		self.tabGeneralAttackNewValue.gameObject:SetActive(true)
		self.tabGeneralDefenseNewValue.gameObject:SetActive(true)
		self.tabGeneralHPNewValue.gameObject:SetActive(true)
		self.tabGeneralSeSpeedNewValue.gameObject:SetActive(true)
		self.tabGeneralAttackNewValue.text = tostring(attack)
		self.tabGeneralDefenseNewValue.text = tostring(defense)
		self.tabGeneralHPNewValue.text = tostring(hp)
		self.tabGeneralSeSpeedNewValue.text = tostring(seSpeed)
		self.tabGeneralLevelNewValue.gameObject:SetActive(true)
		self.tabGeneralLevelNewValue.text = I18N.GetWithParams("pet_param4", self._targetLevel)

		self.tabSlgNewValue.gameObject:SetActive(true)
		self.tabSlgNewValue.text = tostring(slgDamage)
	end

	-- 隐藏没有值的项
	self.tabGeneralAttackNode:SetActive(self._orgSeAttack ~= 0 or attack ~= 0)
	self.tabGeneralDefenseNode:SetActive(self._orgSeDefense ~= 0 or defense ~= 0)
	self.tabGeneralHPNode:SetActive(self._orgSeHp ~= 0 or hp ~= 0)
	self.tabGeneralSeSpeedNode:SetActive(self._orgSeSpeed ~= 0 or seSpeed ~= 0)
end

function UIPetUpgradeMediator:OnLevelScrollChange(old, new)
	self._targetLevel = self._petInfo.Level + self.levelScrollController.pageCount - new - 1
	self:RefreshExpItemsByTargetLevel()
end

--- 根据目标等级刷新经验物品
---@param self UIPetUpgradeMediator
function UIPetUpgradeMediator:RefreshExpItemsByTargetLevel()
	-- 计算需要的经验值
	local needExp = ModuleRefer.PetModule:GetLevelExp(self._petInfo.ConfigId, self._targetLevel)

	if (not self._previewMode) then
		-- 设置经验道具
		local realAddExp = 0
		local remainExp = needExp - self._petInfo.Exp
		for i = #self._expItems, 1, -1 do
			local expItem = self._expItems[i]
			if (expItem) then
				local needCount = 0
				if (remainExp > 0) then
					needCount = math.min(expItem.amount, math.ceil(remainExp / expItem.exp))
					local exp = needCount * expItem.exp
					realAddExp = realAddExp + exp
					remainExp = remainExp - exp
				end
				local data = self._expItemDataMap[expItem.id]
				if (data) then
					data.addCount = needCount
					data.showSelect = data.addCount > 0
					data.showDelBtn = data.addCount > 0
				end
			end
		end
		self.tableExpItem:RefreshAllShownItem()

		local targetLevel, _, pct = ModuleRefer.PetModule:CalcTargetLevel(self._petInfo.ConfigId, self._petInfo.Exp + realAddExp)
		self.textExpAddValue.color = COLOR_ADD_EXP
		self.textExpAddValue.text = I18N.GetWithParams("pet_param3", realAddExp)
		self.expAddImage.fillAmount = pct
		self:RefreshButtonState(targetLevel, realAddExp)
	else
		self.expAddImage.fillAmount = 0
		self.textExpAddValue.color = COLOR_NEED_EXP
		local exp = needExp - self._petInfo.Exp
		if (exp > 0) then
			self.textExpAddValue.text = I18N.GetWithParams("pet_param2", needExp - self._petInfo.Exp)
		else
			self.textExpAddValue.text = ""
		end
	end
	self:RefreshAttr()
end

--- 根据经验物品刷新目标等级
---@param self UIPetUpgradeMediator
function UIPetUpgradeMediator:SetTargetLevelByExpItems()
	-- 收集当前增加经验
	local totalAddExp = 0
	for _, item in pairs(self._expItems) do
		local expItemData = self._expItemDataMap[item.id]
		if (expItemData) then
			totalAddExp = totalAddExp + expItemData.addCount * item.exp
		end
	end
	local targetLevel, _, pct = ModuleRefer.PetModule:CalcTargetLevel(self._petInfo.ConfigId, self._petInfo.Exp + totalAddExp)
	if (targetLevel ~= self._targetLevel) then
		self._targetLevel = targetLevel
		self.levelScrollController:ScrollToPage(self._petInfo.Level + self.levelScrollController.pageCount - targetLevel - 1)
	end
	self.textExpAddValue.text = I18N.GetWithParams("pet_param3", totalAddExp)
	self.expAddImage.fillAmount = pct
	self:RefreshAttr()
	self:RefreshButtonState(targetLevel, totalAddExp)
end

function UIPetUpgradeMediator:OnUpgradeButtonClick(args)
	self.buttonUpgrade:SetEnabled(false)

	local msg = require("PetAddExpParameter").new()
	msg.args.PetCompId = self._petInfo.ID
	for _, item in ipairs(self._expItems) do
		local itemId = item.id
		local data = self._expItemDataMap[itemId]
		if (data and data.addCount and data.addCount > 0) then
			msg.args.ExpItemCfgIds:Add(itemId)
			msg.args.ExpItemNums:Add(data.addCount)
		end
	end
	msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
		if (suc) then
			g_Game.EventManager:TriggerEvent(EventConst.PET_LEVEL_UP)
		end
	end)
end

function UIPetUpgradeMediator:OnUpgradeButtonDisabledClick(args)
	if (self._previewMode) then return end
	ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_memo6"))
end

function UIPetUpgradeMediator:OnExpItemClick(itemCfg, expItem)
	local data = self._expItemDataMap[expItem.id]
	if (not data) then return end
	if (data.addCount < expItem.amount) then
		data.addCount = data.addCount + 1
		data.showSelect = data.addCount > 0
		data.showDelBtn = data.addCount > 0
	end
	self.tableExpItem:RefreshAllShownItem()
	self:SetTargetLevelByExpItems()
end

function UIPetUpgradeMediator:OnExpItemRemoveClick(itemCfg, expItem)
	local data = self._expItemDataMap[expItem.id]
	if (not data) then return end
	if (data.addCount > 0) then
		data.addCount = data.addCount - 1
		data.showSelect = data.addCount > 0
		data.showDelBtn = data.addCount > 0
	end
	self.tableExpItem:RefreshAllShownItem()
	self:SetTargetLevelByExpItems()
end

function UIPetUpgradeMediator:RefreshButtonState(targetLevel, addExp)
	if (self._petInfo.Level == targetLevel) then
		self.buttonUpgrade:SetEnabled(addExp > 0)
		if (addExp > 0) then
			self.buttonUpgrade:SetButtonText(I18N.Get(I18N_BUTTON_ADD_EXP))
		else
			self.buttonUpgrade:SetButtonText(I18N.Get(I18N_BUTTON_UPGRADE))
		end
	else
		self.buttonUpgrade:SetEnabled(true)
		self.buttonUpgrade:SetButtonText(I18N.Get(I18N_BUTTON_UPGRADE))
	end
end

function UIPetUpgradeMediator:OnModelDrag(go, eventData)
    if (self._param and self._param.ui3dModel) then
        self._param.ui3dModel:RotateModelY(eventData.delta.x * -0.5)
    end
end

---@param self UIPetUpgradeMediator
---@param old number
---@param new number
function UIPetUpgradeMediator:OnPageChanged(old, new)
	self:SwitchToDetailPage(new)
end

--- 切换到指定属性页
---@param self UIPetMediator
---@param page number
---@param scroll boolean
function UIPetUpgradeMediator:SwitchToDetailPage(page, scroll)
	if (page == PAGE_DETAIL_BASIC) then
		self.buttonDetailBasicToggle.gameObject:SetActive(false)
		self.buttonDetailBasicSelected:SetActive(true)

		self.buttonDetailWorldToggle.gameObject:SetActive(true)
		self.buttonDetailWorldSelected:SetActive(false)
	elseif (page == PAGE_DETAIL_WORLD) then
		self.buttonDetailBasicToggle.gameObject:SetActive(true)
		self.buttonDetailBasicSelected:SetActive(false)

		self.buttonDetailWorldToggle.gameObject:SetActive(false)
		self.buttonDetailWorldSelected:SetActive(true)
	end
	if (scroll) then
		self.detailPageController:ScrollToPage(page)
	end
end

function UIPetUpgradeMediator:OnDetailBasicToggleButtonClick(args)
	self:SwitchToDetailPage(PAGE_DETAIL_BASIC, true)
end

function UIPetUpgradeMediator:OnDetailWorldToggleButtonClick(args)
	self:SwitchToDetailPage(PAGE_DETAIL_WORLD, true)
end

return UIPetUpgradeMediator
