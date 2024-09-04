local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require("UIMediatorNames")
local Utils = require("Utils")
local CommonTriggerType = CS.FpAnimation.CommonTriggerType
local TimerUtility = require("TimerUtility")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class HUDAllianceDefence : BaseUIComponent
local HUDAllianceDefence = class('HUDAllianceDefence', BaseUIComponent)

function HUDAllianceDefence:OnCreate(param)
    ---@type CS.UnityEngine.UI.LayoutElement
    self._layout = self:BindComponent("", typeof(CS.UnityEngine.UI.LayoutElement))
    self._p_btn_league_defence = self:Button("p_btn_league_defence", Delegate.GetOrCreate(self, self.OnClickBtnTown))
    self._p_btn_league_defence_status = self:StatusRecordParent("p_btn_league_defence")
    -- self._p_text_battle = self:Text("p_text_battle")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._trigger = self:AnimTrigger("")
    self._animTimer = nil
    self._hasAnimPlayed = false
end

function HUDAllianceDefence:OnShow(param)
    self:Refresh()
    self:SetupEvents(true)
end

function HUDAllianceDefence:OnHide(param)
    self:RecycleAnim()
    self:SetupEvents(false)
end

function HUDAllianceDefence:OnClose(param)
    self:SetupEvents(false)
end

function HUDAllianceDefence:Refresh()
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self._tickEndTime = nil
    local info, count = self:GetVillageWarInfo()
    if not info then
        self._layout.ignoreLayout = true
        self._p_btn_league_defence:SetVisible(false)
        return
    end
    self._layout.ignoreLayout = false
    self._p_btn_league_defence:SetVisible(true)
    if Utils.IsNotNull(self._child_reddot_default) then
        self._child_reddot_default:ShowNumRedDot(count)
    end
    self._p_btn_league_defence_status:SetState(1)
    local duration = ConfigRefer.AllianceConsts:AllianceHudAnimDurationSec()

    self:PlayAnim((duration and duration > 0) and duration or 15)
end

function HUDAllianceDefence:OnClickBtnTown()
    ---@type AllianceWarMediatorParameter
    local indexParameter = {}
    indexParameter.enterTabIndex = 2
    g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, indexParameter)
end

function HUDAllianceDefence:SetupEvents(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceVillageWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceVillageWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.OwnVillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    end
end

---@param entity wds.Alliance
function HUDAllianceDefence:OnAllianceWarInfoChanged(entity, _)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    self._hasAnimPlayed = false
    self:Refresh()
end

---@param a wds.VillageAllianceWarInfo
---@param b wds.VillageAllianceWarInfo
function HUDAllianceDefence.SortWarInfo(a, b)
    local statusA = a.Status
    local statusB = b.Status
    if statusA > wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare and statusB <= wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
        return true
    end
    if statusB <= wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
        return a.StartTime < b.StartTime
    end
    return a.EndTime < b.EndTime
end

---@return wds.VillageAllianceWarInfo, number
function HUDAllianceDefence:GetVillageWarInfo()
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return nil, 0
    end
    local villageWars = ModuleRefer.AllianceModule:GetMyAllianceOwnVillageWar()
    local gateWars = ModuleRefer.AllianceModule:GetMyAllianceOwnGateWar()
    local behemothWars = ModuleRefer.AllianceModule:GetMyAllianceOwnedBehemothCageWar()

    local _, villageCount = table.IsNullOrEmpty(villageWars)
    local _, gateCount = table.IsNullOrEmpty(gateWars)
    local _, behemothCageCount = table.IsNullOrEmpty(behemothWars)

    local count = villageCount + gateCount + behemothCageCount
    if count == 0 then
        return nil, 0
    end
    local infoArray = {}
    for _, infos in pairs(villageWars) do
        for _, info in pairs(infos.WarInfo) do
            table.insert(infoArray, info)
        end
    end
    for _, infos in pairs(gateWars) do
        for _, info in pairs(infos.WarInfo) do
            table.insert(infoArray, info)
        end
    end
    for _, infos in pairs(behemothWars) do
        for _, info in pairs(infos.WarInfo) do
            table.insert(infoArray, info)
        end
    end
    table.sort(infoArray, HUDAllianceDefence.SortWarInfo)
    return infoArray[1], count
end

function HUDAllianceDefence:TickSec(dt)
    if not self._tickEndTime then
        return
    end
    local leftTime = self._tickEndTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if leftTime < 0 then
        self._tickEndTime = nil
        return
    end
    -- self._p_text_battle.text = TimeFormatter.SimpleFormatTime(leftTime)
end

---@param sec number
function HUDAllianceDefence:PlayAnim(sec)
    self:RecycleAnim()
    if self._hasAnimPlayed then
        return
    end
    self._trigger:FinishAll(CommonTriggerType.OnEnable)
    self._trigger:PlayAll(CommonTriggerType.Custom2)
    self._animTimer = TimerUtility.DelayExecute(function()
        self._trigger:FinishAll(CommonTriggerType.Custom2)
    end, sec)
    self._hasAnimPlayed = true
end

function HUDAllianceDefence:RecycleAnim()
    if self._animTimer then
        TimerUtility.StopAndRecycle(self._animTimer)
        self._animTimer = nil
    end
    self._trigger:FinishAll(CommonTriggerType.Custom2)
end

return HUDAllianceDefence