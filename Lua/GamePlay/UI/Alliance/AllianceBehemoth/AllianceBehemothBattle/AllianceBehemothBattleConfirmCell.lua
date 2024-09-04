local ModuleRefer = require("ModuleRefer")
local AllianceModuleDefine = require("AllianceModuleDefine")
local BaseUIComponent = require("BaseUIComponent")

---@class AllianceBehemothBattleConfirmCellData
---@field memberInfo wrpc.AllianceMemberInfo
---@field checked boolean
---@field index number

---@class AllianceBehemothBattleConfirmCell:BaseUIComponent
---@field new fun():AllianceBehemothBattleConfirmCell
---@field super BaseUIComponent
local AllianceBehemothBattleConfirmCell = class('AllianceBehemothBattleConfirmCell', BaseUIComponent)

function AllianceBehemothBattleConfirmCell:OnCreate(param)
    self._p_base = self:GameObject("p_base")
    self._p_on = self:GameObject("p_on")
    self._p_off = self:GameObject("p_off")
    ---@see PlayerInfoComponent
    self._child_ui_head_player = self:LuaBaseComponent("child_ui_head_player")
    self._p_text_name = self:Text("p_text_name")
    self._p_icon_r = self:Image("p_icon_r")
end

---@param data AllianceBehemothBattleConfirmCellData
function AllianceBehemothBattleConfirmCell:OnFeedData(data)
    self._p_text_name.text = data.memberInfo.Name
    if data.memberInfo.PlayerID == ModuleRefer.PlayerModule:GetPlayerId() then
        self._child_ui_head_player:FeedData(ModuleRefer.PlayerModule:GetPlayer().Basics.PortraitInfo)
    else
        self._child_ui_head_player:FeedData(data.memberInfo.PortraitInfo)
    end
    self._p_on:SetVisible(data.checked)
    self._p_off:SetVisible(not data.checked)
    self._p_base:SetActive(data.index % 2 == 0)
    local rank = data.memberInfo.Rank
    if rank >= AllianceModuleDefine.OfficerRank then
        self._p_icon_r.gameObject:SetActive(true)
        g_Game.SpriteManager:LoadSprite(AllianceModuleDefine.GetAllianceRankIconName(rank), self._p_icon_r)
    else
        self._p_icon_r.gameObject:SetActive(false)
    end
end

return AllianceBehemothBattleConfirmCell