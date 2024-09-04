---@class MapBitUtility
local MapBitUtility = class("MapBitUtility")

local BIT_SIZE = 64

---@param bit64Values table<number>
---@param digit number
---@return boolean
function MapBitUtility.GetBitAt(bit64Values, digit)
    local index = math.floor(digit / BIT_SIZE) + 1
    local value = bit64Values[index]
    if value == nil then
        return false
    end
    local offset = math.floor(digit % BIT_SIZE)
    return value & (1 << offset) ~= 0
end

---@param bit64Values table<number>
---@param digit number
---@param state  boolean
function MapBitUtility.SetBitAt(bit64Values, digit, state)
    local index = math.floor(digit / BIT_SIZE) + 1
    local num = bit64Values[index]
    if num == nil then
        bit64Values[index] = 0
        num = 0
    end

    local offset = math.floor(digit % BIT_SIZE)
    if state then
        num = num | (1 << offset)
    else
        num = num & (~(1 << offset))
    end
    bit64Values[index] = num
end

---@param patches table<number>
function MapBitUtility.ResetZero(patches)
    for i, _ in ipairs(patches) do
        patches[i] = 0
    end
end

return MapBitUtility