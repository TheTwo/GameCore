local BaseModule = require("BaseModule")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomConstant = require("KingdomConstant")

local Shader = CS.UnityEngine.Shader

---@class RoadModule : BaseModule
---@field cameraLodData CameraLodData
---@field settings CS.Grid.MapRoadSettings
---@field palette CS.System.Collections.Generic.Dictionary(typeof(CS.System.Int32), typeof(CS.System.Int32))
---@field symbolStartLod number
---@field symbolEndLod number
---@field symbolRoadWidthMin number
---@field symbolRoadWidthMax number
local RoadModule = class("RoadModule", BaseModule)

function RoadModule:Setup()
    self.cameraLodData = KingdomMapUtils.GetCameraLodData()
    self.settings = KingdomMapUtils.GetKingdomMapSettings(typeof(CS.Grid.MapRoadSettings))

    self.symbolStartLod = self.settings.SymbolStartLod
    self.symbolEndLod = self.settings.SymbolEndLod
    self.symbolRoadWidthMin = self.settings.SymbolRoadWidthMin
    self.symbolRoadWidthMax = self.settings.SymbolRoadWidthMax
    
    g_Game.EventManager:AddListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
end

function RoadModule:ShutDown()
    g_Game.EventManager:RemoveListener(EventConst.CAMERA_SIZE_CHANGED, Delegate.GetOrCreate(self, self.OnCameraSizeChanged))
    self.settings = nil
end


function RoadModule:OnCameraSizeChanged(oldSize, newSize)
    local symbolSize = self.cameraLodData:GetSizeByLod(self.symbolStartLod - 1)
    local maxSize = self.cameraLodData:GetSizeByLod(self.symbolEndLod)
    if newSize < symbolSize or newSize > maxSize then
        return
    end
    
    local t = math.clamp01((newSize - symbolSize) / (maxSize - symbolSize))
    local width = self.symbolRoadWidthMin * (1 - t) + self.symbolRoadWidthMax * t 
    Shader.SetGlobalFloat("_Kingdom2DRoadExtend", width)
end

---@param idStart number
---@param idEnd number
function RoadModule:BridgeHasCreep(idStart, idEnd)
    return idStart > 0 and idEnd > 0 and (ModuleRefer.TerritoryModule:CheckHasCreep(idStart) or ModuleRefer.TerritoryModule:CheckHasCreep(idEnd))
end

function RoadModule:TestCleanCreep(territoryID, x, z, range, duration)
    territoryID = tonumber(territoryID)
    x = tonumber(x) * 25
    z = tonumber(z) * 25
    range = tonumber(range)
    duration = tonumber(duration)
    local mapSystem = KingdomMapUtils.GetMapSystem()
    local centerPosition = CS.UnityEngine.Vector3(x, 0, z)
    mapSystem:ShowFadingAnim(territoryID, centerPosition, range,duration)

end

return RoadModule