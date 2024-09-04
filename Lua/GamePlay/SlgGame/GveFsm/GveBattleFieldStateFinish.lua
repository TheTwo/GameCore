local Utils = require('Utils')
local State = require("State")

---@class GveBattleFieldStateFinish:State
---@field GetName fun():string
local cls = class('GveBattleFieldStateFinish',State)

---@return string
function cls:GetName()
    -- 重载这个函数
    return 'GveBattleFieldStateFinish'
end

function cls:ReEnter()
    self:Enter()
end

function cls:Enter()   
    --TODO:Win or Lose
    -- g_Game.UIManager:Open('')
end

function cls:Exit()
    -- 重载这个函数
end

---@param dt number
function cls:Tick(dt)
    
end

return cls