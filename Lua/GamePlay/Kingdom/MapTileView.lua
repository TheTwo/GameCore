--警告：不要随意修改这个基类，否则可能导致严重的性能问题！
--asset和view都会缓存。请在回收前清空状态
---@class MapTileView
local MapTileView = class("MapTileView")

---@param x MapTileAsset
---@param y MapTileAsset
local function CompareAssets(x, y)
    if x == nil or y == nil then
        return false
    end

    if x == y then
        return false
    end
    
    return x:GetSortingOrder() < y:GetSortingOrder()
end

function MapTileView:ctor()
    self.assets = {}
    self.typeId = 0
    self.uniqueId = 0
    self.visible = false
end

function MapTileView:GetAssetCount()
    return #self.assets
end

function MapTileView:GetAssets()
    return self.assets
end

---@param mapSystem CS.Grid.MapSystem
---@param uniqueId number
function MapTileView:SetData(mapSystem, typeId, uniqueId)
    self.mapSystem = mapSystem
    self.staticMapData = mapSystem.StaticMapData
    self.typeId = typeId
    self.uniqueId = uniqueId
end

---@return CS.Grid.MapSystem
function MapTileView:GetMapSystem()
    return self.mapSystem
end

---@return CS.Grid.StaticMapData
function MapTileView:GetStaticMapData()
    return self.staticMapData
end

function MapTileView:GetUniqueId()
    return self.uniqueId
end

function MapTileView:GetTypeId()
    return self.typeId
end

function MapTileView:Show()
    if self.visible then
        return
    end

    self.visible = true
    table.sort(self.assets, CompareAssets)
    for _, asset in ipairs(self.assets) do
        asset:Show()
    end
end

function MapTileView:Hide()
    if not self.visible then
        return
    end
    
    self.visible = false
    for _, asset in ipairs(self.assets) do
        asset:Hide()
    end
end

function MapTileView:Refresh()
    if self.visible then
        for _, asset in ipairs(self.assets) do
            asset:Refresh()
        end
    end
end

function MapTileView:Release()
    for _, asset in ipairs(self.assets) do
        asset:Hide()
        asset:Release()
    end
    self.mapSystem = nil
end

function MapTileView:OnLodChanged(oldLod, newLod)
    for _, asset in ipairs(self.assets) do
        asset:OnLodChanged(oldLod, newLod)
    end
end

function MapTileView:OnTerrainLoaded()
    for _, asset in ipairs(self.assets) do
        asset:OnTerrainLoaded()
    end
end

---@param asset MapTileAsset
function MapTileView:AddAsset(asset)
    asset:SetView(self)
    table.insert(self.assets, asset)
end

function MapTileView:GetAsset(index)
    return self.assets[index]
end

---@return PvPTileAssetUnit
function MapTileView:GetMainAsset()
    return self.assets[1]
end

return MapTileView