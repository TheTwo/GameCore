local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceMainCampaignEntryData
---@field onClick fun()

---@class AllianceMainCampaignEntry:BaseUIComponent
---@field new fun():AllianceMainCampaignEntry
---@field super BaseUIComponent
local AllianceMainCampaignEntry = class('AllianceMainCampaignEntry', BaseUIComponent)

function AllianceMainCampaignEntry:ctor()
    BaseUIComponent.ctor(self)
    self._onClick = nil
end

function AllianceMainCampaignEntry:OnCreate(param)
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelfBtn))
    self._p_text_campaign = self:Text("p_text_campaign", "alliance_behemoth_title_name")
    self._p_status_n = self:GameObject("p_status_n")
    self._p_status_war = self:GameObject("p_status_war")
    self._p_text_war_name = self:Text("p_text_war_name")
    self._p_text_war_staus = self:Text("p_text_war_staus")
end

function AllianceMainCampaignEntry:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleDataChanged))
end

function AllianceMainCampaignEntry:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleDataChanged))
end

function AllianceMainCampaignEntry:OnClose(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.OnBattleDataChanged))
end

---@param data AllianceMainCampaignEntryData
function AllianceMainCampaignEntry:OnFeedData(data)
    self._onClick = data.onClick
    self:RefreshStatus()
end

function AllianceMainCampaignEntry:OnClickSelfBtn()
    if self._onClick then
        self._onClick()
    end
end

function AllianceMainCampaignEntry:RefreshStatus()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceData then
        self._p_status_war:SetVisible(false)
        self._p_status_n:SetVisible(true)
        return
    end
    local showStatus = false
    if allianceData.AllianceActivityBattles and allianceData.AllianceActivityBattles.Battles then
        local statuesEnum = wds.AllianceActivityBattleStatus
        ---@type wds.AllianceActivityBattleInfo
        local selectedInfo = nil
        for _, battleInfo in pairs(allianceData.AllianceActivityBattles.Battles) do
            if selectedInfo then
                if battleInfo.Status == statuesEnum.AllianceBattleStatusBattling 
                        and selectedInfo.Status ~= statuesEnum.AllianceBattleStatusBattling then
                    selectedInfo = battleInfo
                elseif battleInfo.Status == statuesEnum.AllianceBattleStatusActivated 
                        and selectedInfo.Status ~= statuesEnum.AllianceBattleStatusActivated 
                        and selectedInfo.Status ~= statuesEnum.AllianceBattleStatusBattling then
                    selectedInfo = battleInfo
                elseif battleInfo.CloseTime.Seconds < selectedInfo.CloseTime.Seconds then
                    selectedInfo = battleInfo
                elseif battleInfo.CloseTime.Seconds == selectedInfo.CloseTime.Seconds and battleInfo.StartBattleTime.Seconds < selectedInfo.StartBattleTime.Seconds then
                    selectedInfo = battleInfo
                end
            elseif battleInfo.Status == statuesEnum.AllianceBattleStatusBattling 
                    or battleInfo.Status == statuesEnum.AllianceBattleStatusActivated then
                selectedInfo = battleInfo
            end
        end
        if selectedInfo then
            local cfg = ConfigRefer.KmonsterData:Find(selectedInfo.MonsterTid)
            if cfg then
                showStatus = true
                self._p_text_war_name.text = I18N.Get(cfg:Name())
                self._p_text_war_staus.text = I18N.Get("alliance_battle_hud2")
            end
        end
    end
    self._p_status_war:SetVisible(showStatus)
    self._p_status_n:SetVisible(not showStatus)
end

---@param entity wds.Alliance
function AllianceMainCampaignEntry:OnBattleDataChanged(entity, changedData)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return
    end
    if ModuleRefer.AllianceModule:GetAllianceId() ~= entity.ID then
        return
    end
    self:RefreshStatus()
end

return AllianceMainCampaignEntry