
local StateMachine = require("StateMachine")
local CityExplorerPetStateSet = require("CityExplorerPetStateSet")
local Utils = require("Utils")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ManualResourceConst = require("ManualResourceConst")

local CityUnitActor = require("CityUnitActor")

---@class CityUnitExplorerPet:CityUnitActor
---@field new fun(id:number, type:UnitActorType):CityUnitExplorerPet
---@field super CityUnitActor
local CityUnitExplorerPet = class("CityUnitExplorerPet", CityUnitActor)

CityUnitExplorerPet._defaultBornVfx = ManualResourceConst.vfx_w_caiji_born
CityUnitExplorerPet._collectActionCD = 1

function CityUnitExplorerPet:ctor(id, type)
    CityUnitActor.ctor(self, id, type)
    self._isRunning = false
    self._stateMachine = StateMachine.new()
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
    self._goCreator = nil
    ---@type CitySeExplorerPetsLogic
    self._groupLogic = nil
    ---@type CS.DragonReborn.Utilities.FindSmoothAStarPathHelper.PathHelperHandle
    self._pathFindingHandle = nil
    self._hasTargetPos = false
    self._pathFindingIndex = 0
    self._needFollow = false
    self._needInBattleHide = false
    self._bornVfxHandle = nil
    self._showBornVfxTime = nil
    self._showHideVfxTime = nil
    ---@type CS.DragonReborn.VisualEffect.VisualEffectBase
    self._bornVfx = nil
    
    ---@type {prefabName:string, playTime:number, handle:CS.DragonReborn.AssetTool.PooledGameObjectHandle}[]
    self._playVfxList = {}
    self._extraLoadedMat = nil
    self._attatchVfxMatName = string.Empty
    ---@type CS.UnityEngine.Renderer[]
    self._loadedRenders = nil
    self._tickAttachMatEffect = nil
    self._tickAttachMatEffectTotal = 1
    self._lastCollecActionEnterCDEnd = 0
end

---@param explorerId number
---@param asset string
---@param creator CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
---@param moveAgent UnitMoveAgent
---@param config UnitActorConfigWrapper
---@param pathFinder CityPathFinding
---@param pathHeightFixer fun(pos:CS.UnityEngine.Vector3):CS.UnityEngine.Vector3|nil
---@param seMgr CitySeManager
---@param linkHeroEntity wds.Hero
function CityUnitExplorerPet:Init(petId, asset, creator, moveAgent, config, pathFinder, pathHeightFixer, seMgr, linkHeroEntity, seNpcConfigId)
    self.petId = petId
    self._goCreator = creator
    self._seMgr = seMgr
    self._linkHeroId = linkHeroEntity.ID
    self._seNpcConfigId = seNpcConfigId
    self._presetIndex = linkHeroEntity.BasicInfo.PresetIndex
    CityUnitActor.Init(self, asset, creator, moveAgent, config, pathFinder, pathHeightFixer)

    self._stateMachine.allowReEnter = true
    for k, v in pairs(CityExplorerPetStateSet) do
        self._stateMachine:AddState(k, v.new(self))
    end
    self:SetupEvent(true)
    self._stateMachine:ChangeState("CityExplorerPetStateEnter")
end

function CityUnitExplorerPet:Tick(delta)
    CityUnitActor.Tick(self, delta)
    self._stateMachine:Tick(delta)
    if self._hasTargetPos and (not self._pathFindingHandle) then
        if not self._moveAgent._isMoving then
            self._hasTargetPos = false
        end
    end
    if self._showBornVfxTime then
        self._showBornVfxTime = self._showBornVfxTime - delta
        if self._showBornVfxTime <= 0 then
            self._showBornVfxTime = nil
            if Utils.IsNotNull(self._bornVfx) then
                self._bornVfx:Stop()
                self._bornVfx.gameObject:SetVisible(false)
            end
        end
    end
    for i = #self._playVfxList, 1, -1 do
        local effect = self._playVfxList[i]
        effect.playTime = effect.playTime - delta
        if effect.playTime <= 0 then
            effect.handle:Delete()
            table.remove(self._playVfxList, i)
        end
    end
    if self._extraLoadedMat and self._tickAttachMatEffect then
        self._tickAttachMatEffect = self._tickAttachMatEffect - delta
        if self._tickAttachMatEffect <= 0 then
            self._tickAttachMatEffect = nil
            self:ClearUpOldAttachMaterial()
        else
            local alpha = 1 - math.inverseLerp(0, self._tickAttachMatEffectTotal, self._tickAttachMatEffect)
            self._extraLoadedMat:SetFloat("_Alpha", alpha)
        end
    end
    if self._moveGridHandle then
        local x,y = self._seMgr.city:GetCoordFromPosition(self._moveAgent._currentPosition)
        self._moveGridHandle:refreshPos(x, y)
    end
end

function CityUnitExplorerPet:SetIsRunning(isRunning)
    if self._isRunning == isRunning then
        return
    end
    self._isRunning = isRunning
    if self._isRunning then
        self._moveAgent._speed = self._config:RunSpeed()
    else
        self._moveAgent._speed = self._config:WalkSpeed()
    end
end

function CityUnitExplorerPet:SetTempSpeedMutli(mutli)
    self._moveAgent:SetTempSpeedMutli(mutli)
end

function CityUnitExplorerPet:WhenModelReady(model)
    CityUnitActor.WhenModelReady(self, model)
    if Utils.IsNull(self.model) then
        return
    end
    local fbxTrans = self.model:Transform():GetChild(0)
    fbxTrans.localScale = CS.UnityEngine.Vector3.one
    self.model:SetScale(self._config:ModelScale())
    self.model:SetGoLayer("City")
    local agent = self._moveAgent
    local displayPos = self._pathHeightFixer and self._pathHeightFixer(agent._currentPosition) or agent._currentPosition
    self.model:SetWorldPositionAndDir(displayPos, agent._currentDirectionNoPitch)
    self._loadedRenders = self.model._go:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))
    self:SetupAttachRenderMat()
    if Utils.IsNull(self._animator) then
        return
    end
    self._animator:CrossFade(self._state, 0)
end

function CityUnitExplorerPet:Dispose()
    self:SetupEvent(false)
    self:ReleasePathFindingHandle()
    if self._moveGridHandle then
        self._moveGridHandle:dispose()
    end
    self._moveGridHandle = nil
    if self._groupLogic then
        self._groupLogic:ClearUnitWork(self)
        self._groupLogic:RemovePet(self)
    end
    self._stateMachine:ClearAllStates()
    self._stateMachine = nil
    CityUnitActor.Dispose(self)
    if self._bornVfxHandle then
        self._bornVfxHandle:Delete()
        self._bornVfxHandle = nil
    end
    self._bornVfx = nil
    self._showBornVfxTime = nil
    for _, value in pairs(self._playVfxList) do
        value.handle:Delete()
    end
    table.clear(self._playVfxList)
    self:ClearUpOldAttachMaterial()
    self._loadedRenders = nil
end

---@param logic CitySeExplorerPetsLogic
function CityUnitExplorerPet:SetGroupLogic(logic)
    self._groupLogic = logic
end

function CityUnitExplorerPet:StopMove(pos, dir)
    self:ReleasePathFindingHandle()
    pos = pos or self._moveAgent._currentPosition
    if pos then
        self._moveAgent:StopMove(pos, dir)
    end
end

---@param targetPos CS.UnityEngine.Vector3
---@param startCallBack fun(p:CS.UnityEngine.Vector3[], agent:UnitMoveAgent)
---@param limitMoveTime number|nil
function CityUnitExplorerPet:MoveToTargetPos(targetPos, startCallBack)
    self._hasTargetPos = true
    local oldHandle = self._pathFindingHandle
    self._pathFindingIndex = self._pathFindingIndex + 1
    local index = self._pathFindingIndex
    self._pathFindingHandle = self._pathFinder:FindPath(self._moveAgent._currentPosition, targetPos ,
            self._pathFinder.AreaMask.CityAllWalkable,function(p)
                if self._pathFindingIndex ~= index then
                    return
                end
                self:ReleasePathFindingHandle()
                if not p or #p <= 1 then
                    self:StopMove(targetPos)
                else
                    self:MoveUseWaypoints(p, startCallBack)
                end
            end)
    if oldHandle then
        oldHandle:Release()
    end
end

function CityUnitExplorerPet:ReleasePathFindingHandle()
    if not self._pathFindingHandle then return end
    self._pathFindingHandle:Release()
    self._pathFindingIndex = self._pathFindingIndex + 1
    self._pathFindingHandle = nil
end

function CityUnitExplorerPet:MoveUseWaypoints(wayPoints, startCallBack)
    self._moveAgent:StopMove(self._moveAgent._currentPosition)
    self._moveAgent:BeginMove(wayPoints)
    if startCallBack then
        startCallBack(wayPoints, self._moveAgent)
    end
end

function CityUnitExplorerPet:SetupEvent(add)
    if not self._eventAdd and add then
        g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.MsgPath, Delegate.GetOrCreate(self, self.OnScenePlayerPresetChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.Hero.MapStates.Moving.MsgPath, Delegate.GetOrCreate(self, self.OnHeroStatusChanged))
    elseif self._eventAdd and not add then
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.MsgPath, Delegate.GetOrCreate(self, self.OnScenePlayerPresetChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Hero.MapStates.Moving.MsgPath, Delegate.GetOrCreate(self, self.OnHeroStatusChanged))
    end
end

---@param entity wds.Hero
function CityUnitExplorerPet:OnHeroStatusChanged(entity, _)
    if not entity or entity.ID ~= self._linkHeroId then
        return
    end
    self._needFollow = entity.MapStates.Moving
end

---@param entity wds.ScenePlayer
function CityUnitExplorerPet:OnScenePlayerPresetChanged(entity, _)
    if not entity or entity.Owner.PlayerID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    self._needInBattleHide = false
    for _, preset in pairs(entity.ScenePlayerPreset.PresetList) do
        if preset.PresetIndex == self._presetIndex then
            self._needInBattleHide = preset.InBattle
            return
        end
    end
end

function CityUnitExplorerPet:PlayBornEffect()
    self._showBornVfxTime = 1
    if Utils.IsNotNull(self._bornVfx) then
        self._bornVfx.gameObject:SetVisible(true)
        self._bornVfx:ResetEffect()
        self._bornVfx:Play()
        return
    end
    if not self.model then return end
    if not self.model:IsReady() then return end
    local parent = self.model:Transform()
    if Utils.IsNull(parent) then return end
    if self._bornVfxHandle then return end
    self._bornVfxHandle = self._goCreator:Create(CityUnitExplorerPet._defaultBornVfx, parent, Delegate.GetOrCreate(self, self.OnBornVfxCreated))
end

---@param go CS.UnityEngine.GameObject
function CityUnitExplorerPet:OnBornVfxCreated(go, userData)
    if Utils.IsNull(go) then return end
    go:SetVisible(false)
    go:SetLayerRecursively("City")
    self._bornVfx = go:GetComponent(typeof(CS.DragonReborn.VisualEffect.VisualEffectBase))
    if Utils.IsNull(self._bornVfx) then return end
    self._bornVfx.autoPlay = false
    self._bornVfx.autoDelete = false
    if self._showBornVfxTime and self._showBornVfxTime > 0 then
        self._bornVfx.gameObject:SetVisible(true)
        self._bornVfx:ResetEffect()
        self._bornVfx:Play()
    end
end

function CityUnitExplorerPet:RemoveEffect(prefabName)
    for i = #self._playVfxList, 1, -1 do
        local effect = self._playVfxList[i]
        if effect.prefabName == prefabName then
            table.remove(self._playVfxList, i)
            effect.handle:Delete()
            break
        end
    end
end

function CityUnitExplorerPet:PlayEffect(prefabName, playTime, notUnderTrans)
    self:RemoveEffect(prefabName)
    self:ClearUpOldAttachMaterial()
    if not self.model then return end
    if not self.model:IsReady() then return end
    local parent = self.model:Transform()
    if Utils.IsNull(parent) then return end
    local param = {notUnderTrans = notUnderTrans, parent = parent}
    if notUnderTrans then
        parent = nil
    end
    local handle = self._goCreator:Create(prefabName, parent, Delegate.GetOrCreate(self, self.OnNormalVfxCreated), param)
    ---@type {prefabName:string, playTime:number, handle:CS.DragonReborn.AssetTool.PooledGameObjectHandle}
    local effect = {}
    effect.prefabName = prefabName
    effect.playTime = playTime
    effect.handle = handle
    table.insert(self._playVfxList, effect)
end

---@param go CS.UnityEngine.GameObject
---@param userData {notUnderTrans:boolean, parent:CS.UnityEngine.Transform}
function CityUnitExplorerPet:OnNormalVfxCreated(go, userData)
    if Utils.IsNull(go) then return end
    if userData and userData.notUnderTrans and Utils.IsNotNull(userData.parent) then
        local t = go.transform
        t.position = userData.parent.position
        t.localScale = userData.parent.lossyScale
        t.rotation = userData.parent.rotation
    end
    go:SetLayerRecursively("City")
    go:SetVisible(true)
    self:PlayAttachMaterialEffect()
end

function CityUnitExplorerPet:PlayAttachMaterialEffect()
    self._tickAttachMatEffect = self._tickAttachMatEffectTotal
    self:AttachRenderMat(ManualResourceConst.mat_vfx_w_pet_catch_body)
end

function CityUnitExplorerPet:ClearUpOldAttachMaterial()
    self._tickAttachMatEffect = nil
    local lastMat = self._extraLoadedMat
    if lastMat and self._loadedRenders then
        for renderIdx = 0, self._loadedRenders.Length - 1 do
            local renderer = self._loadedRenders[renderIdx]
            if Utils.IsNotNull(renderer) then
                local materials = renderer.sharedMaterials
                if materials then
                    for i = materials.Length - 1, 0, -1 do
                        if materials[i] == lastMat then
                            renderer:ReduceMaterial(i)
                        end
                    end
                end
            end
        end
    end
    if Utils.IsNotNull(self._extraLoadedMat) then
        CS.UnityEngine.Object.Destroy(self._extraLoadedMat)
    end
    if not string.IsNullOrEmpty(self._attatchVfxMatName) then
        g_Game.MaterialManager.manager:UnloadMaterial(self._attatchVfxMatName)
    end
    self._extraLoadedMat = nil
    self._attatchVfxMatName = string.Empty
end

function CityUnitExplorerPet:SetupAttachRenderMat()
    if not self._extraLoadedMat then return end
    if not self._loadedRenders then return end
    for renderIdx = 0, self._loadedRenders.Length - 1 do
        local renderer = self._loadedRenders[renderIdx]
        local materials = renderer.materials
        local newMaterials = CS.System.Array.CreateInstance(typeof(CS.UnityEngine.Material), materials.Length + 1)
        newMaterials[materials.Length] = self._extraLoadedMat
        for i = 0, materials.Length - 1 do
            newMaterials[i] = materials[i]
        end
        renderer.materials = newMaterials
    end
end

---@return CS.UnityEngine.Material
function CityUnitExplorerPet:AttachRenderMat(materialName)
    if self._attatchVfxMatName == materialName then return end
    self:ClearUpOldAttachMaterial()
    self._attatchVfxMatName = materialName
    local baseMat = g_Game.MaterialManager.manager:LoadMaterial(materialName)
    if Utils.IsNotNull(baseMat) then
        self._extraLoadedMat = CS.UnityEngine.Object.Instantiate(baseMat)
    end
    self:SetupAttachRenderMat()
    return self._extraLoadedMat
end

function CityUnitExplorerPet:IsInBattleState()
    local currentStateName = self._stateMachine:GetCurrentStateName()
    return currentStateName == "CityExplorerPetStateHideInBattle" or currentStateName == "CityExplorerPetStateRecoverFromSeBattle"
end

function CityUnitExplorerPet:MarkCollectActionCD()
    self._lastCollecActionEnterCDEnd = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + CityUnitExplorerPet._collectActionCD
end

function CityUnitExplorerPet:InCollectActionCD()
    return self._lastCollecActionEnterCDEnd >= g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
end

---@param provider CityUnitMoveGridEventProvider
function CityUnitExplorerPet:AttachMoveGridListener(provider)
    if self._moveGridHandle then
        self._moveGridHandle:dispose()
    end
    local x,y = self._seMgr.city:GetCoordFromPosition(self._moveAgent._currentPosition)
    self._moveGridHandle = provider:AddUnit(x,y, provider.UnitType.Explorer)
end

return CityUnitExplorerPet