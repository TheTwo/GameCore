---scene:scene_construction_popup_help

local BaseUIMediator = require("BaseUIMediator")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local KingdomMapUtils = require("KingdomMapUtils")
local TileHighLightMap = require("TileHighLightMap")
local EventConst = require("EventConst")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")

---@class MapBuildingTroopReinforceUIMediator : BaseUIMediator
---@field textTitle CS.UnityEngine.UI.Text
---@field btnClose CS.UnityEngine.UI.Button
---@field textNameBuilding CS.UnityEngine.UI.Text
---@field textPosition CS.UnityEngine.UI.Text
---@field goTroop CS.UnityEngine.GameObject
---@field goBuff CS.UnityEngine.GameObject
---@field troopList MapBuildingTroopListUICell
---
---@field param MapBuildingParameter
local MapBuildingTroopReinforceUIMediator = class("MapBuildingTroopReinforceUIMediator", BaseUIMediator)

function MapBuildingTroopReinforceUIMediator:OnCreate(param)
    self:Text("p_text_troop", "djianzhu_zhushoubudui")
    self:Text("p_text_buff", "world_build_jc")
    self:Text('p_text_title', "djianzhu_zhushou")

    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnCloseClicked))
    self.textNameBuilding = self:Text('p_text_name_building')
    self.textPosition = self:Text('p_text_position')
    self.textTroopQuantity = self:Text('p_text_troop_quantity')
    self.goTroop = self:GameObject('p_troop')
    self.goBuff = self:GameObject('p_buff')
    ---@type MapBuildingTroopListUICell
    self.troopList = self:LuaObject('p_troop_list')

    self.goTroop:SetVisible(true)
    self.goBuff:SetVisible(false)
end

function MapBuildingTroopReinforceUIMediator:OnShow(param)
    ModuleRefer.MapBuildingTroopModule:RegisterAllBuildingChange(Delegate.GetOrCreate(self, self.RefreshTroopCount))
end

function MapBuildingTroopReinforceUIMediator:OnHide(param)
    ModuleRefer.MapBuildingTroopModule:UnregisterAllBuildingChange(Delegate.GetOrCreate(self, self.RefreshTroopCount))

    self:Clear()
end

---@param param MapBuildingParameter
function MapBuildingTroopReinforceUIMediator:OnOpened(param)
    self.param = param
    self.param.IsStrengthen = false

    self:Refresh()
end

function MapBuildingTroopReinforceUIMediator:OnCloseClicked()
    self:CloseSelf()
end

function MapBuildingTroopReinforceUIMediator:Refresh()
    self.textNameBuilding.text = ModuleRefer.MapBuildingTroopModule:GetBuildingName(self.param)
    local pos = self.param.MapBasics.BuildingPos
    self.textPosition.text = KingdomMapUtils.CoordToXYString(pos.X, pos.Y)

    self.troopList:FeedData(self.param)

    self:RefreshTroopCount()

    TileHighLightMap.ShowTileHighlight(self.tile)
end

function MapBuildingTroopReinforceUIMediator:Clear()
    ModuleRefer.MapBuildingTroopModule:ResetCamera()
    TileHighLightMap.HideTileHighlight(self.tile)
end

function MapBuildingTroopReinforceUIMediator:RefreshTroopCount()
    local troopCount = ModuleRefer.MapBuildingTroopModule:GetTotalTroopCount(self.param.Army, self.param.MapBasics, self.param.StrengthenArmy)
    local maxTroopCount = ModuleRefer.MapBuildingTroopModule:GetMaxTroopCount(self.param.MapBasics)
    self.textTroopQuantity.text = string.format("%d/%d", troopCount, maxTroopCount)
end

return MapBuildingTroopReinforceUIMediator