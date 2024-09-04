local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetFurnitureEggBubble:CityTileAssetBubble
---@field new fun():CityTileAssetFurnitureEggBubble
local CityTileAssetFurnitureEggBubble = class("CityTileAssetFurnitureEggBubble", CityTileAssetBubble)
local ManualResourceConst = require("ManualResourceConst")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local I18N = require("I18N")
local UsePetEggParameter = require("UsePetEggParameter")

function CityTileAssetFurnitureEggBubble:GetPrefabName()
    if not self:CheckCanShow() then return string.Empty end
    if not self.tileView then return string.Empty end
    if not self.tileView.tile then return string.Empty end
    ---@type CityFurniture
    local furniture = self.tileView.tile:GetCell()
    if furniture:IsLocked() then return string.Empty end
    return ManualResourceConst.ui3d_bubble_egg
end

function CityTileAssetFurnitureEggBubble:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end

    local behaviour = go:GetLuaBehaviour("CityTileAssetFurnitureEggBubbleBehaviour")
    if Utils.IsNull(behaviour) then return end
    
    ---@type CityTileAssetFurnitureEggBubbleBehaviour
    self.behaviour = behaviour.Instance
    
    local count1 = ModuleRefer.InventoryModule:GetAmountByConfigId(70071)
    local count2 = ModuleRefer.InventoryModule:GetAmountByConfigId(70072)
    local count3 = ModuleRefer.InventoryModule:GetAmountByConfigId(70073)

    local countSpecial1 = ModuleRefer.InventoryModule:GetAmountByConfigId(70068)
    local countSpecial2 = ModuleRefer.InventoryModule:GetAmountByConfigId(70069)

    self.behaviour:ClearTrigger()
    self.behaviour:ApplyEggNumber(count3, count2, count1 + countSpecial1 + countSpecial2)
    self.behaviour:ActiveTrigger(
        Delegate.GetOrCreate(self, self.OnClickEgg1),
        Delegate.GetOrCreate(self, self.OnClickEgg2),
        Delegate.GetOrCreate(self, self.OnClickEgg3)
    )
    
    self.handles = {}
    table.insert(self.handles, ModuleRefer.InventoryModule:AddCountChangeListener(70071, Delegate.GetOrCreate(self, self.OnItemCountChanged)))
    table.insert(self.handles, ModuleRefer.InventoryModule:AddCountChangeListener(70072, Delegate.GetOrCreate(self, self.OnItemCountChanged)))
    table.insert(self.handles, ModuleRefer.InventoryModule:AddCountChangeListener(70073, Delegate.GetOrCreate(self, self.OnItemCountChanged)))
    table.insert(self.handles, ModuleRefer.InventoryModule:AddCountChangeListener(70068, Delegate.GetOrCreate(self, self.OnItemCountChanged)))
    table.insert(self.handles, ModuleRefer.InventoryModule:AddCountChangeListener(70069, Delegate.GetOrCreate(self, self.OnItemCountChanged)))
end

function CityTileAssetFurnitureEggBubble:OnAssetUnload(go, fadeOut)
    if self.behaviour then
        self.behaviour:ClearTrigger()
        self.behaviour = nil
    end
    for i, handle in ipairs(self.handles) do
        handle()
    end
    self.handles = nil
end

function CityTileAssetFurnitureEggBubble:OnItemCountChanged()
    if self.behaviour == nil then return end
    local count1 = ModuleRefer.InventoryModule:GetAmountByConfigId(70071)
    local count2 = ModuleRefer.InventoryModule:GetAmountByConfigId(70072)
    local count3 = ModuleRefer.InventoryModule:GetAmountByConfigId(70073)

    local countSpecial1 = ModuleRefer.InventoryModule:GetAmountByConfigId(70068)
    local countSpecial2 = ModuleRefer.InventoryModule:GetAmountByConfigId(70069)

    self.behaviour:ApplyEggNumber(count3, count2, count1 + countSpecial1 + countSpecial2)
end

function CityTileAssetFurnitureEggBubble:OnClickEgg1()
    return self:TryOpenEgg(70073)
end

function CityTileAssetFurnitureEggBubble:OnClickEgg2()
    return self:TryOpenEgg(70072)
end

function CityTileAssetFurnitureEggBubble:OnClickEgg3()
    if ModuleRefer.InventoryModule:GetAmountByConfigId(70068) > 0 then
        return self:TryOpenEgg(70068)
    elseif ModuleRefer.InventoryModule:GetAmountByConfigId(70069) > 0 then
        return self:TryOpenEgg(70069)
    else
        return self:TryOpenEgg(70071)
    end
end

function CityTileAssetFurnitureEggBubble:TryOpenEgg(itemId)
    if ModuleRefer.PetModule:CheckIsFullPet() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("pet_num_upperbound_des"))
        return
    end

    local canUseMaxCount = ModuleRefer.PetModule:GetMaxCount() - ModuleRefer.PetModule:GetPetCount()
    local count = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
    local onceMax = 10
    local currentUseCount = math.min(count, canUseMaxCount, onceMax)

    ModuleRefer.ToastModule:BlockPower()
    local msg = UsePetEggParameter.new()
    msg.args.ItemCfgId = itemId
    msg.args.Num = currentUseCount
    msg:Send()
    return true
end

return CityTileAssetFurnitureEggBubble