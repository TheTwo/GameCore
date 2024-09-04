--警告：不要随意修改这个基类，否则可能导致严重的性能问题！
--asset和view都会缓存。请在回收前清空状态

---@class MapTileAsset
local MapTileAsset = class("MapTileAsset")

---@param view MapTileView
function MapTileAsset:SetView(view)
    self.view = view
end

---@return MapTileView
function MapTileAsset:GetView()
    return self.view
end

---@return number
function MapTileAsset:GetUniqueId()
    if self.view then
        return self.view:GetUniqueId()
    else
        g_Logger.Error("View was not specified: " .. self.__class.__cname)
    end
end

---@return number
function MapTileAsset:GetTypeId()
    if self.view then
        return self.view:GetTypeId()
    else
        g_Logger.Error("View was not specified: " .. self.__class.__cname)
    end
end

---@return CS.Grid.MapSystem
function MapTileAsset:GetMapSystem()
    if self.view then
        return self.view:GetMapSystem()
    else
        g_Logger.Error("View was not specified: " .. self.__class.__cname)
    end
end

---@return CS.Grid.StaticMapData
function MapTileAsset:GetStaticMapData()
    if self.view then
        return self.view:GetStaticMapData()
    else
        g_Logger.Error("View was not specified: " .. self.__class.__cname)
    end
end

function MapTileAsset:Show()
    
end

function MapTileAsset:Hide()
    
end

function MapTileAsset:Refresh()
    
end

function MapTileAsset:Release()
    
end

function MapTileAsset:OnLodChanged(oldLod, newLod)
    
end

function MapTileAsset:OnTerrainLoaded()
end

---@return number
function MapTileAsset:GetSortingOrder()
    return 0
end

return MapTileAsset