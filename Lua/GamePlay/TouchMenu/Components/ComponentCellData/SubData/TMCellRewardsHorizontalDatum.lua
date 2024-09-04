local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")

local TMCellRewardBase = require("TMCellRewardBase")

---@class TMCellRewardsHorizontalDatumCellData
---@field itemPayload ItemIconData
---@field petPayload UIPetIconData
---@field imagePayload string

---@class TMCellRewardsHorizontalDatum:TMCellRewardBase
---@field new fun(cells:TMCellRewardsHorizontalDatumCellData[]):TMCellRewardsHorizontalDatum
---@field super TMCellRewardBase
local TMCellRewardsHorizontalDatum = class('TMCellRewardsHorizontalDatum', TMCellRewardBase)

---@param cells TMCellRewardsHorizontalDatumCellData[]
function TMCellRewardsHorizontalDatum:ctor(cells, content)
    self.cells = cells or {}
    self.content = content or nil
end

function TMCellRewardsHorizontalDatum:GetPrefabIndex()
    return 4
end

return TMCellRewardsHorizontalDatum
