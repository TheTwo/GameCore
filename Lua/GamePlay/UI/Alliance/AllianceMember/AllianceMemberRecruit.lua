local DBEntityPath = require("DBEntityPath")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local AllianceMemberListRankCellData = require("AllianceMemberListRankCellData")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceMemberRecruitData
---@field InTableIndex number
---@field MemberId number
---@field MemberData wds.AllianceMember
---@field RankLv number

---@class AllianceMemberRecruit:BaseUIComponent
---@field new fun():AllianceMemberRecruit
---@field super BaseUIComponent
local AllianceMemberRecruit = class('AllianceMemberRecruit', BaseUIComponent)

function AllianceMemberRecruit:ctor()
    BaseUIComponent.ctor(self)
    self._allianceId = nil
    ---@type AllianceMemberListRankCellData[]
    self._tableData = {}
end

function AllianceMemberRecruit:OnCreate(param)
    self.p_table_recruit = self:TableViewPro("p_table_recruit")
    self.p_text_name_player = self:Text("p_text_name_player", "Alliance_main_label1")
    self.p_text_power_player = self:Text("p_text_power_player", "Alliance_main_label2")
    self.p_text_lv = self:Text("p_text_lv", "alliance_tec_dengji")
    self.p_text_online_time = self:Text("p_text_online_time", "#最近在线时间")

    self.p_text_hint = self:Text("p_text_hint", "#每日UTC +0刷新邀请入盟的推荐列表")
    self.p_btn_send_recruit = self:Button("p_btn_send_recruit", Delegate.GetOrCreate(self, self.OnClickRecruit))
    self.p_text = self:Text("p_text", "alliance_gathering_point_8")
end

function AllianceMemberRecruit:OnOpened(param)
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self:ReGenerateCells()
end

function AllianceMemberRecruit:OnShow(param)

end

function AllianceMemberRecruit:OnHide(param)

end

function AllianceMemberRecruit:OnClose(param)
end

function AllianceMemberRecruit:ReGenerateCells()
    self.p_table_recruit:Clear()
    local data = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance.PlayerAllianceWrapper.RecommendPlayerInfo
    local players = {}
    for k, v in pairs(data.RecommendPlayers) do
        table.insert(players, v)
    end
    table.sort(players, function(a, b)
        return a.LastLoginTime.Seconds > b.LastLoginTime.Seconds
    end)
    for k, v in pairs(players) do
        self.p_table_recruit:AppendData(v)
    end
end

function AllianceMemberRecruit:OnClickRecruit()
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    local lastConveneTime = allianceInfo.AllianceBasicInfo.LastConveneTime.Seconds
    local conveneCD = ConfigRefer.AllianceConsts:AllianceConveneCoolDown() / 1000000000
    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    local canSend
    local remainT
    if lastConveneTime > 0 then
        remainT = lastConveneTime + conveneCD - curT
        canSend = remainT <= 0
    else
        canSend = true
    end

    if canSend then
        ModuleRefer.AllianceModule:SendAllianceConvene()
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_gathering_point_7", TimeFormatter.SimpleFormatTime(remainT)))
    end
end

return AllianceMemberRecruit
