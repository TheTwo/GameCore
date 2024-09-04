
local Delegate = require("Delegate")
local BaseTableViewProCell = require ('BaseTableViewProCell')
local I18N = require("I18N")

---@class CityExplorerUIHeroCell:BaseTableViewProCell
---@field new fun():CityExplorerUIHeroCell
---@field super BaseTableViewProCell
local CityExplorerUIHeroCell = class('CityExplorerUIHeroCell', BaseTableViewProCell)

function CityExplorerUIHeroCell:OnCreate(param)
    ---@type CS.StatusRecordParent
    self._s_status = self.CSComponent:GetComponent(typeof(CS.StatusRecordParent))
    self._img_heroIcon = self:Image("p_img_hero")
    self._btn_self = self:Button("child_card_hero_m", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._lb_herName = self:Text("p_text_name")
    self._img_check = self:Image("p_icon_check")
    self._img_check.enabled = false
end

---{BId = self._buildingId, HId = 101, HCfg = heroConfig:Find(101), IsCurrent = false}
function CityExplorerUIHeroCell:OnFeedData(data)
    self._data = data
    self._img_check.enabled = data.IsCurrent
    if data.BId and (not data.IsCurrent) then
        self._s_status:ApplyStatusRecord(2)
    end
    self._lb_herName.text = I18N.Get(data.HCfg:Name())
    g_Game.SpriteManager:LoadSprite(data.HCfg:HeadIcon(), self._img_heroIcon)
end

function CityExplorerUIHeroCell:Select(param)
    self._s_status:ApplyStatusRecord(1)
end

function CityExplorerUIHeroCell:UnSelect(param)
    self._s_status:ApplyStatusRecord(0)
end

function CityExplorerUIHeroCell:OnClickSelf()
    if (not self._data) or (self._data.BId and (not self._data.IsCurrent)) then
        return
    end
    self:GetTableViewPro():SetToggleSelect(self._data)
end

return CityExplorerUIHeroCell