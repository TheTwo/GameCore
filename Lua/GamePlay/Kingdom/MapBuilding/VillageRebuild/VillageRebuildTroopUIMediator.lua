--- scene_construction_popup_help_troop

local BaseUIMediator = require("BaseUIMediator")
local I18N = require("I18N")

---@class VillageRebuildTroopUIMediator : BaseUIMediator
---@field strengthen wds.Strengthen
local VillageRebuildTroopUIMediator = class("VillageRebuildTroopUIMediator", BaseUIMediator)

function VillageRebuildTroopUIMediator:OnCreate(param)
    self.p_text_title = self:Text("p_text_title", I18N.Get("village_outpost_info_assistance_team"))
    self.p_text_troop_quantity = self:Text("p_text_troop_quantity")
    self.p_table_troop = self:TableViewPro("p_table_troop")
end

---@param param wds.Strengthen
function VillageRebuildTroopUIMediator:OnShow(param)
    self.strengthen = param
    
    local troopCount = table.nums(self.strengthen.PlayerTroopIDs)
    self.p_text_troop_quantity.text = I18N.Get("village_outpost_info_players") .. tostring(troopCount)
    
    self.p_table_troop:Clear()
    for _, armyMemberInfo in pairs(self.strengthen.PlayerTroopIDs) do
        self.p_table_troop:AppendData(armyMemberInfo)
    end
    self.p_table_troop:RefreshAllShownItem()
end

function VillageRebuildTroopUIMediator:OnHide(param)
end

return VillageRebuildTroopUIMediator