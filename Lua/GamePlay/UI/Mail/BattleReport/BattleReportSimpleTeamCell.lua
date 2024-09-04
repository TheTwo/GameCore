local BaseTableViewProCell = require("BaseTableViewProCell")
local ObjectType = require("ObjectType")
local MailUtils = require("MailUtils")
local I18N = require("I18N")

---@class BattleReportSimpleTeamCell : BaseTableViewProCell
local BattleReportSimpleTeamCell = class("BattleReportSimpleTeamCell", BaseTableViewProCell)

---@class BattleReportSimpleTeamCellData
---@field attacker wds.BattleReportUnitBasic
---@field target wds.BattleReportUnitBasic

function BattleReportSimpleTeamCell:OnCreate(param)
    ---@type PlayerInfoComponent[]
    self.playerPortrait = {}
    self.hpAfterBattle = {}
    self.hpBeforeBattle = {}
    self.hpValue = {}
    self.hpRoot = {}
    self.hpLoss = {}
    self.hpLoss2 = {}
    self.playerName = {}
    self.root = {}

    self.playerPortrait[1] = self:LuaObject("p_player_head_comp_l")
    self.hpAfterBattle[1] = self:Slider("p_progress_hp")
    self.hpBeforeBattle[1] = self:Image("p_progress_view_player")
    self.hpValue[1] = self:Text("p_text_hp")
    self.hpRoot[1] = nil
    self.hpLoss[1] = self:Text("p_text_power_loss")
    self.hpLoss2[1] = nil
    self.playerName[1] = self:Text("p_text_name")
    self.root[1] = self:GameObject("troop_player")

    self.playerPortrait[2] = self:LuaObject("p_player_head_comp_r")
    self.hpAfterBattle[2] = self:Slider("p_progress_hp_2")
    self.hpBeforeBattle[2] = self:Image("p_progress_view_player_2")
    self.hpValue[2] = self:Text("p_text_hp_2")
    self.hpRoot[2] = self:GameObject("p_hp")
    self.hpLoss[2] = self:Text("p_text_power_loss_2")
    self.hpLoss2[2] = self:Text("p_text_power_loss_3")
    self.playerName[2] = self:Text("p_text_name_2")
    self.root[2] = self:GameObject("troop_enemy")
end

---@param data BattleReportSimpleTeamCellData
function BattleReportSimpleTeamCell:OnFeedData(data)
	self:RefreshUI(data)
end

---@param data BattleReportSimpleTeamCellData
function BattleReportSimpleTeamCell:RefreshUI(data)
    self:RefreshItem(1, data.attacker)

    self:RefreshItem(2, data.target)
end

---@param index number
---@param info wds.BattleReportUnitBasic
function BattleReportSimpleTeamCell:RefreshItem(index, info)
    local visible = info ~= nil
    self.root[index]:SetActive(visible)

    if visible then
        if self.hpRoot[index] then
            self.hpRoot[index]:SetActive(true)
        end

        self.hpAfterBattle[index].value = math.clamp01(info.CurHp / info.MaxHp)
        self.hpBeforeBattle[index].fillAmount = math.clamp01(info.OriHp / info.MaxHp)
        self.hpValue[index].text = math.floor(info.CurHp) .. "/" .. math.floor(info.MaxHp)
        self.hpLoss[index].text = math.floor(info.CurHp - info.OriHp)

        if (info.ObjectType == ObjectType.SlgMob) then
    		local name, icon, level, monsterCfg = MailUtils.GetMonsterNameIconLevel(info.ConfId)
            self.playerName[index].text = "Lv." .. level .. " " .. name
            self.playerPortrait[index]:FeedData({iconName = icon})
            if monsterCfg and monsterCfg:IsStake() then
                if self.hpRoot[index] then
                    self.hpRoot[index]:SetActive(false)
                end

                if self.hpLoss2[index] then
                    self.hpLoss2[index]:SetVisible(true)
                    self.hpLoss2[index].text = I18N.GetWithParams("alliance_activity_coordination1", info.TakeDamage)
                end
            end
        else
            local name = MailUtils.MakePlayerName(info.AllianceName, info.Name)
            self.playerPortrait[index]:FeedData(info.PortraitInfo)
            self.playerName[index].text = name
        end
    end
end

return BattleReportSimpleTeamCell