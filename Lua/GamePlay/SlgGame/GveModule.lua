local BaseModule = require('BaseModule')
local Delegate = require('Delegate')
local DBEntityType = require('DBEntityType')
local DBEntityPath = require('DBEntityPath')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local ConfigRefer = require('ConfigRefer')
local GotoUtils = require('GotoUtils')
local EventConst = require('EventConst')
local TroopGoToBattleParameter = require('TroopGoToBattleParameter')
local SlgUtils = require('SlgUtils')
local QueuedTask = require('QueuedTask')
local ProtocolId = require('ProtocolId')
local TimerUtility = require('TimerUtility')
local MonsterClassType = require('MonsterClassType')
---@class TroopCreateData
---@param index number
---@param coordX number
---@param coordY number
---@param target number
---@param purpose number @wrpc.MovePurpose

---@class GveModule
---@field troopCreateList table<number,TroopCreateData> 
---@field curBoss wds.MapMob
local GveModule = class('GveModule', BaseModule)

GveModule.BattleFieldState = {
    Ready = 0,
    Select = 1,
    Battling = 2,
    DeadCd = 3,
    OB = 4,
    Watching = 5,
    Finish = 6
}

GveModule.FinishDelay = 1.5

function GveModule:ctor() end

function GveModule:OnRegister()
    g_Game.EventManager:AddListener(EventConst.ON_TROOP_CREATED,
                                    Delegate.GetOrCreate(self,
                                                         self.OnTroopCreated))
    g_Game.EventManager:AddListener(EventConst.ON_TROOP_DESTROYED,
                                    Delegate.GetOrCreate(self,
                                                         self.OnTroopDestory))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer
                                          .TroopCandidateList.MsgPath,
                                      Delegate.GetOrCreate(self,
                                                           self.OnScenePlayerChanged))
    g_Game.EventManager:AddListener(EventConst.GVE_BATTLEFIELD_STATE,
                                    Delegate.GetOrCreate(self,
                                                         self.OnBattleFieldState))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushLevelReward, Delegate.GetOrCreate(self, self.PushLevelReward))
end

function GveModule:OnRemove()
    g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_CREATED,
                                       Delegate.GetOrCreate(self,
                                                            self.OnTroopCreated))
    g_Game.EventManager:RemoveListener(EventConst.ON_TROOP_DESTROYED,
                                       Delegate.GetOrCreate(self,
                                                            self.OnTroopDestory))
    g_Game.DatabaseManager:RemoveChanged(
        DBEntityPath.ScenePlayer.TroopCandidateList.MsgPath,
        Delegate.GetOrCreate(self, self.OnScenePlayerChanged))
    g_Game.EventManager:RemoveListener(EventConst.GVE_BATTLEFIELD_STATE,
                                       Delegate.GetOrCreate(self,
                                                            self.OnBattleFieldState))
    if self.hudRuntimeId then g_Game.UIManager:Close(self.hudRuntimeId) end
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushLevelReward, Delegate.GetOrCreate(self, self.PushLevelReward))
    g_Game.UIManager:CloseByName(UIMediatorNames.UIBehemothSettlementMediator)
    if self.finishDelayTimer then
        self.finishDelayTimer:Stop()
        self.finishDelayTimer = nil
    end
end

---@return wds.TroopCandidateList
function GveModule:GetTroopCandidateDBData()
    ---@type wds.ScenePlayer[]
    local entities = g_Game.DatabaseManager:GetEntitiesByType(
                         DBEntityType.ScenePlayer)
    if entities and entities[1] then
        return entities[1].TroopCandidateList
    else
        return nil
    end
end

function GveModule:Init()
    self:UpdateBossTroop()
    self.hudRuntimeId = g_Game.UIManager:Open(UIMediatorNames.UIGveHudMediator)

    local candiData = self:GetTroopCandidateDBData()
    if candiData then
        self:UpdateTroopCandidateData(candiData)
        self:InitCameraPos()
        self:InitFSM()
        -- ModuleRefer.MapFogModule.fogSystem:HideFog()
    else
        require('TimerUtility').DelayExecute(function() self:Exit() end, 2, true)
    end
end

function GveModule:GetSceneDisplayDuration()
    ---@type SlgScene
    local gveScene = ModuleRefer.SlgModule.curScene
    local sceneConfig = ConfigRefer.MapInstance:Find(gveScene.tid)
    return sceneConfig:DispDurationTime()
end

function GveModule:GetEndTime()
    local gveScene = ModuleRefer.SlgModule.curScene
    local sceneConfig = ConfigRefer.MapInstance:Find(gveScene.tid)
    ---@type wds.Scene
    local sceneData = g_Game.DatabaseManager:GetEntity(gveScene.id,DBEntityType.Scene)
    if not sceneData then
        return -1
    end
    return sceneData.SceneBase.StartTime.Seconds + sceneConfig:DurationTime()
end

function GveModule:GetStartTime()
    local gveScene = ModuleRefer.SlgModule.curScene
    ---@type wds.Scene
    local sceneData = g_Game.DatabaseManager:GetEntity(gveScene.id,DBEntityType.Scene)
    if not sceneData then
        return -1
    end
    return sceneData.Level.LevelStartTime.Seconds
end

function GveModule:GetUseTime()
    local gveScene = ModuleRefer.SlgModule.curScene
    ---@type wds.Scene
    local sceneData = g_Game.DatabaseManager:GetEntity(gveScene.id,DBEntityType.Scene)
    if not sceneData then
        return -1
    end
    return  g_Game.ServerTime:GetServerTimestampInSeconds() + sceneData.SceneBase.StartTime.Seconds
end

function GveModule:Exit()
    self.troopCandidates = nil
    self.curStage = nil
    self.stageBeginTime = 0
    self.stageEndTime = 0
    -- GotoUtils.GotoSceneKingdom(0, 0)          

    local SEHudTroopMediatorDefine = require('SEHudTroopMediatorDefine')
    local fromType = g_Game.StateMachine:ReadBlackboard("SE_FROM_TYPE")        
   
    if (fromType == SEHudTroopMediatorDefine.FromType.World) then
                
        local _exitX = g_Game.StateMachine:ReadBlackboard("SE_FROM_X")
        local _exitY = g_Game.StateMachine:ReadBlackboard("SE_FROM_Y")
        local callback = function()
            local KingdomMapUtils = require("KingdomMapUtils")
            local worldPos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(_exitX, _exitY, KingdomMapUtils.GetMapSystem())
            KingdomMapUtils.GetBasicCamera():LookAt(worldPos, 0)
        end
        g_Game.StateMachine:WriteBlackboard("KINGDOM_GO_TO_WORLD", true, true)   
        GotoUtils.GotoSceneKingdomWithLoadingUI(0, 0,_exitX,_exitY,callback)      
    else
        g_Game.StateMachine:WriteBlackboard("KINGDOM_GO_TO_WORLD", false, true)       
        GotoUtils.GotoSceneKingdomWithLoadingUI(0, 0)  
    end

end

function GveModule:Tick(delta)
    if self.battleFieldSM then self.battleFieldSM:Tick(delta) end
end

function GveModule:InitCameraPos()

    local _InitCam = function()
        -- 配置相机的初始位置    
        ---@type CS.UnityEngine.Vector3
        local troopPos
        ModuleRefer.SlgModule.curScene.basicCamera:SetSize(2206)

        local troopData = nil
        local posOffset = nil
        if self.selectTroopID then
            troopData = ModuleRefer.SlgModule:FindTroop(self.selectTroopID)
            posOffset = {x = 0, z = 200}
        else
            troopData = self.curBoss
            posOffset = {x = -64, z = 96}
        end

        if troopData then
            troopPos = ModuleRefer.SlgModule:ServerCoordinate2Vector3(
                           troopData.MapBasics.Position)
        end

        if troopPos then
            troopPos.x = troopPos.x + posOffset.x
            troopPos.z = troopPos.z + posOffset.z
            ModuleRefer.SlgModule.curScene.basicCamera:LookAt(troopPos, -1)
        end
    end

    if self.selectTroopID or self.curBoss then
        _InitCam()
    else
        local initQueue = QueuedTask.new()
        initQueue:WaitTrue(function()
            return self.selectTroopID or self.curBoss
        end):DoAction(function() _InitCam() end):Start()
    end
end

---@param data wds.ScenePlayer
function GveModule:OnScenePlayerChanged(data, changed)

    local dbData = data.TroopCandidateList

    self:UpdateTroopCandidateData(dbData)
end
---@param dbData wds.TroopCandidateList
function GveModule:UpdateTroopCandidateData(dbData, changed)
    if not self.troopCandidates or (changed and changed.Candidates) then
        local candidatesCount = dbData.Candidates:Count()
        ---@type wds.TroopCandidate[]
        self.troopCandidates = {}
        for i = 1, candidatesCount do
            local candidate = dbData.Candidates[i]
            table.insert(self.troopCandidates, candidate)
            if candidate.Status ==
                wds.TroopCandidateStatus.TroopCandidateBattling then
                self.selectTroopID = candidate.TroopObjId
                break
            end
        end
    end

    self.curStage = dbData.Stage
    -- self.stageBeginTime = dbData.StageStartTime
    -- self.stageEndTime = dbData.StageEndTime
end

function GveModule:OnTroopCreated(troopId, troopType)
    if troopType == SlgUtils.TroopType.MySelf then
        if self.selectTroopID ~= troopId then
            self.selectTroopID = troopId
            local ctrl = ModuleRefer.SlgModule:GetTroopCtrl(troopId)
            ModuleRefer.SlgModule:LookAtTroop(ctrl)
            g_Game.EventManager:TriggerEvent(EventConst.GVE_TROOP_MODIFIED)
        end
    elseif troopType >= SlgUtils.TroopType.Monster then
        self:UpdateBossTroop()
    end
end

function GveModule:OnTroopDestory(troopId)
    if self.selectTroopID == troopId then
        self.selectTroopID = nil
        g_Game.EventManager:TriggerEvent(EventConst.GVE_TROOP_MODIFIED)
    else
        self:UpdateBossTroop()
    end
end

function GveModule:SetSelectTroopIndex(index) self.selectTroopIndex = index end

function GveModule:SendSelectTroopParam()
    if not self.selectTroopIndex or self.selectTroopIndex <= 0 then return end
    local param = TroopGoToBattleParameter.new()
    param.args.QueueIdx = self.selectTroopIndex - 1
    param.args.Flag = 0
    param:Send()
end

---@return wds.Troop
function GveModule:GetSelectTroopData()
    if not self.selectTroopID then return end
    return ModuleRefer.SlgModule:FindTroop(self.selectTroopID)
end

function GveModule:UpdateBossTroop()
    local mobTroops = ModuleRefer.SlgModule:GetMobTroops()
    if not mobTroops or table.nums(mobTroops) < 1 then
        if self.curBoss then
            self.lastBoss = self.curBoss
            self.curBoss = nil
            g_Game.EventManager:TriggerEvent(EventConst.GVE_MONSTER_MODIFIED)
        end
        return
    end

    local boss = nil
    for key, troop in pairs(mobTroops) do
        local mobId = troop.MobInfo.MobID
        local mobCfg = ConfigRefer.KmonsterData:Find(mobId)
        if mobCfg:MonsterClass() == MonsterClassType.Boss or mobCfg:MonsterClass() == MonsterClassType.Behemoth then
            boss = troop
            break
        end
    end
    if self.curBoss ~= boss then
        self.lastBoss = self.curBoss
        self.curBoss = boss
        g_Game.EventManager:TriggerEvent(EventConst.GVE_MONSTER_MODIFIED)
    end
end

---@return wds.MapMob
function GveModule:GetBossData()
    if self.curBoss then
        return self.curBoss
    else
        return self.lastBoss
    end
end

function GveModule:InitFSM()
    local ready = require('GveBattleFieldStateReady').new()
    local selectTroop = require('GveBattleFieldStateSelectTroop').new()
    local battling = require('GveBattleFieldStateBattling').new()
    local deadCd = require('GveBattleFieldDeadCd').new()
    -- local reSelectTroop = require('GveBattleFieldStateReSelectTroop').new()
    local ob = require("GveBattleFieldStateOB").new()
    local finish = require('GveBattleFieldStateFinish').new()

    self.battleFieldSM = require('StateMachine').new()
    self.battleFieldSM:AddState(ready:GetName(), ready)
    self.battleFieldSM:AddState(selectTroop:GetName(), selectTroop)
    self.battleFieldSM:AddState(battling:GetName(), battling)
    self.battleFieldSM:AddState(deadCd:GetName(), deadCd)
    -- self.battleFieldSM:AddState(reSelectTroop:GetName(),reSelectTroop)
    self.battleFieldSM:AddState(ob:GetName(), ob)
    self.battleFieldSM:AddState(finish:GetName(), finish)

    local trans = require('GveFsmTranslation')
    ready:AddTransition(trans.ready2select.new(selectTroop:GetName()))
    ready:AddTransition(trans.any2ob.new(ob:GetName()))
    selectTroop:AddTransition(trans.select2battle.new(battling:GetName()))
    battling:AddTransition(trans.battle2deadcd.new(deadCd:GetName()))
    battling:AddTransition(trans.any2ob.new(ob:GetName()))
    deadCd:AddTransition(trans.deadcd2select.new(selectTroop:GetName()))
    -- reSelectTroop:AddTransition(trans.reselect2battle.new(battling:GetName()))    

    if self.curStage == wds.TroopCandidateStage.TroopCandidateInit then
        self.battleFieldSM:ChangeState(ready:GetName())
    elseif self.curStage == wds.TroopCandidateStage.TroopCandidateChoosing then
        self.battleFieldSM:ChangeState(selectTroop:GetName())
    elseif self.curStage == wds.TroopCandidateStage.TroopCandidateStageBattling then
        self.battleFieldSM:ChangeState(battling:GetName())
    elseif self.curStage == wds.TroopCandidateStage.TroopCandidateWaiting then    
        self.battleFieldSM:ChangeState(deadCd:GetName())
    else
        self.battleFieldSM:ChangeState(ob:GetName())
    end
end

function GveModule:OnBattleFinish()
    if self.battleFieldSM then
        self.battleFieldSM:ChangeState('GveBattleFieldStateFinish')
    end
end

-- function GveModule:HasBackupTroop()
--     -- Ignore GM Troops
--     local troops = ModuleRefer.SlgModule:GetMyTroops()
--     local hasBackup = false
--     for key, troop in pairs(troops) do
--         if troop.preset and ModuleRefer.SlgModule:GetTroopHpByPreset(troop.preset) > 0 then
--             hasBackup = true
--             break
--         end
--     end
--     return hasBackup
-- end

---@return wds.TroopCandidate[]
function GveModule:GetAllTroops()
    -- local troops = ModuleRefer.SlgModule:GetMyTroops()
    -- local presets = {}
    -- for key, value in pairs(troops) do
    --     if value.preset then
    --         presets[key] = value
    --     end
    -- end
    -- return presets
    return self.troopCandidates
end

function GveModule:IsInWatchState()
    if not self.troopCandidates or #self.troopCandidates < 1 then
        return true
    end
    return false
end

---@param state number @GveModule.BattleFieldState
function GveModule:OnBattleFieldState(state, param)
    self.curBattleFieldState = state
    self.curBattleFieldParam = param
end

---@return number @GveModule.BattleFieldState
function GveModule:GetCurrentBattleFieldState()
    return self.curBattleFieldState, self.curBattleFieldParam
end

---@return boolean
function GveModule:IsWin()
    return self.isWin
end

function GveModule:BattleFinish()
    g_Game.UIManager:Open(require('UIMediatorNames').UIBehemothSettlementMediator, {isGve = true})
end

---@param msg wrpc.PushLevelRewardRequest
function GveModule:PushLevelReward(isSucceed, msg)
    local curScene = ModuleRefer.SlgModule.curScene
    if not curScene or curScene:GetName() ~= 'SlgScene' then
        return
    end
    if not isSucceed then
        return
    end
    g_Logger.Log("OnPushLevelReward(GvE), Tid:[%s], Id:[%s], Suc:[%s]", tostring(msg.Tid), tostring(msg.Id), msg.Suc)
    self.isWin = msg.Suc
    self.finishDelayTimer = TimerUtility.DelayExecute(function()
        g_Game.UIManager:CloseAll()
        ---@type UIBehemothSettleMediatorParam
        local data = {}
        data.isWin = msg.Suc
        data.startTime = msg.RewardInfo.SlgBattleInfo.BattleStartTime
        data.endTime = msg.RewardInfo.SlgBattleInfo.BattleEndTime
        data.isGve = true
        g_Game.UIManager:Open(require('UIMediatorNames').UIBehemothSettlementMediator, data)
    end, GveModule.FinishDelay, false)
end

function GveModule:TestWin()
    self.isWin = true
	-- g_Game.UIManager:Open(UIMediatorNames.UIBehemothSettlementMediator)
	g_Game.UIManager:Open(UIMediatorNames.UIBehemothSettlementMediator)
end

function GveModule:TestLose()
    self.isWin = false
    -- g_Game.UIManager:Open(UIMediatorNames.UIBehemothSettlementMediator)
    g_Game.UIManager:Open(UIMediatorNames.UIBehemothSettlementMediator)
end

---@class PlayerDamageInfo
---@field playerId number
---@field playerName string
---@field portrait number
---@field portraitInfo wds.PortraitInfo
---@field damage number
---@field takeDamage number
---@field detail table<number,number> @key:troopId value:Damage

---@return PlayerDamageInfo[], number, number, number, number @damageList, allDamage, maxPlayerDamage, totalDamageTaken, maxDamageTaken
function GveModule:GetBossDamageDatas()
    if not self.curBoss
        or not self.curBoss.DamageStatistic
        or not self.curBoss.DamageStatistic.TakeDamage
        or self.curBoss.DamageStatistic.TakeDamage:Count() < 1
    then
        return nil, 0, 0, 0, 0
    end

    return ModuleRefer.SlgModule:GetMobDamageData(self.curBoss)
end

return GveModule
