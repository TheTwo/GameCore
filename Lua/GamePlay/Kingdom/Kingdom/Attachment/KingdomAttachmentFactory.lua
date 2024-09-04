local ObjectType = require("ObjectType")

---@class KingdomAttachmentFactory
local KingdomAttachmentFactory = class("KingdomAttachmentFactory")

---@param helper CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
---@param mapSystem CS.Grid.MapSystem
function KingdomAttachmentFactory:Initialize(helper, mapSystem)
    self.createHelper = helper
    self.mapSystem = mapSystem
end

function KingdomAttachmentFactory:Dispose()
    self.createHelper = nil
    self.mapSystem = nil
end

---@param type number @ObjectType
---@return KingdomAttachmentBase[]
function KingdomAttachmentFactory:Create(type, userData)
    local attachments = {}
    if type == ObjectType.SlgVillage then
        table.insert(attachments, require("KingdomAttachmentVillageInBattle").new(self.createHelper, self.mapSystem))
    end
    return attachments
end

return KingdomAttachmentFactory