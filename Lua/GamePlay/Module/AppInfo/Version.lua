---@class Version
---@field major number
---@field minor number
---@field patch number
local Version = {}
local VersionMt = {
    __index = {major = 0, minor = 0, patch = 0},
    __newindex = function(t, k, v) g_Logger.WarnChannel("Version", "Can't write Version table") end
}

---有元方法__eq和__lt时可以覆盖到__le，因此不写__le
function VersionMt.__eq(a, b)
    return a.major == b.major and a.minor == b.minor and a.patch == b.patch
end

function VersionMt.__lt(a, b)
    if a.major ~= b.major then
        return a.major < b.major
    end

    if a.minor ~= b.minor then
        return a.minor < b.minor
    end

    return a.patch < b.patch
end

function VersionMt.__tostring(a)
    return string.format("%d.%d.%d", a.major, a.minor, a.patch)
end

---@param major number
---@param minor number
---@param patch number
function Version.Create(major, minor, patch)
    local version = {
        major = tonumber(major),
        minor = tonumber(minor),
        patch = tonumber(patch)
    }
    setmetatable(version, VersionMt)
    return version
end

function Version.TryParse(versionStr)
    local major, minor, patch = string.match(versionStr, "(%d+)%.(%d+)%.(%d+)")
    if major and minor and patch then
        return true, Version.Create(major, minor, patch)
    end
    return false
end

function Version.Is(v)
    if type(v) == "table" and getmetatable(v) == VersionMt then
        return true
    end
    return false
end

Version.Default = Version.Create(0, 0, 0)

-- function Version.UnitTest()
--     local a = Version.Create(1, 2, 3)
--     local _, b = Version.TryParse("1.2.3")
--     assert(a == b)
--     assert(a < Version.Create(1, 2, 4))
--     assert(a <= Version.Create(1, 2, 4))
--     assert(a < Version.Create(1, 3, 0))
--     assert(a <= Version.Create(1, 3, 0))
--     assert(a < Version.Create(2, 0, 0))
--     assert(a <= Version.Create(2, 0, 0))
--     assert(a >= b)
--     assert(a > Version.Create(1, 2, 2))
--     assert(a >= Version.Create(1, 2, 2))
--     assert(a > Version.Create(1, 1, 9))
--     assert(a >= Version.Create(1, 1, 9))
--     assert(a > Version.Create(0, 9, 0))
--     assert(a >= Version.Create(0, 9, 0))
--     assert(tostring(a) == "1.2.3")
--     assert(not Version.TryParse(""))
-- end

return Version