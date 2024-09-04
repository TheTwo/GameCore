---Scene Name : scene_city_popup_upgrade
local CityCommonRightPopupUIMediator = require ('CityCommonRightPopupUIMediator')
---@class CityWorkFurnitureUpgradeUIMediator:CityCommonRightPopupUIMediator
local CityWorkFurnitureUpgradeUIMediator = class('CityWorkFurnitureUpgradeUIMediator', CityCommonRightPopupUIMediator)
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local HUDLogicPartDefine = require("HUDLogicPartDefine")
local Utils = require("Utils")

function CityWorkFurnitureUpgradeUIMediator:OnCreate()
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_btn_exit = self:Button("p_btn_exit", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_focus_target = self:Transform("p_focus_target")
    ---@type CityWorkFurnitureUpgradeContent
    self._p_group_upgrade = self:LuaObject("p_group_upgrade")
end

---@param param CityWorkFurnitureUpgradeUIParameter
function CityWorkFurnitureUpgradeUIMediator:OnOpened(param)
    self.param = param
    self.cellTile = param.source
    self.city = param.city
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.ConstructionColor)
    self.cellTile:SetSelected(true)
    self._p_group_upgrade:FeedData(param)
    self:HideHud()
    CityCommonRightPopupUIMediator.OnOpened(self, param)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    self.opened = true
end

function CityWorkFurnitureUpgradeUIMediator:OnClose(param)
    if self.opened then
        self.city.outlineController:ChangeOutlineColor(self.city.outlineController.OtherColor)
        self.cellTile:SetSelected(false)
        CityCommonRightPopupUIMediator.OnClose(self, param)        
        self:RecoverHud()
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    self.opened = false
end

function CityWorkFurnitureUpgradeUIMediator:HideHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.inCityOnlyShowRes, false)
end

function CityWorkFurnitureUpgradeUIMediator:RecoverHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.inCityOnlyShowRes, true)
end

return CityWorkFurnitureUpgradeUIMediator