local CatchPetHelper = class("CatchPetHelper")

---@param furnitureData wds.CastleFurniture
---@return number, number @percent, leftSeconds
function CatchPetHelper.GetAutoPetCatchWorkInfo(furnitureData)
    local now = g_Game.ServerTime:GetServerTimestampInSeconds()
    local left = furnitureData.CastleCatchPetInfo.FinishTime.Seconds - now
    left = math.max(0, left)
    local total = furnitureData.CastleCatchPetInfo.FinishTime.Seconds - furnitureData.CastleCatchPetInfo.StartTime.Seconds
    local progress = 1 - left / total
    progress = math.clamp01(progress)
    return progress, left
end

return CatchPetHelper