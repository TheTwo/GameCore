local DramaStateDefeine = require("DramaStateDefine")

local LumbermillDramaState = require("LumbermillDramaState")
---@class LumbermillDramaStateWorking:LumbermillDramaState
local LumbermillDramaStateWorking = class("LumbermillDramaStateWorking", LumbermillDramaState)
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityPetAnimTriggerEvent = require("CityPetAnimTriggerEvent")

function LumbermillDramaStateWorking:Enter()
    self.handle.petUnit:PlayLoopState(self.handle:GetWorkCfgAnimName())
    self.handle.petUnit:SyncAnimatorSpeed()
    self.fakeEvtDelay = 2.5
    g_Game.EventManager:AddListener(EventConst.CITY_PET_DRAMA_LUMBERMILL_COUNTER, Delegate.GetOrCreate(self, self.OnCounterEvent))
    g_Game.EventManager:AddListener(EventConst.CITY_PET_ANIM_EVENT_TRIGGER, Delegate.GetOrCreate(self, self.OnAnimEventTrigger))
end

function LumbermillDramaStateWorking:Exit()
    g_Game.EventManager:RemoveListener(EventConst.CITY_PET_DRAMA_LUMBERMILL_COUNTER, Delegate.GetOrCreate(self, self.OnCounterEvent))
    g_Game.EventManager:RemoveListener(EventConst.CITY_PET_ANIM_EVENT_TRIGGER, Delegate.GetOrCreate(self, self.OnAnimEventTrigger))
end

function LumbermillDramaStateWorking:Tick(dt)
    if self.fakeEvtDelay and self.fakeEvtDelay > 0 then
        self.fakeEvtDelay = self.fakeEvtDelay - dt
        if self.fakeEvtDelay <= 0 then
            if self.handle.petUnit:IsModelReady() then
                self:OnCounterEvent(self.handle.petUnit._animator:GetInstanceID())
            end
            self.fakeEvtDelay = 2.5
        end
    end
end

function LumbermillDramaStateWorking:OnCounterEvent(animatorId)
    if self.handle.petUnit:IsModelReady() and animatorId == self.handle.petUnit._animator:GetInstanceID() then
        self.handle:CountPlus()
    end

    if self.handle:IsCountFull() then
        self.stateMachine:ChangeState(DramaStateDefeine.State.route)
    end
end

function LumbermillDramaStateWorking:OnAnimEventTrigger(attachPointHolder, triggerEvent)
    if triggerEvent == CityPetAnimTriggerEvent.WOOD_CUTTING then
        if self.handle.petUnit._attachPointHolder == attachPointHolder then
            self.handle:PlayTargetWoodHit()
        end
    end
end

return LumbermillDramaStateWorking