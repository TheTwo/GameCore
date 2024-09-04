local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")

local CityTileAssetFurniture = require("CityTileAssetFurniture")

---@class CityTileAssetFurnitureTrain:CityTileAssetFurniture
---@field new fun():CityTileAssetFurnitureTrain
---@field super CityTileAssetFurniture
local CityTileAssetFurnitureTrain = class('CityTileAssetFurnitureTrain', CityTileAssetFurniture)

function CityTileAssetFurnitureTrain:ctor()
    CityTileAssetFurniture.ctor(self)
end

function CityTileAssetFurnitureTrain:OnTileViewInit()
    CityTileAssetFurniture.OnTileViewInit(self)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleMilitia.MsgPath, Delegate.GetOrCreate(self,self.RefreshTrainState))
end

function CityTileAssetFurnitureTrain:OnTileViewRelease()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleMilitia.MsgPath, Delegate.GetOrCreate(self,self.RefreshTrainState))
    CityTileAssetFurniture.OnTileViewRelease(self)
end

function CityTileAssetFurnitureTrain:RefreshTrainState()
    self:RefreshFurnitureAni()
end

function CityTileAssetFurnitureTrain:GetWorkStatus()
    local castleMilitia = ModuleRefer.TrainingSoldierModule:GetCastleMilitia()
    local isCustomTraining = castleMilitia.TrainPlan and castleMilitia.TrainPlan > 0
    local isAutoTraining = not castleMilitia.SwitchOff
    local isTraining = isAutoTraining or isCustomTraining
    local isMax = castleMilitia.Capacity <= castleMilitia.Count
    local isWork = isTraining and not isMax
    return isWork and 1 or 0
end



return CityTileAssetFurnitureTrain