---Scene Name : scene_construction_mode_new
local BaseUIMediator = require ('BaseUIMediator')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local FurnitureCategory = require("FurnitureCategory")
local CityFurniturePlaceUIToggleDatum = require("CityFurniturePlaceUIToggleDatum")
local CastleAddFurnitureParameter = require("CastleAddFurnitureParameter")
local CastleDelFurnitureParameter = require("CastleDelFurnitureParameter")
local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local CityFurnitureHelper = require("CityFurnitureHelper")
local NotificationType = require("NotificationType")
local CityFurniturePlaceI18N = require("CityFurniturePlaceI18N")
local CityLegoBuffRouteMapUIParameter = require("CityLegoBuffRouteMapUIParameter")
local UIMediatorNames = require("UIMediatorNames")
local CityConst = require("CityConst")
local CityLegoI18N = require("CityLegoI18N")
local CastleSetRoomBuffParameter = require("CastleSetRoomBuffParameter")

---@class CityFurniturePlaceUIMediator:BaseUIMediator
local CityFurniturePlaceUIMediator = class('CityFurniturePlaceUIMediator', BaseUIMediator)

function CityFurniturePlaceUIMediator:OnCreate()
    self._p_content = self:StatusRecordParent("p_content")                                      ----状态机

    self._p_hide_root = self:BindComponent("p_hide_root", typeof(CS.UnityEngine.CanvasGroup))   ----根节点Alpha隐藏

    self._p_group_table = self:BindComponent("p_group_table", typeof(CS.UnityEngine.CanvasGroup))----底部卡片列表
    
    ---@see CityFurniturePlaceUIToggleCell
    self._p_table_toggle_wide = self:TableViewPro("p_table_toggle_wide")                        ----左侧按钮TableView

    ---@see CityFurniturePlaceUINodeCell
    self._p_table_view = self:TableViewPro("p_table_view")                                    ----底部卡片单元TableView

    ---@type CommonBackButtonComponent
    self._child_common_btn_back = self:LuaObject("child_common_btn_back")                       ----通用返回按钮组件

    self._p_btn_suit = self:Button("p_btn_suit", Delegate.GetOrCreate(self, self.OnClickBuffList))  ---- 配方入口
    self._p_text_suit = self:Text("p_text_suit", CityLegoI18N.UI_HintSelectBuff)
    self._child_reddot_default = self:LuaObject("child_reddot_default") ---- 配方红点

    self._p_btn_room = self:Button("p_btn_room", Delegate.GetOrCreate(self, self.OnClickRoom))  ---- 查看房间按钮
    self._p_text_room = self:Text("p_text_room", CityFurniturePlaceI18N.UI_Button_Room)

    self._p_btn_moving = self:Button("p_btn_moving", Delegate.GetOrCreate(self, self.OnClickMovingLego))  ---- 移动房间按钮
    self._p_text_moving = self:Text("p_text_moving", CityFurniturePlaceI18N.UI_Button_Room_Move)

    self._p_btn_base = self:Button("p_btn_base", Delegate.GetOrCreate(self, self.OnClickLegoBase)) ---- 地基按钮
    self._p_text_base = self:Text("p_text_base", CityFurniturePlaceI18N.UI_Button_Base)

    ---@type CityFurniturePlacePadButton
    self._group_view = self:LuaObject("group_view")

    ---@type CityFurniturePlaceRoomHeader
    self._p_room = self:LuaObject("p_room")

    ---@type CityFurniturePlaceLegoRoomBuffComboHint
    self._p_tips_suit = self:LuaObject("p_tips_suit")

    --- 移动Lego
    self._p_move = self:GameObject("p_move")
    self._p_btn_cancel = self:Button("p_btn_cancel", Delegate.GetOrCreate(self, self.OnClickCancelMovingLego))
    self._p_text_hint = self:Text("p_text_hint", CityFurniturePlaceI18N.UI_HintMovingLego)

    --- 动效
    self._trigger = self:AnimTrigger("trigger")

    --- 过滤器
    self._group_dropdown = self:GameObject("group_dropdown")
    ---@type CommonDropDown
    self._child_dropdown = self:LuaObject("child_dropdown")

    self._raycaster = self:BindComponent("", typeof(CS.UnityEngine.UI.GraphicRaycaster))
end

---@param param CityFurniturePlaceUIParameter
function CityFurniturePlaceUIMediator:OnOpened(param)
    self.param = param
    self.focusConfigId = self.param.focusFurnitureTypCfgId
    self.movingLego = false
    self:InitMode()
    self:InitRecommendMap()
    self:InitToggleData()
    self:InitPadButton()
    self:UpdateFilter()
    self:DefaultSelectFirstToggle()
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_UI_HIDE, Delegate.GetOrCreate(self, self.HideRoot))
    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_UI_SHOW, Delegate.GetOrCreate(self, self.ShowRoot))
    g_Game.EventManager:AddListener(EventConst.UI_FURNITURE_PLACE_SELECT, Delegate.GetOrCreate(self, self.OnSelectNode))
    g_Game.EventManager:AddListener(EventConst.CITY_SELECTER_ENTER_BUILDING, Delegate.GetOrCreate(self, self.OnFurnitureEnterBuilding))
    g_Game.EventManager:AddListener(EventConst.CITY_SELECTER_LEAVE_BUILDING, Delegate.GetOrCreate(self, self.OnFurnitureLeaveBuilding))
    g_Game.EventManager:AddListener(EventConst.UI_FURNITURE_PLACE_PREVIEW_FINISH, Delegate.GetOrCreate(self, self.OnPreviewFinish))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_SCORE_CHANGE, Delegate.GetOrCreate(self, self.OnBuildingScoreChanged))
    g_Game.ServiceManager:AddResponseCallback(CastleAddFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureAdd))
    g_Game.ServiceManager:AddResponseCallback(CastleDelFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureRemove))
    g_Game.ServiceManager:AddResponseCallback(CastleSetRoomBuffParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuffChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleObjectCount.FurnitureCount.MsgPath, Delegate.GetOrCreate(self, self.OnCountChanged))
    g_Game.EventManager:AddListener(EventConst.UI_CITY_LEGO_BUFF_RECOMMEND_BUFF_TAG, Delegate.GetOrCreate(self, self.OnRecommendBuffTag))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnDirtyTick))
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
end

function CityFurniturePlaceUIMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_UI_HIDE, Delegate.GetOrCreate(self, self.HideRoot))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_UI_SHOW, Delegate.GetOrCreate(self, self.ShowRoot))
    g_Game.EventManager:RemoveListener(EventConst.UI_FURNITURE_PLACE_SELECT, Delegate.GetOrCreate(self, self.OnSelectNode))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SELECTER_ENTER_BUILDING, Delegate.GetOrCreate(self, self.OnFurnitureEnterBuilding))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SELECTER_LEAVE_BUILDING, Delegate.GetOrCreate(self, self.OnFurnitureLeaveBuilding))
    g_Game.EventManager:RemoveListener(EventConst.UI_FURNITURE_PLACE_PREVIEW_FINISH, Delegate.GetOrCreate(self, self.OnPreviewFinish))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_SCORE_CHANGE, Delegate.GetOrCreate(self, self.OnBuildingScoreChanged))
    g_Game.ServiceManager:RemoveResponseCallback(CastleAddFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureAdd))
    g_Game.ServiceManager:RemoveResponseCallback(CastleDelFurnitureParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnFurnitureRemove))
    g_Game.ServiceManager:RemoveResponseCallback(CastleSetRoomBuffParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuffChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleObjectCount.FurnitureCount.MsgPath, Delegate.GetOrCreate(self, self.OnCountChanged))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_LEGO_BUFF_RECOMMEND_BUFF_TAG, Delegate.GetOrCreate(self, self.OnRecommendBuffTag))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnDirtyTick))

    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_EXIT_EDIT_MODE)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_MAP_GRID_DEFAULT)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CAMERA_TWEEN_TO_DEFAULT_VIEWPORT)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
end

function CityFurniturePlaceUIMediator:InitMode()
    if self.param.city.editBuilding == nil then
        self._p_content:ApplyStatusRecord(1)
    else
        self._p_content:ApplyStatusRecord(0)
        self._p_room:ShowBuildingNormal(self.param.city.editBuilding)
    end
    self._p_tips_suit:SetVisible(false)

    -- self._p_btn_moving:SetVisible(self.param.city.editBuilding == nil)
    self._p_btn_moving:SetVisible(false)
    -- self._p_btn_room:SetVisible(self.param.city.editBuilding == nil)
    self._p_btn_room:SetVisible(false)
    -- self._p_btn_suit:SetVisible(self.param.city.editBuilding ~= nil)
    self._p_btn_suit:SetVisible(false)
    self._p_btn_base:SetVisible(false)
    self._group_dropdown:SetActive(self.param.city.editBuilding == nil and self.param.showPlaced)
end

function CityFurniturePlaceUIMediator:InitRecommendMap()
    self.recommendMap = {}
end

function CityFurniturePlaceUIMediator:InitToggleData()
    ---@type CityFurniturePlaceUIToggleDatum[]
    self.toggleDataList = {}
    
    local categories = {}
    local allCategories = {}
    for _, value in pairs(FurnitureCategory) do
        table.insert(categories, value)
        allCategories[value] = true
    end
    table.sort(categories)

    local category2Image = {}
    local category2Name = {}
    for i = 1, ConfigRefer.CityConfig:CityFurnitureCategoryUILength() do
        local categoryImageGroup = ConfigRefer.CityConfig:CityFurnitureCategoryUI(i)
        category2Image[categoryImageGroup:Category()] = categoryImageGroup:Image()
        category2Name[categoryImageGroup:Category()] = I18N.Get(categoryImageGroup:Name())
    end

    local all = CityFurniturePlaceUIToggleDatum.new(
        self.param.city,
        "sp_icon_missing",
        I18N.Get("UI_Btn_Fur_All"),
        false,
        allCategories,
        nil -- ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityFurnitureHelper.GetPlaceUIAllToggleNotifyName(), NotificationType.CITY_FURNIURE_PLACE)
    )
    table.insert(self.toggleDataList, all)
    
    for _, category in ipairs(categories) do
        if not category2Name[category] then goto continue end
        local toggleData = CityFurniturePlaceUIToggleDatum.new(
            self.param.city,
            category2Image[category] or string.Empty,
            category2Name[category] or string.Empty,
            false,
            {[category] = true},
            ModuleRefer.NotificationModule:GetOrCreateDynamicNode(CityFurnitureHelper.GetPlaceUIToggleNotifyName(category), NotificationType.CITY_FURNIURE_PLACE_TOGGLE)
        )
        table.insert(self.toggleDataList, toggleData)
        ::continue::
    end

    self._p_table_toggle_wide:Clear()
    for _, data in ipairs(self.toggleDataList) do
        self._p_table_toggle_wide:AppendData(data)
    end
end

function CityFurniturePlaceUIMediator:InitPadButton()
    self._group_view:FeedData(self.param)
end

function CityFurniturePlaceUIMediator:DefaultSelectFirstToggle()
    self:SelectToggleData(self.toggleDataList[1])
end

---@param toggleData CityFurniturePlaceUIToggleDatum
function CityFurniturePlaceUIMediator:SelectToggleData(toggleData)
    if toggleData == nil then return end

    for i, v in ipairs(self.toggleDataList) do
        v:SetSelected(v == toggleData)
    end

    self.selectedToggle = toggleData
    self._p_table_toggle_wide:UpdateOnlyAllDataImmediately()
    self:InitRecommendMap()
    self:RefreshNodeTableView()

    if toggleData ~= self.toggleDataList[1] then
        self:ClearCategoryFurnitureNotifyData(toggleData.categoryMap)
    end
end

function CityFurniturePlaceUIMediator:RefreshNodeTableView()
    self._p_table_view:Clear()
    
    local castDataList = self.selectedToggle:GetCardDataList(self.param.showPlaced, self.buildingId)
    local recommendData = {}
    for lvCfgId, _ in pairs(self.recommendMap) do
        --- 将推荐的数据找出来插入到最前面
        for i = #castDataList, 1, -1 do
            local datum = castDataList[i]
            if datum.lvCfg:Id() == lvCfgId then
                datum:SetRecommend(true)
                table.insert(recommendData, datum)
                table.remove(castDataList, i)
            end
        end
    end
    for _, datum in ipairs(recommendData) do
        table.insert(castDataList, 1, datum)
    end

    local findFocusTypeId, findFocusIdx, findFocusData = false, -1, nil
    for i, v in ipairs(castDataList) do
        if self.focusConfigId ~= nil and v.typCfg:Id() == self.focusConfigId then
            v:TriggerGuideFinger()
            findFocusTypeId = true
            findFocusIdx = i
            findFocusData = v
        end
        self._p_table_view:AppendData(v, 0)
        self._p_table_view:AppendCellCustomName(v:GetTableViewCellName())
    end

    local oneLineCellCount = self._p_table_view:GetCountInOneLine(0)
    if oneLineCellCount > #castDataList then
        for i = #castDataList, oneLineCellCount do
            self._p_table_view:AppendData("empty", 1)
            self._p_table_view:AppendCellCustomName(("empty_%d"):format(i))
        end
    end

    self.shownNodeDataList = castDataList

    if findFocusTypeId then
        self:PostTableViewCreated(findFocusIdx, findFocusData)
    end
    self:OnSelectNode(nil)
end

function CityFurniturePlaceUIMediator:PostTableViewCreated(idx, data)
    if not self._p_table_view:IsDataVisable(idx-1) then
        self._p_table_view:SetDataVisable(idx-1, CS.TableViewPro.MoveSpeed.Fast, function()
            g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_CELL_GUIDE_FINGER, data)
        end)
    end
    self.focusConfigId = nil
end

function CityFurniturePlaceUIMediator:HideRoot()
    self._p_hide_root.alpha = 0.1
    self._p_group_table.alpha = 0.1
    self._raycaster.enabled = false
end

function CityFurniturePlaceUIMediator:ShowRoot()
    self._p_hide_root.alpha = 1
    self._p_group_table.alpha = 1
    self._raycaster.enabled = true
end

function CityFurniturePlaceUIMediator:OnFurnitureAdd(isSuccess)
    if not isSuccess then return end

    self.nodeListDirty = true
end

function CityFurniturePlaceUIMediator:OnFurnitureRemove(isSuccess)
    if not isSuccess then return end

    self.nodeListDirty = true
end

function CityFurniturePlaceUIMediator:OnBuffChanged(isSuccess)
    if not isSuccess then return end
    if self.param.city.editBuilding == nil then return end

    self._p_room:UpdateName(self.param.city.editBuilding)
end

---@param entity wds.CastleBrief
function CityFurniturePlaceUIMediator:OnCountChanged(entity, _)
    if not self.param.city then return end

    if self.param.city.uid ~= entity.ID then return end

    self.nodeListDirty = true
end

function CityFurniturePlaceUIMediator:OnDirtyTick()
    if self.nodeListDirty then
        self.nodeListDirty = nil
        self:RefreshNodeTableView()
    end
end

---@param data CityFurniturePlaceUINodeDatum
function CityFurniturePlaceUIMediator:OnSelectNode(data)
    self.selected = data
end

function CityFurniturePlaceUIMediator:ClearCategoryFurnitureNotifyData(categoryMap)
    -- for category, _ in pairs(categoryMap) do
        -- self.param.city.furnitureManager:ClearCategoryFurnitureNotifyData(category)
    -- end
end

function CityFurniturePlaceUIMediator:OnPreviewNewFurniture(lvCfgId)
    if self.param.city.editBuilding == nil then return end
    
    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(lvCfgId)
    --- 如果出现摆下去立刻就能自动生效的新buff，则不显示推荐
    if not self._p_room:ShowBuildingPlusFurniture(self.param.city.editBuilding, lvCfg) then
        --- 否则就根据摆放情况预测推荐
        self._p_tips_suit:TryShowAnyTips(self.param.city.editBuilding, lvCfg)
    end
end

---@param tileHandle CityStateTileHandle
function CityFurniturePlaceUIMediator:OnFurnitureEnterBuilding(city, buildingId, tileHandle)
    if self.param.city ~= city then return end

    if self.param.city.editBuilding == nil then return end
    if self.param.city.editBuilding.id ~= buildingId then return end

    if tileHandle == nil then return end
    if tileHandle.dataSource == nil then return end
    if tileHandle.dataSource:TileHandleType() ~= CityConst.TileHandleType.Furniture then return end
    if tileHandle.dataSource:OriginBuildingId() == buildingId then return end

    local lvCfgId = tileHandle.dataSource:FurnitureLevelCfgId()
    self:OnPreviewNewFurniture(lvCfgId)
end

function CityFurniturePlaceUIMediator:OnFurnitureLeaveBuilding(city, buildingId, tileHandle)
    if self.param.city ~= city then return end

    if self.param.city.editBuilding == nil then return end
    if self.param.city.editBuilding.id ~= buildingId then return end

    self:OnPreviewFinish()
end

function CityFurniturePlaceUIMediator:OnPreviewFinish()
    if self.param.city.editBuilding == nil then return end
    
    self._p_room:ShowBuildingNormal(self.param.city.editBuilding)
    self._p_tips_suit:HideTips()
    self:StopAllVX()
end

function CityFurniturePlaceUIMediator:OnClickBuffList()
    local param = CityLegoBuffRouteMapUIParameter.new(self.param.city, self.param.city.editBuilding)
    g_Game.UIManager:Open(UIMediatorNames.CityLegoBuffRouteMapUIMediator, param)
end

function CityFurniturePlaceUIMediator:OnClickRoom()
    local param = CityLegoBuffRouteMapUIParameter.new(self.param.city)
    g_Game.UIManager:Open(UIMediatorNames.CityLegoBuffRouteMapUIMediator, param)
end

function CityFurniturePlaceUIMediator:OnClickMovingLego()
    if self.movingLego then return end

    self._p_hide_root:SetVisible(false)
    self._p_group_table:SetVisible(false)
    self._p_move:SetActive(true)
    self._p_btn_room:SetVisible(false)

    self.movingLego = true
    self.param.city.enableMovingLego = true
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CHANGE_MOVING_LEGO_STATE, self.movingLego)
end

function CityFurniturePlaceUIMediator:OnClickCancelMovingLego()
    if not self.movingLego then return end

    self._p_hide_root:SetVisible(true)
    self._p_group_table:SetVisible(true)
    self._p_move:SetActive(false)
    self._p_btn_room:SetVisible(true)

    self.movingLego = false
    self.param.city.enableMovingLego = false
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CHANGE_MOVING_LEGO_STATE, self.movingLego) 
end

function CityFurniturePlaceUIMediator:OnClickLegoBase()
    ---TODO:不知道是干嘛的
end

function CityFurniturePlaceUIMediator:PlayWillLevelUpVX()
    self._trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function CityFurniturePlaceUIMediator:PlayLevelUpVX()
    self._trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
end

function CityFurniturePlaceUIMediator:PlayNameWillChangeVX()
    self._trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
end

function CityFurniturePlaceUIMediator:StopAllVX()
    self._trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    self._trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom2)
    self._trigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom3)
end

function CityFurniturePlaceUIMediator:OnBuildingScoreChanged(legoBuilding)
    if self.param.city.editBuilding ~= legoBuilding then return end

    self._p_room:ShowBuildingNormal(self.param.city.editBuilding)
    self._p_tips_suit:HideTips()
end

function CityFurniturePlaceUIMediator:UpdateFilter()
    local index2Building = {}
    ---@type CommonDropDownData
    local filterData = {}
    filterData.items = {
        {
            id = 1,
            iconName = "",
            text = I18N.Get("hero_btn_all"),
            showText = I18N.Get("hero_btn_all"),
        },
        {
            id = 2,
            iconName = "",
            text = I18N.Get("ui_cityout"),
            showText = I18N.Get("ui_cityout"),
        }
    }
    index2Building[1] = -1
    index2Building[2] = 0
    local buildingMap = self.param.city.legoManager.legoBuildings
    local index = 2
    local defaultId = 1
    if buildingMap then
        for id, legoBulding in pairs(buildingMap) do
            if legoBulding:IsUnlocked() and not legoBulding:IsFogMask() then
                index = index + 1
                local data = {
                    id = index,
                    iconName = "",
                    text = I18N.Get(legoBulding:GetNameI18N()),
                    showText = I18N.Get(legoBulding:GetNameI18N()),
                }
                table.insert(filterData.items, data)
                index2Building[index] = legoBulding.id

                -- if legoBulding == self.param.city.editBuilding then
                --     defaultId = index
                -- end
            end
        end
    end

    filterData.defaultId = defaultId
    filterData.onSelect = Delegate.GetOrCreate(self, self.OnFilterSelect)
    self._child_dropdown:FeedData(filterData)
    self.index2Building = index2Building
    self.buildingId = index2Building[defaultId] or -1
end

function CityFurniturePlaceUIMediator:OnFilterSelect(index)
    self.buildingId = self.index2Building[index] or -1
    self:RefreshNodeTableView()
end

function CityFurniturePlaceUIMediator:UpdateByPlacedChange()
    self._group_dropdown:SetActive(self.param.city.editBuilding == nil and self.param.showPlaced)
    self:RefreshNodeTableView()
end

function CityFurniturePlaceUIMediator:OnRecommendBuffTag(tagCfgId)
    local map = ModuleRefer.CityLegoBuffModule:GetFurnitureLvCfgMapFromBuffTag(tagCfgId)
    self.recommendMap = {}
    for lvCfgId, flag in pairs(map) do
        self.recommendMap[lvCfgId] = flag
    end
    self:RefreshNodeTableView()
end

return CityFurniturePlaceUIMediator