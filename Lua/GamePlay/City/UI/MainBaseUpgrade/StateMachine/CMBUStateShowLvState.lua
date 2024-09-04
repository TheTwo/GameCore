local CMBUState = require("CMBUState")
---@class CMBUStateShowLvState:CMBUState
---@field new fun():CMBUStateShowLvState
local CMBUStateShowLvState = class("CMBUStateShowLvState", CMBUState)
local I18N = require("I18N")

function CMBUStateShowLvState:Enter()
    self.autoStepDelay = 0.5
    self:AppendTableCell()
end

function CMBUStateShowLvState:AppendTableCell()
    local data = {content = I18N.Get("city_main_bui_upgrade_effect_1")}
    self.uiMediator._p_table_content:AppendData(data, 0)
end

function CMBUStateShowLvState:Tick(delta)
    self.autoStepDelay = self.autoStepDelay - delta
    if self.autoStepDelay <= 0 then
        self.uiMediator.stateMachine:ChangeState("ShowFurniture")
    end
end

function CMBUStateShowLvState:OnContinueClick()
    self.stateMachine:WriteBlackboard("isSkip", true, true)
    self.uiMediator.stateMachine:ChangeState("ShowFurniture")
end

return CMBUStateShowLvState