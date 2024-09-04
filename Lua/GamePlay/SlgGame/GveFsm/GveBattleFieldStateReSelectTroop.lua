local Utils = require('Utils')
local State = require("State")
local EventConst = require('EventConst')
local ModuleRefer = require('ModuleRefer')

---@class GveBattleFieldStateReSelectTroop:State
---@field GetName fun():string
local cls = class('GveBattleFieldStateReSelectTroop',State)

---@return string
function cls:GetName()
    -- 重载这个函数
    return 'GveBattleFieldStateReSelectTroop'
end

-- function cls:ReEnter()
--     self:Enter()
-- end

-- function cls:Enter()   
--     self.timer = 30
--     g_Game.EventManager:TriggerEvent(EventConst.GVE_BATTLEFIELD_STATE,ModuleRefer.GveModule.BattleFieldState.ReSelect,{})     
-- end

-- function cls:Exit()
--     -- 重载这个函数
-- end

-- ---@param dt number
-- function cls:Tick(dt)
--     self.timer = self.timer + dt   
-- end

return cls