local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceLogCategory = require("AllianceLogCategory")
local DBEntityPath = require("DBEntityPath")
local TimeFormatter = require("TimeFormatter")
local AllianceLogType = require("AllianceLogType")
local ConfigRefer = require("ConfigRefer")
local ServiceDynamicDescHelper = require("ServiceDynamicDescHelper")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceManageGroupLog:BaseUIComponent
---@field new fun():AllianceManageGroupLog
---@field super BaseUIComponent
local AllianceManageGroupLog = class('AllianceManageGroupLog', BaseUIComponent)

function AllianceManageGroupLog:ctor()
    self._allianceId = nil
    ---@type table<number, wds.AllianceLog[]>
    self._logMap = {
        [AllianceLogCategory.EventLog] = {},
        [AllianceLogCategory.MemberLog] = {},
        [AllianceLogCategory.BattleLog] = {}
    }
    ---@type table<number, table[]>
    self._cellsData = {
        [AllianceLogCategory.EventLog] = {},
        [AllianceLogCategory.MemberLog] = {},
        [AllianceLogCategory.BattleLog] = {}
    }
    self._nowTab = nil
    self._emptyLineData = {}
end

function AllianceManageGroupLog:OnCreate(param)
    self._p_table_log = self:TableViewPro("p_table_log")
    self._p_text_event = self:Text("p_text_event", "alliance_setting_log1")
    self._p_btn_event = self:Button("p_btn_event", Delegate.GetOrCreate(self, self.OnClickTabEvent))
    self._p_text_member = self:Text("p_text_member", "alliance_setting_log2")
    self._p_btn_member = self:Button("p_btn_member", Delegate.GetOrCreate(self, self.OnClickTabMember))
    self._p_text_battle = self:Text("p_text_battle", "alliance_setting_log3")
    self._p_btn_battle = self:Button("p_btn_battle", Delegate.GetOrCreate(self, self.OnClickTabBattle))
    self._p_btn_event_Status = self:StatusRecordParent("p_btn_event")
    self._p_btn_member_Status = self:StatusRecordParent("p_btn_member")
    self._p_btn_battle_Status = self:StatusRecordParent("p_btn_battle")
    self._p_group_none = self:GameObject("p_group_none")
end

function AllianceManageGroupLog:GenerateLogData()
    local logs = ModuleRefer.AllianceModule:GetMyAllianceLogs()
    self:BuildCellData(AllianceLogCategory.EventLog, logs and logs.EventLogs)
    self:BuildCellData(AllianceLogCategory.MemberLog, logs and logs.MemberLogs)
    self:BuildCellData(AllianceLogCategory.BattleLog, logs and logs.BattleLogs)
end

---@param category number
---@param logs wds.AllianceLog[]
function AllianceManageGroupLog:BuildCellData(category, logs)
    local data = self._logMap[category]
    local cellData = self._cellsData[category]
    table.clear(data)
    table.clear(cellData)
    if not logs or #logs <= 0 then
        return
    end
    local startDataTime = TimeFormatter.ToDateTime(logs[1].Time.ServerSecond)
    self:DoBuildCellData(data, cellData, logs, 1, #logs, startDataTime)
end

function AllianceManageGroupLog:DoBuildCellData(data, cellData, logs, startIndex, endIndex, startDataTime)
    for i = startIndex, endIndex do
        local singleLog = logs[i]
        table.insert(data, singleLog)
        local logDateTime = TimeFormatter.ToDateTime(singleLog.Time.ServerSecond)
        if TimeFormatter.InSameDay(startDataTime, logDateTime) then
            ---@type AllianceManageGroupLogDateDetailCellData
            local DetailDateCellData = {}
            DetailDateCellData.dateTime = logDateTime
            DetailDateCellData.preBuildText = self:BuildLogString(singleLog)
            table.insert(cellData, 1, DetailDateCellData)
        else
            ---@type AllianceManageGroupLogDateCellData
            local DateCellData = {}
            DateCellData.dateTime = startDataTime
            table.insert(cellData, 1, DateCellData)
            table.insert(cellData, 1, {})
            startDataTime = logDateTime
            ---@type AllianceManageGroupLogDateDetailCellData
            local DetailDateCellData = {}
            DetailDateCellData.dateTime = logDateTime
            DetailDateCellData.preBuildText = self:BuildLogString(singleLog)
            table.insert(cellData, 1, DetailDateCellData)
        end
    end
    ---@type AllianceManageGroupLogDateCellData
    local DateCellData = {}
    DateCellData.dateTime = startDataTime
    table.insert(cellData, 1, DateCellData)
end

function AllianceManageGroupLog:OnShow(param)
    self._allianceId = ModuleRefer.AllianceModule:GetAllianceId()
    self:GenerateLogData()
    self:OnClickTabEvent()
    self:AddEvents()
end

function AllianceManageGroupLog:OnHide(param)
    self:RemoveEvents()
    self._p_table_log:Clear()
    table.clear(self._logMap[AllianceLogCategory.EventLog])
    table.clear(self._logMap[AllianceLogCategory.MemberLog])
    table.clear(self._logMap[AllianceLogCategory.BattleLog])
    table.clear(self._cellsData[AllianceLogCategory.EventLog])
    table.clear(self._cellsData[AllianceLogCategory.MemberLog])
    table.clear(self._cellsData[AllianceLogCategory.BattleLog])
    self._nowTab = nil
end

function AllianceManageGroupLog:OnClickTabEvent()
   self:ChangeTab(AllianceLogCategory.EventLog) 
end

function AllianceManageGroupLog:OnClickTabMember()
    self:ChangeTab(AllianceLogCategory.MemberLog)
end

function AllianceManageGroupLog:OnClickTabBattle()
    self:ChangeTab(AllianceLogCategory.BattleLog)
end

function AllianceManageGroupLog:ChangeTab(category)
    if self._nowTab == category then
        return
    end
    self._p_btn_event_Status:SetState(category == AllianceLogCategory.EventLog and 1 or 0)
    self._p_btn_member_Status:SetState(category == AllianceLogCategory.MemberLog and 1 or 0)
    self._p_btn_battle_Status:SetState(category == AllianceLogCategory.BattleLog and 1 or 0)
    self._nowTab = category
    
    self._p_table_log:Clear()
    local data = self._cellsData[category]
    for i = 1, #data do
        local cellData = data[i]
        if cellData.preBuildText then
            self._p_table_log:AppendData(cellData, 1)
        elseif cellData.dateTime then
            self._p_table_log:AppendData(cellData, 0)
        else
            self._p_table_log:AppendData(cellData, 2)
        end
    end
    self._p_group_none:SetVisible(#data <= 0)
end

function AllianceManageGroupLog:AddEvents()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLogs.EventLogs.MsgPath, Delegate.GetOrCreate(self, self.OnEventLogsChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLogs.MemberLogs.MsgPath, Delegate.GetOrCreate(self, self.OnMemberLogsChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceLogs.BattleLogs.MsgPath, Delegate.GetOrCreate(self, self.OnBattleLogsChanged))
end

function AllianceManageGroupLog:RemoveEvents()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLogs.EventLogs.MsgPath, Delegate.GetOrCreate(self, self.OnEventLogsChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLogs.MemberLogs.MsgPath, Delegate.GetOrCreate(self, self.OnMemberLogsChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceLogs.BattleLogs.MsgPath, Delegate.GetOrCreate(self, self.OnBattleLogsChanged))
end

---@param entity wds.Alliance
function AllianceManageGroupLog:OnEventLogsChanged(entity, changedData)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    local logs = ModuleRefer.AllianceModule:GetMyAllianceLogs()
    if not logs then
        return
    end
    if not logs.EventLogs then
        return
    end
    self:DoLogAppended(logs.EventLogs, AllianceLogCategory.EventLog)
end

---@param entity wds.Alliance
function AllianceManageGroupLog:OnMemberLogsChanged(entity, changedData)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    local logs = ModuleRefer.AllianceModule:GetMyAllianceLogs()
    if not logs then
        return
    end
    if not logs.MemberLogs then
        return
    end
    self:DoLogAppended(logs.MemberLogs, AllianceLogCategory.MemberLog)
end

---@param entity wds.Alliance
function AllianceManageGroupLog:OnBattleLogsChanged(entity, changedData)
    if not self._allianceId or self._allianceId ~= entity.ID then
        return
    end
    local logs = ModuleRefer.AllianceModule:GetMyAllianceLogs()
    if not logs then
        return
    end
    if not logs.BattleLogs then
        return
    end
    self:DoLogAppended(logs.BattleLogs, AllianceLogCategory.BattleLog)
end

---@param newFullLogList wds.AllianceLog[]
function AllianceManageGroupLog:DoLogAppended(newFullLogList, category)
    local tableData = self._logMap[category]
    local cellData = self._cellsData[category]
    local nowCount = #newFullLogList
    local start = nowCount - #tableData
    if start <= 0 then
        return
    end
    local originCount = #cellData
    local startDateTime = nil
    if originCount > 0 then
        originCount = originCount -1
        startDateTime = cellData[1].dateTime
        self._p_table_log:RemData(cellData[1])
        table.remove(cellData, 1)
    else
        startDateTime = TimeFormatter.ToDateTime(newFullLogList[start].Time.ServerSecond)
    end
    self:DoBuildCellData(tableData, cellData, newFullLogList, #tableData + 1, nowCount, startDateTime)
    if self._nowTab == category then
        local needAddStart = #cellData - originCount
        for i = needAddStart, 1, -1 do
            local singleData = cellData[i]
            if singleData.preBuildText then
                self._p_table_log:InsertData(0, singleData, 1)
            elseif singleData.dateTime then
                self._p_table_log:InsertData(0, singleData, 0)
            else
                self._p_table_log:InsertData(0, singleData, 2)
            end
        end
        if needAddStart > 0 then
            self._p_group_none:SetVisible(false)
        end
    end
end

---@param serverLogData wds.AllianceLog
function AllianceManageGroupLog:BuildLogString(serverLogData)
    local config = ModuleRefer.AllianceModule:GetAllianceLogConfig(serverLogData.Type)
    if not config then
        return ''--I18N.Get("*不支持的日志类型")
    end
    local langKey = config:KeyId()
    if config:HaveDynamicParams() then
        return ServiceDynamicDescHelper.ParseWithI18N(langKey, config:DynamicParamsDescLength(), config, config.DynamicParamsDesc
        , serverLogData.stringParams
        , serverLogData.params
        , {}
        , serverLogData.configParams)
    end
    if serverLogData.Type == AllianceLogType.Appointment then
        local rankConfig = ConfigRefer.AllianceRank:Find(serverLogData.params[1])
        return I18N.GetWithParams(langKey, serverLogData.stringParams[1], serverLogData.stringParams[2], rankConfig and I18N.Get(rankConfig:KeyId() or tostring(serverLogData.params[1])))
    end
    if serverLogData.Type == AllianceLogType.Build then
        return I18N.Temp().content_build_log
    end
    if serverLogData.Type == AllianceLogType.Demolish then
        return I18N.Temp().content_destroy_log
    end
    if serverLogData.Type == AllianceLogType.DirectJoin then
        return I18N.GetWithParams(langKey, serverLogData.stringParams[1])
    end
    if serverLogData.Type == AllianceLogType.VerifyJoin then
        return I18N.GetWithParams(langKey, serverLogData.stringParams[1], serverLogData.stringParams[2])
    end
    if serverLogData.Type == AllianceLogType.ActiveQuit then
        return I18N.GetWithParams(langKey, serverLogData.stringParams[1])
    end
    if serverLogData.Type == AllianceLogType.KickQuit then
        return I18N.GetWithParams(langKey, serverLogData.stringParams[1], serverLogData.stringParams[2])
    end
    if serverLogData.Type == AllianceLogType.ModifyTitle then
        local titleConfig = ConfigRefer.AllianceTitle:Find(serverLogData.params[1])
        if serverLogData.params[2] == 1 then
            return I18N.GetWithParams(langKey, serverLogData.stringParams[1], serverLogData.stringParams[2], I18N.Get(titleConfig:Name()))
        else -- 解除任命
            return I18N.GetWithParams(config:KeyIdExt(), serverLogData.stringParams[1], serverLogData.stringParams[2], I18N.Get(titleConfig:Name()))
        end
    end
    if serverLogData.Type == AllianceLogType.Occupy then
        local buildingConfig = ConfigRefer.FixedMapBuilding:Find(serverLogData.params[1])
        return I18N.GetWithParams(langKey, buildingConfig and I18N.Get(buildingConfig:Name()) or serverLogData.params[1], serverLogData.params[2], serverLogData.params[3])
    end
    if serverLogData.Type == AllianceLogType.Occupied then
        local buildingConfig = ConfigRefer.FixedMapBuilding:Find(serverLogData.params[1])
        return I18N.GetWithParams(langKey, ("[%s]%s"):format(serverLogData.stringParams[1], serverLogData.stringParams[2]) ,buildingConfig and I18N.Get(buildingConfig:Name()) or serverLogData.params[1], serverLogData.params[2], serverLogData.params[3])
    end
    if serverLogData.Type == AllianceLogType.SwitchLeaderEnd then
        return I18N.GetWithParams(langKey, serverLogData.stringParams[1], serverLogData.stringParams[2])
    end
    if serverLogData.Type == AllianceLogType.PassiveSwitchLeader then
        return I18N.GetWithParams(langKey, serverLogData.stringParams[1], serverLogData.stringParams[2])
    end
    if serverLogData.Type == AllianceLogType.ImpeachSuccess then
        return I18N.GetWithParams(langKey, serverLogData.stringParams[1], serverLogData.stringParams[2], serverLogData.stringParams[2])
    end
    if serverLogData.Type == AllianceLogType.ImpeachFailed then
        return I18N.GetWithParams(langKey, serverLogData.stringParams[1], serverLogData.stringParams[2])
    end
    if serverLogData.Type == AllianceLogType.OpenExpedition then
        local config = ConfigRefer.WorldExpeditionTemplate:Find(serverLogData.params[1])
        local remainT = serverLogData.params[4] - serverLogData.Time.Seconds
        local time = TimeFormatter.SimpleFormatTime(remainT)
        return I18N.GetWithParams(langKey, serverLogData.stringParams[1],I18N.Get(config:Name()),serverLogData.params[2],serverLogData.params[3],time)
    end
    if serverLogData.Type == AllianceLogType.CloseExpedition then
        local config = ConfigRefer.WorldExpeditionTemplate:Find(serverLogData.params[1])
        return I18N.GetWithParams(langKey, I18N.Get(config:Name()))
    end
    if serverLogData.Type == AllianceLogType.AutoOpenExpedition then
        local config = ConfigRefer.WorldExpeditionTemplate:Find(serverLogData.params[1])
        local remainT
        local time
        if serverLogData.params[2] then
            remainT = serverLogData.params[2] - serverLogData.Time.Seconds
            time = TimeFormatter.SimpleFormatTime(remainT)
        end
        
        return I18N.GetWithParams(langKey, I18N.Get(config:Name()),time)
    end
    if serverLogData.Type == AllianceLogType.SettleExpedition then
        return I18N.GetWithParams(langKey)
    end
    return ''--I18N.Get("*")
end

return AllianceManageGroupLog