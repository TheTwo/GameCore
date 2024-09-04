local Condition = require("Condition")
local Const = require('GveBattleFieldConst')

---@class NormalTransAtt2Move:Condition
local GveTransReady2Select = class('GveTransReady2Select',Condition)

---@return boolean
function GveTransReady2Select: Satisfied()    
    return self.state.stateMachine:ReadBlackboard(Const.BBKeys.ReadyEnd,true)
end
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---@class GveTransSelect2Battle:Condition
local GveTransSelect2Battle = class('GveTransSelect2Battle',Condition)

---@return boolean
function GveTransSelect2Battle: Satisfied()
    return self.state.stateMachine:ReadBlackboard(Const.BBKeys.SelectEnd,true)
end
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---@class GveTransBattle2DeadCd:Condition
local GveTransBattle2DeadCd = class('GveTransBattle2DeadCd',Condition)

---@return boolean
function GveTransBattle2DeadCd: Satisfied()
    return self.state.stateMachine:ReadBlackboard(Const.BBKeys.TroopDead,true)
end
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---@class GveTrans2OB:Condition
local GveTrans2OB = class('GveTrans2OB',Condition)

---@return boolean
function GveTrans2OB: Satisfied()
    return self.state.stateMachine:ReadBlackboard(Const.BBKeys.AllDead,true)
end
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---@class GveTransDeadCd2Select:Condition
local GveTransDeadCd2Select = class('GveTransDeadCd2Select',Condition)

---@return boolean
function GveTransDeadCd2Select: Satisfied()
    return self.state.stateMachine:ReadBlackboard(Const.BBKeys.WaitEnd,true)
end
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ---@class GveTransReSelect2Battle:Condition
-- local GveTransReSelect2Battle = class('GveTransReSelect2Battle',Condition)

-- ---@return boolean
-- function GveTransReSelect2Battle: Satisfied()
--     return false
-- end
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



return {
    ready2select = GveTransReady2Select,
    select2battle = GveTransSelect2Battle,
    battle2deadcd = GveTransBattle2DeadCd,
    any2ob = GveTrans2OB,
    deadcd2select = GveTransDeadCd2Select,
    reselect2battle = GveTransReSelect2Battle
}