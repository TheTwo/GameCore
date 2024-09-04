local ModuleRefer = require("ModuleRefer")

local KingdomPlacerBehavior = require("KingdomPlacerBehavior")

---@class KingdomPlacerBehaviorBehemothDevice:KingdomPlacerBehavior
---@field new fun():KingdomPlacerBehaviorBehemothDevice
---@field super KingdomPlacerBehavior
local KingdomPlacerBehaviorBehemothDevice = class('KingdomPlacerBehaviorBehemothDevice', KingdomPlacerBehavior)

function KingdomPlacerBehaviorBehemothDevice:OnPlacing()
    ModuleRefer.AllianceModule.Behemoth:BuildBehemothDevice(nil, self.context.coord.X,self.context.coord.Y, self.context.buildingConfig:Id())
end

return KingdomPlacerBehaviorBehemothDevice