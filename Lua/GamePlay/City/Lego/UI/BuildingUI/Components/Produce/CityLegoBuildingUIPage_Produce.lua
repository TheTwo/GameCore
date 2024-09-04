local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityWorkProduceUILvPreviewGroupData = require("CityWorkProduceUILvPreviewGroupData")

local I18N = require("I18N")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local CityWorkFormula = require("CityWorkFormula")
local NumberFormatter = require("NumberFormatter")
local EventConst = require("EventConst")
local CityWorkUICostItemData = require("CityWorkUICostItemData")
local ConfigTimeUtility = require("ConfigTimeUtility")
local TimeFormatter = require("TimeFormatter")
local CityWorkProduceUIUnitData = require("CityWorkProduceUIUnitData")
local CityWorkType = require("CityWorkType")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local CityWorkI18N = require("CityWorkI18N")
local UIMediatorNames = require("UIMediatorNames")

---@class CityLegoBuildingUIPage_Produce:BaseUIComponent
local CityLegoBuildingUIPage_Produce = class('CityLegoBuildingUIPage_Produce', BaseUIComponent)
local FailureCode = {
    Success = 0,
    HasAutoInQueue = 1,
    MustHaveCitizen = 2,
    TimesZero = 3,
    LackRes = 4,
    InOtherWork = 5,
    SlotFull = 6,
    QueueFull = 7,
    SameWorkTypeFull = 8,
}

local FailureReasonI18N = {
    [FailureCode.QueueFull] = "sys_city_63",
    [FailureCode.SlotFull] = "sys_city_65",
}

function CityLegoBuildingUIPage_Produce:OnCreate()
    ------------右侧面板静态数据-------------
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetails))

    ------------右侧面板全状态更新数据-------------
    self._p_text_area_num = self:Text("p_text_area_num") ---- 显示产出情况

    ------------右侧面板<已选目标(现在默认进来选第一个)>-------------
    ---@see CityWorkProduceUIRecipeItem
    self._p_table_item = self:TableViewPro("p_table_item") ---- 配方选择table

    self._p_text_item = self:Text("p_text_item")            ---- 配方名字
    self._p_text_desc = self:Text("p_text_desc")            ---- 配方描述

    self._p_text_need = self:Text("p_text_need", "sys_city_44")
    self._p_resource_grid = self:Transform("p_resource_grid")   ---- 材料消耗预览
    self._p_item = self:LuaBaseComponent("p_item")              ---- 材料消耗预览
    self._pool_cost = LuaReusedComponentPool.new(self._p_item, self._p_resource_grid)

    self._group_quantity = self:GameObject("group_quantity")
    self._p_text_select = self:Text("p_text_select", "sys_city_33")   ---- 次数选择滑条文本
    self._p_text_input_quantity = self:Text("p_text_input_quantity")    ---- 次数上限
    self._p_input_box_click = self:InputField("p_input_box_click", nil, nil, Delegate.GetOrCreate(self, self.OnSubmit))
    ---@type CommonNumberSlider
    self._p_set_num_bar = self:LuaObject("p_set_num_bar")       ---- 次数选择滑条
    self._p_text_max = self:Text("p_text_max", "sys_city_22")
    self._p_btn_max = self:Button("p_btn_max", Delegate.GetOrCreate(self, self.OnClickSliderMax))   ---- 最大可种植数设置按钮

    self._p_group_autocreate_time = self:GameObject("p_group_autocreate_time")      ---- 自动生产勾选后的耗时显示
    self._p_text_time_desc = self:Text("p_text_time_desc", "sys_city_46")
    self._p_text_time = self:Text("p_text_time")        ---- 单次培育耗时
    
    self._p_bottom_btn = self:GameObject("p_bottom_btn")        --- 按钮根节点

    self._p_group_auto = self:GameObject("p_group_auto")
    self._p_toggle = self:GameObject("p_toggle")     ---- 自动勾选根节点
    self._p_btn_pading = self:Button("p_btn_pading", Delegate.GetOrCreate(self, self.OnClickAutoBtn))       ----自动勾选
    self._p_status_n = self:GameObject("p_status_n")
    self._p_status_select = self:GameObject("p_status_select")
    self._p_text_auto = self:Text("p_text_auto", "sys_city_48")

    self._p_group_manual = self:GameObject("p_group_manual")
    ---@type CommonPricedButton
    self._child_comp_btn_b_l = self:LuaObject("child_comp_btn_b_l")     ---- 按钮组件
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")

    self._p_chart_title_level = self:Text("p_chart_title_level", "sys_city_49")
    self._p_chart_title_item = self:Text("p_chart_title_item", "sys_city_50")
    self._p_chart_title_outcome = self:Text("p_chart_title_outcome", "sys_city_51")

    self._mask_table = self:GameObject("mask_table")
    ---@see CityWorkProduceUIUnit
    self._p_table = self:TableViewPro("p_table")    ---- 队列table

    ------------等级预览需要显隐的节点------------
    self._p_scroll_content = self:GameObject("p_scroll_content")
    self._bottom = self:GameObject("bottom")
    self._p_chart = self:GameObject("p_chart")      ---- 预览种植图表
    ---@see CityWorkProduceUILvPreviewItem
    self._p_table_chart = self:TableViewPro("p_table_chart")    ---- 预览种植图表TableViewPro [childIndex:0为实际列表，1为分割线] 

    --- 属性
    self._p_buff_1 = self:GameObject("p_buff_1")
    self._p_icon_1 = self:Image("p_icon_1")
    self._p_text_1 = self:Text("p_text_1")

    self._p_buff_2 = self:GameObject("p_buff_2")
    self._p_icon_2 = self:Image("p_icon_2")
    self._p_text_2 = self:Text("p_text_2")

    self._p_buff_3 = self:GameObject("p_buff_3")
    self._p_icon_3 = self:Image("p_icon_3")
    self._p_text_3 = self:Text("p_text_3")
        
    ---@type CityFurnitureConstructionProcessCitizenBlock
    self._p_resident_root = self:LuaObject("p_resident_root")

    self._p_detail = self:GameObject("p_detail")
    self._p_detail:SetActive(false)
end

---@param param CityWorkProduceUIParameter
function CityLegoBuildingUIPage_Produce:OnFeedData(param)
    self.param = param
    self.city = param.city
    self.workCfg = param.workCfg
    self.cellTile = param.cellTile
    self.furnitureId = param.cellTile:GetCell().singleId
    self.showDetails = false

    ---@type CityWorkUICostItemData[]
    self.inputDataList = {}
    self.inputItemList = {}
    ---@type CityWorkProduceUIUnitData[]
    self._queueCache = {}

    self:InitWorkStatus()
    self:InitCitizenStatus()
    self:InitStaticInfo()
    self:UpdateWorkAttributes()
    self:UpdateRecipeTable()
    self:DefaultSelectFirstRecipe()
    self:UpdateAreaInfo()
    self:UpdateSelectRecipeDesc()

    self.showAuto = self.workCfg:IsAuto()
    if not self.showAuto then
        self:UpdateCostPreview()
    end
    self:InitCountSelection()
    self:UpdateButtonStatus()
    self:UpdateQueueTableNew()
end

function CityLegoBuildingUIPage_Produce:OnShow()
    self:AddEventListener()
end

function CityLegoBuildingUIPage_Produce:OnHide()
    self:RemoveEventListener()
    self:ReleaseAllItemCountChangeListener()
end

function CityLegoBuildingUIPage_Produce:OnClose()
    self:OnHide()
end

function CityLegoBuildingUIPage_Produce:OnClickDetails()
    self.showDetails = not self.showDetails
    self._p_scroll_content:SetActive(not self.showDetails)
    self._bottom:SetActive(not self.showDetails)
    self._p_chart:SetActive(self.showDetails)
end

function CityLegoBuildingUIPage_Produce:InitWorkStatus()
    local wds = self:GetCastleResourceGenerateInfo()
    self.isWorking = wds.GeneratePlan:Count() > 0
    self.workId, self.workData = 0, nil
    if self.isWorking then
        self.workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.ResourceGenerate]
        self.workData = self.city.cityWorkManager:GetWorkData(self.workId)
    end
end

function CityLegoBuildingUIPage_Produce:InitCitizenStatus()
    if not self:HasCitizenWorking() then
        if not self.isWorking then
            local citizenId = self:GetParentBaseUIMediator():GetBestFreeCitizenForWork(self.workCfg)
            if citizenId then
                self.citizenId = citizenId
            end
        end
    else
        self.citizenId = self.workData.CitizenId
    end

    ---@type CityFurnitureConstructionProcessCitizenBlockData
    self.citizenBlockData = self.citizenBlockData or {}
    self.citizenBlockData.citizenId = self.citizenId
    self.citizenBlockData.citizenMgr = self.city.cityCitizenManager
    self.citizenBlockData.workCfgId = self.workCfg:Id()
    self.citizenBlockData.onSelectedChanged = Delegate.GetOrCreate(self, self.OnCitizenSelectedChanged)
    self._p_resident_root:FeedData(self.citizenBlockData)
end

function CityLegoBuildingUIPage_Produce:HasCitizenWorking()
    return self.isWorking and self.workData ~= nil and self.workData.CitizenId ~= 0
end

function CityLegoBuildingUIPage_Produce:OnCitizenSelectedChanged(citizenId)
    if citizenId == self.citizenId then
        return true
    end

    local workId = self.workId
    --- 卸掉居民
    if citizenId == nil then
        if workId > 0 then
            --- 当前工作必须要人
            if not self.workCfg:AllowNoCitizen() then
                ---@type CommonConfirmPopupMediatorParameter
                local param = {}
                param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
                param.title = I18N.Get(CityWorkI18N.NotAllowCitizen_RemoveCitizen_Title)
                param.content = I18N.Get(CityWorkI18N.NotAllowCitizen_RemoveCitizen_Content)
                param.onConfirm = function()
                    ---确认后卸掉居民
                    self.city.cityWorkManager:DetachCitizenFromWork(workId, nil, function(isSuccess)
                        if isSuccess then
                            self:SelectCitizen(citizenId)
                            g_Game.UIManager:CloseByName(UIMediatorNames.CityFurnitureOverviewUIMediator)
                        end
                    end)
                    return true
                end
                g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
                return true
            else
                self.city.cityWorkManager:DetachCitizenFromWork(workId)
            end
        end
    else
        local citizenWorkData = self.city.cityWorkManager:GetCitizenWorkDataByCitizenId(citizenId)
        --- 选的其他居民有工作，确认后会卸载对方工作
        if citizenWorkData ~= nil then
            ---@type CommonConfirmPopupMediatorParameter
            local param = {}
            param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
            param.title = I18N.Get(CityWorkI18N.RemoveOtherCitizen_Title)
            param.content = I18N.Get(CityWorkI18N.RemoveOtherCitizen_Content)
            param.onConfirm = function()
                if workId > 0 then
                    self.city.cityWorkManager:AttachCitizenToWork(workId, citizenId, nil, function(cmd, isSuccess)
                        if not isSuccess then return end
                        self:SelectCitizen(citizenId)
                    end)
                else
                    if self.isWorking then
                        self.city.cityWorkManager:StartWorkImp(self.furnitureId, self.workCfg:Id(), citizenId, 0, nil, function(cmd, isSuccess)
                            if not isSuccess then return end
                            self:SelectCitizen(citizenId)
                        end)
                    else
                        self.city.cityWorkManager:DetachCitizenFromWork(citizenWorkData._id, nil, function(cmd, isSuccess)
                            if not isSuccess then return end
                            self:SelectCitizen(citizenId)
                        end)
                    end
                end
                return true
            end
            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
            return true
        --- 选的其他居民没有工作
        else
            --- 采集数据中有存盘数据
            if self.isWorking then
                --- 正在进行中
                if workId > 0 then
                    self.city.cityWorkManager:AttachCitizenToWork(workId, citizenId)
                --- 采集暂停了，重新开始这个工作
                else
                    self.city.cityWorkManager:StartWorkImp(self.furnitureId, self.workCfg:Id(), citizenId, 0)
                end
            end
        end
    end

    self:SelectCitizen(citizenId)
    return true
end

function CityLegoBuildingUIPage_Produce:SelectCitizen(citizenId)
    self.citizenId = citizenId
    self.citizenBlockData.citizenId = citizenId
    self._p_resident_root:FeedData(self.citizenBlockData)
    self:UpdateWorkAttributes()
    if not self.isWorking then
        self:UpdateCountSelection()
        self:UpdateButtonTime()
    end
    self:UpdateAutoTimePreview()
end

function CityLegoBuildingUIPage_Produce:GetCastleResourceGenerateInfo()
    local castleFurniture = self.cellTile:GetCastleFurniture()
    return castleFurniture.ResourceGenerateInfo
end

function CityLegoBuildingUIPage_Produce:InitStaticInfo()

    ---@type CityWorkConfigCell[]
    local workLvList = {}
    local workCfg = self.workCfg
    table.insert(workLvList, self.workCfg)

    local preWork = workCfg:PreLevel()
    while preWork ~= 0 do
        workCfg = ConfigRefer.CityWork:Find(preWork)
        table.insert(workLvList, 1, workCfg)
        preWork = workCfg:PreLevel()
    end

    workCfg = self.workCfg
    local nextWork = workCfg:NextLevel()
    while nextWork ~= 0 do
        workCfg = ConfigRefer.CityWork:Find(nextWork)
        table.insert(workLvList, workCfg)
        nextWork = workCfg:NextLevel()
    end

    local data = CityWorkProduceUILvPreviewGroupData.new(1)
    ---@type CityWorkProduceUILvPreviewGroupData[]
    local dataList = {}
    for i, v in ipairs(workLvList) do
        if not data:IsSameRecipeWork(v) then
            data:Close()
            table.insert(dataList, data)
            data = CityWorkProduceUILvPreviewGroupData.new(i)
        end
        data:AppendWorkLevel(v)

        if v == self.workCfg then
            data:MarkIsCurrent()
        end
    end

    for i, v in ipairs(dataList) do
        local items = v:GetItemDataList()
        if #items > 0 then
            for _, itemData in ipairs(items) do
                self._p_table_chart:AppendData(itemData, 0)
            end
            if i ~= #dataList then
                self._p_table_chart:AppendData(v, 1)
            end
        end
    end
end

function CityLegoBuildingUIPage_Produce:UpdateWorkAttributes()
    --- 消耗减少显示
    local costDecrease = CityWorkFormula.GetCostDecrease(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    self._p_buff_1:SetVisible(costDecrease ~= 0)
    if costDecrease ~= 0 then
        g_Game.SpriteManager:LoadSprite("sp_common_icon_time_01", self._p_icon_1)
        self._p_text_1.text = NumberFormatter.PercentWithSignSymbol(costDecrease)
    end

    --- 产出增加显示
    local outputIncrease = CityWorkFormula.GetOutputIncrease(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    self._p_buff_2:SetVisible(outputIncrease ~= 0)
    if outputIncrease ~= 0 then
        g_Game.SpriteManager:LoadSprite("sp_comp_icon_set", self._p_icon_2)
        self._p_text_2.text = NumberFormatter.PercentWithSignSymbol(outputIncrease)
    end

    local difficulty = self.selectedRecipe ~= nil and self.selectedRecipe:Difficulty() or 0
    --- 耗时减少
    local timeDecrease = math.clamp01(1 - CityWorkFormula.CalculateTimeCostDecrease(self.param.workCfg, difficulty, nil, self.furnitureId, self.citizenId))
    self._p_buff_3:SetVisible(timeDecrease ~= 0)
    if timeDecrease ~= 0 then
        g_Game.SpriteManager:LoadSprite("sp_comp_icon_hero_tab", self._p_icon_3)
        self._p_text_3.text = NumberFormatter.PercentWithSignSymbol(timeDecrease)
    end
end

function CityLegoBuildingUIPage_Produce:UpdateRecipeTable()
    self._p_table_item:Clear()
    local recipes = self.param:GetRecipes()
    for i, v in ipairs(recipes) do
        self._p_table_item:AppendData({cfg = v, uiMediator = self})
    end
end

function CityLegoBuildingUIPage_Produce:DefaultSelectFirstRecipe()
    local recipes = self.param:GetRecipes()
    if #recipes == 0 then return end
    self.selectedRecipe = recipes[1]
    self:UpdateWorkAttributes()
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_RES_GEN_SELECT_RECIPE, recipes[1])
end

function CityLegoBuildingUIPage_Produce:UpdateAreaInfo()
    local eleResCfg = ConfigRefer.CityElementResource:Find(self.selectedRecipe:GenerateResType())
    local cur, max = self.city.cityWorkManager:GetResGenAreaInfo(self.workCfg, self.furnitureId, self.citizenId, eleResCfg)
    self._p_text_area_num.text = ("%d/%d"):format(cur, max)
end

function CityLegoBuildingUIPage_Produce:UpdateSelectRecipeDesc()
    local resCfg = ConfigRefer.CityElementResource:Find(self.selectedRecipe:GenerateResType())
    self._p_text_item.text = I18N.Get(resCfg:NameKey())
    self._p_text_desc.text = I18N.Get(self.selectedRecipe:Description())
end

function CityLegoBuildingUIPage_Produce:UpdateCostPreview()
    self._pool_cost:HideAll()

    self.times = self.times or 1

    local capacity = CityWorkFormula.GetQueueCapacity(self.workCfg, nil, self.furnitureId, self.citizenId)
    self._p_text_input_quantity.text = ("/%d"):format(capacity)
    self.queueCapacity = capacity

    local eleResCfg = ConfigRefer.CityElementResource:Find(self.selectedRecipe:GenerateResType())
    local cur, max = self.city.cityWorkManager:GetResGenAreaInfo(self.workCfg, self.furnitureId, self.citizenId, eleResCfg)
    self.slotCapacity = math.max(0, max - cur)

    local itemGroup = ConfigRefer.ItemGroup:Find(self.selectedRecipe:Cost())
    self.input = CityWorkFormula.CalculateInput(self.workCfg, itemGroup, nil, self.furnitureId, self.citizenId)
    self.inputKind = #self.input

    self:ReleaseAllItemCountChangeListener()

    self.enoughCount = math.maxinteger
    for i = 1, self.inputKind do
        local info = self.input[i]
        local item = self._pool_cost:GetItem().Lua
        self.inputItemList[i] = item
        if self.inputDataList[i] then
            self.inputDataList[i].id = info.id
            self.inputDataList[i].onceNeed = info.count
        else
            self.inputDataList[i] = CityWorkUICostItemData.new(info.id, info.count, self.times)
        end
        self.inputDataList[i]:AddCountListener(Delegate.GetOrCreate(self, self.OnItemCountChanged))
        self.enoughCount = math.min(self.enoughCount, self.inputDataList[i]:GetMaxTimes())
        item:FeedData(self.inputDataList[i])
    end

    self.realMaxTimes = math.min(self.queueCapacity, self.slotCapacity, self.enoughCount)
    self._p_resource_grid:SetVisible(self.inputKind > 0)
end

function CityLegoBuildingUIPage_Produce:ReleaseAllItemCountChangeListener()
    if not self.inputDataList then return end
    for i, v in ipairs(self.inputDataList) do
        v:ReleaseCountListener()
    end
end

function CityLegoBuildingUIPage_Produce:InitCountSelection()
    self:InitAutoStatus()
    self:UpdateCountSelection()
end

function CityLegoBuildingUIPage_Produce:InitAutoStatus()
    self.isAuto = false
    local wds = self:GetCastleResourceGenerateInfo()
    for i, v in ipairs(wds.GeneratePlan) do
        if v.Auto then
            self.isAuto = true
            break
        end
    end
end

function CityLegoBuildingUIPage_Produce:UpdateCountSelection()
    self._group_quantity:SetActive(not self.showAuto)
    self._p_group_autocreate_time:SetActive(self.showAuto)

    if self.showAuto then
        self:UpdateAutoTimePreview()
    else
        self:UpdateSliderAndInputField()
    end
end

function CityLegoBuildingUIPage_Produce:UpdateAutoTimePreview()
    local time = CityWorkFormula.CalculateFinalTimeCost(self.workCfg, ConfigTimeUtility.NsToSeconds(self.selectedRecipe:Time()), self.selectedRecipe:Difficulty(), nil, self.furnitureId, self.citizenId)
    self._p_text_time.text = TimeFormatter.SimpleFormatTime(time)
end

function CityLegoBuildingUIPage_Produce:UpdateSliderAndInputField()
    ---@type CommonNumberSliderData
    self.sliderData = self.sliderData or {}
    self.sliderData.minNum = self.realMaxTimes > 0 and 1 or 0 --- 真的至少能造一个的时候最少选1
    self.sliderData.maxNum = self.queueCapacity
    self.sliderData.curNum = self.realMaxTimes > 0 and 1 or 0 --- 真的至少能造一个的时候就默认选1，否则选0
    self.sliderData.ignoreNum = self.sliderData.minNum
    self.sliderData.callBack = Delegate.GetOrCreate(self, self.OnSliderChange)
    self._p_set_num_bar:FeedData(self.sliderData)
    self._p_input_box_click.text = tostring(self.sliderData.curNum)
end

function CityLegoBuildingUIPage_Produce:UpdateButtonStatus()
    self._p_group_auto:SetActive(self.showAuto)
    self._p_group_manual:SetActive(not self.showAuto)

    if not self.showAuto then
        ---@type CommonPricedButtonData
        self._buttonData = self._buttonData or {}
        self._buttonData.buttonName = I18N.Get("sys_city_55")
        local errCode = self:CanStartWork()
        self._buttonData.enabled = errCode == FailureCode.Success or errCode == FailureCode.LackRes
        self._buttonData.callback = Delegate.GetOrCreate(self, self.OnClickStart)
        self._buttonData.disableCallback = Delegate.GetOrCreate(self, self.OnClickStart)
        self._child_comp_btn_b_l:FeedData(self._buttonData)

        self:UpdateButtonTime()
    end

    self._p_status_n:SetActive(not self.isAuto)
    self._p_status_select:SetActive(self.isAuto)
end

function CityLegoBuildingUIPage_Produce:CanStartWork(isAuto)
    --- 不允许修改Auto状态，说明队列中已存在一个Auto状态的计划
    if self.isAuto then
        return FailureCode.HasAutoInQueue
    end

    local allowNoCitizen = self.workCfg:AllowNoCitizen()
    if not allowNoCitizen and self.citizenId == nil then
        return FailureCode.MustHaveCitizen
    end

    if isAuto == nil then
        isAuto = self.isAuto
    end
    --- 次数为0
    if not isAuto and self.times <= 0 then
        return FailureCode.TimesZero
    end

    local castleFurniture = self.cellTile:GetCastleFurniture()
    local workType = CityWorkType.ResourceGenerate
    local workId = castleFurniture.WorkType2Id[workType] or 0
    local workData = self.city.cityWorkManager:GetWorkData(workId)
    if workId > 0 and workData ~= nil and workData.ConfigId ~= self.workCfg:Id() then
        return FailureCode.InOtherWork
    end

    local eleResCfg = ConfigRefer.CityElementResource:Find(self.selectedRecipe:GenerateResType())
    local cur, max = self.city.cityWorkManager:GetResGenAreaInfo(self.workCfg, self.furnitureId, self.citizenId, eleResCfg)
    if cur >= max and not isAuto then
        return FailureCode.SlotFull
    end

    local queueCount = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if castleFurniture.ResourceGenerateInfo.GeneratePlan:Count() >= queueCount then
        return FailureCode.QueueFull
    end

    local sameWorkTypeCount = self.city.cityWorkManager:GetWorkingCountByType(self.workCfg:Type())
    local maxSameWorkTypeCount = CityWorkFormula.GetTypeMaxQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if sameWorkTypeCount >= maxSameWorkTypeCount then
        return FailureCode.SameWorkTypeFull
    end

    if not isAuto and self.times > self.realMaxTimes then
        if self.times > self.enoughCount then
            return FailureCode.LackRes
        elseif self.times > self.queueCapacity then
            return FailureCode.QueueFull
        elseif self.times > self.slotCapacity then
            return FailureCode.SlotFull
        end
    end

    return 0
end

function CityLegoBuildingUIPage_Produce:UpdateButtonTime()
    if not self.showAuto then
        local time = CityWorkFormula.CalculateFinalTimeCost(self.workCfg, self.times * ConfigTimeUtility.NsToSeconds(self.selectedRecipe:Time()), self.selectedRecipe:Difficulty(), nil, self.furnitureId, self.citizenId)
        ---@type CommonTimerData
        self._timerData = self._timerData or {}
        self._timerData.fixTime = time
        self._timerData.needTimer = false
        self._child_time:FeedData(self._timerData)
    end
end

function CityLegoBuildingUIPage_Produce:UpdateQueueTableNew()
    self._mask_table:SetActive(not self.showAuto)
    if self.showAuto then return end

    local queueCount = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if queueCount == 0 then return end
    local showCount = queueCount
    local info = self:GetCastleResourceGenerateInfo()
    local planCount = info.GeneratePlan:Count()
    for i = 1, showCount do
        local isNew = self._queueCache[i] == nil
        if isNew then
            self._queueCache[i] = CityWorkProduceUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId), self)
        end
        
        if i <= planCount then
            local plan = info.GeneratePlan[i]
            if i == 1 then
                self._queueCache[i]:SetWorking(plan)
            else
                self._queueCache[i]:SetInQueue(plan)
            end
        else
            if not self.isAuto then
                self._queueCache[i]:SetFree()
            else
                self._queueCache[i]:SetForbid()
            end
        end

        if isNew then
            self._p_table:AppendData(self._queueCache[i])
        else
            self._p_table:UpdateChild(self._queueCache[i])
        end
    end
end

function CityLegoBuildingUIPage_Produce:AddEventListener()
    g_Game.EventManager:AddListener(EventConst.UI_CITY_RES_GEN_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    g_Game.EventManager:AddListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
end

function CityLegoBuildingUIPage_Produce:RemoveEventListener()
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_RES_GEN_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))    
    g_Game.EventManager:RemoveListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
end

function CityLegoBuildingUIPage_Produce:OnRecipeSelected(recipe)
    if not self.param then return end
    self.selectedRecipe = recipe
    self.times = nil
    self:UpdateWorkAttributes()
    self:UpdateSelectRecipeDesc()
    self:UpdateAreaInfo()
    self.showAuto = self.selectedRecipe:Cost() == 0
    if not self.showAuto then
        self:UpdateCostPreview()
    end
    self:UpdateButtonStatus()
    self:UpdateCountSelection()
end

function CityLegoBuildingUIPage_Produce:OnCitizenDataRefresh(city, needRefreshCitizenId)
    if not self.param then return end
    if self.city ~= city then return end
    
    if self.citizenId == nil then return end
    if needRefreshCitizenId[self.citizenId] then
        self:InitWorkStatus()
    end
end

function CityLegoBuildingUIPage_Produce:OnFurnitureDataChanged(city, batchEvt)
    if not self.param then return end
    if city ~= self.city then return end

    if batchEvt.Remove[self.furnitureId] then
        self:GetParentBaseUIMediator():FurnitureRemoved()
        return
    end

    if batchEvt.Change[self.furnitureId] then
        local castleFurniture = self.city:GetCastle().CastleFurniture[self.furnitureId]
        if castleFurniture.ConfigId ~= self.param.lvCfgId then
            self:GetParentBaseUIMediator():ProduceReopen()
            return
        end

        self:InitWorkStatus()
        self:InitAutoStatus()
        if not self.showAuto then
            self.enoughCount = math.maxinteger
            for i = 1, self.inputKind do
                self.enoughCount = math.min(self.enoughCount, self.inputDataList[i]:GetMaxTimes())
            end
            self.realMaxTimes = math.min(self.queueCapacity, self.slotCapacity, self.enoughCount)
            self:UpdateCostPreview()
        end
        self:UpdateCountSelection()
        self:UpdateButtonStatus()
        self:UpdateButtonTime()
        self:UpdateQueueTableNew()
        self:UpdateAreaInfo()
    end
end

function CityLegoBuildingUIPage_Produce:OnCastleAttrChanged()
    if not self.param then return end
    self:UpdateWorkAttributes()
    if not self.isWorking then
        self:UpdateCountSelection()
        self:UpdateButtonTime()
    end
end

function CityLegoBuildingUIPage_Produce:RequestRemoveInQueue(plan, lockable)
    if plan == nil then return end

    local wds = self:GetCastleResourceGenerateInfo()
    local index = table.indexof(wds.GeneratePlan, plan)
    if index <= 0 then return end

    self.city.cityWorkManager:RemoveResGenProcessWork(self.furnitureId, index-1, lockable, function()
        self._p_table_item:UpdateOnlyAllDataImmediately()
    end)
end

function CityLegoBuildingUIPage_Produce:OnClickStart(lockable, forceIsAuto)
    if forceIsAuto == nil then
        forceIsAuto = self.isAuto
    end

    local failureCode = self:CanStartWork(forceIsAuto)
    if failureCode == FailureCode.Success then
        self.city.cityWorkManager:StartResGenProcess(self.furnitureId, self.workCfg:Id(), self.citizenId, self.selectedRecipe:Id(), self.times, forceIsAuto, lockable, function()
            self._p_table_item:UpdateOnlyAllDataImmediately()
            self:TryStartGuide()
        end)
    elseif failureCode == FailureCode.LackRes then
        self:ShowLackResGetMore()
    else
        if FailureReasonI18N[failureCode] then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReasonI18N[failureCode]))
        end
    end
end

function CityLegoBuildingUIPage_Produce:TryStartGuide()
    local guideCfgId = self.workCfg:GuideOnStart()
    if guideCfgId > 0 then
        ModuleRefer.GuideModule:CallGuide(guideCfgId)
    end
end

function CityLegoBuildingUIPage_Produce:ShowLackResGetMore()
    local realHasNeed = false
    local getmoreList = {}
    for i, v in ipairs(self.inputDataList) do
        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
        local need = v.onceNeed * self.times
        if own < need then
            table.insert(getmoreList, {id = v.id, num = need - own})
            realHasNeed = true
        end
    end
    --对应实际不是物品不足 而是生产范围被占导致可用生产空位不能对应选择的数量生产 弹空板getmore 不合适，用个笼统的toast
    if not realHasNeed then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("UI_Title_FarmCant"))
        return
    end
    ModuleRefer.InventoryModule:OpenExchangePanel(getmoreList)
end

function CityLegoBuildingUIPage_Produce:OnSubmit(valueText)
    local value = math.clamp(checknumber(valueText), 0, self.queueCapacity)
    self._p_set_num_bar:ChangeCurNum(value)
    self:OnSliderChange(value)
end

function CityLegoBuildingUIPage_Produce:OnSliderChange(value)
    self.times = value
    self._p_input_box_click.text = tostring(value)
    for i = 1, self.inputKind do
        self.inputDataList[i].times = value
        self.inputItemList[i]:FeedData(self.inputDataList[i])
    end
    self:UpdateButtonTime()
end

function CityLegoBuildingUIPage_Produce:OnClickAutoBtn()
    if not self.isAuto then
        self:OnClickStart(self._p_btn_pading.transform, true)
    else
        self:RequestRemoveAutoPlan(self._p_btn_pading.transform)
    end
end

function CityLegoBuildingUIPage_Produce:RequestRemoveAutoPlan(lockable)
    local wds = self:GetCastleResourceGenerateInfo()
    for i, v in ipairs(wds.GeneratePlan) do
        if v.Auto then
            return self:RequestRemoveInQueue(v, lockable)
        end
    end
end

function CityLegoBuildingUIPage_Produce:OnClickSliderMax()
    self._p_set_num_bar:ChangeCurNum(self.realMaxTimes)
    self:OnSliderChange(self.realMaxTimes)
end

function CityLegoBuildingUIPage_Produce:IsProducing(recipeId)
    if not self.isWorking then return false end
    
    local wds = self:GetCastleResourceGenerateInfo()
    for _, plan in ipairs(wds.GeneratePlan) do
        if plan.Auto and plan.ProcessId == recipeId then
            return true
        end
    end

    return false
end

return CityLegoBuildingUIPage_Produce