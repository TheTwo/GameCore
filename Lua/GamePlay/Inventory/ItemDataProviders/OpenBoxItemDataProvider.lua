local FunctionalItemDataProvider = require("FunctionalItemDataProvider")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
---@class OpenBoxItemDataProvider : FunctionalItemDataProvider
local OpenBoxItemDataProvider = class("OpenBoxItemDataProvider", FunctionalItemDataProvider)

function OpenBoxItemDataProvider:CanUse()
    return self:DefaultUseChecker()
end

function OpenBoxItemDataProvider:Use(usageNum, callback)
    if not ModuleRefer.InventoryModule:CheckIsCanUseBox(self.itemCfg:BoxParam()) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("backpack_item_overfill"))
        return
    end
    if usageNum and usageNum > 0 and self.uid then
        local UseItemParameter = require('UseItemParameter')
        local msg = UseItemParameter.new()
        msg.args.ComponentID = self.uid
        msg.args.Num = usageNum
        msg:Send()
    end
end

return OpenBoxItemDataProvider