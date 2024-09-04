local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetFurnitureBar:CityTileAssetBubble
---@field new fun():CityTileAssetFurnitureBar
local CityTileAssetFurnitureBar = class("CityTileAssetFurnitureBar", CityTileAssetBubble)
local Utils = require("Utils")
local Delegate = require("Delegate")
local ManualResourceConst = require("ManualResourceConst")

function CityTileAssetFurnitureBar:ctor()
    CityTileAssetBubble.ctor(self)
    self.selected = false
end

function CityTileAssetFurnitureBar:GetPrefabName()
    if self:CheckCanShow() then
        return ManualResourceConst.ui3d_progress_city
    end
    return string.Empty
end

function CityTileAssetFurnitureBar:CheckCanShow()
    if not CityTileAssetBubble.CheckCanShow(self) then
        return false
    end
    local cell = self.tileView.tile:GetFurnitureTypesCell()
    if not cell:ShowSelectedInfoPanel() then
        return false
    end
    return true
end

function CityTileAssetFurnitureBar:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end

    local component = go:GetLuaBehaviour("CityFurnitureBar")
    if Utils.IsNull(component) then return end

    if not self:TrySetPosToMainAssetAnchor(go.transform, "holder_levelup") then
        self:SetPosToTileWorldCenter(go)
    end

    if not self.furnitureBar then
        ---@type CityFurnitureBar
        self.furnitureBar = component.Instance
        self.furnitureBar:FeedData(self:GetCity(), self.tileView.tile:GetCell().singleId, self.selected)
    end

    if self.tileView.tile:GetCell():IsShowUpgradingBar() then
        self._needTick = true
        g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    end
end

function CityTileAssetFurnitureBar:OnAssetUnload(go)
    if self._needTick then
        g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
        self._needTick = nil
    end

    if self.furnitureBar then
        self.furnitureBar:Clear()
        self.furnitureBar = nil
    end
end

function CityTileAssetFurnitureBar:Refresh()
    local needTick = self.tileView.tile:GetCell():IsShowUpgradingBar()
    if needTick ~= self._needTick then
        if needTick then
            g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
        else
            g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
        end
        self._needTick = needTick
    end

    if self.furnitureBar then
        self.furnitureBar:Refresh()
    end
end

function CityTileAssetFurnitureBar:SetSelected(flag)
    self.selected = flag
    if self.furnitureBar then
        self.furnitureBar:SetSelected(flag)
    end
end

function CityTileAssetFurnitureBar:OnTick()
    if not self.furnitureBar then return end
    self.furnitureBar:UpdateUpgradingProcess()
end

return CityTileAssetFurnitureBar