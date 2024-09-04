local PvPTileAssetUnit = require("PvPTileAssetUnit")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local MapHUDFadeDefine = require("MapHUDFadeDefine")
local MapTileAssetUnit = require("MapTileAssetUnit")
local TileAssetPriority = require("TileAssetPriority")
local ManualResourceConst = require("ManualResourceConst")

---@class PvPTileAssetHUDIcon : PvPTileAssetUnit
---@field super PvPTileAssetUnit
---@field behavior PvPTileAssetHUDIconBehavior
---@field isSelected boolean
local PvPTileAssetHUDIcon = class("PvPTileAssetHUDIcon", PvPTileAssetUnit)
PvPTileAssetHUDIcon.PrefabName = ManualResourceConst.ui3d_bubble_building_icon

function PvPTileAssetHUDIcon:GetPosition()
    return self:CalculateCenterPosition()
end

function PvPTileAssetHUDIcon:GetPriority()
    return TileAssetPriority.Get("PvPTileAssetHUDIcon")
end

function PvPTileAssetHUDIcon:GetSyncCreate()
    return true
end

function PvPTileAssetHUDIcon:CheckLod(lod)
    return self:DisplayIcon(lod) or self:DisplayName(lod) or self:DisplayText(lod)
end

function PvPTileAssetHUDIcon:GetLodPrefabName(lod)
    if not self:CheckLod(lod) then
        return string.Empty
    end
    
    local x, y = self:GetServerCenterPosition()
    if not ModuleRefer.MapFogModule:IsFogUnlocked(x, y) then
        return string.Empty
    end
    return PvPTileAssetHUDIcon.PrefabName
end

function PvPTileAssetHUDIcon:CanShow()
    local entity = self:GetData()
    if not entity then
        return false
    end
    
    if self.isSelected then
        return false
    end
    
    local x, y = self:GetServerCenterPosition()
    if not ModuleRefer.MapFogModule:IsFogUnlocked(x, y) then
        return false
    end
    
    return true
end


function PvPTileAssetHUDIcon:OnHide()
    self.behavior = nil
    self.isSelected = false
end

function PvPTileAssetHUDIcon:OnConstructionSetup()
    local entity = self:GetData()
    if not entity then
        self:Hide()
        return
    end

    local asset = self:GetAsset()
    local comp = asset:GetLuaBehaviour("PvPTileAssetHUDIconBehavior")
    self.behavior = comp and comp.Instance
    if not self.behavior then
        self:Hide()
        return
    end
    self.behavior:Reset()
    self:OnRefresh(entity)
    self.behavior:RefreshAll()
    self.behavior:SetTrigger(Delegate.GetOrCreate(self, self.OnIconClickEvent))

    local lod = KingdomMapUtils.GetLOD()
    local displayIcon = self:DisplayIcon(lod)
    local displayText = self:DisplayText(lod)
    ModuleRefer.MapHUDModule:InitHUDFade(self.behavior.iconMaterialSetter, displayIcon)
    ModuleRefer.MapHUDModule:InitHUDFade(self.behavior.textMaterialSetter, displayText)
    self.behavior:EnableTrigger(displayIcon)
    self.behavior:ShowName(self:DisplayName(lod))
end

function PvPTileAssetHUDIcon:OnConstructionShutdown()
    PvPTileAssetHUDIcon.super.OnConstructionShutdown(self)

    self.behavior = nil
    self.isSelected = false
end

function PvPTileAssetHUDIcon:OnConstructionUpdate()
    local entity = self:GetData()
    if not entity then
        self:Hide()
        return
    end
    --self:OnRefresh(entity)
end

function PvPTileAssetHUDIcon:DoOnLodChanged(oldLod, newLod)

end

function PvPTileAssetHUDIcon:OnLodChanged(oldLod, newLod)
    --跳过 PvPTileAssetUnit 的 OnLodChanged
    PvPTileAssetHUDIcon.super.super.OnLodChanged(self, oldLod, newLod)
    if not self.behavior then
        return
    end
    local needRefreshAll = false
    self:DoOnLodChanged(oldLod, newLod)
    if self:IsIconFadeIn(oldLod, newLod) then
        needRefreshAll = true
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behavior.iconMaterialSetter, MapHUDFadeDefine.FadeIn)
        self.behavior:EnableTrigger(true)
    elseif self:IsIconFadeOut(oldLod, newLod) then
        needRefreshAll = true
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behavior.iconMaterialSetter, MapHUDFadeDefine.FadeOut)
        self.behavior:EnableTrigger(false)
    elseif self:IsIconStay(oldLod, newLod) then
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behavior.iconMaterialSetter, MapHUDFadeDefine.Show)
        self.behavior:EnableTrigger(false)
    else
        needRefreshAll = true
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behavior.iconMaterialSetter, MapHUDFadeDefine.Hide)
        self.behavior:EnableTrigger(false)
    end

    if self:IsTextFadeIn(oldLod, newLod) then
        needRefreshAll = true
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behavior.textMaterialSetter, MapHUDFadeDefine.FadeIn)
    elseif self:IsTextFadeOut(oldLod, newLod) then
        needRefreshAll = true
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behavior.textMaterialSetter, MapHUDFadeDefine.FadeOut)
    elseif self:IsTextStay(oldLod, newLod) then
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behavior.textMaterialSetter, MapHUDFadeDefine.Show)
    else
        needRefreshAll = true
        ModuleRefer.MapHUDModule:UpdateHUDFade(self.behavior.textMaterialSetter, MapHUDFadeDefine.Hide)
    end
    if needRefreshAll then
        self.behavior:RefreshAll()
    end
    self.behavior:ShowName(self:DisplayName(newLod))
end

function PvPTileAssetHUDIcon:IsIconFadeIn(oldLod, newLod)
    return not self:DisplayIcon(oldLod) and self:DisplayIcon(newLod)
end

function PvPTileAssetHUDIcon:IsIconFadeOut(oldLod, newLod)
    return self:DisplayIcon(oldLod) and not self:DisplayIcon(newLod)
end

function PvPTileAssetHUDIcon:IsIconStay(oldLod, newLod)
    return self:DisplayIcon(oldLod) and self:DisplayIcon(newLod)
end

function PvPTileAssetHUDIcon:IsTextFadeIn(oldLod, newLod)
    return not self:DisplayText(oldLod) and self:DisplayText(newLod)
end

function PvPTileAssetHUDIcon:IsTextFadeOut(oldLod, newLod)
    return self:DisplayText(oldLod) and not self:DisplayText(newLod)
end

function PvPTileAssetHUDIcon:IsTextStay(oldLod, newLod)
    return self:DisplayText(oldLod) and self:DisplayText(newLod)
end

function PvPTileAssetHUDIcon:OnIconClickEvent()
    ---@type wds.PlayerMapCreep
    local entity = self:GetData()
    if not entity then
        return
    end
    
    g_Game.EventManager:TriggerEvent(EventConst.MAP_CLICK_ICON, entity)
    
    self:OnIconClick()
end

function PvPTileAssetHUDIcon:CheckLod(lod)
    --override this
    return KingdomMapUtils.InMapNormalLod(lod) or KingdomMapUtils.InMapIconLod(lod)
end

function PvPTileAssetHUDIcon:OnRefresh(entity)
    --override this
end

function PvPTileAssetHUDIcon:OnIconClick()
    --override this
end

function PvPTileAssetHUDIcon:DisplayIcon(lod)
    --override this
    return KingdomMapUtils.InMapIconLod(lod)
end

function PvPTileAssetHUDIcon:DisplayText(lod)
    --override this
    return KingdomMapUtils.InMapNormalLod(lod) or KingdomMapUtils.InMapLowLod(lod) or KingdomMapUtils.InMapMediumLod(lod)
end

function PvPTileAssetHUDIcon:DisplayName(lod)
    --override this
    return true
end


return PvPTileAssetHUDIcon