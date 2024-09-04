local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local NotificationType = require("NotificationType")
local CityCitizenModuleDefine = require("CityCitizenModuleDefine")
local Utils = require("Utils")
local UIHelper = require("UIHelper")

local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class CityFurnitureConstructionProcessFormulaCellParameter
---@field index number
---@field host CityFurnitureConstructionProcessUIMediator|CityFurnitureConstructionSynthesizeUIMediator
---@field processId number
---@field process CityProcessConfigCell
---@field costLake {id:number, num:number}[]
---@field isLocked boolean
---@field isNotEnough boolean
---@field needAbility CityAbilityConfigCell
---@field haveCount number

---@class CityFurnitureConstructionProcessFormulaCell:BaseTableViewProCell
---@field new fun():CityFurnitureConstructionProcessFormulaCell
---@field super BaseTableViewProCell
local CityFurnitureConstructionProcessFormulaCell = class('CityFurnitureConstructionProcessFormulaCell', BaseTableViewProCell)

CityFurnitureConstructionProcessFormulaCell.FrameQualityColor = {
    [1] = "A6A6A6",
    [2] = "89A965",
    [3] = "6D91BB",
    [4] = "AF75D1",
    [5] = "EA9F73",
}

function CityFurnitureConstructionProcessFormulaCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._isDrag = false
    self._isPointDown = false
    self._longPressTime = nil
    self._eventSetup = false
end

function CityFurnitureConstructionProcessFormulaCell:OnCreate(param)
    self._selfTrans = self:RectTransform("")
    self._p_img_select = self:GameObject("p_img_select")
    ---@type BaseCircleItemIcon
    self._p_output_item = self:LuaObject("p_output_item")
    self._p_text_item_name = self:Text("p_text_item_name")
    self._p_text_have_number = self:Text("p_text_have_number")
    self._p_text_city_number = self:Text("p_text_city_number")
    self._p_base = self:Image("p_base")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self:DragEvent("p_btn_cellClick", Delegate.GetOrCreate(self, self.OnBeginDrag), Delegate.GetOrCreate(self, self.OnDrag), Delegate.GetOrCreate(self, self.OnEndDrag), true)
    self:DragCancelEvent("p_btn_cellClick", Delegate.GetOrCreate(self, self.OnCancelDrag))
    --self:PointerDown("p_btn_cellClick", Delegate.GetOrCreate(self, self.OnCellPointDown))
    --self:PointerUp("p_btn_cellClick", Delegate.GetOrCreate(self, self.OnCellPointUp))
    self:PointerClick("p_btn_cellClick", Delegate.GetOrCreate(self, self.OnCellClick))
end

---@param data CityFurnitureConstructionProcessFormulaCellParameter
function CityFurnitureConstructionProcessFormulaCell:OnFeedData(data)
    self._param = data
    self:SetupEvents(true)
    self:CheckHeroRedState()
    local outputItem = self._param.process:Output(1)
    local cost = self._param.process:Cost(1)
    self._costItem = cost:ItemId()
    self._costCount = cost:Count()
    ---@type ItemIconData
    local itemData = {}
    itemData.configCell = ConfigRefer.Item:Find(outputItem:ItemId())
    itemData.addCount = outputItem:Count()
    itemData.locked = self._param.isLocked
    self._p_output_item:FeedData(itemData)
    local isGray = self._param.isLocked or self._param.isNotEnough
    self._p_output_item:SetGray(isGray)
    self._p_text_have_number.text = tostring(self._param.haveCount or 0)
    if Utils.IsNotNull(self._p_base) then
        UIHelper.SetGray(self._p_base.gameObject, isGray)
        if not isGray then
            local quality = math.clamp(itemData.configCell:Quality(), 1,#CityFurnitureConstructionProcessFormulaCell.FrameQualityColor)
            local qualityColor = CityFurnitureConstructionProcessFormulaCell.FrameQualityColor[quality]
            self._p_base.color = ColorUtil.FromHexNoAlphaString(qualityColor)
        end
    end
end

function CityFurnitureConstructionProcessFormulaCell:OnRecycle(data)
    self:SetupEvents(false)
end

function CityFurnitureConstructionProcessFormulaCell:OnClose(param)
    self:SetupEvents(false)
end

function CityFurnitureConstructionProcessFormulaCell:SetupEvents(add)
    --if add and not self._eventSetup then
    --    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.LongPressTick))
    --elseif not add and self._eventSetup then
    --    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.LongPressTick))
    --end
    self._eventSetup = add
end

---@param go CS.UnityEngine.GameObject
function CityFurnitureConstructionProcessFormulaCell:OnCellPointDown(go)
    --if self._isDrag then
    --    return
    --end
    --if self._isPointDown then
    --    return
    --end
    --self._isPointDown = true
    ----self._longPressTime = ConfigRefer.CityConfig:CityProcessTipDelay() * 0.001
    --if not self._param.host._formulaTableInDragging then
    --    self._param.host:OnFormulaCellLongPressFire(self._param, self._selfTrans)
    --end
end

---@param go CS.UnityEngine.GameObject
function CityFurnitureConstructionProcessFormulaCell:OnCellPointUp()
    --self._param.host:OnFormulaCellLongPressEnd()
    --if not self._isPointDown then
    --    if self._param.isLocked or self._param.isNotEnough then
    --        self._param.host:ShowFormulaRequireTip(self._param, self._selfTrans)
    --        return
    --    end
    --    return
    --end
    --self._isPointDown = false
    ----self._longPressTime = nil
end

---@param go CS.UnityEngine.GameObject
---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFurnitureConstructionProcessFormulaCell:OnBeginDrag(go, data)
    if self._isDrag then
        return
    end
    --self._param.host:OnFormulaCellLongPressEnd()
    if self._param.isLocked or self._param.isNotEnough then
        if self._param.isNotEnough and not self._param.isLocked then
            ModuleRefer.InventoryModule:OpenExchangePanel(self._param.costLake)
        end
        return
    end
    self._isDrag = self._param.host:OnFormulaCellBeginDrag(self._param, data)
end

---@param go CS.UnityEngine.GameObject
---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFurnitureConstructionProcessFormulaCell:OnDrag(go, data)
    if not self._isDrag then
        return
    end
    self._param.host:OnFormulaCellDrag(self._param, data)
end

---@param go CS.UnityEngine.GameObject
---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFurnitureConstructionProcessFormulaCell:OnEndDrag(go, data)
    if not self._isDrag then
        return
    end
    self._isDrag = false
    self._param.host:OnFormulaCellEndDrag(self._param, data)
end

---@param go CS.UnityEngine.GameObject
function CityFurnitureConstructionProcessFormulaCell:OnCancelDrag(go)
    if not self._isDrag then
        return
    end
    self._isDrag = false
    self._param.host:OnFormulaCellCancelDrag(self._param)
end

function CityFurnitureConstructionProcessFormulaCell:OnCellClick()
    if self._isDrag then
        return
    end
    self._param.host:ShowItemSelectedTip(self._param)
end

--function CityFurnitureConstructionProcessFormulaCell:LongPressTick(dt)
--    if not self._isPointDown then
--        return
--    end
--    if not self._longPressTime then
--        return
--    end
--    self._longPressTime = self._longPressTime - dt
--    if self._longPressTime <= 0 then
--        self._longPressTime = nil
--        if not self._param.host._formulaTableInDragging then
--            self._param.host:OnFormulaCellLongPressFire(self._param, self._selfTrans)
--        end
--    end
--end

function CityFurnitureConstructionProcessFormulaCell:CheckHeroRedState()
    local id = self._param.processId
    local notifyNode = self._child_reddot_default
    if Utils.IsNull(notifyNode) then
        return
    end
    local heroHeadIconNode = ModuleRefer.NotificationModule:GetDynamicNode(CityCitizenModuleDefine.GetNotifyFormulaKey(id), NotificationType.CITY_FURNITURE_PROCESS_FORMULA)
    ModuleRefer.NotificationModule:AttachToGameObject(heroHeadIconNode, notifyNode.go, notifyNode.redNew)
    local isNew = ModuleRefer.CityCitizenModule:CheckProcessFormulaIsNew(id)
    if isNew then
        ModuleRefer.CityCitizenModule:MarkFormulaCheckedDelay(id)
    end
end

return CityFurnitureConstructionProcessFormulaCell

