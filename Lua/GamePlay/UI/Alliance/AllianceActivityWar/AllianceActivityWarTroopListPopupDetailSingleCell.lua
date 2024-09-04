local ConfigRefer = require("ConfigRefer")
local HeroConfigCache = require("HeroConfigCache")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceActivityWarTroopListPopupDetailSingleCell:BaseTableViewProCell
---@field new fun():AllianceActivityWarTroopListPopupDetailSingleCell
---@field super BaseTableViewProCell
local AllianceActivityWarTroopListPopupDetailSingleCell = class('AllianceActivityWarTroopListPopupDetailSingleCell', BaseTableViewProCell)

function AllianceActivityWarTroopListPopupDetailSingleCell:OnCreate(param)
    self._p_text_power = self:Text("p_text_power")
    self._p_icon_arm = self:Image("p_icon_arm")
    ---@type CS.UnityEngine.GameObject[]
    self._p_empty = {}
    for i = 1, 3 do
        self._p_empty[i] = self:GameObject(string.format("p_empty_%s", i))
    end
    ---@type HeroInfoItemComponent[]
    self._child_card_hero_s = {}
    for i = 1, 3 do
        self._child_card_hero_s[i] = self:LuaObject(string.format("child_card_hero_s_%s", i))
    end
end

---@param data wds.TroopCreateParam
function AllianceActivityWarTroopListPopupDetailSingleCell:OnFeedData(data)
    self._p_text_power.text = tostring(data.Power)
    for i = 1, 3 do
        local heroData = data.Heroes[i - 1]
        if not heroData then
            self._p_empty[i]:SetVisible(true)
            self._child_card_hero_s[i]:SetVisible(false)
        else
            self._p_empty[i]:SetVisible(false)
            self._child_card_hero_s[i]:SetVisible(true)
            local heroConfig = ConfigRefer.Heroes:Find(heroData.ConfigId)
            ---@type HeroInfoData
            local heroCell = {}
            heroCell.heroData = HeroConfigCache.New(heroConfig)
            self._child_card_hero_s[i]:FeedData(heroCell)
        end
    end
end

return AllianceActivityWarTroopListPopupDetailSingleCell