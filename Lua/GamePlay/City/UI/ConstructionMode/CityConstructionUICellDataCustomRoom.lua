---@class CityConstructionUICellDataCustomRoom
---@field new fun():CityConstructionUICellDataCustomRoom
local CityConstructionUICellDataCustomRoom = class("CityConstructionUICellDataCustomRoom")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ArtResourceUtils = require("ArtResourceUtils")
local CityConstructState = require("CityConstructState")
local EventConst = require("EventConst")
local UIHelper = require("UIHelper")
local ModuleRefer = require("ModuleRefer")

---@param cfg BuildingCustomRoomConfigCell
function CityConstructionUICellDataCustomRoom:ctor(cfg)
    self.cfg = cfg
    
    local matMap = {}
    local door = ConfigRefer.BuildingRoomDoor:Find(self.cfg:Door())
    if door then
        local itemGroup = ConfigRefer.ItemGroup:Find(door:Cost())
        if itemGroup then
            for i = 1, itemGroup:ItemGroupInfoListLength() do
                local info = itemGroup:ItemGroupInfoList(i)
                local itemId = info:Items()
                matMap[itemId] = (matMap[itemId] or 0) + info:Nums()
            end
        end
    end
    local wall = ConfigRefer.BuildingRoomWall:Find(self.cfg:Wall())
    if wall then
        local itemGroup = ConfigRefer.ItemGroup:Find(wall:Cost())
        if itemGroup then
            local wallCount = self.cfg:MinHeight() * 2 + self.cfg:MinWidth() * 2
            for i = 1, itemGroup:ItemGroupInfoListLength() do
                local info = itemGroup:ItemGroupInfoList(i)
                local itemId = info:Items()
                matMap[itemId] = (matMap[itemId] or 0) + info:Nums() * wallCount
            end
        end
    end
    self.matList = table.mapToList(matMap)
end

---@param uiCell CityConstructionModeUICell
function CityConstructionUICellDataCustomRoom:OnFeedData(uiCell)
    self.uiCell = uiCell

    --- 房间建造不会处理未激活状态
    uiCell._p_case_unactivated:SetActive(false)
    uiCell._p_case_activated:SetActive(true)

    --- 图片
    uiCell:LoadSprite(self.cfg:Image(), uiCell._p_icon_building_activated)
    --- 不显示材料
    uiCell._p_material:SetActive(false)
    --- 不显示数量
    uiCell._p_quantity_building:SetActive(false)
    --- 不显示仓储
    uiCell._p_save:SetActive(false)
    --- 显示基础占地
    uiCell._p_area:SetActive(true)
    uiCell._p_txt_quantity_area.text = ("%dx%d"):format(self.cfg:MinWidth(), self.cfg:MinHeight())
    --- 不显示等级
    uiCell._p_lv:SetActive(false)
    --- 名字
    uiCell._p_txt_name.text = self:GetName()
    --- 不显示非法提示
    uiCell._p_txt_hint.gameObject:SetActive(false)
    --- 房间没有红点
    uiCell.child_reddot_default.go:SetActive(false)
    --- 房间建造不会置灰
    UIHelper.SetGray(uiCell._p_btn_click.gameObject, false)
end

---@param uiCell CityConstructionModeUICell
function CityConstructionUICellDataCustomRoom:OnRecycle(uiCell)
    self.uiCell = nil
end

---@param uiCell CityConstructionModeUICell
function CityConstructionUICellDataCustomRoom:OnClick(uiCell)
    if not uiCell.dragChecking then
        local CityConstructionModeUIMediator = require("CityConstructionModeUIMediator")
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_SELECTION, self)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW_HINT, CityConstructionModeUIMediator.TIPS_NORMAL, I18N.Get("city_set_room_tips_1"))
    end
end

---@param uiCell CityConstructionModeUICell
---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionUICellDataCustomRoom:BeginDrag(uiCell, go, eventData)
    uiCell.dragChecking = true
end

---@param uiCell CityConstructionModeUICell
---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionUICellDataCustomRoom:Drag(uiCell, go, eventData)
    if uiCell.dragChecking then
        local result = eventData.pointerCurrentRaycast.gameObject
        if result == nil then
            uiCell.dragChecking = false
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_SELECTION, self, eventData.position)
        end
    else
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_START_POS, eventData.position)
    end
end

---@param uiCell CityConstructionModeUICell
---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionUICellDataCustomRoom:EndDrag(uiCell, go, eventData)
    uiCell.dragChecking = false
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ROOM_UICELL_DRAG_RELEASE)
end

function CityConstructionUICellDataCustomRoom:GetName()
    return I18N.Get(self.cfg:Name())
end

function CityConstructionUICellDataCustomRoom:ConfigId()
    return self.cfg:Id()
end

function CityConstructionUICellDataCustomRoom:IsFurniture()
    return false
end

function CityConstructionUICellDataCustomRoom:GetRecommendPos()
    return false
end

return CityConstructionUICellDataCustomRoom