local BaseUIMediator = require("BaseUIMediator")
local DBEntityType = require("DBEntityType")
local PlayerModule = require("PlayerModule")
local NumberFormatter = require("NumberFormatter")

---@class ReplicaPVPBattleStartMediatorParameter
---@field env SEEnvironment

---@class ReplicaPVPBattleStartMediator:BaseUIMediator
---@field new fun():ReplicaPVPBattleStartMediator
---@field super BaseUIMediator
local ReplicaPVPBattleStartMediator = class('ReplicaPVPBattleStartMediator', BaseUIMediator)

function ReplicaPVPBattleStartMediator:OnCreate(param)
    self.txtAttackerName = self:Text('p_text_name_attacker')
    self.txtAttackerPower = self:Text('p_text_power_attacker')
    ---@type PlayerInfoComponent
    self.attackerHeadIcon = self:LuaObject('p_head_attacker')
    
    self.txtDefenderName = self:Text('p_text_name_defender')
    self.txtDefenderPower = self:Text('p_text_power_defender')
    ---@type PlayerInfoComponent
    self.defenderHeadIcon = self:LuaObject('p_head_defender')
end

---@param data ReplicaPVPBattleStartMediatorParameter
function ReplicaPVPBattleStartMediator:OnOpened(param)
    ---@type SEEnvironment
    self.env = param.env

    local attackerPlayerId = g_Game.StateMachine:ReadBlackboard("SE_PVP_ATTACKER_ID", false)
    local defenderPlayerId = g_Game.StateMachine:ReadBlackboard("SE_PVP_DEFENDER_ID", false)

    ---@type wds.ScenePlayer
    local attacker = self.env:GetWdsManager():GetScenePlayer(attackerPlayerId)
    if attacker then
        self.txtAttackerName.text = PlayerModule.FullName(attacker.Owner.AllianceAbbr.String, attacker.Owner.PlayerName.String)
        self.txtAttackerPower.text = NumberFormatter.Normal(attacker.ScenePlayerPreset.Power)
        self.attackerHeadIcon:FeedData(attacker.BasicInfo.PortraitInfo)
    else
        g_Logger.Error('ReplicaPVPBattleStartMediator: Attacker not found, playerid %s', attackerPlayerId)
    end

    ---@type wds.ScenePlayer
    local defender = self.env:GetWdsManager():GetScenePlayer(defenderPlayerId)
    if defender then
        self.txtDefenderName.text = PlayerModule.FullName(defender.Owner.AllianceAbbr.String, defender.Owner.PlayerName.String)
        self.txtDefenderPower.text = NumberFormatter.Normal(defender.ScenePlayerPreset.Power)
        self.defenderHeadIcon:FeedData(defender.BasicInfo.PortraitInfo)
    else
        g_Logger.Error('ReplicaPVPBattleStartMediator: Defender not found, playerid %s', defenderPlayerId)
    end

    g_Game.SoundManager:Play("sfx_se_fight_began")
end

function ReplicaPVPBattleStartMediator:OnClose(param)

end

function ReplicaPVPBattleStartMediator:OnShow(param)
end

function ReplicaPVPBattleStartMediator:OnHide(param)
end

return ReplicaPVPBattleStartMediator