local ModuleRefer = require("ModuleRefer")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceVillageOccupationHistoryListCellData
---@field rank number
---@field player wds.DamagePlayerInfo

---@class AllianceVillageOccupationHistoryListCell:BaseTableViewProCell
---@field new fun():AllianceVillageOccupationHistoryListCell
---@field super BaseTableViewProCell
local AllianceVillageOccupationHistoryListCell = class('AllianceVillageOccupationHistoryListCell', BaseTableViewProCell)

function AllianceVillageOccupationHistoryListCell:OnCreate(param) 
    self._p_text_ranking = self:Text("p_text_ranking")
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")
    self._p_text_player_name = self:Text("p_text_player_name")
    self._p_text_power = self:Text("p_text_power")
    self._p_text_damage = self:Text("p_text_damage", "village_info_damage")
end

---@param data AllianceVillageOccupationHistoryListCellData
function AllianceVillageOccupationHistoryListCell:OnFeedData(data)
    self._p_text_ranking.text = tostring(data.rank)
    if data.player.PlayerId == ModuleRefer.PlayerModule:GetPlayerId() then
        local myData = ModuleRefer.PlayerModule:GetPlayer()
        self._child_ui_head_player:FeedData(myData.Basics.PortraitInfo)
        self._p_text_player_name.text = myData.Owner.PlayerName.String
    else
        self._child_ui_head_player:FeedData(data.player.PortraitInfo)
        self._p_text_player_name.text = data.player.Name
    end
    self._p_text_power.text = tostring(data.player.damage)
end

return AllianceVillageOccupationHistoryListCell