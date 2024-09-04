local ModuleRefer = require("ModuleRefer")

local KingdomPlacerBehavior = require("KingdomPlacerBehavior")

---@class KingdomPlacerBehaviorBehemothSummoner:KingdomPlacerBehavior
---@field new fun():KingdomPlacerBehaviorBehemothSummoner
---@field super KingdomPlacerBehavior
local KingdomPlacerBehaviorBehemothSummoner = class('KingdomPlacerBehaviorBehemothSummoner', KingdomPlacerBehavior)

function KingdomPlacerBehaviorBehemothSummoner:OnPlacing()
    ModuleRefer.AllianceModule.Behemoth:BuildBehemothSummoner(nil, self.context.coord.X,self.context.coord.Y, self.context.buildingConfig:Id())
end

return KingdomPlacerBehaviorBehemothSummoner