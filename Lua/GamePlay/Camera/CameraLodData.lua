--警告：这个类会在多个功能场景中使用，不要把某个功能的特化逻辑写在这个类中，以免产生不必要的耦合！
local Delegate = require("Delegate")
local EventConst = require("EventConst")

---@class CameraLodData
---@field mapCameraEnterSize number
---@field mapCameraEnterNear number
---@field mapCameraEnterFar number
---@field mapCameraMistTaskSize number
---@field mapCameraSizeList table<number>
---@field mapShadowDistanceList table<number>
---@field mapDecorationScaleList table<number>
---@field planeDecorationSize number
---@field altitudeCurve CS.UnityEngine.AnimationCurve
local CameraLodData = class("CameraLodData")

function CameraLodData:ctor(basicCamera)
    ---@type BasicCamera
    self.basicCamera = basicCamera
    self.mapCameraSizeList = {}
    self.mapShadowDistanceList = {}
    self.mapDecorationScaleList = {}
end

function CameraLodData:Initialize()
    self.lodChangeListeners = {}
    self.sizeChangeListeners = {}
    local camSize = self.basicCamera:GetSize()
    self.size = camSize
    self.lod = self:CalculateLod(camSize)
    
    self.basicCamera:AddSizeChangeListener(Delegate.GetOrCreate(self, self.OnSizeChanged))
end

function CameraLodData:Release()
    self.basicCamera:RemoveSizeChangeListener(Delegate.GetOrCreate(self, self.OnSizeChanged))

    self.lodChangeListeners = nil
    self.sizeChangeListeners = nil
end

---@param listener fun(oldLod:number,newLod:number)
function CameraLodData:AddLodChangeListener(listener)
    if self.lodChangeListeners then
        self.lodChangeListeners[listener] = listener
    end
end
---@param listener fun(oldLod:number,newLod:number)
function CameraLodData:RemoveLodChangeListener(listener)
    if self.lodChangeListeners then
        self.lodChangeListeners[listener] = nil
    end
end

---@param listener fun(oldSize:number,newSize:number)
function CameraLodData:AddSizeChangeListener(listener)
    if self.sizeChangeListeners then
        self.sizeChangeListeners[listener] = listener
    end
end
---@param listener fun(oldSize:number,newSize:number)
function CameraLodData:RemoveSizeChangeListener(listener)
    if self.sizeChangeListeners then
        self.sizeChangeListeners[listener] = nil
    end
end

function CameraLodData:OnSizeChanged(oldSize, newSize)
    self.size = newSize
    self.lod = self:CalculateLod(newSize)


    local oldLod = self:CalculateLod(oldSize)
    if self.lod ~= oldLod then
        for k, v in pairs(self.lodChangeListeners) do
            k(oldLod, self.lod)
        end
    end

    for key, value in pairs(self.sizeChangeListeners) do
        key(oldSize,newSize)
    end
    g_Game.EventManager:TriggerEvent(EventConst.CAMERA_SIZE_CHANGED, oldSize, newSize)

end

function CameraLodData:GetLod()
    if self.lod then
        return self.lod
    end
    return 0
end

function CameraLodData:GetSize()
    if self.size then
        return self.size
    end
    return 1000
end

function CameraLodData:GetSizeByLod(lod)
    lod = lod + 1
    if not self.mapCameraSizeList or #self.mapCameraSizeList < 1 then
        return 0
    end

    if lod < 1 or lod > #self.mapCameraSizeList then
        return 0
    end
    
    return self.mapCameraSizeList[lod]
end

---@param size number
---@return number
function CameraLodData:CalculateLod(size)
    local lod = 0
    local thresholds = self.mapCameraSizeList

    if thresholds == nil or #thresholds < 1 then
        return lod
    end

    local lastIndex = #thresholds
    for i = 1, lastIndex do
        local threshold = thresholds[i]
        if size >= threshold then
            lod = lod + 1
        end
    end

    return lod
end

---@param lod number
function CameraLodData:GetLodSizeThreshold(lod)
    lod = lod + 1
    local thresholds = self.mapCameraSizeList
    if thresholds == nil or table.nums(thresholds) < 1 then
        return 0
    end
    
    local maxLod = #thresholds
    if lod >= maxLod then
        return thresholds[maxLod]
    elseif lod < 1 then
        return thresholds[1]
    else
        return thresholds[lod]
    end
end

function CameraLodData:GetLodCount()
    if not self.mapCameraSizeList or #self.mapCameraSizeList < 1 then 
        return 0 
    end
    return #self.mapCameraSizeList
end

return CameraLodData