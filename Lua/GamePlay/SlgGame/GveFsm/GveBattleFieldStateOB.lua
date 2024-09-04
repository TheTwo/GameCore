local Utils = require('Utils')
local State = require("State")
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')
---@class GveBattleFieldStateOB:State
---@field GetName fun():string
local cls = class('GveBattleFieldStateOB',State)

---@return string
function cls:GetName()
    -- 重载这个函数
    return 'GveBattleFieldStateOB'
end

function cls:ReEnter()
    self:Enter()
end

function cls:Enter()       
    g_Game.EventManager:TriggerEvent(EventConst.GVE_BATTLEFIELD_STATE,ModuleRefer.GveModule.BattleFieldState.OB,{})
end

function cls:Exit()
    -- 重载这个函数
end

---@param dt number
function cls:Tick(dt)
    
end

return cls