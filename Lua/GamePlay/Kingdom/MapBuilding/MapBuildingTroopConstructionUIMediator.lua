--scene_construction_popup_defense
local BaseUIMediator = require("BaseUIMediator")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local KingdomMapUtils = require("KingdomMapUtils")
local TileHighLightMap = require("TileHighLightMap")
local EventConst = require("EventConst")

---@class MapBuildingTroopConstructionUIMediator : BaseUIMediator
---@field super BaseUIMediator
---@field textTitle CS.UnityEngine.UI.Text
---@field btnClose CS.UnityEngine.UI.Button
---@field textNameBuilding CS.UnityEngine.UI.Text
---@field textPosition CS.UnityEngine.UI.Text
---@field goTroop CS.UnityEngine.GameObject
---@field goBuff CS.UnityEngine.GameObject
---@field troopList MapBuildingTroopListUICell
---@field param MapBuildingParameter
local MapBuildingTroopConstructionUIMediator = class("MapBuildingTroopConstructionUIMediator", BaseUIMediator)

function MapBuildingTroopConstructionUIMediator:ctor()
    MapBuildingTroopConstructionUIMediator.super.ctor(self)
    ---@type MapBuildingParameter
    self.param = nil
end

function MapBuildingTroopConstructionUIMediator:OnCreate(param)
    self:Text("p_text_troop", "djianzhu_zhiyuanbudui")
    self:Text("p_text_buff", "alliance_buildspeed_text")
    self:Text('p_text_title', "djianzhu_zhiyuan")
    
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnCloseClicked))
    self.textTitle = self:Text('p_text_title')
    self.btnClose = self:Button('p_btn_close')
    self.textNameBuilding = self:Text('p_text_name_building')
    self.textPosition = self:Text('p_text_position')
    self.textTroopQuantity = self:Text('p_text_troop_quantity')
    self.goTroop = self:GameObject('p_troop')
    self.goBuff = self:GameObject('p_buff')
    self.textBuff = self:Text('p_text_buff_quantity')
    self.troopList = self:LuaObject('p_troop_list')

    self.goTroop:SetVisible(true)
    self.goBuff:SetVisible(true)
end


function MapBuildingTroopConstructionUIMediator:OnShow(param)
    ModuleRefer.MapBuildingTroopModule:RegisterAllBuildingChange(Delegate.GetOrCreate(self, self.RefreshTroopCount))
    ModuleRefer.MapBuildingTroopModule:RegisterAllBuildingBuildSpeedChange(Delegate.GetOrCreate(self, self.RefreshBuildSpeed))
    ModuleRefer.MapBuildingTroopModule:RegisterAllBuildingBuildStatusChange(Delegate.GetOrCreate(self, self.CheckIsBuildEnd))
end

function MapBuildingTroopConstructionUIMediator:OnHide(param)
    ModuleRefer.MapBuildingTroopModule:UnregisterAllBuildingChange(Delegate.GetOrCreate(self, self.RefreshTroopCount))
    ModuleRefer.MapBuildingTroopModule:UnregisterAllBuildingBuildSpeedChange(Delegate.GetOrCreate(self, self.RefreshBuildSpeed))
    ModuleRefer.MapBuildingTroopModule:UnregisterAllBuildingBuildStatusChange(Delegate.GetOrCreate(self, self.CheckIsBuildEnd))

    self:Clear()
end

---@param param MapBuildingParameter
function MapBuildingTroopConstructionUIMediator:OnOpened(param)
    self.param = param
    self.param.IsStrengthen = true

    self:Refresh()
end

function MapBuildingTroopConstructionUIMediator:OnCloseClicked()
    self:CloseSelf()
end

function MapBuildingTroopConstructionUIMediator:Refresh()
    self.textNameBuilding.text = ModuleRefer.MapBuildingTroopModule:GetBuildingName(self.param)
    local pos = self.param.MapBasics.BuildingPos
    self.textPosition.text = KingdomMapUtils.CoordToXYString(pos.X, pos.Y)
    self:RefreshBuildSpeed()
    self.troopList:FeedData(self.param)

    self:RefreshTroopCount()

    TileHighLightMap.ShowTileHighlight(self.tile)
end

function MapBuildingTroopConstructionUIMediator:Clear()
    ModuleRefer.MapBuildingTroopModule:ResetCamera()
    TileHighLightMap.HideTileHighlight(self.tile)
end

function MapBuildingTroopConstructionUIMediator:RefreshTroopCount()
    local troopCount = ModuleRefer.MapBuildingTroopModule:GetTotalTroopCount(self.param.Army, self.param.MapBasics, self.param.StrengthenArmy)
    local maxTroopCount = ModuleRefer.MapBuildingTroopModule:GetMaxTroopCount(self.param.MapBasics)
    self.textTroopQuantity.text = string.format("%d/%d", troopCount, maxTroopCount)
end

function MapBuildingTroopConstructionUIMediator:RefreshBuildSpeed()
    local speed = ModuleRefer.MapBuildingTroopModule:GetBuffString(self.param.MapBasics, self.param.Construction, self.param.VillageTransformInfo)
    self.textBuff.text = string.format("%s%%", speed)
end

function MapBuildingTroopConstructionUIMediator:CheckIsBuildEnd()
    if self.param and self.param.Construction and self.param.Construction.Status == wds.BuildingConstructionStatus.BuildingConstructionStatusDone then
        self:CloseSelf()
        return
    end
end

return MapBuildingTroopConstructionUIMediator