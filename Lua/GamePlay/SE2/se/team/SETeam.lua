---@class SETeam
---@field new fun():SETeam
local SETeam = class("SETeam")
local DBEntityType = require("DBEntityType")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local SETeamFormation = require("SETeamFormation")
local SEEnvironmentModeType = require("SEEnvironmentModeType")
local SESceneRoot = require("SESceneRoot")
local StateMachine = require("StateMachine")
local SETeamStateMap = require("SETeamStateMap")

---@param manager SETeamManager
---@param presetIdx number
---@param castleBriefId number
function SETeam:ctor(manager, presetIdx, castleBriefId)
    self._manager = manager
    self._env = manager:GetEnvironment()
    self._presetIdx = presetIdx
    self._castleBriefId = castleBriefId
    ---@type table<number, SEHero>
    self._heroMembers = {}
    ---@type table<number, SEPet>
    self._petMembers = {}
    ---@type fun(add:SEHero, remove:SEHero)[]
    self._heroMembersChangeListeners = {}
    ---@type fun(add:SEPet, remove:SEPet)[]
    self._petMembersChangeListeners = {}

    local castleBrief = self:GetCastleBrief()
    self._playerId = castleBrief.Owner.PlayerID
    self._formation = SETeamFormation.new(self)
    self._clientMoving = false
    self._tickPause = false
    self._stateMachine = StateMachine.new()
end

function SETeam:Initialize()
    self:InitStateMachine()
    self:CacheMembers()
    self._formation:Initialize()
    self._formation:OnFormationChanged()
    self:AddEventListeners()
end

function SETeam:Dispose()
    self._formation:Dispose()
    self._stateMachine:ClearAllStates()
    self:RemoveEventListeners()
    self:ClearMemberCache()
    self._clientMoving = false
end

function SETeam:ClearMemberCache()
    table.clear(self._heroMembers)
    table.clear(self._petMembers)
    table.clear(self._heroMembersChangeListeners)
    table.clear(self._petMembersChangeListeners)
end

function SETeam:Update()
    self:ClearMemberCache()
    self:CacheMembers()
    self._formation:OnFormationChanged()
end

function SETeam:UpdateCenter()
    if not self._clientMoving and self._formation then
        self._formation:UpdateCenterPosAndDir()
    end
end

---@param info wds.ScenePlayerHeroBase
function SETeam:UpdateCaptain(info)
    self._formation:UpdateCaptain(info.CaptainHeroEntityId)
end

function SETeam:InitStateMachine()
    for stateName, stateClass in pairs(SETeamStateMap.StateMap) do
        self._stateMachine:AddState(stateName, stateClass.new(self))
    end
    self._stateMachine:ChangeState(SETeamStateMap.Names.Idle)
end

function SETeam:CacheMembers()
    local unitManager = self._env:GetUnitManager()
    if unitManager then
        for _, seHero in pairs(unitManager:GetHeroList()) do
            ---@type wds.Hero
            local entity = seHero:GetEntity()
            if entity and entity.Owner.PlayerID == self._playerId and entity.BasicInfo.PresetIndex == self._presetIdx then
                self._heroMembers[seHero._id] = seHero
            end
        end

        for _, sePet in pairs(unitManager:GetPetMap()) do
            ---@type wds.SePet
            local entity = sePet:GetEntity()
            if entity and entity.Owner.PlayerID == self._playerId and entity.BasicInfo.PresetIndex == self._presetIdx then
                self._petMembers[sePet._id] = sePet
            end
        end
    end
end

function SETeam:AddEventListeners()
    g_Game.EventManager:AddListener(EventConst.SE_UNIT_HERO_CREATE, Delegate.GetOrCreate(self, self.OnHeroCreate))
    g_Game.EventManager:AddListener(EventConst.SE_UNIT_HERO_DESTORY, Delegate.GetOrCreate(self, self.OnHeroDestory))
    g_Game.EventManager:AddListener(EventConst.SE_UNIT_PET_CREATE, Delegate.GetOrCreate(self, self.OnPetCreate))
    g_Game.EventManager:AddListener(EventConst.SE_UNIT_PET_DESTORY, Delegate.GetOrCreate(self, self.OnPetDestroy))
end

function SETeam:RemoveEventListeners()
    g_Game.EventManager:RemoveListener(EventConst.SE_UNIT_HERO_CREATE, Delegate.GetOrCreate(self, self.OnHeroCreate))
    g_Game.EventManager:RemoveListener(EventConst.SE_UNIT_HERO_DESTORY, Delegate.GetOrCreate(self, self.OnHeroDestory))
    g_Game.EventManager:RemoveListener(EventConst.SE_UNIT_PET_CREATE, Delegate.GetOrCreate(self, self.OnPetCreate))
    g_Game.EventManager:RemoveListener(EventConst.SE_UNIT_PET_DESTORY, Delegate.GetOrCreate(self, self.OnPetDestroy))
end

---@private
---@return wds.CastleBrief
function SETeam:GetCastleBrief()
    return g_Game.DatabaseManager:GetEntity(self._castleBriefId, DBEntityType.CastleBrief)
end

---@return wds.TroopPreset
function SETeam:GetTroopPreset()
    local castleBrief = self:GetCastleBrief()
    if not castleBrief then
        g_Logger.WarnChannel("SETeam", "CastleBrief not found %s", self._castleBriefId)
        return nil
    end

    local validIdx = math.min(self._presetIdx + 1, castleBrief.TroopPresets.Presets:Count())
    if validIdx <= 0 then
        g_Logger.WarnChannel("SETeam", "Invalid preset index %s", self._presetIdx)
        return nil
    end
    return castleBrief.TroopPresets.Presets[self._presetIdx + 1]
end

---@private
---@return wds.ScenePlayer
function SETeam:GetScenePlayer()
    ---@type wds.ScenePlayer[]
    local scenePlayers = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.ScenePlayer)
    for _, scenePlayer in ipairs(scenePlayers) do
        if scenePlayer.Owner.PlayerID == self._playerId then
            return scenePlayer
        end
    end
    return nil
end

---@return wds.ScenePlayerCenterPointBase
function SETeam:GetScenePlayerCenter()
    local scenePlayer = self:GetScenePlayer()
    if scenePlayer == nil then
        g_Logger.WarnChannel("SETeam", "ScenePlayer not found")
        return nil
    end

    local center = scenePlayer.ScenePlayerCenterPoint.Infos
    if not center or center:Count() == 0 then
        g_Logger.WarnChannel("SETeam", "ScenePlayerCenterPoint not found")
        return nil
    end

    return center[self._presetIdx]
end

---@return wds.ScenePlayerPresetBasisInfo
function SETeam:GetScenePlayerPreset()
    local scenePlayer = self:GetScenePlayer()
    if scenePlayer == nil then
        g_Logger.WarnChannel("SETeam", "ScenePlayer not found")
        return nil
    end

    local presetList = scenePlayer.ScenePlayerPreset.PresetList
    if not presetList or presetList:Count() == 0 then
        g_Logger.WarnChannel("SETeam", "ScenePlayerPreset not found")
        return nil
    end

    return presetList[self._presetIdx]
end

---@return wds.ScenePlayerHeroBase
function SETeam:GetScenePlayerHeroBase()
    local scenePlayer = self:GetScenePlayer()
    if scenePlayer == nil then
        g_Logger.WarnChannel("SETeam", "ScenePlayer not found")
        return nil
    end

    local heroList = scenePlayer.ScenePlayerHero
    if not heroList or not heroList.Infos or heroList.Infos:Count() == 0 then
        g_Logger.WarnChannel("SETeam", "ScenePlayerHero not found")
        return nil
    end

    return heroList.Infos[self._presetIdx]
end

---@param unit SEHero
function SETeam:OnHeroCreate(unit)
    ---@type wds.Hero
    local entity = unit:GetEntity()
    if entity.Owner.PlayerID ~= self._playerId or entity.BasicInfo.PresetIndex ~= self._presetIdx then
        return
    end

    self._heroMembers[unit._id] = unit
    self._formation:OnFormationChanged()
    self:DispatchAddOrRemoveEvent(self._heroMembersChangeListeners, unit, nil)
end

---@param unitId number
function SETeam:OnHeroDestory(unitId)
    local unit = self._heroMembers[unitId]
    if not unit then
        return
    end
    self:DispatchAddOrRemoveEvent(self._heroMembersChangeListeners, nil, unit)
    
    self._heroMembers[unitId] = nil
    self._formation:OnFormationChanged()
end

---@param unit SEPet
function SETeam:OnPetCreate(unit)
    ---@type wds.SePet
    local entity = unit:GetEntity()
    if entity.Owner.PlayerID ~= self._playerId or entity.BasicInfo.PresetIndex ~= self._presetIdx then
        return
    end

    self._petMembers[unit._id] = unit
    self._formation:OnFormationChanged()
    self:DispatchAddOrRemoveEvent(self._petMembersChangeListeners, unit, nil)
end

---@param unitId number
function SETeam:OnPetDestroy(unitId)
    local unit = self._petMembers[unitId]
    if not unit then
        return
    end
    self:DispatchAddOrRemoveEvent(self._petMembersChangeListeners, nil, unit)

    self._petMembers[unitId] = nil
    self._formation:OnFormationChanged()
end

function SETeam:IsOperatingTeam()
    if self._env:GetEnvMode() == SEEnvironmentModeType.CityScene then
        local scenePlayerPreset = self:GetScenePlayerPreset()
        if scenePlayerPreset then
            return scenePlayerPreset.InExplore 
        end
        return false
    else
        return true
    end
end

function SETeam:IsControlUnit()
    return self._clientMoving
end

function SETeam:Tick(delta)
    if not self:IsOperatingTeam() then
        return
    end

    if self._tickPause then
        g_Logger.TraceChannel("SETeam", "team[%d] paused tick", self._presetIdx)
        return
    end

    local checkIntencity = not self._clientMoving
    local clientMoving = ModuleRefer.SEJoystickControlModule:IsJoystickMoving(checkIntencity)
    if clientMoving ~= self._clientMoving then
        self._clientMoving = clientMoving
        if self._clientMoving then
            self:OnClientMovingStart(delta)
        else
            self:OnClientMovingEnd(delta)
        end
    elseif self._clientMoving then
        self:OnClintMove(delta)
    end

    if self._clientMoving then
        self._formation:Tick(delta)
    end
end

function SETeam:PauseTickForCatchPetBall()
    self._tickPause = true
    self._clientMoving = false
    self._formation._moveController:StopMove()
end

function SETeam:RecoverTick()
    self._tickPause = false
end

function SETeam:OnClientMovingStart(delta)
    self._stateMachine:ChangeState(SETeamStateMap.Names.Move)
    local dirX, dirY, intencity = ModuleRefer.SEJoystickControlModule:GetMovingParam()
    local dir = CS.UnityEngine.Vector3(dirX, 0, dirY)
    local rotation = SESceneRoot.GetCameraRotation()
    dir = rotation * dir
    self._formation:StartMove(dir, intencity, delta)
end

function SETeam:OnClientMovingEnd(delta)
    self._formation:StopMove(delta)
    self._stateMachine:ChangeState(SETeamStateMap.Names.Idle)
end

function SETeam:OnClintMove(delta)
    local dirX, dirY, intencity = ModuleRefer.SEJoystickControlModule:GetMovingParam()
    if intencity > 0 then
        local dir = CS.UnityEngine.Vector3(dirX, 0, dirY)
        local rotation = SESceneRoot.GetCameraRotation()
        dir = rotation * dir
        self._formation:Move(dir, intencity, delta)
    end
end

function SETeam:GetHeroMembers()
    return self._heroMembers
end

function SETeam:GetPetMembers()
    return self._petMembers
end

function SETeam:GetUnitMember(entityId)
    return self._env._unitManager:GetUnit(entityId)
end

function SETeam:GetCenterMoveSpeed()
    return self._manager:GetCenterMoveSpeed()
end

---@param unit SEUnit
function SETeam:IsUnitInTeam(unit)
    return self._heroMembers[unit._id] ~= nil or self._petMembers[unit._id] ~= nil
end

function SETeam:GetRandomUnitLocoAsCenter()
    for _, hero in pairs(self._heroMembers) do
        ---@type wds.Hero
        local entity = hero:GetEntity()
        if entity then
            local Position = entity.MapBasics.Position
            local Direction = entity.MapBasics.Direction
            return {Position = Position, Direction = Direction}
        end
    end
end

function SETeam:GetCreateHelper()
    return self._manager:GetPooledObjectCreateHelper()
end

function SETeam:GetAliveHeroCount()
    local count = 0
    for _, hero in pairs(self._heroMembers) do
        if not hero:IsDead() then
            count = count + 1
        end
    end
    return count
end

function SETeam:GetTeamVXRadius()
    local aliveCount = self:GetAliveHeroCount()
    return self._manager:GetTeamVXRadius(aliveCount)
end

function SETeam:GetRightOfBallControlHero()
    return self._formation:GetOrderedLastNotDeadHero()
end

---@return CS.UnityEngine.Vector3
function SETeam:GetFormationCenterPos()
    return self._formation:GetCenterClientPos()
end

function SETeam:DispatchAddOrRemoveEvent(eventList, add, remove)
    for _, v in ipairs(eventList) do
        v(add, remove)
    end
end

---@return fun():number,SEHero
function SETeam:PairsOfHeroMembers()
    local k,v
    return function()
        k,v = next(self._heroMembers, k)
        if k then
            return k,v
        end
    end
end

---@return fun():number,SEPet
function SETeam:PairsOfPetMembers()
    local k,v
    return function()
        k,v = next(self._petMembers, k)
        if k then
            return k,v
        end
    end
end

---@param listener fun(add:SEHero, remove:SEHero)
function SETeam:AddOnHeroAddOrRemoveListener(listener)
   table.insert(self._heroMembersChangeListeners, listener) 
end

---@param listener fun(add:SEHero, remove:SEHero)
function SETeam:RemoveOnHeroAddOrRemoveListener(listener)
    table.removebyvalue(self._heroMembersChangeListeners, listener)
end

---@param listener fun(add:SEPet, remove:SEPet)
function SETeam:AddOnPetAddOrRemoveListener(listener)
    table.insert(self._petMembersChangeListeners, listener)
end

---@param listener fun(add:SEPet, remove:SEPet)
function SETeam:RemoveOnPetAddOrRemoveListener(listener)
    table.insert(self._petMembersChangeListeners, listener)
end

---@return SEEnvironment
function SETeam:GetEnvironment()
    return self._env
end

return SETeam