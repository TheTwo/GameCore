---@class CityPetCountdownUpgradeTimeInfo
---@field new fun():CityPetCountdownUpgradeTimeInfo
local CityPetCountdownUpgradeTimeInfo = sealedClass("CityPetCountdownUpgradeTimeInfo")
local TimeFormatter = require("TimeFormatter")

---@param icon1 string @显示的第一个宠物图标
---@param icon2 string @显示的第二个宠物图标，当count参数>2时可以不传
---@param count number @第二个格子显示的+n，当数量<=2时不显示
---@param time number @in seconds
function CityPetCountdownUpgradeTimeInfo:ctor(icon1, icon2, count, time)
    self.icon1 = icon1
    self.icon2 = icon2
    self.count = count
    self.time = time
end

function CityPetCountdownUpgradeTimeInfo:NeedShowIcon2()
    return self.count == 2 and not string.IsNullOrEmpty(self.icon2)
end

function CityPetCountdownUpgradeTimeInfo:GetCountdownTimeStr()
    return string.format("-%s", TimeFormatter.TimerStringFormat(self.time))
end

return CityPetCountdownUpgradeTimeInfo