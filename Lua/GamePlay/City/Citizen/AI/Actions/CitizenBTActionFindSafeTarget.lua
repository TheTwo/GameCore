local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CitizenBTDefine = require("CitizenBTDefine")

local CitizenBTActionNode = require("CitizenBTActionNode")

---@class CitizenBTActionFindSafeTarget:CitizenBTActionNode
---@field new fun():CitizenBTActionFindSafeTarget
---@field super CitizenBTActionNode
local CitizenBTActionFindSafeTarget = class('CitizenBTActionFindSafeTarget', CitizenBTActionNode)

function CitizenBTActionFindSafeTarget:Run(context, gContext)
    local pos = context:GetCurrentPos()
    if not pos then
        return false
    end
    local city = context:GetCity()
    local x, y = city:GetCoordFromPosition(pos, true)
    local currentSafeAreaId = city.safeAreaWallMgr:GetSafeAreaId(math.floor(x),  math.floor(y))
    ---@type CS.UnityEngine.Vector2|nil
    local chooseTargetPos
    local targetSafeAreaCount = ConfigRefer.CityConfig:CitizenEscapeChooseSafeZoneLength()
    if targetSafeAreaCount > 0 then
        local validZones = {}
        for i = 1, targetSafeAreaCount do
            local id = ConfigRefer.CityConfig:CitizenEscapeChooseSafeZone(i)
            if ModuleRefer.CitySafeAreaModule:IsSafeAreaValid(id) and (not currentSafeAreaId or currentSafeAreaId ~= id) then
                table.insert(validZones, id)
            end
        end
        targetSafeAreaCount = #validZones
        if targetSafeAreaCount > 0 then
            local zoneId = validZones[math.random(1, targetSafeAreaCount)]
            local has,rdGrid = city.safeAreaWallController:RandomInSafeAreaGrid(zoneId, city:GetSafeAreaSliceDataUsage())
            if not has then
                chooseTargetPos = nil
            else
                chooseTargetPos = CS.UnityEngine.Vector2(rdGrid.x, rdGrid.y)
            end
        end
    end
    if not chooseTargetPos then
        if currentSafeAreaId then
            local has,rdGrid = city.safeAreaWallController:RandomInSafeAreaGrid(currentSafeAreaId, city:GetSafeAreaSliceDataUsage())
            if has then
                chooseTargetPos = CS.UnityEngine.Vector2(rdGrid.x, rdGrid.y)
            end
        end
        if not chooseTargetPos then
            chooseTargetPos = city.safeAreaWallMgr:FindNearestSafeAreaCenter(x, y, true)
        end
    end
    if not chooseTargetPos then
        return false
    end
    context:Write(CitizenBTDefine.ContextKey.GotoTargetInfo)
    return CitizenBTActionFindSafeTarget.super.Run(self, context, gContext)
end

return CitizenBTActionFindSafeTarget