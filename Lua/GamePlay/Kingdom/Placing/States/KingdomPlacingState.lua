local KingdomMapUtils = require("KingdomMapUtils")

---@class KingdomPlacingState
local KingdomPlacingState = class("KingdomPlacingState")

function KingdomPlacingState:SetContext(context)
end

function KingdomPlacingState:OnStart()
end

function KingdomPlacingState:OnEnd()
end

function KingdomPlacingState:OnPlace()
end

---@return boolean
function KingdomPlacingState:IsDirty()
    
end

---@param gridMeshManager CS.Kingdom.KingdomGridMeshManager
---@param territoryYesList table CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@param territoryNoList table CS.System.Collections.Generic.List(typeof(CS.System.Int32))
---@param rectYesList table CS.System.Collections.Generic.List(typeof(CS.System.Int16))
---@param rectNoList table CS.System.Collections.Generic.List(typeof(CS.System.Int16))
---@param circleYesList table CS.System.Collections.Generic.List(typeof(CS.System.Single))
---@param circleNoList table CS.System.Collections.Generic.List(typeof(CS.System.Single))
function KingdomPlacingState:SetGridData(gridMeshManager, territoryYesList, territoryNoList, rectYesList, rectNoList, circleYesList, circleNoList)
    
end

---@param circleList table CS.System.Collections.Generic.List(typeof(CS.System.Single))---@param buildingCenterPos wds.Vector3F
---@param staticMapData CS.Grid.StaticMapData
function KingdomPlacingState:FillCircle(circleList, buildingCenterPos, radius, staticMapData)
    local centerX, centerY = KingdomMapUtils.ParseBuildingPos(buildingCenterPos)
    centerX = centerX * staticMapData.UnitsPerTileX
    centerY = centerY * staticMapData.UnitsPerTileZ
    radius = radius * staticMapData.UnitsPerTileX
    circleList:Add(centerX)
    circleList:Add(centerY)
    circleList:Add(radius)
end

---@param rectList table CS.System.Collections.Generic.List(typeof(CS.System.Int16))
function KingdomPlacingState:FillBuildingRect(rectList, positionX, positionY, sizeX, sizeY, margin)
    positionX = positionX - margin
    positionY = positionY - margin
    sizeX = sizeX + margin * 2
    sizeY = sizeY + margin * 2
    rectList:Add(positionX)
    rectList:Add(positionY)
    rectList:Add(sizeX)
    rectList:Add(sizeY)
end

return KingdomPlacingState