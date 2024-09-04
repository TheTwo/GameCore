---@class CityHatchEggUICellData
---@field new fun():CityHatchEggUICellData
local CityHatchEggUICellData = class("CityHatchEggUICellData")

---@param processCfg CityWorkProcessConfigCell
---@param param CityHatchEggUIParameter
function CityHatchEggUICellData:ctor(processCfg, param)
    self.processCfg = processCfg
    self.param = param
    self.isTipsCell = param:IsTipsCell()
end

return CityHatchEggUICellData