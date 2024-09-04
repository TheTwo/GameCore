local CommonNpcServiceGotoProvider = require("CommonNpcServiceGotoProvider")
---@class LegoBuildingNpcServiceGotoProvider:CommonNpcServiceGotoProvider
---@field new fun():LegoBuildingNpcServiceGotoProvider
local LegoBuildingNpcServiceGotoProvider = class("LegoBuildingNpcServiceGotoProvider", CommonNpcServiceGotoProvider)
local NpcServiceObjectType = require("NpcServiceObjectType")
local I18N = require("I18N")

---@param legoBuliding CityLegoBuilding
function LegoBuildingNpcServiceGotoProvider:ctor(legoBuliding)
    self.legoBuilding = legoBuliding
    CommonNpcServiceGotoProvider.ctor(self, NpcServiceObjectType.Building, self.legoBuilding.id)
end

function LegoBuildingNpcServiceGotoProvider:GetTitle()
    return I18N.Get(self.legoBuilding:GetNameI18N())
end

function LegoBuildingNpcServiceGotoProvider:GetHintText()
    return I18N.Get("tips_precondition_npc")
end

return LegoBuildingNpcServiceGotoProvider