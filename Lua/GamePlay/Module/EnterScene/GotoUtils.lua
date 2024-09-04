local KingdomType = require('KingdomType')
local KingdomState = require("KingdomState")
local ModuleRefer = require('ModuleRefer')
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityType = require("DBEntityType")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")

---@class GotoUtils
local GotoUtils = class("GotoUtils")

GotoUtils.SceneId = {
    Kingdom = 11001,
    MainCity = 20000,
}

GotoUtils.CannotEnterSeNotice = 24024
GotoUtils.CannotEnterCreepTumorNotice = 83013

-- 切到SE场景
function GotoUtils.GotoSceneSe(tid, troopId)
	if (not GotoUtils.CheckStaminaByTid(tid, true)) then return end
	ModuleRefer.EnterSceneModule:EnterSeScene(tid, 0, troopId)
end

-- 从City的Npc切到SE场景
function GotoUtils.GotoSceneSeFromCityNpc(tid, troopId, elementId, npcServiceCfgId, troopPresetIdx)
	if (not GotoUtils.CheckStaminaByTid(tid, true)) then return end
    ModuleRefer.EnterSceneModule:EnterSeSceneFromCityNpc(tid, 0, troopId, elementId, npcServiceCfgId, troopPresetIdx)
end

-- GM 进SE场景 该指令会跳过服务器的各种验证
function GotoUtils.GotoSceneSeGM(tid, troopId)
    ModuleRefer.EnterSceneModule:EnterSeSceneGMDebug(tid, 0, troopId)
end

--- 切到宠物抓捕场景
---@param tid number 副本ID
---@param troopId number 部队ID
---@param petCompId number 宠物组件ID
---@param npcId number 据点ID
---@param elementId number
---@param troopPresetIdx number 编队编号
---@param villageId number 村庄ID
function GotoUtils.GotoScenePetCatch(tid, troopId, petCompId, npcId, elementId, troopPresetIdx, villageId)
	g_Logger.Error("GotoScenePetCatch tid: %s, troopId: %s, petCompId: %s, petVillageId: %s", tid, troopId, petCompId, villageId)
    g_Logger.Error('此入口已废弃，请调整抓宠进入的写法')
	-- if (not GotoUtils.CheckStaminaByTid(tid, true)) then return end
    -- if KingdomMapUtils.IsMapState() then
	-- 	ModuleRefer.EnterSceneModule:EnterPetCatchScene(tid, 0, troopId, petCompId, nil, nil, troopPresetIdx, villageId)
	-- else
	-- 	ModuleRefer.EnterSceneModule:EnterPetCatchScene(tid, 0, troopId, nil, npcId, elementId, troopPresetIdx)
	-- end
end

---City抓宠
---@param npcServiceId number
---@param elementId number
function GotoUtils.GotoCityPetCatch(npcServiceId, elementId)
    ModuleRefer.PetCaptureModule:OpenPetCaptureFromCity(npcServiceId, elementId)
end

---野外抓宠
---@param petWildCfgId number @PetWildConfigCell ID
---@param petCompId number @宠物组件ID
---@param villageId number @村庄ID
---@param landCfgId number @LandConfigCell ID
function GotoUtils.GotoWildPetCatch(petWildCfgId, petCompId, villageId, landCfgId)
    ModuleRefer.PetCaptureModule:OpenPetCaptureFromWild(petWildCfgId, petCompId, villageId, landCfgId)
end

--- 通过交互物进副本
---@param tid number 副本ID
---@param troopId number 部队ID
---@param interactorId number 交互物ID
---@param troopPresetIdx number 编队编号
function GotoUtils.GotoSceneByInteractor(tid, troopId, interactorId, troopPresetIdx)
    if (not GotoUtils.CheckCanEnterSingleSe(interactorId)) then
        ModuleRefer.ToastModule:AddSimpleToast(g_Game:GetErrMsgWithCode(GotoUtils.CannotEnterSeNotice))
        return
    end
    if GotoUtils.CheckSeInMist(interactorId) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_tips_clearmist"))
        return
    end
	if (not GotoUtils.CheckStaminaByTid(tid, true)) then return end
	ModuleRefer.EnterSceneModule:EnterSceneByInteractor(tid, 0, troopId, interactorId, troopPresetIdx)
end

--- 通过个人se入口交互物进副本
---@param tid number 副本ID
---@param troopId number 部队ID
---@param compID number 交互物组件ID
---@param troopPresetIdx number 编队编号
function GotoUtils.GotoScenePersonalInteractor(tid, troopId, compID, troopPresetIdx)
	if (not GotoUtils.CheckStaminaByTid(tid, true)) then return end
	ModuleRefer.EnterSceneModule:EnterScenePlayerInteractorScene(tid, 0, troopId, compID, troopPresetIdx)
end

-- 切到Kingdom场景
function GotoUtils.GotoSceneKingdom(tid, id, x, y, onSceneLoaded)
    g_Game.StateMachine:WriteBlackboard("GOTO_KINGDOM_X", x, true)
    g_Game.StateMachine:WriteBlackboard("GOTO_KINGDOM_Y", y, true)
    g_Game.StateMachine:WriteBlackboard("GOTO_KINGDOM_CALLBACK", onSceneLoaded)

    ModuleRefer.EnterSceneModule:EnterScene(tid, id)
end

-- 切到Kingdom场景并带上UI遮盖
function GotoUtils.GotoSceneKingdomWithLoadingUI(tid, id, x, y, onSceneLoaded, localChange)
    g_Game.StateMachine:WriteBlackboard("GOTO_KINGDOM_X", x, true)
    g_Game.StateMachine:WriteBlackboard("GOTO_KINGDOM_Y", y, true)
    g_Game.StateMachine:WriteBlackboard("GOTO_KINGDOM_OPEN_LOADING", true)
    g_Game.StateMachine:WriteBlackboard("GOTO_KINGDOM_CALLBACK", onSceneLoaded)

    ModuleRefer.EnterSceneModule:EnterScene(tid, id, localChange)
end

function GotoUtils.GotoSceneNewbie()
    ModuleRefer.EnterSceneModule:EnterScene(20002, 0)
end

function GotoUtils.GotoSceneCity()
    ModuleRefer.EnterSceneModule:EnterScene(20000, 0)
end

function GotoUtils.GoToJumpScene(sceneTid, id, exitX, exitY)
    ModuleRefer.EnterSceneModule:EnterJumpScene(sceneTid, id, exitX, exitY)
end

function GotoUtils.GetCurrentKingdomType()
    if g_Game.StateMachine:IsCurrentState(KingdomState.Name) then
        return KingdomType.Kingdom
    end

    --这里写其他场景的逻辑
    return KingdomType.Unknown
end

function GotoUtils.GetKingdomTypeByKid(tid)
    if tid == GotoUtils.SceneId.Kingdom or tid == GotoUtils.SceneId.MainCity then
        return KingdomType.Kingdom
    end

    --这里写其他场景的逻辑
    return KingdomType.Unknown
end

--- 根据场景检查体力需求
---@param tid number 场景ID
---@param showToast boolean 是否显示Toast
---@return boolean 体力足够返回true, 否则false
function GotoUtils.CheckStaminaByTid(tid, showToast)
	if (not tid or tid <= 0) then return false end
	local mapCfg = ConfigRefer.MapInstance:Find(tid)
	if (not mapCfg) then return false end
	local player = ModuleRefer.PlayerModule:GetPlayer()
	if (not player) then return false end
	local cur = player.PlayerWrapper2.Radar.PPPCur
	local result = cur and cur >= mapCfg:CostPPP()
	if (not result and showToast) then
		ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_tilibuzu"))
	end
	return result
end

--检查是否能进入单人SE副本
function GotoUtils.CheckCanEnterSingleSe(interactorId)
	if (not interactorId or interactorId <= 0) then return false end
    local entity = g_Game.DatabaseManager:GetEntity(interactorId, DBEntityType.SlgInteractor)
    if entity then
        if not entity.Interactor.State.CannotEnterSe then
            return true
        end
    end
	return false
end

--检查是否能进入菌毯核心SE副本
function GotoUtils.CheckCanEnterCreepTumorSe(creepTumorId)
	if (not creepTumorId or creepTumorId <= 0) then return false end
    local creepData = self:GetCreepData(creepTumorId)
    if creepData then
        if ModuleRefer.MapCreepModule:IsTumorAlive(creepData) then
            return true
        end
    end
	return false
end

--检查SE副本是否在迷雾中
function GotoUtils.CheckSeInMist(interactorId)
	if (not interactorId or interactorId <= 0) then return true end
    local entity = g_Game.DatabaseManager:GetEntity(interactorId, DBEntityType.SlgInteractor)
    if entity then
        local tempWorldPos = wds.Vector3F(entity.MapBasics.Position.X, entity.MapBasics.Position.Y, 0)
        local tempx, tempz  = KingdomMapUtils.ParseBuildingPos(tempWorldPos)
        if ModuleRefer.MapFogModule:IsFogUnlocked(tempx, tempz) then
            return false
        end
    end
	return true
end

return GotoUtils
