---@class KingdomAttachmentBase
---@field createHelper CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
---@field mapSystem CS.Grid.MapSystem
local KingdomAttachmentBase = class("KingdomAttachmentBase")

---@param helper CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
---@param mapSystem CS.Grid.MapSystem
function KingdomAttachmentBase:ctor(helper, mapSystem)
    self.createHelper = helper
    self.mapSystem = mapSystem
end

---@param brief wds.MapEntityBrief
---@param lod number
function KingdomAttachmentBase:Show(brief, lod)
    
end

function KingdomAttachmentBase:Hide()

end

function KingdomAttachmentBase:OnLodChange(oldLod, newLod)

end

return KingdomAttachmentBase