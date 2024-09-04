local Delegate = require("Delegate")

local BaseUIComponent = require("BaseUIComponent")

---@class CommonDropDownSelectScrollParameter
---@field dataSource {show:string, context:any, isDisable:boolean}[]
---@field onSelected fun(selected:{index:number, data:{show:string, context:any}})
---@field defaultIndex number

---@class CommonDropDownSelectScroll:BaseUIComponent
---@field new fun():CommonDropDownSelectScroll
---@field super BaseUIComponent
local CommonDropDownSelectScroll = class('CommonDropDownSelectScroll', BaseUIComponent)

function CommonDropDownSelectScroll:ctor()
    BaseUIComponent.ctor(self)
    self._isOpen = false
    self._parameter = nil
    self._tableData = {}
    self._dataDirty = true
    self._refreshTable = false
    self._delayFocusOn = nil
end

function CommonDropDownSelectScroll:OnCreate(param)
    self._selfRect = self:RectTransform("")
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnSwitchOpenOrClose))
    self._p_text_label = self:Text("p_text_label")
    self._p_arrow_open = self:GameObject("p_arrow_open")
    self._p_arrow_close = self:GameObject("p_arrow_close")
    self._p_table = self:TableViewPro("p_table")
    self._p_table_layout = self:BindComponent("p_table", typeof(CS.UnityEngine.UI.LayoutElement))
    self._p_table:SetSelectedDataChanged(Delegate.GetOrCreate(self, self.OnSelectedDataChanged))
    self._p_table_rect = self:RectTransform("p_table")
    g_Game.UIManager:AddOnAnyPointDown(Delegate.GetOrCreate(self, self.OnAnyUIClick))
end

function CommonDropDownSelectScroll:OnClose(param)
    g_Game.UIManager:RemoveOnAnyPointDown(Delegate.GetOrCreate(self, self.OnAnyUIClick))
    self._p_table:SetSelectedDataChanged(nil)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.DelayFocus))
end

function CommonDropDownSelectScroll:OnShow(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.DelayFocus))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.DelayFocus))
end

function CommonDropDownSelectScroll:OnHide(param)
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.DelayFocus))
end

---@param data CommonDropDownSelectScrollParameter
function CommonDropDownSelectScroll:OnFeedData(data)
    self._parameter = data
    self._dataDirty = true
    local width = self._selfRect.sizeDelta.x
    table.clear(self._tableData)
    for index, v in ipairs(data.dataSource) do
        local item = {index= index, data = v, width = width}
        table.insert(self._tableData, item)
        if index == data.defaultIndex then
            self._p_text_label.text = v.show
        end
    end
    local maxCount = math.min(math.max(1, #self._tableData), 4.5)
    self._p_table_layout.preferredHeight = maxCount * self._p_table.cellPrefab[0]:GetComponent(typeof(CS.CellSizeComponent)).preferredHeight
    if self._isOpen then
        self:GenerateItems()
    end
end

function CommonDropDownSelectScroll:OnSwitchOpenOrClose()
    self._isOpen = not self._isOpen
    self._p_arrow_open:SetVisible(not self._isOpen)
    self._p_arrow_close:SetVisible(self._isOpen)
    self._p_table:SetVisible(self._isOpen)
    if self._isOpen then
        self:GenerateItems()
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate( self._p_table_layout:GetComponent(typeof(CS.UnityEngine.RectTransform)))
        self._delayFocusOn = self._parameter.defaultIndex - 1
    end
end

function CommonDropDownSelectScroll:GenerateItems()
    if not self._dataDirty then
        return
    end
    self._dataDirty = false
    self._refreshTable = true
    self._p_table:Clear()
    for _, v in ipairs(self._tableData) do
        self._p_table:AppendData(v)
    end
    self._p_table:SetToggleSelectIndex(self._parameter.defaultIndex - 1)
    self._refreshTable = false
end

---@param current {index:number, data:{show:string, context:any}}
function CommonDropDownSelectScroll:OnSelectedDataChanged(_, current)
    if self._refreshTable then
        return
    end
    if self._parameter and self._parameter.onSelected then
        self._parameter.onSelected(current)
    end
    self:OnSwitchOpenOrClose()
end

---@param screenPoint CS.UnityEngine.Vector2
function CommonDropDownSelectScroll:OnAnyUIClick(screenPoint)
    if not self._isOpen then
        return
    end
    if CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(self._p_table_rect, screenPoint, g_Game.UIManager:GetUICamera()) then
        return
    end
    self:OnSwitchOpenOrClose()
end

function CommonDropDownSelectScroll:DelayFocus()
    if not self._delayFocusOn then
        return
    end
    local v= self._delayFocusOn
    self._delayFocusOn = nil
    self._p_table:SetDataFocus(v, 0.4, CS.TableViewPro.MoveSpeed.Fast)
end

return CommonDropDownSelectScroll