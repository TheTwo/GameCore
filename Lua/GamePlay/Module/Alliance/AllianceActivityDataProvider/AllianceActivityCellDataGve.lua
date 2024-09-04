local AllianceActivityDataProviderDefine = require("AllianceActivityDataProviderDefine")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require("UIMediatorNames")

local AllianceActivityCellData = require("AllianceActivityCellData")

---@class AllianceActivityCellDataGve:AllianceActivityCellData
---@field super AllianceActivityCellData
---@field new fun(id:number, battleData:wds.AllianceActivityBattleInfo)
local AllianceActivityCellDataGve = class("AllianceActivityCellDataGve", AllianceActivityCellData)

---@param id number
---@param battleData wds.AllianceActivityBattleInfo
function AllianceActivityCellDataGve:ctor(id, battleData)
    AllianceActivityCellDataGve.super.ctor(self, id)
    ---@type wds.AllianceActivityBattleInfo
    self._battleData = battleData
    self._cell = nil
end

function AllianceActivityCellDataGve.GetSoureType()
    return AllianceActivityDataProviderDefine.SourceType.AllianceGve
end

---@param cell AllianceWarActivityCell
function AllianceActivityCellDataGve:OnCellEnter(cell)
    self._cell = cell
    cell:ResetCell()
    -- local behemothDevice = ModuleRefer.AllianceModule:getde
    local config = ConfigRefer.AllianceBattle:Find(self._battleData.CfgId)
    g_Game.SpriteManager:LoadSprite(ArtResourceUtils.GetUIItem(config:BossIcon()), cell._p_icon_event)
    local selfFacebookId = ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID
    local isMyActivity = self._battleData.Members and self._battleData.Members[selfFacebookId] or false
    cell._p_my:SetVisible(isMyActivity)
    if isMyActivity then
        cell._p_text_my_status.text = I18N.Get("alliance_behemoth_challenge_state13")
    end
    g_Game.SpriteManager:LoadSprite("sp_behemoth_icon_all_behemoth", cell._p_icon_event_type)
    cell._p_text_event_name.text = I18N.Get(config:LangKey())
    cell._p_text_event_desc.text = I18N.Get(config:LangDesc())
    if self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then
        cell._p_progress_event:SetVisible(true)
        cell._p_btn_goto:SetVisible(true)
        cell._p_text_event_status_desc_2:SetVisible(true)
    elseif self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated then
        local startTime,_ = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(self._battleData.ChosenActivity)
        cell._p_text_event_status_desc_1:SetVisible(true)
        cell._p_text_event_status_desc_1.text = I18N.GetWithParams("alliance_behemoth_fighting11", TimeFormatter.TimeToDateTimeString(startTime.ServerSecond))
        cell._p_progress_event:SetVisible(true)
        cell._p_btn_goto:SetVisible(true)
        cell._p_text_event_status_desc_2:SetVisible(true)
    elseif self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusWaiting then
        cell._p_progress_event:SetVisible(true)
        cell._p_btn_goto:SetVisible(true)
        cell._p_text_event_status_desc_2:SetVisible(true)
    end
    cell._p_text_event_status_desc_2.text = I18N.GetWithParams("alliance_assemble_behemoth_application", table.nums(self._battleData.Members))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
    self:SecTick(0)
end

---@param cell AllianceWarActivityCell
function AllianceActivityCellDataGve:OnCellExit(cell)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
end

function AllianceActivityCellDataGve:OnClickBtnPosition()
end

function AllianceActivityCellDataGve:OnClickBtnGoto()
    if not self._battleData then return end
    -----@type ActivityCenterOpenParam
    local tabId = ConfigRefer.AllianceConsts:BehemothActiviyChallengeTab()
    ModuleRefer.ActivityCenterModule:GotoActivity(tabId)
end

function AllianceActivityCellDataGve:SecTick(dt)
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then
        local battleEndTime = self._battleData.CloseTime.ServerSecond
        local battleStartTime = self._battleData.StartBattleTime.ServerSecond
        local leftTime = math.max(0, battleEndTime - nowTime)
        self._cell._p_text_event_progress.text = I18N.Get("alliance_behemoth_title_copyscenetime") .. TimeFormatter.SimpleFormatTime(leftTime)
        if leftTime <= 0 then
            self._cell._p_progress_event.value = 1
        else
            self._cell._p_progress_event.value = math.inverseLerp(battleStartTime, battleEndTime, nowTime)
        end
    elseif self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusWaiting then
        local waitEndTime = self._battleData.StartBattleTime.ServerSecond
        local waitStartTime = self._battleData.OpenTime.ServerSecond
        local leftTime = math.max(0, waitEndTime - nowTime)
        self._cell._p_text_event_progress.text = I18N.Get("alliance_behemoth_title_readyTiem") .. TimeFormatter.SimpleFormatTime(leftTime)
        if leftTime <= 0 then
            self._cell._p_progress_event.value = 1
        else
            self._cell._p_progress_event.value = math.inverseLerp(waitStartTime, waitEndTime, nowTime)
        end
    elseif self._battleData.Status == wds.AllianceActivityBattleStatus.AllianceBattleStatusActivated then
        local startTime,endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(self._battleData.ChosenActivity)
        local leftTime = math.max(0, endTime.ServerSecond - nowTime)
        self._cell._p_text_event_progress.text = I18N.Get("alliance_assemble_behemoth_time") .. TimeFormatter.SimpleFormatTimeWithDay(leftTime)
        if leftTime <= 0 then
            self._cell._p_progress_event.value = 1
        else
            self._cell._p_progress_event.value = math.inverseLerp(startTime.ServerSecond, endTime.ServerSecond, nowTime)
        end
    end
end

return AllianceActivityCellDataGve