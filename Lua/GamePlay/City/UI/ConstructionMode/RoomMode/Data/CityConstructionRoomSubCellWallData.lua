---@class CityConstructionRoomSubCellFurnitureData
---@field new fun(wallId:number, idx:number):CityConstructionRoomSubCellFurnitureData
local CityConstructionRoomSubCellWallData = class("CityConstructionRoomSubCellFurnitureData")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

function CityConstructionRoomSubCellWallData:ctor(wallId, idx)
    self.idx = idx
    self.wallCfg = ConfigRefer.BuildingRoomWall:Find(wallId)
end

---@param cell CityConstructionRoomSubCell
function CityConstructionRoomSubCellWallData:FeedCell(cell)
    self.cell = cell

    cell._p_case_unactivated:SetActive(false)
    cell._p_case_activated:SetActive(true)
    cell._p_base_save:SetActive(false)
    cell._p_txt_hint:SetVisible(false)

    cell:LoadSprite(self.wallCfg:Image(), cell._p_icon_building_activated)
    
    local itemGroup = ConfigRefer.ItemGroup:Find(self.wallCfg:Cost())
    local length = itemGroup:ItemGroupInfoListLength()
    cell._p_material:SetActive(length > 0)
    cell._p_item_material_1:SetActive(length > 0)
    if length > 0 then
        local groupInfo = itemGroup:ItemGroupInfoList(1)
        local itemCfg = ConfigRefer.Item:Find(groupInfo:Items())
        g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), cell._p_icon_material_1)
        if ModuleRefer.InventoryModule:GetAmountByConfigId(itemCfg:Id()) >= groupInfo:Nums() then
            cell._p_txt_quantity_n_1:SetVisible(true)
            cell._p_txt_quantity_red_1:SetVisible(false)
            cell._p_txt_quantity_n_1.text = tostring(groupInfo:Nums())
        else
            cell._p_txt_quantity_n_1:SetVisible(false)
            cell._p_txt_quantity_red_1:SetVisible(true)
            cell._p_txt_quantity_red_1.text = tostring(groupInfo:Nums())
        end
    end

    cell._p_item_material_2:SetActive(length > 1)
    if length > 1 then
        local groupInfo = itemGroup:ItemGroupInfoList(2)
        local itemCfg = ConfigRefer.Item:Find(groupInfo:Items())
        g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), cell._p_icon_material_2)
        if ModuleRefer.InventoryModule:GetAmountByConfigId(itemCfg:Id()) >= groupInfo:Nums() then
            cell._p_txt_quantity_n_2:SetVisible(true)
            cell._p_txt_quantity_red_2:SetVisible(false)
            cell._p_txt_quantity_n_2.text = tostring(groupInfo:Nums())
        else
            cell._p_txt_quantity_n_2:SetVisible(false)
            cell._p_txt_quantity_red_2:SetVisible(true)
            cell._p_txt_quantity_red_2.text = tostring(groupInfo:Nums())
        end
    end

    cell._p_item_material_3:SetActive(length > 2)
    if length > 2 then
        local groupInfo = itemGroup:ItemGroupInfoList(3)
        local itemCfg = ConfigRefer.Item:Find(groupInfo:Items())
        g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), cell._p_icon_material_3)
        if ModuleRefer.InventoryModule:GetAmountByConfigId(itemCfg:Id()) >= groupInfo:Nums() then
            cell._p_txt_quantity_n_3:SetVisible(true)
            cell._p_txt_quantity_red_3:SetVisible(false)
            cell._p_txt_quantity_n_3.text = tostring(groupInfo:Nums())
        else
            cell._p_txt_quantity_n_3:SetVisible(false)
            cell._p_txt_quantity_red_3:SetVisible(true)
            cell._p_txt_quantity_red_3.text = tostring(groupInfo:Nums())
        end
    end

    cell._p_quantity_building:SetActive(false)
    cell._p_save:SetActive(false)
    cell._p_lv:SetActive(false)
    cell._p_txt_name.text = I18N.Get(self.wallCfg:Name())

    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_ROOM_CELL_IDX, Delegate.GetOrCreate(self, self.OnCellIdxChange))
end

function CityConstructionRoomSubCellWallData:RecycleCell()
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_ROOM_CELL_IDX, Delegate.GetOrCreate(self, self.OnCellIdxChange))
    self.cell = nil
end

function CityConstructionRoomSubCellWallData:OnCellIdxChange(idx)
    self.cell._p_img_select:SetVisible(idx == self.idx)
end

return CityConstructionRoomSubCellWallData