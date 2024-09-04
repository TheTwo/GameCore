---Scene Name : scene_construction_mode_old
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require("EventConst")
local CityConstructionUICellDataBuilding = require("CityConstructionUICellDataBuilding")
local CityConstructionUICellDataFurniture = require("CityConstructionUICellDataFurniture")
local CityConstructionUICellDataCustomRoom = require("CityConstructionUICellDataCustomRoom")
local CityConstructionUICellDataFloor = require("CityConstructionUICellDataFloor")
local CityFurnitureType = require("CityFurnitureType")
local CityUtils = require("CityUtils")
local CityConst = require("CityConst")
local Vector3 = CS.UnityEngine.Vector3
local ConfigRefer = require("ConfigRefer")
local NotificationType = require("NotificationType")
local UIHelper = require("UIHelper")
local CityConstructState = require("CityConstructState")
local CastleAddFurnitureParameter = require("CastleAddFurnitureParameter")
local CastleDelFurnitureParameter = require("CastleDelFurnitureParameter")
local I18N = require("I18N")
local CityConstructionBuildingToggleData = require("CityConstructionBuildingToggleData")
local CityConstructionFurnitureToggleData = require("CityConstructionFurnitureToggleData")
local CityConstructionDecorationToggleData = require("CityConstructionDecorationToggleData")
local CityConstructionRoomToggleData = require("CityConstructionRoomToggleData")
local FurnitureCategory = require("FurnitureCategory")
local CityConstructionModeUIParameter = require("CityConstructionModeUIParameter")

---@alias CityConstructionRoomModeData {header:CityConstructionUICellDataCustomRoom, list:table}

---@class CityConstructionModeUIMediator:BaseUIMediator
---@field btnBuilding CityConstructionToggleButton
---@field btnFurniture CityConstructionToggleButton
---@field btnRoom CityConstructionToggleButton
---@field viewedData CityConstructionUICellDataBuilding[]|CityConstructionUICellDataFurniture[]
---@field _p_group_tips CityConstructionUITip
local CityConstructionModeUIMediator = class('CityConstructionModeUIMediator', BaseUIMediator);

local State = {
    Furniture = 1,
    Decoration = 2,
    Room = 3,
    Building = 4,
}

local reverse_sort = function(l, r) return l > r end

---@return CityConstructionModeUIParameter
function CityConstructionModeUIMediator.GetParameter(state, subState, focusConfigId)
    local defaultState = state or State.Furniture
    local defaultSubState = subState or FurnitureCategory.Economy
    return CityConstructionModeUIParameter.new(defaultState, defaultSubState, focusConfigId)
end

CityConstructionModeUIMediator.TIPS_NORMAL = 1
CityConstructionModeUIMediator.TIPS_ALERT = 2

function CityConstructionModeUIMediator:OnCreate()
    self._p_hide_root = self:BindComponent("p_hide_root", typeof(CS.UnityEngine.CanvasGroup))
    self._p_group_toggle = self:GameObject("p_group_toggle")
    self._p_group_table = self:AnimTrigger("p_group_table")
    self._p_group_tips = self:LuaObject("p_group_tips")

    self._p_group_hint = self:GameObject("p_group_hint")
    self._p_base_alert = self:GameObject("p_base_alert")
    self._p_base_normal = self:GameObject("p_base_normal")
    self._p_icon_hint = self:Image("p_icon_hint")
    self._p_text_hint = self:Text("p_text_hint")

    -- self._p_text_new_1 = self:Text("p_text_new_1", "build_newitem")
    self._child_common_btn_back = self:LuaObject("child_common_btn_back")

    self._p_table_toggle_wide = self:TableViewPro("p_table_toggle_wide")
    self._p_table_view = self:TableViewPro("p_table_view");

    self._p_table_save = self:TableViewPro("p_table_save")
    self._p_btn_back = self:Button("p_btn_back", Delegate.GetOrCreate(self, self.OnHideStockView))

    -- self._p_group_save = self:GameObject("p_group_save")
    self._p_group_room = self:LuaBaseComponent("p_group_room")
    self._p_table_room = self:TableViewPro("p_table_room")
    self._p_btn_back_save = self:Button("p_btn_back_save", Delegate.GetOrCreate(self, self.OnExitRoomMode))

    self._p_sign_hang = self:BindComponent("p_sign_hang", typeof(CS.UnityEngine.Animation))
    self._p_text_name_sign = self:Text("p_text_name_sign")
    self._p_text = self:Text("p_text", "")

    self._p_sign_pick = self:BindComponent("p_sign_pick", typeof(CS.UnityEngine.Animation))
    self._p_text_name_old = self:Text("p_text_name_old")
    self._p_text_name_new = self:Text("p_text_name_new")
end

---@param param CityConstructionModeUIParameter
function CityConstructionModeUIMediator:OnOpened(param)
    self.param = param
    self.state = param.state
    self.subState = param.subState or 1
    self.viewStock = false
    self.roomBuildIdx = -1
    self.titleData = {title = ""}
    
    self._p_group_hint:SetVisible(false)
    -- self._p_group_save:SetVisible(false)
    -- self._p_table_view.gameObject:SetActive(not self.viewStock)
    self._p_table_save.gameObject:SetActive(self.viewStock)
    self._p_btn_back.gameObject:SetActive(self.viewStock)

    if self.param.building then
        self.titleData.title = self.param.building:GetBuildingName()
    else
        self.titleData.title = I18N.Get("menu_btn_build")
    end
    self._child_common_btn_back:FeedData(self.titleData)

    self._p_sign_hang.gameObject:SetActive(false)
    self._p_sign_pick.gameObject:SetActive(false)

    self:ActiveButtons()
    self:ProcessCustomData()
    self:InitialToggle()
    self:PostTableViewCreated()
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_UI_HIDE, Delegate.GetOrCreate(self, self.OnHideUI))
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_UI_SHOW, Delegate.GetOrCreate(self, self.OnRecoverUI))
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_CONTINUE_PLACE, Delegate.GetOrCreate(self, self.OnRecoverUIAndUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_UI_SHOW_ROOM_SUBPAGE, Delegate.GetOrCreate(self, self.OnEnterRoomMode))
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_UI_EXIT_ROOM_SUBPAGE, Delegate.GetOrCreate(self, self.OnExitRoomMode))
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_UI_ROOM_MOVE_STEP, Delegate.GetOrCreate(self, self.OnRoomBuildMoveStep))
    g_Game.EventManager:AddListener(EventConst.CITY_EDIT_MODE_PLAY_COMBO_LEVEL_UP, Delegate.GetOrCreate(self, self.OnFurnitureComboLevelUp))
    g_Game.EventManager:AddListener(EventConst.CITY_EDIT_MODE_PLAY_COMBO_LEVEL_DOWN, Delegate.GetOrCreate(self, self.OnFurnitureComboLevelDown))
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_UI_SHOW_TIPS, Delegate.GetOrCreate(self, self.OnShowTip))
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_UI_HIDE_TIPS, Delegate.GetOrCreate(self, self.OnHideTip))
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_UI_SHOW_HINT, Delegate.GetOrCreate(self, self.OnShowHint))
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_UI_HIDE_HINT, Delegate.GetOrCreate(self, self.OnHideHint))

    g_Game.ServiceManager:AddResponseCallback(CastleAddFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureAdd))
    g_Game.ServiceManager:AddResponseCallback(CastleDelFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureRemove))
end

function CityConstructionModeUIMediator:OnClose(param)
    self:OnRecoverUI()
    if self.param.cameraHandler then
        self.param.cameraHandler:back()
    end
    g_Game.ServiceManager:RemoveResponseCallback(CastleAddFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureAdd))
    g_Game.ServiceManager:RemoveResponseCallback(CastleDelFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureRemove))
    g_Game.EventManager:RemoveListener(EventConst.CITY_EDIT_MODE_PLAY_COMBO_LEVEL_UP, Delegate.GetOrCreate(self, self.OnFurnitureComboLevelUp))
    g_Game.EventManager:RemoveListener(EventConst.CITY_EDIT_MODE_PLAY_COMBO_LEVEL_DOWN, Delegate.GetOrCreate(self, self.OnFurnitureComboLevelDown))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_UI_HIDE, Delegate.GetOrCreate(self, self.OnHideUI))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_UI_SHOW, Delegate.GetOrCreate(self, self.OnRecoverUI))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_CONTINUE_PLACE, Delegate.GetOrCreate(self, self.OnRecoverUIAndUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_UI_SHOW_ROOM_SUBPAGE, Delegate.GetOrCreate(self, self.OnEnterRoomMode))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_UI_EXIT_ROOM_SUBPAGE, Delegate.GetOrCreate(self, self.OnExitRoomMode))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_UI_ROOM_MOVE_STEP, Delegate.GetOrCreate(self, self.OnRoomBuildMoveStep))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_UI_SHOW_TIPS, Delegate.GetOrCreate(self, self.OnShowTip))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_UI_HIDE_TIPS, Delegate.GetOrCreate(self, self.OnHideTip))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_UI_SHOW_HINT, Delegate.GetOrCreate(self, self.OnShowHint))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_UI_HIDE_HINT, Delegate.GetOrCreate(self, self.OnHideHint))

    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_EXIT_EDIT_MODE)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_MAP_GRID_DEFAULT)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CAMERA_TWEEN_TO_DEFAULT_VIEWPORT)
    ModuleRefer.CityConstructionModule:RefreshBuildingDotsDirty()
    ModuleRefer.CityConstructionModule:ClearFurnitureRedDots()
end

function CityConstructionModeUIMediator:ActiveButtons()
    self.toggleData = {}
    self.toggleIdx = {[State.Furniture] = {}}
    self._p_table_toggle_wide:Clear()
    
    local sortedCategory = {}
    for k, category in pairs(FurnitureCategory) do
        if category == FurnitureCategory.Decoration then goto continue end
        if category == FurnitureCategory.Military then goto continue end
        table.insert(sortedCategory, category)
        ::continue::
    end

    table.sort(sortedCategory)

    for i, category in ipairs(sortedCategory) do
        local toggleDatum = CityConstructionFurnitureToggleData.new(self, category)
        self._p_table_toggle_wide:AppendData(toggleDatum)
        table.insert(self.toggleData, toggleDatum)
        self.toggleIdx[State.Furniture][category] = #self.toggleData
    end

    table.insert(self.toggleData, CityConstructionDecorationToggleData.new(self))
    self._p_table_toggle_wide:AppendData(self.toggleData[#self.toggleData])
    self.toggleIdx[State.Decoration] = #self.toggleData

    -- table.insert(self.toggleData, CityConstructionRoomToggleData.new(self))
    -- self._p_table_toggle_wide:AppendData(self.toggleData[#self.toggleData])
    -- self.toggleIdx[State.Room] = #self.toggleData

    -- table.insert(self.toggleData, CityConstructionBuildingToggleData.new(self))
    -- self._p_table_toggle_wide:AppendData(self.toggleData[#self.toggleData])
    -- self.toggleIdx[State.Building] = #self.toggleData

    self._p_table_toggle_wide:RefreshAllShownItem(true)
    self.selectedToggleData = self:GetToggleByState(self.state, self.subState)
end

function CityConstructionModeUIMediator:GetToggleByState(state, subState)
    if state == State.Furniture then
        return self.toggleData[self.toggleIdx[state][subState]]
    end
    return self.toggleData[state]
end

function CityConstructionModeUIMediator:ProcessCustomData()
    if not self.param.customData then return end

    local customData = self.param.customData
    if not self.param.showedState[customData.visibleTag] then return end

    self.state = customData.visibleTag
    self.subState = customData.visibleSubTag or 1
    ---@param data CityConstructionUICellDataFurniture|CityConstructionUICellDataBuilding
    self.visibleTypeFinder = function(data) return data:TypeId() == customData.visibleTypeId end
end

function CityConstructionModeUIMediator:UpdateTableView()
    self.selectedToggleData:OnClickImp()
end

function CityConstructionModeUIMediator:ShowBuildingList()
    self._p_table_view:Clear()
    self.viewedData = {}
    local list, stateMap = ModuleRefer.CityConstructionModule:GetSortedBuildingTypeList()
    for _, v in ipairs(list) do
        local node = self:GenerateBuildingDataTree(v, stateMap[v])
        if node then
            self._p_table_view:AppendData(node)
            table.insert(self.viewedData, node)
            self._p_table_view:AppendCellCustomName('Building_' .. tostring(node:TypeId()))
        else
            g_Logger.Error(("[表:building_type, id:%d]的level表数组长度为0, 找不到任何building_level相关, 找产品检查配置"):format(v:Id()))
        end
    end
    self._p_table_view:RefreshAllShownItem(true)
end

---@param category number @enum-FurnitureCategory
function CityConstructionModeUIMediator:ShowNormalFurnitureList(category)
    self._p_table_view:Clear()
    self.viewedData = {}
    local list, amountMap = ModuleRefer.CityConstructionModule:GetSortedFurnituresByCategory(category)
    self:ShowFurnitureListImp(list, amountMap)
    self._p_table_view:RefreshAllShownItem(true)
end

function CityConstructionModeUIMediator:ShowDecorationList()
    self._p_table_view:Clear()
    self.viewedData = {}
    
    --- 装饰类家具显示在装饰分类中
    local list, amountMap = ModuleRefer.CityConstructionModule:GetSortedFurnituresByCategory(FurnitureCategory.Decoration)
    self:ShowFurnitureListImp(list, amountMap)

    -- --- 地板
    -- for _, cfg in ConfigRefer.BuildingRoomFloor:ipairs() do
    --     local node = CityConstructionUICellDataFloor.new(cfg)
    --     table.insert(self.viewedData, node)
    --     self._p_table_view:AppendData(node)
    --     self._p_table_view:AppendCellCustomName('Floor_' .. tostring(node:ConfigId()))
    -- end
    self._p_table_view:RefreshAllShownItem(true)
end

function CityConstructionModeUIMediator:ShowFurnitureListImp(list, amountMap)
    ---@type CityConstructionUICellDataFurniture[]
    local nodeList = {}
    for _, v in ipairs(list) do
        local node = self:GenerateFurnitureTree(v, amountMap[v])
        table.insert(nodeList, node)
    end

    table.sort(nodeList,
        ---@param l CityConstructionUICellDataFurniture
        ---@param r CityConstructionUICellDataFurniture
        function(l, r)
            local ls = l:GetState()
            local rs = r:GetState()
            if ls ~= rs then
                return ls < rs
            end

            local ln = table.nums(amountMap[l.typCell])
            local rn = table.nums(amountMap[r.typCell])
            if ln == rn or (ln ~= 0 and rn ~= 0) then
                return l.typCell:DisplaySort() > r.typCell:DisplaySort()
            else
                return rn == 0
            end
        end
    )

    --- 填充TableViewPro
    for _, v in ipairs(nodeList) do
        self._p_table_view:AppendData(v)
        table.insert(self.viewedData, v)            
        self._p_table_view:AppendCellCustomName('Furniture_' .. tostring(v:TypeId()))
    end
end

function CityConstructionModeUIMediator:ShowRoomList()
    self._p_table_view:Clear()
    self.viewedData = {}
    for _, cfg in ConfigRefer.BuildingCustomRoom:ipairs() do
        local node = CityConstructionUICellDataCustomRoom.new(cfg)
        table.insert(self.viewedData, node)
        self._p_table_view:AppendData(node)
        self._p_table_view:AppendCellCustomName('Room_' .. tostring(node:ConfigId()))
    end
    self._p_table_view:RefreshAllShownItem(true)
end

---@param typCell BuildingTypesConfigCell
---@param state number
function CityConstructionModeUIMediator:GenerateBuildingDataTree(typCell, state)
    if typCell:LevelCfgIdListLength() == 0 then return nil end

    local data = CityConstructionUICellDataBuilding.new()

    data.typCell = typCell
    local stockData, stockCount = ModuleRefer.CityModule:GetStockCityBuildingInfoByType(typCell:Id());
    local levelMap = {}
    if stockData then
        for id, buildingInfo in pairs(stockData) do
            levelMap[buildingInfo.Level] = levelMap[buildingInfo.Level] or {}
            table.insert(levelMap[buildingInfo.Level], id)
        end
    end

    local isOnlyOne = typCell:MaxNum() == 1 or table.nums(levelMap) == 1
    if stockCount > 0 then
        if isOnlyOne then
            local level, ids = next(levelMap)
            data.tileId = ids[1]
            data.lvCell = ModuleRefer.CityConstructionModule:GetBuildingLevelConfigCell(typCell, level)
            data.state = CityConstructState.CanBuild
            data.stockCount = #ids
        else
            local lvMap = {}
            local lvSort = {}
            for level, ids in pairs(levelMap) do
                lvMap[level] = ids
                table.insert(lvSort, level)
            end
            table.sort(lvSort, reverse_sort)
            
            data.state = CityConstructState.CanBuild
            data.stockFold = {}
            data.stockCount = 0
            for i, v in ipairs(lvSort) do
                local foldData = CityConstructionUICellDataBuilding.new()
                foldData.typCell = typCell
                foldData.tileId = lvMap[v][1]
                foldData.lvCell = ModuleRefer.CityConstructionModule:GetBuildingLevelConfigCell(typCell, v)
                foldData.state = CityConstructState.CanBuild
                foldData.stockCount = #lvMap[v]
                table.insert(data.stockFold, foldData)
                data.stockCount = data.stockCount + #lvMap[v]
            end
        end
    else
        data.lvCell = ModuleRefer.CityConstructionModule:GetBuildingLevelConfigCell(typCell)
        data.state = state
        data.stockCount = 0
    end

    if data.stockCount == 0 then
        data.itemGroup = ConfigRefer.ItemGroup:Find(data.lvCell:CostItemGroupCfgId())
    end
    return data
end

---@param typCell CityFurnitureTypesConfigCell
---@param stockMap table<number, number> key是等级,value是数量
---@return CityConstructionUICellDataFurniture
function CityConstructionModeUIMediator:GenerateFurnitureTree(typCell, stockMap)
    local data = CityConstructionUICellDataFurniture.new()
    data.typCell = typCell
    data.lvCell = ConfigRefer.CityFurnitureLevel:Find(typCell:LevelCfgIdList(1))
    data.stockCount = ModuleRefer.InventoryModule:GetAmountByConfigId(data.lvCell:RelItem())
    data.building = self.param.building
    data.itemGroup = ConfigRefer.ItemGroup:Find(data.lvCell:RelItem())
    return data
end

---@param data CityConstructionUICellDataBuilding|CityConstructionUICellDataFurniture
function CityConstructionModeUIMediator:ListStockView(data)
    if data == nil or data.stockFold == nil then
        return
    end

    self.viewStock = true
    self.viewStockData = data
    -- self._p_table_view.gameObject:SetActive(false)
    -- self._p_table_save.gameObject:SetActive(true)
    -- self._p_btn_back.gameObject:SetActive(true)
    self._p_table_save:Clear()
    
    for _, v in ipairs(data.stockFold) do
        self._p_table_save:AppendData(v)
    end
end

function CityConstructionModeUIMediator:InitialToggle()
    self.selectedToggleData:Selected()
    self.selectedToggleData:OnClickImp()
end

---@param data CityConstructionBuildingToggleData|CityConstructionFurnitureToggleData|CityConstructionTowerToggleData|CityConstructionDecorationToggleData|CityConstructionRoomToggleData
function CityConstructionModeUIMediator:SelectToggle(data)
    if self.selectedToggleData == data then
        return false
    end

    if self.selectedToggleData then
        self.selectedToggleData:UnSelected()
    end
    self.selectedToggleData = data
    self.selectedToggleData:Selected()
    return true
end

function CityConstructionModeUIMediator:PostTableViewCreated()
    if not self.visibleTypeFinder then return end
    for i, v in pairs(self.viewedData) do
        if self.visibleTypeFinder(v) then
            if self._p_table_view:IsDataVisable(i) then
                v.ping = true
            else
                self._p_table_view:SetDataVisable(i, CS.TableViewPro.MoveSpeed.Fast, function()
                    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_CELL_GUIDE_FINGER, v)
                end)
            end
            return
        end
    end
end

function CityConstructionModeUIMediator:OnHideStockView()
    self.viewStock = false
    self.viewStockData = nil
    self:UpdateTableView()
end

---@param data CityConstructionRoomModeData
function CityConstructionModeUIMediator:OnEnterRoomMode(data)
    self._p_group_table:PlayAll("ShowRoomList")
    self._p_table_room:Clear()
    self._p_group_room:FeedData(data.header)
    for _, v in ipairs(data.list) do
        self._p_table_room:AppendData(v)
    end
    self._p_table_room:RefreshAllShownItem(true)
    self.roomBuildIdx = 1
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_ROOM_CELL_IDX, self.roomBuildIdx)
    self.roomMode = true
end

function CityConstructionModeUIMediator:OnExitRoomMode()
    if not self.roomMode then return end
    self.roomMode = false
    self._p_group_table:PlayAll("HideRoomList")
    self._p_table_room:Clear()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_CANCEL_PLACE)
    self.roomBuildIdx = -1
end

function CityConstructionModeUIMediator:OnRoomBuildMoveStep()
    if self.roomBuildIdx <= 0 then return end

    self.roomBuildIdx = self.roomBuildIdx + 1
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_ROOM_CELL_IDX, self.roomBuildIdx)
end

function CityConstructionModeUIMediator:OnHideUI()
    self._p_hide_root.alpha = 0
    self._p_hide_root.blocksRaycasts = false
end

function CityConstructionModeUIMediator:OnRecoverUI()
    self._p_hide_root.alpha = 1
    self._p_hide_root.blocksRaycasts = true
end

function CityConstructionModeUIMediator:OnRecoverUIAndUpdate()
    self:OnRecoverUI()
    self:UpdateTableView()
end

---@param cellTile CityCellTile
---@param combo CityFurnitureCombinationConfigCell
function CityConstructionModeUIMediator:OnFurnitureComboLevelUp(cellTile, combo)
    if self.param.building ~= cellTile then return end

    self._p_sign_hang.gameObject:SetActive(false)
    self._p_sign_hang:Stop()
    self._p_text_name_sign.text = I18N.Get(combo:Description())

    self._p_sign_hang.gameObject:SetActive(true)
    self._p_sign_hang:Play()
    self.titleData.title = I18N.Get(combo:Name())
    self._child_common_btn_back:FeedData(self.titleData)
end

---@param cellTile CityCellTile
---@param fromCombo CityFurnitureCombinationConfigCell
---@param toCombo CityFurnitureCombinationConfigCell|nil
function CityConstructionModeUIMediator:OnFurnitureComboLevelDown(cellTile, fromCombo, toCombo)
    if self.param.building ~= cellTile then return end

    self._p_sign_pick.gameObject:SetActive(false)
    self._p_sign_hang:Stop()
    self._p_text_name_old.text = I18N.Get(fromCombo:Description())
    if toCombo == nil then
        local newName = self.param.building:GetBuildingName()
        self._p_text_name_new.text = newName
        self.titleData.title = newName
    else
        self._p_text_name_new.text = I18N.Get(toCombo:Description())
        self.titleData.title = I18N.Get(toCombo:Name())
    end
    self._p_sign_pick.gameObject:SetActive(true)
    self._p_sign_hang:Play()
    self._child_common_btn_back:FeedData(self.titleData)
end

---@param isSuccess boolean
---@param rsp wrpc.CastleAddFurnitureReply
---@param req rpc.CastleAddFurniture
function CityConstructionModeUIMediator:OnFurnitureAdd(isSuccess, rsp, req)
    if not isSuccess then return end
    if not self.viewStock then
        for i, v in ipairs(self.viewedData) do
            --- viewedData里可能有折叠的数据, 未必有lvCell
            if v.lvCell and v.lvCell:Id() == req.request.ConfigId then
                v.stockCount = v.stockCount - 1
                if v.stockCount > 0 then
                    self._p_table_view:UpdateData(v)
                else
                    table.remove(self.viewedData, i)
                    self._p_table_view:RemData(v)
                end
                break
            end
        end
    else
        local foldDatas = self.viewStockData.stockFold
        for i, v in ipairs(foldDatas) do
            if v.lvCell:Id() == req.request.ConfigId then
                v.stockCount = v.stockCount - 1
                if v.stockCount == 0 then
                    table.remove(foldDatas, i)
                    self._p_table_save:RemData(v)
                end
                self._p_table_save:UpdateAllData()
                break
            end
        end
    end
end

---@param isSuccess boolean
---@param rsp wrpc.CastleDelFurnitureReply
---@param req rpc.CastleDelFurniture
function CityConstructionModeUIMediator:OnFurnitureRemove(isSuccess, rsp, req)
    if not isSuccess then return end
    local isExistedNode = false
    if not self.viewStock then
        for i, v in ipairs(self.viewedData) do
            --- viewedData里可能有折叠的数据, 未必有lvCell
            if v.lvCell and v.lvCell:Id() == rsp.LevelCfgId then
                v.stockCount = v.stockCount + 1
                self._p_table_view:UpdateData(v)
                isExistedNode = true
                break
            end
        end
        
        if not isExistedNode then
            self:UpdateTableView()
        end
    else
        local foldDatas = self.viewStockData.stockFold
        for i, v in ipairs(foldDatas) do
            if v.lvCell:Id() == rsp.LevelCfgId then
                v.stockCount = v.stockCount + 1
                self._p_table_save:UpdateData(v)
                isExistedNode = true
                break
            end
        end

        if not isExistedNode then
            local indexer = {}
            local lvCell = ConfigRefer.CityFurnitureLevel:Find(rsp.LevelCfgId)
            local typCell = ConfigRefer.CityFurnitureTypes:Find(lvCell:Type())
            local stockMap = ModuleRefer.CityConstructionModule:GetFurnitureAmountMap(typCell)
            for k, _ in pairs(stockMap) do
                table.insert(indexer, k)
            end
            table.sort(indexer, reverse_sort)

            local data = self.viewStockData
            data.stockFold = {}
            data.stockCount = 0
            for _, lv in ipairs(indexer) do
                local num = stockMap[lv]
                local foldData = CityConstructionUICellDataFurniture.new()
                foldData.typCell = typCell
                foldData.lvCell = ConfigRefer.CityFurnitureLevel:Find(typCell:LevelCfgIdList(lv))
                foldData.stockCount = num
                foldData.building = data.building
                table.insert(data.stockFold, foldData)
                data.stockCount = data.stockCount + num
            end
            self:ListStockView(data)
        end
    end
end

function CityConstructionModeUIMediator:OnCloseUIClick()
    self:CloseSelf()
end

function CityConstructionModeUIMediator:OnShowTip(worldPos, attrGroup)
    self._p_group_tips:ShowTip(worldPos, attrGroup)
end

function CityConstructionModeUIMediator:OnHideTip()
    self._p_group_tips:HideTip()
end

function CityConstructionModeUIMediator:OnShowHint(style, content, icon)
    self._p_group_hint:SetVisible(true)
    self._p_base_alert:SetVisible(style == CityConstructionModeUIMediator.TIPS_ALERT)
    self._p_base_normal:SetVisible(style == CityConstructionModeUIMediator.TIPS_NORMAL)
    self._p_text_hint.text = content

    local showIcon = not string.IsNullOrEmpty(icon)
    self._p_icon_hint:SetVisible(showIcon)
    if showIcon then
        g_Game.SpriteManager:LoadSprite(icon, self._p_icon_hint)
    end
end

function CityConstructionModeUIMediator:OnHideHint()
    self._p_group_hint:SetVisible(false)
end

return CityConstructionModeUIMediator