local BaseTableViewProCell = require ('BaseTableViewProCell')
local I18N = require('I18N')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local ConfigRefer = require("ConfigRefer")

---@class CityLegoBuffRouteMapUIRoomTypeCell:BaseTableViewProCell
local CityLegoBuffRouteMapUIRoomTypeCell = class('CityLegoBuffRouteMapUIRoomTypeCell', BaseTableViewProCell)

function CityLegoBuffRouteMapUIRoomTypeCell:OnCreate()
    self._p_icon_type = self:Image("p_icon_type")
    self._p_icon_furniture = self:Image("p_icon_furniture")
    self._p_text_type_name = self:Text("p_text_type_name")
    self._p_text_type_detail = self:Text("p_text_type_detail")
    self._p_btn_type = self:Button("p_btn_type", Delegate.GetOrCreate(self, self.OnClick))
end

---@param legoBuilding CityLegoBuilding
function CityLegoBuffRouteMapUIRoomTypeCell:OnFeedData(legoBuilding)
    self.legoBuilding = legoBuilding
    local roomCfg = ConfigRefer.Room:Find(legoBuilding.roomCfgId)
    local mainFurniture = roomCfg:MainFurniture()
    local isShow = mainFurniture and mainFurniture > 0
    self._p_icon_furniture.gameObject:SetActive(isShow)
    if isShow then
        g_Game.SpriteManager:LoadSprite(ConfigRefer.CityFurnitureTypes:Find(mainFurniture):Image(), self._p_icon_furniture)
    end
    g_Game.SpriteManager:LoadSprite(roomCfg:Icon(), self._p_icon_type)
    self._p_text_type_name.text = I18N.Get(legoBuilding:GetNameI18N())
    self._p_text_type_detail.text = I18N.Get(legoBuilding:GetDescriptionI18N())
end

function CityLegoBuffRouteMapUIRoomTypeCell:OnClick()
    local camera = self.legoBuilding.city:GetCamera()
    if camera then
        camera:LookAt(self.legoBuilding:GetWorldCenter(), 0.25)
    end
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_LEGO_BUFF_ROUTE_MAP_SELECT_ROOM_TYPE, self.legoBuilding)
end

return CityLegoBuffRouteMapUIRoomTypeCell