local BaseGuideStep = require("BaseGuideStep")
local QueuedTask = require("QueuedTask")
local EventConst = require("EventConst")
---@class GotoCityGuideStep : BaseGuideStep
local GotoCityGuideStep = class("GotoCityGuideStep", BaseGuideStep)

function GotoCityGuideStep:ExecuteImpl()
    g_Logger.LogChannel('GuideModule','ExeGuideStep_GotoCity: %d)', self.id)
    local queuedTask = QueuedTask.new()
    queuedTask:WaitEvent(EventConst.CITY_SET_ACTIVE, nil, function()
        return true
    end):DoAction(function()
            self:End()
        end
    ):Start()
end

return GotoCityGuideStep