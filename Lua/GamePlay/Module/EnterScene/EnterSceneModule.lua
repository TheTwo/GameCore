local ProtocolId = require('ProtocolId')
local Delegate = require('Delegate')
local EnterSceneParameter = require('EnterSceneParameter')
local EnterSceneNewParameter = require("EnterSceneNewParameter")
local EnterSceneForPeerParameter = require('EnterSceneForPeerParameter')
local LeaveSceneNewParameter = require("LeaveSceneNewParameter")
local BaseModule = require('BaseModule')
local ConfigRefer = require('ConfigRefer')
local SceneType = require('SceneType')
local SceneChildType = require("SceneChildType")
local GotoUtils = require('GotoUtils')
local UIMediatorNames = require('UIMediatorNames')
local EventConst = require('EventConst')
local SeState = require('SeState')
local SeJumpScene = require('SeJumpScene')
local SlgState = require("SlgState")
local NewbieState = require("NewbieState")
local KingdomState = require('KingdomState')
local KingdomType = require('KingdomType')
local QueuedTask = require('QueuedTask')
local ModuleRefer = require('ModuleRefer')
local NumberFormatter = require('NumberFormatter')
local EnterSceneStage = require('EnterSceneStage')
local TimerUtility = require('TimerUtility')
local SEEnvironmentModeType = require("SEEnvironmentModeType")
local ShaderWarmupUtils = CS.DragonReborn.AssetTool.ShaderWarmupUtils

local HashSetString = CS.System.Collections.Generic.HashSet(typeof(CS.System.String))
local ListString = CS.System.Collections.Generic.List(typeof(CS.System.String))

---@class EnterSceneModule : BaseModule
local EnterSceneModule = class('EnterSceneModule', BaseModule)

function EnterSceneModule:ctor()
    -- tid是副本配置id，id是副本实例id
    -- 游戏中，玩家一定存在于某个副本，所以需要把tid和id缓存起来
    self:Reset()
end

function EnterSceneModule:OnRegister()
    self:Reset()

    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushEnterScene, Delegate.GetOrCreate(self, self.OnPushEnterScene))
    g_Game.ServiceManager:AddResponseCallback(EnterSceneParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnEnterSceneResponse))
    g_Game.ServiceManager:AddResponseCallback(EnterSceneNewParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnEnterSceneResponse))
    g_Game.ServiceManager:AddResponseCallback(EnterSceneForPeerParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnEnterSceneResponse))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.LogicTick))
end

function EnterSceneModule:OnRemove()
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushEnterScene, Delegate.GetOrCreate(self, self.OnPushEnterScene))
    g_Game.ServiceManager:RemoveResponseCallback(EnterSceneParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnEnterSceneResponse))
    g_Game.ServiceManager:RemoveResponseCallback(EnterSceneNewParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnEnterSceneResponse))
    g_Game.ServiceManager:RemoveResponseCallback(EnterSceneForPeerParameter.GetMsgId(), Delegate.GetOrCreate(self,self.OnEnterSceneResponse))
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.LogicTick))
end

function EnterSceneModule:Reset()
    self.tid = 0
    self.id = 0
    self.lastTid = 0
    self.lastId = 0
    self.systemReady = false
    self.reqStatus = 0
    self.tryEnterSceneType = nil
    self.hasPendingRequest = false --上个进场景的请求没回来，不允许再次请求进入场景
    self.enterHuntingUsingCover = false
    self.asyncWarmUpShaderCollectionName = string.Empty
    self.continueEnterSceneAfterAsyncWarmUpShader = false
    ShaderWarmupUtils.Reset()
end

function EnterSceneModule:SetSceneSystemReady(ready)
    self.systemReady = ready
end

function EnterSceneModule:IsRequesting()
    return self.reqStatus == 0
end

function EnterSceneModule:GetEnterSceneTypeFromTid(tid)
    local mapInstanceConfigCell = ConfigRefer.MapInstance:Find(tid)
    if mapInstanceConfigCell == nil then
        g_Logger.Warn("获取不到SceneType, 因为找不到配置：MapInstance %s", tid)
        return nil
    end

    return mapInstanceConfigCell:InstanceType()
end

---城内和大地图切换时，通知服务端切换场景
function EnterSceneModule:NoticeEnterScene(tid,id)
    if self.hasPendingRequest then
        return false
    end

    self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)

    -- 重入相同的Scene，不走网络请求
    if self.tid == tid then
        if id == 0 or id == self.id then
            return false
        end
    end
    
    self.hasPendingRequest = true
    
    local param = EnterSceneParameter.new()
    param.args.Tid = tid
    param.args.Id = id
    param:Send()

    self:OnEnterSceneStart()
    
    return true
end

function EnterSceneModule:EnterScene(tid, id, localChange)
    self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)
    -- 重入相同的Scene，不走网络请求
    if self.tid == tid then
        if id == 0 or id == self.id then
            self:DoEnterScene()
            return
        end
    end
    if not localChange then
        local param = EnterSceneParameter.new()
        param.args.Tid = tid
        param.args.Id = id
        param:Send()
    end
    self:OnEnterSceneStart()
end

function EnterSceneModule:EnterJumpScene(sceneTid, id, exitX, exitY)
    if self.tid == sceneTid then
        self.tid = nil
    end
    ---@type SeJumpSceneParameter
    local parameter = {}
    parameter.tid = sceneTid
    parameter.id = id
    parameter.exitX = exitX
    parameter.exitY = exitY
    g_Game.SceneManager:EnterScene(SeJumpScene.Name, parameter)
end

function EnterSceneModule:EnterSeScene(tid, id, troopId)
    self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)
	self.envMode = SEEnvironmentModeType.SingleScene

    -- 重入相同的Scene，不走网络请求
    if self.tid == tid then
        if id == 0 or id == self.id then
            self:DoEnterScene()
            return
        end
    end

    local param = EnterSceneParameter.new()
    param.args.Tid = tid
    param.args.Id = id
    param.args.HeroTids = wrpc.HeroIdList.New()
	param.args.HeroTids.Ids:Add(101)
    param:Send()

    self:OnEnterSceneStart()

    if not self:IsGameLoading() then
        g_Game.UIManager:Open(UIMediatorNames.LoadingPageMediator, {
            onProgress = Delegate.GetOrCreate(self, self.OnEnterSceneProgress)
        })
    end
end

function EnterSceneModule:EnterObserveSeScene(tid, id)
    self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)

    -- 重入相同的Scene，不走网络请求
    if self.tid == tid then
        if id == 0 or id == self.id then
            self:DoEnterScene()
            return
        end
    end

    local msg = EnterSceneForPeerParameter.new()  
    msg.args.EnterParam.Tid = tid
    msg:Send()

    g_Game.StateMachine:WriteBlackboard("SE_OBSERVE", true, true)

    self:OnEnterSceneStart()

    if not self:IsGameLoading() then
        g_Game.UIManager:Open(UIMediatorNames.LoadingPageMediator, {
            onProgress = Delegate.GetOrCreate(self, self.OnEnterSceneProgress)
        })
    end
end

function EnterSceneModule:EnterSeClimbTowerScene(tid, id, sectionId)
	self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)
	self.envMode = SEEnvironmentModeType.ClimbTower

    -- 重入相同的Scene，不走网络请求
    if self.tid == tid then
        if id == 0 or id == self.id then
            self:DoEnterScene()
            return
        end
    end

	local msg = EnterSceneNewParameter.new()
    msg.args.EnterParam.Tid = tid
    msg.args.EnterParam.EnterSceneParamClimbTower.ClimbTowerSectionCfgId = sectionId
    msg:Send()

    self:OnEnterSceneStart()

    if not self:IsGameLoading() then
        g_Game.UIManager:Open(UIMediatorNames.LoadingPageMediator, {
            onProgress = Delegate.GetOrCreate(self, self.OnEnterSceneProgress)
        })
    end
end

function EnterSceneModule:EnterSePVP(tid, id, targetPlayerId)
    self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)

    -- 重入相同的Scene，不走网络请求
    -- if self.tid == tid then
    --     if id == 0 or id == self.id then
    --         self:DoEnterScene()
    --         return
    --     end
    -- end

	local msg = EnterSceneNewParameter.new()
    msg.args.EnterParam.Tid = tid
    msg.args.EnterParam.EnterSceneParamReplicaPvp.TargetId = targetPlayerId
    msg:Send()

    self:OnEnterSceneStart()

    if not self:IsGameLoading() then
        g_Game.UIManager:Open(UIMediatorNames.LoadingPageMediator, {
            onProgress = Delegate.GetOrCreate(self, self.OnEnterSceneProgress),
            loadingType = require('LoadingType').PvPLoading
        })
    end
end

function EnterSceneModule:EnterSeSceneFromCityNpc(tid, id, troopId, elementId, npcServiceCfgId, presetIndex)
    self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)
	self.envMode = SEEnvironmentModeType.SingleScene
	self.presetIndex = presetIndex or 1

    -- 重入相同的Scene，不走网络请求
    if self.tid == tid then
        if id == 0 or id == self.id then
            self:DoEnterScene()
            return
        end
    end

    local huntSectionId = ModuleRefer.HuntingModule:GetHuntingSectionId(elementId)
	local msg = EnterSceneNewParameter.new()
    msg.args.EnterParam.Tid = tid
    if huntSectionId and huntSectionId > 0 then
        msg.args.EnterParam.EnterSceneParamHunting.TroopId = troopId or 0
        msg.args.EnterParam.EnterSceneParamHunting.QueueIndex = self.presetIndex - 1
        msg.args.EnterParam.EnterSceneParamHunting.SectionId = huntSectionId
        msg.args.EnterParam.EnterSceneParamHunting.CityElementTid = elementId
        msg.args.EnterParam.EnterSceneParamHunting.NpcServiceCfgId = npcServiceCfgId or 0
    else
        msg.args.EnterParam.EnterSceneParamNpcService.TroopId = troopId or 0
        msg.args.EnterParam.EnterSceneParamNpcService.CityElementTid = elementId or 0
        msg.args.EnterParam.EnterSceneParamNpcService.NpcServiceCfgId = npcServiceCfgId or 0
        msg.args.EnterParam.EnterSceneParamNpcService.QueueIndex = self.presetIndex - 1
    end
    
    msg:Send()

    self:OnEnterSceneStart()

    if not self:IsGameLoading() then
        g_Game.UIManager:Open(UIMediatorNames.LoadingPageMediator, {
            onProgress = Delegate.GetOrCreate(self, self.OnEnterSceneProgress)
        })
    end
end

function EnterSceneModule:EnterSeSceneGMDebug(tid, id, ...)
    self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)
	self.envMode = SEEnvironmentModeType.SingleScene

    -- 重入相同的Scene，不走网络请求
    if self.tid == tid then
        if id == 0 or id == self.id then
            self:DoEnterScene()
            return
        end
    end
    if g_Game.debugSupportOn then
        local gmCmd = require("DebugCmdParameter")
        local param = gmCmd.new()
        param.args.Cmd = "enter_scene_se"
        param.args.EntityID = ModuleRefer.PlayerModule:GetPlayer().ID
        param.args.Args:Add(tid)
        if id then
            param.args.Args:Add(id)
        end
        for _, value in ipairs(table.pack(...)) do
            if not value then
                param.args.Args:Add('')
            else
                param.args.Args:Add(value)
            end
        end
        param:SendOnceCallback(nil, nil, nil, function(cmd, isSuccess, rsp)
            self:OnEnterSceneResponse(isSuccess, nil)
        end)
        self:OnEnterSceneStart()
        if not self:IsGameLoading() then
            g_Game.UIManager:Open(UIMediatorNames.LoadingPageMediator, {
                onProgress = Delegate.GetOrCreate(self, self.OnEnterSceneProgress)
            })
        end
    end
end

function EnterSceneModule:IsGameLoading()
    return g_Game.UIManager:IsOpenedByName('UIGameLaunchMediator')
end

function EnterSceneModule:EnterSceneByInteractor(tid, id, troopId, interactorId, presetIndex)
	self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)
	self.envMode = SEEnvironmentModeType.SingleScene
	self.presetIndex = presetIndex or 1

    -- 重入相同的Scene，不走网络请求
    if self.tid == tid then
        if id == 0 or id == self.id then
            self:DoEnterScene()
            return
        end
    end

	local msg = require("EnterSceneNewParameter").new()
	msg.args.EnterParam.Tid = tid
	msg.args.EnterParam.EnterSceneParamByInteractor.InteractorId = interactorId or 0
	msg.args.EnterParam.EnterSceneParamByInteractor.TroopId = troopId or 0
	msg.args.EnterParam.EnterSceneParamByInteractor.QueueIndex = self.presetIndex - 1
	msg:Send()

	self:OnEnterSceneStart()

    if not self:IsGameLoading() then
        g_Game.UIManager:Open(UIMediatorNames.LoadingPageMediator, {
            onProgress = Delegate.GetOrCreate(self, self.OnEnterSceneProgress)
        })
    end
end

function EnterSceneModule:EnterScenePlayerInteractorScene(tid, id, troopId, compID, presetIndex)
	self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)
	self.envMode = SEEnvironmentModeType.SingleScene
	self.presetIndex = presetIndex or 1

    -- 重入相同的Scene，不走网络请求
    if self.tid == tid then
        if id == 0 or id == self.id then
            self:DoEnterScene()
            return
        end
    end

    local huntSectionId = ModuleRefer.HuntingModule:GetHuntingSectionIdByCompId(compID)
	local msg = EnterSceneNewParameter.new()
	msg.args.EnterParam.Tid = tid
    if huntSectionId and huntSectionId > 0 then
        msg.args.EnterParam.EnterSceneParamHunting.SeEnterCompId = compID or 0
        msg.args.EnterParam.EnterSceneParamHunting.SectionId = huntSectionId or 0
        msg.args.EnterParam.EnterSceneParamHunting.TroopId = troopId or 0
        msg.args.EnterParam.EnterSceneParamHunting.QueueIndex = self.presetIndex - 1
    else
        msg.args.EnterParam.EnterSceneParamBySeEnter.CompId = compID or 0
        msg.args.EnterParam.EnterSceneParamBySeEnter.TroopId = troopId or 0
        msg.args.EnterParam.EnterSceneParamBySeEnter.QueueIndex = self.presetIndex - 1
    end
	msg:Send()

	self:OnEnterSceneStart()

    if not self:IsGameLoading() then
        g_Game.UIManager:Open(UIMediatorNames.LoadingPageMediator, {
            onProgress = Delegate.GetOrCreate(self, self.OnEnterSceneProgress)
        })
    end
end

function EnterSceneModule:EnterHuntingScene(tid, id, troopId, sectionId, presetIndex)
    self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)
	self.envMode = SEEnvironmentModeType.SingleScene
	self.presetIndex = presetIndex or 1

    -- 重入相同的Scene，不走网络请求
    if self.tid == tid then
        if id == 0 or id == self.id then
            self:DoEnterScene()
            return
        end
    end
    self.enterHuntingUsingCover = false
    
    local preEnterAction = function()
        local msg = EnterSceneNewParameter.new()
        msg.args.EnterParam.Tid = tid
        msg.args.EnterParam.EnterSceneParamHunting.SectionId = sectionId or 0
        msg.args.EnterParam.EnterSceneParamHunting.TroopId = troopId or 0
        msg.args.EnterParam.EnterSceneParamHunting.QueueIndex = self.presetIndex - 1
        msg:SendOnceCallback(nil, nil, nil, function (cmd, isSuccess, rsp)
            if isSuccess then
                g_Game.StateMachine:WriteBlackboard("NEED_REOPEN_MEDIATOR_NAME", UIMediatorNames.HuntingMainMediator, true)
            end
        end)

        self:OnEnterSceneStart()
    end
    if not self:IsGameLoading() then
        local scenePath = EnterSceneModule.DoGetScenePathByTid(tid)
        local SceneLoadUtility = CS.DragonReborn.AssetTool.SceneLoadUtility
        if SceneLoadUtility.IsReadyForAllowSceneActivation(scenePath) then
            local _, _, needDownload, _ = EnterSceneModule.CheckNeedPrepareAssets(tid, self.presetIndex , self.envMode)
            if needDownload.Count <= 0 then
                local shaderCollectionName = EnterSceneModule.DoGetShaderWarmupByTid(tid)
                if string.IsNullOrEmpty(shaderCollectionName) or not g_Game.AssetManager:ExistsInAssetSystem(shaderCollectionName) or ShaderWarmupUtils.IsWarmedUp(shaderCollectionName) then
                    --都满足预载的条件了 不出loading 界面 直接切云
                    self.enterHuntingUsingCover = true
                    require("CloudUtils").Cover(false, preEnterAction)
                    return
                end
            end
        end
        preEnterAction()
        g_Game.UIManager:Open(UIMediatorNames.LoadingPageMediator, {
            onProgress = Delegate.GetOrCreate(self, self.OnEnterSceneProgress)
        })
    else
        preEnterAction()
    end
end

function EnterSceneModule:EnterPetCatchScene(tid, id, troopId, petCompId, npcId, elementId, presetIndex, villageId)
    g_Game.UIManager:CloseByName(UIMediatorNames.WorldEventRecordMediator)
    self.tryEnterSceneType = self:GetEnterSceneTypeFromTid(tid)
	self.envMode = SEEnvironmentModeType.SingleScene
	self.presetIndex = presetIndex or 1

    -- 重入相同的Scene，不走网络请求
    if self.tid == tid then
        if id == 0 or id == self.id then
            self:DoEnterScene()
            return
        end
    end

	require("CloudUtils").Cover(false, function()
		local msg = EnterSceneNewParameter.new()
		msg.args.EnterParam.Tid = tid
		if (petCompId) then
			if (villageId) then
				msg.args.EnterParam.EnterSceneParamVillagePetWild.QueueIndex = self.presetIndex - 1
				msg.args.EnterParam.EnterSceneParamVillagePetWild.PetWildCompId = petCompId
				msg.args.EnterParam.EnterSceneParamVillagePetWild.VillageEid = villageId
			else
				msg.args.EnterParam.EnterSceneParamPetCatch.TroopId = troopId or 0
				msg.args.EnterParam.EnterSceneParamPetCatch.PetWildCompId = petCompId or 0
				msg.args.EnterParam.EnterSceneParamPetCatch.QueueIndex = self.presetIndex - 1
			end
		else
			msg.args.EnterParam.EnterSceneParamPetCatchByNpcService.TroopId = troopId or 0
			msg.args.EnterParam.EnterSceneParamPetCatchByNpcService.NpcServiceCfgId = npcId or 0
			msg.args.EnterParam.EnterSceneParamPetCatchByNpcService.CityElementTid = elementId or 0
			msg.args.EnterParam.EnterSceneParamPetCatchByNpcService.QueueIndex = self.presetIndex - 1
		end
		msg:Send()

		self:OnEnterSceneStart()
	end)

    --if not self:IsGameLoading() then
        -- g_Game.UIManager:Open(UIMediatorNames.LoadingPageMediator, {
        --     onProgress = Delegate.GetOrCreate(self, self.OnEnterSceneProgress)
        -- })
    --end
end

function EnterSceneModule:OnEnterSceneStart()
    self.reqStatus = 0
    self.enterSceneProgress = 0
    self.enterSceneStage = EnterSceneStage.Start
    g_Logger.Log('EnterSceneStage.Start %s', self.enterSceneStage)
end

function EnterSceneModule:OnEnterSceneResponse(isSuccess, rsp)
    g_Logger.Log('EnterSceneModule:OnEnterSceneResponse')
    if not isSuccess then
        g_Game.EventManager:TriggerEvent(EventConst.SCENE_LOAD_STAGE_CHANGED, EnterSceneStage.Error)
		-- 强制开云
		require("CloudUtils").Uncover()
        return
    end

    if self.enterSceneStage < EnterSceneStage.ServerReply then
        g_Game.EventManager:TriggerEvent(EventConst.SCENE_LOAD_STAGE_CHANGED, EnterSceneStage.ServerReply)
        self.enterSceneStage = EnterSceneStage.ServerReply
        g_Logger.Log('EnterSceneStage.ServerReply %s', self.enterSceneStage)
    else
        g_Logger.Log('EnterSceneModule:忽略ServerReply,当前状态为%s', self.enterSceneStage)
    end
end

---@param success boolean
---@param data wrpc.PushEnterSceneRequest
function EnterSceneModule:OnPushEnterScene(success, data)
    g_Logger.Log('EnterSceneModule:PushEnterScene')
    if not success then
        g_Game.EventManager:TriggerEvent(EventConst.SCENE_LOAD_STAGE_CHANGED, EnterSceneStage.Error)
		-- 强制开云
		require("CloudUtils").Uncover()
        return
    end
    ---@type SeJumpScene
    local currentScene = g_Game.SceneManager.current
    if currentScene and currentScene:GetName() == SeJumpScene.Name and not currentScene:IsPushEnterSceneAllowed(data) then
        return
    end

    g_Game.EventManager:TriggerEvent(EventConst.SCENE_LOAD_STAGE_CHANGED, EnterSceneStage.ServerPushEnterScene)
    self.enterSceneStage = EnterSceneStage.ServerPushEnterScene
    g_Logger.Log('EnterSceneStage.ServerPushEnterScene %s', self.enterSceneStage)

    -- 缓存最新的场景状态
    self.lastTid, self.tid = self.tid, data.Tid
    self.lastId, self.id = self.id, data.Id

    self.hasPendingRequest = false

    self.reqStatus = 1

    -- 后端推送，且完成登录了，执行进入场景的逻辑
    if self.systemReady then
        local mapInstanceCell = ConfigRefer.MapInstance:Find(self.tid)
        if mapInstanceCell then
            local myCity = ModuleRefer.CityModule:GetMyCity()
            if myCity then
                local instanceType = mapInstanceCell:InstanceType()
                if instanceType == SceneType.SeInstance
                    or instanceType == SceneType.SlgInstance
                    or instanceType == SceneType.SlgBigWorld
                then
                    -- 从city 离开的话不能等加载完才释放se环境
                    myCity:PreDisposeSeEnvironment()
                end
            end
        end
        local assetsSet, ready, needDownload, invalid = EnterSceneModule.CheckNeedPrepareAssets(self.tid, self.presetIndex, self.envMode)
        if needDownload.Count <= 0 then
            self:OnSyncFinished()
            if UNITY_DEBUG then
                if invalid.Count > 0 then
                    local errorAssetList = invalid[0]
                    for i = 1, invalid.Count - 1 do
                        errorAssetList = errorAssetList .. '\n' .. invalid[i]
                    end
                    g_Logger.Error("load scene assetSet:%d ready:%d, needDownload:%d error assets:%d\n%s", assetsSet.Count, ready.Count, needDownload.Count, invalid.Count ,errorAssetList)
                end
            end
        else
            TimerUtility.DelayExecute(Delegate.GetOrCreate(self, self.PrepareAssets), 0.1, nil, assetsSet)
        end
        -- self:PrepareAssets()
    end
end

function EnterSceneModule:DoEnterScene()
    g_Logger.Log('EnterSceneModule:DoEnterScene')
    local mapInstanceCell = ConfigRefer.MapInstance:Find(self.tid)
    if mapInstanceCell == nil then
        g_Logger.Error('找不到Tid[%s]对应的MapInstance配置', self.tid)
        return
    end

    if self.tryEnterSceneType and mapInstanceCell:InstanceType() ~= self.tryEnterSceneType then
        g_Logger.Error('期待进入%s 网络推送进入%s', self.tryEnterSceneType, mapInstanceCell:InstanceType())
        return
    end

	self.tryEnterSceneType = nil

    if mapInstanceCell:InstanceType() == SceneType.SeInstance then
        self:DoEnterSE()
    elseif mapInstanceCell:InstanceType() == SceneType.SlgInstance then
        local childType = mapInstanceCell:InstanceChildType()
        if childType == SceneChildType.SlgBitplane then
            self:DoEnterBitplane()
        else
            self:DoEnterSlg()
        end
    else
        self:DoEnterKingdom()
    end
end

function EnterSceneModule:PrepareShaderWarmup()
    g_Logger.Log('EnterSceneModule:PrepareShaderWarmup')
    local shaderCollectionName = self:GetShaderWarmupByTid(self.tid)
    --self:DoShaderWarmup(shaderCollectionName)
    --self:DoShaderWarmupEnd()
    --g_Logger.Log('EnterSceneStage.ShaderWarmUpFinish %s', self.enterSceneStage)
    --self:DoShaderWarmupEndNextStep()
    self:DoShaderWarmupAsync(shaderCollectionName, true)
end

function EnterSceneModule:DoShaderWarmupAsync(shaderCollectionName, enterSceneContinue)
    self.continueEnterSceneAfterAsyncWarmUpShader = enterSceneContinue
    if SHADER_CREATE_PROGRAM_TRACKING then
        g_Logger.Log('SHADER_CREATE_PROGRAM_TRACKING is On Skip Warmup:%s', shaderCollectionName)
        self:DoShaderWarmupEnd()
        if self.continueEnterSceneAfterAsyncWarmUpShader then
            self.continueEnterSceneAfterAsyncWarmUpShader = false
            self:DoShaderWarmupEndNextStep()
        end
        return
    end
    if shaderCollectionName and not string.IsNullOrEmpty(shaderCollectionName) then
        self.asyncWarmUpShaderCollectionName = shaderCollectionName
        ShaderWarmupUtils.WarmUpShaderVariantsAsync(shaderCollectionName, 10)
    else
        self:DoShaderWarmupEnd()
        if self.continueEnterSceneAfterAsyncWarmUpShader then
            self.continueEnterSceneAfterAsyncWarmUpShader = false
            self:DoShaderWarmupEndNextStep()
        end
    end
end

function EnterSceneModule:DoShaderWarmup(shaderCollectionName)
    if self.asyncWarmUpShaderCollectionName 
            and not string.IsNullOrEmpty(self.asyncWarmUpShaderCollectionName) 
            and ShaderWarmupUtils.IsInWarmUpping(self.asyncWarmUpShaderCollectionName) then
        ShaderWarmupUtils.Unload(self.asyncWarmUpShaderCollectionName)
    end
    self.continueEnterSceneAfterAsyncWarmUpShader = false
    self.asyncWarmUpShaderCollectionName = string.Empty
    if SHADER_CREATE_PROGRAM_TRACKING then
        g_Logger.Log('SHADER_CREATE_PROGRAM_TRACKING is On Skip Warmup:%s', shaderCollectionName)
        return
    end
    if shaderCollectionName and not string.IsNullOrEmpty(shaderCollectionName) then
        local sw = CS.System.Diagnostics.Stopwatch()
        sw:Start()
        ShaderWarmupUtils.WarmUpShaderVariants(shaderCollectionName)
        sw:Stop()
        g_Logger.Log('PrepareShaderWarmup %s, cost %s ms', shaderCollectionName, sw.ElapsedMilliseconds)
    end
end

function EnterSceneModule:DoShaderWarmupEnd()
    self.asyncWarmUpShaderCollectionName = string.Empty
    g_Game.EventManager:TriggerEvent(EventConst.SCENE_LOAD_STAGE_CHANGED, EnterSceneStage.ShaderWarmUpFinish)
    self.enterSceneStage = EnterSceneStage.ShaderWarmUpFinish
end

function EnterSceneModule:DoShaderWarmupEndNextStep()
    TimerUtility.DelayExecute(Delegate.GetOrCreate(self, self.DoEnterScene), 0.1)
end

function EnterSceneModule.CheckNeedPrepareAssets(mapInstanceId, presetIndex, envMode)
    g_Logger.Log('EnterSceneModule:CheckNeedPrepareAssets')
    local scenePath = EnterSceneModule.DoGetScenePathByTid(mapInstanceId)
    local SceneLoadUtility = CS.DragonReborn.AssetTool.SceneLoadUtility
    local assetsSet = HashSetString()
    if not string.IsNullOrEmpty(scenePath) then
        if not SceneLoadUtility.HasPreLoadScene(scenePath) and not SceneLoadUtility.HasLoadedScene(scenePath) then
            assetsSet:Add(SceneLoadUtility.GetSceneName(scenePath))
        end
    end
    local otherAssets = EnterSceneModule.DoGetOtherAssets(mapInstanceId, presetIndex, envMode)
    if otherAssets then
        for i, v in ipairs(otherAssets) do
            assetsSet:Add(v)
        end
    end
    local readyList = ListString()
    local needDownList = ListString()
    local invalidList = ListString()
    g_Game.AssetManager:CheckSyncLoadAssetsReady(assetsSet, readyList, needDownList, invalidList)
    return assetsSet, readyList,needDownList,invalidList
end

---@param param "CS.System.Collections.Generic.HashSet<CS.System.String>"
function EnterSceneModule:PrepareAssets(assetsSet)
    g_Logger.Log('EnterSceneModule:PrepareAssets')

    g_Game.AssetManager:EnsureSyncLoadAssets(assetsSet, false, nil)

    if ModuleRefer.AssetSyncModule:NeedSkipSyncState() then
        self:OnAssetsReady()
        return
    end

    local bundleList = g_Game.AssetManager:GetAllDependencyAssetBundlesByAssets(assetsSet)
    self.remoteVersionDict = ModuleRefer.AssetSyncModule:FilterVersionCellsByBundleCollection(bundleList)
    self.totalDownloadBytes = ModuleRefer.AssetSyncModule:GetUpdateBytes(self.remoteVersionDict)
    self.finishedDownloadBytes = 0
    self.downloadSpeedByte = 0
    self.downloadStartTime = g_Game.Time.time

    ModuleRefer.AssetSyncModule:SyncFiles(self.remoteVersionDict, Delegate.GetOrCreate(self, self.OnSyncFinished), Delegate.GetOrCreate(self, self.OnSyncProgress), true)
    self.beginDownload = true
end

function EnterSceneModule.DoGetOtherAssets(mapInstanceId, presetIndex, envMode)
    local mapInstanceCell = ConfigRefer.MapInstance:Find(mapInstanceId)
    if mapInstanceCell:InstanceType() == SceneType.SeInstance then
        return require("SEWarmUpManager").PrepareWarmUpData(mapInstanceId, presetIndex, envMode)
    end

    return nil
end

---@return table<string>|nil
function EnterSceneModule:GetOtherAssets()
    return EnterSceneModule.DoGetOtherAssets(self.tid, self.presetIndex, self.envMode)
end

function EnterSceneModule:OnSyncFinished()
    self:OnAssetsReady()
end

function EnterSceneModule:OnSyncProgress(curCount, maxCount, downloadedBytes, totalBytes)
    self.finishedDownloadBytes = downloadedBytes
    self.downloadSpeedByte = math.float02(self.finishedDownloadBytes / (g_Game.Time.time - self.downloadStartTime))
end

function EnterSceneModule:OnAssetsReady()
    g_Logger.Log('EnterSceneModule:OnAssetsReady')
    g_Game.EventManager:TriggerEvent(EventConst.SCENE_LOAD_STAGE_CHANGED, EnterSceneStage.DownloadAssetsFinish)
    self.enterSceneStage = EnterSceneStage.DownloadAssetsFinish
    g_Logger.Log('EnterSceneStage.DownloadAssetsFinish %s', self.enterSceneStage)
    self.beginDownload = false
    local shaderCollectionName = self:GetShaderWarmupByTid(self.tid)
    if string.IsNullOrEmpty(shaderCollectionName) or ShaderWarmupUtils.IsWarmedUp(shaderCollectionName) then
        self:DoShaderWarmupEnd()
        self:DoEnterScene()
    else
        TimerUtility.DelayExecute(Delegate.GetOrCreate(self, self.PrepareShaderWarmup), 0.1)
    end
    -- self:PrepareShaderWarmup()
end

function EnterSceneModule:OnEnterSceneProgress()
    self.uiProgress = self.uiProgress or 0
    self.uiDescription = self.uiDescription or '#准备进入'

    if self.enterSceneStage < EnterSceneStage.ServerReply then
        self.uiProgress = EnterSceneStage.ServerReply / 100
        self.uiDescription = '#等待ServerReply'

    elseif self.enterSceneStage < EnterSceneStage.ServerPushEnterScene then
        self.uiProgress = EnterSceneStage.ServerPushEnterScene / 100
        self.uiDescription = '#等待ServerPushEnterScene'

    elseif self.enterSceneStage < EnterSceneStage.DownloadAssetsFinish then
        local tmpFinishedDownloadBytes = self.finishedDownloadBytes or 0
        local tmpTotalDownloadBytes = self.totalDownloadBytes or 0
        local tmpDownloadSpeedByte = self.downloadSpeedByte or 0
        local finishSize = NumberFormatter.NumberAbbr(tmpFinishedDownloadBytes)
        local totalSize = NumberFormatter.NumberAbbr(tmpTotalDownloadBytes)
        local speed = NumberFormatter.NumberAbbr(tmpDownloadSpeedByte)
        self.uiDescription = string.format("%s %s/S (%s / %s)", '#下载ab', speed, finishSize, totalSize)

        local benginProgress = EnterSceneStage.ServerPushEnterScene / 100
        local endProgress = EnterSceneStage.DownloadAssetsFinish / 100
        local downloadProgress = tmpFinishedDownloadBytes / math.max(0.1, tmpTotalDownloadBytes)
        self.uiProgress = math.clamp01(benginProgress + (endProgress - benginProgress) * downloadProgress)
        self.uiProgress = math.max(self.uiProgress, EnterSceneStage.DownloadAssetsFinish / 100)

    elseif self.enterSceneStage < EnterSceneStage.ShaderWarmUpFinish then
        self.uiProgress = EnterSceneStage.ShaderWarmUpFinish / 100
        self.uiDescription = '#正在shader warmup'

    end

    return self.uiProgress, self.uiDescription
end

function EnterSceneModule:DoEnterSE()
    g_Logger.Log('DoEnterSE')
    g_Game.StateMachine:WriteBlackboard("SE_TID", self.tid)
    g_Game.StateMachine:WriteBlackboard("SE_ID", self.id)
	g_Game.StateMachine:WriteBlackboard("SE_PRESET_INDEX", self.presetIndex)
	g_Game.StateMachine:WriteBlackboard("SE_IS_CLIMB_TOWER", self.envMode == SEEnvironmentModeType.ClimbTower)
    g_Game.StateMachine:ChangeState(SeState.Name)
end

function EnterSceneModule:DoEnterSlg()
    g_Logger.Log('DoEnterSlg')
    g_Game.StateMachine:WriteBlackboard("SLG_TID", self.tid)
    g_Game.StateMachine:WriteBlackboard("SLG_ID", self.id)
    g_Game.StateMachine:ChangeState(SlgState.Name)
end

function EnterSceneModule:DoEnterBitplane()
    g_Logger.Log('DoEnterBitplane')
    g_Game.StateMachine:WriteBlackboard("BIT_PLANE_TID", self.tid)
    g_Game.StateMachine:WriteBlackboard("BIT_PLANE_ID", self.id)
    g_Game.StateMachine:ChangeState(NewbieState.Name)
end

function EnterSceneModule:DoEnterKingdom()
    g_Logger.Log('DoEnterKingdom')
    if self.lastTid then
        local lastMapInstCell = ConfigRefer.MapInstance:Find(self.lastTid)
        if lastMapInstCell then
            if lastMapInstCell:InstanceType() == SceneType.SeInstance or
               lastMapInstCell:InstanceType() == SceneType.SlgInstance then
                --- 如果上一个场景是副本, 被Push踢出来时也需要Loading界面
                g_Game.StateMachine:WriteBlackboard("GOTO_KINGDOM_OPEN_LOADING", true, true)
            end
        end
    end

    local callback = g_Game.StateMachine:ReadBlackboard('GOTO_KINGDOM_CALLBACK')
    local onSceneLoaded = callback
    local loading = g_Game.StateMachine:ReadBlackboard('GOTO_KINGDOM_OPEN_LOADING')

    if loading then
        local wrapCallback = function()
            g_Game.UIManager:CloseByName(UIMediatorNames.LoadingPageMediator)

            if callback then
                callback()
            end
        end
        onSceneLoaded = wrapCallback
    end

    local targetKingdomType = GotoUtils.GetKingdomTypeByKid(self.tid)
    local currentKingdomType = GotoUtils.GetCurrentKingdomType()
    if targetKingdomType ~= currentKingdomType then
        if targetKingdomType == KingdomType.Kingdom then
            local queuedTask = QueuedTask.new()
            queuedTask:WaitEvent(EventConst.SCENE_LOADED, function()
                local entryToMap = GotoUtils.SceneId.Kingdom == self.tid
                g_Game.StateMachine:WriteBlackboard("KINGDOM_GO_TO_WORLD", entryToMap, true)
                g_Game.StateMachine:WriteBlackboard("KINGDOM_LOADING", loading)
                g_Game.StateMachine:ChangeState(KingdomState.Name)
            end):DoAction(function()
                if callback ~= nil then
                    callback()
                end
            end):Start()
        end
    else
        if onSceneLoaded then
            onSceneLoaded()
        end
    end
end

function EnterSceneModule.DoGetScenePathByTid(tid)
    local mapInstanceConfigCell = ConfigRefer.MapInstance:Find(tid)
    if mapInstanceConfigCell == nil then
        g_Logger.Error("找不到配置：MapInstance %s", tid)
        return ''
    end

    local sceneId = mapInstanceConfigCell:SceneId()
    local mapSceneConfigCell = ConfigRefer.MapScene:Find(sceneId)
    if mapSceneConfigCell == nil then
        g_Logger.Error("找不到配置：MapScene %s", sceneId)
        return ''
    end

    return mapSceneConfigCell:ResPath()
end

function EnterSceneModule:GetScenePathByTid(tid)
    return EnterSceneModule.DoGetScenePathByTid(tid)
end

function EnterSceneModule.DoGetShaderWarmupByTid(tid)
    local mapInstanceConfigCell = ConfigRefer.MapInstance:Find(tid)
    if mapInstanceConfigCell == nil then
        g_Logger.Error("找不到配置：MapInstance %s", tid)
        return ''
    end

    local sceneId = mapInstanceConfigCell:SceneId()
    local mapSceneConfigCell = ConfigRefer.MapScene:Find(sceneId)
    if mapSceneConfigCell == nil then
        g_Logger.Error("找不到配置：MapScene %s", sceneId)
        return ''
    end

    return mapSceneConfigCell:ShaderWarmup()
end

function EnterSceneModule:GetShaderWarmupByTid(tid)
    return EnterSceneModule.DoGetShaderWarmupByTid(tid)
end

function EnterSceneModule:Tick(dt)
    ShaderWarmupUtils.Tick()
end

function EnterSceneModule:LogicTick(dt)
    if string.IsNullOrEmpty(self.asyncWarmUpShaderCollectionName) then
        return
    end
    if ShaderWarmupUtils.IsWarmedUp(self.asyncWarmUpShaderCollectionName) or not ShaderWarmupUtils.IsInWarmUpping(self.asyncWarmUpShaderCollectionName) then
        self.asyncWarmUpShaderCollectionName = string.Empty
        self:DoShaderWarmupEnd()
        if self.continueEnterSceneAfterAsyncWarmUpShader then
            self.continueEnterSceneAfterAsyncWarmUpShader = false
            self:DoShaderWarmupEndNextStep()
        end
    end
end

return EnterSceneModule
