local Utils = require('Utils')
local State = require("State")
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local Const = require('GveBattleFieldConst')
---@class GveBattleFieldDeadCd:State
---@field GetName fun():string
local cls = class('GveBattleFieldDeadCd',State)

---@return string
function cls:GetName()
    -- 重载这个函数
    return 'GveBattleFieldDeadCd'
end

function cls:ReEnter()
    self:Enter()
end

function cls:Enter()   
    self.module = ModuleRefer.GveModule
    -- self.timer = (self.module.stageEndTime - g_Game.ServerTime:GetServerTimestampInMilliseconds())/1000.0
    g_Game.EventManager:TriggerEvent(EventConst.GVE_BATTLEFIELD_STATE,ModuleRefer.GveModule.BattleFieldState.DeadCd,{})
end

function cls:Exit()
    -- 重载这个函数
end

---@param dt number
function cls:Tick(dt)    
    -- if self.timer > 0 then
    --     self.timer = self.timer - dt   
    --     if self.timer < 0 then
    --         self.timer = 0
    --     end
    -- end
    if self.module.curStage ~= wds.TroopCandidateStage.TroopCandidateWaiting then
        self.stateMachine:WriteBlackboard(Const.BBKeys.WaitEnd,true,true)
    end
end

return cls