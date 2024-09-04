local BaseTableViewProCell = require("BaseTableViewProCell")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIHelper = require("UIHelper")
local Utils = require("Utils")

---@class MapBuildingNPCTroopUICell :BaseTableViewProCell
local MapBuildingNPCTroopUICell = class("MapBuildingNPCTroopUICell", BaseTableViewProCell)

function MapBuildingNPCTroopUICell:OnCreate(param)
    -- self.p_img_head = self:Image("p_img_head")
    self.p_text_name_troop = self:Text("p_text_name_troop")
    self.p_progress_blood = self:Slider("p_progress_blood")
    self.p_text_num_power = self:Text("p_text_num_power")

    self.child_card_monster_s = self:LuaObject("child_card_monster_s")
end

---@param armyMemberInfo wds.ArmyMemberInfo
function MapBuildingNPCTroopUICell:OnFeedData(armyMemberInfo)
    self.p_text_name_troop.text = I18N.Get("village_info_Garrison_Defenders")
    self.p_progress_blood.value = armyMemberInfo.Hp / armyMemberInfo.HpMax
    self.p_text_num_power.text = tostring(armyMemberInfo.Hp)

    -- g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(spriteName), self.p_img_head)
    local heroConfig = ConfigRefer.Heroes:Find(armyMemberInfo.HeroTId[1])
    local spriteName = ModuleRefer.MapBuildingTroopModule:GetHeroSpriteName(heroConfig)
    local level = armyMemberInfo.HeroLevel and armyMemberInfo.HeroLevel[1]
    self.child_card_monster_s:FeedData({sprite = spriteName, level = level})
end

return MapBuildingNPCTroopUICell
