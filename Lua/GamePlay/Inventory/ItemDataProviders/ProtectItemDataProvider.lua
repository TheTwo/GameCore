local FunctionalItemDataProvider = require("FunctionalItemDataProvider")
local ModuleRefer = require("ModuleRefer")
---@class ProtectItemDataProvider : FunctionalItemDataProvider
local ProtectItemDataProvider = class("ProtectItemDataProvider", FunctionalItemDataProvider)

function ProtectItemDataProvider:CanUse()
    return self:DefaultUseChecker()
end

function ProtectItemDataProvider:Use(usageNum, callback)
    if self.uid then
        ModuleRefer.ProtectModule:OnUseProtectItem(self.uid)
    end
end

return ProtectItemDataProvider