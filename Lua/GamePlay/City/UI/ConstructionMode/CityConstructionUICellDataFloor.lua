---@class CityConstructionUICellDataFloor
---@field new fun():CityConstructionUICellDataFloor
local CityConstructionUICellDataFloor = class("CityConstructionUICellDataFloor")
local UIHelper = require("UIHelper")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local Utils = require("Utils")

---@param cfg BuildingRoomFloorConfigCell
function CityConstructionUICellDataFloor:ctor(cfg)
    self.cfg = cfg
    self.itemGroup = ConfigRefer.ItemGroup:Find(self.cfg:Cost())
end

---@param uiCell CityConstructionModeUICell
function CityConstructionUICellDataFloor:OnFeedData(uiCell)
    self.uiCell = uiCell
    --- 地板不会处理未激活状态
    uiCell._p_case_unactivated:SetActive(false)
    uiCell._p_case_activated:SetActive(true)

    --- 图片
    uiCell:LoadSprite(self.cfg:Image(), uiCell._p_icon_building_activated)
    --- 显示材料
    uiCell._p_material:SetActive(true)
    local matType = self:GetMaterialTypeAmount()
    uiCell._p_item_material_1:SetActive(matType >= 1)
    uiCell._p_item_material_2:SetActive(matType >= 2)
    uiCell._p_item_material_3:SetActive(matType >= 3)
    if matType >= 1 then
        local mat = self:GetMaterial(1)
        local need = self:GetMaterialNeed(1)
        g_Game.SpriteManager:LoadSprite(mat:Icon(), uiCell._p_icon_material_1)
        local have = ModuleRefer.InventoryModule:GetAmountByConfigId(mat:Id())

        uiCell._p_txt_quantity_n_1.gameObject:SetActive(have >= need)
        uiCell._p_txt_quantity_red_1.gameObject:SetActive(have < need)

        if have >= need then
            uiCell._p_txt_quantity_n_1.text = tostring(need)
        else
            uiCell._p_txt_quantity_red_1.text = tostring(need)
        end
    end

    if matType >= 2 then
        local mat = self:GetMaterial(2)
        local need = self:GetMaterialNeed(2)
        g_Game.SpriteManager:LoadSprite(mat:Icon(), uiCell._p_icon_material_2)
        local have = ModuleRefer.InventoryModule:GetAmountByConfigId(mat:Id())

        uiCell._p_txt_quantity_n_2.gameObject:SetActive(have >= need)
        uiCell._p_txt_quantity_red_2.gameObject:SetActive(have < need)

        if have >= need then
            uiCell._p_txt_quantity_n_2.text = tostring(need)
        else
            uiCell._p_txt_quantity_red_2.text = tostring(need)
        end
    end

    if matType >= 3 then
        local mat = self:GetMaterial(3)
        local need = self:GetMaterialNeed(3)
        g_Game.SpriteManager:LoadSprite(mat:Icon(), uiCell._p_icon_material_3)
        local have = ModuleRefer.InventoryModule:GetAmountByConfigId(mat:Id())

        uiCell._p_txt_quantity_n_3.gameObject:SetActive(have >= need)
        uiCell._p_txt_quantity_red_3.gameObject:SetActive(have < need)

        if have >= need then
            uiCell._p_txt_quantity_n_3.text = tostring(need)
        else
            uiCell._p_txt_quantity_red_3.text = tostring(need)
        end
    end
    

    --- 不显示数量
    uiCell._p_quantity_building:SetActive(false)
    --- 不显示基础占地
    uiCell._p_area:SetActive(false)
    --- 不显示等级
    uiCell._p_lv:SetActive(false)
    --- 名字
    uiCell._p_txt_name.text = I18N.Get(self.cfg:Name())
    --- 不显示非法提示
    uiCell._p_txt_hint.gameObject:SetActive(false)
    --- 地板没有红点
    uiCell.child_reddot_default.go:SetActive(false)
    --- 地板建造不会置灰
    UIHelper.SetGray(uiCell._p_btn_click.gameObject, false)

    for i = 1, matType do
        ModuleRefer.InventoryModule:AddCountChangeListener(self:GetMaterial(i):Id(), Delegate.GetOrCreate(self, self.OnMatCountChange))
    end
end

function CityConstructionUICellDataFloor:OnRecycle()
    local matType = self:GetMaterialTypeAmount()
    for i = 1, matType do
        ModuleRefer.InventoryModule:RemoveCountChangeListener(self:GetMaterial(i):Id(), Delegate.GetOrCreate(self, self.OnMatCountChange))
    end

    self.uiCell = nil
end

function CityConstructionUICellDataFloor:GetMaterialTypeAmount()
    return self.itemGroup:ItemGroupInfoListLength()
end

function CityConstructionUICellDataFloor:GetMaterial(idx)
    local id = self.itemGroup:ItemGroupInfoList(idx):Items()
    return ConfigRefer.Item:Find(id)
end

function CityConstructionUICellDataFloor:GetMaterialNeed(idx)
    return self.itemGroup:ItemGroupInfoList(idx):Nums()
end

function CityConstructionUICellDataFloor:ConfigId()
    return self.cfg:Id()
end

---@param uiCell CityConstructionModeUICell
function CityConstructionUICellDataFloor:OnClick(uiCell)
    if not uiCell.dragChecking then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_FLOOR_SELECTION, self)
    end
end

---@param uiCell CityConstructionModeUICell
---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionUICellDataFloor:BeginDrag(uiCell, go, eventData)
    uiCell.dragChecking = true
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FLOOR_SELECTION, self)
    self.lastPosition = uiCell.transform.anchoredPosition

    
    self.dragInst = CS.UnityEngine.GameObject("dragInst", typeof(CS.UnityEngine.RectTransform), typeof(CS.UnityEngine.UI.Image))
    self.dragInst.transform.sizeDelta = uiCell.transform.sizeDelta--CS.UnityEngine.Vector2(272, 272)
    self.dragInst.transform.pivot = CS.UnityEngine.Vector2.up
    self.dragInst.transform.anchorMin = CS.UnityEngine.Vector2.up
    self.dragInst.transform.anchorMax = CS.UnityEngine.Vector2.up
    self.dragInst.transform:SetPositionAndRotation(uiCell.transform.position, CS.UnityEngine.Quaternion.identity)
    self.dragInst.transform:SetParent(uiCell:GetTableViewPro().transform.parent)
    self.dragInst.transform.localScale = CS.UnityEngine.Vector3.one
    uiCell:LoadSprite(self.cfg:Image(), self.dragInst:GetComponent(typeof(CS.UnityEngine.UI.Image)))
    uiCell:HideCanvas()
    -- self.dragInst = CS.UnityEngine.Object.Instantiate(uiCell.transform.gameObject, uiCell.transform.position, CS.UnityEngine.Quaternion.identity, uiCell:GetTableViewPro().transform.parent)
end

---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionUICellDataFloor:Drag(uiCell, go, eventData)
    ---DO NOTHING
    uiCell.transform.anchoredPosition = uiCell.transform.anchoredPosition + eventData.delta
    self.dragInst.transform.anchoredPosition = self.dragInst.transform.anchoredPosition + eventData.delta
end

---@param uiCell CityConstructionModeUICell
---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionUICellDataFloor:EndDrag(uiCell, go, eventData)
    uiCell.dragChecking = false
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FLOOR_UICELL_DRAG_RELEASE, eventData.position)
    uiCell.transform.anchoredPosition = self.lastPosition
    uiCell:ShowCanvas()
    CS.UnityEngine.Object.Destroy(self.dragInst)
    self.dragInst = nil
end

function CityConstructionUICellDataFloor:IsFurniture()
    return false
end

function CityConstructionUICellDataFloor:OnMatCountChange()
    if Utils.IsNotNull(self.uiCell.CSComponent) then
        self:OnFeedData(self.uiCell)
    end
end

function CityConstructionUICellDataFloor:GetRecommendPos()
    return false
end

return CityConstructionUICellDataFloor