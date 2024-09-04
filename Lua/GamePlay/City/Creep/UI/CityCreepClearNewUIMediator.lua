---Scene Name : scene_creepclean_menu
local BaseUIMediator = require ('BaseUIMediator')
local ConfigTimeUtility = require('ConfigTimeUtility')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local EventConst = require("EventConst")
local GuideUtils = require("GuideUtils")
local UIHelper = require("UIHelper")
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local ModuleRefer = require("ModuleRefer")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local KingdomMapUtils = require("KingdomMapUtils")

local TriggerType = {
    ShakeIcon = "ShakeIcon",
    OnOpen = "OnOpen",
    OnStartDrag = "OnStartDrag",
    OnOpenLackUnit = "OnOpenLackRes",
    OnStartDragLackUnit = "OnStartDragLackRes",
    OnLackUnitLoop = "OnLackResLoop",
}

---@class CityCreepClearInteractUIParameter
---@field camera BasicCamera

---@class CityCreepClearNewUIMediator:BaseUIMediator
---@field currentItemDurability number
---@field itemList CityCreepClearSweeperItemData[]
local CityCreepClearNewUIMediator = class('CityCreepClearNewUIMediator', BaseUIMediator)

CityCreepClearNewUIMediator.DragMoveCamera = {
    MinX = 0.06,
    MaxX = 0.94,
    MinY = 0.05,
    MaxY = 0.95,

    CityMaxSpeed = 20,
    CityMinSpeed = 5,

    MapMaxSpeed = 20 * 25,
    MapMinSpeed = 5 * 25,
}

function CityCreepClearNewUIMediator:OnCreate()
    self._p_vx_trigger_guide = self:AnimTrigger("p_vx_trigger_guide")
    self._p_drag_icon_root = self:StatusRecordParent("p_drag_icon_root")

    self._p_drag_pad = self:GameObject("p_drag_pad")
    self:PointerDown("p_drag_pad", Delegate.GetOrCreate(self, self.OnPressDown))
    self:PointerUp("p_drag_pad", Delegate.GetOrCreate(self, self.OnPressUp))
    -- self:PointerClick("p_drag_pad", Delegate.GetOrCreate(self, self.OnClick))
    self:DragEvent("p_drag_pad", Delegate.GetOrCreate(self, self.BeginDrag), Delegate.GetOrCreate(self, self.Drag), Delegate.GetOrCreate(self, self.EndDrag))
    self._p_img_farme = self:Image("p_img_farme")

    self._p_bubble_potion = self:StatusRecordParent("p_bubble_potion")
    self._p_text_potion = self:Text("p_text_potion")

    self._p_text_durability = self:Text("p_text_durability")
    self._p_img_cleaner = self:Image("p_img_cleaner")
    self._p_img_add = self:Button("p_img_add", Delegate.GetOrCreate(self, self.OnChangeItemClicked))

    self._p_btn_change = self:Button("p_btn_change", Delegate.GetOrCreate(self, self.OnChangeItemClicked))

    self._p_group_tips = self:GameObject("p_group_tips")
    self._p_text_item_name = self:Text("p_text_item_name")
    self._p_text_desc = self:Text("p_text_desc")
    self._p_group_table = self:GameObject("p_group_table")
    self._p_table_cleaners = self:TableViewPro("p_table_cleaners")
    self._p_group_empty = self:GameObject("p_group_empty")

    self._p_text_empty = self:Text("p_text_empty", "CREEPCLEANER_GET_MORE")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnAddItemClicked))
end

---@param param CityCreepClearInteractUIParameter
function CityCreepClearNewUIMediator:OnOpened(param)
    self.clearDo = false
    self.param = param
    self.itemList = {}
    self:InitItemOrderList()
    self:RefreshSweepItemData()
    self:DefaultSelectItem()
    self:UpdateUI()

    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_CLEAR_BIG_ADD, Delegate.GetOrCreate(self, self.OnClearCreepBigAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_CLEAR_DO, Delegate.GetOrCreate(self, self.OnClearCreepDo))
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_FORCE_END_DRAG, Delegate.GetOrCreate(self, self.EndDragAndClearSweeperSelect))
    g_Game.EventManager:AddListener(EventConst.UI_BUTTON_CLICK_PRE, Delegate.GetOrCreate(self, self.OnButtonClick))
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_STATE_CLICK, Delegate.GetOrCreate(self, self.OnGestureClickEmpty))
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))

    for i = 1, ConfigRefer.CityConfig:SweeperItemsLength() do
        local itemID = ConfigRefer.CityConfig:SweeperItems(i)
        ModuleRefer.InventoryModule:AddCountChangeListener(itemID, Delegate.GetOrCreate(self, self.OnSweepItemCountChanged))
    end

    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, false)
    g_Game.EventManager:TriggerEvent(EventConst.SET_WORLD_EVENT_TOAST_STATE, false)
end

function CityCreepClearNewUIMediator:OnShow()
    self._p_vx_trigger_guide:PlayAll(FpAnimTriggerEvent.OnShow)
end

function CityCreepClearNewUIMediator:OnClose(param)
    --g_Logger.Error(debug.traceback())
    self._lastDragPos = nil
    self._dragging = false
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_CLEAR_BIG_ADD, Delegate.GetOrCreate(self, self.OnClearCreepBigAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_CLEAR_DO, Delegate.GetOrCreate(self, self.OnClearCreepDo))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_FORCE_END_DRAG, Delegate.GetOrCreate(self, self.EndDragAndClearSweeperSelect))
    g_Game.EventManager:RemoveListener(EventConst.UI_BUTTON_CLICK_PRE, Delegate.GetOrCreate(self, self.OnButtonClick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_STATE_CLICK, Delegate.GetOrCreate(self, self.OnGestureClickEmpty))

    for i = 1, ConfigRefer.CityConfig:SweeperItemsLength() do
        local itemID = ConfigRefer.CityConfig:SweeperItems(i)
        ModuleRefer.InventoryModule:RemoveCountChangeListener(itemID, Delegate.GetOrCreate(self, self.OnSweepItemCountChanged))
    end

    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, true)
    g_Game.EventManager:TriggerEvent(EventConst.SET_WORLD_EVENT_TOAST_STATE, true)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_UI_CLOSE_BY_BUTTON)
end

function CityCreepClearNewUIMediator:Tick(dt)
    if not self._dragging or not self._lastDragPos then return end
    self:OnScreenEdgeMove(self._lastDragPos, dt)
end

---@param screenPos CS.UnityEngine.Vector3
---@param delta number
function CityCreepClearNewUIMediator:OnScreenEdgeMove(screenPos, delta)
    local camera = self.param.camera
    local needMove = false
    local horizontal = camera:ScreenHorizontalBoard(screenPos, CityCreepClearNewUIMediator.DragMoveCamera)
    if horizontal == 1 and self._lastDragOffset.x <= 0 then
        needMove = true
    elseif horizontal == -1 and self._lastDragOffset.x >= 0 then
        needMove = true
    end
    local vertical = camera:ScreenVerticalBoard(screenPos, CityCreepClearNewUIMediator.DragMoveCamera)
    if vertical == 1 and self._lastDragOffset.y <= 0 then
        needMove = true
    elseif vertical == -1 and self._lastDragOffset.y >= 0 then
        needMove = true
    end

    if needMove then
        local offset = camera:GetScrollingOffset(screenPos)
        self._dragCamTimer = self._dragCamTimer + delta
        local moveSpeed = self:GetScreenMoveSpeed()
        camera:MoveCameraOffset(offset * moveSpeed  * delta)
    else
        self._dragCamTimer = 0
    end
end

function CityCreepClearNewUIMediator:GetScreenMoveSpeed()
    local mapState = KingdomMapUtils.IsMapState()
    local minSpeed = mapState and CityCreepClearNewUIMediator.DragMoveCamera.MapMinSpeed or CityCreepClearNewUIMediator.DragMoveCamera.CityMinSpeed
    local maxSpeed = mapState and CityCreepClearNewUIMediator.DragMoveCamera.MapMaxSpeed or CityCreepClearNewUIMediator.DragMoveCamera.CityMaxSpeed
    return math.lerp(minSpeed, maxSpeed, math.clamp01( self._dragCamTimer / 2.0))
end

function CityCreepClearNewUIMediator:OnChangeItemClicked()
    self._p_group_tips:SetVisible(not self._p_group_tips.activeSelf)
    if self._p_group_tips.activeSelf then
        self:UpdateSweeperItems()
    end
end

function CityCreepClearNewUIMediator:OnAddItemClicked()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_UI_CLOSE_BY_BUTTON)
    local guidID = ConfigRefer.ConstMain:CreepCleanerGuideCall()
    GuideUtils.GotoByGuide(guidID, false)
end

---@param customData CityCreepClearSweeperItemData
function CityCreepClearNewUIMediator:OnSweeperItemSelected(itemConfig, customData)
    if customData.count == 0 or customData.durability == 0 then
        self:ShowGetMoreInfo(customData)
        return
    end

    ModuleRefer.CityCreepModule:SetSelectSweeperCfgId(itemConfig:Id())
    self:SelectSweeperItem(itemConfig:Id())
    self:RefreshSweepItemData()
    self:UpdateCurrentDurability()
end

function CityCreepClearNewUIMediator:InitItemOrderList()
    for i = 1, ConfigRefer.CityConfig:SweeperItemsLength() do
        local itemCfgId = ConfigRefer.CityConfig:SweeperItems(i)
        local itemCfg = ConfigRefer.Item:Find(itemCfgId)
        local datum = {itemCfg = itemCfg, selected = itemCfgId == self.currentItemCfgId, onClick = Delegate.GetOrCreate(self, self.OnSweeperItemSelected)}
        table.insert(self.itemList, datum)
    end
    ---@param a CityCreepClearSweeperItemData
    ---@param b CityCreepClearSweeperItemData
    table.sort(self.itemList, function(a, b)
        local qa, qb = a.itemCfg:Quality(), b.itemCfg:Quality()
        if qa ~= qb then return qa < qb end
        return a.itemCfg:Id() > b.itemCfg:Id()
    end)
end

---@param data CityCreepClearSweeperItemData
function CityCreepClearNewUIMediator:ShowGetMoreInfo(data)
    local getmoreList = {}
    local itemId = data.itemCfg:Id()
    local count = 1
    table.insert(getmoreList, {id = itemId, num = count})
    ModuleRefer.InventoryModule:OpenExchangePanel(getmoreList)
end

function CityCreepClearNewUIMediator:RefreshSweepItemData()
    self.currentItemDurability = 0
    self.sweeperCount = 0
    for i, v in ipairs(self.itemList) do
        local itemCfgId = v.itemCfg:Id()
        v.count = ModuleRefer.InventoryModule:GetAmountByConfigId(itemCfgId)
        v.durability = ModuleRefer.CityCreepModule:GetSweeperDurabilitySum(itemCfgId)

        if itemCfgId == self.currentItemCfgId then
            self.currentItemDurability = v.durability
        end
        self.sweeperCount = self.sweeperCount + v.count
    end

    self.canDrag = self.currentItemDurability > 0
    self._p_img_add:SetVisible(self.currentItemCfgId == nil)
    self._p_img_cleaner:SetVisible(self.currentItemCfgId ~= nil)
end

function CityCreepClearNewUIMediator:DefaultSelectItem()
    local savedCfgId = ModuleRefer.CityCreepModule:GetSelectSweeperCfgId()
    for _, v in ipairs(self.itemList) do
        if v.itemCfg:Id() == savedCfgId and (v.count == 0 or v.durability == 0) then
            savedCfgId = nil
            break
        end
    end

    if savedCfgId == nil then
        for _, v in ipairs(self.itemList) do
            if v.count > 0 and v.durability > 0 then
                savedCfgId = v.itemCfg:Id()
                break
            end
        end
    end
    self:SelectSweeperItem(savedCfgId)
    self.canDrag = self.currentItemDurability > 0
    self._p_img_add:SetVisible(self.currentItemCfgId == nil)
    self._p_img_cleaner:SetVisible(self.currentItemCfgId ~= nil)
end

function CityCreepClearNewUIMediator:UpdateUI()
    self._p_drag_pad:SetActive(true)
    self._p_drag_icon_root:ApplyStatusRecord(1, true)
    self._p_drag_icon_root:SetVisible(self._dragging)
    self._p_bubble_potion:SetVisible(self._dragging)
    self._p_group_tips:SetVisible(false)
    self:UpdateCurrentDurability()
end

function CityCreepClearNewUIMediator:UpdateCurrentDurability()
    self._p_text_durability.text = tostring(self.currentItemDurability)
    self._p_text_potion.text = tostring(self.currentItemDurability)
end

function CityCreepClearNewUIMediator:UpdateSweeperItems()
    self._p_table_cleaners:Clear()

    if self.sweeperCount > 0 then
        self._p_group_table:SetVisible(true)
        self._p_group_empty:SetVisible(false)
        for _, data in ipairs(self.itemList) do
            self._p_table_cleaners:AppendData(data)
        end
        self._p_table_cleaners:RefreshAllShownItem()
    else
        self._p_group_table:SetVisible(false)
        self._p_group_empty:SetVisible(true)
    end
end

function CityCreepClearNewUIMediator:SelectSweeperItem(itemCfgId)
    for i, data in ipairs(self.itemList) do
        if data.itemCfg:Id() == self.currentItemCfgId then
            ---@type CityCreepClearSweeperItemData
            local cellData = self._p_table_cleaners:LuaGetCell(i - 1)
            if cellData then
                cellData.selected = false
                self._p_table_cleaners:UpdateChild(cellData)
            end
        end
    end

    self.currentItemCfgId = itemCfgId
    self._p_text_item_name.text = string.Empty
    self._p_text_desc.text = I18N.Get("CREEP_CLEAN_COST_TIPS")
    self._p_img_farme.color = CS.UnityEngine.Color.black
    for i, data in ipairs(self.itemList) do
        if data.itemCfg:Id() == itemCfgId then
            ---@type CityCreepClearSweeperItemData
            local cellData = self._p_table_cleaners:LuaGetCell(i - 1)
            if cellData then
                cellData.selected = true
                self._p_table_cleaners:UpdateChild(cellData)
            end

            local itemConfig = data.itemCfg
            self._p_text_item_name.text = I18N.Get(itemConfig:NameKey())
            self._p_text_desc.text = I18N.Get(itemConfig:DescKey())
            self.currentItemDurability = data.durability
            self._p_img_farme.color = self:GetQualityColor(data.itemCfg:Quality())
        end
    end
    self._p_text_item_name:SetVisible(not string.IsNullOrEmpty(self._p_text_item_name.text))
    self._p_text_desc:SetVisible(not string.IsNullOrEmpty(self._p_text_desc.text))
end

function CityCreepClearNewUIMediator:GetQualityColor(quality)
    local colorStr = ModuleRefer.InventoryModule:GetItemQualityColor(quality)
    local flag, color = CS.UnityEngine.ColorUtility.TryParseHtmlString(colorStr)
    if flag then
        return color
    end
    return CS.UnityEngine.Color.black
end

function CityCreepClearNewUIMediator:OnPressDown()
    g_Logger.TraceChannel("CityCreepClearNewUIMediator", "OnPressDown, canDrag = %s", tostring(self.canDrag))
    if not self.canDrag then return end

    self._pressing = true
    self._p_drag_icon_root:SetVisible(true)
    self._p_bubble_potion:SetVisible(true)
    self:ResetAllVfxTrigger()
    self._p_vx_trigger_guide:PlayAll(TriggerType.OnStartDrag)
    self._p_group_tips:SetVisible(false)
end

function CityCreepClearNewUIMediator:OnPressUp()
    g_Logger.TraceChannel("CityCreepClearNewUIMediator", "OnPressDown, pressing = %s", tostring(self._pressing))
    if not self._pressing then return end

    self:OnPressUpImp()
end

function CityCreepClearNewUIMediator:OnPressUpImp()
    self._pressing = false
    self._p_drag_icon_root:SetVisible(false)
    self._p_bubble_potion:SetVisible(false)
    self:ResetAllVfxTrigger()
    self._p_vx_trigger_guide:PlayAll(TriggerType.OnOpen)
end

function CityCreepClearNewUIMediator:OnClick()
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityCreepClearNewUIMediator:BeginDrag(go, eventData)
    g_Logger.TraceChannel("CityCreepClearNewUIMediator", "BeginDrag, canDrag = %s, currentItemCfgId = %s", tostring(self.canDrag), tostring(self.currentItemCfgId))
    --g_Logger.Error("BeginDrag")
    if not self.canDrag or not self.currentItemCfgId then
        return
    end
    --g_Logger.Error(self._dragging)
    self._dragging = true

    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_PESTICIDE_START, self.currentItemCfgId)
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityCreepClearNewUIMediator:Drag(go, eventData)
    g_Logger.TraceChannel("CityCreepClearNewUIMediator", "BeginDrag, dragging = %s", tostring(self._dragging))
    if not self._dragging then return end

    local uiCamera = g_Game.UIManager:GetUICamera()
    local screenPos = CS.UnityEngine.Vector3(eventData.position.x, eventData.position.y, 0)
    local uiWorldPos = uiCamera:ScreenToWorldPoint(screenPos)
    local rootTrans = self._p_drag_icon_root.transform
    local p = rootTrans.parent:InverseTransformPoint(uiWorldPos)
    rootTrans.anchoredPosition = CS.UnityEngine.Vector2(p.x, p.y)

    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_PESTICIDE_DRAG, screenPos, self.currentItemCfgId)
    self._lastDragPos = screenPos
    self._lastDragOffset = eventData.delta
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityCreepClearNewUIMediator:EndDrag(go, eventData)
    g_Logger.TraceChannel("CityCreepClearNewUIMediator", "EndDrag, dragging = %s, pressing = %s", tostring(self._dragging), tostring(self._pressing))
    if self._pressing then
        self:OnPressUpImp()
    end
    --g_Logger.Error(self._dragging)
    if not self._dragging then return end

    self._lastDragPos = nil
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_PESTICIDE_END)
    self._dragging = false
end

function CityCreepClearNewUIMediator:EndDragAndClearSweeperSelect()
    self:EndDrag()
    local newCfgId = nil
    for i, v in ipairs(self.itemList) do
        if v.itemCfg:Id() ~= self.currentItemCfgId and v.durability > 0 then
            newCfgId = v.itemCfg:Id()
            break
        end
    end
    ModuleRefer.CityCreepModule:SetSelectSweeperCfgId(newCfgId)
    self:SelectSweeperItem(newCfgId)
    self:RefreshSweepItemData()
    self:UpdateUI()
    self:UpdateCurrentDurability()
end

function CityCreepClearNewUIMediator:ResetAllVfxTrigger()
    local list = self._p_vx_trigger_guide.TriggerList
    local count = list.Count
    for i = 0, count - 1 do
        ---@type CS.FpAnimation.FpAnimationCommonTrigger.FpAnimTrigger
        local trigger = list[i]
        self._p_vx_trigger_guide:ResetOneTriggerEvent(trigger)
    end
end

function CityCreepClearNewUIMediator:OnClearCreepBigAdd(cost)
    if self.currentItemDurability and self._dragging then
        self.currentItemDurability = self.currentItemDurability - cost
        self._p_text_potion.text = tostring(self.currentItemDurability)
        if self.currentItemDurability <= 0 then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_toast_cleaner_run_out"))
            self:EndDragAndClearSweeperSelect()
        end
    end
end

function CityCreepClearNewUIMediator:OnClearCreepDo()
    self.clearDo = true
    self:UpdateCurrentDurability()
end

function CityCreepClearNewUIMediator:OnSweepItemCountChanged()
    self:RefreshSweepItemData()
    self._p_drag_pad:SetActive(true)
    self._p_drag_icon_root:ApplyStatusRecord(1, true)
    self._p_drag_icon_root:SetVisible(self._dragging)
    self._p_bubble_potion:SetVisible(self._dragging)

    if self._p_group_tips.activeSelf then
        self._p_table_cleaners:UpdateOnlyAllDataImmediately()
    end

    self:UpdateCurrentDurability()
end

---@param baseComponent BaseUIComponent
function CityCreepClearNewUIMediator:OnButtonClick(baseComponent)
    if baseComponent then
        local mediator = baseComponent:GetParentBaseUIMediator()
        if mediator == nil or mediator == self then
            return
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_UI_CLOSE_BY_BUTTON)
end

function CityCreepClearNewUIMediator:OnGestureClickEmpty()
    if self._p_group_tips.activeSelf then
        self._p_group_tips:SetActive(false)
    else
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_UI_CLOSE_BY_BUTTON)
    end
end

return CityCreepClearNewUIMediator