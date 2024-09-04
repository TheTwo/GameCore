---Scene Name : scene_creepclean_menu_map
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

local TriggerType = {
    ShakeIcon = "ShakeIcon",
    OnOpen = "OnOpen",
    OnStartDrag = "OnStartDrag",
    OnOpenLackUnit = "OnOpenLackRes",
    OnStartDragLackUnit = "OnStartDragLackRes",
    OnLackUnitLoop = "OnLackResLoop",
}

---@class MapCreepClearInteractUIParameter
---@field camera BasicCamera

---@class MapCreepClearUIMediator:BaseUIMediator
---@field currentItemUID number
---@field currentItemDurability number
---@field itemList wds.Item[]
local MapCreepClearUIMediator = class('MapCreepClearUIMediator', BaseUIMediator)

MapCreepClearUIMediator.DragMoveCamera = {
    MinX = 0.06,
    MaxX = 0.94,
    MinY = 0.05,
    MaxY = 0.90,

    MaxSpeed = 20,
    MinSpeed = 5,
}

function MapCreepClearUIMediator:OnCreate()
    self._p_vx_trigger_guide = self:AnimTrigger("p_vx_trigger_guide")
    self._p_drag_icon_root = self:BindComponent("p_drag_icon_root", typeof(CS.StatusRecordParent))

    self._p_drag_pad = self:GameObject("p_drag_pad")
    self:PointerDown("p_drag_pad", Delegate.GetOrCreate(self, self.OnPressDown))
    self:PointerUp("p_drag_pad", Delegate.GetOrCreate(self, self.OnPressUp))
    self:PointerClick("p_drag_pad", Delegate.GetOrCreate(self, self.OnClick))
    self:DragEvent("p_drag_pad", Delegate.GetOrCreate(self, self.BeginDrag), Delegate.GetOrCreate(self, self.Drag), Delegate.GetOrCreate(self, self.EndDrag))
    self._p_group_btn = self:BindComponent("p_group_btn", typeof(CS.StatusRecordParent))
    self._p_text_durability = self:Text("p_text_durability")
    self._p_img_cleaner = self:Image("p_img_cleaner")
    self._p_img_add = self:Button("p_img_add", Delegate.GetOrCreate(self, self.OnChangeItemClicked))

    self._p_btn_change = self:Button("p_btn_change", Delegate.GetOrCreate(self, self.OnChangeItemClicked))
    self._p_text_num = self:Text("p_text_num")
    
    self._p_group_tips = self:GameObject("p_group_tips")
    self._p_text_item_name = self:Text("p_text_item_name")
    self._p_text_desc = self:Text("p_text_desc")
    self._p_group_table = self:GameObject("p_group_table")
    self._p_table_cleaners = self:TableViewPro("p_table_cleaners")
    self._p_group_empty = self:GameObject("p_group_empty")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnAddItemClicked))

end

---@param param CityCreepClearInteractUIParameter
function MapCreepClearUIMediator:OnOpened(param)
    self.clearDo = false
    self.param = param
    self.itemList = {}
    self:RefreshSweepItemData()
    self:UpdateUI()

    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_CLEAR_BIG_ADD, Delegate.GetOrCreate(self, self.OnClearCreepBigAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_CREEP_CLEAR_DO, Delegate.GetOrCreate(self, self.OnClearCreepDo))
    g_Game.EventManager:AddListener(EventConst.UI_BUTTON_CLICK_PRE, Delegate.GetOrCreate(self, self.OnButtonClick))
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    
    for i = 1, ConfigRefer.CityConfig:SweeperItemsLength() do
        local itemID = ConfigRefer.CityConfig:SweeperItems(i)
        ModuleRefer.InventoryModule:AddCountChangeListener(itemID, Delegate.GetOrCreate(self, self.OnSweepItemCountChanged))
    end

    self.param.camera.enableDragging = false
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, false)
    g_Game.EventManager:TriggerEvent(EventConst.SET_WORLD_EVENT_TOAST_STATE, false)
end

function MapCreepClearUIMediator:OnShow()
    self._p_vx_trigger_guide:PlayAll(FpAnimTriggerEvent.OnShow)
end

function MapCreepClearUIMediator:OnClose(param)
    self._lastDragPos = nil
    self._dragging = false
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_CLEAR_BIG_ADD, Delegate.GetOrCreate(self, self.OnClearCreepBigAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CREEP_CLEAR_DO, Delegate.GetOrCreate(self, self.OnClearCreepDo))
    g_Game.EventManager:RemoveListener(EventConst.UI_BUTTON_CLICK_PRE, Delegate.GetOrCreate(self, self.OnButtonClick))

    for i = 1, ConfigRefer.CityConfig:SweeperItemsLength() do
        local itemID = ConfigRefer.CityConfig:SweeperItems(i)
        ModuleRefer.InventoryModule:RemoveCountChangeListener(itemID, Delegate.GetOrCreate(self, self.OnSweepItemCountChanged))
    end
    
    self.param.camera.enableDragging = true
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.allBottom, true)
    g_Game.EventManager:TriggerEvent(EventConst.SET_WORLD_EVENT_TOAST_STATE, true)
end

function MapCreepClearUIMediator:Tick(dt)
    if not self._dragging or not self._lastDragPos then return end
    self:OnScreenEdgeMove(self._lastDragPos, dt)
end

---@param screenPos CS.UnityEngine.Vector3
---@param delta number
function MapCreepClearUIMediator:OnScreenEdgeMove(screenPos, delta)
    local camera = self.param.camera
    local needMove = false
    local horizontal = camera:ScreenHorizontalBoard(screenPos, MapCreepClearUIMediator.DragMoveCamera)
    if horizontal == 1 and self._lastDragOffset.x <= 0 then
        needMove = true
    elseif horizontal == -1 and self._lastDragOffset.x >= 0 then
        needMove = true
    end
    local vertical = camera:ScreenVerticalBoard(screenPos, MapCreepClearUIMediator.DragMoveCamera)
    if vertical == 1 and self._lastDragOffset.y <= 0 then
        needMove = true
    elseif vertical == -1 and self._lastDragOffset.y >= 0 then
        needMove = true
    end

    if needMove then
        local offset = camera:GetScrollingOffset(screenPos)
        self._dragCamTimer = self._dragCamTimer + delta
        local moveSpeed = math.lerp(
                MapCreepClearUIMediator.DragMoveCamera.MinSpeed,
                MapCreepClearUIMediator.DragMoveCamera.MaxSpeed,
                math.clamp01( self._dragCamTimer / 2.0)
        )
        camera:MoveCameraOffset(offset * moveSpeed  * delta)
    else
        self._dragCamTimer = 0
    end
end

function MapCreepClearUIMediator:OnChangeItemClicked()
    self._p_group_tips:SetVisible(not self._p_group_tips.activeSelf)
    if self._p_group_tips.activeSelf then
        self:UpdateSweeperItems()
    end
end

function MapCreepClearUIMediator:OnAddItemClicked()
    local guidID = ConfigRefer.ConstMain:CreepCleanerGuideCall()
    GuideUtils.GotoByGuide(guidID, false)
end

function MapCreepClearUIMediator:OnSweeperItemSelected(itemConfig, itemUid)
    self:SelectSweeperItem(itemUid)
    self:UpdateCurrentDurability()
end

function MapCreepClearUIMediator:RefreshSweepItemData()
    table.clear(self.itemList)
    for i = 1, ConfigRefer.CityConfig:SweeperItemsLength() do
        local itemID = ConfigRefer.CityConfig:SweeperItems(i)
        local uids = ModuleRefer.InventoryModule:GetUidsByConfigId(itemID)
        for _, uid in ipairs(uids) do
            local item = ModuleRefer.InventoryModule:GetItemInfoByUid(uid)
            table.insert(self.itemList, item)
        end
    end
    
    local hasItem = table.nums(self.itemList) > 0
    if hasItem then
        ---@param a wds.Item
        ---@param b wds.Item
        table.sort(self.itemList, function(a, b)
            local itemConfigA = ConfigRefer.Item:Find(a.ConfigId)
            local itemConfigB = ConfigRefer.Item:Find(b.ConfigId)
            if itemConfigA:Quality() ~= itemConfigB:Quality() then
                return itemConfigA:Quality() > itemConfigB:Quality()
            end
            return a.DurabilityInfo.CurDurability < b.DurabilityInfo.CurDurability
        end)
        local first = self.itemList[1]
        self.currentItemUID = first.ID
        self.currentItemDurability = first.DurabilityInfo.CurDurability
    end
    
    self.canDrag = self.currentItemUID and self.currentItemDurability and self.currentItemDurability > 0

    self._p_img_add:SetVisible(not hasItem)
    self._p_img_cleaner:SetVisible(hasItem)
end

function MapCreepClearUIMediator:UpdateUI()
    self._p_drag_pad:SetActive(true)

    UIHelper.SetGray(self._p_img_cleaner.gameObject, not self.canDrag)
    
    self._p_drag_icon_root:ApplyStatusRecord(1, true)
    self._p_drag_icon_root:SetVisible(self._dragging)
    self._p_group_tips:SetVisible(false)
    self:UpdateCurrentDurability()
    self:UpdateSweeperCount()

end

function MapCreepClearUIMediator:UpdateCurrentDurability()
    if self.currentItemUID then
        local item = ModuleRefer.InventoryModule:GetItemInfoByUid(self.currentItemUID)
        self._p_text_durability.text = ModuleRefer.CityCreepModule:GetSweeperItemDurabilityText(item) 
    end
end

function MapCreepClearUIMediator:UpdateSweeperCount()
    local sum = 0
    for i = 1, ConfigRefer.CityConfig:SweeperItemsLength() do
        local itemID = ConfigRefer.CityConfig:SweeperItems(i)
        local count = ModuleRefer.InventoryModule:GetAmountByConfigId(itemID)
        sum = sum + count
    end
    self._p_text_num.text = tostring(sum)
end

function MapCreepClearUIMediator:UpdateSweeperItems()
    self._p_table_cleaners:Clear()
    if table.nums(self.itemList) > 0 then
        self._p_group_table:SetVisible(true)
        self._p_group_empty:SetVisible(false)
        ---@param item wds.Item
        for _, item in ipairs(self.itemList) do
            ---@type ItemIconData
            local itemIconData = {}
            local itemConfig = ConfigRefer.Item:Find(item.ConfigId)
            itemIconData.configCell = itemConfig
            itemIconData.showDurability = true
            itemIconData.showCount = false
            itemIconData.durability = item.DurabilityInfo.CurDurability / itemConfig:Durability()
            itemIconData.onClick = Delegate.GetOrCreate(self, self.OnSweeperItemSelected)
            itemIconData.customData = item.ID
            self._p_table_cleaners:AppendData(itemIconData)
        end
        self._p_table_cleaners:RefreshAllShownItem()
        
        local firstItem = self.itemList[1]
        self:SelectSweeperItem(firstItem.ID)
    else
        self._p_group_table:SetVisible(false)
        self._p_group_empty:SetVisible(true)
    end
    
end

function MapCreepClearUIMediator:SelectSweeperItem(itemUID)
    if self.currentItemUID then
        for i, item in ipairs(self.itemList) do
            if item.ID == self.currentItemUID then
                ---@type ItemIconData
                local iconData = self._p_table_cleaners:LuaGetCell(i - 1)
                iconData.showSelect = false
                self._p_table_cleaners:UpdateChild(iconData)
            end
        end
    end

    for i, item in ipairs(self.itemList) do
        if item.ID == itemUID then
            ---@type ItemIconData
            local iconData = self._p_table_cleaners:LuaGetCell(i - 1)
            iconData.showSelect = true
            self._p_table_cleaners:UpdateChild(iconData)
            
            local itemConfig = ConfigRefer.Item:Find(item.ConfigId)
            self._p_text_item_name.text = I18N.Get(itemConfig:NameKey())
            self._p_text_desc.text = I18N.Get(itemConfig:DescKey())


            self.currentItemUID = itemUID
            self.currentItemDurability = item.DurabilityInfo.CurDurability
        end
    end
end

function MapCreepClearUIMediator:OnPressDown()
    if not self.canDrag then return end

    self._pressing = true
    self._p_drag_icon_root:SetVisible(true)
    self:ResetAllVfxTrigger()
    self._p_vx_trigger_guide:PlayAll(TriggerType.OnStartDrag)
    self._p_group_tips:SetVisible(false)
end

function MapCreepClearUIMediator:OnPressUp()
    if not self._pressing then return end

    self:OnPressUpImp()
end

function MapCreepClearUIMediator:OnPressUpImp()
    self._pressing = false
    self._p_drag_icon_root:SetVisible(false)
    self:ResetAllVfxTrigger()
    self._p_vx_trigger_guide:PlayAll(TriggerType.OnOpen)
end

function MapCreepClearUIMediator:OnClick()
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function MapCreepClearUIMediator:BeginDrag(go, eventData)
    if not self.canDrag or not self.currentItemUID then
        return
    end
    
    self._dragging = true

    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_PESTICIDE_START, self.currentItemUID)
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function MapCreepClearUIMediator:Drag(go, eventData)
    if not self._dragging then return end

    local uiCamera = g_Game.UIManager:GetUICamera()
    local screenPos = CS.UnityEngine.Vector3(eventData.position.x, eventData.position.y, 0)
    local uiWorldPos = uiCamera:ScreenToWorldPoint(screenPos)
    local rootTrans = self._p_drag_icon_root.transform
    local p = rootTrans.parent:InverseTransformPoint(uiWorldPos)
    rootTrans.anchoredPosition = CS.UnityEngine.Vector2(p.x, p.y)

    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_PESTICIDE_DRAG, screenPos, self.currentItemUID)
    self._lastDragPos = screenPos
    self._lastDragOffset = eventData.delta
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function MapCreepClearUIMediator:EndDrag(go, eventData)
    if self._pressing then
        self:OnPressUpImp()
    end

    if not self._dragging then return end

    self._lastDragPos = nil
    local sendRequest, dontKeepState = self.clearDo, not self.clearDo
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_PESTICIDE_END, sendRequest, dontKeepState)
    self._dragging = false
end

function MapCreepClearUIMediator:ResetAllVfxTrigger()
    local list = self._p_vx_trigger_guide.TriggerList
    local count = list.Count
    for i = 0, count - 1 do
        ---@type CS.FpAnimation.FpAnimationCommonTrigger.FpAnimTrigger
        local trigger = list[i]
        self._p_vx_trigger_guide:ResetOneTriggerEvent(trigger)
    end
end

function MapCreepClearUIMediator:OnClearCreepBigAdd(cost)
    if self.currentItemUID and self.currentItemDurability and self._dragging then
        self.currentItemDurability = self.currentItemDurability - cost
        if self.currentItemDurability <= 0 then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_toast_cleaner_run_out"))
            self:EndDrag()
        end
    end
end

function MapCreepClearUIMediator:OnClearCreepDo()
    self.clearDo = true
    self:UpdateCurrentDurability()
    self:UpdateSweeperCount()
end

function MapCreepClearUIMediator:OnSweepItemCountChanged()
    self:RefreshSweepItemData()
    self:UpdateUI()
end

---@param baseComponent BaseUIComponent
function MapCreepClearUIMediator:OnButtonClick(baseComponent)
    if baseComponent then
        local mediator = baseComponent:GetParentBaseUIMediator()
        if mediator == nil or mediator == self then
            return
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_UI_CLOSE_BY_BUTTON)
end

return MapCreepClearUIMediator