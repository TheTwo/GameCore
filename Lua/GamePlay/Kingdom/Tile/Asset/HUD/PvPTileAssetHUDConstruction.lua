local PvPTileAssetHud = require("PvPTileAssetHud")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require("Utils")
local TimeFormatter = require("TimeFormatter")
local ManualResourceConst = require("ManualResourceConst")

---@class PvPTileAssetHUDConstruction : PvPTileAssetUnit
---@field behavior PvPTileAssetHUDConstructionBehavior
local PvPTileAssetHUDConstruction = class("PvPTileAssetHUDConstruction", PvPTileAssetHud)

local PrefabName = ManualResourceConst.ui3d_building

function PvPTileAssetHUDConstruction:AutoRefresh()
    return true
end

function PvPTileAssetHUDConstruction:GetPosition()
    return self:CalculateCenterPosition()
end

function PvPTileAssetHUDConstruction:GetLodPrefab(lod)
    local entity = self:GetData()
    if not entity or not entity.MapBasics then
        return string.Empty
    end

    if not self:CheckLod(lod) then
        return string.Empty
    end

    local tileX, tileZ = KingdomMapUtils.ParseBuildingPos(entity.MapBasics.Position)
    if not ModuleRefer.MapFogModule:IsFogUnlocked(tileX, tileZ) then
        return string.Empty
    end
    
    return PrefabName
end

function PvPTileAssetHUDConstruction:OnConstructionSetup()
    PvPTileAssetHUDConstruction.super.OnConstructionSetup(self)
    
    local asset = self:GetAsset()
    if Utils.IsNull(asset) then
        return
    end
    
    local luaBehaviour = asset:GetLuaBehaviour("PvPTileAssetHUDConstructionBehavior")
    self.behavior = luaBehaviour and luaBehaviour.Instance
    self:RefreshData()
end

function PvPTileAssetHUDConstruction:OnConstructionShutdown()
    self.behavior = nil
    PvPTileAssetHUDConstruction.super.OnConstructionShutdown(self)
end

function PvPTileAssetHUDConstruction:OnConstructionUpdate()
    if self:AutoRefresh() then
        self:RefreshData()
    end
end

function PvPTileAssetHUDConstruction:RefreshData()
    local entity = self:GetData()
    if not entity then
        self:Hide()
        return
    end
    
    if Utils.IsNull(self.behavior) then
        self:Hide()
        return
    end

    self.behavior:ResetAll()
    self:OnRefresh(entity)
    self.behavior:RefreshAll()
    self.behavior:LayoutVertical()
end

function PvPTileAssetHUDConstruction:OnRefresh(entity)
    --override this
end

function PvPTileAssetHUDConstruction:CheckLod(lod)
    --override this
    return not KingdomMapUtils.InSymbolMapLod(lod)
end

function PvPTileAssetHUDConstruction:RefreshStateTime(textKey, timestamp, icon)
    if not self.behavior then
        return
    end

    if not timestamp or timestamp <= 0 then
        self.behavior:ShowStateTime(false)
        return
    end

    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local remainTime = timestamp - serverTime
    if remainTime >= 0 then
        local timeStr = TimeFormatter.SimpleFormatTimeWithDay(remainTime)
        self.behavior:SetStateTime(textKey, timeStr)
        self.behavior:ShowStateTime(true)
        self.behavior:SetStateIcon(icon)
    end
end

function PvPTileAssetHUDConstruction:RefreshDurability(current, max, showText, customColor)
    if not self.behavior then
        return
    end
    
    if not current or not max then
        self.behavior:ShowDurability(false)
        return
    end
    
    if current > 0 and max > 0 and current < max then
        local color = customColor
        if not color then
            if current / max < 0.3 then
                color = ModuleRefer.MapHUDModule.colorHostile
            else
                color = ModuleRefer.MapHUDModule.colorNeutral
            end
        end
        self.behavior:SetDurability(current, max, color)
        self.behavior:ShowDurability(true)
        if showText then
            self.behavior:SetDurabilityText(current, max)
            self.behavior:ShowDurabilityText(true)
        end
    else
        self.behavior:ShowDurability(false)
        self.behavior:ShowDurabilityText(false)
    end
end

---@param army wds.Army
function PvPTileAssetHUDConstruction:RefreshTroopQuantity(troopCount, myTroopCount)
    if not self.behavior then
        return
    end
    
    if not troopCount or not myTroopCount then
        self.behavior:ShowTroopQuantity(false)
        return
    end

    if troopCount > 0 and myTroopCount > 0 then
        self.behavior:SetTroopQuantity(troopCount, myTroopCount)
        self.behavior:ShowTroopQuantity(true)
    else
        self.behavior:ShowTroopQuantity(false)
    end
end

---@param appear number
---@param pattern number
function PvPTileAssetHUDConstruction:RefreshAllianceLogo(appear, pattern)
    if not self.behavior then
        return
    end

    self.behavior:SetAllianceLogo(appear, pattern)
end

return PvPTileAssetHUDConstruction