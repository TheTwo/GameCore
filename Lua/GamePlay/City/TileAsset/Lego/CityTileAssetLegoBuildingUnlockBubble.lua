local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetLegoBuildingUnlockBubble:CityTileAssetBubble
---@field new fun():CityTileAssetLegoBuildingUnlockBubble
local CityTileAssetLegoBuildingUnlockBubble = class("CityTileAssetLegoBuildingUnlockBubble", CityTileAssetBubble)
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local ColorUtil = require("ColorUtil")
local ColorConsts = require("ColorConsts")
local ConfigRefer = require("ConfigRefer")
local Delegate = require("Delegate")
local ManualResourceConst = require("ManualResourceConst")
local NumberFormatter = require("NumberFormatter")

---@param legoBuilding CityLegoBuilding
function CityTileAssetLegoBuildingUnlockBubble:ctor(legoBuilding)
    CityTileAssetBubble.ctor(self)
    self.legoBuilding = legoBuilding
    self.itemCountListeners = {}
end

function CityTileAssetLegoBuildingUnlockBubble:GetPrefabName()
    if not self:CheckCanShow() then return string.Empty end
    return ManualResourceConst.ui3d_bubble_need
end

function CityTileAssetLegoBuildingUnlockBubble:OnAssetLoaded(go, userdata, handle)
    CityTileAssetBubble.OnAssetLoaded(self, go, userdata, handle)
    if Utils.IsNull(go) then return end

    self.go = go
    local pos = self.legoBuilding:GetWorldCenter()
    local offset = self.legoBuilding.legoBluePrintCfg:BubbleHeightOffset() * self:GetCity().scale
    self.go.transform.position = pos + (CS.UnityEngine.Vector3.up * offset)

    ---@type City3DBubbleNeed
    self.bubble = go:GetLuaBehaviour("City3DBubbleNeed").Instance
    self:UpdateBubble()
end

function CityTileAssetLegoBuildingUnlockBubble:OnAssetUnload(go, fadeout)
    self:ReleaseAllItemCountListeners()
    self.bubble = nil
    self.go = nil
end

function CityTileAssetLegoBuildingUnlockBubble:UpdateBubble()
    self.bubble:Reset()
    self.bubble:ClearTrigger()
    self:ReleaseAllItemCountListeners()
    
    if not self.legoBuilding.needItemMap then return end
    
    local index = 0
    for _, v in ipairs(self.legoBuilding.needItemMap) do
        local commitCount = self.legoBuilding.commitItemMap[v.id] or 0
        local lackCount =  v.count - commitCount
        if lackCount > 0 then
            index = index + 1

            local ownCount = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
            local colorText = ownCount >= lackCount and ColorUtil.FromGammaStrToLinearStr(ColorConsts.quality_green) or ColorUtil.FromGammaStrToLinearStr(ColorConsts.warning)
            local text = string.format("<color=%s>%s</color>/%s", colorText, NumberFormatter.NumberAbbr(ownCount, true, false), NumberFormatter.NumberAbbr(lackCount, true, false))
            local itemCfg = ConfigRefer.Item:Find(v.id)
            self.bubble:AppendCustom(itemCfg:Icon(), text, false)
            
            local releaseCall = ModuleRefer.InventoryModule:AddCountChangeListener(v.id, function()
                local ownCount = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
                local colorText = ownCount >= lackCount and ColorUtil.FromGammaStrToLinearStr(ColorConsts.quality_green) or ColorUtil.FromGammaStrToLinearStr(ColorConsts.warning)
                local text = string.format("<color=%s>%s</color>/%s", colorText, NumberFormatter.NumberAbbr(ownCount, true, false), NumberFormatter.NumberAbbr(lackCount, true, false))
                local itemCfg = ConfigRefer.Item:Find(v.id)
                self.bubble:UpdateCustom(index, itemCfg:Icon(), text, false)
            end)
            self.itemCountListeners[v.id] = releaseCall
        end
    end

    self.bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickBubble), self.tileView.tile)
end

function CityTileAssetLegoBuildingUnlockBubble:ReleaseAllItemCountListeners()
    for id, releaseCall in pairs(self.itemCountListeners) do
        releaseCall()
    end
    table.clear(self.itemCountListeners)
end

function CityTileAssetLegoBuildingUnlockBubble:OnClickBubble()
    return self.legoBuilding:RequestToUnlock()
end

return CityTileAssetLegoBuildingUnlockBubble