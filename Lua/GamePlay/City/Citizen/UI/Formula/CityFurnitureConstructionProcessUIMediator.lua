--- scene:scene_construction_process

local CityConst = require("CityConst")
local I18N = require("I18N")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local EventConst = require("EventConst")
local OnChangeHelper = require("OnChangeHelper")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local UIHelper = require("UIHelper")
local CityFurnitureTypesSelectedFocusType = require("CityFurnitureTypesSelectedFocusType")
local CityWorkTargetType = require("CityWorkTargetType")
local BaseUIMediator = require("BaseUIMediator")

---@class CityFurnitureConstructionProcessUIMediatorData
---@field city MyCity
---@field furniture CityFurniture

---@class CityFurnitureConstructionProcessUIMediator:BaseUIMediator
---@field new fun():CityFurnitureConstructionProcessUIMediator
---@field super BaseUIMediator
local CityFurnitureConstructionProcessUIMediator = class('CityFurnitureConstructionProcessUIMediator', BaseUIMediator)

function CityFurnitureConstructionProcessUIMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type CityFurnitureConstructionProcessUIMediatorData
    self._param = nil
    ---@type MyCity
    self._city = nil
    ---@type CityFurniture
    self._furniture = nil
    ---@type CityFurnitureTypesConfigCell
    self._furnitureTypeConfig = nil
    ---@type CityCitizenWorkData
    self._workData = nil
    ---@type CityCitizenManager
    self._citizenMgr = nil
    ---@type CityFurnitureManager
    self._furnitureMgr = nil
    ---@type ZoomToWithFocusStackStatus
    self._backHandle = nil
    self._bindCitizenId = nil
    
    ---@type CityFurnitureConstructionProcessFormulaCellParameter[]
    self._formulaList = {}
    ---@type table<number, CityFurnitureConstructionProcessFormulaCellParameter[]>
    self._needItem2FormulaMap = {}
    ---@type table<number, CityFurnitureConstructionProcessFormulaCellParameter[]>
    self._needAbility2FormulaMap = {}
    ---@type table<number, CityFurnitureConstructionProcessFormulaCellParameter[]>
    self._outputItem2FormulaMap = {}
    self._lastDragIndex = -1
    ---@type CS.UnityEngine.Vector2
    self._dragPos = nil
    
    ---@type CityFurnitureConstructionProcessQueueCell[]
    self._dragTargetCells = {}
    ---@type table<CityFurnitureConstructionProcessQueueCell, boolean>
    self._dragSetTargetCellMap = {}
    ---@type boolean|nil
    self._beforeDragScrollRectHorizontal = nil
    ---@type fun()
    self._clickBlockerCallback = nil
    
    ---@type CityFurnitureConstructionProcessQueueCellData[]
    self._queueCellsData = {}
    
    self._bindSafeAreaId = nil
    self._isNotFunctional = false
    ---@type CS.UnityEngine.GameObject[]
    self._p_arrows = {}
end

function CityFurnitureConstructionProcessUIMediator:OnCreate(_)
    self._p_click_scene_bubble = self:BindComponent("p_click_scene_bubble", typeof(CS.Empty4Raycast))
    self:PointerClick("p_click_scene_bubble", Delegate.GetOrCreate(self, self.OnClickEmpty))
    --self._p_time_need = self:GameObject("p_time_need")
    ---@type CommonTimer
    self._child_time_editor_pre = self:LuaObject("child_time_editor_pre")
    self._p_text_time = self:Text("p_text_time", I18N.Temp().text_cost_time)
    self._p_text_lv = self:Text("p_text_lv")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_buff = self:Text("p_text_buff")
    self._child_comp_btn_detail = self:GameObject("child_comp_btn_detail")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickBtnDetail))
    self._p_table = self:TableViewPro("p_table")
    self._p_table_layout = self:BindComponent("p_table", typeof(CS.UnityEngine.UI.LayoutElement))
    self._p_arrow_root = self:Transform("p_arrow_root")
    self._p_icon_arrow_template = self:GameObject("p_icon_arrow_template")
    self._p_icon_arrow_template:SetVisible(false)
    ---@type CityFurnitureConstructionProcessCitizenBlock
    self._p_resident_root = self:LuaObject("p_resident_root")
    self._p_pollution = self:GameObject("p_pollution")
    self._p_text_pollution = self:Text("p_text_pollution", "crafting_creep_debuff")
    self._p_table_process = self:TableViewPro("p_table_process")
    self._p_table_process.OnScrollRectMovingAction = Delegate.GetOrCreate(self, self.OnFormulaTableScroll)
    self._p_table_process.OnScrollRectEndAction = Delegate.GetOrCreate(self, self.OnFormulaTableScrollEnd)
    ---@type CityFurnitureConstructionProcessDragCell
    self._p_dragMove_Cell = self:LuaObject("p_dragMove_Cell")
    ---@type CityFurnitureConstructionProcessRequireTips
    self._p_tips_item = self:LuaObject("p_tips_item")
    ---@type CityFurnitureConstructionProcessTipsDetail
    self._p_tips_detail = self:LuaObject("p_tips_detail")
    self._p_rect_tip_range = self:RectTransform("p_rect_tip_range")
    ---@type CommonCanvasRaycastFilter
    self._p_touch_blocker = self:LuaObject("p_touch_blocker")
    self._p_touch_blocker_click = self:PointerClick("p_touch_blocker", Delegate.GetOrCreate(self, self.OnClickBlocker))
    self._p_hint = self:GameObject("p_hint")
    self._p_text_hint = self:Text("p_text_hint", "city_city_set_room_tips_7")
    self._p_focus_target = self:RectTransform("p_focus_target")
    self._p_text_buff:SetVisible(false)
    self._child_comp_btn_detail:SetVisible(false)
    ---@type CityFurnitureConstructionProcessSelectedTip
    self._p_tips_item_produce = self:LuaObject("p_tips_item_produce")
    self._p_block_for_selectedTips = self:GameObject("p_block_for_selectedTips")
    self:PointerDown("p_block_for_selectedTips", Delegate.GetOrCreate(self._p_tips_item_produce, self._p_tips_item_produce.OnClickBlocker))
    
    self._p_block_for_selectedTips:SetVisible(false)
    self._p_tips_item_produce:SetVisible(false)
end

function CityFurnitureConstructionProcessUIMediator:OnShow(_)
    ModuleRefer.InventoryModule:ForceInitCache()
    self:SetupEvents(true)
    self:HideHUD()
end

function CityFurnitureConstructionProcessUIMediator:OnHide(_)
    self:RestoreHUD()
    self:SetupEvents(false)
end

function CityFurnitureConstructionProcessUIMediator:HideHUD()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, false)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_TASK_TEMP_FOLD, true)
end

function CityFurnitureConstructionProcessUIMediator:RestoreHUD()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, true)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_TASK_TEMP_FOLD, false)
end

---@param param CityFurnitureConstructionProcessUIMediatorData
function CityFurnitureConstructionProcessUIMediator:OnOpened(param)
    self._param = param
    self._city = param.city
    self._citizenMgr = self._city.cityCitizenManager
    self._furnitureMgr = self._city.furnitureManager
    self._furniture = param.furniture
    self._furnitureTypeConfig = ConfigRefer.CityFurnitureTypes:Find(param.furniture.furnitureCell:Type())
    self._workData = self._citizenMgr:GetWorkDataByTarget(self._furniture:UniqueId(), CityWorkTargetType.Furniture)
    
    self:DragSelectedCleanup()
    self:SetupFromFurniture()
    self:AutoSelectCitizen()
    self:SetupCitizen()
    self:GenerateQueueTable()
    self:GenerateFormulaTable()
    self:FocusOnTarget()
end

function CityFurnitureConstructionProcessUIMediator:OnClose(_)
    if  self._p_table_process then
        self._p_table_process.OnScrollRectMovingAction = nil
        self._p_table_process.OnScrollRectEndAction = nil
    end
    self:DragSelectedCleanup()
    ModuleRefer.CityCitizenModule:ApplyDelayMarkItem(false)
end

function CityFurnitureConstructionProcessUIMediator:SetupEvents(add)
    if add then
        g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnCastleItemChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleAbility.MsgPath, Delegate.GetOrCreate(self, self.OnCastleAbilityChanged))
        g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
        g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_CHANGE, Delegate.GetOrCreate(self, self.OnWorkDataChanged))
        g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_DEL, Delegate.GetOrCreate(self, self.OnWorkDataRemoved))
        g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataNeedRefresh))
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
        g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnSafeAreaStatusChanged))
    else
        g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnSafeAreaStatusChanged))
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
        g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataNeedRefresh))
        g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_DEL, Delegate.GetOrCreate(self, self.OnWorkDataRemoved))
        g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_CHANGE, Delegate.GetOrCreate(self, self.OnWorkDataChanged))
        g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleAbility.MsgPath, Delegate.GetOrCreate(self, self.OnCastleAbilityChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnCastleItemChanged))
    end
end

function CityFurnitureConstructionProcessUIMediator:FocusOnTarget()
    if not self._furnitureTypeConfig or self._furnitureTypeConfig:SelectedFocus() == CityFurnitureTypesSelectedFocusType.None then
        return
    end
    ---@type CityFurnitureTile
    local tile = self._city.gridView.furnitureTiles:Get(self._furniture.x, self._furniture.y)
    if tile == nil then return end

    self._city:MoveGameObjIntoCamera(tile.tileView.root, 0.25, CityConst.TopHalfScreenCameraSafeArea)
end

function CityFurnitureConstructionProcessUIMediator:OnClickEmpty()
    self:CloseSelf()
end

function CityFurnitureConstructionProcessUIMediator:OnClickBtnDetail()
    self._p_tips_detail:SetVisible(true)
end

function CityFurnitureConstructionProcessUIMediator:OnClickBlocker()
    self._p_touch_blocker:SetRect(nil)
    if self._clickBlockerCallback then
        local call = self._clickBlockerCallback
        self._clickBlockerCallback = nil
        call()
    end
end

---@param a CityFurnitureConstructionProcessQueueCell
---@param b CityFurnitureConstructionProcessQueueCell
local function SortFreeQueueSlot(a, b) 
    return a._data.queueIndex < b._data.queueIndex
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param data CS.UnityEngine.EventSystems.PointerEventData
---@return boolean
function CityFurnitureConstructionProcessUIMediator:OnFormulaCellBeginDrag(cellData, data)
    if self._isNotFunctional then
        return false
    end
    if self._lastDragIndex > 0 then
        return false
    end
    self._lastDragIndex = cellData.index
    local screenPos = data.position
    self._dragPos = screenPos
    self:CheckAndSetDetailTip(screenPos)
    self:ShowDragCell(cellData, screenPos)
    self._p_table.ScrollRect:StopMovement()
    self._beforeDragScrollRectHorizontal = self._p_table.ScrollRect.horizontal
    self._p_table.ScrollRect.horizontal = false
    table.clear(self._dragTargetCells)
    ---@type CS.TableViewProCell[]
    local inViewCells = self._p_table._shownCellList
    local count = inViewCells.Count
    for i = 0, count -1 do
        local cell = inViewCells[i]
        ---@type CityFurnitureConstructionProcessQueueCell
        local tableLua = cell.Lua
        if tableLua and tableLua._data and tableLua._data.status == 0 then
            table.insert(self._dragTargetCells, tableLua)
        end
    end
    table.sort(self._dragTargetCells, SortFreeQueueSlot)
    return true
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFurnitureConstructionProcessUIMediator:OnFormulaCellDrag(cellData, data)
    if self._isNotFunctional then
        return false
    end
    if self._lastDragIndex ~= cellData.index then
        return
    end
    local screenPos = data.position
    self._dragPos = screenPos
    self:CheckAndSetDetailTip(screenPos)
    self:PickQueue(cellData, screenPos)
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFurnitureConstructionProcessUIMediator:OnFormulaCellEndDrag(cellData, data)
    if self._isNotFunctional then
        return false
    end
    if self._lastDragIndex ~= cellData.index then
        return
    end
    self._dragPos = nil
    self._lastDragIndex = -1
    self:SendAddQueue(cellData)
    self:DragSelectedCleanup()
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
function CityFurnitureConstructionProcessUIMediator:OnFormulaCellCancelDrag(cellData)
    if self._lastDragIndex ~= cellData.index then
        return
    end
    self._dragPos = nil
    self._lastDragIndex = -1
    self:CleanupTempSelected()
    self:DragSelectedCleanup()
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param rectTransform CS.UnityEngine.RectTransform
function CityFurnitureConstructionProcessUIMediator:OnFormulaCellLongPressFire(cellData, rectTransform)
    self._p_tips_item:FeedData(cellData)
    self._p_tips_item:SetVisible(true)
    if self._dragPos then
        self:CheckAndSetDetailTip(self._dragPos)
    else
        local pos = rectTransform.rect.center
        local worldPos = rectTransform:TransformPoint(pos.x, pos.y, 0)
        local uiCamera = g_Game.UIManager:GetUICamera()
        local screenPos = uiCamera:WorldToScreenPoint(worldPos)
        self:CheckAndSetDetailTip(CS.UnityEngine.Vector2(screenPos.x, screenPos.y))
    end
end

function CityFurnitureConstructionProcessUIMediator:OnFormulaCellLongPressEnd()
    self._p_tips_item:SetVisible(false)
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param rectTransform CS.UnityEngine.RectTransform
function CityFurnitureConstructionProcessUIMediator:ShowFormulaRequireTip(cellData, rectTransform)
    self._p_tips_item:FeedData(cellData)
    self._p_tips_item:SetVisible(true)
    local pos = rectTransform.rect.center
    local worldPos = rectTransform:TransformPoint(pos.x, pos.y, 0)
    local uiCamera = g_Game.UIManager:GetUICamera()
    local screenPos = uiCamera:WorldToScreenPoint(worldPos)
    self:CheckAndSetDetailTip(CS.UnityEngine.Vector2(screenPos.x, screenPos.y))
    self:SetBlockAllowRect(self._p_tips_item.SelfTrans, function()
        self._p_tips_item:SetVisible(false)
    end)
end

---@param screenPos CS.UnityEngine.Vector2
---@param skipCheckRange boolean
function CityFurnitureConstructionProcessUIMediator:CheckAndSetDetailTip(screenPos, skipCheckRange)
    if self._p_tips_item:IsHide() then
        return
    end
    local uiCamera = g_Game.UIManager:GetUICamera()
    local inRange = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(self._p_rect_tip_range, screenPos, uiCamera)
    if not inRange and not skipCheckRange then
        self._p_tips_item:SetVisible(false)
        return
    end
    local worldPos = uiCamera:ScreenToWorldPoint(CS.UnityEngine.Vector3(screenPos.x, screenPos.y, 0))
    local parent = self._p_tips_item.SelfTrans.parent
    local localPos = parent:InverseTransformPoint(worldPos)
    localPos.y = localPos.y + 280
    localPos.z = 0
    self._p_tips_item.SelfTrans.anchoredPosition3D = localPos
end

function CityFurnitureConstructionProcessUIMediator:SetupFromFurniture()
    self._p_text_lv.text = tostring(self._furniture.furnitureCell:Level())
    self._p_text_name.text = I18N.Get(self._furnitureTypeConfig:Name())
    self._p_pollution:SetVisible(self._furniture:IsPolluted())
    self._bindSafeAreaId = nil
    local furnitureTile = self._city.gridView:GetFurnitureTile(self._furniture.x, self._furniture.y)
    if furnitureTile:IsOutside() then
        local id = self._city.safeAreaWallMgr:GetSafeAreaId(self._furniture.x, self._furniture.y)
        if id ~= 0 then
            self._bindSafeAreaId = id
        end
    end
    self:OnSafeAreaStatusChanged(self._city:GetCastle().ID)
end

function CityFurnitureConstructionProcessUIMediator:GenerateQueueTable()
    self._p_table:Clear()
    table.clear(self._queueCellsData)
    local castle = self._city:GetCastle()
    local furnitureData = castle.CastleFurniture[self._furniture:UniqueId()]
    local slotCount = math.max(1, furnitureData.ProcessQueueCount) 
    local processInfo = furnitureData.ProcessInfo
    local dataCount = #processInfo
    local count = math.max(dataCount, slotCount)
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    self:OnQueueSlotCountChanged(count)
    local isRunning = false
    for i = 1, count do
        ---@type CityFurnitureConstructionProcessQueueCellData
        local cell = {}
        cell = {}
        cell.queueIndex = i
        cell.host = self
        cell.castle = castle
        if i > dataCount then
            cell.status = 0
        else
            cell.work = processInfo[i]
            cell.process = ConfigRefer.CityProcess:Find(cell.work.ConfigId)
            if cell.work.FinishTime and cell.work.FinishTime.ServerSecond <= nowTime and cell.work.LeftNum <= 0 then
                cell.status = 3
            else
                if not isRunning then
                    isRunning = true
                    cell.status = 2
                else
                    cell.status = 1
                end
            end
            cell.endTimestamp = cell.work.FinishTime and cell.work.FinishTime.ServerSecond
        end
        table.insert(self._queueCellsData, cell)
        self._p_table:AppendData(cell)
    end
    for i = count + 1, 4 do
        ---@type CityFurnitureConstructionProcessQueueCellData
        local cell = {}
        cell = {}
        cell.queueIndex = i
        cell.host = self
        cell.castle = castle
        cell.status = 4
        table.insert(self._queueCellsData, cell)
        self._p_table:AppendData(cell)
    end
end

function CityFurnitureConstructionProcessUIMediator:GenerateFormulaTable()
    self._lastDragIndex = -1
    table.clear(self._formulaList)
    table.clear(self._needItem2FormulaMap)
    table.clear(self._needAbility2FormulaMap)
    table.clear(self._outputItem2FormulaMap)
    local furnitureConfig = self._furniture.furnitureCell
    ---@type wds.Castle
    local castle = self._city:GetCastle()
    local castleAbility = castle and castle.CastleAbility or {}
    local InventoryModule = ModuleRefer.InventoryModule
    for i = 1, furnitureConfig:WorkAbilityLength() do
        local processId = furnitureConfig:WorkAbility(i)
        local process = ConfigRefer.CityProcess:Find(processId)
        ---@type CityFurnitureConstructionProcessFormulaCellParameter
        local formulaCellData = {}
        formulaCellData.index = i
        formulaCellData.processId = processId
        formulaCellData.process = process
        formulaCellData.host = self
        formulaCellData.isNotEnough = false
        formulaCellData.isLocked = false
        formulaCellData.costLake = {}
        local outputItemId = process:Output(1):ItemId()
        if not self._outputItem2FormulaMap[outputItemId] then
            self._outputItem2FormulaMap[outputItemId] = {}
        end
        table.insert(self._outputItem2FormulaMap[outputItemId], formulaCellData)
        formulaCellData.haveCount = InventoryModule:GetAmountByConfigId(outputItemId)
        local need = process:AbilityNeed()
        if need then
            local ability = ConfigRefer.CityAbility:Find(need)
            if ability then
                formulaCellData.needAbility = ability
                local abilityType = ability:Type()
                if not self._needAbility2FormulaMap[abilityType] then
                    self._needAbility2FormulaMap[abilityType] = {}
                end
                table.insert(self._needAbility2FormulaMap[abilityType], formulaCellData)
                local abV = castleAbility[abilityType] or 0
                if ability:Level() > abV then
                    formulaCellData.isLocked = true
                end
            end
        end
        for costIndex = 1, process:CostLength() do
            local cost = process:Cost(costIndex)
            local needItemId = cost:ItemId()
            local count = InventoryModule:GetAmountByConfigId(needItemId)
            local needCount = cost:Count()
            if not self._needItem2FormulaMap[needItemId] then
                self._needItem2FormulaMap[needItemId] = {}
            end
            table.insert(self._needItem2FormulaMap[needItemId], formulaCellData)
            local lake = needCount-count
            if lake > 0 then
                table.insert(formulaCellData.costLake, {id=needItemId, num=lake})
                formulaCellData.isNotEnough = true
            end
        end
        table.insert(self._formulaList, formulaCellData)
    end
    self._p_table_process:Clear()
    for _, v in ipairs(self._formulaList) do
        self._p_table_process:AppendData(v)
    end
end

function CityFurnitureConstructionProcessUIMediator:AutoSelectCitizen()
    local lastCitizenId = self._bindCitizenId
    self._bindCitizenId = nil
    if not self._workData then
        local pos = self._citizenMgr:GetWorkDataByTarget(self._furniture:UniqueId(), CityWorkTargetType.Furniture)
        if lastCitizenId and self._citizenMgr:IsCitizenFree(lastCitizenId) then
            self._bindCitizenId = lastCitizenId
        else
            local freeCitizen = self._citizenMgr:GetFreeWorkableCitizen(pos) or self._citizenMgr:GetFreeHomelessCitizen(pos)
            if freeCitizen then
               self._bindCitizenId = freeCitizen._data._id
            end
        end
    else
        self._bindCitizenId = self._citizenMgr:GetCitizenIdByWorkId(self._workData._id)
    end
end

function CityFurnitureConstructionProcessUIMediator:SetupCitizen()
    ---@type CityFurnitureConstructionProcessCitizenBlockData
    local param = {}
    param.citizenId = self._bindCitizenId
    param.citizenMgr = self._citizenMgr
    param.onSelectedChanged = Delegate.GetOrCreate(self, self.OnSelectedCitizenIdChanged)
    self._p_resident_root:FeedData(param)
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param screenPos CS.UnityEngine.Vector2
function CityFurnitureConstructionProcessUIMediator:ShowDragCell(cellData, screenPos)
    self._p_dragMove_Cell:SetVisible(true)
    self._p_dragMove_Cell:FeedData(cellData)
    self:SetupDragPosWithScreenPos(screenPos)
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param screenPos CS.UnityEngine.Vector2
function CityFurnitureConstructionProcessUIMediator:PickQueue(cellData, screenPos)
    self:SetupDragPosWithScreenPos(screenPos)
    ---@type CityFurnitureConstructionProcessQueueCell
    local last
    local requireItem = {}
    local preCostCount = {}
    for i = 1, cellData.process:CostLength() do
        local cost = cellData.process:Cost(i)
        local costItemId = cost:ItemId()
        requireItem[costItemId] = (requireItem[costItemId] or 0) + cost:Count()
    end
    for itemId, costCount in pairs(requireItem) do
        preCostCount[itemId] = costCount
    end
    for _, isPreSelected in pairs(self._dragSetTargetCellMap) do
        if isPreSelected then
            for itemId, needCount in pairs(requireItem) do
                preCostCount[itemId] = preCostCount[itemId] + needCount
            end
        end
    end
    local InventoryModule = ModuleRefer.InventoryModule
    for itemId, willCostCount in pairs(preCostCount) do
        if InventoryModule:GetAmountByConfigId(itemId) < willCostCount then
            self._p_dragMove_Cell:SetGray()
            return
        end
    end
    for _, v in ipairs(self._dragTargetCells) do
        if not self._dragSetTargetCellMap[v] then
            if not last then
                if v:IsInInCellRange(screenPos) then
                    v:TempSelected(cellData)
                    self._dragSetTargetCellMap[v] = true
                    break
                end
            elseif self._dragSetTargetCellMap[last] then
                if v:IsInInCellRange(screenPos) then
                    v:TempSelected(cellData)
                    self._dragSetTargetCellMap[v] = true
                    break
                end
            end
        end
        last = v
    end
end

function CityFurnitureConstructionProcessUIMediator:CleanupTempSelected()
    for _, cellData in ipairs(self._queueCellsData) do
        cellData.tempSelected = nil
        self._p_table:UpdateData(cellData)
    end
end

function CityFurnitureConstructionProcessUIMediator:DragSelectedCleanup()
    self._p_dragMove_Cell:SetVisible(false)
    table.clear(self._dragSetTargetCellMap)
    table.clear(self._dragTargetCells)
    if self._beforeDragScrollRectHorizontal ~= nil then
        self._p_table.ScrollRect.horizontal = self._beforeDragScrollRectHorizontal
    end
    self._beforeDragScrollRectHorizontal = nil
end

---@param screenPos CS.UnityEngine.Vector2
function CityFurnitureConstructionProcessUIMediator:SetupDragPosWithScreenPos(screenPos)
    local uiCamera = g_Game.UIManager:GetUICamera()
    local worldPos = uiCamera:ScreenToWorldPoint(CS.UnityEngine.Vector3(screenPos.x, screenPos.y))
    local parent = self._p_dragMove_Cell.SelfTrans.parent
    local localPos = parent:InverseTransformPoint(worldPos.x, worldPos.y, worldPos.z)
    localPos.y = localPos.y + 20
    localPos.z = 0
    self._p_dragMove_Cell.SelfTrans.anchoredPosition3D = localPos
end

---@param entity wds.CastleBrief
---@param changedData any
function CityFurnitureConstructionProcessUIMediator:OnCastleItemChanged(entity, changedData)
    if not self._city or entity.ID ~= self._city.uid then
        return
    end
    ---@type table<number, boolean>
    local changedItems = {}
    local add,remove,change = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    if add then
        for _, v in pairs(add) do
            changedItems[v.ConfigId] = true
        end
    end
    if remove then
        for _, v in pairs(remove) do
            changedItems[v.ConfigId] = true
        end
    end
    if change then
        for _, v in pairs(change) do
            changedItems[v[2].ConfigId] = true
        end
    end
    ---@type table<CityFurnitureConstructionProcessFormulaCellParameter, boolean>
    local needUpdateCell = {}
    for itemId, _ in pairs(changedItems) do
        local cellList = self._needItem2FormulaMap[itemId]
        if cellList then
            for _, cellData in pairs(cellList) do
                needUpdateCell[cellData] = true
            end
        end
        cellList = self._outputItem2FormulaMap[itemId]
        if cellList then
            for _, cellData in pairs(cellList) do
                needUpdateCell[cellData] = true
            end
        end
    end
    local InventoryModule = ModuleRefer.InventoryModule
    for cellData,_ in pairs(needUpdateCell) do
        local process = cellData.process
        local IsNotEnough = false
        local lakeChanged = false
        local costLake
        local haveCount = InventoryModule:GetAmountByConfigId(process:Output(1):ItemId())
        for i = 1, process:CostLength() do
            local cost = process:Cost(i)
            local has = InventoryModule:GetAmountByConfigId(cost:ItemId())
            local lake = cost:Count() - has
            if lake > 0 then
                if not costLake then
                    costLake = {}
                    if not cellData.costLake then
                        lakeChanged = true
                    end
                end
                IsNotEnough = true
                table.insert(costLake, {id = cost:ItemId(), num = lake })
            end
        end
        if not lakeChanged then
            if not costLake and cellData.costLake then
                lakeChanged = true
            elseif costLake and not cellData.costLake then
                lakeChanged = true
            elseif costLake and cellData.costLak then
                if #costLake ~= #cellData.costLak then
                    lakeChanged = true
                else
                    for i = 1, #costLake do
                        if costLake[i].id ~= cellData.costLak[i].id then
                            lakeChanged = true
                            break
                        end
                        if costLake[i].num ~= cellData.costLak[i].num then
                            lakeChanged = true
                            break
                        end
                    end
                end
            end
        end
        if IsNotEnough ~= cellData.isNotEnough or haveCount ~= cellData.haveCount or lakeChanged then
            cellData.isNotEnough = IsNotEnough
            cellData.haveCount = haveCount
            cellData.costLake = costLake
            self._p_table_process:UpdateData(cellData)
        end
    end
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
---@param lockTrans CS.UnityEngine.RectTransform[]
---@return number
function CityFurnitureConstructionProcessUIMediator:SingleAddAndSend(cellData, lockTrans)
    local leftChooseCellCount = 0
    if not self._queueCellsData or #self._queueCellsData <= 0 then
        return leftChooseCellCount
    end
    local citizenMgr = self._citizenMgr
    local furnitureId = self._furniture:UniqueId()
    local assignCitizen = self._workData == nil
    local citizenId = self._bindCitizenId
    ---@type number[]
    local sendCells
    for i = 1, #self._queueCellsData do
        local cell = self._queueCellsData[i]
        if not cell.tempSelected and cell.status == 0 then
            sendCells = { i - 1 }
            leftChooseCellCount = #self._queueCellsData - i
            break
        end
    end
    if not sendCells then
        return leftChooseCellCount
    end
    self._p_resident_root:MarkWaitUpdateData()
    citizenMgr:ModifyProcessPlan(lockTrans, furnitureId, sendCells, cellData.processId, 1, function(_, isSuccess, _)
        if self._p_resident_root then
            self._p_resident_root:ClearMarkWaitUpdateData()
        end
        if isSuccess then
            if assignCitizen then
                assignCitizen = false
                citizenMgr:StartWork(citizenId, self._furniture:UniqueId(), CityWorkTargetType.Furniture, lockTrans)
            end
        end
    end,function(msgId, errorCode, jsonTable)
        if errorCode == 46045 then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("crafting_toast_resource_full"))
            return true
        end
        return false
    end)
    return leftChooseCellCount
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
function CityFurnitureConstructionProcessUIMediator:SendAddQueue(cellData)
    local citizenMgr = self._citizenMgr
    local furnitureId = self._furniture:UniqueId()
    local assignCitizen = self._workData == nil
    local citizenId = self._bindCitizenId
    ---@type number[]
    local sendCells = {}
    for _, v in ipairs(self._dragTargetCells) do
        if self._dragSetTargetCellMap[v] then
            table.insert(sendCells, v._data.queueIndex-1)
        end
    end
    if #sendCells <= 0 then
        return
    end
    self._p_resident_root:MarkWaitUpdateData()
    citizenMgr:ModifyProcessPlan(nil, furnitureId, sendCells, cellData.processId, 1, function(_, isSuccess, _)
        self:CleanupTempSelected()
        if self._p_resident_root then
            self._p_resident_root:ClearMarkWaitUpdateData()
        end
        if isSuccess then
            if assignCitizen then
                assignCitizen = false
                citizenMgr:StartWork(citizenId, self._furniture:UniqueId(), CityWorkTargetType.Furniture)
            end
        end
    end,function(msgId, errorCode, jsonTable)
        if errorCode == 46045 then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("crafting_toast_resource_full"))
            return true
        end
        return false
    end)
end

---@param entity wds.CastleBrief
---@param changedData any
function CityFurnitureConstructionProcessUIMediator:OnCastleAbilityChanged(entity, changedData)
    if not self._city or entity.ID ~= self._city.uid then
        return
    end
    ---@type table<number, boolean>
    local changedAbility = {}
    local add,remove,change = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    if add then
        for k, _ in pairs(add) do
            changedAbility[k] = true
        end
    end
    if remove then
        for k, _ in pairs(remove) do
            changedAbility[k] = true
        end
    end
    if change then
        for k, _ in pairs(change) do
            changedAbility[k] = true
        end
    end
    ---@type table<CityFurnitureConstructionProcessFormulaCellParameter, boolean>
    local needUpdateCell = {}
    for abilityType, _ in pairs(changedAbility) do
        local cellList = self._needAbility2FormulaMap[abilityType]
        if cellList then
            for _, cellData in pairs(cellList) do
                needUpdateCell[cellData] = true
            end
        end
    end
    local castle = self._city:GetCastle()
    local abilityMap = castle and castle.CastleAbility or {}
    for cellData,_ in pairs(needUpdateCell) do
        local isLocked = cellData.needAbility:Level() > (abilityMap[cellData.needAbility:Type()] or 0)
        if isLocked ~= cellData.isLocked then
            cellData.isLocked = isLocked
            self._p_table_process:UpdateData(cellData)
        end
    end
end

---@param entity wds.CastleBrief
---@param changedData any
function CityFurnitureConstructionProcessUIMediator:OnFurnitureDataChanged(entity, changedData)
    if not self._city or entity.ID ~= self._city.uid then
        return
    end
    local furnitureId = self._furniture:UniqueId()
    local _,remove,changed = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    if remove[furnitureId] then
        self:CloseSelf()
        return
    end
    local changeCell = changed[furnitureId]
    if not changeCell then
        return
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local castle = self._city:GetCastle()
    local furnitureData = castle.CastleFurniture[furnitureId]
    local slotCount = furnitureData.ProcessQueueCount
    local processInfo = furnitureData.ProcessInfo
    local dataCount = #processInfo
    local count = math.max(dataCount, slotCount)
    local oldCount = #self._queueCellsData
    ---@type table<CityFurnitureConstructionProcessQueueCellData, CityFurnitureConstructionProcessQueueCell>
    local selectedCellData2Cell = {}
    for cell, on in pairs(self._dragSetTargetCellMap) do
        if on and cell._data then
            selectedCellData2Cell[cell._data] = cell
        end
    end
    if count < oldCount then
        for i = oldCount, count + 1 , -1 do
            local cell = self._queueCellsData[i]
            if cell.status ~= 4 then
                table.remove(self._queueCellsData, i)
                self._p_table:RemData(cell)
                local selectedCell = selectedCellData2Cell[cell]
                if selectedCell then
                    self._dragSetTargetCellMap[selectedCell] = nil
                end
                selectedCellData2Cell[cell] = nil
            end
        end
    end
    local usRunning = false
    for i = 1, count do
        ---@type CityFurnitureConstructionProcessQueueCellData
        local cell = self._queueCellsData[i] or {
            queueIndex = i,
            host = self,
            tempSelected = nil,
        }
        cell.castle = castle
        if i > dataCount then
            cell.status = 0
            cell.work = nil
            cell.process = nil
        else
            cell.work = processInfo[i]
            cell.process = ConfigRefer.CityProcess:Find(cell.work.ConfigId)
            cell.tempSelected = nil
            if cell.work.FinishTime and cell.work.FinishTime.Seconds <= nowTime and cell.work.LeftNum <= 0 then
                cell.status = 3
            else
                if not usRunning then
                    usRunning = true
                    cell.status = 2
                else
                    cell.status = 1
                end
            end
            cell.endTimestamp = cell.work.FinishTime and cell.work.FinishTime.ServerSecond
        end
        if i > oldCount then
            cell.tempSelected = nil
            table.insert(self._queueCellsData, cell)
            self._p_table:AppendData(cell)
        else
            self._p_table:UpdateData(cell)
        end
    end
    for i = count + 1, 4 do
        ---@type CityFurnitureConstructionProcessQueueCellData
        local cell = {}
        cell = {}
        cell.queueIndex = i
        cell.host = self
        cell.castle = castle
        cell.status = 4
        cell.tempSelected = nil
        table.insert(self._queueCellsData, cell)
        self._p_table:AppendData(cell)
    end
end

---@param city MyCity
---@param workId number
---@param pair CityCitizenWorkTargetPair
function CityFurnitureConstructionProcessUIMediator:OnWorkDataAdd(city, workId, pair)
    if not self._city or self._city ~= city or not self._furniture or self._furniture:UniqueId() ~= pair.targetId or pair.targetType ~= CityWorkTargetType.Furniture then
        return
    end
    self._workData = self._citizenMgr:GetWorkData(workId)
    self._workDataDirty = true
end

---@param city MyCity
---@param changedWorkId number
function CityFurnitureConstructionProcessUIMediator:OnWorkDataChanged(city, changedWorkId)
    if not self._city or self._city ~= city or not self._workData or self._workData._id ~= changedWorkId then
        return
    end
    self._workData = self._citizenMgr:GetWorkData(changedWorkId)
    self._workDataDirty = true
end

---@param city MyCity
---@param workId number
function CityFurnitureConstructionProcessUIMediator:OnWorkDataRemoved(city, workId)
    if not self._city or self._city ~= city or not self._workData or self._workData._id ~= workId then
        return
    end
    self._workData = nil
    self._workDataDirty = true
end

function CityFurnitureConstructionProcessUIMediator:OnCitizenDataNeedRefresh(city, refreshIds)
    if not self._city or self._city ~= city or not refreshIds or not self._bindCitizenId or not refreshIds[self._bindCitizenId] then
        return
    end
    self._workDataDirty = true
end

function CityFurnitureConstructionProcessUIMediator:OnSafeAreaStatusChanged(castleBriefId, changeToNormal, changeToBroken)
    if not self._city or self._city.uid ~= castleBriefId then
        return
    end
    if not self._bindSafeAreaId then
        self._isNotFunctional = false
    else
        self._isNotFunctional = not self._city.safeAreaWallMgr:IsOutDoorFurnitureCanUse(self._furniture.x, self._furniture.y, self._furnitureTypeConfig:Category())
        if self._isNotFunctional then
            if self._lastDragIndex ~= -1 then
                self:OnFormulaCellCancelDrag(self._lastDragIndex)
            end
        end
    end
    self._p_hint:SetVisible(self._isNotFunctional)
end

---@param citizenId number|nil
---@return boolean
function CityFurnitureConstructionProcessUIMediator:OnSelectedCitizenIdChanged(citizenId)
    if self._workData then
        if citizenId and citizenId ~= 0 then
            local citizenData = self._citizenMgr:GetCitizenDataById(citizenId)
            if citizenData and citizenData._workId ~= self._workData._id then
                self._citizenMgr:AssignProcessWorkCitizen(nil, self._workData._id, citizenId, function(cmd, isSuccess, rsp)
                    if isSuccess then
                        if self._workData then
                            if citizenId ~= self._bindCitizenId then
                                self._bindCitizenId = citizenId
                                self:SetupCitizen()
                            end
                        end
                    end
                end)
            end
        else
            local citizen = self._citizenMgr:GetCitizenIdByWorkId(self._workData._id)
            if citizen then
                self._citizenMgr:AssignProcessWorkCitizen(nil, self._workData._id, 0, function(cmd, isSuccess, rsp)
                    self._bindCitizenId = nil
                    self:SetupCitizen()
                end)
            end
        end
    else
        self._bindCitizenId = citizenId
        self:SetupCitizen()
    end
    return true
end

---@param rectTransform CS.UnityEngine.RectTransform
---@param otherClickCallback fun()
function CityFurnitureConstructionProcessUIMediator:SetBlockAllowRect(rectTransform, otherClickCallback)
    self._p_touch_blocker:SetRect(rectTransform)
    self._clickBlockerCallback = otherClickCallback
end

function CityFurnitureConstructionProcessUIMediator:Tick(dt)
    if self._workDataDirty then
        self._workDataDirty = false
        self:AutoSelectCitizen()
        self:SetupCitizen()
    end
end

function CityFurnitureConstructionProcessUIMediator:OnFormulaTableScroll()
    self._formulaTableInDragging = true
    self._dragPos = nil
    self._lastDragIndex = -1
    self:DragSelectedCleanup()
    self:OnFormulaCellLongPressEnd()
end

function CityFurnitureConstructionProcessUIMediator:OnFormulaTableScrollEnd()
    self._formulaTableInDragging = false
end

function CityFurnitureConstructionProcessUIMediator:OnQueueSlotCountChanged(count)
    local slotWidth = count * self._p_table.cellPrefab[0]:GetComponent(typeof(CS.CellSizeComponent)).Width
    local spaceAdd = (count - 1) * self._p_table.spacing.x
    local newWidth = slotWidth + spaceAdd
    local oldWidth = self._p_table_layout.preferredWidth
    if math.abs(newWidth - oldWidth) > 0.001 then
        self._p_table_layout.preferredWidth = slotWidth + spaceAdd
    end
    local newArrowCount = count - 1
    local oldArrowCount = #self._p_arrows
    if oldArrowCount > count - 1 then
        for idx = oldArrowCount, newArrowCount + 1, -1 do
            self._p_arrows[idx]:SetVisible(false)
        end
    elseif oldArrowCount < newArrowCount then
        for idx = oldArrowCount + 1, newArrowCount do
            local go = UIHelper.DuplicateUIGameObject(self._p_icon_arrow_template, self._p_arrow_root)
            go.transform.localRotation = self._p_icon_arrow_template.transform.localRotation
            self._p_arrows[idx] = go
        end
    end
    for i = 1, newArrowCount do
        self._p_arrows[i]:SetVisible(true)
    end
end

---@param cell CityFurnitureConstructionProcessFormulaCellParameter
function CityFurnitureConstructionProcessUIMediator:ShowItemSelectedTip(cell)
    self._p_block_for_selectedTips:SetVisible(true)
    self._p_tips_item_produce:SetVisible(true)
    self._p_tips_item_produce:FeedData(cell)
end

return CityFurnitureConstructionProcessUIMediator

