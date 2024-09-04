---@class CityConstructionModeUIParameter
---@field new fun():CityConstructionModeUIParameter
---@field state number @大类型
---@field subState number @小类型-目前仅家具
---@field focusConfigId number|nil @需Focus的配置Id, 需与state相匹配使用
local CityConstructionModeUIParameter = class("CityConstructionModeUIParameter")

function CityConstructionModeUIParameter:ctor(state, subState, focusConfigId)
    self.state = state
    self.subState = subState
    self.focusConfigId = focusConfigId
end

return CityConstructionModeUIParameter