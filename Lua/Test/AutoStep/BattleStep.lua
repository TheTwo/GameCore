local EmptyStep = require("EmptyStep")
---@class BattleStep:EmptyStep
---@field new fun():BattleStep
local BattleStep = class("BattleStep", EmptyStep)
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

function BattleStep:ctor(poses)
    self.poses = poses
    self.city = ModuleRefer.CityModule:GetMyCity()
    self.index = 1
    self.isEnteringBattle = false
    self.isFinishBattle = false
end

function BattleStep:Start()
    g_Game.EventManager:AddListener(EventConst.CITY_STATEMACHINE_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChange))

    local state = self.city.stateMachine.currentState
    if state:GetName() == "CityStateSeBattle" then
        self.isEnteringBattle = true
    end
end

function BattleStep:End()
    g_Game.EventManager:RemoveListener(EventConst.CITY_STATEMACHINE_STATE_CHANGED, Delegate.GetOrCreate(self, self.OnCityStateChange))
end

function BattleStep:OnCityStateChange(city, oldState, newState)
    if oldState:GetName() == "CityStateSeBattle" then
        self.isFinishBattle = true
    elseif newState:GetName() == "CityStateSeBattle" then
        self.isEnteringBattle = true
    end
end

function BattleStep:TryExecuted()
    if self.isFinishBattle then
        return true
    end

    if self.isEnteringBattle then
        return false
    end

    local unit = self.city.citySeManger:GetCurrentCameraFocusOnHero(0)
    if not unit then return false end

    local pos = unit:GetActor():GetPosition()
    if not pos then return false end

    local mapInfo = self.city.citySeManger._seEnvironment:GetMapInfo()
    if not mapInfo then return false end
    
    local logicPos = mapInfo:ClientPos2Server(CS.UnityEngine.Vector3(pos.x, 0, pos.z))
    local x, z = self.poses[self.index].x, self.poses[self.index].z
    local distance = math.sqrt((x - logicPos.x) ^ 2 + (z - logicPos.y) ^ 2)
    if distance < 4 then
        self.index = math.clamp(((self.index % #self.poses) + 1), 1, #self.poses)
        return false
    end

    local param = require("MoveStepParameter").new()
    param.args.DestPoint.X = x
    param.args.DestPoint.Y = z
    param:Send()
    return false
end

return BattleStep