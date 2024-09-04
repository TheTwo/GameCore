local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionRandomTarget:CitizenBTActionNode
---@field new fun():CitizenBTActionRandomTarget
---@field super CitizenBTActionNode
local CitizenBTActionRandomTarget = class('CitizenBTActionRandomTarget', CitizenBTActionNode)

function CitizenBTActionRandomTarget:Run(context, gContext)
    local citizen = context:GetCitizen()
    local citizenData = context:GetCitizenData()
    ---@type CitizenBTActionGoToContextParam
    local targetInfo = {}
    if not citizenData:IsAssignedHouse() then
        targetInfo.targetPos = citizen._pathFinder:RandomPositionInExploredZoneWithInSafeArea(citizen._pathFinder.AreaMask.CityGround)
    else
        local x,z,sX,sZ,areaMask = citizenData:GetAssignedArea()
        if x and z and sX and sZ and areaMask then
            targetInfo.targetPos = citizen._pathFinder:RandomPositionInRange(x,z,sX, sZ, areaMask)
        else
            targetInfo.targetPos = citizen._pathFinder:RandomPositionInExploredZoneWithInSafeArea(citizen._pathFinder.AreaMask.CityGround)
        end
    end
    targetInfo.dumpStr = CitizenBTDefine.DumpGotoInfo
    context:Write(CitizenBTDefine.ContextKey.GotoTargetInfo, targetInfo)
    return CitizenBTActionRandomTarget.super.Run(self, context, gContext)
end

return CitizenBTActionRandomTarget