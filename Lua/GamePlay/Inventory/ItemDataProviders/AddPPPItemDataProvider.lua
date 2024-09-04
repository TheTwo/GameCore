local FunctionalItemDataProvider = require("FunctionalItemDataProvider")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
---@class AddPPPItemDataProvider : FunctionalItemDataProvider
local AddPPPItemDataProvider = class("AddPPPItemDataProvider", FunctionalItemDataProvider)

function AddPPPItemDataProvider:CanUse()
    return self:DefaultUseChecker()
end

function AddPPPItemDataProvider:Use(usageNum, callback)
    if not ModuleRefer.InventoryModule:CheckIsCanUseBox(self.itemCfg:BoxParam()) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("backpack_item_overfill"))
        return
    end
    if usageNum and usageNum > 0 and self.uid then
        local UseItemParameter = require('UseItemParameter')
        local msg = UseItemParameter.new()
        msg.args.ComponentID = self.uid
        msg.args.Num = usageNum
        msg:SendOnceCallback(self.transform, nil, nil, function (_, isSuccess)
            if isSuccess then
                if callback then
                    callback()
                end
            end
        end)
    end
end

return AddPPPItemDataProvider