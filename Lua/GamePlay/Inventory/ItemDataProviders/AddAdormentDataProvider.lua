local FunctionalItemDataProvider = require("FunctionalItemDataProvider")
local ModuleRefer = require("ModuleRefer")
---@class AddAdormentDataProvider : FunctionalItemDataProvider
local AddAdormentDataProvider = class("AddAdormentDataProvider", FunctionalItemDataProvider)

function AddAdormentDataProvider:CanUse()
    return self:DefaultUseChecker()
end

function AddAdormentDataProvider:Use(usageNum, callback)
    if self.uid then
        ModuleRefer.PersonaliseModule:OnUseAdornmentItem(self.uid)
    end
end

return AddAdormentDataProvider