local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')

---@class CityFurnitureDeployUIHeroCell:BaseTableViewProCell
local CityFurnitureDeployUIHeroCell = class('CityFurnitureDeployUIHeroCell', BaseTableViewProCell)

function CityFurnitureDeployUIHeroCell:OnCreate()
    self._p_btn_hero = self:Button("p_btn_hero", Delegate.GetOrCreate(self, self.OnClick))
    ---@type HeroInfoItemSmallComponent
    self._p_hero = self:LuaObject("p_hero")
    self._p_text_hero_name = self:Text("p_text_hero_name")
    self._p_text_hero_lv = self:Text("p_text_hero_lv")
    self._p_text_baseline = self:Text("p_text_baseline", "pet_sync_name")
end

---@param data CityFurnitureDeployHeroCellData
function CityFurnitureDeployUIHeroCell:OnFeedData(data)
    self.data = data
    self._p_hero:FeedData({heroData = data:GetHeroData()})
    self._p_text_hero_name.text = data:GetHeroName()
    self._p_text_hero_lv.text = data:GetHeroLv()
    self._p_text_baseline:SetVisible(data:IsShareTarget())
end

return CityFurnitureDeployUIHeroCell