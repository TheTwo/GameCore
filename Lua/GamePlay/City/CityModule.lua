local BaseModule = require ('BaseModule')
local Delegate = require('Delegate')
local City = require("City")
local EventConst = require("EventConst")
local CityUtils = require("CityUtils")
local ConfigRefer = require("ConfigRefer")
local ArtResourceUtils = require("ArtResourceUtils")
local CityCitizenDefine = require("CityCitizenDefine")
local ModuleRefer = require("ModuleRefer")
local MyCity = require("MyCity")
local MapFoundation = require("MapFoundation")
local DBEntityPath = require("DBEntityPath")

---@class CityModule:BaseModule
---@field myCity City|nil
---@field activeCity table<number, City>
local CityModule = class('CityModule', BaseModule)
local DBEntityViewType = require("DBEntityViewType")

function CityModule:ctor()
    self.myCity = nil
    self.activeCity = {}
end

function CityModule:OnRegister()
    local staticMapData = MapFoundation.LoadStaticMapData()
    self.UnitsPerTileX = staticMapData.UnitsPerTileX
    self.UnitsPerTileZ = staticMapData.UnitsPerTileZ
    MapFoundation.UnloadStaticMapData(staticMapData)

    -- g_Game.DatabaseManager:AddViewNewByType(DBEntityViewType.ViewCastleBriefForMap, Delegate.GetOrCreate(self, self.OnOtherCastleBriefAdd))
    -- g_Game.DatabaseManager:AddViewDestroyByType(DBEntityViewType.ViewCastleBriefForMap, Delegate.GetOrCreate(self, self.OnOtherCastleBriefDelete))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.MapBasics.BuildingPos.MsgPath, Delegate.GetOrCreate(self, self.OnBuildingPosChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureChanged))

    g_Game.EventManager:AddListener(EventConst.RELOGIN_START, Delegate.GetOrCreate(self, self.OnReloginStart))
    g_Game.EventManager:AddListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self, self.OnReloginSuccess))
    g_Game.EventManager:AddListener(EventConst.RELOGIN_FAILURE, Delegate.GetOrCreate(self, self.OnReloginFailure))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_DATA_LOADED,Delegate.GetOrCreate(self,self.SaveMyBaseLevel))
    g_Game.EventManager:AddListener(EventConst.ON_LOW_MEMORY, Delegate.GetOrCreate(self, self.OnLowMemory))

    CS.CityCreepController.SwitchUseStaticCache(not g_Game.PerformanceLevelManager:IsLowLevel())
    CS.CityFogController.SwitchUseStaticCache(not g_Game.PerformanceLevelManager:IsLowLevel())
end

function CityModule:OnRemove()
    if self.myCity then
        self.myCity:Dispose()
    end
    self.myCity = nil
    self:ReleaseActiveCitys()
    -- g_Game.DatabaseManager:RemoveViewNewByType(DBEntityViewType.ViewCastleBriefForMap, Delegate.GetOrCreate(self, self.OnOtherCastleBriefAdd))
    -- g_Game.DatabaseManager:RemoveViewDestroyByType(DBEntityViewType.ViewCastleBriefForMap, Delegate.GetOrCreate(self, self.OnOtherCastleBriefDelete))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.MapBasics.BuildingPos.MsgPath, Delegate.GetOrCreate(self, self.OnBuildingPosChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.CastleFurniture.MsgPath, Delegate.GetOrCreate(self, self.OnFurnitureChanged))

    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_START, Delegate.GetOrCreate(self, self.OnReloginStart))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_SUCCESS, Delegate.GetOrCreate(self, self.OnReloginSuccess))
    g_Game.EventManager:RemoveListener(EventConst.RELOGIN_FAILURE, Delegate.GetOrCreate(self, self.OnReloginFailure))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_DATA_LOADED,Delegate.GetOrCreate(self,self.SaveMyBaseLevel))
    g_Game.EventManager:RemoveListener(EventConst.ON_LOW_MEMORY, Delegate.GetOrCreate(self, self.OnLowMemory))
end

function CityModule:OnLoggedIn()
    local castleBrief = ModuleRefer.PlayerModule:GetCastle()
    local mapBasics = castleBrief.MapBasics
    local myCity = MyCity.new(castleBrief.ID, mapBasics.BuildingPos.X, mapBasics.BuildingPos.Y, self.UnitsPerTileX, self.UnitsPerTileZ)
    self:SetMyCity(myCity)
end

---@param entity wds.CastleBrief
---@param viewTypeHash number DBEntityViewType的成员
---@param refCount number
function CityModule:OnOtherCastleBriefAdd(entity, viewTypeHash, refCount)
    if self.activeCity[entity.ID] then
        g_Logger.Error("重复Add %s", entity.ID)
        return
    end

    local x = entity.MapBasics.BuildingPos.X
    local y = entity.MapBasics.BuildingPos.Y
    local city = City.new(entity.ID, x, y, self.UnitsPerTileX, self.UnitsPerTileZ)

    city:SetKingdomMainLight(self.kingdomMainLight)
    self.activeCity[city.uid] = city
end

---@param entity wds.CastleBrief
---@param viewTypeHash number DBEntityViewType的成员
---@param refCount number
function CityModule:OnOtherCastleBriefDelete(entity, viewTypeHash, refCount)
    local city = self.activeCity[entity.ID]
    if not city then
        g_Logger.Error(("Delete Nonexistent City, Id : %d"):format(entity.ID))
        return
    end

    city:Dispose()
    self.activeCity[entity.ID] = nil
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CASTLE_BRIEF_DELETE, city)
end

function CityModule:ReleaseActiveCitys()
    for k, v in pairs(self.activeCity) do
        v:Dispose()
    end
    table.clear(self.activeCity)
end

---@param light CS.UnityEngine.Light
function CityModule:SetKingdomMainLight(light)
    self.kingdomMainLight = light
    for k, v in pairs(self.activeCity) do
        v:SetKingdomMainLight(self.kingdomMainLight)
    end
    if self.myCity then
        self.myCity:SetKingdomMainLight(light)
    end
end

---@return MyCity|nil
function CityModule:GetMyCity()
    return self.myCity
end

---@param myCity MyCity
function CityModule:SetMyCity(myCity)
    self.myCity = myCity
    self.myCity:LoadBasicResource()
    self.myCity:LoadData()
end

function CityModule:TryViewedClosestCity(position)
    local point = position
    local distance, result
    if self.myCity then
        distance = (self.myCity:GetCenter() - point).magnitude
        result = self.myCity
    end

    for k, v in pairs(self.activeCity) do
        if not distance then
            distance = (v:GetCenter() - point).magnitude
            result = v
        else
            local dist = (v:GetCenter() - point).magnitude
            if dist < distance then
                distance = dist
                result = v
            end
        end
    end

    return result
end

function CityModule:PrintCityLayerMask()
    self.myCity.gridLayer:Print()
    for k, v in pairs(self.activeCity) do
        v.gridLayer:Print()
    end
end

function CityModule:GetCity(uid)
    if self.myCity and uid == self.myCity.uid then
        return self.myCity
    end

    for k, v in pairs(self.activeCity) do
        if v.uid == uid then
            return v
        end
    end
end

---@param typ number
---@return table<number, wds.CastleBuildingInfo>, number TileID:BuildingInfo
function CityModule:GetStockCityBuildingInfoByType(typ)
    if not self.myCity then
        return nil, 0
    end

    local ret = {}
    local retCount = 0
    local castle = self.myCity:GetCastle()
    for tileId, info in pairs(castle.StoredBuildings) do
        if info.BuildingType == typ then
            ret[tileId] = info
            retCount = retCount + 1
        end
    end

    return ret, retCount
end

function CityModule:WarmUpCitizen()
    local helper = CityUtils.GetPooledGameObjectCreateHelper()
    self.waitWarmUp = 0
    self.finishWarmUp = 0
    local pathMap = {}
    for i, v in ConfigRefer.Citizen:pairs() do
        local path = CityCitizenDefine.GetCitizenModelByDeviceLv(v)
        pathMap[path] = (pathMap[path] or 0) + 1
        self.waitWarmUp = self.waitWarmUp + 1
    end

    for k, v in pairs(pathMap) do
        helper:WarmUp(k, v, Delegate.GetOrCreate(self, self.OnWarmUpSingle))
    end
    return pathMap
end

function CityModule:OnWarmUpSingle(go)
    self.finishWarmUp = self.finishWarmUp + 1
    if self.finishWarmUp == self.waitWarmUp then
        self.finishWarmUp = nil
        self.waitWarmUp = nil
        g_Game.EventManager:TriggerEvent(EventConst.CITY_WARM_UP_FINISH)
    end
end

---@return boolean
function CityModule:CanDoBuild()
    -- local taskId = ConfigRefer.CityConfig:CityConstructionBtnShowCondition()
    -- if taskId == nil then return true end

    -- local taskCfg = ConfigRefer.Task:Find(taskId)
    -- if taskCfg == nil then return true end

    -- local ModuleRefer = require("ModuleRefer")
    -- local player = ModuleRefer.PlayerModule:GetPlayer()
    -- return ModuleRefer.QuestModule:IsInBitMap(taskId, player.PlayerWrapper.Task.FinishedBitMap)
    local sysIndex = ConfigRefer.CityConfig:CityConstructionSystemSwitch()
    local ModuleRefer = require("ModuleRefer")
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysIndex)
end

---@param castleBrief wds.CastleBrief
function CityModule:OnBuildingPosChanged(castleBrief, changeTable)
    if self.myCity and self.myCity.uid == castleBrief.ID then
        self.myCity:SetCityPosition(castleBrief.MapBasics.BuildingPos.X, castleBrief.MapBasics.BuildingPos.Y, self.UnitsPerTileX, self.UnitsPerTileZ)
    end

    if self.activeCity and self.activeCity[castleBrief.ID] then
        self.activeCity[castleBrief.ID]:SetCityPosition(castleBrief.MapBasics.BuildingPos.X, castleBrief.MapBasics.BuildingPos.Y, self.UnitsPerTileX, self.UnitsPerTileZ)
    end
end

function CityModule:OnReloginStart()
    self.reloading = true
end

function CityModule:OnReloginSuccess()
    self.reloading = false

    if self.myCity then
        self.myCity:UpdateCastle()
        if not self.myCity.inRestarting then
            self.myCity:MarkAsLightRestart()
            self.myCity:UnloadView()
            self.myCity:UnloadData()
            self.myCity:LoadData()
        end
    end

    for k, v in pairs(self.activeCity) do
        v:UpdateCastle()
    end
end

function CityModule:OnReloginFailure()
    ---DO Nothing
end

function CityModule:OnFurnitureChanged(entity, changedData)
    if not self.myCity or entity.ID ~= self.myCity.uid then
        return
    end
    ---@type table<number, wds.CastleFurniture>
    local add = changedData.Add
    ---@type table<number, wds.CastleFurniture>
    local remove = changedData.Remove
    local baseChaned = false
    if add then
        for _,v in pairs(add) do
            local cfg = ConfigRefer.CityFurnitureLevel:Find(v.ConfigId)
            if cfg and cfg:Type() == CityUtils.CityBaseTypeCfgId then
                baseChaned = true
                break
            end
        end
    end

    if not baseChaned and remove then
        for _,v in pairs(remove) do
            local cfg = ConfigRefer.CityFurnitureLevel:Find(v.ConfigId)
            if cfg and cfg:Type() == CityUtils.CityBaseTypeCfgId then
                baseChaned = true
                break
            end
        end    
    end

    if baseChaned then
        self:SaveMyBaseLevel()
    end
end

function CityModule:SaveMyBaseLevel()
    if self.myCity then
        CityUtils.SaveBaseLevelToPrefs()
    end
end

function CityModule:OnLowMemory()
    if self.myCity then
        self.myCity:OnLowMemory()
    end
end

function CityModule:ClearViewportCreepForUWAPocoAutoTest()
    if not self.myCity then return end
    if not self.myCity.creepManager:IsDataReady() then return end
    if not self.myCity:GetCamera() then return end

    local camera = self.myCity:GetCamera()
    local xMin, yMin, xMax, yMax = camera:GetLookAtPlaneAABB()
    xMin, yMin = self.myCity:GetCoordFromPosition(CS.UnityEngine.Vector3(xMin, 0, yMin))
    xMax, yMax = self.myCity:GetCoordFromPosition(CS.UnityEngine.Vector3(xMax, 0, yMax))
    local bigCellSize = ConfigRefer.CityConfig:SprayMedicineOperateCellSize()
    local RectDyadicMap = require("RectDyadicMap")
    local sizeX, sizeY = self.myCity.gridConfig.cellsX, self.myCity.gridConfig.cellsY
    local batchBigCell = RectDyadicMap.new(math.ceil(sizeX / bigCellSize), math.ceil(sizeY / bigCellSize))

    for i = xMin, xMax do
        for j = yMin, yMax do
            if self.myCity.creepManager:IsAffect(i, j) and not self.myCity:IsFogMask(i, j) then
                batchBigCell:TryAdd(i // bigCellSize, j // bigCellSize, true)
            end
        end
    end

    if batchBigCell.count == 0 then return end

    local itemList = {}
    for i = 1, ConfigRefer.CityConfig:SweeperItemsLength() do
        local itemCfgId = ConfigRefer.CityConfig:SweeperItems(i)
        local itemCfg = ConfigRefer.Item:Find(itemCfgId)
        local datum = {itemCfg = itemCfg}
        table.insert(itemList, datum)
    end
    ---@param a CityCreepClearSweeperItemData
    ---@param b CityCreepClearSweeperItemData
    table.sort(itemList, function(a, b)
        local qa, qb = a.itemCfg:Quality(), b.itemCfg:Quality()
        if qa ~= qb then return qa < qb end
        return a.itemCfg:Id() > b.itemCfg:Id()
    end)

    for i, v in ipairs(itemList) do
        local itemCfgId = v.itemCfg:Id()
        v.count = ModuleRefer.InventoryModule:GetAmountByConfigId(itemCfgId)
        v.durability = ModuleRefer.CityCreepModule:GetSweeperDurabilitySum(itemCfgId)
    end

    local savedCfgId = ModuleRefer.CityCreepModule:GetSelectSweeperCfgId()
    for _, v in ipairs(itemList) do
        if v.itemCfg:Id() == savedCfgId and (v.count == 0 or v.durability == 0) then
            savedCfgId = nil
            break
        end
    end

    if savedCfgId == nil then
        for _, v in ipairs(itemList) do
            if v.count > 0 and v.durability > 0 then
                savedCfgId = v.itemCfg:Id()
                break
            end
        end
    end

    if savedCfgId == nil then return end

    --- Not Check durability enough
    local CastleCreepSweepByItemParameter = require("CastleCreepSweepByItemParameter")
    local param = CastleCreepSweepByItemParameter.new()
    local points = param.args.Points
    for x, y, _ in batchBigCell:pairs() do
        local point2 = wds.Point2.New(x, y)
        points:Add(point2)
    end
    param.args.ItemId = savedCfgId
    param:Send()
end

---@return boolean
function CityModule:IsInMyCity()
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if scene then
        local sceneName = scene:GetName()
        if sceneName == 'KingdomScene' then
            return scene:IsInMyCity()
        end
    end
    return false
end

return CityModule