---@class MapCreepUtils
local MapCreepUtils = class("MapCreepUtils")

local BIT_SIZE = 64

---@param patches table<number>
---@param patchId number
---@return boolean
function MapCreepUtils.GetPatchAt(patches, patchId)
    local index = math.floor(patchId / BIT_SIZE) + 1
    local num = patches[index]
    if num == nil then
        return nil
    end
    local offset = math.floor(patchId % BIT_SIZE)
    return num & (1 << offset) > 0
end

---@param patches table<number>
---@param patchId number
---@param state  boolean
function MapCreepUtils.SetPatchAt(patches, patchId, state)
    local index = math.floor(patchId / BIT_SIZE) + 1
    local num = patches[index]
    if num == nil then
        return nil
    end

    local offset = math.floor(patchId % BIT_SIZE)
    if state then
        num = num | (1 << offset)
    else
        num = num & (~(1 << offset))
    end
    patches[index] = num
end

return MapCreepUtils