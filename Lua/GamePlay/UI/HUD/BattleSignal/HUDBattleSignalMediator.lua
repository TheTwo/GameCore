---scene:scene_slg_battle_signal    

local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require('UIHelper')
local BattleSignalConfig = require("BattleSignalConfig")
local Delegate = require("Delegate")
local CSCameraUtils = CS.Grid.CameraUtils
local CSMapUtils = CS.Grid.MapUtils
local KingdomMapUtils = require("KingdomMapUtils")

---@alias SignalDataPair {data:BattleSignalData, comp:CS.DragonReborn.UI.LuaBaseComponent}

---@class HUDBattleSignalMediator : BaseUIMediator
local HUDBattleSignalMediator = class('HUDBattleSignalMediator', BaseUIMediator)

function HUDBattleSignalMediator:ctor()
    ---@type table<number, SignalDataPair>
    self.troopSignals = {}
    ---@type table<number, SignalDataPair>
    self.inViewPointSignals = {}
    ---@type table<number, BattleSignalData>
    self.outViewPointsSignals = {}
    self.viewDirty = true
    
    self.signalsPool = {}
    self.slgModule = ModuleRefer.SlgModule
end

function HUDBattleSignalMediator:OnCreate()
    self.compSignal = self:LuaBaseComponent('p_signal')
    self.compSignal:SetVisible(false)    
end

function HUDBattleSignalMediator:OnShow(param)
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdateTick))
    self.viewDirty = true
    self.baseCamera = ModuleRefer.SlgModule:GetBasicCamera()
    if self.baseCamera then
        self.baseCamera:AddTransformChangeListener(Delegate.GetOrCreate(self, self.OnCameraTransformChanged))
    end
end

function HUDBattleSignalMediator:OnHide(param)
    if self.baseCamera then
        self.baseCamera:RemoveTransformChangeListener(Delegate.GetOrCreate(self, self.OnCameraTransformChanged))
    end
    self.baseCamera = nil
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.LateUpdateTick))
end

---@param id number
---@param param wds.AllianceMapLabel
function HUDBattleSignalMediator:AddOrUpdateSignal(id, param)
    local signalData = BattleSignalConfig.MakeParameter(param)
    if not signalData then
        return
    end
    if signalData.troopId then
        self:DoAddSignal(id, signalData, self.troopSignals)
    else
        self.outViewPointsSignals[id] = signalData
        self.viewDirty = true
    end
end

---@param signalData BattleSignalData
---@param signalMap table<number, SignalDataPair>
function HUDBattleSignalMediator:DoAddSignal(id, signalData, signalMap)
    ---@type SignalDataPair
    local signalPair = signalMap[id]
    if not signalPair then
        signalPair = {}
        if #self.signalsPool > 0 then
            signalPair.comp = table.remove(self.signalsPool)
        else
            signalPair.comp = UIHelper.DuplicateUIComponent(self.compSignal, self.compSignal.transform.parent)
        end
        signalMap[id] = signalPair
    end
    signalPair.data = signalData
    signalPair.comp:FeedData(signalData)
end

---@param id number
function HUDBattleSignalMediator:RemoveSignal(id, param)
    local signal = self.troopSignals[id]
    if signal then
        self.troopSignals[id] = nil
        table.insert(self.signalsPool, signal.comp)
        signal.comp:SetVisible(false)
        return
    end
    signal = self.inViewPointSignals[id]
    if signal then
        self.inViewPointSignals[id] = nil
        table.insert(self.signalsPool, signal.comp)
        signal.comp:SetVisible(false)
        return
    end
    local outViewData = self.outViewPointsSignals[id]
    if outViewData then
        self.outViewPointsSignals[id] = nil
    end
end

function HUDBattleSignalMediator:ClearSignal()
    table.clear(self.outViewPointsSignals)
    for _, signal in pairs(self.inViewPointSignals) do
        table.insert(self.signalsPool,signal.comp)
        signal.comp:SetVisible(false)
    end
    table.clear(self.inViewPointSignals)
    for _, signal in pairs(self.troopSignals) do
        table.insert(self.signalsPool,signal.comp)
        signal.comp:SetVisible(false)
    end
    table.clear(self.troopSignals)
end

function HUDBattleSignalMediator:UpdateAllShowSignal()
    for _, value in pairs(self.troopSignals) do
        ---@type HUDBattleSignal
        local logic = value.comp.Lua
        if logic and logic.IsAtTroop then
            logic:RefreshFollowTroop()
        end
    end
end

HUDBattleSignalMediator.CheckExpend = CS.UnityEngine.Vector3(10, 0, 10)

---@param cam BasicCamera
function HUDBattleSignalMediator:OnCameraTransformChanged(cam)
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local checkCoordX = {}
    local checkCoordZ = {}
    local idArray = {}
    local vector3Array = {}
    local ret = {}
    local toOutView = {}
    for id, v in pairs(self.inViewPointSignals) do
        table.insert(checkCoordX, v.data.X)
        table.insert(checkCoordZ, v.data.Y)
        table.insert(idArray, id)
    end
    if #checkCoordX > 0 then
        CSMapUtils.CalculateCoordToWorldPositionBatch(#checkCoordX, checkCoordX, checkCoordZ, vector3Array, staticMapData)
        CSCameraUtils.CheckPointsInCameraViewAABB(cam:GetUnityCamera(), HUDBattleSignalMediator.CheckExpend, vector3Array, ret)
        for i, v in ipairs(ret) do
            if not v then
                local id = idArray[i]
                local signal = self.inViewPointSignals[id]
                if signal then
                    self.inViewPointSignals[id] = nil
                    table.insert(self.signalsPool, signal.comp)
                    signal.comp:SetVisible(false)
                    toOutView[id] = signal.data
                end
            end
        end
        checkCoordX = {}
        checkCoordZ = {}
        idArray = {}
        vector3Array = {}
        ret = {}
    end
    for id, v in pairs(self.outViewPointsSignals) do
        table.insert(checkCoordX, v.X)
        table.insert(checkCoordZ, v.Y)
        table.insert(idArray, id)
    end
    if #checkCoordX > 0 then
        CSMapUtils.CalculateCoordToWorldPositionBatch(#checkCoordX, checkCoordX, checkCoordZ, vector3Array, staticMapData)
        CSCameraUtils.CheckPointsInCameraViewAABB(cam:GetUnityCamera(), HUDBattleSignalMediator.CheckExpend, vector3Array, ret)
        for i, v in ipairs(ret) do
            if v then
                local id = idArray[i]
                local data = self.outViewPointsSignals[id]
                self.outViewPointsSignals[id] = nil
                self:DoAddSignal(id, data, self.inViewPointSignals)
            end
        end
    end
    for i, v in pairs(toOutView) do
        self.outViewPointsSignals[i] = v
    end
end

function HUDBattleSignalMediator:SetViewDirty()
    self.viewDirty = true
end

function HUDBattleSignalMediator:LateUpdateTick()
    if not self.viewDirty then
        return
    end
    self.viewDirty = false
    if self.baseCamera then
        self:OnCameraTransformChanged(self.baseCamera)
    end
end

return HUDBattleSignalMediator
