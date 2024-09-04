local CityManagerBase = require("CityManagerBase")
---@class CityLegoBuildingManager:CityManagerBase
---@field new fun():CityLegoBuildingManager
local CityLegoBuildingManager = class("CityLegoBuildingManager", CityManagerBase)
local CityLegoBuilding = require("CityLegoBuilding")
local ConfigRefer = require("ConfigRefer")
local NpcServiceObjectType = require("NpcServiceObjectType")
local Delegate = require("Delegate")
local OnChangeHelper = require("OnChangeHelper")
local EventConst = require("EventConst")
local CastleSetRoomBuffParameter = require("CastleSetRoomBuffParameter")
local ModuleRefer = require("ModuleRefer")
local BuffFormulaMarker = require("BuffFormulaMarker")
local ExpireBuffFormulaMarker = require("ExpireBuffFormulaMarker")

function CityLegoBuildingManager:NeedLoadData()
    return true
end

function CityLegoBuildingManager:DoDataLoad()
    ---@type table<number, CityLegoBuilding>
    self.legoBuildings = {}
    
    local castle = self.city:GetCastle()
    for id, building in pairs(castle.Buildings) do
        local legoBuilding = CityLegoBuilding.new(self, id, building)
        self.legoBuildings[id] = legoBuilding
        g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_BUILDING_ADD, self.city, legoBuilding)
    end

    self:AddEventListeners()
    self:DataLoadFinish()
    self.needShowBuildingName = false
end

function CityLegoBuildingManager:DoDataUnload()
    self.needShowBuildingName = false
    self:OnFurniturePreviewFinish()
    self:RemoveEventListeners()
    self.legoBuildings = nil
    g_Game.VisualEffectManager.manager:Clear("CityLegoBuilding")
end

function CityLegoBuildingManager:AddEventListeners()
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureBatchUpdate))
    g_Game.EventManager:AddListener(EventConst.UI_FURNITURE_PLACE_PREVIEW_NEW, Delegate.GetOrCreate(self, self.OnFurniturePreviewBuffFormula))
    g_Game.EventManager:AddListener(EventConst.UI_FURNITURE_PLACE_PREVIEW_FINISH, Delegate.GetOrCreate(self, self.OnFurniturePreviewFinish))
    g_Game.EventManager:AddListener(EventConst.UI_FURNITURE_MOVING_PREVIEW_BUFF_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureMovingCauseBuffChange))
    g_Game.EventManager:AddListener(EventConst.UI_FURNITURE_MOVING_PREVIEW_END, Delegate.GetOrCreate(self, self.OnFurnitureMovingFinish))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_SHOW_NAME, Delegate.GetOrCreate(self, self.OnBuildingNameShow))
    g_Game.EventManager:AddListener(EventConst.CITY_LEGO_HIDE_NAME, Delegate.GetOrCreate(self, self.OnBuildingNameHide))
    ModuleRefer.PlayerServiceModule:AddServicesChanged(NpcServiceObjectType.Building, Delegate.GetOrCreate(self, self.OnLegoServiceChanged))
end

function CityLegoBuildingManager:RemoveEventListeners()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureBatchUpdate))
    g_Game.EventManager:RemoveListener(EventConst.UI_FURNITURE_PLACE_PREVIEW_NEW, Delegate.GetOrCreate(self, self.OnFurniturePreviewBuffFormula))
    g_Game.EventManager:RemoveListener(EventConst.UI_FURNITURE_PLACE_PREVIEW_FINISH, Delegate.GetOrCreate(self, self.OnFurniturePreviewFinish))
    g_Game.EventManager:RemoveListener(EventConst.UI_FURNITURE_MOVING_PREVIEW_BUFF_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureMovingCauseBuffChange))
    g_Game.EventManager:RemoveListener(EventConst.UI_FURNITURE_MOVING_PREVIEW_END, Delegate.GetOrCreate(self, self.OnFurnitureMovingFinish))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_SHOW_NAME, Delegate.GetOrCreate(self, self.OnBuildingNameShow))
    g_Game.EventManager:RemoveListener(EventConst.CITY_LEGO_HIDE_NAME, Delegate.GetOrCreate(self, self.OnBuildingNameHide))
    ModuleRefer.PlayerServiceModule:RemoveServicesChanged(NpcServiceObjectType.Building, Delegate.GetOrCreate(self, self.OnLegoServiceChanged))
end

function CityLegoBuildingManager:OnViewUnloadFinish()
    for id, legoBuilding in pairs(self.legoBuildings) do
        legoBuilding:UnloadTileView()
    end
end

function CityLegoBuildingManager:GetLegoBuilding(id)
    return self.legoBuildings[id]
end

function CityLegoBuildingManager:GetLegoBuildingAt(x, y)
    for id, legoBuilding in pairs(self.legoBuildings) do
        if legoBuilding:FloorContains(x, y) then
            return legoBuilding
        end
    end
    return nil
end

function CityLegoBuildingManager:GetLegoBuildingByRoomCfgId(roomCfgId)
    for id, legoBuilding in pairs(self.legoBuildings) do
        if legoBuilding.roomCfgId == roomCfgId then
            return legoBuilding
        end
    end
    return nil
end

---@param castleBrief wds.CastleBrief
function CityLegoBuildingManager:OnLegoBuildingChanged(castleBrief, changeTable, batchEvts)
    if castleBrief ~= self.city:GetCastleBrief() then
        return
    end

    local batchEvt = {Event = EventConst.CITY_BATCH_WDS_CASTLE_LEGO_UPDATE, Add = {}, Remove = {}, Change = {}}
    local Add, Remove, Change = OnChangeHelper.GenerateMapComponentFieldChangeMap(changeTable, wds.CastleBuilding)
    Remove, Change = OnChangeHelper.PostFixChangeMap(castleBrief.Castle.Buildings, Remove, Change)

    if Add then
        for id, _ in pairs(Add) do
            local building = castleBrief.Castle.Buildings[id]
            local legoBuilding = CityLegoBuilding.new(self, id, building)
            self.legoBuildings[id] = legoBuilding
            g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_BUILDING_ADD, self.city, legoBuilding)
            batchEvt.Add[id] = true
        end
    end
    if Remove then
        for id, _ in pairs(Remove) do
            local legoBuilding = self.legoBuildings[id]
            if legoBuilding then
                legoBuilding:Release()
                self.legoBuildings[id] = nil
                g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_BUILDING_REMOVE_PRE, self.city, legoBuilding)
                g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_BUILDING_REMOVE, self.city, legoBuilding)
                batchEvt.Remove[id] = true
            end
        end
    end
    if Change then
        for id, _ in pairs(Change) do
            local legoBuilding = self.legoBuildings[id]
            if legoBuilding then
                legoBuilding:UpdatePayload(castleBrief.Castle.Buildings[id])
                g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_BUILDING_UPDATE, self.city, legoBuilding)
                batchEvt.Change[id] = true
            end
        end
    end
    table.insert(batchEvts, batchEvt)
end

---@return table<number, CityWallOrDoorNavmeshDatum[]>
function CityLegoBuildingManager:GenerateBuildingsNavmeshData()
    local navmeshData = {}
    for id, legoBuilding in pairs(self.legoBuildings) do
        navmeshData[id] = legoBuilding.navmeshData
    end
    return navmeshData
end

function CityLegoBuildingManager:OnFurnitureBatchUpdate(city, batchEvt)
    if city ~= self.city then return end

    for id, legoBuilding in pairs(self.legoBuildings) do
        legoBuilding:OnFurnitureBatchUpdate(batchEvt.Change)
    end
end

function CityLegoBuildingManager:OnLegoServiceChanged()
    for id, legoBuilding in pairs(self.legoBuildings) do
        legoBuilding:UpdateUnlockBubble()
    end
end

function CityLegoBuildingManager:RequestSelectBuff(legoBuilding, selectedBuffs, callback)
    local param = CastleSetRoomBuffParameter.new()
    param.args.BuildingId = legoBuilding.id
    param.args.BuffIds:AddRange(selectedBuffs)
    param:SendWithFullScreenLockAndOnceCallback(nil, true, callback)
end

---@return RoomLevelInfoConfigCell|nil
function CityLegoBuildingManager:GetRoomLevelCfg(roomCfgId, roomLevel)
    local roomCfg = ConfigRefer.Room:Find(roomCfgId)
    for i = 1, roomCfg:LevelInfosLength() do
        local levelCfgId = roomCfg:LevelInfos(i)
        local levelCfg = ConfigRefer.RoomLevelInfo:Find(levelCfgId)
        if levelCfg:Level() == roomLevel then
            return levelCfg
        end
    end
    return nil
end

function CityLegoBuildingManager:OnFurniturePreviewBuffFormula(lvCfgId)
    if self.city.editBuilding ~= nil then return end

    local showTipBuildings = {}
    for id, legoBuilding in pairs(self.legoBuildings) do
        if legoBuilding:TryShowRecommendFormula(lvCfgId) then
            showTipBuildings[id] = BuffFormulaMarker.new(legoBuilding:GetWorldCenter(), self.city:GetCamera())
        end
    end

    for _, marker in pairs(showTipBuildings) do
        g_Game.EventManager:TriggerEvent(EventConst.UI_MARKER_APPEND, marker)
    end

    ---@type table<number, BuffFormulaMarker>
    self.formulaMarkers = showTipBuildings
end

function CityLegoBuildingManager:OnFurniturePreviewFinish()
    for id, legoBuilding in pairs(self.legoBuildings) do
        legoBuilding:HideRecommendFormula()
    end

    if not self.formulaMarkers then return end

    for _, marker in pairs(self.formulaMarkers) do
        marker:Dispose()
        g_Game.EventManager:TriggerEvent(EventConst.UI_MARKER_REMOVE, marker)
    end

    self.formulaMarkers = nil
end

function CityLegoBuildingManager:OnFurnitureMovingCauseBuffChange(id, furnitureId)
    if self.city.editBuilding ~= nil then return end

    local legoBuilding = self.legoBuildings[id]
    if not legoBuilding then return end

    if legoBuilding:TryShowBuffExpireFormula(furnitureId) then
        self.expireLegoBuilding = legoBuilding
        self.expireFormulaMarker = ExpireBuffFormulaMarker.new(legoBuilding:GetWorldCenter(), self.city:GetCamera())
        g_Game.EventManager:TriggerEvent(EventConst.UI_MARKER_APPEND, self.expireFormulaMarker)
    end
end

function CityLegoBuildingManager:OnFurnitureMovingFinish()
    if self.expireLegoBuilding then
        self.expireLegoBuilding:HideBuffExpireFormula()
        self.expireLegoBuilding = nil
    end

    if not self.expireFormulaMarker then return end

    self.expireFormulaMarker:Dispose()
    g_Game.EventManager:TriggerEvent(EventConst.UI_MARKER_REMOVE, self.expireFormulaMarker)
    self.expireFormulaMarker = nil
end

function CityLegoBuildingManager:DontHasRoof(id)
    if not self.legoBuildings then return false end
    if not self.legoBuildings[id] then return false end
    return self.legoBuildings[id]:DontHasRoof()
end

function CityLegoBuildingManager:NeedShowBuildingName()
    return self.needShowBuildingName
end

function CityLegoBuildingManager:OnBuildingNameShow(city)
    if self.city ~= city then return end

    if not self.needShowBuildingName then
        self.needShowBuildingName = true
        for id, legoBuilding in pairs(self.legoBuildings) do
            legoBuilding:ShowName()
        end
    end
end

function CityLegoBuildingManager:OnBuildingNameHide(city)
    if self.city ~= city then return end

    if self.needShowBuildingName then
        self.needShowBuildingName = false
        for id, legoBuilding in pairs(self.legoBuildings) do
            legoBuilding:HideName()
        end
    end
end

---@param legoBuilding CityLegoBuilding
function CityLegoBuildingManager:PlayPutDownVfx(legoBuilding)
    local handle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    handle:Create("vfx_w_common_city_jiaju_fangzhi", "CityLegoBuilding", self.city.CityRoot.transform, function(flag, obj, tHandle)
        if not flag then return end
        tHandle.Effect.transform.position = self.city:GetCenterWorldPositionFromCoord(legoBuilding.x, legoBuilding.z, legoBuilding.sizeX, legoBuilding.sizeZ)
        tHandle.Effect.transform.localScale = CS.UnityEngine.Vector3(legoBuilding.sizeX * 0.1, 1, legoBuilding.sizeZ * 0.1)
    end)
end

return CityLegoBuildingManager