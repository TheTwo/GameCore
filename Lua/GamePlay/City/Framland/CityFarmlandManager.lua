local CityManagerBase = require("CityManagerBase")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local OnChangeHelper = require("OnChangeHelper")
local CastleLandSowSeedsParameter = require("CastleLandSowSeedsParameter")
local CastleLandHarvestCropsParameter = require("CastleLandHarvestCropsParameter")
local CastleLandGrowSpeedUpParameter = require("CastleLandGrowSpeedUpParameter")
local CityCitizenDefine = require("CityCitizenDefine")
local ModuleRefer = require("ModuleRefer")

---@class CityFarmlandManager:CityManagerBase
---@field new fun():CityFarmlandManager
local CityFarmlandManager = class('CityFarmlandManager', CityManagerBase)

function CityFarmlandManager:ctor(city, ...)
    CityManagerBase.ctor(self, city, ...)
    self._castleBriefId = self.city.uid
    self._currentSelectedGrowingFarmlandId = nil
end

function CityFarmlandManager:OnDataLoadFinish()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
end

function CityFarmlandManager:OnDataUnloadStart()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
end

---@param f1 wds.CastleFurniture
---@param f2 wds.CastleFurniture
function CityFarmlandManager.IsCastleFurnitureLandInfoDiff(f1, f2)
    local l1 = f1.LandInfo
    local l2 = f2.LandInfo
    if not l1 and l2 then
        return true
    end
    if l1 and not l2 then
        return true
    end
    if not l1 then
        return false
    end
    if l1.state ~= l2.state then
        return true
    end
    if l1.HarvestableTime ~= l2.HarvestableTime then
        return true
    end
    if l1.cropTid ~= l2.cropTid then
        return true
    end
    return false
end

---@param entity wds.CastleBrief
---@param changedData table
function CityFarmlandManager:OnFurnitureDataChanged(entity, changedData)
    if self._castleBriefId ~= entity.ID then
        return
    end
    local _,removed,change = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    local needNotify = {}
    local notify = false
    if change then
        for id, v in pairs(change) do
            ---@type wds.CastleFurniture
            local oldValue = v[1]
            ---@type wds.CastleFurniture
            local newValue = v[2]
            if CityFarmlandManager.IsCastleFurnitureLandInfoDiff(oldValue, newValue) then
                needNotify[id] = true
                notify = true

            end
        end
    end
    if self._currentSelectedGrowingFarmlandId then
        if removed and removed[self._currentSelectedGrowingFarmlandId] then
            self:SetSelectedGrowingFarmland(nil)
        elseif notify and needNotify[self._currentSelectedGrowingFarmlandId]  then
            ---@type wds.CastleFurniture
            local newValue = change[self._currentSelectedGrowingFarmlandId][2]
            if newValue.LandInfo.state ~= wds.CastleLandState.CastleLandGrowing then
                self:SetSelectedGrowingFarmland(nil)
            end
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_FARMLAND_UPDATE, self._castleBriefId, needNotify)
end

---@param farmlandId number
---@param cropConfig CropConfigCell
function CityFarmlandManager:DummySowSeed(farmlandId, cropConfig)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_SEED, self._castleBriefId, farmlandId, cropConfig)
end

function CityFarmlandManager:DummyHarvest(farmlandId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_HARVEST, self._castleBriefId, farmlandId)
end

function CityFarmlandManager:DummySelect(farmlandId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_SELECT, self._castleBriefId, farmlandId)
end

function CityFarmlandManager:DummyCancel()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_FARMLAND_DUMMY_CANCEL, self._castleBriefId)
end

function CityFarmlandManager:SowSeeds(cropId, landIds)
    local sendCmd = CastleLandSowSeedsParameter.new()
    sendCmd.args.CropId = cropId
    sendCmd.args.LandIds:AddRange(landIds)
    sendCmd:Send()
end

function CityFarmlandManager:HarvestCrops(landIds)
    local sendCmd = CastleLandHarvestCropsParameter.new()
    sendCmd.args.LandIds:AddRange(landIds)
    sendCmd:Send()
end

function CityFarmlandManager:GrowSpeed(landId)
    local landInfo = self.city:GetCastle().CastleFurniture[landId].LandInfo
    if landInfo.cropTid == 0 or landInfo.state ~= wds.CastleLandState.CastleLandGrowing then
        return
    end
    local leftTime = landInfo.HarvestableTime - g_Game.ServerTime:GetServerTimestampInSeconds()
    if leftTime <= 0 then
        return
    end
    local cropConfig = ConfigRefer.Crop:Find(landInfo.cropTid)
    local costItemId = ConfigRefer.ConstMain:CropSpeedUpConsumeItemId()
    local speedCost = math.ceil(cropConfig:SpeedUpConsume() * leftTime)
    if speedCost <= 0 then
        return
    end
    if ModuleRefer.InventoryModule:GetAmountByConfigId(costItemId) < speedCost then
        return
    end
    local sendCmd = CastleLandGrowSpeedUpParameter.new()
    sendCmd.args.LandId = landId
    sendCmd:Send()
end

---@return boolean
function CityFarmlandManager:SetSelectedGrowingFarmland(landId)
    if self._currentSelectedGrowingFarmlandId ~= landId then
        local oldId = self._currentSelectedGrowingFarmlandId
        self._currentSelectedGrowingFarmlandId = landId
        if oldId then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_FARMLAND_GROWING_UNSELECT, self._castleBriefId, oldId)
        end
        if self._currentSelectedGrowingFarmlandId then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_FARMLAND_GROWING_SELECT, self._castleBriefId, self._currentSelectedGrowingFarmlandId)
        end
    end
end

---@return boolean
function CityFarmlandManager:IsSelectedGrowingFarmland(landId)
    return landId and self._currentSelectedGrowingFarmlandId == landId
end

---@return CityFurnitureTile|nil
function CityFarmlandManager:GetNearestGrowingFarmland(x, y)
    local castle = self.city:GetCastle()
    local furniture = castle.CastleFurniture
    local minDistance = nil
    ---@type wds.CastleFurniture
    local ret = nil
    for _, v in pairs(furniture) do
        if v.LandInfo.state == wds.CastleLandState.CastleLandGrowing then
            local c = ConfigRefer.CityFurnitureLevel:Find(v.ConfigId)
            if CityCitizenDefine.IsFarmlandFurniture(c:Type()) then
                if not ret then
                    ret = v
                    local a = v.Pos.X - x
                    local b = v.Pos.Y- y
                    minDistance = a * a + b * b
                else
                    local a = v.Pos.X - ret.Pos.X
                    local b = v.Pos.Y- ret.Pos.Y
                    local distance = a * a + b * b
                    if distance < minDistance then
                        minDistance = distance
                        ret = v
                    end
                end
            end
        end
    end
    if ret then
        return self.city.gridView:GetFurnitureTile(ret.Pos.X, ret.Pos.Y)
    end
    return nil
end

return CityFarmlandManager