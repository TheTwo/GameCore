local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")

---@class MapBuildingTroopEmptyUICellParameter
---@field tile MapRetrieveResult
---@field isReinforce boolean

---@class MapBuildingTroopEmptyUICell : BaseUIComponent
---@field buttonReinforce  CS.UnityEngine.UI.Button
---@field tile MapRetrieveResult
local MapBuildingTroopEmptyUICell = class("MapBuildingTroopEmptyUICell", BaseUIComponent)

function MapBuildingTroopEmptyUICell:OnCreate(param)
    self:Text("p_text", "djianzhu_paiqian")
    self.buttonReinforce = self:Button("p_comp_btn_help", Delegate.GetOrCreate(self, self.OnReinforceClicked))
    self.isReinforce = false
end

---@param tile MapBuildingTroopEmptyUICellParameter|MapRetrieveResult
function MapBuildingTroopEmptyUICell:OnFeedData(tile)
    if tile.tile then
        self.tile = tile.tile
        self.isReinforce = tile.isReinforce
    else
        self.tile = tile
    end
end 

function MapBuildingTroopEmptyUICell:OnReinforceClicked()
    if self.isReinforce then
        require('KingdomTouchInfoOperation').SendReinforceTroop(self.tile)
    else
        require('KingdomTouchInfoOperation').SendStrengthenTroop(self.tile)
    end
end

return MapBuildingTroopEmptyUICell