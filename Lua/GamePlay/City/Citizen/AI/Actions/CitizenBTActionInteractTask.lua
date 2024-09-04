local CityCitizenDefine = require("CityCitizenDefine")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionInteractTask:CitizenBTActionNode
---@field new fun():CitizenBTActionInteractTask
---@field super CitizenBTActionNode
local CitizenBTActionInteractTask = class('CitizenBTActionInteractTask', CitizenBTActionNode)

function CitizenBTActionInteractTask:Enter(context, gContext)
    local citizen = context:GetCitizen()
    citizen:SetIsRunning(false)
    citizen:ChangeAnimatorState(CityCitizenDefine.AniClip.Idle)
end

return CitizenBTActionInteractTask