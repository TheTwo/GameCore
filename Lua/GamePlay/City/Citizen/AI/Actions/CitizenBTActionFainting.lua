local CityCitizenDefine = require("CityCitizenDefine")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionFainting:CitizenBTActionNode
---@field new fun():CitizenBTActionFainting
---@field super CitizenBTActionNode
local CitizenBTActionFainting = class('CitizenBTActionFainting', CitizenBTActionNode)

function CitizenBTActionFainting:Enter(context, gContext)
    context:Write("_bubbleCreated", false)
    context:Write("_faintingEnd", false)
    local citizen = context:GetCitizen()
    citizen:StopMove()
    citizen:ChangeAnimatorState(CityCitizenDefine.AniClip.Logging)
    citizen:SyncInfectionVfx()
end

function CitizenBTActionFainting:Tick(dt, nowTime, context, gContext)
    if context:GetCitizenData():IsFainting() then
        if not context:Read("_bubbleCreated") then
            if context:GetCitizenData():IsReadyForWeakUp() then
                context:Write("_bubbleCreated", true)
                context:GetMgr():CreateCitizenRecoverBubble(context:GetCitizenId())
            end
        end
        return
    end
    context:Write("_faintingEnd", true)
end

function CitizenBTActionFainting:Exit(context, gContext)
    context:Write("_faintingEnd", true)
    if context:Read("_bubbleCreated") then
        context:GetMgr():RemoveCitizenRecoverBubble(context:GetCitizenId())
    end
    context:Write("_bubbleCreated", true)
end

return CitizenBTActionFainting