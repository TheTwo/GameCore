---@class CityManagerBase
---@field new fun():CityManagerBase
local CityManagerBase = class("CityManagerBase")
local I18N = require("I18N")
local LoadState = {
    None = 0,
    NotStart = 1,
    Loading = 2,
    Loaded = 3,
    PartialLoading = 4,
    PartialLoaded = 5,
}
CityManagerBase.LoadState = LoadState
local EnableLog = false

function CityManagerBase.OrderByPriority(l, r)
    return l.priority < r.priority
end

---@param city MyCity
---@vararg CityManagerBase
function CityManagerBase:ctor(city, ...)
    self.city = city
    self.basicResourceStatus = self:NeedLoadBasicAsset() and LoadState.NotStart or LoadState.None
    self.dataStatus = self:NeedLoadData() and LoadState.NotStart or LoadState.None
    self.viewStatus = self:NeedLoadView() and LoadState.NotStart or LoadState.None
    self.dependencies = {...}
    self.priority = self:CalculatePriority()
end

---同一类别(BasicRes/Data/View)的依赖，当依赖对象未加载完成时，不会加载自身
---@generic T : CityManagerBase
---@param manager T 
function CityManagerBase:AddDependency(manager)
    table.insert(self.dependencies, manager)
    self.priority = self:CalculatePriority()
    return self
end

---当基础资源加载开始时，所有Manager都会收到通知
function CityManagerBase:OnBasicResourceLoadStart()
    ---override this
    if EnableLog then
        self._resLoadFirstTryStart = CS.UnityEngine.Time.realtimeSinceStartup
    end
end

function CityManagerBase:TryDoBasicResourceLoad()
    local time = CS.UnityEngine.Time.realtimeSinceStartup
    if #self.dependencies == 0 then
        if EnableLog then
            g_Logger.TraceChannel("CityManagerBase", "[%s]BasicResourceLoad Start at %.2f", GetClassName(self), time)
            self._resLoadRealStart = time
        end
        return self:DoBasicResourceLoad()
    end

    for _, v in ipairs(self.dependencies) do
        if v.basicResourceStatus ~= LoadState.Loaded and v.basicResourceStatus ~= LoadState.None then
            return LoadState.NotStart
        end
    end
    if EnableLog then
        g_Logger.TraceChannel("CityManagerBase", "[%s]BasicResourceLoad Start at %.2f", GetClassName(self), time)
        self._resLoadRealStart = time
    end
    return self:DoBasicResourceLoad()
end

---执行基础资源加载，仅当NeedLoadBasicAsset返回true时才会执行
---@protected
---@return number @LoadState
function CityManagerBase:DoBasicResourceLoad()
    return self:BasicResourceLoadFinish()
end

---当所有基础资源加载完毕时，所有Manager都会收到通知
function CityManagerBase:OnBasicResourceLoadFinish()
    ---override this
end

---当数据加载开始时，所有Manager都会收到通知
function CityManagerBase:OnDataLoadStart()
    ---override this
    if EnableLog then
        self._dataLoadFirstTryStart = CS.UnityEngine.Time.realtimeSinceStartup
    end
end

function CityManagerBase:TryDoDataLoad()
    local time = CS.UnityEngine.Time.realtimeSinceStartup
    if #self.dependencies == 0 then
        if EnableLog then
            g_Logger.TraceChannel("CityManagerBase", "[%s]DataLoad Start at %.2f", GetClassName(self), time)
            self._dataLoadRealStart = time
        end
        return self:DoDataLoad()
    end

    for _, v in ipairs(self.dependencies) do
        if v.dataStatus ~= LoadState.Loaded and v.dataStatus ~= LoadState.None then
            return LoadState.NotStart
        end
    end
    if EnableLog then
        g_Logger.TraceChannel("CityManagerBase", "[%s]DataLoad Start at %.2f", GetClassName(self), time)
        self._dataLoadRealStart = time
    end
    return self:DoDataLoad()
end

---执行数据加载，仅当NeedLoadData返回true时才会执行
---@protected
---@return number @LoadState
function CityManagerBase:DoDataLoad()
    return self:DataLoadFinish()
end

---当所有数据加载完毕时，所有Manager都会收到通知
function CityManagerBase:OnDataLoadFinish()
    ---override this
end

---当表现层加载开始时，所有Manager都会收到通知
function CityManagerBase:OnViewLoadStart()
    ---override this
    if EnableLog then
        self._viewLoadFirstTryStart = CS.UnityEngine.Time.realtimeSinceStartup
    end
end

function CityManagerBase:TryDoViewLoad()
    local time = CS.UnityEngine.Time.realtimeSinceStartup
    if #self.dependencies == 0 then
        if EnableLog then
            g_Logger.TraceChannel("CityManagerBase", "[%s]ViewLoad Start at %.2f", GetClassName(self), time)
            self._viewLoadRealStart = time
        end
        return self:DoViewLoad()
    end

    for _, v in ipairs(self.dependencies) do
        if v.viewStatus ~= LoadState.Loaded and v.viewStatus ~= LoadState.None then
            return LoadState.NotStart
        end
    end
    if EnableLog then
        g_Logger.TraceChannel("CityManagerBase", "[%s]ViewLoad Start at %.2f", GetClassName(self), time)
        self._viewLoadRealStart = time
    end
    return self:DoViewLoad()
end

---执行表现层加载，仅当NeedLoadView返回true时才会执行
---@protected
---@return number @LoadState
function CityManagerBase:DoViewLoad()
    return self:ViewLoadFinish()
end

---当所有表现层加载完毕时，所有Manager都会收到通知
function CityManagerBase:OnViewLoadFinish()
    ---override this
end

---当表现层卸载开始时，所有Manager都会收到通知
function CityManagerBase:OnViewUnloadStart()
    
end

---执行表现层卸载，仅当NeedLoadView返回true时才会执行
function CityManagerBase:DoViewUnload()
    ---override this
end

---当所有表现层卸载完毕时，所有Manager都会收到通知
function CityManagerBase:OnViewUnloadFinish()
    ---override this
end

---当数据卸载开始时，所有Manager都会收到通知
function CityManagerBase:OnDataUnloadStart()
    ---override this
end

---执行数据卸载，仅当NeedLoadData返回true时才会执行
function CityManagerBase:DoDataUnload()
    ---override this
end

---当所有数据卸载完毕时，所有Manager都会收到通知
function CityManagerBase:OnDataUnloadFinish()
    ---override this
end

---当基础资源卸载开始时，所有Manager都会收到通知
function CityManagerBase:OnBasicResourceUnloadStart()
    ---override this
end

---执行基础资源卸载，仅当NeedLoadBasicAsset返回true时才会执行
function CityManagerBase:DoBasicResourceUnload()
    ---override this
end

---当所有基础资源卸载完毕时，所有Manager都会收到通知
function CityManagerBase:OnBasicResourceUnloadFinish()
    ---override this
end

function CityManagerBase:NeedLoadBasicAsset()
    return false
end

function CityManagerBase:NeedLoadData()
    return false
end

function CityManagerBase:NeedLoadView()
    return false
end

---当City OnEnable时，所有Manager都会收到通知
function CityManagerBase:OnCityActive()
    ---override this
end

---当City OnDisable时，所有Manager都会收到通知
function CityManagerBase:OnCityInactive()
    ---override this
end

---当BasicCamera加载完成时，所有Manager都会收到通知
---@param camera BasicCamera
function CityManagerBase:OnCameraLoaded(camera)
    ---override this
end

---当BasicCamera卸载时，所有Manager都会收到通知
function CityManagerBase:OnCameraUnload()
    ---override this
end

---@protected
---@return number @LoadState
function CityManagerBase:BasicResourceLoadFinish()
    self.basicResourceStatus = LoadState.Loaded
    self.city:OnSingleBasicResourceManagerFinish(self)
    if EnableLog then
        local cost = CS.UnityEngine.Time.realtimeSinceStartup - self._resLoadFirstTryStart
        local wait = self._resLoadRealStart - self._resLoadFirstTryStart
        local realCost = CS.UnityEngine.Time.realtimeSinceStartup - self._resLoadRealStart
        g_Logger.TraceChannel("CityManager_LoadCost", "[%s]BasicResourceLoad cost %.2f(wait:%.2f, realCost:%.2f)", GetClassName(self), cost, wait, realCost)
    end
    return self.basicResourceStatus
end

function CityManagerBase:BasicResourceLoadFailed()
    self.city:OnBasicResourceLoadFailed(self)
end

---@protected
---@return number @LoadState
function CityManagerBase:DataLoadFinish()
    self.dataStatus = LoadState.Loaded
    self.city:OnSingleDataManagerLoadFinish(self)
    if EnableLog then
        local cost = CS.UnityEngine.Time.realtimeSinceStartup - self._dataLoadFirstTryStart
        local wait = self._dataLoadRealStart - self._dataLoadFirstTryStart
        local realCost = CS.UnityEngine.Time.realtimeSinceStartup - self._dataLoadRealStart
        g_Logger.TraceChannel("CityManager_LoadCost", "[%s]DataLoad cost %.2f(wait:%.2f, realCost:%.2f)", GetClassName(self), cost, wait, realCost)
    end
    return self.dataStatus
end

function CityManagerBase:DataLoadFailed()
    self.city:OnDataManagerLoadFailed(self)
end

---@protected
---@return number @LoadState
function CityManagerBase:ViewLoadFinish()
    self.viewStatus = LoadState.Loaded
    self.city:OnViewManagerLoadFinish(self)
    if EnableLog then
        local cost = CS.UnityEngine.Time.realtimeSinceStartup - self._viewLoadFirstTryStart
        local wait = self._viewLoadRealStart - self._viewLoadFirstTryStart
        local realCost = CS.UnityEngine.Time.realtimeSinceStartup - self._viewLoadRealStart
        g_Logger.TraceChannel("CityManager_LoadCost", "[%s]ViewLoad cost %.2f(wait:%.2f, realCost:%.2f)", GetClassName(self), cost, wait, realCost)
    end
    return self.viewStatus
end

function CityManagerBase:ViewLoadFailed()
    self.city:OnViewManagerLoadFailed(self)
end

function CityManagerBase:CalculatePrioritySelf()
    return 1 << #self.dependencies
end

function CityManagerBase:CalculatePriority()
    local ret = self:CalculatePrioritySelf()
    for i, v in ipairs(self.dependencies) do
        ret = ret + v:CalculatePriority()
    end
    return ret
end

function CityManagerBase:GetName()
    return GetClassName(self)
end

function CityManagerBase:ToString()
    local names = {}
    for i, v in ipairs(self.dependencies) do
        table.insert(names, v:GetName())
    end
    local dependencyNames = table.concat(names, ',')
    return ("[%s]:依赖[%s],Priority:%d"):format(self:GetName(), dependencyNames, self.priority)
end

function CityManagerBase:IsResReady()
    return self.basicResourceStatus == LoadState.Loaded or self.basicResourceStatus == LoadState.None
end

function CityManagerBase:IsDataReady()
    return self.dataStatus == LoadState.Loaded or self.dataStatus == LoadState.None
end

function CityManagerBase:IsViewReady()
    return self.viewStatus == LoadState.Loaded or self.viewStatus == LoadState.None
end

function CityManagerBase:GetLoadDescription()
    return I18N.Get("enter_reminder")
end

function CityManagerBase:NeedUnloadViewWhenDisable()
    return false
end

return CityManagerBase