local Utils = require('Utils')
local State = require("State")
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local DBEntityType = require('DBEntityType')
local Delegate = require('Delegate')
local Const = require('GveBattleFieldConst')
---@class GveBattleFieldStateBattling:State
---@field GetName fun():string
local cls = class('GveBattleFieldStateBattling',State)

---@return string
function cls:GetName()
    -- 重载这个函数
    return 'GveBattleFieldStateBattling'
end

function cls:ReEnter()
    self:Enter()
end

function cls:Enter()   
    self.timer = 0   
    self.module = ModuleRefer.GveModule
    self.troopId = self.module.selectTroopID
    -- g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.Troop,Delegate.GetOrCreate(self,self.OnTroopDestory))
    g_Game.EventManager:TriggerEvent(EventConst.GVE_BATTLEFIELD_STATE,ModuleRefer.GveModule.BattleFieldState.Battling,{})   
end
---@param data wds.Troop
-- function cls:OnTroopDestory(type,data)
--     if data.ID ~= self.troopId then return end
--     if self.module:HasBackupTroop() then
--         self.stateMachine:WriteBlackboard(Const.BBKeys.TroopDead,true,true)
--     else
--         self.stateMachine:WriteBlackboard(Const.BBKeys.AllDead,true,true)
--     end
-- end

function cls:Exit()
    -- 重载这个函数
    -- g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.Troop,Delegate.GetOrCreate(self,self.OnTroopDestory))
end

---@param dt number
function cls:Tick(dt)
    -- self.timer = self.timer + dt   
    if self.module.curStage ~= wds.TroopCandidateStage.TroopCandidateStageBattling then
        if self.module.curStage == wds.TroopCandidateStage.TroopCandidateWaiting then        
            self.stateMachine.blackboard:Write(Const.BBKeys.TroopDead,true,true)
        elseif self.module.curStage == wds.TroopCandidateStage.TroopCandidateStageObserving then
            self.stateMachine:WriteBlackboard(Const.BBKeys.AllDead,true,true)
        end
    end
end

return cls