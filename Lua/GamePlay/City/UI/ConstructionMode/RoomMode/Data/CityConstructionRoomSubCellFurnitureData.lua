---@class CityConstructionRoomSubCellFurnitureData
---@field new fun():CityConstructionRoomSubCellFurnitureData
local CityConstructionRoomSubCellFurnitureData = class("CityConstructionRoomSubCellFurnitureData")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

---@param cellTile CityCellTile
function CityConstructionRoomSubCellFurnitureData:ctor(cellTile, lvId, idx)
    self.idx = idx
    self.cellTile = cellTile
    self.furCfg = ConfigRefer.CityFurnitureLevel:Find(lvId)
end

---@param cell CityConstructionRoomSubCell
function CityConstructionRoomSubCellFurnitureData:FeedCell(cell)
    self.cell = cell

    cell._p_case_unactivated:SetActive(false)
    cell._p_case_activated:SetActive(true)
    cell._p_base_save:SetActive(false)
    cell._p_txt_hint:SetVisible(false)

    local typCell = ConfigRefer.CityFurnitureTypes:Find(self.furCfg:Type())
    g_Game.SpriteManager:LoadSprite(typCell:Image(), cell._p_icon_building_activated)

    local itemGroup = ConfigRefer.ItemGroup:Find(self.furCfg:RelItem())
    local matType = itemGroup:ItemGroupInfoListLength()
    cell._p_item_material_1:SetActive(matType >= 1)
    cell._p_item_material_2:SetActive(matType >= 2)
    cell._p_item_material_3:SetActive(matType >= 3)

    if matType >= 1 then
        local info = itemGroup:ItemGroupInfoList(1)
        local mat = ConfigRefer.Item:Find(info:Items())
        local need = info:Nums()
        g_Game.SpriteManager:LoadSprite(mat:Icon(), cell._p_icon_material_1)
        local have = ModuleRefer.InventoryModule:GetAmountByConfigId(mat:Id())

        cell._p_txt_quantity_n_1.gameObject:SetActive(have >= need)
        cell._p_txt_quantity_red_1.gameObject:SetActive(have < need)

        if have >= need then
            cell._p_txt_quantity_n_1.text = tostring(need)
        else
            cell._p_txt_quantity_red_1.text = tostring(need)
        end
    end

    if matType >= 2 then
        local info = itemGroup:ItemGroupInfoList(2)
        local mat = ConfigRefer.Item:Find(info:Items())
        local need = info:Nums()
        g_Game.SpriteManager:LoadSprite(mat:Icon(), cell._p_icon_material_2)
        local have = ModuleRefer.InventoryModule:GetAmountByConfigId(mat:Id())

        cell._p_txt_quantity_n_2.gameObject:SetActive(have >= need)
        cell._p_txt_quantity_red_2.gameObject:SetActive(have < need)

        if have >= need then
            cell._p_txt_quantity_n_2.text = tostring(need)
        else
            cell._p_txt_quantity_red_2.text = tostring(need)
        end
    end

    if matType >= 3 then
        local info = itemGroup:ItemGroupInfoList(3)
        local mat = ConfigRefer.Item:Find(info:Items())
        local need = info:Nums()
        g_Game.SpriteManager:LoadSprite(mat:Icon(), cell._p_icon_material_3)
        local have = ModuleRefer.InventoryModule:GetAmountByConfigId(mat:Id())

        cell._p_txt_quantity_n_3.gameObject:SetActive(have >= need)
        cell._p_txt_quantity_red_3.gameObject:SetActive(have < need)

        if have >= need then
            cell._p_txt_quantity_n_3.text = tostring(need)
        else
            cell._p_txt_quantity_red_3.text = tostring(need)
        end
    end

    cell._p_quantity_building:SetActive(true)
    cell._p_txt_quantity_building.text = self:GetPlacedCountText()
    cell._p_save:SetActive(false)
    cell._p_lv:SetActive(true)
    cell._p_text_lv.text = tostring(1)
    cell._p_txt_name.text = I18N.Get(typCell:Name())
    UIHelper.SetGray(cell._go, not self:CanBuild())

    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_ROOM_CELL_IDX, Delegate.GetOrCreate(self, self.OnCellIdxChange))
end

function CityConstructionRoomSubCellFurnitureData:RecycleCell()
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_ROOM_CELL_IDX, Delegate.GetOrCreate(self, self.OnCellIdxChange))
    UIHelper.SetGray(self.cell._go, false)
    self.cell = nil
end

function CityConstructionRoomSubCellFurnitureData:OnCellIdxChange(idx)
    self.cell._p_img_select:SetVisible(idx == self.idx)
end

function CityConstructionRoomSubCellFurnitureData:CanBuild()
    local typCell = ConfigRefer.CityFurnitureTypes:Find(self.furCfg:Type())
    local max = ModuleRefer.CityConstructionModule:GetPlaceFurnitureTypeNumLimit(typCell:Id())
    local cur = ModuleRefer.CityConstructionModule:GetFurnitureCountByType(typCell:Id())
    return cur < max
end

function CityConstructionRoomSubCellFurnitureData:GetPlacedCountText()
    local typCell = ConfigRefer.CityFurnitureTypes:Find(self.furCfg:Type())
    local max = ModuleRefer.CityConstructionModule:GetPlaceFurnitureTypeNumLimit(typCell:Id())
    local cur = ModuleRefer.CityConstructionModule:GetFurnitureCountByType(typCell:Id())
    return ("%s%d/%d"):format(I18N.Get("crafting_furniture_putup"), cur, max)
end

return CityConstructionRoomSubCellFurnitureData