local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ArtResourceUtils = require("ArtResourceUtils")
local SEUnitCategory = require("SEUnitCategory")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class SeDetailPopupMonstersCell:BaseTableViewProCell
---@field new fun():SeDetailPopupMonstersCell
---@field super BaseTableViewProCell
local SeDetailPopupMonstersCell = class('SeDetailPopupMonstersCell', BaseTableViewProCell)

function SeDetailPopupMonstersCell:OnCreate(param)
    self._p_img_light = self:Image("p_img_light")
    self._p_img_monster = self:Image("p_img_monster")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_detail = self:Text("p_text_detail")
    self._p_boss = self:GameObject("p_boss", "BOSS")
    self._p_text_boss = self:Text("p_text_boss")
end

---@param data SeNpcConfigCell
function SeDetailPopupMonstersCell:OnFeedData(data)
    local isBoss = data:Category() == SEUnitCategory.Boss
    local icon = isBoss and ArtResourceUtils.GetUIItem(data:BossIcon()) or ArtResourceUtils.GetUIItem(data:MonsterInfoIcon())
    g_Game.SpriteManager:LoadSprite(icon, self._p_img_monster)
    self._p_text_name.text = I18N.Get(data:Name())
    self._p_text_detail.text = I18N.Get(data:Des())
    self._p_boss:SetVisible(isBoss)
    self._p_img_light:SetVisible(isBoss)
end

return SeDetailPopupMonstersCell