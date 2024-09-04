local BaseModule = require("BaseModule")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomConstant = require("KingdomConstant")
local PlayerModule = require('PlayerModule')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local I18N = require("I18N")
local EventConst = require("EventConst")
local UIMediatorNames = require("UIMediatorNames")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local ObjectType = require("ObjectType")
local ArtResourceUtils = require("ArtResourceUtils")
local AreaShape = require('AreaShape')
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')
local TouchMenuPageDatum = require("TouchMenuPageDatum")

local MapUtils = CS.Grid.MapUtils
local Vector2Short = CS.DragonReborn.Vector2Short

local BuildingTypes =
{
    DBEntityType.Village,
    DBEntityType.CastleBrief,
    DBEntityType.EnergyTower,
    DBEntityType.DefenceTower,
    DBEntityType.TransferTower,
    DBEntityType.MobileFortress,
}

---@class MapBuildingParameter
---@field EntityID number
---@field Owner wds.Owner
---@field MapBasics wds.MapEntityBasicInfo
---@field Army wds.Army
---@field StrengthenArmy wds.Strengthen
---@field Construction wds.BuildingConstruction
---@field VillageTransformInfo wds.VillageTransformInfo
---@field IsStrengthen boolean
---@field EntityTypeHash number

---@class MapBuildingTroopModule : BaseModule
---@field basicCamera BasicCamera
---@field staticMapData CS.Grid.StaticMapData
---@field mapBuildingProviders table<number, MapBuildingProvider>
local MapBuildingTroopModule = class("MapBuildingTroopModule", BaseModule)
MapBuildingTroopModule.HudHideFlag = HUDMediatorPartDefine.left | HUDMediatorPartDefine.allBottom | HUDMediatorPartDefine.right

MapBuildingTroopModule.ProcessBuildingChangeEntityPath = {
    DBEntityPath.Village.Army.MsgPath,
    DBEntityPath.CastleBrief.Army.MsgPath,
    DBEntityPath.EnergyTower.Army.MsgPath,
    DBEntityPath.DefenceTower.Army.MsgPath,
    DBEntityPath.TransferTower.Army.MsgPath,
    DBEntityPath.MobileFortress.Army.MsgPath,
    DBEntityPath.CommonMapBuilding.Army.MsgPath,

    DBEntityPath.EnergyTower.Strengthen.MsgPath,
    DBEntityPath.DefenceTower.Strengthen.MsgPath,
    DBEntityPath.TransferTower.Strengthen.MsgPath,
    DBEntityPath.MobileFortress.Strengthen.MsgPath,
    DBEntityPath.CommonMapBuilding.Strengthen.MsgPath,
}

MapBuildingTroopModule.ProcessBuildingStatusChangeEntityPath = {
    DBEntityPath.Village.Construction.Status.MsgPath,
    DBEntityPath.EnergyTower.Construction.Status.MsgPath,
    DBEntityPath.DefenceTower.Construction.Status.MsgPath,
    DBEntityPath.TransferTower.Construction.Status.MsgPath,
    DBEntityPath.MobileFortress.Construction.Status.MsgPath,
    DBEntityPath.CommonMapBuilding.Construction.Status.MsgPath,
}

MapBuildingTroopModule.ProcessBuildingSpeedChangeEntityPath = {
    DBEntityPath.Village.Construction.BuildSpeed.MsgPath,
    DBEntityPath.EnergyTower.Construction.BuildSpeed.MsgPath,
    DBEntityPath.DefenceTower.Construction.BuildSpeed.MsgPath,
    DBEntityPath.TransferTower.Construction.BuildSpeed.MsgPath,
    DBEntityPath.MobileFortress.Construction.BuildSpeed.MsgPath,
    DBEntityPath.CommonMapBuilding.Construction.BuildSpeed.MsgPath,
    DBEntityPath.Village.VillageTransformInfo.Speed.MsgPath,
}

function MapBuildingTroopModule:OnRegister()
    self.basicCamera = KingdomMapUtils.GetBasicCamera()
    self.staticMapData = KingdomMapUtils.GetStaticMapData()
    
    self.mapBuildingProviders =
    {
        [wds.PlayerMapCreep.TypeHash] = require("MapBuildingProviderCreepTumor"),
        [wds.CastleBrief.TypeHash] = require("MapBuildingProviderCastle"),
        [wds.FakeCastle.TypeHash] = require("MapBuildingProviderCastle"),
        [wds.ResourceField.TypeHash] = require("MapBuildingProviderResourceField"),
        [wds.Village.TypeHash] = require("MapBuildingProviderVillage"),
        [wds.Pass.TypeHash] = require("MapBuildingProviderVillage"),
        [wds.BehemothCage.TypeHash] = require("MapBuildingProviderBehemothCage"),
        [wds.CommonMapBuilding.TypeHash] = require("MapBuildingProviderCommonMapBuilding"),
        [wds.DefenceTower.TypeHash] = require("MapBuildingProviderDefenseTower"),
        [wds.EnergyTower.TypeHash] = require("MapBuildingProviderEnergyTower"),
    }

    self.ColorArmyGreen = UIHelper.TryParseHtmlString(ColorConsts.army_green)
    self.ColorArmyBlue = UIHelper.TryParseHtmlString(ColorConsts.army_blue)
    self.ColorArmyPink = UIHelper.TryParseHtmlString(ColorConsts.army_pink)
    self.ColorArmyWhite = UIHelper.TryParseHtmlString(ColorConsts.army_white)
    self.ColorArmyRed = UIHelper.TryParseHtmlString(ColorConsts.army_red)

end

function MapBuildingTroopModule:OnRemove()
    self.mapBuildingProviders = nil
end

function MapBuildingTroopModule:RegisterAllBuildingChange(delegate)
    for _, path in ipairs(MapBuildingTroopModule.ProcessBuildingChangeEntityPath) do
        g_Game.DatabaseManager:AddChanged(path, delegate)
    end
end

function MapBuildingTroopModule:UnregisterAllBuildingChange(delegate)
    for _, path in ipairs(MapBuildingTroopModule.ProcessBuildingChangeEntityPath) do
        g_Game.DatabaseManager:RemoveChanged(path, delegate)
    end
end

function MapBuildingTroopModule:RegisterAllBuildingNew(delegate)
    for _, t in ipairs(BuildingTypes) do
        g_Game.DatabaseManager:AddEntityNewByType(t, delegate)
    end
end

function MapBuildingTroopModule:UnregisterAllBuildingNew(delegate)
    for _, t in ipairs(BuildingTypes) do
        g_Game.DatabaseManager:RemoveEntityNewByType(t, delegate)
    end
end

function MapBuildingTroopModule:RegisterAllBuildingDestroy(delegate)
    for _, t in ipairs(BuildingTypes) do
        g_Game.DatabaseManager:AddEntityDestroyByType(t, delegate)
    end
end

function MapBuildingTroopModule:UnregisterAllBuildingDestroy(delegate)
    for _, t in ipairs(BuildingTypes) do
        g_Game.DatabaseManager:RemoveEntityDestroyByType(t, delegate)
    end
end

function MapBuildingTroopModule:RegisterAllBuildingBuildStatusChange(delegate)
    for _, path in ipairs(MapBuildingTroopModule.ProcessBuildingStatusChangeEntityPath) do
        g_Game.DatabaseManager:AddChanged(path, delegate)
    end
end

function MapBuildingTroopModule:UnregisterAllBuildingBuildStatusChange(delegate)
    for _, path in ipairs(MapBuildingTroopModule.ProcessBuildingStatusChangeEntityPath) do
        g_Game.DatabaseManager:RemoveChanged(path, delegate)
    end
end

function MapBuildingTroopModule:RegisterAllBuildingBuildSpeedChange(delegate)
    for _, path in ipairs(MapBuildingTroopModule.ProcessBuildingSpeedChangeEntityPath) do
        g_Game.DatabaseManager:AddChanged(path, delegate)
    end
end

function MapBuildingTroopModule:UnregisterAllBuildingBuildSpeedChange(delegate)
    for _, path in ipairs(MapBuildingTroopModule.ProcessBuildingSpeedChangeEntityPath) do
        g_Game.DatabaseManager:RemoveChanged(path, delegate)
    end
end

---@type wds.DefenceTower | wds.EnergyTower | wds.TransferTower
function MapBuildingTroopModule.IsSlgBuilding(entity)
    return entity.TypeHash == DBEntityType.DefenceTower 
            or entity.TypeHash == DBEntityType.EnergyTower 
            or entity.TypeHash == DBEntityType.TransferTower
end

---@param tile MapRetrieveResult
function MapBuildingTroopModule:ShowNpcTroopInfo(tile)
    if not tile.entity then
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.MapBuildingNPCTroopUIMediator, tile)
end

---@param tile MapRetrieveResult
function MapBuildingTroopModule:ShowTroopInfo(tile, noFocusBuilding)
    if not tile.entity then
        return
    end
    local position = tile.entity.MapBasics.Position
    local call = function()
        ---@type MapBuildingParameter
        local param = {
            EntityID = tile.entity.ID,
            Owner = tile.entity.Owner,
            MapBasics = tile.entity.MapBasics,
            Army = tile.entity.Army,
            Construction = tile.entity.Construction,
            EntityTypeHash = tile.entity.TypeHash
        }
        g_Game.UIManager:Open(UIMediatorNames.MapBuildingTroopReinforceUIMediator, param)
    end
    if noFocusBuilding then
        call()
    else
        self:FocusBuilding(position.X, position.Y, call)
    end
end

---@param coord CS.DragonReborn.Vector2Short
function MapBuildingTroopModule:FocusBuilding(tileX, tileZ, callback)
    self.prevCameraSize = self.basicCamera:GetSize()
    self.prevCameraAnchor = KingdomMapUtils.GetCameraAnchorPosition()
    self.prevCameraEnableDragging = self.basicCamera.enableDragging
    self.prevCameraEnablePinch = self.basicCamera.enablePinch

    self.basicCamera.enableDragging = false
    self.basicCamera.enablePinch = false

    tileX = math.round(tileX) + KingdomConstant.CameraFocusBuildingTileOffsetX
    tileZ = math.round(tileZ) + KingdomConstant.CameraFocusBuildingTileOffsetY
    
    local targetPosition = MapUtils.CalculateCoordToTerrainPosition(tileX, tileZ, KingdomMapUtils.GetMapSystem())
    local size = KingdomConstant.CameraMinSize
    local duration = KingdomConstant.CameraFocusDuration / 2
    KingdomMapUtils.MoveAndZoomCamera(targetPosition, size, duration, duration, nil, callback)

    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, MapBuildingTroopModule.HudHideFlag, false)
end

function MapBuildingTroopModule:ResetCamera()
    self.basicCamera.enableDragging = self.prevCameraEnableDragging
    self.basicCamera.enablePinch = self.prevCameraEnablePinch
    local duration = KingdomConstant.CameraFocusDuration / 2
    KingdomMapUtils.MoveAndZoomCamera(self.prevCameraAnchor, self.prevCameraSize, duration, duration)

    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, MapBuildingTroopModule.HudHideFlag, true)
end

function MapBuildingTroopModule:GetBuildingName(entity)
    local provider = self.mapBuildingProviders[entity.TypeHash]
    if provider then
        return provider.GetName(entity)
    end

    if entity.MapBasics then
        local config = self:GetBuildingConfig(entity.MapBasics.ConfID)
        if config ~= nil then
            return I18N.Get(config:Name())
        end
    end
    return string.Empty
end

function MapBuildingTroopModule:GetBuildingLevel(entity)
    local provider = self.mapBuildingProviders[entity.TypeHash]
    if provider then
        return provider.GetLevel(entity)
    end

    if entity.MapBasics then
        local config = self:GetBuildingConfig(entity.MapBasics.ConfID)
        if config ~= nil then
            return config:Level()
        end
    end
    return 0
end

function MapBuildingTroopModule:GetBuildingImage(entity)
    local provider = self.mapBuildingProviders[entity.TypeHash]
    if provider then
        return provider.GetBuildingImage(entity)
    end
    if entity.MapBasics then
        local config = self:GetBuildingConfig(entity.MapBasics.ConfID)
        if config ~= nil then
            return UIHelper.IconOrMissing(config:Image() ~= 0 and ArtResourceUtils.GetUIItem(config:Image()))
        end
    end
    return string.Empty
end

function MapBuildingTroopModule:GetBuildingIcon(entity, lod)
    local provider = self.mapBuildingProviders[entity.TypeHash]
    if provider then
        return provider.GetIcon(entity, lod)
    end
    return string.Empty
end

---@param entity wds.Village
---@param touchData TouchMenuUIDatum
---@return boolean @modified
function MapBuildingTroopModule:ExtraHighLodDataProcessor(entity, touchData)
    if not entity or not entity.TypeHash or not touchData then
        return false
    end
    if entity.TypeHash == DBEntityType.Village then
        local pairOccupiedAlliances = require("KingdomTouchInfoProviderVillage").GetOccupyInfoPart(entity)
        if pairOccupiedAlliances then
            if touchData.pages then
                ---@type TouchMenuPageDatum
                local touchMainPage = touchData.pages[1]
                if touchMainPage and touchMainPage.is and touchMainPage:is(TouchMenuPageDatum) then
                    if touchMainPage.basic and not touchMainPage.basic.image then
                        touchMainPage.basic:SetImage(self:GetBuildingImage(entity))
                    end
                    touchMainPage.compsData = touchMainPage.compsData or {}
                    table.insert(touchMainPage.compsData, pairOccupiedAlliances)
                    return true
                end
            end
        end
    end
    return false
end

---@param owner wds.Owner
function MapBuildingTroopModule:GetColor(owner, isCreepInfected, noAllianceAsHostile)
    return self:GetColorByID(owner.PlayerID, owner.AllianceID, isCreepInfected, noAllianceAsHostile)
end

function MapBuildingTroopModule:GetColorByID(playerID, allianceID, isCreepInfected, noAllianceAsHostile)
    if ModuleRefer.PlayerModule:IsMineById(playerID) then
        return self.ColorArmyGreen
    elseif ModuleRefer.PlayerModule:IsFriendlyById(allianceID, playerID) then
        return self.ColorArmyBlue
    elseif ModuleRefer.PlayerModule:IsNeutral(allianceID) and not noAllianceAsHostile then
        if isCreepInfected then
            return self.ColorArmyPink
        else
            return self.ColorArmyWhite
        end
    else
        return self.ColorArmyRed
    end
    return self.ColorArmyWhite
end

---@param buildingConfigId number
---@return FlexibleMapBuildingConfigCell|FixedMapBuildingConfigCell
function MapBuildingTroopModule:GetBuildingConfig(buildingConfigId)
    local config = ConfigRefer.FlexibleMapBuilding:Find(buildingConfigId)
    if not config then
        config = ConfigRefer.FixedMapBuilding:Find(buildingConfigId)
    end
    return config
end

---@param entity wds.CastleBrief
function MapBuildingTroopModule:GetStrongholdLevel(entity)
    if entity and entity.BasicInfo then
        return entity.BasicInfo.MainBuildingLevel
    end
    return 1
end

---@param entityID number
---@param troopID number
function MapBuildingTroopModule:LeaveTroopFrom(entityID, troopID, isStrengthen)
    if isStrengthen then
        ModuleRefer.SlgModule:LeaveStrengthen(entityID, troopID)
    else
        ModuleRefer.SlgModule:LeaveReinforce(entityID, troopID)
    end
end

---@param troop wds.Troop
function MapBuildingTroopModule:IsMyTroop(troop)
    return ModuleRefer.PlayerModule:IsMine(troop.Owner)
end

---@param army wds.Army
function MapBuildingTroopModule:IsNPCTroopInit(army)
    return army.DummyTroopInitFinish
end

---@param mapBasics wds.MapEntityBasicInfo
function MapBuildingTroopModule:GetMaxTroopCount(mapBasics)
    local config = self:GetBuildingConfig(mapBasics.ConfID)
    if config then
        return config:MaxReinforceCount()
    end
    return ConfigRefer.ConstMain:CastleReinforceMaxTroopCount()
end

---@param army wds.Army
function MapBuildingTroopModule:GetReinforceCount(army)
    if not army or not army.PlayerTroopIDs or not army.PlayerOnRoadTroopIDs then
        return 0
    end
    return table.nums(army.PlayerTroopIDs) + table.nums(army.PlayerOnRoadTroopIDs)
end

---@param army wds.Strengthen
function MapBuildingTroopModule:GetReinforceCountStrengthen(army)
    if not army or not army.PlayerTroopIDs or not army.PlayerOnRoadTroopIDs then
        return 0
    end
    return table.nums(army.PlayerTroopIDs) + table.nums(army.PlayerOnRoadTroopIDs)
end

---@param army wds.Army
---@param mapBasics wds.MapEntityBasicInfo
function MapBuildingTroopModule:GetNpcTroopCount(army, mapBasics)
    if not army then
        return 0
    end
    if army.DummyTroopInitFinish then
        return table.nums(army.DummyTroopIDs)
    else
        local config = self:GetBuildingConfig(mapBasics.ConfID)
        return config.InitTroopsLength and config:InitTroopsLength() or 0
    end
end

---@param army wds.Army
function MapBuildingTroopModule:GetMyTroopCount(army)
    local count = 0
    if army then
        ---@param armyMemberInfo wds.ArmyMemberInfo
        for _,armyMemberInfo in pairs(army.PlayerTroopIDs) do
            ---@type wds.Troop
            if armyMemberInfo then
                if ModuleRefer.PlayerModule:IsMineById(armyMemberInfo.PlayerId) then
                    count = count + 1
                end    
            end
        end
    end
    return count
end

---@param army wds.Army
---@return wds.ArmyMemberInfo
function MapBuildingTroopModule:HasPlayerTroop(army)
    if army then
        ---@param armyMemberInfo wds.ArmyMemberInfo
        for _,armyMemberInfo in pairs(army.PlayerTroopIDs) do
            ---@type wds.Troop
            if armyMemberInfo then
                return true
            end
        end
    end
    return false
end

---@param army wds.Army
---@return wds.ArmyMemberInfo
function MapBuildingTroopModule:GetMyTroop(army)
    local playerID = ModuleRefer.PlayerModule.playerId
    return self:GetPlayerTroop(army, playerID)
end

---@param army wds.Army
---@return wds.ArmyMemberInfo
function MapBuildingTroopModule:GetPlayerTroop(army, playerID)
    if army then
        ---@param armyMemberInfo wds.ArmyMemberInfo
        for _,armyMemberInfo in pairs(army.PlayerTroopIDs) do
            ---@type wds.Troop
            if armyMemberInfo then
                if armyMemberInfo.PlayerId == playerID then
                    return armyMemberInfo
                end
            end
        end
    end
end

---@param army wds.Army
---@param mapBasics wds.MapEntityBasicInfo
---@param strengthArmy wds.Strengthen
function MapBuildingTroopModule:GetTotalTroopCount(army, mapBasics, strengthArmy)
    return self:GetNpcTroopCount(army, mapBasics) + self:GetReinforceCount(army) + self:GetReinforceCountStrengthen(strengthArmy)
end

---@param army wds.Army
---@param mapBasics wds.MapEntityBasicInfo
---@param strengthArmy wds.Strengthen
function MapBuildingTroopModule:IsBuildingTroopFull(army, mapBasics, strengthArmy)
   return (self:GetReinforceCount(army) + self:GetReinforceCountStrengthen(strengthArmy)) >= self:GetMaxTroopCount(mapBasics)
end

---@param army wds.Army
function MapBuildingTroopModule:GetNpcTroopHP(army)
    if not army then
        return 0, 1
    end
    local hp = 0
    local hpMax = 0
    if army.DummyTroopInitFinish then
        for _, armyMemberInfo in pairs(army.DummyTroopIDs) do
            hp = hp + armyMemberInfo.Hp
            hpMax = hpMax + armyMemberInfo.HpMax
        end
    else
        --local config = self:GetBuildingConfig(mapBasics.ConfID)
        --for i = 1, config:InitTroopsLength() do
        --    local monsterID = config:InitTroops(i)
        --    local monsterConfig = ConfigRefer.KmonsterData:Find(monsterID)
        --    for j = 1, monsterConfig:HeroLength() do
        --        local heroNPCID = monsterConfig:Hero(j):HeroConf()
        --        local heroNPCConfig = ConfigRefer.HeroNpc:Find(heroNPCID)
        --        local heroConfig = ConfigRefer.Heroes:Find(heroNPCConfig:HeroConfigId())
        --    end
        --end
    end
    return math.max(hp, 0), math.max(hpMax, 0)
end

---@param army wds.Army
function MapBuildingTroopModule:GetMyTroopHP(army)
    if not army then
        return 0, 1
    end
    local hp = 0
    local hpMax = 0
    for _, armyMemberInfo in pairs(army.PlayerTroopIDs) do
        if ModuleRefer.PlayerModule:IsMineById(armyMemberInfo.PlayerId) then
            hp = hp + armyMemberInfo.Hp
            hpMax = hpMax + armyMemberInfo.HpMax
        end
    end
    return math.max(hp, 0), math.max(hpMax, 0)
end

---@param army wds.Army
function MapBuildingTroopModule:GetMyTroopCollectLoad(army)
    if not army then
        return 0
    end
    local load = 0
    for _, armyMemberInfo in pairs(army.PlayerTroopIDs) do
        if ModuleRefer.PlayerModule:IsMineById(armyMemberInfo.PlayerId) then
        end
    end
    return math.max(load, 0)
end

---@param army wds.Army
function MapBuildingTroopModule:GetMyTroopCollectSpeed(army)
    if not army then
        return 0
    end
    local load = 0
    for _, armyMemberInfo in pairs(army.PlayerTroopIDs) do
        if ModuleRefer.PlayerModule:IsMineById(armyMemberInfo.PlayerId) then
            for _, heroID in pairs(armyMemberInfo.HeroTId) do
                local heroLoad = ModuleRefer.TroopModule:GetTroopHeroCollectSpeed(heroID)
                load = load + heroLoad
            end
        end
    end
    return math.max(load, 0)
end

---@param army wds.Army
function MapBuildingTroopModule:GetPlayerTroopHP(army)
    if not army then
        return 0, 1
    end
    local hp = 0
    local hpMax = 0
    for _, armyMemberInfo in pairs(army.PlayerTroopIDs) do
        hp = hp + armyMemberInfo.Hp
        hpMax = hpMax + armyMemberInfo.HpMax
    end
    return math.max(hp, 0), math.max(hpMax, 0)
end

---@param army wds.Army
function MapBuildingTroopModule:GetTotalTroopHP(army)
    local npcHP, npcHPMax = self:GetNpcTroopHP(army)
    local playerHP, playerHPMax = self:GetPlayerTroopHP(army)
    return npcHP + playerHP, npcHPMax + playerHPMax
end

---@param troop wds.ArmyMemberInfo
function MapBuildingTroopModule:GetTroopHeroSpriteName(troop)
    if troop and troop.HeroTId:Count() > 0 then
        local heroConfigID = troop.HeroTId[1]
        local heroConfig = ConfigRefer.Heroes:Find(heroConfigID)
        return ModuleRefer.MapBuildingTroopModule:GetHeroSpriteName(heroConfig)
    end
    return string.Empty
end

---@param heroConfig HeroesConfigCell
function MapBuildingTroopModule:GetHeroSpriteName(heroConfig)
    if heroConfig then
        local heroResConfig = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())
        return ArtResourceUtils.GetUIItem(heroResConfig:HeadMini())
    end
    return string.Empty
end

---@param mapBasics wds.MapEntityBasicInfo
---@param construction wds.BuildingConstruction
---@param transformInfo wds.VillageTransformInfo
function MapBuildingTroopModule:GetBuffString(mapBasics, construction, transformInfo)
    local buff = 0
    if transformInfo then
        local allianceCenter = ConfigRefer.AllianceCenter:Find(ConfigRefer.FixedMapBuilding:Find(mapBasics.ConfID):BuildAllianceCenter())
        local change = allianceCenter:BuildSpeedValue()
        buff = ((transformInfo.Speed - change) / change) + 1
    elseif construction then
        local buildingConfig = self:GetBuildingConfig(mapBasics.ConfID)
        local change = buildingConfig:BuildSpeedValue()
        buff = ((construction.BuildSpeed - change) / change) + 1
    end
    return string.format("%.2f", buff * 100)
end

---@param heroConfig HeroesConfigCell
function MapBuildingTroopModule:GetHeroSpriteName(heroConfig)
    if heroConfig then
        local heroResConfig = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())
        return ArtResourceUtils.GetUIItem(heroResConfig:HeadMini())
    end
    return string.Empty
end

function MapBuildingTroopModule:GetBuildingAffectedRange(entity)
    local mapBasics = entity.MapBasics
    local positionX = mapBasics.Position.X
    local positionY = mapBasics.Position.Y
    local buildingX = mapBasics.BuildingPos.X
    local buildingY = mapBasics.BuildingPos.Y
    if entity.TypeHash == DBEntityType.Expedition then
        local instanceCfg = ConfigRefer.WorldExpeditionTemplateInstance:Find(entity.ExpeditionInfo.Tid)
        if not instanceCfg then
            g_Logger.Error("can't find event config:"..entity.ExpeditionInfo.Tid)
            return positionX, positionY, 0, 0
        end
        local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(instanceCfg:Template())
        local ra = eventCfg:RadiusA()
        if eventCfg:Shape() == AreaShape.Ellipse then
            local rb = eventCfg:RadiusB()
            local rot = math.radian2angle(instanceCfg:Rot())
            local rectX = math.sqrt(ra * ra * math.cos(rot) * math.cos(rot) + rb * rb * math.sin(rot) * math.sin(rot))
            local sizeA = math.ceil(rectX * 2)
            local rectY = math.sqrt(rb * rb * math.cos(rot) * math.cos(rot) + ra * ra * math.sin(rot) * math.sin(rot))
            local sizeB = math.ceil(rectY * 2)
            return math.floor(buildingX - rectX), math.floor(buildingY - rectY), sizeA, sizeB
        else
            return math.floor(buildingX - ra), math.floor(buildingY - ra), math.ceil(ra * 2), math.ceil(ra * 2)
        end
    elseif entity.TypeHash == DBEntityType.EnergyTower
            or entity.TypeHash == DBEntityType.DefenceTower then
        local buildingConfig = ConfigRefer.FlexibleMapBuilding:Find(entity.MapBasics.ConfID)
        local size = buildingConfig:EffectRaid()
        return math.floor(positionX - size),
        math.floor(positionY - size),
        math.ceil(positionX + size),
        math.ceil(positionY + size)
    else
        local layout = ModuleRefer.MapBuildingLayoutModule:GetLayout(mapBasics.LayoutCfgId)
        return buildingX, buildingY, layout.SizeX, layout.SizeY
    end
end

return MapBuildingTroopModule