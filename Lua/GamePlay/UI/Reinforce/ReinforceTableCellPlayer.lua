local Delegate = require("Delegate")
local MailUtils = require("MailUtils")
local ModuleRefer = require("ModuleRefer")
local BaseUIComponent = require("BaseUIComponent")
local NumberFormatter = require("NumberFormatter")
local TimeFormatter = require("TimeFormatter")

---@class ReinforceTableCellPlayer : BaseUIComponent
local ReinforceTableCellPlayer = class("ReinforceTableCellPlayer", BaseUIComponent)

function ReinforceTableCellPlayer:OnCreate()
    ---@type PlayerInfoComponent
    self.child_ui_head_player = self:LuaObject("child_ui_head_player")
    self.p_text_player_name = self:Text("p_text_player_name")
    self.p_text_power = self:Text("p_text_power")
    self.p_progress_hp = self:Slider("p_progress_hp")
    self.p_text_progress_hp = self:Text("p_text_progress_hp")
    self.p_btn_ally = self:Button("p_btn_ally", Delegate.GetOrCreate(self, self.OnFold))

    ---@type CS.StatusRecordParent
    self.fold = self.p_btn_ally:GetComponent(typeof(CS.StatusRecordParent))

    self.p_troop_status_march = self:Transform("p_troop_status_march")
    self.p_text_status_march = self:Text("p_text_status_march", "formation-xingjun")
    self.p_progress_status = self:Slider("p_progress_status")
    self.p_text_time_march = self:Text("p_text_time_march")

    self.p_troop_status_station = self:Transform("p_troop_status_station")
    self.p_text_status_station = self:Text("p_text_status_station", "formation-zhuzha")
    self.p_btn_back = self:Button("p_btn_back", Delegate.GetOrCreate(self, self.OnBack))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.Tick))
end

function ReinforceTableCellPlayer:OnClose()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.Tick))
end

---@param data ReinforceListData
function ReinforceTableCellPlayer:OnFeedData(data)
    self.data = data
    self:RefreshUI()
end

function ReinforceTableCellPlayer:RefreshUI()
    local data = self.data
    self.fold:SetState(data.fold)

    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    local member = data.member
    local hpRatio = math.clamp01(member.Hp / member.HpMax)
    local isMyself = member.PlayerId == myPlayerId

    self.child_ui_head_player:FeedData(member.PortraitInfo)
    self.p_text_player_name.text = MailUtils.MakePlayerName(member.AllianceAbbr, member.Name)
    self.p_text_power.text = NumberFormatter.Normal(member.Power)
    self.p_progress_hp.value = hpRatio
    self.p_text_progress_hp.text = string.format("%0.2f", (hpRatio * 100)) .. "%"

    self.p_troop_status_march:SetVisible(not data.arrived)
    self.p_troop_status_station:SetVisible(data.arrived)
    self.p_progress_status:SetVisible(false) -- 隐藏行军进度条

    if data.arrived then
        self.p_btn_back:SetVisible(isMyself)
    else
        if isMyself then
            self:Tick()
        end
    end
end

function ReinforceTableCellPlayer:OnFold()
    self.data.fold = 1 - self.data.fold
    self.fold:SetState(self.data.fold)
    self.data.onFold(self.data)
end

function ReinforceTableCellPlayer:OnBack()
    ModuleRefer.SlgModule:ReturnToHome(self.data.member.Id)
end

function ReinforceTableCellPlayer:Tick()
    if self.data == nil then
        return
    end

    local ctrl = ModuleRefer.SlgModule:GetCtrl(self.data.member.Id)
    if ctrl == nil then
        return
    end

    local view = ctrl:GetTroopView()
    if view == nil then
        return
    end

    local duration = view:GetMoveStopTime() - g_Game.ServerTime:GetServerTimestampInSeconds()
    duration = math.max(duration, 0)
    self.p_text_time_march.text = TimeFormatter.SimpleFormatTime(duration)
end

return ReinforceTableCellPlayer