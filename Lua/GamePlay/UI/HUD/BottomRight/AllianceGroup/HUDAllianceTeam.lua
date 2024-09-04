local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local DBEntityPath = require("DBEntityPath")
local UIMediatorNames = require("UIMediatorNames")
local CommonTriggerType = CS.FpAnimation.CommonTriggerType
local TimerUtility = require("TimerUtility")
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class HUDAllianceTeam:BaseUIComponent
---@field new fun():HUDAllianceTeam
---@field super BaseUIComponent
local HUDAllianceTeam = class('HUDAllianceTeam', BaseUIComponent)

function HUDAllianceTeam:ctor()
    HUDAllianceTeam.super.ctor(self)
    self._eventAdd = false
    self._allianceId = nil
    self._nextRefreshTime = nil
    self._animTimer = nil
    self._oldData = nil
    self._hasAnimPlayed = false
end

function HUDAllianceTeam:OnCreate(param)
    ---@type CS.UnityEngine.UI.LayoutElement
    self._layout = self:BindComponent("", typeof(CS.UnityEngine.UI.LayoutElement))
    self._p_btn_league_team = self:Button("p_btn_league_team", Delegate.GetOrCreate(self, self.OnClickBtnTeam))
    self._child_reddot_default = self:LuaObject("child_reddot_default")
    self._trigger = self:AnimTrigger("")
end

function HUDAllianceTeam:OnShow(param)
    self:Refresh()
    self:SetupEvents(true)
end

function HUDAllianceTeam:OnHide(param)
    self:RecycleAnim()
    self:SetupEvents(false)
end

function HUDAllianceTeam:OnClose(param)
    self:SetupEvents(false)
end

function HUDAllianceTeam:Refresh()
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self._nextRefreshTime = nil
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        self._layout.ignoreLayout = true
        self._p_btn_league_team:SetVisible(false)
        return false
    end
    local data = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not data then
        return false
    end
    local teamInfo = data.AllianceTeamInfos.Infos
    local count = 0
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for _, v in pairs(teamInfo) do
        if v.StartTime > nowTime then
            if not self._nextRefreshTime or v.StartTime < self._nextRefreshTime then
                self._nextRefreshTime = v.StartTime
            end
            count = count + 1
        end
    end
    self._layout.ignoreLayout = count <= 0
    self._p_btn_league_team:SetVisible(count > 0)
    if count > 0 then
        self._child_reddot_default:ShowNumRedDot(count)
        local duration = ConfigRefer.AllianceConsts:AllianceHudAnimDurationSec()
        self:PlayAnim((duration and duration > 0) and duration or 15)
    end
    return count > 0
end

function HUDAllianceTeam:SetupEvents(add)
    if not self._eventAdd and add then
        self._eventAdd = true
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceTeamInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceTeamInfoChanged))
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    elseif self._eventAdd and not add then
        self._eventAdd = false
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceTeamInfos.Infos.MsgPath, Delegate.GetOrCreate(self, self.OnAllianceTeamInfoChanged))
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TickSec))
    end
end

function HUDAllianceTeam:OnClickBtnTeam()
    ---@type AllianceWarMediatorParameter
    local indexParameter = {}
    indexParameter.enterTabIndex = 1
    g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, indexParameter)
end

---@param entity wds.Alliance
function HUDAllianceTeam:OnAllianceTeamInfoChanged(entity, changed)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    local keysMap = {}
    for _, v in pairs(changed.Remove or {}) do
        if not keysMap[v.Id] then
            keysMap[v.Id] = -1
        else
            keysMap[v.Id] = keysMap[v.Id] - 1
        end
    end
    for _, v in pairs(changed.Add or {}) do
        if not keysMap[v.Id] then
            keysMap[v.Id] = 1
        else
            keysMap[v.Id] = keysMap[v.Id] + 1
        end
    end
    local hasChange = false
    for _, count in pairs(keysMap) do
        if count and count ~= 0 then
            hasChange = true
            break
        end
    end
    hasChange = hasChange or not table.IsNullOrEmpty(changed.Change)
    if hasChange then
        self._hasAnimPlayed = false
        self:Refresh()
    end
end

function HUDAllianceTeam:TickSec(dt)
    if not self._nextRefreshTime then
        return
    end
    if self._nextRefreshTime < g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then
        self:Refresh()
    end
end

---@param sec number
function HUDAllianceTeam:PlayAnim(sec)
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

function HUDAllianceTeam:RecycleAnim()
    if self._animTimer then
        TimerUtility.StopAndRecycle(self._animTimer)
        self._animTimer = nil
    end
    self._trigger:FinishAll(CommonTriggerType.Custom1)
end

return HUDAllianceTeam