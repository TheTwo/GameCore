local Delegate = require("Delegate")
local EventConst = require("EventConst")
local CityTileAssetBubble = require("CityTileAssetBubble")
local DBEntityPath = require("DBEntityPath")
local Utils = require("Utils")
local ModuleRefer = require("ModuleRefer")
local FurniturePageDefine = require("FurniturePageDefine")
local CityWorkType = require("CityWorkType")
local CityLegoBuildingUIParameter = require("CityLegoBuildingUIParameter")
local ConfigRefer = require("ConfigRefer")
local ManualResourceConst = require("ManualResourceConst")

---@class CityTileAssetGachaBubble:CityTileAssetBubble
---@field new fun():CityTileAssetGachaBubble
---@field super CityTileAssetGachaBubble
local CityTileAssetGachaBubble = class('CityTileAssetGachaBubble', CityTileAssetBubble)

function CityTileAssetGachaBubble:ctor()
    CityTileAssetBubble.ctor(self)
    self.isUI = true
    ---@type CS.UnityEngine.GameObject
    self._go = nil
    ---@type City3DBubbleGacha
    self._bubble = nil
end

function CityTileAssetGachaBubble:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    local cell = self.tileView.tile:GetCell()
    self.furnitureId = cell:UniqueId()
    self.configId = cell:ConfigId()
    ModuleRefer.InventoryModule:AddCountChangeListener(ModuleRefer.HeroCardModule:GetTenDrawCostItemId(), Delegate.GetOrCreate(self, self.DoRefreshBubble))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Gacha.MsgPath, Delegate.GetOrCreate(self, self.DoRefreshBubble))
end

function CityTileAssetGachaBubble:OnTileViewRelease()
    CityTileAssetBubble.OnTileViewRelease(self)
    if self.gachaTrigger then
        self.gachaTrigger:SetOnTrigger(nil, nil, false)
    end
    ModuleRefer.InventoryModule:RemoveCountChangeListener(ModuleRefer.HeroCardModule:GetTenDrawCostItemId(), Delegate.GetOrCreate(self, self.DoRefreshBubble))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Gacha.MsgPath, Delegate.GetOrCreate(self, self.DoRefreshBubble))
end

function CityTileAssetGachaBubble:OnCityFurnitureSelectionChanged(_, furnitureId)
    local hide = self.furnitureId == furnitureId
    if self.handle and hide then
        self:Hide()
    elseif not (self.handle or hide) then
        self:Show()
    end
end

function CityTileAssetGachaBubble:GetPrefabName()
    if self:ShouldShow() then
        return ManualResourceConst.ui3d_bubble_gacha
    end
    return string.Empty
end

function CityTileAssetGachaBubble:OnAssetLoaded(go, userdata)
    CityTileAssetBubble.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end

    if not self:TrySetPosToMainAssetAnchor(go.transform, "holder_3dui") then
        self:SetPosToTileWorldCenter(go)
    end

    local behaviour = go:GetLuaBehaviour("City3DBubbleGacha")
    if not behaviour or not behaviour.Instance then
        return
    end
    self._bubble = behaviour.Instance
    if not self._bubble then
        return
    end
    self.gachaTrigger = self._bubble.p_position.gameObject:GetLuaBehaviour("CityTrigger").Instance
    local callback = function()
        return self:OnClick()
    end
    self.gachaTrigger:SetOnTrigger(callback, nil, true)
    self._go = go
    self:DoRefreshBubble()
end

function CityTileAssetGachaBubble:OnAssetUnload(go, fade)
    if self._bubble then
        self._bubble = nil
    end
    CityTileAssetBubble.OnAssetUnload(self, go, fade)
end

function CityTileAssetGachaBubble:Refresh()
    local shouldShow = self:ShouldShow()
    if not shouldShow then
        self:Hide()
    end
    if not self.handle then
        self:Show()
    elseif self._bubble then
        self:DoRefreshBubble()
    end
end

function CityTileAssetGachaBubble:ShouldShow()
    local isOpen = ModuleRefer.HeroCardModule:CheckIsOpenGacha()
    return isOpen
end

function CityTileAssetGachaBubble:OnClick()
    g_Game.UIManager:Open('HeroCardMediator')
    return true
end

function CityTileAssetGachaBubble:DoRefreshBubble()
    if Utils.IsNull(self._bubble) then
        return
    end
    self._bubble:RefreshState()
end


return CityTileAssetGachaBubble
