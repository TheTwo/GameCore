local ManualResourceConst = require("ManualResourceConst")
local Delegate = require("Delegate")

---@type CS.DragonReborn.City.CityZoneSliceDataProvider
local CityZoneSliceDataProvider = CS.DragonReborn.City.CityZoneSliceDataProvider

local CityManagerBase = require("CityManagerBase")
local LoadState = CityManagerBase.LoadState

---@class CityBasicDataLoadManager:CityManagerBase
---@field new fun(city:City, ...):CityBasicDataLoadManager
---@field super CityManagerBase
local CityBasicDataLoadManager = class("CityBasicDataLoadManager", CityManagerBase)

function CityBasicDataLoadManager:ctor(city, ...)
    CityManagerBase.ctor(self, city, ...)
    ---@type CS.DragonReborn.City.ICityZoneSliceDataProviderUsage
    self.zoneSliceDataUsage = nil
    ---@type CS.DragonReborn.City.ICityZoneSliceDataProviderUsage
    self.safeAreaDataUsage = nil
    ---@type CS.DragonReborn.City.ICityZoneSliceDataProviderUsage
    self.safeAreaWallDataUsage = nil
    ---@type CS.DragonReborn.City.ISafeAreaEdgeDataUsage
    self.safeAreaEdgeDataUsage = nil
end

function CityBasicDataLoadManager:NeedLoadData()
    return true
end

function CityBasicDataLoadManager:OnDataLoadStart()
    CityBasicDataLoadManager.super.OnDataLoadStart(self)
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.TickLoadCheck))
end

function CityBasicDataLoadManager:OnDataLoadFinish()
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TickLoadCheck))
    CityBasicDataLoadManager.super.OnDataLoadFinish(self)
end

function CityBasicDataLoadManager:DoDataLoad()
    if not self.zoneSliceDataUsage then
        self.zoneSliceDataUsage = CityZoneSliceDataProvider.Get(ManualResourceConst.cityZoneSlice)
    end
    if not self.safeAreaDataUsage then
        self.safeAreaDataUsage = CityZoneSliceDataProvider.Get(ManualResourceConst.citySafeAreaSlice)
    end
    if not self.safeAreaWallDataUsage then
        self.safeAreaWallDataUsage = CityZoneSliceDataProvider.Get(ManualResourceConst.cityWallSlice)
    end
    if not self.safeAreaEdgeDataUsage then
        self.safeAreaEdgeDataUsage = CityZoneSliceDataProvider.GetEdgeData(ManualResourceConst.citySafeAreaEdge)
    end
    self.dataStatus = LoadState.Loading
    return self.dataStatus
end

function CityBasicDataLoadManager:TickLoadCheck(dt)
    if self.dataStatus ~= LoadState.Loading then
        return
    end
    if not self.zoneSliceDataUsage or not self.zoneSliceDataUsage:IsDataLoaded() then
        return
    end
    if not self.safeAreaDataUsage or not self.safeAreaDataUsage:IsDataLoaded() then
        return
    end
    if not self.safeAreaWallDataUsage or not self.safeAreaWallDataUsage:IsDataLoaded() then
        return
    end
    if not self.safeAreaEdgeDataUsage or not self.safeAreaEdgeDataUsage:IsDataLoaded() then
        return
    end
    self:DataLoadFinish()
end

function CityBasicDataLoadManager:ReleaseAllSliceData()
    if self.zoneSliceDataUsage then
        self.zoneSliceDataUsage:Dispose()
    end
    self.zoneSliceDataUsage = nil
    if self.safeAreaDataUsage then
        self.safeAreaDataUsage:Dispose()
    end
    self.safeAreaDataUsage = nil
    if self.safeAreaWallDataUsage then
        self.safeAreaWallDataUsage:Dispose()
    end
    self.safeAreaWallDataUsage = nil
    if self.safeAreaEdgeDataUsage then
        self.safeAreaEdgeDataUsage:Dispose()
    end
    self.safeAreaEdgeDataUsage = nil
end

function CityBasicDataLoadManager:DoDataUnload()
    self:ReleaseAllSliceData()
end

function CityBasicDataLoadManager:OnDispose()
   self:ReleaseAllSliceData() 
end

return CityBasicDataLoadManager