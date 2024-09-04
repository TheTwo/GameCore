local CityExplorerTeamDefine = require("CityExplorerTeamDefine")
local StateMachine = require("StateMachine")
local CityExplorerTeamStateSet = require("CityExplorerTeamStateSet")
local CityExplorerTeamTrigger = require("CityExplorerTeamTrigger")
local CityExplorerStateDefine = require("CityExplorerStateDefine")
local ModuleRefer = require("ModuleRefer")
local CityExplorerTeamData = require("CityExplorerTeamData")
local Utils = require("Utils")
local CityUnitPathLine = require("CityUnitPathLine")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local SEPreExportDefine = require("SEPreExportDefine")
local CityElementType = require("CityElementType")
local LogicUnitRuleKey = require("LogicUnitRuleKey")
local SpecialDamageType = require("SpecialDamageType")

local ColorUtility = CS.UnityEngine.ColorUtility

---@class CityExplorerTeam
---@field new fun():CityExplorerTeam
local CityExplorerTeam = class('CityExplorerTeam')
local success, color = ColorUtility.TryParseHtmlString("#FFF186")
CityExplorerTeam.MarchLineColor = success and color or CS.UnityEngine.Color.cyan

function CityExplorerTeam:ctor()
    ---@type table<number, SEHero>
    self._assignSEHeros = {}
    ---@type table<number, number>
    self._assignSEHerosHpCache = {}
    ---@type table<number, CityUnitMoveGridEventProvider.UnitHandle>
    self._moveGridHandles = {}
    self._currentFocusOnHero = nil
    self._heroCount = 0
    ---@type number
    self._teamPresetIdx = nil
    ---@type CityExplorerManager
    self._mgr = nil
    ---@type CityExplorerTeamData
    self._teamData = nil
    
    ---@type CS.UnityEngine.Vector3
    self._lastInCityPos = nil
    self._stateMachine = StateMachine.new()
    for stateName, state in pairs(CityExplorerTeamStateSet.TeamState) do
        self._stateMachine:AddState(stateName, state.new(self))
    end
    self._teamTrigger = CityExplorerTeamTrigger.new()
    self._isHideAndPause = false
    self._allowShowLine = false
    ---@type CityUnitPathLine
    self._wayPointsLine = nil
    self._disposed = false
end

---@return CityExplorerTeamData
function CityExplorerTeam:GetTeamData()
    return self._teamData
end

---@param mgr CityExplorerManager
---@param presetIndex number
function CityExplorerTeam:Spawn(mgr, presetIndex, scenePlayerId)
    self._mgr = mgr
    self._teamPresetIdx = presetIndex
    self._teamData = CityExplorerTeamData.new(self._mgr.city, self._mgr, self, scenePlayerId)
    self._teamTrigger:Init(self)
    -- self._teamTrigger:Show()
    -- self._teamTrigger:SetSelected(false)
end

function CityExplorerTeam:Tick(dt)
    if self._isHideAndPause then
        return
    end
    self._stateMachine:Tick(dt)
    self._teamTrigger:Tick(dt)
    for heroId, heroUnit in pairs(self._assignSEHeros) do
        local pos = heroUnit:GetActor():GetPosition()
        if not pos then
            goto continue
        end
        local moveHandle = self._moveGridHandles[heroId]
        local x, y = self._mgr.city:GetCoordFromPosition(pos)
        moveHandle:refreshPos(x, y)
        ::continue::
    end
    -- self:TestNavRayCast()
end

function CityExplorerTeam:Release()
    self:RemovePathLine()
    self._heroCount = 0
    table.clear(self._assignSEHeros)
    for _, handle in pairs(self._moveGridHandles) do
        handle:dispose()
    end
    table.clear(self._assignSEHerosHpCache)
    table.clear(self._moveGridHandles)
    self._currentFocusOnHero = nil
    self._disposed = true
    self._teamTrigger:Hide()
    self._teamTrigger:Release()
end

function CityExplorerTeam:WaitForSync()
    self._stateMachine:ChangeState("CityExplorerTeamStateSyncFromData")
end

function CityExplorerTeam:SyncFromData()
    if self._stateMachine.currentName ~= "CityExplorerTeamStateSyncFromData" then
        return
    end
    ---@type CityExplorerTeamStateSyncFromData
    local state = self._stateMachine.currentState
    state:Fire()
end

function CityExplorerTeam:AddEvents()
    g_Game.EventManager:AddListener(EventConst.SE_UNIT_HERO_CREATE, Delegate.GetOrCreate(self, self.OnHeroCreate))
    g_Game.EventManager:AddListener(EventConst.SE_UNIT_HERO_DESTORY, Delegate.GetOrCreate(self, self.OnHeroDestory))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Hero.MovePathInfo.Path.MsgPath, Delegate.GetOrCreate(self, self.OnHeroEntityPathChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Hero.Fight.HP.MsgPath, Delegate.GetOrCreate(self, self.OnHeroHpChanged))
end

function CityExplorerTeam:RemoveEvents()
    g_Game.EventManager:RemoveListener(EventConst.SE_UNIT_HERO_CREATE, Delegate.GetOrCreate(self, self.OnHeroCreate))
    g_Game.EventManager:RemoveListener(EventConst.SE_UNIT_HERO_DESTORY, Delegate.GetOrCreate(self, self.OnHeroDestory))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Hero.MovePathInfo.Path.MsgPath, Delegate.GetOrCreate(self, self.OnHeroEntityPathChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Hero.Fight.HP.MsgPath, Delegate.GetOrCreate(self, self.OnHeroHpChanged))
end

---@param seUnit SEHero
function CityExplorerTeam:OnHeroCreate(seUnit)
    ---@type wds.Hero
    local entity = seUnit:GetEntity()
    if entity.Owner.PlayerID ~= ModuleRefer.PlayerModule:GetPlayerId() or entity.BasicInfo.PresetIndex ~= self._teamPresetIdx then
        return
    end
    if self._assignSEHeros[entity.ID] then return end
    self._assignSEHeros[entity.ID] = seUnit
    self._assignSEHerosHpCache[entity.ID] = entity.Fight.HP
    self._heroCount = self._heroCount + 1
    local seMgr = self._mgr.city.citySeManger
    self._currentFocusOnHero = seMgr:GetFocusOnHeroInTeam(self._assignSEHeros, self._teamPresetIdx)
    local provider = self._mgr.city.unitMoveGridEventProvider
    local oldHandle = self._moveGridHandles[entity.ID]
    if oldHandle then
        oldHandle:dispose()
    end
    local x,y = entity.MapBasics.Position.X,entity.MapBasics.Position.Y
    oldHandle = provider:AddUnit(x,y, provider.UnitType.Explorer)
    self._moveGridHandles[entity.ID] = oldHandle
end

---@param seEntityID number
function CityExplorerTeam:OnHeroDestory(seEntityID)
    local seUnit = self._assignSEHeros[seEntityID]
    if not seUnit then return end
    self._assignSEHeros[seEntityID] = nil
    self._assignSEHerosHpCache[seEntityID] = nil
    local oldHandle = self._moveGridHandles[seEntityID]
    if oldHandle then
        oldHandle:dispose()
    end
    self._moveGridHandles[seEntityID] = nil
    self._heroCount = self._heroCount - 1
    if self._currentFocusOnHero == seUnit then
        local seMgr = self._mgr.city.citySeManger
        self._currentFocusOnHero = seMgr:GetFocusOnHeroInTeam(self._assignSEHeros, self._teamPresetIdx)
    end
end

function CityExplorerTeam:HasHero()
    return self._heroCount > 0
end

function CityExplorerTeam:GetCurrentMovePath()
    if not self._currentFocusOnHero then return nil end
    ---@type wds.Hero
    local entity = self._currentFocusOnHero:GetEntity()
    if not entity or not entity.MovePathInfo or not entity.MovePathInfo.Path or entity.MovePathInfo.Path:Count() <= 0 then
        return nil
    end
    return entity.MovePathInfo.Path
end

---@return CS.UnityEngine.Vector3|nil
function CityExplorerTeam:GetPosition()
    if not self._currentFocusOnHero then return self._lastInCityPos end
    local actor = self._currentFocusOnHero:GetActor()
    if not actor then return self._lastInCityPos end
    self._lastInCityPos = actor:GetPosition()
    return self._lastInCityPos
end

function CityExplorerTeam:GetFocusOnHeroDir()
    local actor = self:GetFocusOnHeroActor()
    if not actor then return nil end
    return actor:GetForward()
end

function CityExplorerTeam:GetFocusOnHeroActor()
    if not self._currentFocusOnHero then return nil end
    return self._currentFocusOnHero:GetActor()
end

function CityExplorerTeam:IsTeamGoingToTarget(targetId)
    if not self._teamData:HasTarget() then
        return false
    end
    if self._teamData._targetId ~= targetId then
        return false
    end
    if self._stateMachine.currentName == "CityExplorerTeamStateGoToTarget" then
        local teamTarget = self._stateMachine:ReadBlackboard(CityExplorerStateDefine.BlackboardKey.TargetId, false)
        if teamTarget and teamTarget == targetId then
            return true
        end
    end
    local currentState = self._stateMachine.currentState
    if not currentState then
        return false
    end
    if self._stateMachine.currentName == "CityExplorerTeamStateGoToTarget" 
            or self._stateMachine.currentName == "CityExplorerTeamStateInteractTarget" then
        if currentState._targetId and currentState._targetId == targetId then
            return true
        end
    end
    return false
end

function CityExplorerTeam:SetHideAndPause(isHideAndPause)
    self._isHideAndPause = isHideAndPause
end

function CityExplorerTeam:SetupSlgTroopTrigger(on)
    if on then
        self._teamTrigger:Show()
        self._teamTrigger:SetSelected(true)
        self._teamTrigger:SetOnClick(Delegate.GetOrCreate(self, self.OnTeamClick))
        self._teamTrigger:SetOnDrag(Delegate.GetOrCreate(self, self.OnTeamDragBegin),Delegate.GetOrCreate(self, self.OnTeamDrag),Delegate.GetOrCreate(self, self.OnTeamDragEnd))
     else
        self._teamTrigger:SetOnClick(nil)
        self._teamTrigger:SetOnDrag(nil,nil,nil)
        self._teamTrigger:SetSelected(false)
        self._teamTrigger:Hide()
     end
end

---@param teamTrigger CityExplorerTeamTrigger
function CityExplorerTeam:OnTeamClick(teamTrigger)
    local cityUid = self._mgr.city.uid
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_OPERATE_MENU, cityUid, self)
end
function CityExplorerTeam:OnTeamDragBegin()
    local event = {}
    event.position = CS.UnityEngine.Input.mousePosition
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_DRAG_BEGIN,self._teamPresetIdx,nil,event)
end
function CityExplorerTeam:OnTeamDrag()
    local event = {}
    event.position = CS.UnityEngine.Input.mousePosition
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_DRAG_UPDATE, self._teamPresetIdx,nil,event)
end
function CityExplorerTeam:OnTeamDragEnd()
    local event = {}
    event.position = CS.UnityEngine.Input.mousePosition
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_SLG_TROOP_DRAG_END, self._teamPresetIdx,nil,event)
end

function CityExplorerTeam:SetShowSelected(selected)
    if selected then
       self._teamTrigger:Show()
    end
    self._teamTrigger:SetSelected(selected)
end

---@param worldPos CS.UnityEngine.Vector3
---@param coord wds.Vector2F
---@param targetId number
---@param isTargetGround boolean
function CityExplorerTeam:GoToTarget(worldPos, targetId, isTargetGround)
    self._teamData._targetId = targetId
    self._teamData._isTargetGround = isTargetGround
    local targetConfig = ConfigRefer.CityElementData:Find(targetId)
    self._targetIsSpawner = targetConfig and targetConfig:Type() == CityElementType.Spawner
end

function CityExplorerTeam:InteractTarget(targetId)
    self._teamData._targetId = targetId
    self._teamData._isTargetGround = false
    local targetConfig = ConfigRefer.CityElementData:Find(targetId)
    self._targetIsSpawner = targetConfig and targetConfig:Type() == CityElementType.Spawner
    self._stateMachine:ReadBlackboard(CityExplorerStateDefine.BlackboardKey.TargetId)
    self._stateMachine:ReadBlackboard(CityExplorerStateDefine.BlackboardKey.TargetFromPlayerClick)
    self._stateMachine:WriteBlackboard(CityExplorerStateDefine.BlackboardKey.TargetId, targetId)
    self._stateMachine:WriteBlackboard(CityExplorerStateDefine.BlackboardKey.TargetFromPlayerClick, true)
    self._stateMachine:ChangeState("CityExplorerTeamStateInteractTarget")
end

function CityExplorerTeam:ShowPathLine(wayPoints, currentPoint)
    if self._disposed then
        return
    end
    if not wayPoints then
        return
    end
    if not self._wayPointsLine then
        self._wayPointsLine = CityUnitPathLine.GetOrCreate(self._mgr.city.CityExploreRoot, ArtResourceUtils.GetItem(ArtResourceConsts.effect_city_explorer_pathline))
    end
    self._wayPointsLine:SetLineColor(CityExplorerTeam.MarchLineColor)
    self._wayPointsLine:InitWayPoints(wayPoints, currentPoint)
end

function CityExplorerTeam:RemovePathLine()
    if self._wayPointsLine then
        CityUnitPathLine.Delete(self._wayPointsLine)
    end
    self._wayPointsLine = nil
end

---@param hero wds.Hero
function CityExplorerTeam:OnHeroEntityPathChanged(hero,_)
    if not hero or not self._currentFocusOnHero or hero.ID ~= self._currentFocusOnHero:GetEntity().ID then
        return
    end
    local path = hero.MovePathInfo.Path
    if path:Count() <= 0 then
        self:RemovePathLine()
        return
    end
    if not self._allowShowLine then
        return
    end
    local teamPos = self:GetPosition()
    if not teamPos then
        return
    end
    local city = self._mgr.city
    local wayPoints = {}
    wayPoints[#wayPoints + 1] = teamPos
    for index = #path,1,-1 do
        local value = path[index]
        local pos = city:GetWorldPositionFromCoord(value.X, value.Y)
        wayPoints[#wayPoints + 1] = pos
    end
    self:ShowPathLine(wayPoints)
end

---@param hero wds.Hero
---@param hpChanged
function CityExplorerTeam:OnHeroHpChanged(hero, hpChanged)
    local value = self._assignSEHerosHpCache[hero.ID]
    if not value then return end
    self._assignSEHerosHpCache[hero.ID] = hpChanged
    if value >= hpChanged then
        return
    end
    if self:IsInBattle() then return end
    local heroUnit = self._assignSEHeros[hero.ID]
    if not heroUnit then return end
    local seMgr = self._mgr.city.citySeManger
    local seEnv = seMgr._seEnvironment
    --- city view unload start 会清理 _seEnvironment 所以这里判下空吧
    if not seEnv then return end
    local skillMgr = seEnv:GetSkillManager()
    local skillConfig = seEnv:GetWdsManager():GetSkillConfig(10004)
    local skillCfgId = skillConfig:Id()
    local targetId = heroUnit:GetID()
    local target = heroUnit:GetActor()
    local targetPos = heroUnit:GetActor():GetPosition()
    local dummySkillInfo = wrpc.SkillInfo.New(skillCfgId, 10004, heroUnit:GetID())
    ---@type wrpc.SkillResultDamageData
    local dummyDamageData = wrpc.SkillResultDamageData.New(hpChanged - value, false, hpChanged, 0, SpecialDamageType.Heal)
    local mask = (1 << LogicUnitRuleKey.Heal) | (1 << LogicUnitRuleKey.CauseDmg)
    ---@type {msg:wrpc.SkillResultData}
    dummySkillInfo.localDummy = {
        msg = wrpc.SkillResultData.New(targetId, 0, 0, skillCfgId, 1, -1, dummyDamageData, nil, nil, mask),
    }
    local dummyMsgSkill = wrpc.SkillCastRPC.New(heroUnit:GetID(), 1, dummySkillInfo)
    local dummyServerData = wrpc.PushBattleCastSkillMessageRequest.New(0, dummyMsgSkill)
    skillMgr:CastSkillPerform(skillConfig:Asset(), wds.enum.SkillStageType.SkillStageTypeDefault, target,targetPos , target, targetPos, nil, skillConfig, dummyServerData)
end

function CityExplorerTeam:SetAllowShowLine(allow)
    self._allowShowLine = allow
    if not self._allowShowLine then
        self:RemovePathLine()
    else
        self:OnHeroEntityPathChanged(self._currentFocusOnHero and self._currentFocusOnHero:GetEntity())
    end
end

---@param targetId number
function CityExplorerTeam:TeamTurnToTargetId(elementId)
    if not elementId or not self._currentFocusOnHero then return end
    local cfg = ConfigRefer.CityElementData:Find(elementId)
    if not cfg then return end
    local pos = cfg:Pos()
    local worldPos = self._mgr.city:GetWorldPositionFromCoord(pos:X(), pos:Y())
    local actor = self._currentFocusOnHero:GetActor()
    local unitPos = actor:GetPosition()
    -- 方向与距离
    local forward = (worldPos - unitPos).normalized
    forward.y = 0
    local oldEulerAngles = actor:GetTransform().localEulerAngles
	local newEulerAngles = CS.UnityEngine.Quaternion.LookRotation(forward).eulerAngles
	local angleOffsetY = newEulerAngles.y - oldEulerAngles.y
	local rotateTime = angleOffsetY / SEPreExportDefine.ROTATE_ANGLE_PER_SECOND
    actor:SetForward(forward, rotateTime)
end

---@return boolean,number|nil
function CityExplorerTeam:CastSkillPerformOnTarget(elementId, callback)
    local teamPos = self:GetPosition()
    if not teamPos then return false end
    local cfg = ConfigRefer.CityElementData:Find(elementId)
    if not cfg then return false end
    local npcCfg = ConfigRefer.CityElementNpc:Find(cfg:ElementId())
    if not npcCfg then return false end
    local skillId = npcCfg:InteractSeSkill()
    if skillId == 0 then return false end
    local pos = cfg:Pos()
    local targetGridPos = wrpc.PBVector3.New(pos:X() + npcCfg:SizeX() * 0.5, pos:Y() + npcCfg:SizeY() * 0.5)
    local targetPosWorld = self._mgr.city:GetCenterWorldPositionFromCoord(pos:X(), pos:Y(), npcCfg:SizeX(), npcCfg:SizeY())
    local seMgr = self._mgr.city.citySeManger
    local seEnv = seMgr._seEnvironment
    local skillMgr = seEnv:GetSkillManager()
    local skillConfig = seEnv:GetWdsManager():GetSkillConfig(skillId)
    local dummyTarget = seMgr:GetOrCreateDummyUnitOnGridPos(targetGridPos.X, targetGridPos.Y)
    local distance = (targetPosWorld - teamPos).magnitude * self._mgr.city.scale
    local retTime = 0.1
    local speed = skillConfig:BulletSpeed()
    if speed > 0 then
        retTime = math.max(2, distance / speed)
    end
    skillMgr:CastSkillPerform(skillConfig:Asset(), wds.enum.SkillStageType.SkillStageTypeChant, self._currentFocusOnHero:GetActor(), self._currentFocusOnHero:GetActor():GetPosition(), dummyTarget, targetPosWorld, nil, skillConfig , nil, callback)
    return true, retTime
end

function CityExplorerTeam:InInteractState()
    local stateName = self._stateMachine:GetCurrentStateName()
    return stateName == "CityExplorerTeamStateInteractTarget"
        or stateName == "CityExplorerTeamStateWaitEnterSeBattle"
        or stateName == "CityExplorerTeamStateWaitSeBattleEnd"
        or stateName == "CityExplorerTeamStateBackToBase"
end

function CityExplorerTeam:InResWork()
    local inWork,_ = self._teamData._city.citySeManger:IsInResCollectWork(self._teamPresetIdx)
    return inWork
end

function CityExplorerTeam:IsInBattle()
    local scenePreset = self._teamData:GetScenePlayerPreset()
    return scenePreset and scenePreset.InBattle
end

function CityExplorerTeam:InExplore()
    local scenePreset = self._teamData:GetScenePlayerPreset()
    return scenePreset and scenePreset.InExplore
end

function CityExplorerTeam:InCanReSetTargetState()
    return not self:InInteractState() and not self:IsInBattle() and not self:InExplore() and (not self:InMovingState() or self._teamData:IsTargetGround())
end

function CityExplorerTeam:IsExpectSpawnerElementIdState(spawnerEleId)
    if self._teamData._targetId ~= spawnerEleId then return false end
    return self:InInteractState() and not self:InExplore() and not self:InBackState()
end

function CityExplorerTeam:InMovingState()
    local stateName = self._stateMachine:GetCurrentStateName()
    return stateName == "CityExplorerTeamStateGoToTarget"
end

function CityExplorerTeam:InBackState()
    local stateName = self._stateMachine:GetCurrentStateName()
    return stateName == "CityExplorerTeamStateBackToBase"
end

---@return number|nil
function CityExplorerTeam:GetExpectSpawnerExpeditionId()
    local preset = self._teamData:GetScenePlayerPreset()
    if not preset then return nil end
    return preset.ExpectSpawnerId
end

function CityExplorerTeam:TestNavRayCast()
    local teamPosition = self:GetPosition()
    if not teamPosition then return end
    local dir = self:GetFocusOnHeroDir()
    if not dir then return end
    local pathFinding = self._teamData._mgr.city.cityPathFinding
    local hit,hitPos = pathFinding:NavMeshRayCast(teamPosition, dir, 1, -1)
    if hitPos then
        local color = hit and CS.UnityEngine.Color.green or CS.UnityEngine.Color.red
        CS.UnityEngine.Debug.DrawLine(teamPosition, hitPos, color, 0.016)
    end
end

return CityExplorerTeam