local Delegate = require("Delegate")
local MailUtils = require("MailUtils")
local BaseUIComponent = require("BaseUIComponent")
local NumberFormatter = require("NumberFormatter")
local ModuleRefer = require("ModuleRefer")

---@class WallReinforcePageCellPlayer : BaseUIComponent
local WallReinforcePageCellPlayer = class("WallReinforcePageCellPlayer", BaseUIComponent)

function WallReinforcePageCellPlayer:OnCreate()
    ---@type PlayerInfoComponent
    self.child_ui_head_player = self:LuaObject("child_ui_head_player")
    self.p_text_player_name = self:Text("p_text_player_name")
    self.p_text_power = self:Text("p_text_power")
    self.p_progress_hp = self:Slider("p_progress_hp")
    self.p_text_progress_hp = self:Text("p_text_progress_hp")
    self.p_btn_ally = self:Button("p_btn_ally", Delegate.GetOrCreate(self, self.OnFold))

    ---@type CS.StatusRecordParent
    self.fold = self.p_btn_ally:GetComponent(typeof(CS.StatusRecordParent))

    self.p_btn_back = self:Button("p_btn_back", Delegate.GetOrCreate(self, self.OnBack))
end

---@param data ReinforceListData
function WallReinforcePageCellPlayer:OnFeedData(data)
    self.data = data
    self:RefreshUI()
end

function WallReinforcePageCellPlayer:RefreshUI()
    local data = self.data
    self.fold:SetState(data.fold)

    local member = data.member
    local hpRatio = math.clamp01(member.Hp / member.HpMax)

    self.child_ui_head_player:FeedData(member.PortraitInfo)
    self.p_text_player_name.text = MailUtils.MakePlayerName(member.AllianceAbbr, member.Name)
    self.p_text_power.text = NumberFormatter.Normal(member.Power)
    self.p_progress_hp.value = hpRatio
    self.p_text_progress_hp.text = string.format("%0.2f", (hpRatio * 100)) .. "%"
end

function WallReinforcePageCellPlayer:OnFold()
    self.data.fold = 1 - self.data.fold
    self.fold:SetState(self.data.fold)
    self.data.onFold(self.data)
end

function WallReinforcePageCellPlayer:OnBack()
    -- 遣送
    local castle = ModuleRefer.PlayerModule:GetCastle()
    ModuleRefer.SlgModule:LeaveReinforce(castle.ID, self.data.member.Id)
end

return WallReinforcePageCellPlayer