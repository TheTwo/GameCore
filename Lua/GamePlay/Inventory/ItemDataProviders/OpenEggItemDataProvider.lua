local FunctionalItemDataProvider = require("FunctionalItemDataProvider")
local ModuleRefer = require("ModuleRefer")
local UsePetEggParameter = require("UsePetEggParameter")
local I18N = require("I18N")
---@class OpenEggItemDataProvider : FunctionalItemDataProvider
local OpenEggItemDataProvider = class("OpenEggItemDataProvider", FunctionalItemDataProvider)

function OpenEggItemDataProvider:CanUse()
    return self:DefaultUseChecker()
end

function OpenEggItemDataProvider:Use(usageNum, callback)
    if ModuleRefer.PetModule:CheckIsFullPet() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_num_upperbound_des"))
        return
    end
    ModuleRefer.ToastModule:BlockPower()
    local msg = UsePetEggParameter.new()
    msg.args.ItemCfgId = self.itemCfgId
    msg.args.Num = usageNum
    msg:Send()
end

return OpenEggItemDataProvider