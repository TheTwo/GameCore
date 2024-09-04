---Scene Name : scene_furniture_dialog_create_collection
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local CityWorkFormula = require("CityWorkFormula")
local NumberFormatter = require("NumberFormatter")
local EventConst = require("EventConst")
local I18N = require("I18N")
local CityWorkUICostItemData = require("CityWorkUICostItemData")
local ConfigTimeUtility = require("ConfigTimeUtility")
local TimeFormatter = require("TimeFormatter")
local Utils = require("Utils")
local HUDLogicPartDefine = require("HUDLogicPartDefine")
local CityWorkProduceUIUnitData = require("CityWorkProduceUIUnitData")
local TimerUtility = require("TimerUtility")
local CityWorkProduceUILvPreviewGroupData = require("CityWorkProduceUILvPreviewGroupData")
local CityWorkHelper = require("CityWorkHelper")
local CityWorkType = require("CityWorkType")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local CityWorkI18N = require("CityWorkI18N")
local UIMediatorNames = require("UIMediatorNames")

---@class CityWorkProduceUIMediator:BaseUIMediator
local CityWorkProduceUIMediator = class('CityWorkProduceUIMediator', BaseUIMediator)
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

function CityWorkProduceUIMediator:OnCreate()
    --- 退出按钮
    self._p_btn_exit = self:Button("p_btn_exit", Delegate.GetOrCreate(self, self.CloseSelf))
    --- 居民选择
    ---@type CityFurnitureConstructionProcessCitizenBlock
    self._child_city_labor = self:LuaObject("child_city_labor")
    --- 相机瞄准位置
    self._p_focus_target = self:Transform("p_focus_target")

    --- 左上方静态属性区
    self._p_btn_efficiency = self:Button("p_btn_efficiency", Delegate.GetOrCreate(self, self.OnClickGear))
    self._p_icon_efficiency = self:Image("p_icon_efficiency")
    self._p_text_efficiency = self:Text("p_text_efficiency")
    ---@type CityWorkUIBuffItem
    self._p_btn_buff_1 = self:LuaObject("p_btn_buff_1")
    ---@type CityWorkUIBuffItem
    self._p_btn_buff_2 = self:LuaObject("p_btn_buff_2")
    ---@type CityWorkUIBuffItem
    self._p_btn_buff_3 = self:LuaObject("p_btn_buff_3")

    --- 中间气泡
    self._p_btn_bubble = self:StatusRecordParent("p_btn_bubble")    --- 0空闲状态；1进行中（包括无限模式）；2暂停（暂不考虑
    self._vx_trigger_bubble = self:AnimTrigger("vx_trigger_bubble") --- 气泡的VX触发器
    self._p_bubble_btn = self:Button("p_btn_bubble", Delegate.GetOrCreate(self, self.OnClickShowCancel))
    self._p_progress = self:Image("p_progress")         --- 气泡进度条
    self._p_text_time_bubble = self:Text("p_text_time_bubble")      --- 气泡时间倒计时
    self._p_icon_item = self:Image("p_icon_item")       --- 种植中资源的预览图标
    self._p_text_quantity = self:Text("p_text_quantity")        --- 种植次数：eg:x1/∞

    self._p_btn_reduce = self:Button("p_btn_reduce", Delegate.GetOrCreate(self, self.OnClickCancel))
    self._p_text_reduce = self:Text("p_text_reduce", "sys_city_41")

    --- 右侧主面板
    self._p_content_right = self:StatusRecordParent("p_content_right") --- 0未选目标；1已选目标；2目标详情；3培育进度
    self._vx_trigger = self:AnimTrigger("vx_trigger") --- VX触发器

    --- 左下角订单详情
    self._p_text_working = self:Text("p_text_working", "sys_city_42")
    ---@see CityWorkProduceUIUnit
    self._p_table = self:TableViewPro("p_table")

    ------------右侧面板静态数据-------------
    self._p_text_building_name = self:Text("p_text_building_name")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetails))

    ------------右侧面板全状态更新数据-------------
    self._p_text_area_num = self:Text("p_text_area_num") ---- 显示产出情况

    ------------右侧面板<已选目标(现在默认进来选第一个)>-------------
    ---@see CityWorkProduceUIRecipeItem
    self._p_table_item = self:TableViewPro("p_table_item") ---- 配方选择table

    self._p_text_need = self:Text("p_text_need", "sys_city_43")
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

    self._p_text_forbid = self:Text("p_text_forbid", "sys_city_47")     ---- 队列中存在自动计划时，无法添加更多计划
    
    self._p_toggle = self:GameObject("p_toggle")     ---- 自动勾选根节点
    self._p_btn_pading = self:Button("p_btn_pading", Delegate.GetOrCreate(self, self.OnClickAutoBtn))       ----自动勾选
    self._p_status_n = self:GameObject("p_status_n")
    self._p_status_select = self:GameObject("p_status_select")
    self._p_text_auto = self:Text("p_text_auto", "sys_city_48")

    self._p_bottom_btn = self:GameObject("p_bottom_btn")        --- 按钮根节点
    ---@type CommonPricedButton
    self._child_comp_btn_b_l = self:LuaObject("child_comp_btn_b_l")     ---- 按钮组件
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")

    self._p_chart = self:GameObject("p_chart")      ---- 预览种植图表
    self._p_chart_title_level = self:Text("p_chart_title_level", "sys_city_49")
    self._p_chart_title_item = self:Text("p_chart_title_item", "sys_city_50")
    self._p_chart_title_outcome = self:Text("p_chart_title_outcome", "sys_city_51")

    ------------等级预览需要显隐的节点------------
    self._p_scroll_content = self:GameObject("p_scroll_content")
    self._bottom = self:GameObject("bottom")
    self._p_chart = self:GameObject("p_chart")
    ---@see CityWorkProduceUILvPreviewItem
    self._p_table_chart = self:TableViewPro("p_table_chart")    ---- 预览种植图表TableViewPro [childIndex:0为实际列表，1为分割线] 
end

---@param param CityWorkProduceUIParameter
function CityWorkProduceUIMediator:OnOpened(param)
    self.param = param
    self.city = param.city
    self.workCfg = param.workCfg
    self.cellTile = param.cellTile
    self.furnitureId = param.cellTile:GetCell().singleId
    self.showDetails = false
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.ConstructionColor)
    self.cellTile:SetSelected(true)
    self.bubbleWorking = nil
    g_Game.SpriteManager:LoadSprite(self.city.cityWorkManager:GetWorkBuffIconForCitizen(self.workCfg), self._p_icon_efficiency)

    ---@type CityWorkUICostItemData[]
    self.inputDataList = {}
    self.inputItemList = {}
    ---@type CityWorkProduceUIUnitData[]
    self._queueCache = {}

    self:InitWorkStatus()
    self:InitCitizenInfo()
    self:InitStaticInfo()
    self:UpdateWorkAttributes()
    self:UpdateRecipeTable()
    self:DefaultSelectFirstRecipe()
    self:UpdateAreaInfo()
    self:UpdateSelectRecipeDesc()
    self:UpdateCostPreview()
    self:InitCountSelection()
    self:UpdateButtonStatus()
    self:UpdateQueueTableNew()
    self:UpdateBubble()
    self:HideHud()
    self:AddEventListener()
    self:MoveCameraToFocusTarget()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_WORK_PRODUCE_OPEN, true)
end

function CityWorkProduceUIMediator:OnClose(param)
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.OtherColor)
    self.cellTile:SetSelected(false)
    self:RecoverCamera()
    self:RecoverHud()
    self:StopBubbleTimer()
    self:RemoveEventListener()
    self:ReleaseAllItemCountChangeListener()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_WORK_PRODUCE_OPEN, false)
end

function CityWorkProduceUIMediator:AddEventListener()
    g_Game.EventManager:AddListener(EventConst.UI_CITY_RES_GEN_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    g_Game.EventManager:AddListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
    g_Game.EventManager:AddListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
end

function CityWorkProduceUIMediator:RemoveEventListener()
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_RES_GEN_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))    
    g_Game.EventManager:RemoveListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
    g_Game.EventManager:RemoveListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
end

function CityWorkProduceUIMediator:HideHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.inCityOnlyShowRes, false)
end

function CityWorkProduceUIMediator:RecoverHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.inCityOnlyShowRes, true)
end


function CityWorkProduceUIMediator:MoveCameraToFocusTarget()
    local uiCamera = g_Game.UIManager:GetUICamera()
    if Utils.IsNull(uiCamera) then return end

    local basicCamera = self.city:GetCamera()
    if basicCamera == nil then return end

    local viewport = uiCamera:WorldToViewportPoint(self._p_focus_target.position)
    local tileView = self.cellTile.tileView
    local mainAssets = tileView and tileView:GetMainAssets()
    ---@type CityTileAsset
    local asset = next(mainAssets or {})
    if asset then
        local flag, pos = asset:TryGetAnchorPos()
        self.cameraStackHandle = basicCamera:ZoomToWithFocusStack(basicCamera:GetMinSize(), viewport, pos, 0.5)
    else
        self.cameraStackHandle = basicCamera:ZoomToWithFocusStack(basicCamera:GetMinSize(), viewport, self.cellTile:GetWorldCenter(), 0.5)
    end
end

function CityWorkProduceUIMediator:RecoverCamera()
    if self.cameraStackHandle then
        self.cameraStackHandle:back()
        self.cameraStackHandle = nil
    end
end

function CityWorkProduceUIMediator:InitWorkStatus()
    local wds = self:GetCastleResourceGenerateInfo()
    self.isWorking = wds.GeneratePlan:Count() > 0
end

function CityWorkProduceUIMediator:InitCitizenInfo()
    self.citizenId = nil
    local castleFurniture = self.cellTile:GetCastleFurniture()
    if castleFurniture.WorkType2Id[CityWorkType.ResourceGenerate] ~= nil then
        local workData = self.city.cityWorkManager:GetWorkData(castleFurniture.WorkType2Id[CityWorkType.ResourceGenerate])
        self.citizenId = workData.CitizenId ~= 0 and workData.CitizenId or nil
    end

    ---@type CityFurnitureConstructionProcessCitizenBlockData
    self._citizenCompData = self._citizenCompData or {}
    self._citizenCompData.citizenId = self.citizenId
    self._citizenCompData.workCfgId = self.workCfg:Id()
    self._citizenCompData.citizenMgr = self.city.cityCitizenManager
    self._citizenCompData.onSelectedChanged = Delegate.GetOrCreate(self, self.OnCitizenSelectedChanged)
    self._child_city_labor:FeedData(self._citizenCompData)
end

function CityWorkProduceUIMediator:OnCitizenSelectedChanged(citizenId)
    --- 选的同一个人，直接返回
    if citizenId == self.citizenId then
        return true
    end
    
    local workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.ResourceGenerate] or 0
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
                        if not isSuccess then return end
                        self:SelectCitizen(citizenId)
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
            --- 种植数据中有存盘数据
            if self.isWorking then
                --- 正在进行中
                if workId > 0 then
                    self.city.cityWorkManager:AttachCitizenToWork(workId, citizenId)
                --- 种植暂停了，重新开始这个工作
                else
                    self.city.cityWorkManager:StartWorkImp(self.furnitureId, self.workCfg:Id(), citizenId, 0)
                end
            end
        end
    end

    self:SelectCitizen(citizenId)
    return true
end

function CityWorkProduceUIMediator:SelectCitizen(citizenId)
    self._citizenCompData.citizenId = citizenId
    self._child_city_labor:FeedData(self._citizenCompData)
    self.citizenId = citizenId
    self:UpdateWorkAttributes()
    if not self.isWorking then
        self:UpdateCountSelection()
        self:UpdateButtonTime()
    end

    self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
    if self.citizenId == nil then
        self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom4)
    end
end

function CityWorkProduceUIMediator:OnCitizenDataRefresh(city, needRefreshCitizenId)
    if self.city ~= city then return end
    
    if self.citizenId == nil then return end
    if needRefreshCitizenId[self.citizenId] then
        self._child_city_labor:FeedData(self._citizenCompData)
    end
end

---@return wds.CastleResourceGenerateInfo
function CityWorkProduceUIMediator:GetCastleResourceGenerateInfo()
    local castleFurniture = self.cellTile:GetCastleFurniture()
    return castleFurniture.ResourceGenerateInfo
end

function CityWorkProduceUIMediator:InitStaticInfo()
    self._p_text_building_name.text = I18N.Get(self.workCfg:Name())

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

function CityWorkProduceUIMediator:UpdateWorkAttributes()
    --- 强度显示
    local power = CityWorkFormula.GetWorkPower(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    local citizenPower = self.city.cityWorkManager:GetWorkBuffValueFromCitizenId(self.param.workCfg, self.citizenId)
    if citizenPower > 0 then
        self._p_text_efficiency.text = string.format("%.0f(%s)", (power - citizenPower), NumberFormatter.WithSign(citizenPower))
    else
        self._p_text_efficiency.text = string.format("%.0f", power)
    end

    --- 效率加成显示
    local efficiency = CityWorkFormula.GetWorkEfficiency(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    local originEfficiency = CityWorkFormula.GetWorkEfficiency(self.param.workCfg, nil, self.furnitureId, nil)
    self._p_btn_buff_1:SetVisible(efficiency ~= 0)
    if efficiency ~= 0 then
        local total, other, citizen = CityWorkHelper.GetBuffPercentItemDescStringForI18NParams(efficiency, originEfficiency)
        self._p_btn_buff_1:FeedData({desc = NumberFormatter.PercentWithSignSymbol(efficiency), tip = I18N.GetWithParams("sys_city_70", total, citizen, other)})
    end

    --- 消耗减少显示
    local costDecrease = CityWorkFormula.GetCostDecrease(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    local originCostDecrease = CityWorkFormula.GetCostDecrease(self.param.workCfg, nil, self.furnitureId, nil)
    self._p_btn_buff_2:SetVisible(costDecrease ~= 0)
    if costDecrease ~= 0 then
        local total, other, citizen = CityWorkHelper.GetBuffPercentItemDescStringForI18NParams(costDecrease, originCostDecrease)
        self._p_btn_buff_2:FeedData({desc = NumberFormatter.PercentWithSignSymbol(costDecrease), tip = I18N.GetWithParams("sys_city_71", total, citizen, other)})
    end

    --- 产出增加显示
    local outputIncrease = CityWorkFormula.GetOutputIncrease(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    local originOutputIncrease = CityWorkFormula.GetOutputIncrease(self.param.workCfg, nil, self.furnitureId)
    self._p_btn_buff_3:SetVisible(outputIncrease ~= 0)
    if outputIncrease ~= 0 then
        local total, other, citizen = CityWorkHelper.GetBuffPercentItemDescStringForI18NParams(outputIncrease, originOutputIncrease)
        self._p_btn_buff_3:FeedData({desc = NumberFormatter.PercentWithSignSymbol(outputIncrease), tip = I18N.GetWithParams("sys_city_72", total, citizen, other)})
    end
end

function CityWorkProduceUIMediator:UpdateRecipeTable()
    self._p_table_item:Clear()
    local recipes = self.param:GetRecipes()
    for i, v in ipairs(recipes) do
        self._p_table_item:AppendData(v)
    end
end

function CityWorkProduceUIMediator:UpdateAreaInfo()
    local eleResCfg = ConfigRefer.CityElementResource:Find(self.selectedRecipe:GenerateResType())
    local cur, max = self.city.cityWorkManager:GetResGenAreaInfo(self.workCfg, self.furnitureId, self.citizenId, eleResCfg)
    self._p_text_area_num.text = ("%d/%d"):format(cur, max)
end

function CityWorkProduceUIMediator:DefaultSelectFirstRecipe()
    local recipes = self.param:GetRecipes()
    if #recipes == 0 then return end
    self.selectedRecipe = recipes[1]
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_RES_GEN_SELECT_RECIPE, recipes[1])
end

function CityWorkProduceUIMediator:UpdateSelectRecipeDesc()
    local resCfg = ConfigRefer.CityElementResource:Find(self.selectedRecipe:GenerateResType())
    self._p_text_item.text = I18N.Get(resCfg:NameKey())
    self._p_text_desc.text = I18N.Get(self.selectedRecipe:Description())
end

function CityWorkProduceUIMediator:UpdateCostPreview()
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

function CityWorkProduceUIMediator:ReleaseAllItemCountChangeListener()
    for i, v in ipairs(self.inputDataList) do
        v:ReleaseCountListener()
    end
end

function CityWorkProduceUIMediator:OnItemCountChanged()
    for i = 1, self.inputKind do
        self.inputItemList[i]:FeedData(self.inputDataList[i])
    end
    self:UpdateButtonStatus()
end

function CityWorkProduceUIMediator:InitCountSelection()
    self:InitAutoStatus()
    self:UpdateCountSelection()
end

function CityWorkProduceUIMediator:UpdateCountSelection()
    self._group_quantity:SetActive(not self.isAuto)
    self._p_group_autocreate_time:SetActive(self.isAuto)

    if self.isAuto then
        self:UpdateAutoTimePreview()
    else
        self:UpdateSliderAndInputField()
    end
end

function CityWorkProduceUIMediator:InitAutoStatus()
    self.isAuto = false
    local wds = self:GetCastleResourceGenerateInfo()
    for i, v in ipairs(wds.GeneratePlan) do
        if v.Auto then
            self.isAuto = true
            break
        end
    end
end

function CityWorkProduceUIMediator:UpdateSliderAndInputField()
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

function CityWorkProduceUIMediator:UpdateAutoTimePreview()
    local time = CityWorkFormula.CalculateFinalTimeCost(self.workCfg, ConfigTimeUtility.NsToSeconds(self.selectedRecipe:Time()), self.selectedRecipe:Difficulty(), nil, self.furnitureId, self.citizenId)
    self._p_text_time.text = TimeFormatter.SimpleFormatTime(time)
end

function CityWorkProduceUIMediator:UpdateButtonStatus()
    self._p_text_forbid:SetVisible(false)
    self._p_toggle:SetActive(true)
    self._p_bottom_btn:SetActive(not self.isAuto)

    if not self.isAuto then
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

function CityWorkProduceUIMediator:UpdateButtonTime()
    self._child_time:SetVisible(not self.isAuto)

    if not self.isAuto then
        local time = CityWorkFormula.CalculateFinalTimeCost(self.workCfg, self.times * ConfigTimeUtility.NsToSeconds(self.selectedRecipe:Time()), self.selectedRecipe:Difficulty(), nil, self.furnitureId, self.citizenId)
        ---@type CommonTimerData
        self._timerData = self._timerData or {}
        self._timerData.fixTime = time
        self._timerData.needTimer = false
        self._child_time:FeedData(self._timerData)
    end
end

function CityWorkProduceUIMediator:OnRecipeSelected(recipe)
    self.selectedRecipe = recipe
    self.times = nil
    self:UpdateSelectRecipeDesc()
    self:UpdateAreaInfo()
    self:UpdateCostPreview()
    self:UpdateButtonStatus()
    self:UpdateCountSelection()
end

---@return boolean
function CityWorkProduceUIMediator:CanStartWork(isAuto)
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

function CityWorkProduceUIMediator:ShowLackResGetMore()
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

function CityWorkProduceUIMediator:OnSubmit(valueText)
    local value = math.clamp(checknumber(valueText), 0, self.queueCapacity)
    self._p_set_num_bar:ChangeCurNum(value)
    self:OnSliderChange(value)
end

function CityWorkProduceUIMediator:OnSliderChange(value)
    self.times = value
    self._p_input_box_click.text = tostring(value)
    for i = 1, self.inputKind do
        self.inputDataList[i].times = value
        self.inputItemList[i]:FeedData(self.inputDataList[i])
    end
    self:UpdateButtonTime()
end

function CityWorkProduceUIMediator:OnClickAutoBtn()
    if not self.isAuto then
        self:OnClickStart(self._p_btn_pading.transform, true)
    else
        self:RequestRemoveAutoPlan(self._p_btn_pading.transform)
    end
end

function CityWorkProduceUIMediator:OnClickStart(lockable, forceIsAuto)
    if forceIsAuto == nil then
        forceIsAuto = self.isAuto
    end

    local failureCode = self:CanStartWork(forceIsAuto)
    if failureCode == FailureCode.Success then
        self.city.cityWorkManager:StartResGenProcess(self.furnitureId, self.workCfg:Id(), self.citizenId, self.selectedRecipe:Id(), self.times, forceIsAuto, lockable, Delegate.GetOrCreate(self, self.TryStartGuide))
    elseif failureCode == FailureCode.LackRes then
        self:ShowLackResGetMore()
    else
        if FailureReasonI18N[failureCode] then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReasonI18N[failureCode]))
        end
    end
end

function CityWorkProduceUIMediator:TryStartGuide()
    local guideCfgId = self.workCfg:GuideOnStart()
    if guideCfgId > 0 then
        ModuleRefer.GuideModule:CallGuide(guideCfgId)
    end
end

function CityWorkProduceUIMediator:UpdateQueueTable()
    self._p_table:Clear()
    
    local queueCount = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if queueCount == 0 then return end
    local showCount = queueCount
    --- 种植队列不存在收取问题，所以在队列中的一定都是正在进行的
    local wds = self:GetCastleResourceGenerateInfo()
    if wds.GeneratePlan:Count() > 0 then
        showCount = showCount - 1
    end

    local index = 0
    for i, v in ipairs(wds.GeneratePlan) do
        if i == 1 then goto continue end
        index = index + 1
        self._queueCache[index] = self._queueCache[index] or CityWorkProduceUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId))
        self._queueCache[index]:SetInQueue(v)
        self._p_table:AppendData(self._queueCache[index])
        ::continue::
    end

    for i = index + 1, showCount do
        self._queueCache[i] = self._queueCache[i] or CityWorkProduceUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId))
        if not self.isAuto then
            self._queueCache[i]:SetFree()
        else
            self._queueCache[i]:SetForbid()
        end
        self._p_table:AppendData(self._queueCache[i])
    end
end

function CityWorkProduceUIMediator:UpdateQueueTableNew()
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

function CityWorkProduceUIMediator:UpdateBubble()
    self._p_btn_bubble:SetVisible(false)
    -- self._p_btn_bubble:ApplyStatusRecord(self.isWorking and 1 or 0)
    -- if self.isWorking then
    --     local wds = self:GetCastleResourceGenerateInfo()
    --     local plan = wds.GeneratePlan[1]
    --     local processCfg = ConfigRefer.CityProcess:Find(plan.ProcessId)
    --     local eleResCfg = ConfigRefer.CityElementResource:Find(processCfg:GenerateResType())
    --     g_Game.SpriteManager:LoadSprite(eleResCfg:Icon(), self._p_icon_item)
    --     if plan.Auto then
    --         self._p_text_quantity.text = ("x∞")
    --         self:StopBubbleTimer()
    --     else
    --         self._p_text_quantity.text = ("x%d"):format(plan.TargetCount)
    --         self:UpdateBubbleProgress()
    --         self:UpdateBubbleTime()
    --         self:StartBubbleTimer()
    --     end

    --     if self.currentStartTime == nil then
    --         self.currentStartTime = plan.StartTime.ServerSecond
    --     elseif self.currentStartTime ~= plan.StartTime.ServerSecond then
    --         self._p_btn_reduce:SetVisible(false)
    --     end
        
    --     if self.bubbleWorking == false then
    --         self._vx_trigger_bubble:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    --     end
    --     self.bubbleWorking = true
    -- else
    --     self:StopBubbleTimer()
    --     self._p_btn_reduce:SetVisible(false)
    --     self.bubbleWorking = true
    -- end
end

function CityWorkProduceUIMediator:UpdateBubbleProgress()
    if not self.isWorking then return end
    local wds = self:GetCastleResourceGenerateInfo()
    local plan = wds.GeneratePlan[1]
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local passTime = nowTime - plan.StartTime.ServerSecond
    local fullTime = plan.FinishTime.ServerSecond - plan.StartTime.ServerSecond
    local progress = math.clamp01(passTime / fullTime)
    self._p_progress.fillAmount = progress
end

function CityWorkProduceUIMediator:UpdateBubbleTime()
    if not self.isWorking then return end
    local wds = self:GetCastleResourceGenerateInfo()
    local plan = wds.GeneratePlan[1]
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local remainTime = plan.FinishTime.ServerSecond - nowTime
    self._p_text_time_bubble.text = TimeFormatter.SimpleFormatTime(remainTime)
end

function CityWorkProduceUIMediator:StartBubbleTimer()
    if not self._bubbleSecondTimer then
        self._bubbleSecondTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.UpdateBubbleTime), 1, -1, true)
    end
    if not self._bubbleFrameTimer then
        self._bubbleFrameTimer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.UpdateBubbleProgress), 1, -1)
    end
end

function CityWorkProduceUIMediator:StopBubbleTimer()
    if self._bubbleSecondTimer then
        TimerUtility.StopAndRecycle(self._bubbleSecondTimer)
        self._bubbleSecondTimer = nil
    end
    if self._bubbleFrameTimer then
        TimerUtility.StopAndRecycle(self._bubbleFrameTimer)
        self._bubbleFrameTimer = nil
    end
end

---@param city City
function CityWorkProduceUIMediator:OnFurnitureDataChanged(city, batchEvt)
    if city ~= self.city then return end

    if batchEvt.Remove[self.furnitureId] then
        self:CloseSelf()
        return
    end

    if batchEvt.Change[self.furnitureId] then
        local castleFurniture = self.city:GetCastle().CastleFurniture[self.furnitureId]
        if castleFurniture.ConfigId ~= self.param.lvCfgId then
            self:CloseSelf()
            return
        end

        self:InitWorkStatus()
        self:InitAutoStatus()
        self.enoughCount = math.maxinteger
        for i = 1, self.inputKind do
            self.enoughCount = math.min(self.enoughCount, self.inputDataList[i]:GetMaxTimes())
        end
        self.realMaxTimes = math.min(self.queueCapacity, self.slotCapacity, self.enoughCount)
        self:UpdateCostPreview()
        self:UpdateCountSelection()
        self:UpdateButtonStatus()
        self:UpdateButtonTime()
        self:UpdateQueueTableNew()
        self:UpdateBubble()
        self:UpdateAreaInfo()
    end
end

function CityWorkProduceUIMediator:OnClickGear()
    ---@type TextToastMediatorParameter
    if not self.toastData then
        self.toastData = {}
        self.toastData.clickTransform = self._p_btn_efficiency.transform
    end
    local power = CityWorkFormula.GetWorkPower(self.workCfg, nil, self.furnitureId, self.citizenId)
    self.toastData.content = I18N.GetWithParams("sys_city_16", power)
    ModuleRefer.ToastModule:ShowTextToast(self.toastData)
end

function CityWorkProduceUIMediator:OnClickDetails()
    self.showDetails = not self.showDetails
    self._p_scroll_content:SetActive(not self.showDetails)
    self._bottom:SetActive(not self.showDetails)
    self._p_chart:SetActive(self.showDetails)
end

function CityWorkProduceUIMediator:OnClickShowCancel()
    if self.isWorking then
        self._p_btn_reduce:SetVisible(true)
    end
end

function CityWorkProduceUIMediator:OnClickCancel()
    if self.isWorking then
        self.city.cityWorkManager:RemoveResGenProcessWork(self.furnitureId, 0, self._p_btn_reduce.transform)
    end
end

---@param plan wds.CastleResourceGeneratePlan
function CityWorkProduceUIMediator:RequestRemoveInQueue(plan, lockable)
    if plan == nil then return end

    local wds = self:GetCastleResourceGenerateInfo()
    local index = table.indexof(wds.GeneratePlan, plan)
    if index <= 0 then return end

    self.city.cityWorkManager:RemoveResGenProcessWork(self.furnitureId, index-1, lockable)
end

function CityWorkProduceUIMediator:RequestRemoveAutoPlan(lockable)
    local wds = self:GetCastleResourceGenerateInfo()
    for i, v in ipairs(wds.GeneratePlan) do
        if v.Auto then
            return self:RequestRemoveInQueue(v, lockable)
        end
    end
end

function CityWorkProduceUIMediator:OnUITouchUp(gameObj)
    if self._p_bubble_btn.gameObject ~= gameObj then
        self._p_btn_reduce:SetVisible(false)
    end
end

function CityWorkProduceUIMediator:OnCastleAttrChanged()
    self:UpdateWorkAttributes()
    if not self.isWorking then
        self:UpdateCountSelection()
        self:UpdateButtonTime()
    end
end

function CityWorkProduceUIMediator:CanAddOrChangeCitizen()
    return not self.isWorking or self.citizenId == nil
end

function CityWorkProduceUIMediator:OnClickSliderMax()
    self._p_set_num_bar:ChangeCurNum(self.realMaxTimes)
    self:OnSliderChange(self.realMaxTimes)
end

return CityWorkProduceUIMediator