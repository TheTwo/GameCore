local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local DBEntityPath = require('DBEntityPath')
local EventConst = require('EventConst')

---@class QuestDataWatcher
---@field dataCache table<number,table>
---@field noType number[]
---@field donotCacheType table<number,fun(condType:number,condOp:number, param:string[]):number>
local QuestDataWatcher = class('QuestDataWatcher')

---追踪的任务条件类型查看TaskCondType
function QuestDataWatcher:Init()
    self.dataCache = {}
    self.noType = {}
    self.donotCacheType = {}
    self:UpdatePlayerInfo()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self,self.OnDataChanged))
    g_Game.EventManager:AddListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self,self.UpdatePlayerInfo))
end

function QuestDataWatcher:Destory()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper.Task.MsgPath, Delegate.GetOrCreate(self,self.OnDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self,self.UpdatePlayerInfo))
end

function QuestDataWatcher:UpdatePlayerInfo()
    self.player = ModuleRefer.PlayerModule:GetPlayer()
end

function QuestDataWatcher:OnDataChanged(_, changedTable)
    if not changedTable then
        return
    end
    local changeItems = {}
    if changedTable and changedTable.Processing then
        local addItems = changedTable.Processing.Add or {}
        for taskId, _ in pairs(addItems) do
            changeItems[#changeItems + 1] = taskId
        end
    end
    ModuleRefer.QuestModule.Chapter:UpdateQuestCache(true)
    g_Game.EventManager:TriggerEvent(EventConst.QUEST_DATA_WATCHER_EVENT, changeItems)
    ModuleRefer.QuestModule:UpdateFollowQuest()
    g_Game.EventManager:TriggerEvent( EventConst.QUEST_FOLLOW_REFRESH )
    g_Game.EventManager:TriggerEvent( EventConst.QUEST_LATE_UPDATE )
end

function QuestDataWatcher:GetData(condType,dataKey)
    if dataKey == nil then
        return self.dataCache[condType]
    else
        local dataTable = self.dataCache[condType]
        if dataTable then
            return dataTable[dataKey]
        else
            return nil
        end
    end
end

---@param condType number 枚举来自TaskCondType
---@param condOp number 枚举来自CondExprOp
function QuestDataWatcher.CalcCondKey(condType,condOp)
    return condType * 10000 + condOp
end

---@param condType number 枚举来自TaskCondType
---@param condOp number 枚举来自CondExprOp
---@param params string[]
function QuestDataWatcher:GetDataByCondition(condType,condOp,params)
    local dataParam = nil
    local isSpDataType = false

    local notCachedDataProcesser = self.donotCacheType[condType]
    if notCachedDataProcesser then
        return notCachedDataProcesser(condType,condOp,params)
    end

    for key, value in pairs(self.noType) do
        if value == condType then
            isSpDataType = true
            break
        end
    end
    --额外判定条件处理
    if not isSpDataType  then
        --英雄相关
        if params and #params > 1 then
            dataParam = tonumber(params[2])
        else
            dataParam = 1
        end
    end

    return self:GetData(condType,dataParam)
end

return QuestDataWatcher