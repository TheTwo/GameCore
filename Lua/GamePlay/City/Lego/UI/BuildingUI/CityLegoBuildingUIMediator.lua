---Scene Name : scene_city_room
local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local I18N = require("I18N")
local CityLegoI18N = require("CityLegoI18N")
local CityWorkType = require("CityWorkType")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")
local CastleSetRoomBuffParameter = require("CastleSetRoomBuffParameter")
local Utils = require("Utils")
local FurniturePageDefine = require("FurniturePageDefine")
local ModuleRefer = require("ModuleRefer")
local NumberAnim = require("NumberAnim")
local ColorUtil = require("ColorUtil")
local ColorConsts = require("ColorConsts")

local CityWorkProcessUIParameter = require("CityWorkProcessUIParameter")
local CityWorkCollectUIParameter = require("CityWorkCollectUIParameter")
local CityWorkProduceUIParameter = require("CityWorkProduceUIParameter")
local CityWorkFurnitureUpgradeUIParameter = require("CityWorkFurnitureUpgradeUIParameter")
local CityFurnitureDetailsUIParameter = require("CityFurnitureDetailsUIParameter")
local CityFurnitureEnergyUIParameter = require("CityFurnitureEnergyUIParameter")
local CityFurnitureCatchPetUIParameter = require("CityFurnitureCatchPetUIParameter")

local CityLegoBuildingUIBuffData = require("CityLegoBuildingUIBuffData")
local CityLegoBuffRouteMapUIParameter = require("CityLegoBuffRouteMapUIParameter")
local UIMediatorNames = require("UIMediatorNames")

---@class CityLegoBuildingUIMediator:BaseUIMediator
local CityLegoBuildingUIMediator = class('CityLegoBuildingUIMediator', BaseUIMediator)

function CityLegoBuildingUIMediator:OnCreate()
    self._p_btn_exit = self:Button("p_btn_exit", Delegate.GetOrCreate(self, self.OnClickQuit))

    self._layout_title = self:GameObject("layout_title")
    --- 标题
    self._p_text_title_name = self:Text("p_text_title_name")

    --- Buff进度和星级
    self._group_score = self:GameObject("group_score")
    self._p_text_title_score = self:Text("p_text_title_score")
    self._p_progress_score = self:Slider("p_progress_score")
    self._p_text_room_score = self:Text("p_text_room_score")

    ---房间buff
    self._p_buff_vertical = self:Transform("p_buff_vertical")
    ---@type CityLegoBuildingUIBuffDesc
    self._p_buff = self:LuaBaseComponent("p_buff")
    self._p_text_buff_title = self:Text("p_text_buff_title", CityLegoI18N.UI_TitleBuff)
    self._p_text_empty_buff = self:Text("p_text_empty_buff", CityLegoI18N.UI_HintNoBuff)
    self._buff_pool = LuaReusedComponentPool.new(self._p_buff, self._p_buff_vertical)

    ---改变Buff入口
    self._p_btn_change_formula = self:Button("p_btn_change_formula", Delegate.GetOrCreate(self, self.OnClickChangeBuff))

    ---室内编辑按钮入口
    self._p_btn_set = self:Button("p_btn_set", Delegate.GetOrCreate(self, self.OnClickEnterIndoorEdit))
    self._p_text = self:Text("p_text", CityLegoI18N.UI_BtnEnterIndoorEdit)
    self._p_new_set = self:GameObject("p_new_set")
    self._p_text_new_set = self:Text("p_text_new_set", CityLegoI18N.UI_NewBuffGroup)

    --- 左侧按钮
    self._p_btn_room = self:Button("p_btn_room") -- Delegate.GetOrCreate(self, self.OnClickBuilding)
    self._p_icon_room = self:Image("p_icon_room")

    --- 新配方
    self._p_new = self:GameObject("p_new")
    self._p_text_new_point = self:Text("p_text_new_point", CityLegoI18N.UI_NewBuffGroup)

    self._p_focus_target = self:RectTransform("p_focus_target")

    --- 左侧内部家具页签
    self._p_group_right_tab = self:GameObject("p_group_right_tab")
    self._p_table_furniture = self:TableViewPro("p_table_furniture")

    --- 房间主界面
    ---@type CityLegoBuildingUIPage_Room
    self._p_group_room = nil--self:LuaObject("p_group_room")
    --- 家具功能子界面
    self._p_group_furniture = self:GameObject("p_group_furniture")
    ---@type CityLegoBuildingUIPage_Process
    self._p_group_process = nil--self:LuaObject("p_group_process")
    ---@type CityLegoBuildingUIPage_Upgrade
    self._p_group_upgrade = nil--self:LuaObject("p_group_upgrade")
    ---@type CityLegoBuildingUIPage_Collect
    self._p_group_collect = nil--self:LuaObject("p_group_collect")
    ---@type CityLegoBuildingUIPage_Produce
    self._p_group_create_collection = nil--self:LuaObject("p_group_create_collection")
    ---@type CityLegoBuildingUIPage_CatchPet
    self._p_group_catch_pet = nil--self:LuaObject("p_group_catch_pet")
    ---@type CityLegoBuildingUIPage_Details
    self._p_group_info = nil--self:LuaObject("p_group_info")
    ---@type CityLegoBuildingUIPage_Energy
    self._p_group_energy = nil--self:LuaObject("p_group_energy")
    ---@type CityLegoBuildingUIPage_Special
    self._p_group_special = nil--self:LuaObject("p_group_special")
    ---@type CityLegoBuildingUIPage_Repair
    self._p_group_repair = nil--self:LuaObject("p_group_repair")

    --- 家具子界面选择Toggle
    self._p_group_tab = self:Transform("p_group_tab")
    ---@type CityLegoBuildingUIPageToggleButton
    self._p_btn_template = self:LuaBaseComponent("p_btn_template")
    self._page_toggle_pool = LuaReusedComponentPool.new(self._p_btn_template, self._p_group_tab)

    ---@type CityLegoBuildingFurnitureWorkComp @家具铭牌下的附属信息
    self._layout = self:LuaObject("layout")
    self._layout:SetVisible(true)

    --- 关闭按钮
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
end

---@param param CityLegoBuildingUIParameter
function CityLegoBuildingUIMediator:OnOpened(param)
    self.param = param
    self.city = param.city
    self.cameraSizeCache = self.city.camera:GetSize()
    self.legoBuilding = param.legoBuilding
    self.currentFurnitureId = param.selectFurnitureId

    self.lastPage = nil
    self._layout:ReleaseLastFurnitureData()

    if self.city.outlineController ~= nil then
        self.cacheColor = self.city.outlineController:GetOutlineColor()
        self.city.outlineController:ChangeOutlineColor(ColorUtil.FromHexNoAlphaString("fed521"))
        self.city.outlineController:ChangeOutlineWidth(0.1)
    end

    if self.legoBuilding ~= nil then
        self:UpdateUI_InBuilding()
    else
        self:UpdateUI_SingleFurniture()
    end

    self:ShowFurniturePage(self.currentFurnitureId) ---必须要有一个家具被选中

    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnUpgradeWorkingChange))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_LEGO_UPDATE, Delegate.GetOrCreate(self, self.OnLegoBatchUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_BUILDING_SCORE_CHANGE, Delegate.GetOrCreate(self, self.OnBuildingScoreChanged))
    g_Game.EventManager:AddListener(EventConst.UI_CITY_LEGO_SELECT_TARGET_FURNITURE, Delegate.GetOrCreate(self, self.OnQuickGotoFurniture))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.ServiceManager:AddResponseCallback(CastleSetRoomBuffParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuffSelectChange))
end

function CityLegoBuildingUIMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnUpgradeWorkingChange))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_LEGO_UPDATE, Delegate.GetOrCreate(self, self.OnLegoBatchUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_BUILDING_SCORE_CHANGE, Delegate.GetOrCreate(self, self.OnBuildingScoreChanged))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_LEGO_SELECT_TARGET_FURNITURE, Delegate.GetOrCreate(self, self.OnQuickGotoFurniture))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.ServiceManager:RemoveResponseCallback(CastleSetRoomBuffParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnBuffSelectChange))
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_LEGO_CLOSE)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    if self.city then
        self.city:RefreshBorderParams()
    end

    if self.city.outlineController ~= nil then
        self.city.outlineController:ChangeOutlineColor(self.cacheColor)
        self.city.outlineController:ChangeOutlineWidth(0.08)
    end

    self:CancelFurnitureTileSelected()
    self._layout:ReleaseLastFurnitureData()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnProgressAnimTick))

    if self.city and self.city.camera and self.cameraSizeCache then
        self.city.camera:StopTween()
        self.city.camera:ZoomTo(self.cameraSizeCache, 0.5)
    end
end

function CityLegoBuildingUIMediator:OnReOpen()
    if self.lastPage == self._p_group_room and self.lastPageDefine == FurniturePageDefine.Room then
        self._p_group_room:FeedData(self.legoBuilding)
    elseif self.lastPage == self._p_group_process and self.lastPageDefine == FurniturePageDefine.Process then
        self._p_group_process:FeedData(self.lastProcessParam)
    elseif self.lastPage == self._p_group_upgrade and self.lastPageDefine == FurniturePageDefine.Upgrade then
        self._p_group_upgrade:FeedData(self.lastUpgradeParam)
    elseif self.lastPage == self._p_group_collect and self.lastPageDefine == FurniturePageDefine.Collect then
        self._p_group_collect:FeedData(self.lastCollectParam)
    elseif self.lastPage == self._p_group_create_collection and self.lastPageDefine == FurniturePageDefine.Produce then
        self._p_group_create_collection:FeedData(self.lastProduceParam)
    elseif self.lastPage == self._p_group_catch_pet and self.lastPageDefine == FurniturePageDefine.CatchPet then
        self._p_group_catch_pet:FeedData(self.lastCatchPetParam)
    elseif self.lastPage == self._p_group_info and self.lastPageDefine == FurniturePageDefine.Details then
        self._p_group_info:FeedData(self.lastDetailsParam)
    elseif self.lastPage == self._p_group_energy and self.lastPageDefine == FurniturePageDefine.Energy then
        self._p_group_energy:FeedData(self.lastEnergyParam)
    elseif self.lastPage == self._p_group_special and self.lastPageDefine == FurniturePageDefine.Special then
        self._p_group_special:FeedData(self.lastSpecialParam)
    elseif self.lastPage == self._p_group_repair and self.lastPageDefine == FurniturePageDefine.Repair then
        self._p_group_repair:FeedData(self.lastRepairParam)
    end
end

function CityLegoBuildingUIMediator:UpdateRoomBuff()
    self._buff_pool:HideAll()
    local buffCfg = self.legoBuilding:GetCurrentBuffCfg()
    if buffCfg == nil then
        self._p_text_empty_buff:SetVisible(true)
    else
        self._p_text_empty_buff:SetVisible(false)

        local buffValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(buffCfg:GolbalAttr())
        local dataList = {}
        if buffValues then
            for i, v in ipairs(buffValues) do
                local value = CityLegoBuildingUIBuffData.new(v.type, v.value, v.originValue, v.icon)
                table.insert(dataList, value)
            end
        end

        for i = 1, buffCfg:BattleAttrGroupsLength() do
            local battleGroup = buffCfg:BattleAttrGroups(i)
            local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
            if battleValues then
                if battleGroup:TextLength() == 0 then
                    for _, v in ipairs(battleValues) do
                        local value = CityLegoBuildingUIBuffData.new(v.type, v.value, v.originValue, v.icon)
                        table.insert(dataList, value)
                    end
                else
                    for _, v in ipairs(battleValues) do
                        for j = 1, battleGroup:TextLength() do
                            local prefix = battleGroup:Text(j)
                            local value = CityLegoBuildingUIBuffData.new(v.type, v.value, v.originValue, v.icon, prefix)
                            table.insert(dataList, value)
                        end
                    end
                end
            end
        end

        for _, v in ipairs(dataList) do
            local item = self._buff_pool:GetItem()
            item:FeedData(v)
        end
    end
end

function CityLegoBuildingUIMediator:UpdateUI_InBuilding()
    self._layout_title:SetActive(true)
    self._p_group_right_tab:SetActive(true)

    self._p_text_title_name.text = I18N.Get(self.legoBuilding:GetNameI18N())
    self.buildingLv = self.legoBuilding.roomLevel
    self.lvProgress = self.legoBuilding:GetScoreProgress()
    self:UpdateRoomBuff()

    g_Game.SpriteManager:LoadSprite(self.legoBuilding:GetRoomUILeftToggleIcon(), self._p_icon_room)

    if self.legoBuilding:ShowScore() then
        self._group_score:SetActive(true)
        self._p_progress_score:SetVisible(true)
        self._p_text_title_score.text = tostring(self.legoBuilding.roomLevel)
        self._p_progress_score.value = self.lvProgress
    else
        self._group_score:SetActive(false)
        self._p_progress_score:SetVisible(false)
    end

    self._p_table_furniture:Clear()
    ---@type CityLegoBuildingUIFurnitureToggleButtonData[]
    self.furnitureData = {}
    local selectFurnitureValid = false
    for i, v in ipairs(self.legoBuilding.payload.InnerFurnitureIds) do
        local furniture = self.city.furnitureManager:GetFurnitureById(v)
        if v == self.currentFurnitureId then selectFurnitureValid = true end
        ---@type CityLegoBuildingUIFurnitureToggleButtonData
        local data = {furniture = furniture, isSelect = self.currentFurnitureId == v, onClick = Delegate.GetOrCreate(self, self.OnClickFurniture)}
        table.insert(self.furnitureData, data)
    end

    table.sort(self.furnitureData, function(a, b)
        ---@type CityFurniture
        local aFurniture = a.furniture
        ---@type CityFurniture
        local bFurniture = b.furniture
        if aFurniture:IsDecoration() ~= bFurniture:IsDecoration() then
            return bFurniture:IsDecoration()
        elseif aFurniture:IsLocked() ~= bFurniture:IsLocked() then
            return bFurniture:IsLocked()
        elseif aFurniture.displaySort ~= bFurniture.displaySort then
            return aFurniture.displaySort > bFurniture.displaySort
        elseif aFurniture.level ~= bFurniture.level then
            return aFurniture.level > bFurniture.level
        else
            return aFurniture.singleId < bFurniture.singleId
        end
    end)

    for _, data in ipairs(self.furnitureData) do
        self._p_table_furniture:AppendData(data)
    end

    if not selectFurnitureValid then
        self.currentFurnitureId = nil
    end

    ModuleRefer.NotificationModule:AttachToGameObject(self.legoBuilding.dynamicNode, self._p_new)
end

function CityLegoBuildingUIMediator:UpdateUI_SingleFurniture()
    self._layout_title:SetActive(false)
    self._p_group_right_tab:SetActive(false)

    self._p_table_furniture:Clear()
    self.furnitureData = {}
    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    ---@type CityLegoBuildingUIFurnitureToggleButtonData
    local data = {furniture = furniture, isSelect = true, onClick = Delegate.GetOrCreate(self, self.OnClickFurniture)}
    table.insert(self.furnitureData, data)

    for _, data in ipairs(self.furnitureData) do
        self._p_table_furniture:AppendData(data)
    end
end

function CityLegoBuildingUIMediator:OnClickQuit()
    self:CloseSelf()
end

function CityLegoBuildingUIMediator:OnClickBuilding()
    if self.currentFurnitureId == nil then return end

    self:ShowRoomPage()
end

---@param data CityLegoBuildingUIFurnitureToggleButtonData
function CityLegoBuildingUIMediator:OnClickFurniture(data)
    if data.furniture.singleId == self.currentFurnitureId then return end

    self:ShowFurniturePage(data.furniture.singleId)
end

function CityLegoBuildingUIMediator:ChangeFurnitureSelected()
    if self.furnitureData == nil or #self.furnitureData == 0 then return end

    for i, v in ipairs(self.furnitureData) do
        v.isSelect = v.furniture.singleId == self.currentFurnitureId
    end
    self._p_table_furniture:UpdateOnlyAllDataImmediately()
end

function CityLegoBuildingUIMediator:ShowRoomPage()
    self.currentFurnitureId = nil
    self.lastPageDefine = FurniturePageDefine.Room
    self:ChangeFurnitureSelected()
    self._page_toggle_pool:HideAll()

    if self.lastPage then
        self.lastPage:SetVisible(false)
    end
    self.city:RefreshBorderParams()
    self:TryShowRoomSubPrefab()
end

function CityLegoBuildingUIMediator:ShowFurniturePage(furnitureId)
    self:CancelFurnitureTileSelected()
    self.currentFurnitureId = furnitureId
    self:ChangeFurnitureSelected()
    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    if furniture == nil then
        return self:CloseSelf()
    end

    self:RefreshFurniturePageToggle()
    self:SetFurnitureSelected()

    if #self.toggleButtonData == 0 then
        if self.legoBuilding ~= nil then
            return self:ShowRoomPage()
        else
            return self:CloseSelf()
        end
    end

    self.city:DisableCameraBorderCheck()

    if self.param.priorityPage and self.togglePageMap[self.param.priorityPage] then
        self.togglePageMap[self.param.priorityPage]:onClick()
        self.param.priorityPage = nil
    else
        self.toggleButtonData[1]:onClick()
    end

    self:ApplyFurnitureWorkComp(furniture)

    local uiCamera = g_Game.UIManager:GetUICamera()
    if Utils.IsNull(uiCamera) then return end

    local basicCamera = self.city:GetCamera()
    if basicCamera == nil then return end
    basicCamera:StopTween()

    local recommendSize = ConfigRefer.CityFurnitureTypes:Find(furniture.furType):FocusCameraSize()
    local viewport = uiCamera:WorldToViewportPoint(self._p_focus_target.position)
    local cellTile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local tileView = cellTile.tileView
    local mainAssets = tileView and tileView:GetMainAssets()
    ---@type CityTileAsset
    local asset = next(mainAssets or {})
    if asset then
        local flag, pos = asset:TryGetAnchorPos("holder_levelup")
        basicCamera:ZoomToWithFocus(recommendSize, viewport, pos, 0.5)
    else
        basicCamera:ZoomToWithFocus(recommendSize, viewport, cellTile:GetWorldCenter(), 0.5)
    end
end

function CityLegoBuildingUIMediator:RefreshFurniturePageToggle()
    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    ---@type CityLegoBuildingUIPageToggleButtonData[]
    local toggleButtonData = {}
    local togglePageMap = {}
    if furniture:IsLocked() then
        local data = {onClick = Delegate.GetOrCreate(self, self.OnClickRepair), name = CityLegoI18N.UI_Repair, selected = false, showUpgrade = false}
        table.insert(toggleButtonData, data)
        togglePageMap[FurniturePageDefine.Repair] = data
    else
        local specialData = self.param:GetSpecialData(self.currentFurnitureId)
        local canLevelUp = furniture:CanDoCityWork(CityWorkType.FurnitureLevelUp)
        local nextLvCfgCell = ModuleRefer.CityConstructionModule:GetFurnitureLevelCell(furniture.furType, furniture.level + 1)
        canLevelUp = canLevelUp and nextLvCfgCell ~= nil
        if canLevelUp then
            local data = {onClick = Delegate.GetOrCreate(self, self.OnClickUpgrade), name = CityLegoI18N.UI_Upgrade, selected = false, showUpgrade = false}
            table.insert(toggleButtonData, data)
            togglePageMap[FurniturePageDefine.Upgrade] = data
        end
        if not canLevelUp then
            local data = {onClick = Delegate.GetOrCreate(self, self.OnClickDetails), name = specialData ~= nil and specialData.buttonI18N or CityLegoI18N.UI_Details, selected = false, showUpgrade = false, payload = specialData}
            table.insert(toggleButtonData, data)
            togglePageMap[FurniturePageDefine.Details] = data
        end
        if furniture:CanDoCityWork(CityWorkType.Process) and furniture:IsMakingFurnitureProcess() then
            local data = {onClick = Delegate.GetOrCreate(self, self.OnClickProcess), name = CityLegoI18N.UI_Process, selected = false, showUpgrade = false}
            table.insert(toggleButtonData, data)
            togglePageMap[FurniturePageDefine.Process] = data
        end
        --- 仅当家具可升级且有Special功能时，才显示Special页签，否则会合并到上面的Details界面里
        if canLevelUp and specialData ~= nil then
            local data = {onClick = Delegate.GetOrCreate(self, self.OnClickDetails), name = specialData.buttonI18N, selected = false, showUpgrade = false, payload = specialData}
            table.insert(toggleButtonData, data)
            togglePageMap[FurniturePageDefine.Details] = data
        end
    end

    self.toggleButtonData = toggleButtonData
    self.togglePageMap = togglePageMap

    if self.param.priorityPage and self.togglePageMap[self.param.priorityPage] then
        self.togglePageMap[self.param.priorityPage].selected = true
    else
        self.toggleButtonData[1].selected = true
    end

    ---@type table<CityLegoBuildingUIPageToggleButtonData, CityLegoBuildingUIPageToggleButton>
    self.toggleInst = {}
    self._page_toggle_pool:HideAll()

    self._p_group_tab:SetVisible(#self.toggleButtonData > 1)
    if #self.toggleButtonData > 1 then
        for i, v in ipairs(self.toggleButtonData) do
            local toggleButton = self._page_toggle_pool:GetItem()
            self.toggleInst[v] = toggleButton
            toggleButton:FeedData(v)
        end
    end
end

---@param data CityLegoBuildingUIPageToggleButtonData
function CityLegoBuildingUIMediator:ChangeToggleButtonSelected(data)
    for cache, button in pairs(self.toggleInst) do
        cache.selected = cache == data
        button:FeedData(cache)
    end
end

---@param data CityLegoBuildingUIPageToggleButtonData
function CityLegoBuildingUIMediator:OnClickProcess(data)
    self:ChangeToggleButtonSelected(data)
    if self.lastPage then
        self.lastPage:SetVisible(false)
    end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    local workCfg = ConfigRefer.CityWork:Find(furniture:GetWorkCfgId(CityWorkType.Process))
    local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local param = CityWorkProcessUIParameter.new(workCfg, tile)
    self.lastProcessParam = param
    self.lastPageDefine = FurniturePageDefine.Process
    self:TryShowProcessSubPrefab()
end

---@param data CityLegoBuildingUIPageToggleButtonData
function CityLegoBuildingUIMediator:OnClickCollect(data)
    self:ChangeToggleButtonSelected(data)
    if self.lastPage then
        self.lastPage:SetVisible(false)
    end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    local workCfg = ConfigRefer.CityWork:Find(furniture:GetWorkCfgId(CityWorkType.FurnitureResCollect))
    local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local param = CityWorkCollectUIParameter.new(workCfg, tile)
    self.lastCollectParam = param
    self.lastPageDefine = FurniturePageDefine.Collect
    self:TryShowCollectSubPrefab()
end

---@param data CityLegoBuildingUIPageToggleButtonData
function CityLegoBuildingUIMediator:OnClickProduce(data)
    self:ChangeToggleButtonSelected(data)
    if self.lastPage then
        self.lastPage:SetVisible(false)
    end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    local workCfg = ConfigRefer.CityWork:Find(furniture:GetWorkCfgId(CityWorkType.ResourceGenerate))
    local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local param = CityWorkProduceUIParameter.new(workCfg, tile)
    self.lastProduceParam = param
    self.lastPageDefine = FurniturePageDefine.Produce
    self:TryShowProduceSubPrefab()
end

---@param data CityLegoBuildingUIPageToggleButtonData
function CityLegoBuildingUIMediator:OnClickUpgrade(data)
    self:ChangeToggleButtonSelected(data)
    if self.lastPage then
        self.lastPage:SetVisible(false)
    end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    local workCfg = ConfigRefer.CityWork:Find(furniture:GetWorkCfgId(CityWorkType.FurnitureLevelUp))
    local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local param = CityWorkFurnitureUpgradeUIParameter.new(workCfg, tile)
    self.lastUpgradeParam = param
    self.lastPageDefine = FurniturePageDefine.Upgrade
    self:TryShowUpgradeSubPrefab()
end

---@param data CityLegoBuildingUIPageToggleButtonData
function CityLegoBuildingUIMediator:OnClickDetails(data)
    self:ChangeToggleButtonSelected(data)
    if self.lastPage then
        self.lastPage:SetVisible(false)
    end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local param = CityFurnitureDetailsUIParameter.new(tile, data.payload)
    self.lastDetailsParam = param
    self.lastPageDefine = FurniturePageDefine.Details
    self:TryShowDetailsSubPrefab()
end

---@param data CityLegoBuildingUIPageToggleButtonData
function CityLegoBuildingUIMediator:OnClickEnergy(data)
    self:ChangeToggleButtonSelected(data)
    if self.lastPage then
        self.lastPage:SetVisible(false)
    end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local param = CityFurnitureEnergyUIParameter.new(tile)
    self.lastEnergyParam = param
    self.lastPageDefine = FurniturePageDefine.Energy
    self:TryShowEnergySubPrefab()
end

---@param data CityLegoBuildingUIPageToggleButtonData
function CityLegoBuildingUIMediator:OnClickCatchPet(data)
    self:ChangeToggleButtonSelected(data)
    if self.lastPage then
        self.lastPage:SetVisible(false)
    end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local param = CityFurnitureCatchPetUIParameter.new(tile)
    self.lastCatchPetParam = param
    self.lastPageDefine = FurniturePageDefine.CatchPet
    self:TryShowCatchPetSubPrefab()
end

---@param data CityLegoBuildingUIPageToggleButtonData
function CityLegoBuildingUIMediator:OnClickRepair(data)
    self:ChangeToggleButtonSelected(data)
    if self.lastPage then
        self.lastPage:SetVisible(false)
    end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    self.lastRepairParam = furniture
    self.lastPageDefine = FurniturePageDefine.Repair
    self:TryShowRepairSubPrefab()
end

---@param data CityLegoBuildingUIPageToggleButtonData
function CityLegoBuildingUIMediator:OnClickSpecial(data)
    self:ChangeToggleButtonSelected(data)
    if self.lastPage then
        self.lastPage:SetVisible(false)
    end

    self.lastSpecialParam = data.payload
    self.lastPageDefine = FurniturePageDefine.Special
    self:TryShowSpecialSubPrefab()
end

function CityLegoBuildingUIMediator:FurnitureRemoved()
    if self.legoBuilding == nil then
        return self:CloseSelf()
    end

    if self.lastPage then
        self.lastPage:SetVisible(false)
    end

    self._p_table_furniture:Clear()
    self.furnitureData = {}
    local selectFurnitureValid = false
    for i, v in ipairs(self.legoBuilding.payload.InnerFurnitureIds) do
        if v == self.currentFurnitureId then selectFurnitureValid = true end

        local furniture = self.city.furnitureManager:GetFurnitureById(v)
        local data = {furniture = furniture, isSelect = self.currentFurnitureId == v, onClick = Delegate.GetOrCreate(self, self.OnClickFurniture)}
        self._p_table_furniture:AppendData(data)
        table.insert(self.furnitureData, data)
    end

    if not selectFurnitureValid then
        self.currentFurnitureId = nil
    end

    if self.currentFurnitureId == nil then
        if self.legoBuilding.payload.InnerFurnitureIds:Count() > 0 then
            self.currentFurnitureId = self.legoBuilding.payload.InnerFurnitureIds[1]
            self:ShowFurniturePage(self.currentFurnitureId)
        else
            self:CloseSelf()
        end
    else
        self:ShowFurniturePage(self.currentFurnitureId)
    end
end

function CityLegoBuildingUIMediator:ProcessReopen()
    self._p_group_process:SetVisible(false)
    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    local workCfg = ConfigRefer.CityWork:Find(furniture:GetWorkCfgId(CityWorkType.Process))
    local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local param = CityWorkProcessUIParameter.new(workCfg, tile)
    self._p_group_process:SetVisible(true, param)
end

function CityLegoBuildingUIMediator:CollectReopen()
    self._p_group_collect:SetVisible(false)
    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    local workCfg = ConfigRefer.CityWork:Find(furniture:GetWorkCfgId(CityWorkType.FurnitureResCollect))
    local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local param = CityWorkCollectUIParameter.new(workCfg, tile)
    self._p_group_collect:SetVisible(true, param)
end

function CityLegoBuildingUIMediator:ProduceReopen()
    self._p_group_create_collection:SetVisible(false)
    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    local workCfg = ConfigRefer.CityWork:Find(furniture:GetWorkCfgId(CityWorkType.FurnitureResCollect))
    local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    local param = CityWorkProduceUIParameter.new(workCfg, tile)
    self._p_group_create_collection:SetVisible(true, param)
end

---@param workCfg CityWorkConfigCell
function CityLegoBuildingUIMediator:GetBestFreeCitizenForWork(workCfg)
    local citizenId = nil
    if self.legoBuilding ~= nil then
        citizenId = self.legoBuilding:GetBestFreeCitizenForWork(workCfg)
    end
    if citizenId == nil then
        citizenId = self.city.cityWorkManager:GetBestFreeCitizenForWork(workCfg)
    end
    return citizenId
end

function CityLegoBuildingUIMediator:OnUpgradeWorkingChange(city, batchEvt)
    if city ~= self.city then return end
    if batchEvt.Change[self.currentFurnitureId] == nil then return end
end

function CityLegoBuildingUIMediator:TryShowRoomSubPrefab()
    if self._p_group_room == nil then
        self:LoadRoomPage()
    else
        self._p_group_room:SetVisible(true)
        self._p_group_room:FeedData(self.legoBuilding)
        self.lastPage = self._p_group_room
    end
end

function CityLegoBuildingUIMediator:LoadRoomPage()
    if self._p_group_room ~= nil then return end
    if self.loadingRoomPage then return end
    self.loadingRoomPage = true
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_city_room", "content", Delegate.GetOrCreate(self, self.OnRoomPageLoaded),true)
end

function CityLegoBuildingUIMediator:OnRoomPageLoaded(go,allFinish)
    if not allFinish then return end
    self.loadingRoomPage = false
    self._p_group_room = self:LuaObject("p_group_room")

    if self.currentFurnitureId == nil and self.lastPageDefine == FurniturePageDefine.Room then
        self._p_group_room:SetVisible(true)
        self._p_group_room:FeedData(self.legoBuilding)
        self.lastPage = self._p_group_room
    else
        self._p_group_room:SetVisible(false)
    end
end

function CityLegoBuildingUIMediator:TryShowProcessSubPrefab()
    if self._p_group_process == nil then
        self:LoadProcessPage()
    else
        self._p_group_process:SetVisible(true)
        self._p_group_process:FeedData(self.lastProcessParam)
        self._p_group_process:AgentFurnitureWorkComp(self._layout)
        self.lastPage = self._p_group_process
    end
end

function CityLegoBuildingUIMediator:LoadProcessPage()
    if self._p_group_process ~= nil then return end
    if self.loadingProcessPage then return end
    self.loadingProcessPage = true
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_city_room_process", "p_group_furniture", Delegate.GetOrCreate(self, self.OnProcessPageLoaded),true)
end

function CityLegoBuildingUIMediator:OnProcessPageLoaded(go,allFinish)
    if not allFinish then return end
    self.loadingProcessPage = false
    self._p_group_process = self:LuaObject("p_group_process")

    if self.lastPageDefine == FurniturePageDefine.Process then
        self._p_group_process:SetVisible(true)
        self._p_group_process:FeedData(self.lastProcessParam)
        self._p_group_process:AgentFurnitureWorkComp(self._layout)
        self.lastPage = self._p_group_process
    else
        self._p_group_process:SetVisible(false)
    end
end

function CityLegoBuildingUIMediator:TryShowCollectSubPrefab()
    if self._p_group_collect == nil then
        self:LoadCollectPage()
    else
        self._p_group_collect:SetVisible(true)
        self._p_group_collect:FeedData(self.lastCollectParam)
        self.lastPage = self._p_group_collect
    end
end

function CityLegoBuildingUIMediator:LoadCollectPage()
    if self._p_group_collect ~= nil then return end
    if self.loadingCollectPage then return end
    self.loadingCollectPage = true
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_city_room_collect", "p_group_furniture", Delegate.GetOrCreate(self, self.OnCollectPageLoaded),true)
end

function CityLegoBuildingUIMediator:OnCollectPageLoaded(go,allFinish)
    if not allFinish then return end
    self.loadingCollectPage = false
    self._p_group_collect = self:LuaObject("p_group_collect")

    if self.lastPageDefine == FurniturePageDefine.Collect then
        self._p_group_collect:SetVisible(true)
        self._p_group_collect:FeedData(self.lastCollectParam)
        self.lastPage = self._p_group_collect
    else
        self._p_group_collect:SetVisible(false)
    end
end

function CityLegoBuildingUIMediator:TryShowProduceSubPrefab()
    if self._p_group_create_collection == nil then
        self:LoadProducePage()
    else
        self._p_group_create_collection:SetVisible(true)
        self._p_group_create_collection:FeedData(self.lastProduceParam)
        self.lastPage = self._p_group_create_collection
    end
end

function CityLegoBuildingUIMediator:LoadProducePage()
    if self._p_group_create_collection ~= nil then return end
    if self.loadingProducePage then return end
    self.loadingProducePage = true
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_city_room_create_collection", "p_group_furniture", Delegate.GetOrCreate(self, self.OnProducePageLoaded),true)
end

function CityLegoBuildingUIMediator:OnProducePageLoaded(go,allFinish)
    if not allFinish then return end
    self.loadingProducePage = false
    self._p_group_create_collection = self:LuaObject("p_group_create_collection")

    if self.lastPageDefine == FurniturePageDefine.Produce then
        self._p_group_create_collection:SetVisible(true)
        self._p_group_create_collection:FeedData(self.lastProduceParam)
        self.lastPage = self._p_group_create_collection
    else
        self._p_group_create_collection:SetVisible(false)
    end
end

function CityLegoBuildingUIMediator:TryShowUpgradeSubPrefab()
    if self._p_group_upgrade == nil then
        self:LoadUpgradePage()
    else
        self._p_group_upgrade:SetVisible(true)
        self._p_group_upgrade:FeedData(self.lastUpgradeParam)
        self.lastPage = self._p_group_upgrade
    end
end

function CityLegoBuildingUIMediator:LoadUpgradePage()
    if self._p_group_upgrade ~= nil then return end
    if self.loadingUpgradePage then return end
    self.loadingUpgradePage = true
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_city_room_upgrade", "p_group_furniture", Delegate.GetOrCreate(self, self.OnUpgradePageLoaded),true)
end

function CityLegoBuildingUIMediator:OnUpgradePageLoaded(go,allFinish)
    if not allFinish then return end
    self.loadingUpgradePage = false
    self._p_group_upgrade = self:LuaObject("p_group_upgrade")

    if self.lastPageDefine == FurniturePageDefine.Upgrade then
        self._p_group_upgrade:SetVisible(true)
        self._p_group_upgrade:FeedData(self.lastUpgradeParam)
        self.lastPage = self._p_group_upgrade
    else
        self._p_group_upgrade:SetVisible(false)
    end
end

function CityLegoBuildingUIMediator:TryShowDetailsSubPrefab()
    if self._p_group_info == nil then
        self:LoadDetailsPage()
    else
        self._p_group_info:SetVisible(true)
        self._p_group_info:FeedData(self.lastDetailsParam)
        self.lastPage = self._p_group_info
    end
end

function CityLegoBuildingUIMediator:LoadDetailsPage()
    if self._p_group_info ~= nil then return end
    if self.loadingDetailsPage then return end
    self.loadingDetailsPage = true
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_city_room_info", "p_group_furniture", Delegate.GetOrCreate(self, self.OnDetailsPageLoaded),true)
end

function CityLegoBuildingUIMediator:OnDetailsPageLoaded(go,allFinish)
    if not allFinish then return end
    self.loadingDetailsPage = false
    self._p_group_info = self:LuaObject("p_group_info")

    if self.lastPageDefine == FurniturePageDefine.Details then
        self._p_group_info:SetVisible(true)
        self._p_group_info:FeedData(self.lastDetailsParam)
        self.lastPage = self._p_group_info
    else
        self._p_group_info:SetVisible(false)
    end
end

function CityLegoBuildingUIMediator:TryShowEnergySubPrefab()
    if self._p_group_energy == nil then
        self:LoadEnergyPage()
    else
        self._p_group_energy:SetVisible(true)
        self._p_group_energy:FeedData(self.lastEnergyParam)
        self.lastPage = self._p_group_energy
    end
end

function CityLegoBuildingUIMediator:LoadEnergyPage()
    if self._p_group_energy ~= nil then return end
    if self.loadingEnergyPage then return end
    self.loadingEnergyPage = true
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_city_room_energy", "p_group_furniture", Delegate.GetOrCreate(self, self.OnEnergyPageLoaded),true)
end

function CityLegoBuildingUIMediator:OnEnergyPageLoaded(go,allFinish)
    if not allFinish then return end
    self.loadingEnergyPage = false
    self._p_group_energy = self:LuaObject("p_group_energy")

    if self.lastPageDefine == FurniturePageDefine.Energy then
        self._p_group_energy:SetVisible(true)
        self._p_group_energy:FeedData(self.lastEnergyParam)
        self.lastPage = self._p_group_energy
    else
        self._p_group_energy:SetVisible(false)
    end
end

function CityLegoBuildingUIMediator:TryShowCatchPetSubPrefab()
    if self._p_group_catch_pet == nil then
        self:LoadCatchPetPage()
    else
        self._p_group_catch_pet:SetVisible(true)
        self._p_group_catch_pet:FeedData(self.lastCatchPetParam)
        self.lastPage = self._p_group_catch_pet
    end
end

function CityLegoBuildingUIMediator:LoadCatchPetPage()
    if self._p_group_catch_pet ~= nil then return end
    if self.loadingCatchPetPage then return end
    self.loadingCatchPetPage = true
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_city_room_catch_pet", "p_group_furniture", Delegate.GetOrCreate(self, self.OnCatchPetPageLoaded),true)
end

function CityLegoBuildingUIMediator:OnCatchPetPageLoaded(go,allFinish)
    if not allFinish then return end
    self.loadingCatchPetPage = false
    self._p_group_catch_pet = self:LuaObject("p_group_catch_pet")

    if self.lastPageDefine == FurniturePageDefine.CatchPet then
        self._p_group_catch_pet:SetVisible(true)
        self._p_group_catch_pet:FeedData(self.lastCatchPetParam)
        self.lastPage = self._p_group_catch_pet
    else
        self._p_group_catch_pet:SetVisible(false)
    end
end

function CityLegoBuildingUIMediator:TryShowRepairSubPrefab()
    if self._p_group_repair == nil then
        self:LoadRepairPage()
    else
        self._p_group_repair:SetVisible(true)
        self._p_group_repair:FeedData(self.lastRepairParam)
        self.lastPage = self._p_group_repair
    end
end

function CityLegoBuildingUIMediator:LoadRepairPage()
    if self._p_group_repair ~= nil then return end
    if self.loadingRepairPage then return end
    self.loadingRepairPage = true
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_city_room_repair", "p_group_furniture", Delegate.GetOrCreate(self, self.OnRepairPageLoaded),true)
end

function CityLegoBuildingUIMediator:OnRepairPageLoaded(go,allFinish)
    if not allFinish then return end
    self.loadingRepairPage = false
    self._p_group_repair = self:LuaObject("p_group_repair")

    if self.lastPageDefine == FurniturePageDefine.Repair then
        self._p_group_repair:SetVisible(true)
        self._p_group_repair:FeedData(self.lastRepairParam)
        self.lastPage = self._p_group_repair
    else
        self._p_group_repair:SetVisible(false)
    end
end

function CityLegoBuildingUIMediator:TryShowSpecialSubPrefab()
    if self._p_group_special == nil then
        self:LoadSpecialPage()
    else
        self._p_group_special:SetVisible(true)
        self._p_group_special:FeedData(self.lastSpecialParam)
        self.lastPage = self._p_group_special
    end
end

function CityLegoBuildingUIMediator:LoadSpecialPage()
    if self._p_group_special ~= nil then return end
    if self.loadingSpecialPage then return end
    self.loadingSpecialPage = true
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, "child_city_room_special", "p_group_furniture", Delegate.GetOrCreate(self, self.OnSpecialPageLoaded),true)
end

function CityLegoBuildingUIMediator:OnSpecialPageLoaded(go,allFinish)
    if not allFinish then return end
    self.loadingSpecialPage = false
    self._p_group_special = self:LuaObject("p_group_special")

    if self.lastPageDefine == FurniturePageDefine.Special then
        self._p_group_special:SetVisible(true)
        self._p_group_special:FeedData(self.lastSpecialParam)
        self.lastPage = self._p_group_special
    else
        self._p_group_special:SetVisible(false)
    end
end

function CityLegoBuildingUIMediator:UpdateHasEmptyCitizenSlot()
    if self.legoBuilding == nil then return end

    local maxCitizenCount = self.legoBuilding:GetMaxCitizenCount()
    local currentCitizenCount = self.legoBuilding.payload.InnerHeroIds:Count()
    local freeCitizenCount = self.city.cityCitizenManager:GetHomelessCitizenCount()
end

function CityLegoBuildingUIMediator:OnLegoBatchUpdate(city, batchEvt)
    if city ~= self.city then return end
    if self.legoBuilding == nil then return end

    if not batchEvt.Change then return end
    if batchEvt.Change[self.legoBuilding.id] == nil then return end

    g_Game.SpriteManager:LoadSprite(self.legoBuilding:GetRoomUILeftToggleIcon(), self._p_icon_room)
end

---@param legoBuilding CityLegoBuilding
function CityLegoBuildingUIMediator:OnBuildingScoreChanged(legoBuilding, oldScore, newScore)
    if legoBuilding ~= self.legoBuilding then return end

    local oldLevel, newLevel = self.buildingLv, legoBuilding.roomLevel
    local oldProgress, newProgress = self.lvProgress, legoBuilding:GetScoreProgress()
    if oldLevel >= newLevel and oldProgress >= newProgress then return end

    self._p_text_title_name.text = I18N.Get(self.legoBuilding:GetNameI18N())
    self.buildingLv = self.legoBuilding.roomLevel
    self.lvProgress = self.legoBuilding:GetScoreProgress()
    self.maxScore = self.legoBuilding:GetCurrentMaxScore()

    if self.animating then
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnProgressAnimTick))
        self._p_progress_score.value = self.endValue
        self._p_text_title_score.text = tostring(self.buildingLv)
    end

    local totalProcess
    if newLevel > oldLevel then
        totalProcess = (1-oldProgress) + (newLevel - oldLevel - 1) + newProgress
    else
        totalProcess = newProgress - oldProgress
    end
    local totalTimeCost = 1 ---TODO:等着对一个VX动效的时长
    self:StartScoreAnim(newLevel - oldLevel, oldProgress, newProgress, totalProcess / totalTimeCost, oldScore, newScore)
end

function CityLegoBuildingUIMediator:StartScoreAnim(fullTimes, startValue, endValue, step, oldScore, newScore)
    self.moveStep = step
    self.startValue = startValue
    self.endValue = endValue
    self.fullTimes = fullTimes
    self.animating = true
    self.textAnim = NumberAnim.new(oldScore, newScore, 1, Delegate.GetOrCreate(self, self.HideScoreText))
    self.textAnim:Start()
    self._p_text_room_score:SetVisible(true)
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnProgressAnimTick))
end

function CityLegoBuildingUIMediator:OnProgressAnimTick(delta)
    local target = self.fullTimes > 0 and 1 or self.endValue
    local newValue = self._p_progress_score.value + math.clamp01(self.moveStep * delta)
    if newValue >= target then
        if self.fullTimes > 0 then
            self.fullTimes = self.fullTimes - 1
            self._p_progress_score.value = math.clamp01(newValue - 1)
            self._p_text_title_score.text = tostring(self.buildingLv - self.fullTimes)
        else
            self._p_progress_score.value = self.endValue
            self._p_text_title_score.text = tostring(self.buildingLv)
            g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnProgressAnimTick))
            self.animating = false
            self._p_text_room_score:SetVisible(false)
        end
    else
        self._p_progress_score.value = newValue
    end

    self.textAnim:Tick(delta)
    self._p_text_room_score.text = string.format("<color=%s>%s</color>/%d", ColorUtil.FromGammaStrToLinearStr(ColorConsts.army_green), self.textAnim:GetText(), self.maxScore)
end

function CityLegoBuildingUIMediator:HideScoreText()
    self._p_text_room_score:SetVisible(false)
end

function CityLegoBuildingUIMediator:OnBuffSelectChange(isSuccess, reply, rpc)
    if not isSuccess then return end
    if not self.legoBuilding then return end

    if self.lastPageDefine == FurniturePageDefine.Room then
        self._p_group_room:FeedData(self.legoBuilding)
    end
    self:UpdateRoomBuff()
    self._p_text_title_name.text = I18N.Get(self.legoBuilding:GetNameI18N())
end

function CityLegoBuildingUIMediator:IsCurrentFurnitureUpgradeConditionMeet()
    if self.currentFurnitureId == nil then
        return false
    end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    if furniture == nil then
        return false
    end

    return furniture:IsUpgradeConditionMeet()
end

function CityLegoBuildingUIMediator:OnClickChangeBuff()
    if self.legoBuilding == nil then return end

    local param = CityLegoBuffRouteMapUIParameter.new(self.city, self.legoBuilding)
    g_Game.UIManager:Open(UIMediatorNames.CityLegoBuffRouteMapUIMediator, param)
end

function CityLegoBuildingUIMediator:OnClickEnterIndoorEdit()
    if self.legoBuilding == nil then return end

    self.legoBuilding:ClearNewBuffHint()
    self.city:TryEnterEditMode(self.legoBuilding)
end

function CityLegoBuildingUIMediator:OnClickMakingFurniture()
    self:OnClickProcess()
end

function CityLegoBuildingUIMediator:ApplyFurnitureWorkComp(furniture)
    self._layout:FeedData(furniture)
end

function CityLegoBuildingUIMediator:OnQuickGotoFurniture(gotoId, furnitureId)
    if self.legoBuilding == nil then
        g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_LEGO_SELECT_TARGET_FURNITURE_FAILED, gotoId)
        return
    end
    for i, v in ipairs(self.furnitureData) do
        if v.furniture and v.furniture.singleId == furnitureId then
            self:ShowFurniturePage(furnitureId)
            return
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_LEGO_SELECT_TARGET_FURNITURE_FAILED, gotoId)
end

function CityLegoBuildingUIMediator:CancelFurnitureTileSelected()
    if not self.furnitureTile then return end
    self.furnitureTile:SetSelected(false)
    self.furnitureTile = nil
end

function CityLegoBuildingUIMediator:SetFurnitureSelected()
    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    if furniture == nil then return end

    local furnitureTile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
    if furnitureTile == nil then return end

    self.furnitureTile = furnitureTile
    self.furnitureTile:SetSelected(true)
end

function CityLegoBuildingUIMediator:OnFurnitureUpdate(city, batchEvt)
    if city ~= self.city then return end
    if self.currentFurnitureId == nil then return end
    if batchEvt == nil or batchEvt.Change == nil then return end
    if batchEvt.Change[self.currentFurnitureId] == nil then return end

    local furniture = self.city.furnitureManager:GetFurnitureById(self.currentFurnitureId)
    self._layout:OnFurnitureUpdate(furniture)
end

return CityLegoBuildingUIMediator