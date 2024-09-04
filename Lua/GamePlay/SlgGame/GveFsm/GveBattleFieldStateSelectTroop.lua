local Utils = require('Utils')
local State = require("State")
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local Const = require('GveBattleFieldConst')
---@class GveBattleFieldStateSelectTroop:State
---@field GetName fun():string
local cls = class('GveBattleFieldStateSelectTroop',State)

---@return string
function cls:GetName()
    -- 重载这个函数
    return 'GveBattleFieldStateSelectTroop'
end

function cls:ReEnter()
    self:Enter()
end

function cls:Enter()   
    if not self.module then
        self.module = ModuleRefer.GveModule
    end    
    -- self.timer = (self.module.stageEndTime - g_Game.ServerTime:GetServerTimestampInMilliseconds())/1000.0
    g_Game.EventManager:TriggerEvent(EventConst.GVE_BATTLEFIELD_STATE,self.module.BattleFieldState.Select,
    {
            -- duration = self.timer,
            onSelect = Delegate.GetOrCreate(self,self.OnSelectTroop)
        }
    )   

end

function cls:OnSelectTroop(index)
    self.module:SetSelectTroopIndex(index)
end

function cls:Exit()
    --TODO:Auto Select a Troop
end

---@param dt number
function cls:Tick(dt)    
    -- if self.timer > 0 then
    --     self.timer = self.timer - dt   
    --     if self.timer < 0 then
    --         self.timer = 0
    --     end
    -- end
    if self.module.curStage ~= wds.TroopCandidateStage.TroopCandidateChoosing then
        self.stateMachine:WriteBlackboard(Const.BBKeys.SelectEnd,true,true)
    end
end

return cls