local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceModuleDefine = require("AllianceModuleDefine")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceImpeachmentVoteListCell:BaseTableViewProCell
---@field new fun():AllianceImpeachmentVoteListCell
---@field super BaseTableViewProCell
local AllianceImpeachmentVoteListCell = class('AllianceImpeachmentVoteListCell', BaseTableViewProCell)

function AllianceImpeachmentVoteListCell:OnCreate(param)
    ---@see PlayerInfoComponent
    self._child_ui_head_player = self:LuaBaseComponent("child_ui_head_player")
    self._p_icon_r = self:Image("p_icon_r")
    self._p_text_name = self:Text("p_text_name")
end

---@param data wds.AllianceMember
function AllianceImpeachmentVoteListCell:OnFeedData(data)
    self._child_ui_head_player:FeedData(data)
    self._p_text_name.text = data.Name
    g_Game.SpriteManager:LoadSprite(AllianceModuleDefine.GetRankIcon(data.Rank), self._p_icon_r)
end

return AllianceImpeachmentVoteListCell