local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require("UIMediatorNames")
local Utils = require("Utils")
local CommonTriggerType = CS.FpAnimation.CommonTriggerType
local TimerUtility = require("TimerUtility")
local ConfigRefer = require("ConfigRefer")
local FPXSDKBIDefine = require("FPXSDKBIDefine")

local BaseUIComponent = require("BaseUIComponent")

---@class HUDAllianceVillage:BaseUIComponent
---@field new fun():HUDAllianceVillage
---@field super BaseUIComponent
local HUDAllianceVillage = class('HUDAllianceVillage', BaseUIComponent)

function HUDAllianceVillage:ctor()
    HUDAllianceVillage.super.ctor(self)
    self._eventAdd = false
    self._allianceId = nil
    self._tickEndTime = nil
    self._animTimer = nil
    self._hasAnimPlayed = false
end

function HUDAllianceVillage:OnCreate(param)
    ---@type CS.UnityEngine.UI.LayoutElement
    self._layout = self:BindComponent("", typeof(CS.UnityEngine.UI.LayoutElement))
    self._p_btn_league_town = self:Button("p_btn_league_town", Delegate.GetOrCreate(self, self.OnClickBtnTown))
    self._p_btn_league_town_status = self:StatusRecordParent("p_btn_league_town")
    self._p_text_battle = self:Text("p_text_battle")
    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._trigger = self:AnimTrigger("")
end

function HUDAllianceVillage:OnShow(param)
    self:Refresh()
    self:SetupEvents(true)
end

function HUDAllianceVillage:OnHide(param)
    self:SetupEvents(false)
    self:RecycleAnim()
end

function HUDAllianceVillage:OnClose(param)
    self:SetupEvents(false)
end

function HUDAllianceVillage:Refresh()
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self._tickEndTime = nil
    local info, count = self:GetVillageWarInfo()
    if not info then
        self._layout.ignoreLayout = true
        self._p_btn_league_town:SetVisible(false)
        return
    end
    self._layout.ignoreLayout = false
    self._p_btn_league_town:SetVisible(true)
    if Utils.IsNotNull(self._child_reddot_default) then
        self._child_reddot_default:ShowNumRedDot(count)
    end
    if info.Status > wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
        self._p_btn_league_town_status:SetState(1)
    else
        self._p_btn_league_town_status:SetState(0)
        self._tickEndTime = info.StartTime
    end
    local duration = ConfigRefer.AllianceConsts:AllianceHudAnimDurationSec()

    self:PlayAnim((duration and duration > 0) and duration or 15)
end

function HUDAllianceVillage:OnClickBtnTown()
    local extraData = {}
    extraData[FPXSDKBIDefine.ExtraKey.town_icon_mediator.alliance_id] = ModuleRefer.AllianceModule:GetAllianceId()
    ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.town_icon_mediator, extraData)
    ---@type AllianceWarMediatorParameter
    local indexParameter = {}
    indexParameter.enterTabIndex = 2
    g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, indexParameter)
end

function HUDAllianceVillage:SetupEvents(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceVillageWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceVillageWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.PassWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceWarInfo.BehemothWar.VillageWar.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceWarInfoChanged))
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    end
end

---@param entity wds.Alliance
function HUDAllianceVillage:OnAllianceWarInfoChanged(entity, _)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    self._hasAnimPlayed = false
    self:Refresh()
end

---@param a wds.VillageAllianceWarInfo
---@param b wds.VillageAllianceWarInfo
function HUDAllianceVillage.SortWarInfo(a, b)
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
function HUDAllianceVillage:GetVillageWarInfo()
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return nil, 0
    end
    local villageWars = ModuleRefer.AllianceModule:GetMyAllianceVillageWars()
    local gateWars = ModuleRefer.AllianceModule:GetMyAllianceGateWars()
    local behemothWars = ModuleRefer.AllianceModule:GetMyAllianceBehemothCageWar()

    local _, villageCount = table.IsNullOrEmpty(villageWars)
    local _, gateCount = table.IsNullOrEmpty(gateWars)
    local _, behemothCageCount = table.IsNullOrEmpty(behemothWars)

    local count = villageCount + gateCount + behemothCageCount
    if count == 0 then
        return nil, 0
    end
    local infoArray = {}
    for _, v in pairs(villageWars) do
        table.insert(infoArray, v)
    end
    for _, v in pairs(gateWars) do
        table.insert(infoArray, v)
    end
    for _, v in pairs(behemothWars) do
        table.insert(infoArray, v)
    end
    table.sort(infoArray, HUDAllianceVillage.SortWarInfo)
    return infoArray[1], count
end

function HUDAllianceVillage:TickSec(dt)
    if not self._tickEndTime then
        return
    end
    local leftTime = self._tickEndTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if leftTime < 0 then
        self._tickEndTime = nil
        return
    end
    self._p_text_battle.text = TimeFormatter.SimpleFormatTime(leftTime)
end

---@param sec number
function HUDAllianceVillage:PlayAnim(sec)
    self:RecycleAnim()
    if self._hasAnimPlayed then
        return
    end
    self._trigger:FinishAll(CommonTriggerType.OnEnable)
    self._trigger:PlayAll(CommonTriggerType.Custom1)
    self._animTimer = TimerUtility.DelayExecute(function()
        self._trigger:FinishAll(CommonTriggerType.Custom1)
    end, sec)
    self._hasAnimPlayed = true
end

function HUDAllianceVillage:RecycleAnim()
    if self._animTimer then
        TimerUtility.StopAndRecycle(self._animTimer)
        self._animTimer = nil
    end
    self._trigger:FinishAll(CommonTriggerType.Custom1)
end

return HUDAllianceVillage
