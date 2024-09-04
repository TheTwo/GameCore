local EventConst = require("EventConst")
local CityExplorerStateDefine = require("CityExplorerStateDefine")
local ModuleRefer = require('ModuleRefer')
local CityExplorerTeamState = require("CityExplorerTeamState")
local UIMediatorNames = require('UIMediatorNames')
local ManualResourceConst = require("ManualResourceConst")
local CityExplorerTeamDefine = require("CityExplorerTeamDefine")
local ConfigRefer = require("ConfigRefer")

---@class CityExplorerTeamStateInteractTarget:CityExplorerTeamState
---@field new fun():CityExplorerTeamStateInteractTarget
---@field super CityExplorerTeamState
local CityExplorerTeamStateInteractTarget = class('CityExplorerTeamStateInteractTarget', CityExplorerTeamState)

function CityExplorerTeamStateInteractTarget:ctor(team)
    CityExplorerTeamStateInteractTarget.super.ctor(self, team)
    self._enterIndex = 0
    self._delayFireEvent = nil
    self._delayAction = nil
end

function CityExplorerTeamStateInteractTarget:Enter()
    self._delayFireEvent = nil
    self._enterIndex = self._enterIndex + 1
    local index = self._enterIndex
    local isTargetGround = self._team._teamData:IsTargetGround()
    self._team._teamData:ResetTarget()
    local targetId = self.stateMachine:ReadBlackboard(CityExplorerStateDefine.BlackboardKey.TargetId)
    local isFromClick = self.stateMachine:ReadBlackboard(CityExplorerStateDefine.BlackboardKey.TargetFromPlayerClick) or false
    local cityId = self._team._mgr.city.uid
    self._team._teamData:MarkForceNotifyPosFlag()
    if not isTargetGround then --and (isFromClick or not ModuleRefer.GuideModule:IsPlaying()) then
        self._team:TeamTurnToTargetId(targetId)
        local continueAction = function(skipFireCatachEffect)
            if index ~= self._enterIndex then
                return
            end
            if not skipFireCatachEffect then
                local catchAudio = ConfigRefer.CityConfig:ExploreCatchPetSound()
                g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_TRIGGER_CATCH_EFFECT, cityId,targetId, ManualResourceConst.vfx_w_jing_ling_qiu_catch, ManualResourceConst.mat_vfx_w_pet_catch_body, 0.2, catchAudio)
            end
            -- g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_INTERACT_TARGET,cityId,targetId,self._team:GetPosition(), nil , isFromClick, self._team._teamPresetIdx + 1)
            self:InteractEndAction()
        end
        local castSkill,flyTime = self._team:CastSkillPerformOnTarget(targetId, nil)
        if not castSkill or not flyTime then
            continueAction(true)
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_INTERACT_TARGET,cityId,targetId,self._team:GetPosition(), nil , isFromClick, self._team._teamPresetIdx + 1)
        else
            -- g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_BUBBLE_TMP_HIDE, cityId, targetId, flyTime)
            self._delayFireEvent = flyTime
            self._delayAction = continueAction
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_INTERACT_TARGET,cityId,targetId,self._team:GetPosition(), nil , isFromClick, self._team._teamPresetIdx + 1)
        end
    else
        self:InteractEndAction()
    end
end

function CityExplorerTeamStateInteractTarget:Exit()
    self._delayFireEvent = nil
    self._enterIndex = self._enterIndex + 1
    g_Game.EventManager:TriggerEvent(EventConst.ON_TROOP_LEAVE_EVENT_TRIGGER, nil, true, self._team._teamPresetIdx + 1)
    g_Game.UIManager:CloseByName(UIMediatorNames.TouchMenuUIMediator)
end

function CityExplorerTeamStateInteractTarget:InteractEndAction()
    local actionEnum = self._team._teamData._markInteractEndAction
    self._team._teamData._markInteractEndAction = nil
    if not actionEnum then
        self.stateMachine:ChangeState("CityExplorerTeamStateIdle")
        return
    end
    if actionEnum == CityExplorerTeamDefine.InteractEndAction.ToIdle then
        self.stateMachine:ChangeState("CityExplorerTeamStateIdle")
    elseif actionEnum == CityExplorerTeamDefine.InteractEndAction.ToIdleAndResetExpectSpawnerId then
        if self._team:GetExpectSpawnerExpeditionId() ~= 0 then
            self._team._mgr:ReSetHomeSeTroopExpectSpawnerId(self._team._teamPresetIdx, 0)
        end
        self.stateMachine:ChangeState("CityExplorerTeamStateIdle")
    elseif actionEnum == CityExplorerTeamDefine.InteractEndAction.AutoRemove then
        self._team._mgr:SendDismissTeam(self._team)
    elseif actionEnum == CityExplorerTeamDefine.InteractEndAction.WaitBattleEnd then
        self.stateMachine:ChangeState("CityExplorerTeamStateWaitEnterSeBattle")
    end
end

function CityExplorerTeamStateInteractTarget:Tick(dt)
    if not self._delayFireEvent then return end
    self._delayFireEvent = self._delayFireEvent - dt
    if self._delayFireEvent > 0 then
        return
    end
    self._delayFireEvent = nil
    local action = self._delayAction
    self._delayAction = nil
    if action then
        action()
    end
end

return CityExplorerTeamStateInteractTarget

