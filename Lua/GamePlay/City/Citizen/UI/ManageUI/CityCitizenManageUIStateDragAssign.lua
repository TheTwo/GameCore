local Delegate = require("Delegate")
local EventConst = require("EventConst")
local CityCitizenDefine = require("CityCitizenDefine")
local ConfigRefer = require("ConfigRefer")
local CityConst = require("CityConst")
local I18N = require("I18N")
local CityUtils = require("CityUtils")
local CityCitizenManageUITypeCellDataDefine = require("CityCitizenManageUITypeCellDataDefine")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local ModuleRefer = require("ModuleRefer")
local CityWorkTargetType = require("CityWorkTargetType")

---@type CS.UnityEngine.RectTransformUtility
local RectTransformUtility = CS.UnityEngine.RectTransformUtility

local CityCitizenManageUIState = require("CityCitizenManageUIState")

---@class CityCitizenManageUIStateDragAssign:CityCitizenManageUIState
---@field new fun(host:CityCitizenManageUIMediator):CityCitizenManageUIStateDragAssign
---@field super CityCitizenManageUIState
local CityCitizenManageUIStateDragAssign = class('CityCitizenManageUIStateDragAssign', CityCitizenManageUIState)

---@param draggableCellDataArray CityCitizenManageUIDraggableCellData[]
---@param citizenId number
---@return CityCitizenManageUIDraggableCellData|nil
local function FindCitizenDataIn(draggableCellDataArray, citizenId)
    for _, data in pairs(draggableCellDataArray) do
        if data.citizenData._id == citizenId then
            return data
        end
    end
    return nil
end

function CityCitizenManageUIStateDragAssign:ctor(host)
    CityCitizenManageUIState.ctor(self, host)

    ---@type CityCitizenManageUIDraggableCellData[]
    self._citizenData = {}
    ---@type table<number, CityCitizenManageUIDraggableCellData>
    self._citizenDataMap = {}
    self._selectedCitizenId = nil
    self._selectedWorkTarget = nil
    self._selectedWorkTargetType = nil
    ---@type CityTileView
    self._lastSelectedTargetTile = nil

    self._operateHomeless = false

    ---@type CityCitizenManageUIDraggableCellData[]
    self._homelessCitizen = {}
    self._selectedHomelessId = nil
    self._selectedHouseId = nil
    ---@type CityTileView
    self._lastSelectHouseTile = nil

    self._cellUsingDrag = false
    self._lastGesturePosition = nil
    ---@type CS.UnityEngine.Bounds
    self._scrollEdgeRange = nil
    ---@type CS.UnityEngine.Bounds
    self._scrollEdgeRangeExt = nil
end

function CityCitizenManageUIStateDragAssign:OnShow()
    CityCitizenManageUIState.OnShow(self)
    --self._host:PushCameraStatus(0.1)
    self._host:SetCameraStatusFromConfig()
    self._host._p_text_title.text = I18N.Get("citizen_information")

    self._scrollEdgeRange = RectTransformUtility.CalculateRelativeRectTransformBounds(self._host._p_scroll_rect)
    self._scrollEdgeRangeExt = CS.UnityEngine.Bounds(self._scrollEdgeRange.center, self._scrollEdgeRange.size * 0.95)
    self._host._p_gesture_pad:SetVisible(false)

    self:RegisterPadGesture()
    --self:ZoomCameraSize()
    local camera = self._host._city:GetCamera()
    if camera ~= nil then
        camera.enableDragging = true
        camera.enablePinch = true
    end
    --self:BlockCamera()
    self:GenerateTypeTable()
    self:OnClickTitleResident()
    self._host:TitleResidentMode()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_MANAGE_UI_STATE, true)
    self:RefreshTypeTable(self._host._city)
    self:OnSelectType(1)
    --self:RefreshHomelessTable(self._host._city)
    self._host._city.stateMachine:WriteBlackboard("CityStateCitizenManageUIExitCallback", Delegate.GetOrCreate(self, self.OnClickClose))
    self._host._city.stateMachine:ChangeState(CityConst.STATE_CITIZEN_MANAGE_UI)
    ---@type CS.DragonReborn.UI.UIMediatorType
    local t = CS.DragonReborn.UI.UIMediatorType
    --g_Game.UIManager:SetBlockUIRootType(t.Hud, false)
    g_Game.UIManager:SetBlockUIRootType(t.SceneUI, false)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allRight, false)
end

function CityCitizenManageUIStateDragAssign:OnHide()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allRight, true)
    --self._host:PopCameraStatus()
    ---@type CS.DragonReborn.UI.UIMediatorType
    local t = CS.DragonReborn.UI.UIMediatorType
    --g_Game.UIManager:SetBlockUIRootType(t.Hud, true)
    g_Game.UIManager:SetBlockUIRootType(t.SceneUI, true)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_MANAGE_UI_STATE, false)
    self._host._city.stateMachine:ReadBlackboard("CityStateCitizenManageUIExitCallback", true)
    self._host._city.stateMachine:ChangeState(self._host._city:GetSuitableIdleState(self._host._city.cameraSize))
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SELECT_SHOW, 0)
    --self:RecoverCamera()
    if self._lastSelectedTargetTile then
        self._lastSelectedTargetTile:SetSelected(false)
        self._lastSelectedTargetTile = nil
    end
    if self._lastSelectHouseTile then
        self._lastSelectHouseTile:SetSelected(false)
        self._lastSelectHouseTile = nil
    end
    CityCitizenManageUIState.OnHide(self)
end

function CityCitizenManageUIStateDragAssign:AddEvents()
    CityCitizenManageUIState.AddEvents(self)
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshHomelessTable))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_MANAGE_UI_STATE_CLICK, Delegate.GetOrCreate(self, self.OnClickClose))
    g_Game.UIManager:AddOnAnyPointDown(Delegate.GetOrCreate(self, self.OnAnyPointDown))
end

function CityCitizenManageUIStateDragAssign:RemoveEvents()
    g_Game.UIManager:RemoveOnAnyPointDown(Delegate.GetOrCreate(self, self.OnAnyPointDown))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_MANAGE_UI_STATE_CLICK, Delegate.GetOrCreate(self, self.OnClickClose))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshTypeTable))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.RefreshHomelessTable))
    CityCitizenManageUIState.RemoveEvents(self)
end

function CityCitizenManageUIStateDragAssign:OnClickTitleResident()
    CityCitizenManageUIState.OnClickTitleResident(self)
    self._operateHomeless = false
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_MANAGE_UI_STATE, false)
end

function CityCitizenManageUIStateDragAssign:OnClickTitleVagrant()
    CityCitizenManageUIState.OnClickTitleVagrant(self)
    self._operateHomeless = true
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_MANAGE_UI_STATE, true)
end

function CityCitizenManageUIStateDragAssign:OnSelectType(index)
    self._selectedType = index
    self._host._p_table_btn:SetToggleSelectIndex(index - 1)
    self:RefreshTypeCitizenTable()
end

---@param a CityCitizenManageUIDraggableCellData
---@param b CityCitizenManageUIDraggableCellData
---@return boolean
local function sortForCitizens(a, b)
    local sortOrder = CityCitizenDefine.HealthStatusSortOrder
    local statusA = sortOrder[a.citizenData:GetHealthStatusLocal()]
    local statusB = sortOrder[b.citizenData:GetHealthStatusLocal()]
    local isAssignedHouseA = a.citizenData:IsAssignedHouse()
    local isAssignedHouseB = b.citizenData:IsAssignedHouse()
    if statusA == statusB then
        if isAssignedHouseA and not isAssignedHouseB then
            return true
        elseif isAssignedHouseB and not isAssignedHouseA then
            return false
        end
        return a.citizenData._id < b.citizenData._id
    end
    return statusA < statusB
end

function CityCitizenManageUIStateDragAssign:RefreshTypeCitizenTable()
    if not self._selectedType then
        return
    end
    self._host._p_table_detail:UnSelectAll()

    local onSelected = Delegate.GetOrCreate(self, self.OnCellSelected)
    local onBeginDrag = Delegate.GetOrCreate(self, self.OnBeginDrag)
    local onDrag = Delegate.GetOrCreate(self, self.OnDrag)
    local onEndDrag = Delegate.GetOrCreate(self, self.OnEndDrag)
    local onReCall = Delegate.GetOrCreate(self, self.OnCellReCall)
    local onClickRecover = Delegate.GetOrCreate(self, self.OnClickRecover)

    local mgr = self._host._city.cityCitizenManager
    local typ = self._citizenTypeData[self._selectedType].type
    ---@type CityCitizenManageUIDraggableCellData[]
    local tmpDataList = {}
    local tmpUpdateDataIds = {}
    local useUpdateMode = true
    for _, citizenData, citizenWork in mgr:pairsCitizenData() do
        if citizenWork and typ > CityCitizenManageUITypeCellDataDefine.Type.Work then
            ---@type CityCitizenManageUIDraggableCellData
            local data = {}
            data.citizenData = citizenData
            data.citizenWork = citizenWork
            data.OnSelected = onSelected
            data.OnBeginDrag = onBeginDrag
            data.OnDrag = onDrag
            data.OnEndDrag = onEndDrag
            data.OnRecall = onReCall
            data.OnClickRecover = onClickRecover
            table.insert(tmpDataList, data)
            tmpUpdateDataIds[citizenData._id] = citizenData._id
            if not self._citizenDataMap[citizenData._id] then
                useUpdateMode = false
            end
        elseif not citizenWork and not citizenData:HasWork() then
            if typ ~= CityCitizenManageUITypeCellDataDefine.Type.Free then
                goto loopCitizenContinue
            end
            ---@type CityCitizenManageUIDraggableCellData
            local data = {}
            data.citizenData = citizenData
            data.OnSelected = onSelected
            data.OnBeginDrag = onBeginDrag
            data.OnDrag = onDrag
            data.OnEndDrag = onEndDrag
            data.OnRecall = nil
            data.OnClickRecover = onClickRecover
            table.insert(tmpDataList, data)
            tmpUpdateDataIds[citizenData._id] = citizenData._id
            if not self._citizenDataMap[citizenData._id] then
                useUpdateMode = false
            end
        end
        ::loopCitizenContinue::
    end
    if useUpdateMode then
        for id,_ in pairs(self._citizenDataMap) do
            if not tmpUpdateDataIds[id] then
                useUpdateMode = false
                break
            end
        end
    end
    if useUpdateMode then
        for _, data in pairs(tmpDataList) do
            local cellData = self._citizenDataMap[data.citizenData._id]
            cellData.citizenData = data.citizenData
            cellData.citizenWork = data.citizenWork
        end
        self._host._p_table_detail:UpdateOnlyAllDataImmediately()
    else
        self._host._p_table_detail:Clear()
        table.clear(self._citizenData)
        table.clear(self._citizenDataMap)
        table.sort(tmpDataList, sortForCitizens)
        for _, data in pairs(tmpDataList) do
            table.insert(self._citizenData, data)
            self._citizenDataMap[data.citizenData._id] = data
            self._host._p_table_detail:AppendData(data)
        end
        if self._selectedCitizenId and not self._operateHomeless then
            self:SetArrowStatus(false, false)
        end
        self._selectedCitizenId = nil
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SELECT_SHOW, 0)
    end
    self._host:SetTableShowNoCitizens(#self._citizenData <= 0)
end

---@param city City
function CityCitizenManageUIStateDragAssign:RefreshHomelessTable(city)
    if self._host._city.uid ~= city.uid then
        return
    end
    table.clear(self._homelessCitizen)
    self._host._p_table_vagrant:Clear()
    local citizenMgr = self._host._city.cityCitizenManager
    local onSelected = Delegate.GetOrCreate(self, self.OnCellSelected)
    local onBeginDrag = Delegate.GetOrCreate(self, self.OnBeginDrag)
    local onDrag = Delegate.GetOrCreate(self, self.OnDrag)
    local onEndDrag = Delegate.GetOrCreate(self, self.OnEndDrag)
    local idInData = false
    for _, data, _ in citizenMgr:pairsCitizenData() do
        if data._houseId == 0 then
            ---@type CityCitizenManageUIDraggableCellData
            local cellData = {}
            cellData.OnSelected = onSelected
            cellData.OnBeginDrag = onBeginDrag
            cellData.OnDrag = onDrag
            cellData.OnEndDrag = onEndDrag
            cellData.citizenData = data
            table.insert(self._homelessCitizen, cellData)
            self._host._p_table_vagrant:AppendData(cellData)
            if self._selectedHomelessId == data._id then
                idInData = true
            end
        end
    end
    if self._selectedHomelessId and self._operateHomeless then
        self:SetArrowStatus(false, false)
    end
    if not idInData then
        self._selectedHomelessId = nil
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SELECT_SHOW, 0)
    end
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenManageUIStateDragAssign:OnCellSelected(data)
    ---@type CityCitizenManageUIDraggableCellData[]
    local dataSource
    ---@type CS.TableViewPro
    local tableView
    if self._operateHomeless then
        dataSource = self._homelessCitizen
        tableView = self._host._p_table_vagrant
    else
        dataSource = self._citizenData
        tableView = self._host._p_table_detail
    end
    local index = table.indexof(dataSource, data, 1)
    if index == -1 then
        return
    end
    tableView:UnSelectAll()
    self._host:FocusOnCitizen(data.citizenData._id, true)
    tableView:SetToggleSelectIndex(index - 1)
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenManageUIStateDragAssign:OnCellReCall(data)
    if self._operateHomeless then
        return
    end
    if data then
        if table.indexof(self._citizenData, data, 1) == -1 then
            return
        end
        if data.citizenData._workId ~= 0 then
            self._host._city.cityCitizenManager:StopWork(data.citizenData._id)
        end
    end
end

---@param data CityCitizenManageUIDraggableCellData
function CityCitizenManageUIStateDragAssign:OnClickRecover(data)
    ---@type CityCitizenManageUIDraggableCellData[]
    local dataSource
    if self._operateHomeless then
        dataSource = self._homelessCitizen
    else
        dataSource = self._citizenData
    end
    local index = table.indexof(dataSource, data, 1)
    if index == -1 then
        return
    end
    if data.citizenData:IsReadyForWeakUp() ~= 0 then
        self._host._city.cityCitizenManager:SendRecoverCitizen(data.citizenData._id)
    end
end

local function ToVec3(vec2)
    return CS.UnityEngine.Vector3(vec2.x, vec2.y)
end

---@param data CityCitizenManageUIDraggableCellData
---@param go CS.UnityEngine.GameObject
---@param event CS.UnityEngine.EventSystems.PointerEventData
function CityCitizenManageUIStateDragAssign:OnBeginDrag(data, go, event)
    if not data then
        return false
    end
    self:ResetPick()
    if self._operateHomeless then
        --if data.citizenData._id ~= self._selectedHomelessId then
        --    return false
        --end
        self._selectedHomelessId = data.citizenData._id
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SELECT_SHOW, data.citizenData._id)
        local onUiPosition = g_Game.UIManager:GetUICamera():ScreenToWorldPoint(ToVec3(event.position))
        self:UpdateDragArrow(go.transform.position, onUiPosition)
        local isValid = self:DragPeekHouse(event.position)
        self:SetArrowStatus(isValid, true)
    else
        --if data.citizenData._id ~= self._selectedCitizenId then
        --    return false
        --end
        self._selectedCitizenId = data.citizenData._id
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SELECT_SHOW, data.citizenData._id)
        local onUiPosition = g_Game.UIManager:GetUICamera():ScreenToWorldPoint(ToVec3(event.position))
        self:UpdateDragArrow(go.transform.position, onUiPosition)
        local isValid = not data.citizenData:IsFainting() and self:DragPeekWorkTarget(event.position)
        if not isValid and not data.citizenData:IsAssignedHouse() then
            isValid = self:DragPeekHouse(event.position)
        end
        self:SetArrowStatus(isValid, true)
    end
    self._cellUsingDrag = true
    return true
end

---@param data CityCitizenManageUIDraggableCellData
---@param go CS.UnityEngine.GameObject
---@param event CS.UnityEngine.EventSystems.PointerEventData
function CityCitizenManageUIStateDragAssign:OnDrag(data, go, event)
    if not data then
        return
    end
    self:CameraScrollingForDragInEdge(event)
    self:ResetPick()
    if self._operateHomeless then
        if data.citizenData._id ~= self._selectedHomelessId then
            return
        end
        local onUiPosition = g_Game.UIManager:GetUICamera():ScreenToWorldPoint(ToVec3(event.position))
        self:UpdateDragArrow(go.transform.position, onUiPosition)
        local isValid = self:DragPeekHouse(event.position)
        self:SetArrowStatus(isValid, true)
    else
        if data.citizenData._id ~= self._selectedCitizenId then
            return
        end
        local onUiPosition = g_Game.UIManager:GetUICamera():ScreenToWorldPoint(ToVec3(event.position))
        self:UpdateDragArrow(go.transform.position, onUiPosition)
        local isValid = not data.citizenData:IsFainting() and self:DragPeekWorkTarget(event.position)
        if not isValid and not data.citizenData:IsAssignedHouse() then
            isValid = self:DragPeekHouse(event.position)
        end
        self:SetArrowStatus(isValid, true)
    end
end

---@param data CityCitizenManageUIDraggableCellData
---@param go CS.UnityEngine.GameObject
---@param event CS.UnityEngine.EventSystems.PointerEventData
function CityCitizenManageUIStateDragAssign:OnEndDrag(data, go, event)
    self._cellUsingDrag = false
    if not data then
        return
    end
    self:ResetPick()
    if self._operateHomeless then
        if data.citizenData._id ~= self._selectedHomelessId then
            return
        end
        local onUiPosition = g_Game.UIManager:GetUICamera():ScreenToWorldPoint(ToVec3(event.position))
        self:UpdateDragArrow(go.transform.position, onUiPosition)
        local isValid = self:DragPeekHouse(event.position)
        if isValid then
            self:PeekHouseEnd()
        end
        self:SetArrowStatus(false, false)
        self:ResetPick()
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SELECT_SHOW, 0)
    else
        if data.citizenData._id ~= self._selectedCitizenId then
            return
        end
        local onUiPosition = g_Game.UIManager:GetUICamera():ScreenToWorldPoint(ToVec3(event.position))
        self:UpdateDragArrow(go.transform.position, onUiPosition)
        local isValid = self:DragPeekWorkTarget(event.position)
        if isValid then
            self:PeekWorkTargetEnd()
        elseif not data.citizenData:IsAssignedHouse() then
            isValid = self:DragPeekHouse(event.position)
            if isValid then
                self:PeekHouseEnd()
            end
        end
        self:SetArrowStatus(false, false)
        self:ResetPick()
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CITIZEN_SELECT_SHOW, 0)
    end
end

---@param uiRootPosition CS.UnityEngine.Vector3
---@param targetPosition CS.UnityEngine.Vector3
function CityCitizenManageUIStateDragAssign:UpdateDragArrow(uiRootPosition, targetPosition)
    local dir = targetPosition - uiRootPosition
    local length = dir.magnitude
    local l = self._host._p_line_root.localScale
    l.z = length / self._host._lineBaseLength
    self._host._p_line_root.transform.position = uiRootPosition
    self._host._p_line_root.localScale = l
    self._host._p_line_root:LookAt(targetPosition, CS.UnityEngine.Vector3(0,0,-1))
end

function CityCitizenManageUIStateDragAssign:SetArrowStatus(isValid, show)
    self._host._p_line_root:SetVisible(show)
    self._host._p_line_a:SetVisible(isValid)
    self._host._p_line_b:SetVisible(not isValid)
end

function CityCitizenManageUIStateDragAssign:ResetPick()
    self._selectedHouseId = nil
    self._selectedWorkTarget = nil
    self._selectedWorkTargetType = nil
end

---@param screenPosition CS.UnityEngine.Vector2
function CityCitizenManageUIStateDragAssign:DragPeekHouse(screenPosition)
    local cell = self._host._city:RaycastCityCellTile(ToVec3(screenPosition))
    if not cell then
        if self._lastSelectHouseTile then
            self._lastSelectHouseTile:SetSelected(false)
            self._lastSelectHouseTile = nil
        end
        return false
    end
    local buildingCell = cell:GetCell()
    if not buildingCell or not buildingCell:IsBuilding() then
        if self._lastSelectHouseTile then
            self._lastSelectHouseTile:SetSelected(false)
            self._lastSelectHouseTile = nil
        end
        return false
    end
    local buildingInfo = cell:GetCastleBuildingInfo()
    if not buildingInfo then
        if self._lastSelectHouseTile then
            self._lastSelectHouseTile:SetSelected(false)
            self._lastSelectHouseTile = nil
        end
        return false
    end
    if table.isNilOrZeroNums(buildingInfo.InnerFurniture) then
        if self._lastSelectHouseTile then
            self._lastSelectHouseTile:SetSelected(false)
            self._lastSelectHouseTile = nil
        end
        return false
    end
    ---@type MyCity
    local city = cell:GetCity()
    local citizenMgr = city.cityCitizenManager
    local castle = city:GetCastle()
    local bedCount = 0
    local cfg = ConfigRefer.CityFurnitureLevel
    for _, furnitureId in pairs(buildingInfo.InnerFurniture) do
        local f = castle.CastleFurniture[furnitureId]
        if not f then
            goto continue
        end
        local c = cfg:Find(f.ConfigId)
        if not c then
            goto continue
        end
        bedCount = bedCount + CityCitizenDefine.GetFurnitureBedCount(c)
        ::continue::
    end
    if bedCount <= 0 then
        if self._lastSelectHouseTile then
            self._lastSelectHouseTile:SetSelected(false)
            self._lastSelectHouseTile = nil
        end
        return false
    end
    local inHouseCount = citizenMgr:GetCitizenCountByHouse(buildingCell.tileId)
    if inHouseCount >= bedCount then
        if self._lastSelectHouseTile then
            self._lastSelectHouseTile:SetSelected(false)
            self._lastSelectHouseTile = nil
        end
        return false
    end
    self._selectedHouseId = buildingCell.tileId
    if self._lastSelectHouseTile ~= cell.tileView then
        if self._lastSelectHouseTile then
            self._lastSelectHouseTile:SetSelected(false)
            self._lastSelectHouseTile = nil
        end
        self._lastSelectHouseTile = cell.tileView
        if self._lastSelectHouseTile then
            self._lastSelectHouseTile:SetSelected(true)
        end
    end
    return true
end

function CityCitizenManageUIStateDragAssign:PeekHouseEnd()
    if self._lastSelectHouseTile then
        self._lastSelectHouseTile:SetSelected(false)
        self._lastSelectHouseTile = nil
    end
    if not self._selectedHouseId then
        return
    end
    ---@type CityCitizenManageUIDraggableCellData
    local citizenData
    if self._operateHomeless then
        citizenData = FindCitizenDataIn(self._homelessCitizen, self._selectedHomelessId)

    else
        citizenData = FindCitizenDataIn(self._citizenData, self._selectedCitizenId)
    end
    if not citizenData then
        return
    end
    if citizenData.citizenData:HasWork() then
        ---@type CommonConfirmPopupMediatorParameter
        local param = {}
        param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        param.title = I18N.Get("citizen_check_in_hint_title")
        param.content = I18N.GetWithParams("citizen_check_in_hint_content_1", I18N.Get(citizenData.citizenData._config:Name()))
        local citizenId = citizenData.citizenData._id
        local houseId = self._selectedHouseId
        param.onConfirm = function()
            self._host._city.cityCitizenManager:StopWork(citizenId)
            self._host._city.cityCitizenManager:AssignCitizenToHouse(citizenId, houseId)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
    else
        self._host._city.cityCitizenManager:AssignCitizenToHouse(citizenData.citizenData._id, self._selectedHouseId)
    end
    self._selectedHouseId = nil
end

---@param screenPosition CS.UnityEngine.Vector3
function CityCitizenManageUIStateDragAssign:DragPeekWorkTarget(screenPosition)
    local cityCellTile, cityFurnitureTile = self._host._city:RaycastTileBaseTwoRet(ToVec3(screenPosition))
    if self:PeekCityCellTile(cityCellTile) then
        if self._selectedWorkTarget then
            if self._lastSelectedTargetTile ~= cityCellTile.tileView then
                if self._lastSelectedTargetTile then
                    self._lastSelectedTargetTile:SetSelected(false)
                end
                self._lastSelectedTargetTile = cityCellTile.tileView
                self._lastSelectedTargetTile:SetSelected(true)
            end
            return true
        end
        return false
    end
    if self:PeekFurniture(cityFurnitureTile) then
        if self._lastSelectedTargetTile ~= cityFurnitureTile.tileView then
            if self._lastSelectedTargetTile then
                self._lastSelectedTargetTile:SetSelected(false)
            end
            self._lastSelectedTargetTile = cityFurnitureTile.tileView
            self._lastSelectedTargetTile:SetSelected(true)
        end
        return true
    end
    if self._lastSelectedTargetTile then
        self._lastSelectedTargetTile:SetSelected(false)
        self._lastSelectedTargetTile = nil
    end
    return
end

---@param cellTile CityCellTile
---@return boolean
function CityCitizenManageUIStateDragAssign:PeekCityCellTile(cellTile)
    if not cellTile then
        return false
    end
    local buildingInfo = cellTile:GetCastleBuildingInfo()
    if buildingInfo then
        local city = cellTile:GetCity()
        ---@type CityCitizenManager
        local citizenMgr = city.cityCitizenManager
        if not citizenMgr then
            return false
        end
        if CityUtils.IsStatusWaitWorker(buildingInfo.Status) then
            local workData = citizenMgr:GetWorkDataByTarget(cellTile:GetCell().tileId, CityWorkTargetType.Building)
            if not workData then
                self._selectedWorkTarget = cellTile:GetCell().tileId
                self._selectedWorkTargetType = CityWorkTargetType.Building
            end
            return true
        end
        local castle = city:GetCastle()
        if not castle.CastleFurniture or table.nums(castle.CastleFurniture) <= 0 then
            return false
        end
        if buildingInfo.InnerFurniture then
            for _, furnitureId in pairs(buildingInfo.InnerFurniture) do
                local work = citizenMgr:GetWorkDataByTarget(furnitureId, CityWorkTargetType.Furniture)
                local f = castle.CastleFurniture[furnitureId]
                if f and f.ProcessInfo and f.ProcessInfo[1] and not work and f.ProcessInfo[1].LeftNum > 0 then
                    self._selectedWorkTarget = furnitureId
                    self._selectedWorkTargetType = CityWorkTargetType.Furniture
                    return true
                end
            end
        end
    else
        local cell = cellTile:GetCell()
        if cell:IsResource() then
            local city = cellTile:GetCity()
            ---@type CityCitizenManager
            local citizenMgr = city.cityCitizenManager
            local eleConfigId = cell.configId
            local work = citizenMgr:GetWorkDataByTarget(eleConfigId, CityWorkTargetType.Resource)
            if not work then
                self._selectedWorkTarget = eleConfigId
                self._selectedWorkTargetType = CityWorkTargetType.Resource
                return true
            end
        end
    end
    return false
end

---@param furnitureTile CityFurnitureTile
---@return boolean
function CityCitizenManageUIStateDragAssign:PeekFurniture(furnitureTile)
    if not furnitureTile then
        return false
    end
    local city = furnitureTile:GetCity()
    local citizenMgr = city.cityCitizenManager
    local castle = city:GetCastle()
    local furniture = furnitureTile:GetCell()
    local furnitureId = furniture:UniqueId()
    local work = citizenMgr:GetWorkDataByTarget(furnitureId, CityWorkTargetType.Furniture)
    local f = castle.CastleFurniture[furnitureId]
    if f and f.ProcessInfo and f.ProcessInfo[1] and not work and f.ProcessInfo[1].LeftNum > 0 then
        self._selectedWorkTarget = furnitureId
        self._selectedWorkTargetType = CityWorkTargetType.Furniture
        return true
    end
    return false
end

function CityCitizenManageUIStateDragAssign:PeekWorkTargetEnd()
    if self._lastSelectedTargetTile then
        self._lastSelectedTargetTile:SetSelected(false)
        self._lastSelectedTargetTile = nil
    end
    if not self._selectedWorkTarget or not self._selectedWorkTargetType then
        return
    end
    local citizenData = FindCitizenDataIn(self._citizenData , self._selectedCitizenId)
    if not citizenData then
        return
    end
    if citizenData.citizenData:IsFainting() then
        local healthStatus = citizenData.citizenData:GetHealthStatusLocal()
        if healthStatus == CityCitizenDefine.HealthStatus.FaintingReadyWakeUp then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("citizen_coma_tips_1"))
        else
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("citizen_coma_tips_2"))
        end
        return
    end
    if citizenData.citizenData._workId ~= 0 then
        self._host._city.cityCitizenManager:StopWork(citizenData.citizenData._id)
    end
    self._host._city.cityCitizenManager:StartWork(citizenData.citizenData._id, self._selectedWorkTarget, self._selectedWorkTargetType)
    self._selectedWorkTarget = nil
    self._selectedWorkTargetType = nil
end

function CityCitizenManageUIStateDragAssign:RegisterPadGesture()
    self._host:DragEvent("p_gesture_pad"
            , Delegate.GetOrCreate(self, self.OnBeginDragPad)
            , Delegate.GetOrCreate(self, self.OnDragPad)
            , Delegate.GetOrCreate(self, self.OnEndDragPad)
            , false
    )
end

function CityCitizenManageUIStateDragAssign:ZoomCameraSize()
    local camera = self._host._city:GetCamera()
    if camera ~= nil then
        local size = math.lerp(CityConst.CITY_RECOMMEND_CAMERA_SIZE, CityConst.AIR_VIEW_THRESHOLD, 0.5)
        local c = camera:GetSize()
        local delta = size - c
        camera:ZoomBySpeed(delta, 128)
    end
end

function CityCitizenManageUIStateDragAssign:BlockCamera(log)
    local camera = self._host._city:GetCamera()
    if camera ~= nil then
        camera.enableDragging = false
        camera.enablePinch = false
    end
end

function CityCitizenManageUIStateDragAssign:RecoverCamera()
    local camera = self._host._city:GetCamera()
    if camera then
        if camera ~= nil then
            camera.enableDragging = true
            camera.enablePinch = true
        end
    end
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityCitizenManageUIStateDragAssign:OnBeginDragPad(_, eventData)
    if self._cellUsingDrag then
        return
    end
    --self:RecoverCamera()
    ---@type CS.DragonReborn.DragGesture
    local gesture = CS.DragonReborn.DragGesture()
    gesture.phase = CS.DragonReborn.GesturePhase.Started
    gesture.position = ToVec3(eventData.position)
    self._lastGesturePosition = gesture.position
    self._host._city:GetCamera():OnDrag(gesture)
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityCitizenManageUIStateDragAssign:OnDragPad(_, eventData)
    if self._cellUsingDrag then
        return
    end
    ---@type CS.DragonReborn.DragGesture
    local gesture = CS.DragonReborn.DragGesture()
    gesture.phase = CS.DragonReborn.GesturePhase.Updated
    gesture.position = ToVec3(eventData.position)
    gesture.lastPosition = self._lastGesturePosition
    gesture.delta = gesture.position - self._lastGesturePosition
    self._lastGesturePosition = gesture.position
    self._host._city:GetCamera():OnDrag(gesture)
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityCitizenManageUIStateDragAssign:OnEndDragPad(_, eventData)
    if self._cellUsingDrag then
        return
    end

    ---@type CS.DragonReborn.DragGesture
    local gesture = CS.DragonReborn.DragGesture()
    gesture.phase = CS.DragonReborn.GesturePhase.Ended
    gesture.position = ToVec3(eventData.position)
    gesture.lastPosition = self._lastGesturePosition
    gesture.delta = gesture.position - self._lastGesturePosition
    self._lastGesturePosition = gesture.position
    self._host._city:GetCamera():OnDrag(gesture)

    --self:BlockCamera()
end

---@param event CS.UnityEngine.EventSystems.PointerEventData
function CityCitizenManageUIStateDragAssign:CameraScrollingForDragInEdge(event)
    local uiCamera = g_Game.UIManager:GetUICamera()
    local eventPosVec3 = ToVec3(event.position)
    local uiWorldPos = uiCamera:ScreenToWorldPoint(eventPosVec3)
    local rectLocal = self._host._p_scroll_rect:InverseTransformPoint(uiWorldPos)
    if self._scrollEdgeRange:Contains(rectLocal) then
        return false
    end
    local closestPoint = self._scrollEdgeRangeExt:ClosestPoint(rectLocal)
    local cityPosOffset = self._host._city:RaycastPostionOnPlane(eventPosVec3) -self._host._city:RaycastPostionOnPlane(uiCamera:WorldToScreenPoint(self._host._p_scroll_rect:TransformPoint(closestPoint)))
    local cityCamera = self._host._city:GetCamera()
    cityCamera:LookAt(cityCamera:GetLookAtPosition() + cityPosOffset, 0.1)
    return true
end

---@param screenPos CS.UnityEngine.Vector2
function CityCitizenManageUIStateDragAssign:OnAnyPointDown(screenPos)
    if RectTransformUtility.RectangleContainsScreenPoint(self._host._p_background_base, screenPos, g_Game.UIManager:GetUICamera()) then
        return
    end
    self:OnClickClose()
end

return CityCitizenManageUIStateDragAssign

