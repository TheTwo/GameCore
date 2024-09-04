local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = {}

---@param id number
---@param name string | "'PackId'" | "'Type'" | "'Path'"| "'CapsuleHeight'"| "'CapsuleRadius'"| "'CapsuleYOffset'"| "'NmaType'"| "'NmaHeight'"| "'NmaRadius'"| "'HpYOffset'"| "'SlgRvoRadius'"| "'SlgRvoBattleRadius'"| "'SlgAttackEffect'"| "'ModelScale'"
---@return nil|string|number
function ArtResourceUtils.GetItem(id, name, idx)
    if not ArtResourceUtils.CheckID(id) then return end
    name = name or 'Path'
    local cell = ConfigRefer.ArtResource:Find(id)
    return ArtResourceUtils.CheckAndGetItem(id, cell, name, idx)
end

---@param id number
---@return string,number
function ArtResourceUtils.GetItemAndScale(id)
    if not ArtResourceUtils.CheckID(id) then return end
    local cell = ConfigRefer.ArtResource:Find(id)
    local path = ArtResourceUtils.CheckAndGetItem(id, cell, "Path") 
    local scale = ArtResourceUtils.CheckAndGetItem(id, cell, "ModelScale")
    return path, (scale and scale ~= 0) and scale or 1
end

---@param id number
---@return number
function ArtResourceUtils.GetScale(id)
    if not ArtResourceUtils.CheckID(id) then return 1 end
    local cell = ConfigRefer.ArtResource:Find(id)
    local scale = ArtResourceUtils.CheckAndGetItem(id, cell, "ModelScale")
    return (scale and scale ~= 0) and scale or 1
end

---@param id number
---@return CS.UnityEngine.Vector3
function ArtResourceUtils.GetPosition(id)
    if not ArtResourceUtils.CheckID(id) then return end
    local cell = ConfigRefer.ArtResource:Find(id)
    local x = ArtResourceUtils.CheckAndGetItem(id, cell, "ModelPosition", 1)
    local y = ArtResourceUtils.CheckAndGetItem(id, cell, "ModelPosition", 2)
    local z = ArtResourceUtils.CheckAndGetItem(id, cell, "ModelPosition", 3)
    return CS.UnityEngine.Vector3(x, y, z)
end

---@param id number
---@param name string | nil | "'Type'"| "'Path'" | "'PackId'"
---@return nil|string
function ArtResourceUtils.GetUIItem(id, name)
    if not ArtResourceUtils.CheckID(id) then return end
    name = name or 'Path'
    local cell = ConfigRefer.ArtResourceUI:Find(id)
    return ArtResourceUtils.CheckAndGetItem(id, cell, name)
end

---@param id number @see AudioConsts.lua
---@return string
function ArtResourceUtils.GetAudio(id)
    if not ArtResourceUtils.CheckID(id) then return end
    local cell = ConfigRefer.AudioConfig:Find(id)
    if not cell or cell:PlayDataLength() < 1 then
        return string.Empty
    end
    return cell:PlayData(1)
end

function ArtResourceUtils.CheckID(id)
    if not id then
        g_Logger.Warn("empty art resource id!")
        return false
    end
    return id ~= 0
end

function ArtResourceUtils.CheckAndGetItem(id, cell, name, index)
    if cell == nil then
        g_Logger.Warn("can't find art resource id=%s", id)
        return nil
    end
    if name == "Path" then
        local path = cell:Path()
        if string.IsNullOrEmpty(path) then
            g_Logger.Warn("empty res path. id=%s", id)
            return nil
        end
        return path
    else
        local item = cell[name](cell, index)
        if not item then
            g_Logger.Warn("empty item. id=%s", id)
            return nil
        end
        return item
    end
end

return ArtResourceUtils