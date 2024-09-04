local Utils = require('Utils')
local State = require("State")
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local Const = require('GveBattleFieldConst')
---@class GveBattleFieldStateReady:State
---@field GetName fun():string
local cls = class('GveBattleFieldStateReady',State)

---@return string
function cls:GetName()
    -- 重载这个函数
    return 'GveBattleFieldStateReady'
end

function cls:ReEnter()
    self:Enter()
end

function cls:Enter()   
    if not self.module then
        self.module = ModuleRefer.GveModule
    end
    -- if self.module:HasBackupTroop() then
        -- self.timer = (self.module.stageEndTime - g_Game.ServerTime:GetServerTimestampInMilliseconds())/1000
        g_Game.EventManager:TriggerEvent(EventConst.GVE_BATTLEFIELD_STATE,self.module.BattleFieldState.Ready,{duration = self.timer})
    -- else
    --     self.timer = -1
    --     self.stateMachine.blackboard:Write(Const.BBKeys.AllDead,true,true)
    -- end
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
    -- else
    --     self.timer = (self.module.stageEndTime - g_Game.ServerTime:GetServerTimestampInMilliseconds())/1000
    -- end
    if self.module.curStage ~= wds.TroopCandidateStage.TroopCandidateInit then
        self.stateMachine.blackboard:Write(Const.BBKeys.ReadyEnd,true,true)
    end
end

return cls