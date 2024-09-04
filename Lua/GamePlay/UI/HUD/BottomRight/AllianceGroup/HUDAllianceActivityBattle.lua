local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local UIMediatorNames = require("UIMediatorNames")

local BaseUIComponent = require("BaseUIComponent")

---@class HUDAllianceActivityBattle:BaseUIComponent
---@field new fun():HUDAllianceActivityBattle
---@field super BaseUIComponent
local HUDAllianceActivityBattle = class('HUDAllianceActivityBattle', BaseUIComponent)

function HUDAllianceActivityBattle:ctor()
    HUDAllianceActivityBattle.super.ctor(self)
    self._eventSetup = false
    self._battleId = nil
end

function HUDAllianceActivityBattle:OnCreate(param)
    ---@type CS.UnityEngine.UI.LayoutElement
    self._layout = self:BindComponent("", typeof(CS.UnityEngine.UI.LayoutElement))
    self._p_btn_league_boss = self:Button("p_btn_league_boss", Delegate.GetOrCreate(self, self.OnClickBtnEnter))
    self._p_btn_league_boss_status = self:StatusRecordParent("p_btn_league_boss")
    self._p_img_head_boss = self:Image("p_img_head_boss")
    self._p_text_battle = self:Text("p_text_battle")
end

function HUDAllianceActivityBattle:OnShow(param)
    self:OnBattleRefresh()
    self:SetupEvents(true)
end

function HUDAllianceActivityBattle:OnHide(param)
    self:SetupEvents(false)
end

---@param a wds.AllianceActivityBattleInfo
---@param b wds.AllianceActivityBattleInfo
---@return boolean
local function Sort(a, b)
    if a.Status > b.Status then
        return true
    end
    if b.Status > a.Status then
        return false
    end
    if a.CloseTime.Seconds < b.CloseTime.Seconds then
        return true
    end
    if a.CloseTime.Seconds > b.CloseTime.Seconds then
        return true
    end
    return a.OpenTime.Seconds < b.OpenTime.Seconds
end

---@return wds.AllianceActivityBattleInfo
function HUDAllianceActivityBattle:CheckHasAvailableBattle()
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return nil
    end
    local myAllianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not myAllianceData then
        return nil
    end
    local myBattleData = myAllianceData.AllianceActivityBattles and myAllianceData.AllianceActivityBattles.Battles
    if not myBattleData then
        return
    end
    local battleArray = {}
    local enum = wds.AllianceActivityBattleStatus
    for _, v in pairs(myBattleData) do
        if v.Status > enum.AllianceBattleStatusClose and v.Status < enum.AllianceBattleStatusFinished then
            table.insert(battleArray, v)
        end
    end
    table.sort(battleArray, Sort)
    return battleArray[1]
end

function HUDAllianceActivityBattle:OnClickBtnEnter()
    if not self._battleId then
        return
    end
    if not ModuleRefer.AllianceModule:CheckBehemothUnlock(true) then
        return
    end
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return
    end
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    local battleData = allianceData and allianceData.AllianceActivityBattles and allianceData.AllianceActivityBattles.Battles
    if not battleData then
        return
    end
    local data = battleData[self._battleId]
    if not data then
        return
    end
    local tabId = ConfigRefer.AllianceConsts:BehemothActiviyChallengeTab()
    ModuleRefer.ActivityCenterModule:GotoActivity(tabId)
end

function HUDAllianceActivityBattle:OnBattleRefresh()
    self._battleId = nil
    local battleData = self:CheckHasAvailableBattle()
    if not battleData or battleData.Status >= wds.AllianceActivityBattleStatus.AllianceBattleStatusFinished then
        self:SetNoBattle()
        return
    end
    self._battleId = battleData.ID
    local config = ConfigRefer.AllianceBattle:Find(battleData.CfgId)
    if not config then
        self:SetNoBattle()
        return
    end
    if (not ModuleRefer.ActivityBehemothModule:IsDeviceBuilt()) then
        self:SetNoBattle()
        return
    end
    if not battleData or battleData.Status < wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated then
        self:SetNoBattle()
        return
    end
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(config:BossIcon()), self._p_img_head_boss)
    self._p_text_battle.text = I18N.Get("league_hud_battle")
    self._layout.ignoreLayout = false
    self._p_btn_league_boss:SetVisible(true)
    if battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then
        self._p_btn_league_boss_status:SetState(1)
    else
        self._p_btn_league_boss_status:SetState(0)
    end
end

function HUDAllianceActivityBattle:SetupEvents(add)
    if not self._eventSetup and add then
        self._eventSetup = true
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_BATTLE_HUD_REFRESH, Delegate.GetOrCreate(self, self.OnBattleRefresh))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_DEVICE_UPDATE, Delegate.GetOrCreate(self, self.OnBattleRefresh))
        g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_DEVICE_REMOVED, Delegate.GetOrCreate(self, self.OnBattleRefresh))
    elseif self._eventSetup and not add then
        self._eventSetup = false
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BATTLE_HUD_REFRESH, Delegate.GetOrCreate(self, self.OnBattleRefresh))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_DEVICE_UPDATE, Delegate.GetOrCreate(self, self.OnBattleRefresh))
        g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_DEVICE_REMOVED, Delegate.GetOrCreate(self, self.OnBattleRefresh))
    end
end

function HUDAllianceActivityBattle:SetNoBattle()
    self._layout.ignoreLayout = true
    self._p_btn_league_boss:SetVisible(false)
end

return HUDAllianceActivityBattle