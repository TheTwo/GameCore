local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local AllianceTechnologyType = require("AllianceTechnologyType")
local DBEntityPath = require("DBEntityPath")
local OnChangeHelper = require("OnChangeHelper")
local AllianceAttr = require("AllianceAttr")
local UIMediatorNames = require('UIMediatorNames')
local DonateAllianceParameter = require("DonateAllianceParameter")
local UpgradeAllianceTechParameter = require("UpgradeAllianceTechParameter")
local MarkAllianceTechParameter = require("MarkAllianceTechParameter")

local BaseModule = require("BaseModule")

---@alias AllianceTechGroup AllianceTechnologyConfigCell[]

---@class AllianceTechGroupChain
---@field id number
---@field group AllianceTechGroup
---@field pre table<number, AllianceTechGroupChain>
---@field next table<number, AllianceTechGroupChain>
---@field columnDepth number
---@field groupType number @AllianceTechnologyType

---@class AllianceTechModule:BaseModule
---@field new fun():AllianceTechModule
---@field super BaseModule
local AllianceTechModule = class('AllianceTechModule', BaseModule)

function AllianceTechModule:ctor()
    BaseModule.ctor(self)
    self._allianceTechGroup = {}
    ---@type table<number, AllianceTechGroup>
    self._allianceTechGroupId2Group = {}
    ---@type table<number, AllianceTechGroup>
    self._allianceTechId2Group = {}
    ---@type table<number, AllianceTechGroupChain>
    self._allianceTechGroup2ChainNode = {}
    ---@type table<number, table<number, AllianceTechGroupChain[]>>
    self._allianceType2TechChain = {}
    ---@type table<number, number>
    self._allianceGroupId2Type = {}
    self._researchIdleStatus = true
end

function AllianceTechModule:OnRegister()
    self:PreCacheTechGroup()
    self:RefreshResearchIdleStatus()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceTechnology.TechnologyData.MsgPath, Delegate.GetOrCreate(self, self.OnTechnologyDataChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceTechnology.MarkTechnology.MsgPath, Delegate.GetOrCreate(self, self.OnRecommendTechnologyChanged))
end

function AllianceTechModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceTechnology.TechnologyData.MsgPath, Delegate.GetOrCreate(self, self.OnTechnologyDataChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceTechnology.MarkTechnology.MsgPath, Delegate.GetOrCreate(self, self.OnTechnologyDataChanged))
end

---@param lockTrans CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param groupId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)|nil
function AllianceTechModule:SendStartResearchTech(lockTrans, groupId, callback)
    local sendCmd = UpgradeAllianceTechParameter.new()
    sendCmd.args.TechGroupId = groupId
    sendCmd:SendOnceCallback(lockTrans, nil, nil, callback)
end

---@param lockTrans CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param groupId number
---@param useCurrency boolean
---@param all boolean
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)|nil
---@param gainPoints number
function AllianceTechModule:DonateAllianceTech(lockTrans, groupId, useCurrency, all, callback, gainPoints)
    local sendCmd = DonateAllianceParameter.new()
    sendCmd.args.TechGroupId = groupId
    sendCmd.args.UseCurrency = useCurrency
	sendCmd.args.DonateAll = all
    sendCmd:SendOnceCallback(lockTrans, gainPoints, nil, callback)
end

---@param lockTrans CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param groupId number
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)|nil
function AllianceTechModule:SetRecommendTech(lockTrans, groupId, callback)
    local sendCmd = MarkAllianceTechParameter.new()
    sendCmd.args.TechGroupId = groupId
    sendCmd:SendOnceCallback(lockTrans, nil, nil, callback)
end

---@param entity wds.Alliance
function AllianceTechModule:OnTechnologyDataChanged(entity, changedData)
    if entity.ID ~= ModuleRefer.AllianceModule:GetAllianceId() then
        return
    end
    local add, remove, change = OnChangeHelper.GenerateMapFieldChangeMap(changedData, wds.AllianceTechnologyNode)
    local groupIds = {}
    if add then
        for i, v in pairs(add) do
            groupIds[i] = true
        end
    end
    if remove then
        for i, v in pairs(remove) do
            groupIds[i] = true
        end
    end
    if change then
        for i, v in pairs(change) do
            groupIds[i] = true
        end
    end
    local lastResearchIdle = self._researchIdleStatus
    self:RefreshResearchIdleStatus()
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_TECH_NODE_UPDATED, groupIds)
    if lastResearchIdle ~= self._researchIdleStatus then
        g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_TECH_RESEARCH_IDLE_STATUS_UPDATED, lastResearchIdle, self._researchIdleStatus)
    end
end

function AllianceTechModule:GetResearchIdleStatus()
    return self._researchIdleStatus
end

function AllianceTechModule:RefreshResearchIdleStatus()
    local status = true
    local data = self:GetMyTechData()
    if data then
        for i, v in pairs(data.TechnologyData) do
            if v.Status == wds.AllianceTechnologyNodeStatus.AlisTechStatusInStudy then
                status = false
                break
            end
        end
    end
    self._researchIdleStatus = status
end

---@param entity wds.Alliance
function AllianceTechModule:OnRecommendTechnologyChanged(entity, changedData)
    if entity.ID ~= ModuleRefer.AllianceModule:GetAllianceId() then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.ALLIANCE_TECH_RECOMMEND_UPDATED)
end

---@return CurrencyInfoConfigCell,number
function AllianceTechModule:GetCurrentDonateCost()
    local playerAlliance = ModuleRefer.PlayerModule:GetPlayer().PlayerAlliance
    local currencyDonateStartTimes = playerAlliance.CurrencyDonateTimes + 1
    local currencyTypeLength = ConfigRefer.AllianceConsts:AllianceCurrencyDonateTypeLength()
    local currencyCountLength = ConfigRefer.AllianceConsts:AllianceCurrencyDonateCountLength()
    if currencyTypeLength ~= currencyCountLength then
        g_Logger.Error("AllianceCurrencyDonateTypeLength ~= AllianceCurrencyDonateCountLength")
    end
    if currencyTypeLength <= 0 then
        return nil
    end
    currencyDonateStartTimes = math.clamp(currencyDonateStartTimes, 1, currencyTypeLength)
    local retType = ConfigRefer.AllianceConsts:AllianceCurrencyDonateType(currencyDonateStartTimes)
    local retCount = ConfigRefer.AllianceConsts:AllianceCurrencyDonateCount(currencyDonateStartTimes)
    return ConfigRefer.CurrencyInfo:Find(retType), retCount
end

---@return table<number, AllianceTechGroupChain[]>
function AllianceTechModule:GetTechChainByType(type)
    return self._allianceType2TechChain[type]
end

---@return AllianceTechGroup
function AllianceTechModule:GetTechGroupByGroupId(groupId)
    return self._allianceTechGroupId2Group[groupId]
end

---@return number @AllianceTechnologyType
function AllianceTechModule:GetTechTypeByGroupId(groupId)
    return self._allianceGroupId2Type[groupId]
end

function AllianceTechModule:GetMyTechData()
    local myAllianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not myAllianceData then
        return nil
    end
    return myAllianceData and myAllianceData.AllianceTechnology or nil
end

function AllianceTechModule:GetRecommendTech()
    local myAllianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not myAllianceData then
        return nil
    end
    return myAllianceData.AllianceTechnology.MarkTechnology
end

---@param leftGroup number @groupId
---@param rightGroup number @groupId
---@return boolean
function AllianceTechModule:IsLeftUnlockLinkToRight(leftGroup, rightGroup)
    if not leftGroup or not rightGroup then
        return false
    end
    local leftChain = self._allianceTechGroup2ChainNode[leftGroup]
    local rightChain = self._allianceTechGroup2ChainNode[rightGroup]
    if not leftChain or not rightChain then
        return false
    end
    if not leftChain.next[rightChain.id] then
        return false
    end
    local leftData = self:GetTechGroupStatus(leftGroup)
    local rightData = self:GetTechGroupStatus(rightGroup)
    if not leftData or not rightData then
        return false
    end
    return leftData.Level > 0 and rightData.Level > 0
end

---@param techGroupNodeData wds.AllianceTechnologyNode
function AllianceTechModule:IsReadyToNextLevel(techGroupNodeData)
    if not techGroupNodeData or not techGroupNodeData.UnlockNextLevel or techGroupNodeData.Status == wds.AllianceTechnologyNodeStatus.AlisTechStatusInStudy then
        return false
    end
    local group = self._allianceTechGroupId2Group[techGroupNodeData.GroupId]
    if not group then
        return false
    end
    local nextLv = group[techGroupNodeData.Level + 1]
    if not nextLv then
        return false
    end
    if nextLv:RequireTechPoint() > techGroupNodeData.Point then
        return false
    end
    local currency = ConfigRefer.AllianceCurrency:Find(nextLv:RequireAllianceCurrency())
    if currency and nextLv:RequireAllianceCurrencyCount() > 0 then
        local needCount = ModuleRefer.AllianceTechModule:CalculateTechRequireAllianceCurrencyCount(nextLv)
        if needCount > ModuleRefer.AllianceModule:GetAllianceCurrencyById(currency:Id()) then
            return false
        end
    end
    return true
end

---@param a AllianceTechnologyConfigCell
---@param b AllianceTechnologyConfigCell
function AllianceTechModule.SortForTechGroup(a, b)
    return a:Level() < b:Level()
end

---@param groupId number
---@param group AllianceTechGroup
---@param chainNodeMap table<number, AllianceTechGroupChain>
---@param chainStart AllianceTechGroupChain[]
---@param groupMap table<number, AllianceTechGroup>
---@param fromNode AllianceTechGroupChain
function AllianceTechModule.DoBuildReverseChain(groupId, group, chainNodeMap, chainStart, groupMap, fromNode)
    local stack = {}
    table.insert(stack, {groupId, group, fromNode})
    while #stack > 0 do
        local params = table.remove(stack)
        local currentGroupId = params[1]
        local currentGroup = params[2]
        local currentFromNode = params[3]

        local groupStart = currentGroup[1]
        local chainNode = chainNodeMap[currentGroupId]
        if not chainNode then
            chainNode = {}
            chainNode.id = currentGroupId
            chainNode.group = currentGroup
            chainNode.next = {}
            chainNode.pre = {}
            chainNodeMap[currentGroupId] = chainNode
            local preGroupCount = groupStart:PreNodesLength()
            if preGroupCount <= 0 then
                table.insert(chainStart, chainNode)
            else
                for i = 1, preGroupCount do
                    local preGroupId = groupStart:PreNodes(i)
                    if currentGroupId ~= preGroupId then
                        if groupMap[preGroupId] then
                            table.insert(stack, {preGroupId, groupMap[preGroupId], chainNode})
                        else
                            g_Logger.Error("preGroupId:%s has none groupMap! -> from currentGroupId:%s", preGroupId, currentGroupId)
                        end
                    end
                end
            end
        end
        if currentFromNode and currentFromNode.id ~= currentGroupId then
            chainNode.next[currentFromNode.id] = currentFromNode
            currentFromNode.pre[currentGroupId] = chainNode
        end
    end
end

---@param chainNode AllianceTechGroupChain
---@param depth number
function AllianceTechModule.DoSetupChainNodeColumnDepth(chainNode, groupId2Type)
    ---@type AllianceTechGroupChain[]
    local stack = {}
    table.insert(stack, chainNode)
    while #stack > 0 do
        ---@type AllianceTechGroupChain
        local currentChainNode = table.remove(stack)
        currentChainNode.columnDepth = currentChainNode.group[1]:LayerNumber()
        currentChainNode.groupType = groupId2Type[currentChainNode.id]
        for _, v in pairs(currentChainNode.next) do
            table.insert(stack, v)
        end
    end
end

---@param chainNode AllianceTechGroupChain
---@param depthMap table<number, AllianceTechGroupChain[]>
function AllianceTechModule.DoSetupChainNodeColumnDepthMap(chainNode, depthMap)
    local stack = {}
    table.insert(stack, chainNode)
    while #stack > 0 do
        ---@type AllianceTechGroupChain
        local currentChainNode = table.remove(stack)
        local depth = currentChainNode.columnDepth
        local stageChainNodes = depthMap[depth]
        if not stageChainNodes then
            stageChainNodes = {}
            depthMap[depth] = stageChainNodes
            table.insert(stageChainNodes, currentChainNode)
        else
            local has = false
            for _, v in pairs(stageChainNodes) do
                if v.id == currentChainNode.id then
                    has = true
                    break
                end
            end
            if not has then
                table.insert(stageChainNodes, currentChainNode)
            end
        end
        for _, v in pairs(currentChainNode.next) do
            table.insert(stack, v)
        end
    end
end

function AllianceTechModule:PreCacheTechGroup()
    table.clear(self._allianceTechGroup)
    table.clear(self._allianceType2TechChain)
    table.clear(self._allianceTechGroup2ChainNode)
    table.clear(self._allianceGroupId2Type)
    table.clear(self._allianceTechGroupId2Group)
    local TechConfig = ConfigRefer.AllianceTechnology
    for _, techConfig in TechConfig:ipairs() do
        local groupId = techConfig:Group()
        local group = self._allianceTechGroupId2Group[groupId]
        if not group then
            group = {}
            self._allianceTechGroupId2Group[groupId] = group
        end
        table.insert(group, techConfig)
    end
    for _, v in pairs(self._allianceTechGroupId2Group) do
        table.sort(v, AllianceTechModule.SortForTechGroup)
    end
    for groupId, v in pairs(self._allianceTechGroupId2Group) do
        self._allianceGroupId2Type[groupId] = v[1]:Type()
    end
    ---@type table<number, AllianceTechGroupChain>
    local chainNodeMap = {}
    ---@type AllianceTechGroupChain[]
    local chainStart = {}
    ---@type table<number, AllianceTechGroup>
    local mayNotInChainNode = {}
    for groupId, v in pairs(self._allianceTechGroupId2Group) do
        if v[1]:PreNodesLength() > 0 then
            AllianceTechModule.DoBuildReverseChain(groupId, v, chainNodeMap, chainStart, self._allianceTechGroupId2Group, nil)
        else
            mayNotInChainNode[groupId] = v
        end
    end
    for groupId, v in pairs(mayNotInChainNode) do
        local inChainNode = chainNodeMap[groupId]
        if not inChainNode then
            ---@type AllianceTechGroupChain
            local singleNode = {}
            singleNode.id = groupId
            singleNode.group = v
            singleNode.pre = {}
            singleNode.next = {}
            chainNodeMap[groupId] = singleNode
            table.insert(chainStart, singleNode)
            -- g_Logger.Error("联盟科技 孤立节点:%s", groupId)
        end
    end
    for _, v in pairs(chainStart) do
        AllianceTechModule.DoSetupChainNodeColumnDepth(v, self._allianceGroupId2Type)
        local chainStartNodeType = v.groupType
        local depthMap = self._allianceType2TechChain[chainStartNodeType]
        if not depthMap then
            depthMap = {}
            self._allianceType2TechChain[chainStartNodeType] = depthMap
        end
        AllianceTechModule.DoSetupChainNodeColumnDepthMap(v, depthMap)
    end
    for _, depthMap in pairs(self._allianceType2TechChain) do
        for depth, chainNodes in pairs(depthMap) do
            if #chainNodes > 4 then
                g_Logger.Error("LayerNumber:%s 存在超过4个节点, groupId:%s", depth, chainNodes[1].id)
            end
            table.sort(chainNodes, function(a, b)
                return a.id < b.id
            end)
            for _, chainNode in pairs(chainNodes) do
                self._allianceTechGroup2ChainNode[chainNode.id] = chainNode
            end
        end
    end
end

---@return wds.AllianceTechnologyNode
function AllianceTechModule:GetTechGroupStatus(groupId)
    local allianceData = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not allianceData or not allianceData.AllianceTechnology or not allianceData.AllianceTechnology.TechnologyData then
        return nil
    end
    return allianceData.AllianceTechnology.TechnologyData[groupId]
end

---@param config FlexibleMapBuildingConfigCell
---@return boolean
function AllianceTechModule:IsBuildingTechSatisfy(config)
    if not config then
        return true
    end
    local needTechConfigCount = config:UnlockTechLength()
    if needTechConfigCount <= 0 then
        return true
    end
    for i = 1, needTechConfigCount do
        local tech = config:UnlockTech(i)

        local techConfig = ConfigRefer.AllianceTechnology:Find(tech)
        if not self:IsTechSatisfy(techConfig) then
            return false
        end
    end
    return true
end

---@param config FlexibleMapBuildingConfigCell
---@return boolean
function AllianceTechModule:IsBuildingAllianceCenterSatisfy(config)
    if not config then
        return true
    end
    if not config:AllianceCenterTerritoryOnly() then
        return true
    end
    return ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillageId() ~= nil
end

function AllianceTechModule:IsTechSatisfy(techConfig)
    if not techConfig then
        return false
    end
    local lv = techConfig:Level()
    if lv > 0 then
        local group = techConfig:Group()
        local groupStatus = self:GetTechGroupStatus(group)
        if not groupStatus or groupStatus.Level < lv then
            return false
        end
    end
    return true
end

---@param techLvConfig AllianceTechnologyConfigCell
function AllianceTechModule:CalculateTechCostTime(techLvConfig)
    local originCostTime = techLvConfig:CostSecond()
    local techData = self:GetMyTechData()
    local multi = 0
    local point = 0
    if techData and techData.AttrDisplay then
        multi = techData.AttrDisplay[AllianceAttr.Tech_Upgrade_Time_Cost_multi] or 0
        point = techData.AttrDisplay[AllianceAttr.Tech_Upgrade_Time_Cost_point] or 0
    end
    return math.ceil(originCostTime * (1 + multi / 10000) + point)
end

---@param techLvConfig AllianceTechnologyConfigCell
function AllianceTechModule:CalculateTechRequireAllianceCurrencyCount(techLvConfig)
    local originCostCount = techLvConfig:RequireAllianceCurrencyCount()
    local techData = self:GetMyTechData()
    local multi = 0
    local point = 0
    if techData and techData.AttrDisplay then
        multi = techData.AttrDisplay[AllianceAttr.Tech_Upgrade_Currency_Cost_multi] or 0
        point = techData.AttrDisplay[AllianceAttr.Tech_Upgrade_Currency_Cost_point] or 0
    end
    return math.ceil(originCostCount * (1 + multi / 10000) + point)
end

function AllianceTechModule:GetTechAttrDisplayValue(id, defaultValue)
    local techData = self:GetMyTechData()
    if not techData then
        return defaultValue
    end
    return techData.AttrDisplay[id] or defaultValue
end

function AllianceTechModule:SetDonateRank()
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    local myID = ModuleRefer.PlayerModule:GetPlayer().ID
    self.myWeekRank = 0
    self.weeklyRank = {}
    self.totalRank = {}
    for k, v in pairs(allianceInfo.AllianceTechnology.MemberData) do
        local isMine = myID == v.PlayerId
        table.insert(self.weeklyRank,
                     {PlayerId = v.PlayerId, DonateTimes = v.WeekDonateTimes, LastDonateTime = v.LastDonateTime.Seconds, DonateValues = v.WeekDonateValue, FacebookId = v.FacebookId, isMine = isMine})
        table.insert(self.totalRank, {
            PlayerId = v.PlayerId,
            DonateTimes = v.SeasonDonateTimes,
            LastDonateTime = v.LastDonateTime.Seconds,
            DonateValues = v.SeasonDonateValue,
            FacebookId = v.FacebookId,
            isMine = isMine,
        })
    end

    table.sort(self.weeklyRank, AllianceTechModule.SortByDonateValue)
    table.sort(self.totalRank, AllianceTechModule.SortByDonateValue)

    for k, v in pairs(self.weeklyRank) do
        if v.isMine and v.DonateValues > 0 then
            self.myWeekRank = k
        end
    end

    local mediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.AllianceTechResearchMediator)
    if mediator then
        mediator:UpdateRank()
    end
end

function AllianceTechModule.SortByDonateValue(a, b)
    if a.DonateValues == b.DonateValues then
        return a.LastDonateTime < b.LastDonateTime
    else
        return a.DonateValues > b.DonateValues
    end
end

return AllianceTechModule
