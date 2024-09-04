local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local TimeFormatter = require("TimeFormatter")
local CityWorkFormula = require("CityWorkFormula")
local ConfigTimeUtility = require("ConfigTimeUtility")
local I18N = require("I18N")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local CityWorkUICostItemData = require("CityWorkUICostItemData")
local CityWorkI18N = require("CityWorkI18N")

---@class CityWorkProcessUIRecipeDetailsPanel:BaseUIComponent
---@field uiMediator CityWorkProcessUIMediator
local CityWorkProcessUIRecipeDetailsPanel = class('CityWorkProcessUIRecipeDetailsPanel', BaseUIComponent)
local FailureCode = {
    Success = 0,
    QueueFull = 1,
    InOtherWork = 2,
    SameWorkTypeFull = 3,
    TimesZero = 4,
    NotMeetCondition = 5,
    LackRes = 6,
    CountOverflow = 7,
    Polluted = 8,
}
local FailureReason = {
    [FailureCode.QueueFull] = "sys_city_37",
    [FailureCode.SameWorkTypeFull] = "sys_city_68",
    [FailureCode.NotMeetCondition] = "sys_city_36",
    [FailureCode.LackRes] = "sys_city_38",
    [FailureCode.CountOverflow] = CityWorkI18N.FAILURE_REASON_COUNT_OVERFLOW,
    [FailureCode.Polluted] = CityWorkI18N.FAILURE_REASON_POLLUTED,
}

function CityWorkProcessUIRecipeDetailsPanel:ctor()
    ---@type CityWorkUICostItemData[]
    self.inputDataList = {}
    ---@type CS.DragonReborn.UI.LuaBaseComponent[] @CityWorkProcessUIRecipeCostItem
    self.inputItemList = {}
end

function CityWorkProcessUIRecipeDetailsPanel:OnCreate()
    self._p_title_need = self:GameObject("p_title_need")
    self._p_text_title = self:Text("p_text_title", "sys_city_43")

    self._p_grid_need = self:Transform("p_grid_need")
    ---@type CityWorkProcessUIRecipeCostItem
    self._p_item_need = self:LuaBaseComponent("p_item_need")
    self._pool = LuaReusedComponentPool.new(self._p_item_need, self._p_grid_need)

    self._p_group_num = self:GameObject("p_group_num")
    ---@type CommonNumberSlider
    self._p_set_bar = self:LuaObject("p_set_bar")
    self._p_text_max = self:Text("p_text_max", "sys_city_22")
    self._p_btn_max = self:Button("p_btn_max", Delegate.GetOrCreate(self, self.OnClickSliderMax))

    self._p_text_select = self:Text("p_text_select", "sys_city_33")
    self._p_input_grade = self:Text("p_input_grade")
    self._p_input_box_click = self:InputField("p_input_box_click", nil, Delegate.GetOrCreate(self, self.OnEndEditInput), Delegate.GetOrCreate(self, self.OnSubmitInput))

    self._p_condition_vertical = self:Transform("p_condition_vertical")
    self._p_text_condition = self:Text("p_text_condition")
    ---@type CityWorkUIConditionItem
    self._p_conditions = self:LuaBaseComponent("p_conditions")
    self._pool_condition = LuaReusedComponentPool.new(self._p_conditions, self._p_condition_vertical)

    self._bottom = self:GameObject("bottom")
    self._p_group_manual = self:GameObject("p_group_manual")
    self._p_time_need = self:GameObject("p_time_need")
    self._p_text_time = self:Text("p_text_time", "sys_city_34")
    ---@type CommonTimer
    self._child_time_editor_pre = self:LuaObject("child_time_editor_pre")
    -- self._p_text_hint = self:Text("p_text_hint")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")

    self._p_group_auto = self:GameObject("p_group_auto")
    --- 自动勾选根节点
    self._p_toggle = self:GameObject("p_toggle")
    self._p_btn_pading = self:Button("p_btn_pading", Delegate.GetOrCreate(self, self.OnClickAuto))
    self._p_status_n = self:GameObject("p_status_n")
    self._p_status_select = self:GameObject("p_status_select")
    self._p_text_auto = self:Text("p_text_auto", "sys_city_48")

    --- 自动模式时显示制造耗时
    self._p_group_process_time = self:GameObject("p_group_process_time")
    self._p_text_time_desc = self:Text("p_text_time_desc", "sys_city_46")
    self._p_text_time_process = self:Text("p_text_time_process")
end

function CityWorkProcessUIRecipeDetailsPanel:OnClose()
    self:ReleaseAllItemCountChangeListener()
end

function CityWorkProcessUIRecipeDetailsPanel:OnHide()
    self:ReleaseAllItemCountChangeListener()
end

---@param data CityProcessConfigCell
function CityWorkProcessUIRecipeDetailsPanel:OnFeedData(data)
    local lastRecipeId = self.recipe == nil and -1 or self.recipe:Id()
    self.recipe = data
    self.times = lastRecipeId == self.recipe:Id() and self.times or nil
    self:Refresh()
end

function CityWorkProcessUIRecipeDetailsPanel:Refresh()
    self:GetDataFromMediator()
    
    self._pool:HideAll()

    if self.city.cityWorkManager:IsProcessEffective(self.recipe) then
        self:RefreshEffectiveRecipe()
    else
        self:RefreshIneffectiveRecipe()
    end
end

function CityWorkProcessUIRecipeDetailsPanel:RefreshEffectiveRecipe()
    self._p_group_num:SetActive(not self.isMakingFurniture and not self.showAuto and not self:HasPausedProcess())
    self._p_condition_vertical:SetVisible(false)
    self._bottom:SetActive(true)

    self.times = self.times or 1
    self.reachVersionLimit = false

    if self.isMakingFurniture then
        local lvCfgId = self.uiMediator:GetSelectRecipeOutputFurnitureLvCfgId(self.recipe)
        self.canProcessCount, self.reachVersionLimit = self.uiMediator.city.furnitureManager:GetFurnitureCanProcessCount(lvCfgId)
        self.realMaxTimes = self.canProcessCount
        self.times = math.min(self.times, self.realMaxTimes)
    else
        local maxCount = CityWorkFormula.GetQueueCapacity(self.workCfg, nil, self.furnitureId, self.citizenId)
        self.maxTimes = maxCount
        self.realMaxTimes = maxCount
        self._p_input_grade.text = ("/%d"):format(self.maxTimes)
    end

    if self.isMakingFurniture and self.realMaxTimes == 0 and not self.reachVersionLimit then
        local count = 0
        self._p_text_condition.text = I18N.Get(CityWorkI18N.UIHint_CityWorkProcess_CountConditionTitle)
        self._pool_condition:HideAll()
        for i = 1, self.recipe:OutputMaxCountTraceConditionLength() do
            local taskId = self.recipe:OutputMaxCountTraceCondition(i)
            local status = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
            if status ~= wds.TaskState.TaskStateFinished and status ~= wds.TaskState.TaskStateCanFinish then 
                local taskCfg = ConfigRefer.Task:Find(taskId)
                if taskCfg then
                    local item = self._pool_condition:GetItem()
                    item:FeedData({cfg = taskCfg, furniture = self.cellTile:GetCell()})
                    count = count + 1
                end
            end
        end
        self._p_condition_vertical:SetVisible(count > 0)
    else
        self._p_condition_vertical:SetVisible(false)
    end

    self:ReleaseAllItemCountChangeListener()

    local showCost = (not self.isMakingFurniture) or (self.realMaxTimes > 0)
    self._p_title_need:SetActive(showCost)
    self._p_grid_need:SetVisible(showCost)
    if showCost then
        self.input = CityWorkFormula.CalculateInput(self.workCfg, ConfigRefer.ItemGroup:Find(self.recipe:Cost()), nil, self.furnitureId, self.citizenId)
        self.inputKind = #self.input
        for i = 1, self.inputKind do
            local info = self.input[i]
            local item = self._pool:GetItem().Lua
            self.inputItemList[i] = item
            if self.inputDataList[i] then
                self.inputDataList[i].id = info.id
                self.inputDataList[i].onceNeed = info.count
            else
                self.inputDataList[i] = CityWorkUICostItemData.new(info.id, info.count, self.times)
            end
            self.inputDataList[i]:AddCountListener(Delegate.GetOrCreate(self, self.OnItemCountChanged))
            self.realMaxTimes = math.min(self.realMaxTimes, self.inputDataList[i]:GetMaxTimes())
            item:FeedData(self.inputDataList[i])
        end
        self._p_grid_need:SetVisible(self.inputKind > 0)
        self._p_title_need:SetActive(self.inputKind > 0)
    end

    if not self.isMakingFurniture and not self.showAuto then
        ---@type CommonNumberSliderData
        self.sliderData = self.sliderData or {}
        self.sliderData.minNum = self.realMaxTimes > 0 and 1 or 0 --- 真的至少能造一个的时候最少选1
        self.sliderData.maxNum = self.maxTimes
        self.sliderData.curNum = self.realMaxTimes > 0 and self.times or 0 --- 真的至少能造一个的时候就默认选1，否则选0
        self.sliderData.ignoreNum = self.sliderData.minNum
        self.sliderData.callBack = Delegate.GetOrCreate(self, self.OnSliderChange)
        self._p_set_bar:FeedData(self.sliderData)
        self._p_input_box_click.text = tostring(self.sliderData.curNum)
    end

    self.condition = self:IsRecipeConditionMeed()
    self:UpdateTimer()
    self:UpdateButtonState()
end

function CityWorkProcessUIRecipeDetailsPanel:OnClickSliderMax()
    self._p_set_bar:ChangeCurNum(self.realMaxTimes)
    self:OnSliderChange(self.realMaxTimes)
end

function CityWorkProcessUIRecipeDetailsPanel:ReleaseAllItemCountChangeListener()
    for i, v in ipairs(self.inputDataList) do
        v:ReleaseCountListener()
    end
end

function CityWorkProcessUIRecipeDetailsPanel:OnItemCountChanged()
    for i = 1, self.inputKind do
        self.inputItemList[i]:FeedData(self.inputDataList[i])
    end

    self.reachVersionLimit = false

    if self.isMakingFurniture then
        local lvCfgId = self.uiMediator:GetSelectRecipeOutputFurnitureLvCfgId(self.recipe)
        self.canProcessCount, self.reachVersionLimit = self.uiMediator.city.furnitureManager:GetFurnitureCanProcessCount(lvCfgId)
        self.realMaxTimes = self.canProcessCount
    else
        local maxCount = CityWorkFormula.GetQueueCapacity(self.workCfg, nil, self.furnitureId, self.citizenId)
        self.realMaxTimes = maxCount
    end

    for i = 1, self.inputKind do
        self.realMaxTimes = math.min(self.realMaxTimes, self.inputDataList[i]:GetMaxTimes())
    end
    
    self:UpdateButtonState()
end

function CityWorkProcessUIRecipeDetailsPanel:RefreshIneffectiveRecipe()
    self._p_title_need:SetActive(false)
    self._p_grid_need:SetVisible(false)
    self._p_group_num:SetActive(false)
    self._p_condition_vertical:SetVisible(true)
    self._p_group_process_time:SetActive(false)
    self._p_text_condition.text = I18N.Get(CityWorkI18N.UIHint_CityWorkProcess_ConditionTitle)
    self._bottom:SetActive(true)
    self._child_comp_btn_b:SetVisible(false)
    -- self._p_text_hint:SetVisible(true)
    -- self._p_text_hint.text = I18N.Get(CityWorkI18N.UIHint_CityWorkProcess_NotUnlock)
    self._p_toggle:SetActive(false)
    self._child_time_editor_pre:SetVisible(false)

    self._pool_condition:HideAll()
    local furniture = self.cellTile:GetCell()
    for i = 1, self.recipe:EffectiveConditionLength() do
        local taskId = self.recipe:EffectiveCondition(i)
        local taskCfg = ConfigRefer.Task:Find(taskId)
        if taskCfg then
            local item = self._pool_condition:GetItem()
            item:FeedData({cfg = taskCfg, furniture = furniture})
        end
    end
end

function CityWorkProcessUIRecipeDetailsPanel:GetDataFromMediator()
    if self.uiMediator == nil then
        self.uiMediator = self:GetParentBaseUIMediator()
    end
    self.cellTile = self.uiMediator.cellTile
    self.workCfg = self.uiMediator.workCfg
    self.furnitureId = self.uiMediator.furnitureId
    self.citizenId = self.uiMediator.citizenId
    self.city = self.uiMediator.city
    self.isMakingFurniture = self.uiMediator.isMakingFurniture
    self.isAuto = self.uiMediator.isAuto
    self.showAuto = self.uiMediator.showAuto
end

function CityWorkProcessUIRecipeDetailsPanel:UpdateTimer()
    local showTimer = self.realMaxTimes > 0 and not self.isAuto
    self._child_time_editor_pre:SetVisible(showTimer)
    if showTimer then
        ---@type CommonTimerData
        self.timerData = self.timerData or {}
        self.timerData.needTimer = false
        local singleTimeCost = math.ceil(CityWorkFormula.CalculateFinalTimeCost(self.workCfg, ConfigTimeUtility.NsToSeconds(self.recipe:Time()), self.recipe:Difficulty(), nil, self.furnitureId, self.citizenId))
        self.timerData.fixTime = singleTimeCost * self.times
        self._child_time_editor_pre:FeedData(self.timerData)
    end

    self._p_group_process_time:SetActive(self.showAuto)
    if self.showAuto then
        local time = CityWorkFormula.CalculateFinalTimeCost(self.workCfg, ConfigTimeUtility.NsToSeconds(self.recipe:Time()), self.recipe:Difficulty(), nil, self.furnitureId, self.citizenId)
        self._p_text_time_process.text = TimeFormatter.SimpleFormatTime(time)
    end
end

function CityWorkProcessUIRecipeDetailsPanel:CanStart(isAuto)
    if self.cellTile:IsPolluted() then
        return FailureCode.Polluted
    end

    local maxQueue = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    local curQueue = self.uiMediator:GetActiveQueueCount()

    if curQueue >= maxQueue  then
        return FailureCode.QueueFull
    end

    if self.isMakingFurniture then
        local output = ConfigRefer.ItemGroup:Find(self.recipe:Output())
        local firstItemInfo = output:ItemGroupInfoList(1)
        local itemId = firstItemInfo:Items()
        local lvCfgId = ModuleRefer.CityConstructionModule:GetFurnitureRelative(itemId)
        if lvCfgId > 0 then
            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
            local limit = self.city.furnitureManager:GetFurnitureGlobalLimitCount(lvCfgId)
            local current = self.city.furnitureManager:GetFurnitureCountByTypeCfgId(lvCfg:Type())
            if current >= limit then
                return FailureCode.CountOverflow
            end
        end
    end

    local sameTypeWorkCount = self.city.cityWorkManager:GetWorkingCountByType(self.workCfg:Type())
    local maxSameTypeWorkCount = CityWorkFormula.GetTypeMaxQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if sameTypeWorkCount >= maxSameTypeWorkCount then
        return FailureCode.SameWorkTypeFull
    end

    if isAuto == nil then
        isAuto = self.isAuto
    end

    if self.times <= 0 and not isAuto then
        return FailureCode.TimesZero
    end

    if not self.condition then
        return FailureCode.NotMeetCondition
    end

    if self.times > self.realMaxTimes and not isAuto then
        return FailureCode.LackRes
    end

    return FailureCode.Success
end

function CityWorkProcessUIRecipeDetailsPanel:UpdateButtonState()
    if self.times == nil then return end

    if self:HasPausedProcess() then
        self:UpdateButtonPaused()
    else
        self:UpdateButtonProcessing()
    end
end

function CityWorkProcessUIRecipeDetailsPanel:HasPausedProcess()
    local furniture = self.cellTile:GetCell()
    return furniture:IsProcessPaused()
end

function CityWorkProcessUIRecipeDetailsPanel:UpdateButtonPaused()
    self._p_group_auto:SetActive(self.showAuto)
    self._p_group_manual:SetActive(not self.showAuto)

    if not self.showAuto then
        self.btnData = self.btnData or {}
        self.btnData.buttonText = I18N.Get(CityWorkI18N.UI_CityWorkProcess_Button_Continue)
        self.btnData.onClick = Delegate.GetOrCreate(self, self.OnClickContinue)
        self.btnData.disableClick = Delegate.GetOrCreate(self, self.OnClickContinueDisable)
        self._child_comp_btn_b:FeedData(self.btnData)
        self._child_comp_btn_b:SetEnabled(not self.cellTile:IsPolluted())
    end

    self._p_toggle:SetActive(true)
end

function CityWorkProcessUIRecipeDetailsPanel:UpdateButtonProcessing()
    local showButton = (not self.isMakingFurniture) or (self.canProcessCount > 0)
    self._p_group_auto:SetActive(self.showAuto)
    self._p_group_manual:SetActive(not self.showAuto)
    if self.showAuto then
        self._p_toggle:SetActive(showButton)
        if showButton then
            self._p_status_n:SetActive(not self.isAuto)
            self._p_status_select:SetActive(self.isAuto)
        end
    else
        self._child_comp_btn_b:SetVisible(showButton)
        if showButton then
            ---@type BistateButtonParameter
            self.btnData = self.btnData or {}
            self.btnData.buttonText = I18N.Get("sys_city_35")
            self.btnData.onClick = Delegate.GetOrCreate(self, self.OnClickStart)
            self.btnData.disableClick = Delegate.GetOrCreate(self, self.OnClickDisable)
            self._child_comp_btn_b:FeedData(self.btnData)

            local failCode = self:CanStart()
            self._child_comp_btn_b:SetEnabled(failCode == FailureCode.Success or failCode == FailureCode.LackRes)
        end
    end
end

function CityWorkProcessUIRecipeDetailsPanel:OnSliderChange(value)
    self.times = value
    self.sliderData.curNum = value
    for i = 1, self.inputKind do
        self.inputDataList[i].times = value
        self.inputItemList[i]:FeedData(self.inputDataList[i])
    end
    self._p_input_box_click.text = tostring(value)
    self:UpdateTimer()
    self:UpdateButtonState()
end

function CityWorkProcessUIRecipeDetailsPanel:OnEndEditInput(valueText)
    g_Logger.TraceChannel("CityWorkProcessUIRecipeDetailsPanel", "OnEndEditInput")
end

function CityWorkProcessUIRecipeDetailsPanel:OnSubmitInput(valueText)
    g_Logger.TraceChannel("CityWorkProcessUIRecipeDetailsPanel", "OnSubmitInput")
    local value = math.clamp(checknumber(valueText), 0, self.maxTimes)
    self._p_set_bar:ChangeCurNum(value)
    self:OnSliderChange(value)
end

function CityWorkProcessUIRecipeDetailsPanel:GetNextEmptyIndex()
    local castleFurniture = self.cellTile:GetCastleFurniture()
    return castleFurniture.ProcessInfo:Count()
end

function CityWorkProcessUIRecipeDetailsPanel:OnClickStart(clickData, lockable, isAuto)
    if self:HasPausedProcess() then
        self:OnClickContinue()
        return
    end

    if isAuto == nil then
        isAuto = self.isAuto
    end

    local errCode = self:CanStart(isAuto)
    if errCode == FailureCode.LackRes then
        self:ShowLackResGetMore()
    elseif errCode == FailureCode.Success then
        local idx = self:GetNextEmptyIndex()
        self.uiMediator.city.cityWorkManager:StartProcessWork(self.furnitureId, self.recipe:Id(), idx, self.times, self.workCfg:Id(), self.citizenId, isAuto, lockable, Delegate.GetOrCreate(self, self.TryStartGuide))
    end
end

function CityWorkProcessUIRecipeDetailsPanel:OnClickDisable()
    local errCode = self:CanStart()
    if FailureReason[errCode] then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[errCode]))
        return
    end
end

function CityWorkProcessUIRecipeDetailsPanel:TryStartGuide()
    local guideCfgId = self.workCfg:GuideOnStart()
    if guideCfgId > 0 then
        ModuleRefer.GuideModule:CallGuide(guideCfgId)
    end
end

function CityWorkProcessUIRecipeDetailsPanel:ShowLackResGetMore()
    local getmoreList = {}
    for i, v in ipairs(self.inputDataList) do
        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
        local need = v.onceNeed * self.times
        if need > own then
            table.insert(getmoreList, {id = v.id, num = need - own})
        end
    end
    ModuleRefer.InventoryModule:OpenExchangePanel(getmoreList)
end

function CityWorkProcessUIRecipeDetailsPanel:IsRecipeConditionMeed()
    if not self.recipe then return false end

    return self.uiMediator.city.cityWorkManager:IsProcessEffective(self.recipe)
end

function CityWorkProcessUIRecipeDetailsPanel:OnClickContinue()
    self.city.cityWorkManager:StartWorkImp(self.furnitureId, self.workCfg:Id(), self.citizenId, 0)
end

function CityWorkProcessUIRecipeDetailsPanel:OnClickContinueDisable()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[FailureCode.Polluted]))
end

function CityWorkProcessUIRecipeDetailsPanel:OnClickAuto()
    if not self.isAuto then
        self:OnClickStart(nil, self._p_btn_pading.transform, true)
    else
        self:RequestRemoveAutoProcess()
    end
end

function CityWorkProcessUIRecipeDetailsPanel:RequestRemoveAutoProcess()
    local castleFurniture = self.cellTile:GetCastleFurniture()
    for i, v in ipairs(castleFurniture.ProcessInfo) do
        if v.Auto then
            self.uiMediator:RequestRemoveInQueue(v, self._p_btn_pading.transform)
            return
        end
    end
end

return CityWorkProcessUIRecipeDetailsPanel