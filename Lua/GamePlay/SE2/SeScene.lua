local Scene = require("Scene")
local SEEnvironment = require("SEEnvironment")
local UIMediatorNames = require('UIMediatorNames')
local ModuleRefer = require('ModuleRefer')
local Utils = require("Utils")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local SEEnvironmentModeType = require("SEEnvironmentModeType")
local ConfigRefer = require("ConfigRefer")
local ConfigTimeUtility = require("ConfigTimeUtility")
local SceneEnterType = require("SceneEnterType")

---@class SeScene : Scene
local SeScene = class("SeScene", Scene)

SeScene.Name = "SeScene"

function SeScene:ctor()

end

function SeScene:GetTagName()
    return string.format('se_%s', self.tid)
end

function SeScene:EnterScene(param)
    Scene.EnterScene(self, param)

    self.SceneEntered = false
    self.SceneLoadReady = false
    self.tid = g_Game.StateMachine:ReadBlackboard("SE_TID")
    self.id = g_Game.StateMachine:ReadBlackboard("SE_ID")
	self.presetIndex = g_Game.StateMachine:ReadBlackboard("SE_PRESET_INDEX")
	self.isClimbTower = g_Game.StateMachine:ReadBlackboard("SE_IS_CLIMB_TOWER")
    self:LoadScene()

    ModuleRefer.PerformanceModule:AddTag(self:GetTagName())
end

function SeScene:ExitScene(param)
    local ins = SEEnvironment.Instance()
    if ins then
        ins:Dispose()
    end
    self:UnloadScene()

    ModuleRefer.PerformanceModule:RemoveTag(self:GetTagName())
    g_Game.UIManager:CloseAllByName(UIMediatorNames.SESettlementBattleDetailTipMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.SEExploreSettlementMediator)
    Utils.FullGC()
end

function SeScene:Tick(dt)
    if self.SceneLoadReady and not self.SceneEntered then
        g_Logger.Log("SeScene LoadSceneAsync %s finish", self.scenePath)
        self.SceneEntered = true
        self:StartSE()
    end
end

function SeScene:LoadScene()
    local SceneLoadUtility = CS.DragonReborn.AssetTool.SceneLoadUtility
    self.scenePath = ModuleRefer.EnterSceneModule:GetScenePathByTid(self.tid)
    
	g_Logger.TraceChannel("SE", "SE副本开始加载...")
	g_Game.EventManager:TriggerEvent(EventConst.SE_START_LOADING, self.tid)
    _G["SELoadingTimer"] = CS.System.DateTime.Now.Ticks

	-- 加载场景前调整背景优先级
	CS.UnityEngine.Application.backgroundLoadingPriority = CS.UnityEngine.ThreadPriority.High
	SceneLoadUtility.LoadSceneAsync(self.scenePath, function()
		-- 加载场景后恢复背景优先级
		CS.UnityEngine.Application.backgroundLoadingPriority = CS.UnityEngine.ThreadPriority.BelowNormal
        self.SceneLoadReady = true
    end)
end

function SeScene:UnloadScene()
    local SceneLoadUtility = CS.DragonReborn.AssetTool.SceneLoadUtility
    SceneLoadUtility.UnloadScene(self.scenePath)
    self.SceneLoadReady = false
    -- g_Game.UIManager:CloseAll() --避免“首领来袭”等UI被带到城内

    if self.runtimeId2 then
        g_Game.UIManager:Close(self.runtimeId2)
        self.runtimeId2 = nil
    end
    if self.runtimeId then
        g_Game.UIManager:Close(self.runtimeId)
        self.runtimeId = nil
    end
end

function SeScene:StartSE()
    local instanceId = self.tid
    local mapInfo = CS.SEMapInfo.GetInstance(instanceId)
    local uiCamera = g_Game.UIManager:GetUICamera()
    local camera = mapInfo:GetMainCamera()
    local mode = self.isClimbTower and SEEnvironmentModeType.ClimbTower or SEEnvironmentModeType.SingleScene
    local seEnv = SEEnvironment.Instance(true)
    seEnv:Init(instanceId, uiCamera, camera, mapInfo, self.presetIndex, mode)
    
    local noJoyStick = false
    local sceneConfig = ConfigRefer.MapInstance:Find(instanceId)
    if sceneConfig then
        local sceneEnterType = sceneConfig:SceneEnterTypo()
        if sceneEnterType == SceneEnterType.ReplicaPvp or sceneEnterType == SceneEnterType.Hunting then
            -- 异步竞技场 爬塔 不显示摇杆界面
            noJoyStick = true
        end
    end
    
    ---@type SEHudMediatorParameter
    local parameter = {}
    parameter.tid = self.tid
    parameter.noCardMode = true
    parameter.hideSkillShow = not noJoyStick
    parameter.noAutoMode = not noJoyStick
    self.runtimeId = g_Game.UIManager:Open(UIMediatorNames.SEHudMediator, parameter)
    if noJoyStick then
        return
    end
    ---@type SEHudJoyStickMediatorParameter
    local uiParameter = {}
    uiParameter.seEnv = seEnv
    uiParameter.throwBallTimeLimit = ConfigTimeUtility.NsToSeconds(ConfigRefer.ConstMain:PetCatchSlowMaxDuration())
    self.runtimeId2 = g_Game.UIManager:Open(UIMediatorNames.SEHudJoyStickMediator, uiParameter)
end

function SeScene:IsLoaded()
    return self.SceneLoadReady
end

return SeScene
