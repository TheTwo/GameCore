---Scene Name : scene_furniture_dialog_info
local BaseUIMediator = require ('BaseUIMediator')
local Utils = require('Utils')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local HUDLogicPartDefine = require("HUDLogicPartDefine")
local ModuleRefer = require("ModuleRefer")
local CityWorkUIPropertyChangeItemData = require("CityWorkUIPropertyChangeItemData")
local LuaReusedComponentPool = require("LuaReusedComponentPool")

---@class CityFurnitureDetailsUIMediator:BaseUIMediator
local CityFurnitureDetailsUIMediator = class('CityFurnitureDetailsUIMediator', BaseUIMediator)

function CityFurnitureDetailsUIMediator:OnCreate()
    self._p_focus_target = self:Transform("p_focus_target")
    self._p_btn_exit = self:Button("p_btn_exit", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_text_furniture_name = self:Text("p_text_furniture_name")
    self._p_text_description = self:Text("p_text_description")

    self._p_property_vertical = self:Transform("p_property_vertical")
    self._p_property = self:LuaBaseComponent("p_property")
    self._pool_property = LuaReusedComponentPool.new(self._p_property, self._p_property_vertical)
end

---@param param CityFurnitureDetailsUIParameter
function CityFurnitureDetailsUIMediator:OnOpened(param)
    self.param = param
    self.cellTile = self.param.cellTile
    self.city = self.cellTile:GetCity()
    self._p_text_furniture_name.text = self.param.name
    self._p_text_description.text = self.param.description
    self:MoveCameraToFocusTarget()
    self:HideHud()

    self:UpdatePropertyCurrent()
end

function CityFurnitureDetailsUIMediator:OnClose(param)
    self:RecoverCamera()
    self:RecoverHud()
end

function CityFurnitureDetailsUIMediator:MoveCameraToFocusTarget()
    local uiCamera = g_Game.UIManager:GetUICamera()
    if Utils.IsNull(uiCamera) then return end

    local basicCamera = self.city:GetCamera()
    if basicCamera == nil then return end

    local viewport = uiCamera:WorldToViewportPoint(self._p_focus_target.position)
    local mainAssets = self.cellTile.tileView:GetMainAssets()
    local asset = next(mainAssets)
    if asset then
        local flag, pos = asset:TryGetAnchorPos()
        self.cameraStackHandle = basicCamera:ZoomToWithFocusStack(basicCamera:GetMinSize(), viewport, pos, 0.5)
    else
        self.cameraStackHandle = basicCamera:ZoomToWithFocusStack(basicCamera:GetMinSize(), viewport, self.cellTile:GetWorldCenter(), 0.5)
    end
end

function CityFurnitureDetailsUIMediator:RecoverCamera()
    if self.cameraStackHandle then
        self.cameraStackHandle:back()
        self.cameraStackHandle = nil
    end
end

function CityFurnitureDetailsUIMediator:HideHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.inCityOnlyShowRes, false)
end

function CityFurnitureDetailsUIMediator:RecoverHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.inCityOnlyShowRes, true)
end

function CityFurnitureDetailsUIMediator:UpdatePropertyCurrent()
    if self._p_property == nil then return end
    self._pool_property:HideAll()
    self.lvCell = self.param.furLvCfg
    local propertyList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(self.lvCell:Attr()) or {}
    for i, prop in ipairs(propertyList) do
        if prop.value == 0 then goto continue end
        local item = self._pool_property:GetItem()
        local data = CityWorkUIPropertyChangeItemData.new(prop.type, prop.value)
        item:FeedData(data)
        ::continue::
    end
end

return CityFurnitureDetailsUIMediator