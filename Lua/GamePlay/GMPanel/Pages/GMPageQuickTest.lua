local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local TimeFormatter = require('TimeFormatter')  

local JoinTeamTrusteeshipParameter = require('JoinTeamTrusteeshipParameter')
local LeaveTeamTrusteeshipParameter = require('LeaveTeamTrusteeshipParameter')

---@class GMPageQuickTest:GMPage
local cls = class('GMPageQuickTest', GMPage)

function cls:ctor()
    self.taskIds = '10101,...,10107,10201,...,10211,20101,...,20114,20201,...,20209,30101,...,30308'
    self.presetIndex = '1'
    self.scroPos = CS.UnityEngine.Vector2.zero
end

function cls:OnShow()
    if self.panel._serverCmdProvider then
        if self.panel._serverCmdProvider:NeedRefresh() then
            self.panel._serverCmdProvider:RefreshCmdList()
        end
    end
end

function cls:OnGUI()
    self.scroPos = GUILayout.BeginScrollView(self.scroPos)   
    GUILayout.Label('任务相关')

    GUILayout.BeginHorizontal()
    GUILayout.Label("配置TaskID:", GUILayout.shrinkWidth)
    self.taskIds = GUILayout.TextField(self.taskIds)
    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    if GUILayout.Button("完成配置的任务") then
        self:SendTasksOptCmd(4)
    end 
    if GUILayout.Button("领取配置的任务") then
        self:SendTasksOptCmd(5)
    end 
    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    if GUILayout.Button("完成所有主线任务") then
        self:SendAllChapterTaskOptCmd(4)
    end 
    if GUILayout.Button("领取所有主线任务") then
        self:SendAllChapterTaskOptCmd(5)
    end 
    GUILayout.EndHorizontal()
     
    GUILayout.Label('SE相关')
    GUILayout.BeginHorizontal()
	if (GUILayout.Button("直接完成SE关卡")) then
		self.panel:SendGMCmd("finishlevel", 0)
		self.panel:PanelShow(false)
	end
    GUILayout.EndHorizontal()

    GUILayout.Label('Gve相关')
    GUILayout.BeginHorizontal()

    if (GUILayout.Button("添加1K兵")) then
		self.panel:SendGMCmd("addsoldier", 1,1000)		
	end

	if (GUILayout.Button("开启联盟战役")) then
		self.panel:SendGMCmd("open_alliance_battle", 1,3600)		
	end
    if (GUILayout.Button("关闭联盟战役")) then
		self.panel:SendGMCmd("close_alliance_battle", 1)		
	end
    GUILayout.EndHorizontal()

    GUILayout.Label("测试常用功能")
    if (GUILayout.Button("解锁全系统获得所有道具收复所有区域重启")) then
        if self.panel and self.panel._serverCmdProvider and self.panel._serverCmdProvider:IsReady()then
            ---@type GMServerCmdPair
            -- self.panel._serverCmdProvider:SendCmd({cmd = "addallitems"}, {"1"})
            self.panel._serverCmdProvider:SendCmd({cmd = "open_all_system"}, {})
            self.panel._serverCmdProvider:SendCmd({cmd = "recover_all_zone"}, {})
            g_Game:RestartGame()
        end
    end
    if GUILayout.Button("满级基地") then
        if self.panel and self.panel._serverCmdProvider and self.panel._serverCmdProvider:IsReady()then
            self.panel._serverCmdProvider:SendCmd({cmd = "upgrade_furniture"}, {"1000101", "30"})
        end
    end
    if GUILayout.Button("升级四件套") then
        if self.panel and self.panel._serverCmdProvider and self.panel._serverCmdProvider:IsReady()then
            self.panel._serverCmdProvider:SendCmd({cmd = "additem"}, {"61001", "99999"})
            self.panel._serverCmdProvider:SendCmd({cmd = "additem"}, {"62001", "99999"})
            self.panel._serverCmdProvider:SendCmd({cmd = "additem"}, {"60001", "99999"})
            self.panel._serverCmdProvider:SendCmd({cmd = "additem"}, {"2", "99999"})
        end
    end

    if ModuleRefer.AllianceModule:IsInAlliance() then
        GUILayout.Label('组队挑战')
        self:OnGUI_AllianceTeamBattle()        
    end
    GUILayout.EndScrollView()
end

function cls:SendTasksOptCmd(opCode)
    if string.IsNullOrEmpty(self.taskIds) then return end
    local rawIds = string.split(self.taskIds,',')
    local ids = {}      
    for i = 1, #rawIds do
        local tmpNumber = tonumber(rawIds[i])
        if tmpNumber then
            table.insert(ids,tmpNumber)        
        elseif rawIds[i] == '...' then
            local beginId = ids[#ids]
            local endId = tonumber(rawIds[i+1])
            if endId and endId > beginId then                               
                for j = beginId+1, endId - 1 do
                    table.insert(ids,j)
                end                
            end            
        end
    end

    for index, taskId in ipairs(ids) do
        self.panel:SendGMCmd('task_op', opCode,taskId)
    end  
   
end

function cls:SendAllChapterTaskOptCmd(opCode)
    local ids = {}      
    local TaskType = require('TaskType')
    for key, value in ConfigRefer.Task:ipairs() do
        local taskProp = value:Property()
        if taskProp and taskProp:TaskType() == TaskType.MainChapter then
            table.insert(ids,value:Id())
        end
    end
    for index, taskId in ipairs(ids) do
        self.panel:SendGMCmd('task_op', opCode,taskId)
    end 
end

function cls:OnGUI_AllianceTeamBattle()
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceData 
        or not allianceData.AllianceTeamInfos 
        or not allianceData.AllianceTeamInfos.Infos 
        or not allianceData.AllianceTeamInfos.Infos 
        or allianceData.AllianceTeamInfos.Infos:Count() < 1 
    then
        return
    end

    GUILayout.Label('Preset列表:')
    local troopInfos = ModuleRefer.SlgModule:GetMyTroops()
    for index, info in pairs(troopInfos) do
        GUILayout.BeginHorizontal()
        GUILayout.Label('Preset序号:' .. tostring(index))
        if not info.preset or info.locked then
            GUILayout.Label('锁定', GUILayout.Width(80))
        else
           if not info.preset.TrusteeshipInfo or info.preset.TrusteeshipInfo.TrusteeshipStatus == wds.TrusteeshipStatus.TrusteeshipStatus_None then
                GUILayout.Label('未托管', GUILayout.Width(80))
           else
                GUILayout.Label('TeamID:' .. info.preset.TrusteeshipInfo.TeamId, GUILayout.Width(80))
                if GUILayout.Button('取消托管', GUILayout.Width(80)) then
                    ModuleRefer.SlgModule:LeaveAllianceTeam(index)
                end
           end
        end
        GUILayout.EndHorizontal()
    end


    GUILayout.BeginHorizontal()
    GUILayout.Label('要加入组队的Preset序号:')
    self.presetIndex = GUILayout.TextField(self.presetIndex)
    GUILayout.EndHorizontal()
    GUILayout.Label('公会组队列表:')
    for id, info in pairs(allianceData.AllianceTeamInfos.Infos) do
        GUILayout.BeginHorizontal()
        if GUILayout.Button("加入队伍", GUILayout.Width(100)) then
            self:JoinAllianceTeam(id,tonumber(self.presetIndex))
        end
        GUILayout.Label('Id:', GUILayout.Width(80))
        GUILayout.Label(tostring(id))
        GUILayout.Label('TroopCount:', GUILayout.Width(80))
        GUILayout.Label(tostring(info.Members:Count()))
        GUILayout.EndHorizontal()

        GUILayout.BeginHorizontal()
        GUILayout.Label('      Create Time')
        GUILayout.Label( TimeFormatter.ToDateTime(info.CreateTime):ToString())
        GUILayout.EndHorizontal()

        GUILayout.BeginHorizontal()
        GUILayout.Label('      Start Time')
        GUILayout.Label( TimeFormatter.ToDateTime(info.StartTime):ToString())
        GUILayout.EndHorizontal()
       
    end

end

function cls:JoinAllianceTeam(teamID,presetIndex)
   ModuleRefer.SlgModule:JoinAllianceTeam(teamID,presetIndex)
end




return cls
