local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local TimeFormatter = require("TimeFormatter")
local BaseTableViewProCell = require("BaseTableViewProCell")
local I18N = require("I18N")
local InviteToAllianceParameter = require("InviteToAllianceParameter")

---@class AllianceMemeberRecruitCell:BaseTableViewProCell
---@field new fun():AllianceMemeberRecruitCell
---@field super BaseTableViewProCell
local AllianceMemeberRecruitCell = class('AllianceMemeberRecruitCell', BaseTableViewProCell)

function AllianceMemeberRecruitCell:OnCreate(param)
    ---@type PlayerInfoComponent
    self.child_ui_head_player = self:LuaObject("child_ui_head_player")
    self.p_text_name_player = self:Text("p_text_name_player")
    self.p_text_position = self:Text("p_text_position")
    self.p_text_power_player = self:Text("p_text_power_player")
    self.p_text_lv = self:Text("p_text_lv")
    self.p_text_online_time = self:Text("p_text_online_time")

    ---@type BistateButtonSmall
    self.p_btn_invite = self:LuaObject("p_btn_invite")
end

function AllianceMemeberRecruitCell:OnFeedData(data)
    self.data = data
    data.PortraitInfo.PlayerId = data.PlayerId
    self.child_ui_head_player:FeedData(data.PortraitInfo)
    self.p_text_name_player.text = data.PlayerName
    self.p_text_power_player.text = data.Power
    self.p_text_lv.text = data.CommanderLevel
    self.p_text_position.text = string.format("#(x:%d,y:%d)", data.PosInfo.X, data.PosInfo.Y)

    local nowTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local passTime = nowTime - data.LastLoginTime.Seconds
    self.p_text_online_time.text = TimeFormatter.FormatLastOnlineTime(passTime)

    ---@type BistateButtonSmallParam
    local buttonData = {}
    buttonData.buttonText = I18N.Get("#邀请")
    buttonData.disableButtonText = I18N.Get("#已邀请")
    buttonData.onClick = Delegate.GetOrCreate(self, self.OnClickBtn)
    buttonData.disableClick = Delegate.GetOrCreate(self, self.OnClickDisabled)
    self.p_btn_invite:FeedData(buttonData)
    self:RefreshBtn()
end

function AllianceMemeberRecruitCell:RefreshBtn()
    self.p_btn_invite:SetEnabled(self.data.InviteTime.Seconds == 0)
end

function AllianceMemeberRecruitCell:OnClickBtn()
    local msg = InviteToAllianceParameter.new()
    msg.args.Invitee = self.data.PlayerId
    msg:SendWithFullScreenLockAndOnceCallback(nil, true, function(cmd, suc, resp)
        -- 无论成功与否 都置灰
        self.data.InviteTime.Seconds = g_Game.ServerTime:GetServerTimestampInSeconds()
        self:RefreshBtn()
    end)
end

function AllianceMemeberRecruitCell:OnClickDisabled()
    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("#已邀请此玩家"))
end

return AllianceMemeberRecruitCell
