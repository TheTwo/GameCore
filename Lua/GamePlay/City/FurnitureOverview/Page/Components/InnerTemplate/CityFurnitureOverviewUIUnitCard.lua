local CityFurnitureOverviewUIUnit = require("CityFurnitureOverviewUIUnit")
---@class CityFurnitureOverviewUIUnitCard:CityFurnitureOverviewUIUnit
---@field new fun():CityFurnitureOverviewUIUnitCard
local CityFurnitureOverviewUIUnitCard = class("CityFurnitureOverviewUIUnitCard", CityFurnitureOverviewUIUnit)
local FurnitureOverview_I18N = require("FurnitureOverview_I18N")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")

function CityFurnitureOverviewUIUnitCard:OnCreate()
    self._rootButton = self:Button("", Delegate.GetOrCreate(self,self.OnButtonClick))
    self._statusRecord = self:StatusRecordParent("")
    self._p_text_free_card = self:Text("p_text_free_card", FurnitureOverview_I18N.GambleText)
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._p_progress_card = self:Slider("p_progress_card")
    self._p_text_time_card = self:Text("p_text_time_card")
end

function CityFurnitureOverviewUIUnitCard:OnButtonClick()
    g_Game.UIManager:Open(UIMediatorNames.HeroCardMediator)
end

return CityFurnitureOverviewUIUnitCard