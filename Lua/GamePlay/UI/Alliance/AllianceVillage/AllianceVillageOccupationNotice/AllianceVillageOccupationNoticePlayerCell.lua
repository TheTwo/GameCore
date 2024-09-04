local ModuleRefer = require("ModuleRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceVillageOccupationNoticePlayerCell:BaseUIComponent
---@field new fun():AllianceVillageOccupationNoticePlayerCell
---@field super BaseUIComponent
local AllianceVillageOccupationNoticePlayerCell = class('AllianceVillageOccupationNoticePlayerCell', BaseUIComponent)

function AllianceVillageOccupationNoticePlayerCell:OnCreate(param)
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")
    self._p_text_name = self:Text("p_text_name")
    self._p_text = self:Text("p_text")
    self._p_icon_rank = self:Image("p_icon_rank")
end

---@param data {rank:number, player:wrpc.DamagePlayerInfo}
function AllianceVillageOccupationNoticePlayerCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite( self:GetRankStr(data.rank), self._p_icon_rank)
    if data.player.PlayerId == ModuleRefer.PlayerModule:GetPlayerId() then
        local myData = ModuleRefer.PlayerModule:GetPlayer()
        self._p_text_name.text = myData.Owner.PlayerName.String
        self._child_ui_head_player:FeedData(myData.Basics.PortraitInfo)
    else
        local allianceMember = ModuleRefer.AllianceModule:QueryMyAllianceMemberDataByPlayerId(data.player.PlayerId)
        self._p_text_name.text = allianceMember and allianceMember.Name or data.player.Name
        self._child_ui_head_player:FeedData(data.player)
    end
end

function AllianceVillageOccupationNoticePlayerCell:GetRankStr(rank)
    if rank < 1 or rank > 3 then
        return "sp_icon_missing"
    end
    return ("sp_world_icon_rank_%d"):format(rank)
end

return AllianceVillageOccupationNoticePlayerCell