---Scene Name : scene_city_popup_process
local CityCommonRightPopupUIMediator = require ('CityCommonRightPopupUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityProcessV2I18N = require("CityProcessV2I18N")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local I18N = require("I18N")
local FunctionClass = require("FunctionClass")
local UIStatusEnum = require("CityProcessV2UIStatusEnum")
local ItemGroupHelper = require("ItemGroupHelper")
local CityWorkUICostItemData = require("CityWorkUICostItemData")
local CastleStartWorkParameter = require("CastleStartWorkParameter")
local CityMaterialProcessRecipeData = require("CityMaterialProcessRecipeData")
local CastleGetProcessOutputParameter = require("CastleGetProcessOutputParameter")
local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")
local EventConst = require("EventConst")

---@class CityProcessV2UIMediator:CityCommonRightPopupUIMediator
local CityProcessV2UIMediator = class('CityProcessV2UIMediator', CityCommonRightPopupUIMediator)

function CityProcessV2UIMediator:OnCreate()
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_focus_target = self:Transform("p_focus_target")
    self._btn_exit = self:Button("btn_exit", Delegate.GetOrCreate(self, self.CloseSelf))

    ---@type CityProcessV2UINormalRecipeList 普通道具消耗列表
    self._p_group_item = self:LuaObject("p_group_item")

    ---@type CityProcessV2UIFurnitureRecipeList 家具制造列表
    self._p_group_furniture = self:LuaObject("p_group_furniture")

    ---右侧界面
    self._p_group_right = self:StatusRecordParent("p_group_right")

    ---工作名
    self._p_text_property_name = self:Text("p_text_property_name")
    ---所需feature
    self._p_btn_type = self:Button("p_btn_type", Delegate.GetOrCreate(self, self.OnClickFeature))
    self._p_text_type = self:Text("p_text_type", CityProcessV2I18N.UIHint_NeedFeature)
    self._p_icon_type = self:Image("p_icon_type")
    self._pool_feature = LuaReusedComponentPool.new(self._p_icon_type, self._p_btn_type.transform)

    ---配方细节
    self._group_item = self:GameObject("group_item")
    ---配方图标
    self._p_icon = self:Image("p_icon")
    ---配方/产物名字
    self._p_text_item = self:Text("p_text_item")
    ---某种信息的图标表示
    self._p_icon_detail = self:Image("p_icon_detail")
    ---某种信息的文字表示
    self._p_text_item_detail = self:Text("p_text_item_detail")
    ---配方描述
    self._p_text_desc = self:Text("p_text_desc")

    self._p_title_need = self:GameObject("p_title_need")
    self._p_text_title = self:Text("p_text_title")

    ---@see CityWorkUICostItem
    self._p_table_need = self:TableViewPro("p_table_need")

    ---材料加工消耗列表
    ---@see CityMaterialProcessRecipe
    self._p_table_plan = self:TableViewPro("p_table_plan")

    ---条件不足时的提示
    self._p_condition_vertical = self:Transform("p_condition_vertical")
    self._p_title_condition = self:GameObject("p_title_condition")
    self._p_text_condition = self:Text("p_text_condition", CityProcessV2I18N.UITitle_Condition)
    ---@type CityWorkUIConditionItem
    self._p_conditions = self:LuaBaseComponent("p_conditions")
    self._pool_condition = LuaReusedComponentPool.new(self._p_conditions, self._p_condition_vertical)

    ---订单选择
    self._p_group_num = self:GameObject("p_group_num")
    self._p_text_select = self:Text("p_text_select", CityProcessV2I18N.UITitle_CountSelect)
    ---订单最大重复数
    self._p_input_grade = self:Text("p_input_grade")
    self._p_input_box_click = self:InputField("p_input_box_click", nil, nil, Delegate.GetOrCreate(self, self.OnInputSubmit))
    ---@type CommonNumberSlider
    self._p_set_bar = self:LuaObject("p_set_bar")

    ---底部交互面板
    self._group_bottom = self:GameObject("group_bottom")
    ---耗时面板
    self._layout = self:GameObject("layout")
    ---如果存在时间减少时，初始的时间预览
    self._p_time_need_old = self:GameObject("p_time_need_old")
    ---@type CommonTimer
    self._child_time_editor_pre = self:LuaObject("child_time_editor_pre")
    ---当前耗时
    self._p_time_need = self:GameObject("p_time_need")
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")

    ---普通按钮
    self._btn_b = self:GameObject("btn_b")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")
    ---黄金大按钮
    self._btn_e = self:GameObject("btn_e")
    ---@type GoldenCostPreviewButton
    self._child_comp_btn_e_l = self:LuaObject("child_comp_btn_e_l")
    self._p_text_hint = self:Text("p_text_hint")

    self._p_progress = self:GameObject("p_progress")
    ---进度已完成的特效
    self._p_finish = self:GameObject("p_finish")
    ---生产配方图片
    self._p_icon_item = self:Image("p_icon_item")
    ---已生产次数
    self._p_text_number = self:Text("p_text_number")
    ---当次生产的进度
    self._p_progress_item = self:Image("p_progress_item")
    ---总进度条
    self._p_progress_n = self:Slider("p_progress_n")
    self._time = self:GameObject("time")
    ---生产配方名
    self._p_text_name = self:Text("p_text_name")
    ---@type CommonTimer
    self._child_time_progress = self:LuaObject("child_time_progress")
    ---取消生产
    self._p_btn_delect = self:Button("p_btn_delect", Delegate.GetOrCreate(self, self.OnClickCancel))

    ---@type PetAssignComponent
    self._p_pet_list = self:LuaObject("p_pet_list")
end

---@param param CityProcessV2UIParameter
function CityProcessV2UIMediator:OnOpened(param)
    self.param = param
    self.param:OnMediatorOpen(self)
    self.city = param.city

    local isMakingFurniture = param:IsMakingFurniture()
    self.isMakingFurniture = isMakingFurniture
    self._p_group_item:SetVisible(not isMakingFurniture)
    self._p_group_furniture:SetVisible(isMakingFurniture)
    
    if isMakingFurniture then
        self._p_group_furniture:FeedData({param = param})
    else
        self._p_group_item:FeedData({param = param})
    end

    self._p_text_property_name.text = param:GetWorkName()
    local features = self.param:NeedFeatureList()
    if features and #features > 0 then
        self._p_btn_type:SetVisible(true)
        self._pool_feature:HideAll()
        for i, feature in ipairs(features) do
            local image = self._pool_feature:GetItem()
            local icon = self.city.petManager:GetFeatureIcon(feature)
            g_Game.SpriteManager:LoadSprite(icon, image)
        end
    else
        self._p_btn_type:SetVisible(false)
    end

    if self.param:IsMakingMaterial() then
        self:OnMaterialRecipeSelect(self.param:GetFirstMaterialRecipeId())
    else
        self:OnRecipeSelect(self.param:GetFirstRecipeId())
    end

    CityCommonRightPopupUIMediator.OnOpened(self, param)
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
end

function CityProcessV2UIMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    CityCommonRightPopupUIMediator.OnClose(self, param)
    if self.param then
        self.param:OnMediatorClose(self)
    end
    self:UnbindItemCountChangeListeners()
    self:RemoveTicker()
end

function CityProcessV2UIMediator:OnMaterialRecipeSelect(convertCfgId, recipeId)
    local matProcessCfg = ConfigRefer.CityWorkMatConvertProcess:Find(convertCfgId)
    if matProcessCfg == nil then
        g_Logger.ErrorChannel("CityProcessV2UIMediator", "非法材料转化配方Id:[%d]", convertCfgId)
        return
    end
    self.matProcessCfg = matProcessCfg
    self:OnRecipeSelect(recipeId)
end

function CityProcessV2UIMediator:OnRecipeSelect(recipeId)
    local processCfg = ConfigRefer.CityWorkProcess:Find(recipeId)
    if not processCfg then
        g_Logger.ErrorChannel("CityProcessV2UIMediator", "非法配方Id:[%d]", recipeId)
        return
    end
    if self.processCfg ~= nil and self.processCfg:Id() ~= recipeId then
        self.lastNum = nil
    end
    self.processCfg = processCfg
    if self.isMakingFurniture then
        self._p_group_furniture:OnFeedData(self._p_group_furniture.data)
    else
        self._p_group_item:OnFeedData(self._p_group_item.data)
    end
    local outputItem = ConfigRefer.Item:Find(processCfg:Output())
    if outputItem then
        if self.param:IsFurnitureRecipe(processCfg) then
            local lvCfgId = checknumber(outputItem:UseParam(1))
            local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
            local typeCfg = ConfigRefer.CityFurnitureTypes:Find(lvCfg:Type())
            g_Game.SpriteManager:LoadSprite(typeCfg:Image(), self._p_icon)
            self._p_text_item.text = I18N.Get(typeCfg:Name())
        else
            g_Game.SpriteManager:LoadSprite(outputItem:Icon(), self._p_icon)
            self._p_text_item.text = I18N.Get(outputItem:NameKey())
        end

        local showFoodExtraInfo = outputItem:FunctionClass() == FunctionClass.AddFood
        self._p_icon_detail:SetVisible(showFoodExtraInfo)
        self._p_text_item_detail:SetVisible(showFoodExtraInfo)
        
        if showFoodExtraInfo then
            g_Game.SpriteManager:LoadSprite(self.param:GetFoodAddIcon(), self._p_icon_detail)
            self._p_text_item_detail.text = outputItem:UseParamLength() > 0 and outputItem:UseParam(1) or ""
        end
    end

    self._p_text_desc.text = I18N.Get(processCfg:Description())
    self:OnRecipeSelectUpdatePanel()
end

function CityProcessV2UIMediator:OnRecipeSelectUpdatePanel()
    if self.processCfg == nil then return end

    local uiStatus = self.param:GetUIStatusByRecipeId(self.processCfg:Id())
    self._p_group_right:ApplyStatusRecord(uiStatus)

    self:UnbindItemCountChangeListeners()
    self:RemoveTicker()
    if uiStatus == UIStatusEnum.NotWorking_Process then
        self._p_text_title.text = I18N.Get(CityProcessV2I18N.UITitle_Cost)
        self:UpdateCountSelect(self.lastNum)
        self:UpdateCostTableView()
        self:UpdateBottomNotStart()
    elseif uiStatus == UIStatusEnum.NotWorking_Convert then
        self._p_text_title.text = I18N.Get(CityProcessV2I18N.UITitle_SelectSolution)
        self:UpdateCountSelect(self.lastNum)
        self:UpdateMatProcessTableView()
        self:UpdateBottomNotStart()
    elseif uiStatus == UIStatusEnum.NotWorking_Locked then
        self:UpdateLocked()
    elseif uiStatus == UIStatusEnum.NotWorking_LimitNotReach then
        self:UpdateLimitNotReach()
    elseif uiStatus == UIStatusEnum.NotWorking_LimitReach then
        self:UpdateLimitReach()
    elseif uiStatus == UIStatusEnum.Working_Undergoing then
        self:UpdateProcessing()
    elseif uiStatus == UIStatusEnum.Working_Finished then
        self:UpdateFinished()
    end
end

function CityProcessV2UIMediator:GetWorldTargetPos()
    return self.param:GetWorldTargetPos()
end

function CityProcessV2UIMediator:GetFocusAnchor()
    return self._p_focus_target
end

function CityProcessV2UIMediator:GetBasicCamera()
    return self.city:GetCamera()
end

function CityProcessV2UIMediator:GetZoomSize()
    return self.param:GetZoomSize()
end

function CityProcessV2UIMediator:UnbindItemCountChangeListeners()
    if not self.inputList then return end

    for i, data in ipairs(self.inputList) do
        data:ReleaseCountListener()
    end
    self.inputList = nil
end

function CityProcessV2UIMediator:AddTicker()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityProcessV2UIMediator:RemoveTicker()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityProcessV2UIMediator:UpdateCostTableView()
    self._p_table_need:Clear()
    self:UnbindItemCountChangeListeners()
    
    local itemGroup = ConfigRefer.ItemGroup:Find(self.processCfg:Cost())
    if itemGroup == nil then return end

    local costArray, costMap = ItemGroupHelper.GetPossibleOutput(itemGroup)
    ---@type CityWorkUICostItemData[]|CityMaterialProcessRecipeData[]
    self.inputList = {}
    for _, cost in ipairs(costArray) do
        if cost.minCount == cost.maxCount then
            local data = CityWorkUICostItemData.new(cost.id, cost.maxCount, math.max(1, self._p_set_bar.curNum))
            self._p_table_need:AppendData(data)
            data:AddCountListener(Delegate.GetOrCreate(self, self.OnItemCountChange))
            table.insert(self.inputList, data)
        end
    end
end

function CityProcessV2UIMediator:UpdateMatProcessTableView()
    self._p_table_plan:Clear()
    self:UnbindItemCountChangeListeners()
    
    ---@type CityWorkUICostItemData[]|CityMaterialProcessRecipeData[]
    self.inputList = {}
    local selectedIndex = -1
    for i = 1, self.matProcessCfg:RecipesLength() do
        local recipeId = self.matProcessCfg:Recipes(i)
        local processCfg = ConfigRefer.CityWorkProcess:Find(recipeId)
        if processCfg and self.param:IsRecipeVisible(processCfg) then
            local data = CityMaterialProcessRecipeData.new(processCfg, self.param, math.max(1, self._p_set_bar.curNum))
            if data:IsValid() then
                self._p_table_plan:AppendData(data)
                data:AddCountListener(Delegate.GetOrCreate(self, self.OnMatProcessItemCountChange))
                table.insert(self.inputList, data)

                if self.param:IsRecipeSelected(processCfg:Id()) then
                    selectedIndex = i
                end
            end
        end
    end

    if selectedIndex > 0 then
        self._p_table_plan:SetDataVisable(selectedIndex - 1)
    end
end

function CityProcessV2UIMediator:OnItemCountChange()
    self._p_table_need:UpdateOnlyAllDataImmediately()
    self:UpdateCountSelect(self._p_set_bar.curNum)
    local uiStatus = self.param:GetUIStatusByRecipeId(self.processCfg:Id())
    if uiStatus == UIStatusEnum.NotWorking_Process or uiStatus == UIStatusEnum.NotWorking_Convert then
        self:UpdateBottomNotStart()
    end
end

function CityProcessV2UIMediator:OnMatProcessItemCountChange()
    self._p_table_plan:UpdateOnlyAllDataImmediately()
    self:UpdateCountSelect(self._p_set_bar.curNum)
    self:UpdateBottomNotStart()
    local uiStatus = self.param:GetUIStatusByRecipeId(self.processCfg:Id())
    if uiStatus == UIStatusEnum.NotWorking_Process or uiStatus == UIStatusEnum.NotWorking_Convert then
        self:UpdateBottomNotStart()
    end
end

function CityProcessV2UIMediator:UpdateCountSelect(curNum)
    local maxTimes = self.param:GetMaxTimes()
    self._p_input_grade.text = ("/%d"):format(maxTimes)
    local autoFull = self.param:AutoSelectFullTimes()
    ---@type CommonNumberSliderData
    self.sliderData = {
        minNum = maxTimes >= 1 and 1 or 0,
        maxNum = maxTimes,
        oneStepNum = 1,
        curNum = autoFull and maxTimes or (maxTimes >= 1 and 1 or 0),
        callBack = Delegate.GetOrCreate(self, self.OnSliderValueChanged),
    }

    if curNum then
        self.sliderData.curNum = math.clamp(curNum, self.sliderData.minNum, self.sliderData.maxNum)
    end

    self.lastNum = self.sliderData.curNum
    self._p_set_bar:FeedData(self.sliderData)
    self._p_input_box_click.text = tostring(self.sliderData.curNum)
end

---@private
---@param curNum number
function CityProcessV2UIMediator:OnSliderValueChanged(curNum)
    self.lastNum = curNum
    self._p_input_box_click.text = tostring(curNum)
    if self.inputList then
        for i, v in ipairs(self.inputList) do
            v:UpdateTimes(math.max(1, self._p_set_bar.curNum))
        end
    end
    self._p_table_need:UpdateOnlyAllDataImmediately()
    self._p_table_plan:UpdateOnlyAllDataImmediately()
    self:UpdateBottomNotStart()
end

---@private
---@param value string
function CityProcessV2UIMediator:OnInputSubmit(value)
    local num = tonumber(value)
    if num then
        local finalValue = math.clamp(num, self._p_set_bar.minNum, self._p_set_bar.maxNum)
        self._p_set_bar:ChangeCurNum(finalValue)
        self:OnSliderValueChanged(finalValue)
    else
        self._p_input_box_click.text = tostring(self._p_set_bar.curNum)
    end
end

function CityProcessV2UIMediator:UpdateBottomNotStart()
    local showOld = self.param:IsAssignedPetReduceTime()
    self._p_time_need_old:SetActive(showOld)
    if showOld then
        local originalTime = self.param:GetOriginalCostTime() * self._p_set_bar.curNum
        self._child_time_editor_pre:FeedData({fixTime = math.ceil(originalTime), needTimer = false})
    end
    local realTime = self.param:GetRealCostTime() * self._p_set_bar.curNum
    self._child_time:FeedData({fixTime = math.ceil(realTime), needTimer = false})
    local isAssignedPet = self.param:IsAssignedPet()
    ---@type BistateButtonParameter
    local buttonData = {
        onClick = isAssignedPet and Delegate.GetOrCreate(self, self.OnClickStart) or Delegate.GetOrCreate(self, self.OnClickAssignPet),
        buttonText = I18N.Get(CityProcessV2I18N.UIButton_Start),
        disableClick = isAssignedPet and Delegate.GetOrCreate(self, self.OnClickStart) or Delegate.GetOrCreate(self, self.OnClickAssignPet),
        disableButtonText = I18N.Get(CityProcessV2I18N.UIButton_Start),
    }
    self._child_comp_btn_b:FeedData(buttonData)
    self._child_comp_btn_b:SetEnabled(true)

    ---@type GoldenCostPreviewButtonData
    local buttonData = {
        onClick = Delegate.GetOrCreate(self, self.OnClickFinishImmediately),
        buttonText = I18N.Get(CityProcessV2I18N.UIButton_QuickMaking),
        costInfo = {
            icon = ModuleRefer.ConsumeModule:GetSpeedUpCommonItemCfg():Icon(),
            need = ModuleRefer.ConsumeModule:CalculateFurnitureLevelUpCost(realTime),
            own = ModuleRefer.ConsumeModule:GetOwnedConsumeCoin()
        },    
    }
    self._child_comp_btn_e_l:FeedData(buttonData)

    local petAssignData = self.param:GetPetAssignData()
    if petAssignData.slotCount == 0 then
        local furnitureId = self.param.cellTile:GetCell().singleId
        g_Logger.ErrorChannel("属性异常", "furnitureId:%d", furnitureId)
        local castle = self.city:GetCastle()
        local castleAttrMap = castle.CastleAttribute
        local furnitureAttrMap = castleAttrMap.FurnitureAttr[furnitureId]
        if not furnitureAttrMap then
            g_Logger.ErrorChannel("属性异常", "furnitureAttrMap is nil")
        else
            g_Logger.ErrorChannel("属性异常", FormatTable(furnitureAttrMap))
        end

        g_Game.ModuleManager:RemoveModule("CastleAttrModule")
        g_Game.ModuleManager:RetrieveModule("CastleAttrModule")
    end

    local petAssignData = self.param:GetPetAssignData()
    if petAssignData.slotCount == 0 then
        g_Logger.ErrorChannel("属性异常", "重载CastleAttrModule之后, petAssignData.slotCount == 0")
    end

    self._p_pet_list:FeedData(petAssignData)
end

function CityProcessV2UIMediator:OnClickStart(clickData, transform)
    if not self.param:IsMaterialEnough() then
        self.param:OpenExchangePanel()
        return
    end

    local workerIds = self._p_pet_list:GetAssignedPetId()
    self.param:RequestStartWork(transform, workerIds, self._p_set_bar.curNum)
end

function CityProcessV2UIMediator:OnClickAssignPet(clickData, transform)
    if not self.param:IsMaterialEnough() then
        self.param:OpenExchangePanel()
        return
    end

    self.param:OpenAssignPopupUI(transform)
end

function CityProcessV2UIMediator:UpdateLocked()
    self._pool_condition:HideAll()
    for i = 1, self.processCfg:EffectiveConditionLength() do
        local taskId = self.processCfg:EffectiveCondition(i)
        local state = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
        if state ~= wds.TaskState.TaskStateFinished and state ~= wds.TaskState.TaskStateCanFinish then
            local condition = self._pool_condition:GetItem()
            condition:FeedData({cfg = ConfigRefer.Task:Find(taskId)})
        end
    end
    self._p_text_hint.text = I18N.Get("animal_work_interface_desc01")
end

function CityProcessV2UIMediator:UpdateLimitNotReach()
    self._pool_condition:HideAll()

    for i, v in ipairs(self.param:GetFurnitureOwnCountUpTasks(self.processCfg)) do
        local condition = self._pool_condition:GetItem()
        condition:FeedData({cfg = ConfigRefer.Task:Find(v)})
    end
    self._p_text_hint.text = I18N.Get("animal_work_interface_desc14")
end

function CityProcessV2UIMediator:UpdateLimitReach() 
    self._pool_condition:HideAll()
    self._p_text_hint.text = I18N.Get("animal_work_interface_desc13")
end

function CityProcessV2UIMediator:UpdateProcessing()
    local processCfg = self.param:GetUndergoingProcessCfg()
    local itemCfg = ConfigRefer.Item:Find(processCfg:Output())
    g_Game.SpriteManager:LoadSprite(CityWorkProcessWdsHelper.GetOutputIcon(processCfg), self._p_icon_item)
    
    self._p_text_number.text = tostring(self.param:GetFinishedTimes())
    self._p_text_name.text = I18N.Get(itemCfg:NameKey())

    ---@type GoldenCostPreviewButtonData
    local buttonData = {
        onClick = Delegate.GetOrCreate(self, self.OnClickSpeedUp),
        buttonText = I18N.Get(CityProcessV2I18N.UIButton_SpeedUp),
    }
    self._child_comp_btn_e_l:FeedData(buttonData)
    
    local petAssignData = self.param:GetPetAssignData()
    if petAssignData.slotCount == 0 then
        local furnitureId = self.param.cellTile:GetCell().singleId
        g_Logger.ErrorChannel("属性异常", "furnitureId:%d", furnitureId)
        local castle = self.city:GetCastle()
        local castleAttrMap = castle.CastleAttribute
        local furnitureAttrMap = castleAttrMap.FurnitureAttr[furnitureId]
        if not furnitureAttrMap then
            g_Logger.ErrorChannel("属性异常", "furnitureAttrMap is nil")
        else
            g_Logger.ErrorChannel("属性异常", FormatTable(furnitureAttrMap))
        end

        g_Game.ModuleManager:RemoveModule("CastleAttrModule")
        g_Game.ModuleManager:RetrieveModule("CastleAttrModule")
    end

    local petAssignData = self.param:GetPetAssignData()
    if petAssignData.slotCount == 0 then
        g_Logger.ErrorChannel("属性异常", "重载CastleAttrModule之后, petAssignData.slotCount == 0")
    end

    self._p_pet_list:FeedData(petAssignData)

    self:UpdateProcessingTick()
    self:AddTicker()
end

function CityProcessV2UIMediator:UpdateProcessingTick()
    self._p_progress_item.fillAmount = self.param:GetSingleOutputProgress()
    self._p_progress_n.value = self.param:GetTotalOutputProgress()
    ---@type CommonTimerData
    self._progressTimeData = self._progressTimeData or {needTimer = false}
    self._progressTimeData.fixTime = self.param:GetProcessingRemainTime()
    self._child_time_progress:SetVisible(true)
    self._child_time_progress:FeedData(self._progressTimeData)
end

function CityProcessV2UIMediator:UpdateFinished()
    local processCfg = self.param:GetUndergoingProcessCfg()
    local itemCfg = ConfigRefer.Item:Find(processCfg:Output())
    g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self._p_icon_item)
    self._p_text_number.text = tostring(self.param:GetFinishedTimes())
    self._p_text_name.text = I18N.Get(itemCfg:NameKey())

    self._p_progress_item.fillAmount = 1
    self._p_progress_n.value = self.param:GetTotalOutputProgress()
    self._child_time_progress:SetVisible(false)

    ---@type BistateButtonParameter
    local buttonData = {
        onClick = Delegate.GetOrCreate(self, self.OnClickClaim),
        buttonText = I18N.Get(CityProcessV2I18N.UIButton_Claim),
    }
    self._child_comp_btn_b:FeedData(buttonData)

    local petAssignData = self.param:GetPetAssignData()
    if petAssignData.slotCount == 0 then
        local furnitureId = self.param.cellTile:GetCell().singleId
        g_Logger.ErrorChannel("属性异常", "furnitureId:%d", furnitureId)
        local castle = self.city:GetCastle()
        local castleAttrMap = castle.CastleAttribute
        local furnitureAttrMap = castleAttrMap.FurnitureAttr[furnitureId]
        if not furnitureAttrMap then
            g_Logger.ErrorChannel("属性异常", "furnitureAttrMap is nil")
        else
            g_Logger.ErrorChannel("属性异常", FormatTable(furnitureAttrMap))
        end

        g_Game.ModuleManager:RemoveModule("CastleAttrModule")
        g_Game.ModuleManager:RetrieveModule("CastleAttrModule")
    end

    local petAssignData = self.param:GetPetAssignData()
    if petAssignData.slotCount == 0 then
        g_Logger.ErrorChannel("属性异常", "重载CastleAttrModule之后, petAssignData.slotCount == 0")
    end

    self._p_pet_list:FeedData(petAssignData)
end

function CityProcessV2UIMediator:OnTick(delta)
    self:UpdateProcessingTick()
end

function CityProcessV2UIMediator:OnFurnitureUpdate(city, batchEvt)
    if self.city ~= city then return end
    if not batchEvt.Change then return end
    if not batchEvt.Change[self.param.cellTile:GetCell().singleId] then return end
    
    self:OnRecipeSelectUpdatePanel()
end

function CityProcessV2UIMediator:OnClickClaim(clickData, rectTransform)
    self.param:RequestClaim(rectTransform)
end

function CityProcessV2UIMediator:OnClickSpeedUp()
    self.param:OpenSpeedUpPanel()
end

function CityProcessV2UIMediator:OnClickFinishImmediately(rectTransform)
    self.param:RequestFinishImmediately(self._p_set_bar.curNum, rectTransform)
end

function CityProcessV2UIMediator:OnClickCancel()
    self.param:RequestCancel(self._p_btn_delect.transform)
end

return CityProcessV2UIMediator