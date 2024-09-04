---@class CityConstructionRoomToggleData
---@field new fun():CityConstructionRoomToggleData
local CityConstructionRoomToggleData = class("CityConstructionRoomToggleData")
local ModuleRefer = require("ModuleRefer")
local NotificationType = require("NotificationType")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")

---@param uiMediator CityConstructionModeUIMediator
function CityConstructionRoomToggleData:ctor(uiMediator)
    self.uiMediator = uiMediator
end

function CityConstructionRoomToggleData:OnClick()
    if self.uiMediator:SelectToggle(self) then
        self:OnClickImp()
    end
end

function CityConstructionRoomToggleData:OnClickImp()
    self.uiMediator:ShowRoomList()
end

---@param cell CityConstructionModeUIToggleCell
function CityConstructionRoomToggleData:FeedCell(cell)
    self.cell = cell
    g_Game.SpriteManager:LoadSprite(ConfigRefer.CityConfig:ConstRoom(), self.cell._p_icon_tab_a)
    g_Game.SpriteManager:LoadSprite(ConfigRefer.CityConfig:ConstRoom(), self.cell._p_icon_tab_b)
    ModuleRefer.NotificationModule:GetOrCreateDynamicNode(ModuleRefer.CityConstructionModule.notifyRoomName, NotificationType.CITY_CONSTRUCTION_TAG_ROOM, self.cell._child_reddot_default.go, self.cell._child_reddot_default.redNew)
end

function CityConstructionRoomToggleData:Selected()
    self.cell._p_tab_a:SetActive(false)
    self.cell._p_tab_b:SetActive(true)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_MAP_GRID_ONLY_SHOW_IN_BUILDING)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CAMERA_TWEEN_TO_TOP_VIEWPORT)
end

function CityConstructionRoomToggleData:UnSelected()
    self.cell._p_tab_a:SetActive(true)
    self.cell._p_tab_b:SetActive(false)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_MAP_GRID_DEFAULT)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CAMERA_TWEEN_TO_DEFAULT_VIEWPORT)
    self.uiMediator:OnExitRoomMode()
end

---@param cell CityConstructionModeUIToggleCell
function CityConstructionRoomToggleData:OnClose(cell)
    
end

return CityConstructionRoomToggleData