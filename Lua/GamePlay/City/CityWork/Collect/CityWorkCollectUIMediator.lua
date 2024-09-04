---Scene Name : scene_furniture_dialog_collect
local BaseUIMediator = require ('BaseUIMediator')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require("ModuleRefer")
local Delegate = require('Delegate')
local CityWorkFormula = require("CityWorkFormula")
local NumberFormatter = require("NumberFormatter")
local EventConst = require("EventConst")
local CityWorkCollectWdsHelper = require("CityWorkCollectWdsHelper")
local I18N = require("I18N")
local TimerUtility = require("TimerUtility")
local TimeFormatter = require("TimeFormatter")
local CityWorkCollectUIUnitData = require("CityWorkCollectUIUnitData")
local UIHelper = require("UIHelper")
local ConfigTimeUtility = require("ConfigTimeUtility")
local HUDLogicPartDefine = require("HUDLogicPartDefine")
local Utils = require("Utils")
local CityWorkHelper = require("CityWorkHelper")
local CityWorkType = require("CityWorkType")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")
local CityWorkI18N = require("CityWorkI18N")
local CityUtils = require("CityUtils")

---@class CityWorkCollectUIMediator:BaseUIMediator
local CityWorkCollectUIMediator = class('CityWorkCollectUIMediator', BaseUIMediator)
local RightPanelStatus = {NotSelectCitizen = 0, NotSelectRecipe = 1, SelectedRecipe = 2}
local BubbleStatus = {Free = 0, Collecting = 1}
local CantStartReason = {"sys_city_3", "sys_city_4", "sys_city_5", "sys_city_6", "sys_city_7", "sys_city_8", "toast_gatherworklimited"}

function CityWorkCollectUIMediator:OnCreate()
    self._group_left = self:GameObject("group_left")
    self._p_icon_efficiency = self:Image("p_icon_efficiency")
    self._p_btn_efficiency = self:Button("p_btn_efficiency", Delegate.GetOrCreate(self, self.OnClickGear))
    self._p_text_efficiency = self:Text("p_text_efficiency")
    self._p_focus_target = self:Transform("p_focus_target")

    ---@type CityWorkUIBuffItem
    self._p_btn_buff_1 = self:LuaObject("p_btn_buff_1")
    ---@type CityWorkUIBuffItem
    self._p_btn_buff_2 = self:LuaObject("p_btn_buff_2")
    ---@type CityWorkUIBuffItem
    self._p_btn_buff_3 = self:LuaObject("p_btn_buff_3")

    self._p_btn_exit = self:Button("p_btn_exit", Delegate.GetOrCreate(self, self.OnClickExit))

    self._group_process = self:GameObject("group_process")
    self._p_text_working = self:Text("p_text_working", "sys_city_9")
    self._mask_table = self:GameObject("mask_table")
    self._p_table = self:TableViewPro("p_table")

    self._p_content_right = self:StatusRecordParent("p_content_right")
    self._p_building_name = self:GameObject("p_building_name")
    self._p_text_building_name = self:Text("p_text_building_name")
    self._p_detail = self:GameObject("p_detail")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetails))

    ---@type CityFurnitureConstructionProcessCitizenBlock
    self._p_btn_resident_root = self:LuaObject("p_btn_resident_root")

    self._p_text_view = self:Text("p_text_view", "sys_city_10")
    ---@see CityWorkCollectUIRecipeItem
    self._p_table_item = self:TableViewPro("p_table_item")

    self._p_group_quantity = self:GameObject("p_group_quantity")
    self._p_text_select = self:Text("p_text_select", "sys_city_12")
    self._p_text_input_quantity = self:Text("p_text_input_quantity")
    self._p_input_box_click = self:InputField("p_input_box_click", nil, nil, Delegate.GetOrCreate(self, self.OnSubmit))
    ---@type CommonNumberSlider
    self._p_set_num_bar = self:LuaObject("p_set_num_bar")
    self._p_text_max = self:Text("p_text_max", "sys_city_22")
    self._p_btn_max = self:Button("p_btn_max", Delegate.GetOrCreate(self, self.OnClickSliderMax))

    self._p_base_empty = self:GameObject("p_base_empty")
    self._p_text_empty = self:Text("p_text_empty", "sys_city_13")

    self._p_bottom_btn = self:GameObject("p_bottom_btn")
    self._child_comp_btn_b_l = self:Button("child_comp_btn_b_l", Delegate.GetOrCreate(self, self.OnClickStart))
    self._p_text = self:Text("p_text", "sys_city_14")
    self._p_number_bl = self:GameObject("p_number_bl")
    self._p_number_bl:SetActive(false)
    self._p_icon_item_bl = self:Image("p_icon_item_bl")
    self._p_text_num_green_bl = self:Text("p_text_num_green_bl")
    self._p_text_num_red_bl = self:Text("p_text_num_red_bl")
    self._p_text_num_wilth_bl = self:Text("p_text_num_wilth_bl")

    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")
    ---@type CityFurnitureConstructionProcessCitizenBlock
    self._p_resident_root = self:LuaObject("p_resident_root")

    self._p_btn_bubble = self:StatusRecordParent("p_btn_bubble")
    self._vx_trigger_bubble = self:AnimTrigger("vx_trigger_bubble")
    self._p_bubble_btn = self:Button("p_btn_bubble", Delegate.GetOrCreate(self, self.OnClickBubble))
    self._p_progress = self:Image("p_progress")
    self._p_progress_stop = self:Image("p_progress_stop")
    self._p_text_time_bubble = self:Text("p_text_time_bubble")
    self._p_icon_item = self:Image("p_icon_item")
    self._p_text_quantity = self:Text("p_text_quantity")
    self._p_btn_reduce = self:Button("p_btn_reduce", Delegate.GetOrCreate(self, self.OnClickCancelCurrent))
    self._p_text_reduce = self:Text("p_text_reduce", "sys_city_15")

    --- 自动勾选根节点
    self._p_toggle = self:GameObject("p_toggle")
    self._p_btn_pading = self:Button("p_btn_pading", Delegate.GetOrCreate(self, self.OnClickAuto))
    self._p_status_n = self:GameObject("p_status_n")
    self._p_status_select = self:GameObject("p_status_select")
    self._p_text_auto = self:Text("p_text_auto", "sys_city_48")

    self._vx_trigger = self:AnimTrigger("vx_trigger")
end

---@param param CityWorkCollectUIParameter
function CityWorkCollectUIMediator:OnOpened(param)
    self.param = param
    self.city = self.param.city
    self.cellTile = self.param.source
    self.workCfg = self.param.workCfg
    self.furnitureId = self.cellTile:GetCell().singleId
    self.citizenId = nil
    self.bubbleWorking = nil
    ---@type CityWorkCollectUIUnitData[]
    self.unitDataCaches = {}
    ---@type table<number, ItemConfigCell[]>
    self.outputCache = {}
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.ConstructionColor)
    self.cellTile:SetSelected(true)
    
    g_Game.SpriteManager:LoadSprite(self.city.cityWorkManager:GetWorkBuffIconForCitizen(self.workCfg), self._p_icon_efficiency)

    self:InitStaticInfo()
    self:InitWorkStatus()
    self:InitAutoStatus()
    self:InitCitizenComponent()
    self:UpdateWorkAttributes()
    if self.isWorking then
        self._p_content_right:ApplyStatusRecord(RightPanelStatus.NotSelectRecipe)
        self:InitRecipeTable()
        self:UpdateWorkingQueue()
    else
        self._p_content_right:ApplyStatusRecord(RightPanelStatus.NotSelectCitizen)
        self:InitRecipeTable()
        self:UpdateWorkingQueue()
    end
    self:HideHud()
    self:MoveCameraToFocusTarget()
    self:AddEventListener()
    self:DefaultSelectFirst()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
end

function CityWorkCollectUIMediator:OnClose(param)
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.OtherColor)
    self.cellTile:SetSelected(false)
    self:RemoveEventListener()
    self:RecoverHud()
    self:RecoverCamera()
    self:TryStopTimer()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
end

function CityWorkCollectUIMediator:AddEventListener()
    g_Game.EventManager:AddListener(EventConst.UI_CITY_COLLECT_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnCastleFurnitureChanged))
    g_Game.EventManager:AddListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnElementCountChange))
    g_Game.EventManager:AddListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
end

function CityWorkCollectUIMediator:RemoveEventListener()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnCastleFurnitureChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_COLLECT_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:RemoveListener(EventConst.ON_OVER_UI_ELEMENT, Delegate.GetOrCreate(self, self.OnUITouchUp))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnElementCountChange))
    g_Game.EventManager:RemoveListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
end

function CityWorkCollectUIMediator:HideHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.inCityOnlyShowRes, false)
end

function CityWorkCollectUIMediator:RecoverHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.inCityOnlyShowRes, true)
end

function CityWorkCollectUIMediator:MoveCameraToFocusTarget()
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

function CityWorkCollectUIMediator:DefaultSelectFirst()
    if self.recipesTableDataSrc and #self.recipesTableDataSrc > 0 then
        for i, v in ipairs(self.recipesTableDataSrc) do
            if not v.isEmpty then
                g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_COLLECT_SELECT_RECIPE, v)
                return
            end
        end
    end
end

function CityWorkCollectUIMediator:RecoverCamera()
    if self.cameraStackHandle then
        self.cameraStackHandle:back()
        self.cameraStackHandle = nil
    end
end

function CityWorkCollectUIMediator:InitStaticInfo()
    self._p_text_building_name.text = I18N.Get(self.workCfg:Name())
end

function CityWorkCollectUIMediator:InitCitizenComponent()
    if not self:HasCitizenWorking() then
        if self.param.autoAssignFreeCitizen then
            local pos = self.cellTile:GetWorldCenter()
            local freeCitizen = self.city.cityCitizenManager:GetFreeCitizen(pos)
            if freeCitizen then
                self.citizenId = freeCitizen._data._id
            end
        else
            self.citizenId = nil
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
    self._p_btn_resident_root:FeedData(self.citizenBlockData)
    self._p_resident_root:FeedData(self.citizenBlockData)
end

function CityWorkCollectUIMediator:OnCitizenSelectedChanged(citizenId)
    --- 选的同一个人，直接返回
    if citizenId == self.citizenId then
        return true
    end
    
    local workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.FurnitureResCollect] or 0
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

function CityWorkCollectUIMediator:SelectCitizen(citizenId)
    self.citizenBlockData.citizenId = citizenId
    self._p_btn_resident_root:FeedData(self.citizenBlockData)
    self._p_resident_root:FeedData(self.citizenBlockData)
    self.citizenId = citizenId
    self:UpdateWorkAttributes()
    if not self.isWorking and self._select ~= nil then
        -- self:UpdateTimerPreview()
    end

    if self.citizenId == nil then
        self._p_content_right:ApplyStatusRecord(RightPanelStatus.NotSelectCitizen)
    elseif self._select then
        self._p_content_right:ApplyStatusRecord(RightPanelStatus.SelectedRecipe)
    else
        self._p_content_right:ApplyStatusRecord(RightPanelStatus.NotSelectRecipe)
    end
    
    self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5)
    if self.citizenId ~= nil then
        self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom6)
    end
end

function CityWorkCollectUIMediator:InitWorkStatus()
    self:UpdateIsWorking()
    if self.isWorking then
        self.workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.FurnitureResCollect] or 0
        self.workData = self.city.cityWorkManager:GetWorkData(self.workId)
    else
        self.workId, self.workData = nil, nil
    end
end

function CityWorkCollectUIMediator:InitAutoStatus()
    self.isAuto = false
    local castleFurniture = self.cellTile:GetCastleFurniture()
    for i, v in ipairs(castleFurniture.FurnitureCollectInfo) do
        if v.Auto then
            self.isAuto = true
            return
        end
    end
end

function CityWorkCollectUIMediator:UpdateIsWorking()
    local castleFurniture = self.cellTile:GetCastleFurniture()
    for i, v in ipairs(castleFurniture.FurnitureCollectInfo) do
        if not v.Finished then
            self.isWorking = true
            return
        end
    end
    self.isWorking = false
end

function CityWorkCollectUIMediator:HasCitizenWorking()
    return self.isWorking and self.workData ~= nil and self.workData.CitizenId ~= 0
end

function CityWorkCollectUIMediator:UpdateWorkAttributes()
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

function CityWorkCollectUIMediator:InitRecipeTable()
    ---@type table<number, CityWorkCollectUIRecipeData|CityWorkCollectUIRecipeSubData>
    self.recipesTableDataSrc = {}
    for i, v in ipairs(self.param:GetRecipes()) do
        local resType = v:CollectResType()
        local count = self:GetResCountByType(resType)
        local subData = self:GetExpandedSubData(resType)
        table.insert(self.recipesTableDataSrc, {recipe = v, resType = resType, count = count, subData = subData})
    end

    self._p_table_item:Clear()
    for i, v in ipairs(self.recipesTableDataSrc) do
        self._p_table_item:AppendData(v, 0)
    end
end

function CityWorkCollectUIMediator:GetResCountByType(resType)
    return self.city.elementManager:GetElementResourceCountByType(resType)
end

---@return CityWorkCollectUIRecipeSubData
function CityWorkCollectUIMediator:GetExpandedSubData(resType)
    local data = {}
    data.eleResArray = CityUtils.GetElementResourceCfgsByType(resType)
    data.expanded = false
    return data
end

function CityWorkCollectUIMediator:GetOutputByResType(resType)
    if self.outputCache[resType] ~= nil then
        return self.outputCache[resType]
    end

    local eleResArray = CityUtils.GetElementResourceCfgsByType(resType)
    local itemMap = {}
    self.outputCache[resType] = {}
    
    for _, v in ipairs(eleResArray) do
        local itemGroup = ConfigRefer.ItemGroup:Find(v:Reward())
        if itemGroup then
            for i = 1, math.min(itemGroup:ItemNum(), itemGroup:ItemGroupInfoListLength()) do
                local itemInfo = itemGroup:ItemGroupInfoList(i)
                itemMap[itemInfo:Items()] = true
            end
        end
    end

    for id, flag in pairs(itemMap) do
        local itemCfg = ConfigRefer.Item:Find(id)
        table.insert(self.outputCache[resType], itemCfg)
    end

    table.sort(self.outputCache[resType], function(l, r)
        if l:Quality() == r:Quality() then
            return l:Id() < r:Id()
        end
        return l:Quality() > r:Quality()
    end)

    return self.outputCache[resType]
end

---@param data CityWorkCollectUIRecipeData
function CityWorkCollectUIMediator:InsertSubDataForDetails(data)
    for i, v in ipairs(self.recipesTableDataSrc) do
        if v == data then
            table.insert(self.recipesTableDataSrc, i, v.subData)
            self._p_table_item:InsertData(i, v.subData, 1)
            return
        end
    end
end

---@param data CityWorkCollectUIRecipeData
function CityWorkCollectUIMediator:RemoveSubData(data)
    for i, v in ipairs(self.recipesTableDataSrc) do
        if v == data.subData then
            table.remove(self.recipesTableDataSrc, i)
            self._p_table_item:RemAt(i)
            return
        end
    end
end

function CityWorkCollectUIMediator:TryMakeRecipesFullFillAtLeastTwoLine(srcArray)
    local oneLineCellCount = self._p_table_item:GetCountInOneLine(0)
    if oneLineCellCount < 0 then return end

    local srcArrayCount = #srcArray
    if srcArrayCount <= oneLineCellCount * 2 then
        for i = srcArrayCount + 1, oneLineCellCount * 2 do
            table.insert(srcArray, {recipe = nil, eleResCfg = nil, isEmpty = true})
        end
        return
    end

    local remainCount = srcArrayCount % oneLineCellCount
    if remainCount == 0 then return end

    for i = remainCount + 1, oneLineCellCount do
        table.insert(srcArray, {recipe = nil, eleResCfg = nil, isEmpty = true})
    end
end

---@param data CityWorkCollectUIRecipeData
function CityWorkCollectUIMediator:OnRecipeSelected(data)
    if data == nil or data.recipe == nil then return end

    self._select = data
    self.times = nil

    
    if self.citizenId ~= nil then
        self._p_content_right:ApplyStatusRecord(RightPanelStatus.SelectedRecipe)
    end
    self:UpdateQuantitySlider()
    -- self:UpdateTimerPreview()
    self:UpdateButtonStatus()
end

function CityWorkCollectUIMediator:OnCitizenDataRefresh(city, needRefreshCitizenId)
    if self.city ~= city then return end
    
    if self.citizenId == nil then return end
    if needRefreshCitizenId[self.citizenId] then
        self._p_resident_root:FeedData(self.citizenBlockData)
        self._p_btn_resident_root:FeedData(self.citizenBlockData)
    end
end

---@param city City
function CityWorkCollectUIMediator:OnCastleFurnitureChanged(city, batchEvt)
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
        self:UpdateIsWorking()
        self:InitAutoStatus()
        self:UpdateWorkingQueue()
        self:UpdateButtonStatus()
    end
end

function CityWorkCollectUIMediator:GetSelectedRecipe()
    return self._select and self._select.recipe
end

function CityWorkCollectUIMediator:UpdateQuantitySlider()
    local maxTimes = CityWorkFormula.GetQueueCapacity(self.workCfg, nil, self.furnitureId, self.citizenId)
    local realMaxTimes = math.min(self._select.count, maxTimes)
    self.times = realMaxTimes > 0 and 1 or 0
    ---@type CommonNumberSliderData
    self.sliderData = self.sliderData or {}
    self.sliderData.maxNum = maxTimes
    self.sliderData.minNum = realMaxTimes > 0 and 1 or 0
    self.sliderData.curNum = realMaxTimes > 0 and 1 or 0
    self.sliderData.callBack = Delegate.GetOrCreate(self, self.OnSliderValueChanged)
    self._p_set_num_bar:FeedData(self.sliderData)
    self._p_input_box_click.text = tostring(self.times)
    self._p_text_input_quantity.text = ("/%d"):format(maxTimes)
end

function CityWorkCollectUIMediator:OnSliderValueChanged(curCount)
    self._p_input_box_click.text = tostring(curCount)

    self.times = curCount
    self.sliderData.curNum = curCount
    -- self:UpdateTimerPreview()
    self:UpdateButtonStatus()
end

function CityWorkCollectUIMediator:UpdateTimerPreview()
    ---@type CommonTimerData
    self.timerData = self.timerData or {}
    self.timerData.needTimer = false

    local singleTimeCost = CityWorkFormula.CalculateFinalTimeCost(self.workCfg, ConfigTimeUtility.NsToSeconds(self._select.eleResCfg:CollectTime()) * self._select.eleResCfg:CollectCount(), self._select.eleResCfg:Difficulty(), nil, self.furnitureId, self.citizenId)
    local totalTimeCost = math.ceil(singleTimeCost * self.times)
    self.timerData.fixTime = totalTimeCost
    self._child_time:FeedData(self.timerData)
end

function CityWorkCollectUIMediator:UpdateButtonStatus()
    self._child_comp_btn_b_l:SetVisible(not self.isAuto)
    self.cantStartReason = self:GetButtonStatus()
    self.canStart = self.cantStartReason == 0
    if not self.isAuto then
        UIHelper.SetGray(self._child_comp_btn_b_l.gameObject, not self.canStart)
    end
    self._p_status_n:SetActive(not self.isAuto)
    self._p_status_select:SetActive(self.isAuto)
    self._p_group_quantity:SetActive(not self.isAuto)
end

function CityWorkCollectUIMediator:GetButtonStatus()
    local queueCount = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if queueCount == 0 then
        return 1
    end

    local activeQueue = self.cellTile:GetCastleFurniture().FurnitureCollectInfo:Count()
    if activeQueue >= queueCount then
        return 2
    end

    if not self._select then return 3 end
    if self._select.count <= 0 then return 4 end

    if self.times <= 0 then return 5 end
    
    local castleFurniture = self.cellTile:GetCastleFurniture()
    local collectType = CityWorkType.FurnitureResCollect
    local workData = self.city.cityWorkManager:GetWorkData(castleFurniture.WorkType2Id[collectType])
    if castleFurniture.WorkType2Id[collectType] ~= nil and workData ~= nil and workData.ConfigId ~= self.workCfg:Id() then
        return 6
    end

    local sameWorkTypeCount = self.city.cityWorkManager:GetWorkingCountByType(self.workCfg:Type())
    local maxSameWorkTypeCount = CityWorkFormula.GetTypeMaxQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if sameWorkTypeCount >= maxSameWorkTypeCount then
        return 7
    end

    return 0
end

function CityWorkCollectUIMediator:UpdateWorkingQueue()
    local castleFurniture = self.cellTile:GetCastleFurniture()
    local collectInfoArray = castleFurniture.FurnitureCollectInfo
    self.collecting, self.inqueue, self.finished = CityWorkCollectWdsHelper.GetCollecting_InQueue_FinishedPart(collectInfoArray)
    self:UpdateBubble()
    self:UpdateQueueNew()
end

function CityWorkCollectUIMediator:UpdateBubble()
    self._p_btn_bubble:SetVisible(false)
    -- if self.collecting then
    --     self._p_btn_bubble:ApplyStatusRecord(BubbleStatus.Collecting)
    --     self:OnCollectingTimerSecondTick()
    --     self:TryStartTimer()

    --     local eleResCfg = ConfigRefer.CityElementResource:Find(self.collecting.ResourceType)
    --     local itemGroup = ConfigRefer.ItemGroup:Find(eleResCfg:Reward())
    --     local item = ConfigRefer.Item:Find(itemGroup:ItemGroupInfoList(1):Items())
    --     g_Game.SpriteManager:LoadSprite(item:Icon(), self._p_icon_item)

    --     if self.bubbleWorking == false then
    --         self._vx_trigger_bubble:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    --     end

    --     self.bubbleWorking = true
    -- else
    --     self._p_btn_bubble:ApplyStatusRecord(BubbleStatus.Free)
    --     self:TryStopTimer()
    --     self.bubbleWorking = false
    -- end
end

function CityWorkCollectUIMediator:TryStartTimer()
    if self._collectingSecTimer then return end

    self._collectingSecTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.OnCollectingTimerSecondTick), 1, -1)
    self._collectingFrameTicker = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnCollectingTimerTick), 1, -1)
end

function CityWorkCollectUIMediator:TryStopTimer()
    if not self._collectingSecTimer then return end

    TimerUtility.StopAndRecycle(self._collectingSecTimer)
    TimerUtility.StopAndRecycle(self._collectingFrameTicker)
    self._collectingSecTimer = nil
    self._collectingFrameTicker = nil
end

function CityWorkCollectUIMediator:GetWorkData()
    local castleFurnitures = self.city:GetCastle().CastleFurniture
    local castleFurniture = castleFurnitures[self.furnitureId]
    if castleFurniture == nil then return nil end

    local workId = castleFurniture.WorkType2Id[CityWorkType.FurnitureResCollect]
    if workId == nil then return nil end

    return self.city.cityWorkManager:GetWorkData(workId)
end

function CityWorkCollectUIMediator:OnCollectingTimerSecondTick()
    local workData = self.collecting
    if workData == nil then return end

    local endTime = workData.FinishTime.ServerSecond
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local remainTime = math.max(0, endTime - nowTime)
    self._p_text_time_bubble.text = TimeFormatter.SimpleFormatTimeWithoutHour(remainTime)
end

function CityWorkCollectUIMediator:OnCollectingTimerTick()
    local workData = self.collecting
    if workData == nil then return end

    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local passTime = math.max(0, nowTime - workData.StartTime.ServerSecond)
    local percent = math.clamp01(passTime / (workData.FinishTime.ServerSecond - workData.StartTime.ServerSecond))
    self._p_progress.fillAmount = percent
end

function CityWorkCollectUIMediator:UpdateQueue()
    self._p_table:Clear()

    local queueCount = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if queueCount == 0 then return end

    local showQueueCount = queueCount
    if self.collecting ~= nil then
        showQueueCount = showQueueCount - 1
    end

    local idx = 0
    for _, v in ipairs(self.inqueue) do
        idx = idx + 1
        if self.unitDataCaches[idx] == nil then
            self.unitDataCaches[idx] = CityWorkCollectUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId))
        end
        self.unitDataCaches[idx]:SetInQueue(v)
        self._p_table:AppendData(self.unitDataCaches[idx])
    end
    for _, v in ipairs(self.finished) do
        idx = idx + 1
        if self.unitDataCaches[idx] == nil then
            self.unitDataCaches[idx] = CityWorkCollectUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId))
        end
        self.unitDataCaches[idx]:SetFinished(v)
        self._p_table:AppendData(self.unitDataCaches[idx])
    end

    for i = idx + 1, showQueueCount do
        if self.unitDataCaches[i] == nil then
            self.unitDataCaches[i] = CityWorkCollectUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId))
        end
        self.unitDataCaches[i]:SetFree()
        self._p_table:AppendData(self.unitDataCaches[i])
    end
end

function CityWorkCollectUIMediator:UpdateQueueNew()
    local queueCount = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if queueCount == 0 then return end

    local castleFurniture = self.cellTile:GetCastleFurniture()
    local collectInfoArray = castleFurniture.FurnitureCollectInfo
    local collectCount = collectInfoArray:Count()
    for i = 1, queueCount do
        local isNew = self.unitDataCaches[i] == nil
        if isNew then
            self.unitDataCaches[i] = CityWorkCollectUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId), self)
        end

        if i <= collectCount then
            local info = collectInfoArray[i]
            if info == self.collecting then
                self.unitDataCaches[i]:SetWorking(info)
            elseif info.Finished then
                self.unitDataCaches[i]:SetFinished(info)
            else
                self.unitDataCaches[i]:SetInQueue(info)
            end
        else
            if self.isAuto then
                self.unitDataCaches[i]:SetForbid()
            else
                self.unitDataCaches[i]:SetFree()
            end
        end

        if isNew then
            self._p_table:AppendData(self.unitDataCaches[i])
        else
            self._p_table:UpdateChild(self.unitDataCaches[i])
        end
    end
end

function CityWorkCollectUIMediator:OnClickGear()
    ---@type TextToastMediatorParameter
    if not self.toastData then
        self.toastData = {}
        self.toastData.clickTransform = self._p_btn_efficiency.transform
    end
    local power = CityWorkFormula.GetWorkPower(self.workCfg, nil, self.furnitureId, self.citizenId)
    self.toastData.content = I18N.GetWithParams("sys_city_16", power)
    ModuleRefer.ToastModule:ShowTextToast(self.toastData)
end

function CityWorkCollectUIMediator:OnClickExit()
    self:CloseSelf()
end

function CityWorkCollectUIMediator:OnSubmit(value)
    local number = checknumber(value)
    local clampNumber = math.clamp(number, self.sliderData.minNum, self.sliderData.maxNum)
    self:OnSliderValueChanged(clampNumber)
end

function CityWorkCollectUIMediator:OnClickDetails()
    ---TODO
end

function CityWorkCollectUIMediator:OnClickStart(lockable, isAuto)
    if not self.canStart then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(CantStartReason[self.cantStartReason]))
        return
    end

    if lockable == nil then
        lockable = self._child_comp_btn_b_l.transform
    end

    if isAuto == nil then
        isAuto = self.isAuto
    end

    self.city.cityWorkManager:StartCollectWork(self.workCfg:Id(), self.furnitureId, self.citizenId or 0, self._select.recipe:Id(), self.times, isAuto, lockable
        ,Delegate.GetOrCreate(self, self.TryStartGuide)
        ,Delegate.GetOrCreate(self, self.OnSimpleError))
end

function CityWorkCollectUIMediator:TryStartGuide()
    local guideCfgId = self.workCfg:GuideOnStart()
    if guideCfgId > 0 then
        ModuleRefer.GuideModule:CallGuide(guideCfgId)
    end
end

function CityWorkCollectUIMediator:OnSimpleError(msgId, errorCode, jsonTable)
    if errorCode == 46016 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("sys_city_79"))
    end
end

---@param info wds.CastleFurnitureCollectInfo
function CityWorkCollectUIMediator:RequestCollect(info, lockable)
    local infos = self.cellTile:GetCastleFurniture().FurnitureCollectInfo
    local index = table.indexof(infos, info)
    if index <= 0 then return end

    self.city.cityWorkManager:RequestCollectProcessLike(self.furnitureId, index-1, self.workCfg:Id(), lockable)
end

function CityWorkCollectUIMediator:RequestCancel(info, lockable)
    local infos = self.cellTile:GetCastleFurniture().FurnitureCollectInfo
    local index = table.indexof(infos, info)
    if index <= 0 then return end

    self.city.cityWorkManager:RemoveCollectProcess(self.furnitureId, index-1, lockable)
end

function CityWorkCollectUIMediator:OnClickBubble()
    if self.collecting then
        self._p_btn_reduce:SetVisible(true)
    end
end

function CityWorkCollectUIMediator:OnClickCancelCurrent()
    if not self.collecting then return end

    self:RequestCancel(self.collecting, self._p_btn_reduce.transform)
end

function CityWorkCollectUIMediator:OnUITouchUp(gameObj)
    if self._p_bubble_btn.gameObject == gameObj then
        return
    end
    self._p_btn_reduce:SetVisible(false)
end

---@param evtInfo {Event:string, Add:table<number, boolean>, Remove:table<number, boolean>, Change:table<number, boolean>}
function CityWorkCollectUIMediator:OnElementCountChange(evtInfo)
    if not self.recipesTableDataSrc then return end

    for i, v in ipairs(self.recipesTableDataSrc) do
        v.count = self:GetResCountByType(v.resType)
        ---@type CityWorkCollectUIRecipeItem
        local cell = self._p_table_item:LuaGetCell(i-1)
        if cell ~= nil and cell.IsMainCell and cell:IsMainCell() then
            cell:UpdateCount()
        end
    end

    self:UpdateButtonStatus()
end

function CityWorkCollectUIMediator:OnCastleAttrChanged()
    self:UpdateWorkAttributes()
    if not self.isWorking and self._select ~= nil then
        -- self:UpdateTimerPreview()
    end
    self:UpdateButtonStatus()
end

function CityWorkCollectUIMediator:CanAddOrChangeCitizen()
    return not self.isWorking or self.citizenId == nil
end

function CityWorkCollectUIMediator:OnClickSliderMax()
    local maxTimes = CityWorkFormula.GetQueueCapacity(self.workCfg, nil, self.furnitureId, self.citizenId)
    local maxCount = maxTimes
    if self._select then
        maxCount = math.min(self._select.count, maxTimes)
    end
    self._p_set_num_bar:ChangeCurNum(maxCount)
    self:OnSliderValueChanged(maxCount)
end

function CityWorkCollectUIMediator:OnClickAuto()
    if not self.isAuto then
        self:OnClickStart(self._p_btn_pading.transform, true)
    else
        self:RequestRemoveAutoCollect(self._p_btn_pading.transform)
    end
end

function CityWorkCollectUIMediator:RequestRemoveAutoCollect(lockable)
    local castleFurniture = self.cellTile:GetCastleFurniture()
    for i, v in ipairs(castleFurniture.FurnitureCollectInfo) do
        if v.Auto then
            self.city.cityWorkManager:RemoveCollectProcess(self.furnitureId, i-1, lockable)
            return
        end
    end
end

return CityWorkCollectUIMediator