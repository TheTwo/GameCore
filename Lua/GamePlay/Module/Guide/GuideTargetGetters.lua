local GuideZoneType = require('GuideZoneType')
local GuideConst = require('GuideConst')
local GuideUtils = require('GuideUtils')
local Utils = require('Utils')
local ModuleRefer = require('ModuleRefer')
local KingdomMapUtils = require('KingdomMapUtils')
local DBEntityType = require('DBEntityType')
local ConfigRefer = require('ConfigRefer')
---@class GuideTargetGetters
local GuideTargetGetters = class('GuideTargetGetters')

---@class StepTargetData
---@field type TargetTypeEnum
---@field target CS.UnityEngine.RectTransform | CityCellTile | TroopCtrl
---@field position CS.UnityEngine.Vector3 | CS.UnityEngine.Vector2
---@field range number

---@return boolean, StepTargetData | string
function GuideTargetGetters.GetStepTarget_UIElement(zoneCfg)
    local winName = zoneCfg:UIName()
    local ctrlName = zoneCfg:CtrlName()
    local ctrlIndex = zoneCfg:CtrlIndex()
    local uiTrans = g_Game.UIManager:FindUICtrl(winName,ctrlName,ctrlIndex,g_Game.UIManager.UIMediatorType.Popup)
    if not uiTrans then
        local errorInfo = string.format('查找UI控件失败：name:%s index:%d',ctrlName,ctrlIndex)
        return false, errorInfo
    end
    return true, {
        type = GuideConst.TargetTypeEnum.UITrans,
        target = uiTrans,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CityBuilding(zoneCfg)
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    if myCity and elementId then
        local tiles = myCity:GetCityCellTilesByBuildingType(elementId)
        if tiles and #tiles > 0 then
            tile = GuideUtils.GetNearestTile(tiles)
        end
    end
    if not tile then
        return false, string.format('查找主城建筑失败 ElementId:%d', elementId)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.CityTile,
        target = tile,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CityFurniture(zoneCfg)
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    if myCity and elementId then
        local tiles = myCity:GetFurnitureTilesByFurnitureType(elementId)
        if tiles and #tiles > 0 then
            tile = GuideUtils.GetNearestTile(tiles)
        end
    end
    if not tile then
        return false, string.format('查找主城家具失败 ElementId:%d', elementId)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.CityTile,
        target = tile,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CityNpc(zoneCfg)
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    if myCity and elementId then
        local tiles = myCity:GetCellTilesByNpcConfigId(elementId)
        if tiles and #tiles > 0 then
            tile = GuideUtils.GetNearestTile(tiles)
        end
    end
    if tile and tile.tileView then
        local rotRoot = tile.tileView:GetAssetAttachTrans(true)
        local bubble = rotRoot:Find("ui3d_bubble_group/p_rotation/p_position/p_progress")
        local needBubble = rotRoot:Find("ui3d_bubble_need/p_rotation/p_position/p_frame")
        if bubble and Utils.IsNotNull(bubble) then
            return {
                type = GuideConst.TargetTypeEnum.Transform,
                target = bubble.transform,
                range = zoneCfg:Range()
            }
        elseif needBubble and Utils.IsNotNull(needBubble) then
            return {
                type = GuideConst.TargetTypeEnum.Transform,
                target = needBubble.transform,
                range = zoneCfg:Range()
            }
        elseif rotRoot and Utils.IsNotNull(rotRoot) then
            return {
                type = GuideConst.TargetTypeEnum.Transform,
                target = rotRoot.transform,
                range = zoneCfg:Range()
            }
        end
    end
    return false, string.format('查找主城NPC失败 ElementId:%d', elementId)
end

function GuideTargetGetters.GetStepTarget_CityResource(zoneCfg)
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    if myCity and elementId then
        local tiles = myCity:GetCityCellTilesByResourceType(elementId)
        local worktype = require("CityWorkTargetType").Resource
        if tiles and #tiles > 0 then
            for _, value in pairs(tiles) do
                local cell = value:GetCell()
                if cell and not value:IsPolluted() and (myCity.cityCitizenManager:GetWorkDataByTarget(cell.tileId, worktype) == nil) then
                    tile = value
                    break
                end
            end
        end
    end
    if not tile then
        return false, string.format('查找主城资源失败 ElementId:%d', elementId)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.CityTile,
        target = tile,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CityZone(zoneCfg)
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tilePos = nil
    if myCity and elementId then
        local zone = myCity.zoneManager:GetZoneById(elementId)
        if zone then
            tilePos = zone:WorldCenter()
        end
    end
    if not tilePos then
        return false, string.format('查找主城区域失败 ElementId:%d', elementId)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = tilePos,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CityCreepBlock(zoneCfg)
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tilePos = nil
    if myCity and myCity.gridView and elementId then
        local creepManager = myCity.creepManager
        local sceneCam = myCity:GetCamera()
        local lookatPos = sceneCam:GetLookAtPosition()
        local lookX, lookY = myCity:GetCoordFromPosition(lookatPos)
        local affectX,affectY
        if creepManager then
            local minDist = creepManager.area.maxX * creepManager.area.maxX + creepManager.area.maxY * creepManager.area.maxY   --511*511

            for x,y, value in creepManager.area:pairs() do
                if GuideUtils.IsTileHasByCreepBlock(value,elementId) then
                    local dist = (x - lookX)*(x - lookX) + (y - lookY)*(y - lookY)
                    if minDist > dist and not myCity:IsFogMask(x, y) then
                        minDist = dist
                        affectX = x
                        affectY = y
                    end
                end
            end

            if affectX and affectY then
                tilePos = myCity:GetWorldPositionFromCoord(affectX,affectY)
                local tileScale = myCity.scale * 0.5
                tilePos.x = tilePos.x + tileScale * myCity.gridConfig.unitsPerCellX
                tilePos.z = tilePos.z + tileScale * myCity.gridConfig.unitsPerCellY
            end
        end
    end
    if not tilePos then
        return false, string.format('查找主城CreepZone失败 ElementId:%d', elementId)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = tilePos,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CitySpawner(zoneCfg)
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local position = nil
    if myCity then
        position = myCity:GetWorldPositionBySpawnerConfigId(elementId)
    end
    if not position then
        return false, string.format('查找Spawner失败, ElementId:%d',elementId)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = position,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CityBuildingBubble(zoneCfg)
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile
    local errorInfo = ''
    if myCity and elementId then
        --查找主城内的建筑，CtrlName为建筑的类型枚举值（BuildingType的枚举值）
        local tiles = myCity:GetCityCellTilesByBuildingType(elementId)
        if tiles and #tiles > 0 then
            tile = GuideUtils.GetNearestTile(tiles)
            if tile and tile.tileView then
                local rotRoot = tile.tileView:GetAssetAttachTrans(true)
                local bubble = rotRoot:Find("ui3d_bubble_progress/p_rotation/p_position/p_icon_status")
                if bubble and Utils.IsNotNull(bubble) then
                    return true, {
                        type = GuideConst.TargetTypeEnum.Transform,
                        target = bubble.transform,
                        range = zoneCfg:Range()
                    }
                elseif rotRoot and Utils.IsNotNull(rotRoot) then
                    return true, {
                        type = GuideConst.TargetTypeEnum.Transform,
                        target = rotRoot.transform,
                        range = zoneCfg:Range()
                    }
                else
                    errorInfo = string.format('查找建筑泡泡失败 ElementId:%d',elementId)
                end
            else
                errorInfo = string.format('查找建筑泡泡失败 ElementId:%d',elementId)
            end
        end
    else
        errorInfo = "没有配置正确的建筑ID"
    end
    return false, errorInfo
end

function GuideTargetGetters.GetStepTarget_CityAreaWallBubble(zoneCfg)
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local errorInfo
    if myCity and elementId then
        local doorTile = myCity.safeAreaWallMgr:GetTile(elementId)
        if doorTile and doorTile.tileView then
            local rotRoot = doorTile.tileView:GetAssetAttachTrans(true)
            local bubble = rotRoot:Find("ui3d_bubble_progress/p_rotation/p_position/p_icon_status")
            if bubble and Utils.IsNotNull(bubble) then
                return true, {
                    type = GuideConst.TargetTypeEnum.Transform,
                    target = bubble.transform,
                    range = zoneCfg:Range()
                }
            elseif rotRoot and Utils.IsNotNull(rotRoot) then
                return true, {
                    type = GuideConst.TargetTypeEnum.Transform,
                    target = rotRoot.transform,
                    range = zoneCfg:Range()
                }
            else
                errorInfo = string.format('查找城墙门泡泡失败 ElementId:%d',elementId)
            end
        else
            errorInfo = string.format('查找城墙门失败 ElementId:%d',elementId)
        end
    else
        errorInfo = '没有配置正确的城墙门ID'
    end
    return false, errorInfo
end

function GuideTargetGetters.GetStepTarget_KingdomBuilding(zoneCfg)
    --TODO: find kingdom building
    return false, string.Empty
end

function GuideTargetGetters.GetStepTarget_KingdomMob(zoneCfg)
    local troopData = nil
    local troops = ModuleRefer.SlgModule:GetMobTroops()
    local lvl = zoneCfg:CtrlIndex()
    for _, value in pairs(troops) do
        if value.MobInfo.Level == lvl then
            troopData = value
            break
        end
    end
    if not troopData then
        return false, string.format('查找怪物部队失败, Lvl:%d', lvl)
    end
    local ctrl = ModuleRefer.SlgModule:GetTroopCtrl(troopData.ID)
    return true, {
        type = GuideConst.TargetTypeEnum.Troop,
        target = ctrl,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_KingdomTroop(zoneCfg)
    local troopData = nil
    local troops = ModuleRefer.SlgModule:GetMyTroops()
    local index = zoneCfg:CtrlIndex()
    if troops[index] then
        troopData = troops[index].entityData
    end
    if not troopData then
        return false, string.format('查找部队失败, index:%d', index)
    end
    local ctrl = ModuleRefer.SlgModule:GetTroopCtrl(troopData.ID)
    return true, {
        type = GuideConst.TargetTypeEnum.Troop,
        target = ctrl,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_WorldPos(zoneCfg)
    local pos = zoneCfg:WorldPos()
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = CS.UnityEngine.Vector3(pos:X(),pos:Y(),pos:Z()),
        range = zoneCfg:Range(),
    }
end

function GuideTargetGetters.GetStepTarget_ScreenPos(zoneCfg)
    local pos = zoneCfg:ScreenPos()
    return true, {
        type = GuideConst.TargetTypeEnum.ScreenPos,
        position = CS.UnityEngine.Vector2(pos:X(),pos:Y()),
        range = zoneCfg:Range(),
    }
end

function GuideTargetGetters.GetStepTarget_CityCreepElement(zoneCfg)
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    if myCity and elementId then
        --查找主城内的菌毯节点
        local tiles = myCity:GetCellTilesByCreepConfigId(elementId,true)
        if tiles and #tiles > 0 then
            tile = GuideUtils.GetNearestTile(tiles)
        end
    end
    if not tile then
        return false, string.format('查找主城菌毯失败 ElementId:%d', elementId)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.CityTile,
        target = tile,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_KingdomResource(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local allResourceFields = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.ResourceField)
    for _, value in pairs(allResourceFields) do
        local cfgId = value.FieldInfo.ConfID
        if cfgId == elementId and ModuleRefer.PlayerModule:IsEmpty(value.Owner) and
            ModuleRefer.MapFogModule:IsFogUnlocked(value.MapBasics.BuildingPos.X, value.MapBasics.BuildingPos.Y) then
                tile = value
        end
    end
    if not tile then
        return false, string.format('查找资源田失败 ElementId:%d', elementId)
    end
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local x = tile.MapBasics.BuildingPos.X * staticMapData.UnitsPerTileX
    local z = tile.MapBasics.BuildingPos.Y * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = CS.UnityEngine.Vector3(x, y, z),
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_KingdomCreep(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local allCreeps = ModuleRefer.MapCreepModule:GetAllCreeps()
    for _, value in pairs(allCreeps) do
        local cfgId = value.FieldInfo.ConfID
        if cfgId == elementId and ModuleRefer.MapFogModule:IsFogUnlocked(value.MapBasics.BuildingPos.X, value.MapBasics.BuildingPos.Y) then
            tile = value
        end
    end
    if not tile then
        return false, string.format('查找怪物失败 ElementId:%d', elementId)
    end
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local x = tile.MapBasics.BuildingPos.X * staticMapData.UnitsPerTileX
    local z = tile.MapBasics.BuildingPos.Y * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = CS.UnityEngine.Vector3(x, y, z),
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_KingdomMonster(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local mobCtrl = ModuleRefer.SlgModule.troopManager:FindMobCtrl(elementId)
    if not mobCtrl then
        return false, string.format('查找怪物失败 ElementId:%d', elementId)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.Mob,
        target = mobCtrl,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_KingdomMonsterLevel(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local mobCtrl = ModuleRefer.SlgModule.troopManager:FindLvMobCtrl(elementId)
    if not mobCtrl then
        return false, string.format('查找怪物失败 ElementId:%d', elementId)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.Mob,
        target = mobCtrl,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_KingdomMistCell(zoneCfg)
end

function GuideTargetGetters.GetStepTarget_KingdomMine(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local allMines = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.SlgInteractor)
    for _, value in pairs(allMines) do
        local cfgId = value.Interactor.ConfigID
        if cfgId == elementId and (ModuleRefer.MapFogModule:IsFogUnlocked(value.MapBasics.BuildingPos.X, value.MapBasics.BuildingPos.Y) or KingdomMapUtils.IsNewbieState()) then
            tile = value
        end
    end
    if not tile then
        return false, string.format('查找KingdomMine失败, ElementId:%d',elementId)
    end
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local x = tile.MapBasics.Position.X * staticMapData.UnitsPerTileX
    local z = tile.MapBasics.Position.Y * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = CS.UnityEngine.Vector3(x, y, z),
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_WorldExpedition(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local allWorldEvents = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Expedition)
    for _, value in pairs(allWorldEvents) do
        local cfgId = value.ExpeditionInfo.Tid
        if cfgId == elementId and (ModuleRefer.MapFogModule:IsFogUnlocked(value.MapBasics.BuildingPos.X, value.MapBasics.BuildingPos.Y) or KingdomMapUtils.IsNewbieState()) then
            tile = value
        end
    end
    if not tile then
        return false, string.format('查找WorldExpedition失败, ElementId:%d',elementId)
    end
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local x = tile.MapBasics.BuildingPos.X * staticMapData.UnitsPerTileX
    local z = tile.MapBasics.BuildingPos.Y * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = CS.UnityEngine.Vector3(x, y, z),
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_WorldFakeExpedition(zoneCfg)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = ModuleRefer.RadarModule:GetFakePos(),
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_WorldExpeditionLevel(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local allWorldEvents = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Expedition)
    for _, value in pairs(allWorldEvents) do
        local cfgId = value.ExpeditionInfo.Tid
        local templateCfg = ConfigRefer.WorldExpeditionTemplate:Find(cfgId)
        if templateCfg:Level() == elementId and (ModuleRefer.MapFogModule:IsFogUnlocked(value.MapBasics.BuildingPos.X, value.MapBasics.BuildingPos.Y) or KingdomMapUtils.IsNewbieState()) then
            tile = value
        end
    end
    if not tile then
        return false, string.format('查找WorldExpedition失败, Level:%d', elementId)
    end
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local x = tile.MapBasics.BuildingPos.X * staticMapData.UnitsPerTileX
    local z = tile.MapBasics.BuildingPos.Y * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = CS.UnityEngine.Vector3(x, y, z),
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_KingdomResourceLevel(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local allResourceFields = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.ResourceField)
    for _, value in pairs(allResourceFields) do
        local cfgId = value.FieldInfo.ConfID
        local config = ConfigRefer.FixedMapBuilding:Find(cfgId)
        if config:Level() == elementId and ModuleRefer.PlayerModule:IsEmpty(value.Owner) and
            ModuleRefer.MapFogModule:IsFogUnlocked(value.MapBasics.BuildingPos.X, value.MapBasics.BuildingPos.Y) then
                tile = value
        end
    end
    if not tile then
        return false, string.format('查找KingdomResource失败, Level:%d',elementId)
    end
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local x = tile.MapBasics.BuildingPos.X * staticMapData.UnitsPerTileX
    local z = tile.MapBasics.BuildingPos.Y * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = CS.UnityEngine.Vector3(x, y, z),
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_WorldPet(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local petList = ModuleRefer.PetModule:GetWorldPetList()
    local tile = nil
    for _, pdata in pairs(petList) do
        local petId = ConfigRefer.PetWild:Find(pdata.data.ConfigId):PetId()
        if elementId == petId then
            tile = pdata
        end
    end
    if not tile then
        return false, string.format('查找WorldPet失败, PetId:%d', elementId)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = tile.worldPos,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_KingdomCreepLevel(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local allCreeps = ModuleRefer.MapCreepModule:GetAllCreeps()
    for _, value in pairs(allCreeps) do
        local cfgId = value.FieldInfo.ConfID
        local config = ConfigRefer.FixedMapBuilding:Find(cfgId)
        if config:Level() == elementId and ModuleRefer.MapFogModule:IsFogUnlocked(value.MapBasics.BuildingPos.X, value.MapBasics.BuildingPos.Y) then
            tile = value
        end
    end
    if not tile then
        return false, string.format('查找KingdomCreep失败, Level:%d',elementId)
    end
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local x = tile.MapBasics.BuildingPos.X * staticMapData.UnitsPerTileX
    local z = tile.MapBasics.BuildingPos.Y * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = CS.UnityEngine.Vector3(x, y, z),
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CityResourceType(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local myCity = GuideUtils.FindMyCity()
    if myCity then
        local tiles = myCity:GetCellTilesByResourceType(elementId, true)
        if tiles and #tiles > 0 then
            tile = GuideUtils.GetNearestTile(tiles)
        end
    end
    if not tile then
        return false, string.format('查找主城内的采集类型失败, ElementId:%d', elementId)
    end

    return true, {
        type = GuideConst.TargetTypeEnum.CityTile,
        target = tile,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_KingdomSlgInteractor(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local allResourceFields = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.SlgInteractor)
    for _, value in pairs(allResourceFields) do
        local cfgId = value.Interactor.ConfigID
        if cfgId == elementId and ModuleRefer.MapFogModule:IsFogUnlocked(value.MapBasics.BuildingPos.X, value.MapBasics.BuildingPos.Y) then
            tile = value
        end
    end
    if not tile then
        return false, string.format('查找KingdomSlgInteractor失败, ElementId:%d', elementId)
    end
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local x = tile.MapBasics.BuildingPos.X * staticMapData.UnitsPerTileX
    local z = tile.MapBasics.BuildingPos.Y * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = CS.UnityEngine.Vector3(x, y, z),
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_GetCityPetList(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local myCity = GuideUtils.FindMyCity()
    local tile = nil
    if myCity then
        local params = string.split(elementName, ';')
        for i = 1, #params do
            if not tile then
                local petNpcId = tonumber(params[i])
                local tiles = myCity:GetCellTilesByNpcConfigId(petNpcId,true)
                if tiles and #tiles > 0 then
                    tile = GuideUtils.GetNearestTile(tiles)
                end
            end
        end
    end
    if not tile then
        return false, string.format('查找主城内的PetNpc失败, ElementId:%s',elementName)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.CityTile,
        target = tile,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_GetWorldPetList(zoneCfg)
    local elementName = zoneCfg:CtrlName()
    local params = string.split(elementName, ';')
    local petList = ModuleRefer.PetModule:GetWorldPetList()
    local tile = nil
    for i = 1, #params do
        local elementId = tonumber(params[i])
        for _, pdata in pairs(petList) do
            if not tile then
                local petId = ConfigRefer.PetWild:Find(pdata.data.ConfigId):PetId()
                if elementId == petId and not tile and ModuleRefer.MapFogModule:IsFogUnlocked(pdata.gridPos.X, pdata.gridPos.Y) then
                    tile = pdata
                end
            end
        end
    end
    if not tile then
        return false, string.format('查找WorldPetList失败, PetId:%s', elementName)
    end
    return {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = tile.worldPos,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_RewardRadarTask(zoneCfg)
    local uiTrans = ModuleRefer.RadarModule:GetRandomCanReceiveTaskTrans()
    if not uiTrans then
        return false, '查找可领奖雷达任务UI控件失败'
    end
    return true, {
        type = GuideConst.TargetTypeEnum.UITrans,
        target = uiTrans,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_WorldRewardInteractor(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local rewardBox = nil
    for _, data in pairs(player.PlayerWrapper2.PlayerRtBox.RtBoxes or {}) do
        if data.ConfigId == elementId then
            rewardBox = data
        end
    end
    if not rewardBox then
        return false, string.format('查找WorldRewardInteractor失败, Id:%d', elementId)
    end
    local wpos, _ = ModuleRefer.WorldRewardInteractorModule:GetWorldPos(rewardBox.Pos.X, rewardBox.Pos.Y)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = wpos,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_KingdomTerritory(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)

    local wpos, _ = ModuleRefer.TerritoryModule:GetNearestTerritoryPosition(nil, elementId)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = wpos,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_NearlyWorldExpedition(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local allWorldEvents = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.Expedition)
    local myCityCoord = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
    local dis = 0
    local minDis = math.huge
    for _, value in pairs(allWorldEvents) do
        if ModuleRefer.MapFogModule:IsFogUnlocked(value.MapBasics.BuildingPos.X, value.MapBasics.BuildingPos.Y) or KingdomMapUtils.IsNewbieState() then
            dis = CS.UnityEngine.Vector3.Distance(myCityCoord, value.MapBasics.BuildingPos)
            if dis < minDis then
                minDis = dis
                tile = value
            end
        end
    end
    if not tile then
        return false, string.format('查找NearlyWorldExpedition失败, ElementId:%d', elementId)
    end
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local x = tile.MapBasics.BuildingPos.X * staticMapData.UnitsPerTileX
    local z = tile.MapBasics.BuildingPos.Y * staticMapData.UnitsPerTileZ
    local y = KingdomMapUtils.SampleHeight(x, z)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = CS.UnityEngine.Vector3(x, y, z),
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CityElementResType(zoneCfg)
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local myCity = GuideUtils.FindMyCity()
    if myCity then
        local tiles = myCity:GetCellTilesByCityElementResType(elementId, true)
        if tiles and #tiles > 0 then
            tile = GuideUtils.GetNearestTile(tiles)
        end
    end
    if not tile then
        return false, string.format('主城内的采集资源点大类失败, ElementId:%d', elementId)
    end

    return true, {
        type = GuideConst.TargetTypeEnum.CityTile,
        target = tile,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CityRoom(zoneCfg)
    local elementName = zoneCfg:CtrlName()
    local roomCfgId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local myCity = GuideUtils.FindMyCity()
    if not myCity then
        return
    end
    local legoBuilding = myCity.legoManager:GetLegoBuildingByRoomCfgId(roomCfgId)
    if not legoBuilding then
        return false, string.format('查找主城内的房间失败, RoomCfgId:%d', roomCfgId)
    end
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = legoBuilding:GetWorldCenter(),
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CitizenBubble(zoneCfg)
    local elementName = zoneCfg:CtrlName()
    local citizenId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local myCity = GuideUtils.FindMyCity()
    if not myCity then
        return
    end
    local trans = myCity.cityCitizenManager:GetCitizenTaskBubbleTrans(citizenId)
    if not trans then
        return false, string.format('查找主城内的市民失败, CitizenId:%d', citizenId)
    end
     ---@type CS.UnityEngine.BoxCollider
    local touchCollider = trans.gameObject:GetComponent(typeof(CS.UnityEngine.BoxCollider))
    local wPos
    if Utils.IsNotNull(touchCollider) then
        wPos = touchCollider.transform:TransformPoint(touchCollider.center)
    else
        wPos = trans.position
    end
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = wPos,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_CityEggFurnitureBubble(zoneCfg)
    ---@type MyCity
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local tiles = myCity:GetFurnitureTilesByFurnitureType(elementId)
    if tiles and #tiles > 0 then
        tile = GuideUtils.GetNearestTile(tiles)
    end
    local errorInfo
    if not tile then
        errorInfo = string.format('查找温泉蛋失败, ElementId:%d',elementId)
    elseif tile and tile.tileView then
        local rotRoot = tile.tileView:GetAssetAttachTrans(true)
        local count1 = ModuleRefer.InventoryModule:GetAmountByConfigId(70071)
        local countSpecial1 = ModuleRefer.InventoryModule:GetAmountByConfigId(70068)
        local countSpecial2 = ModuleRefer.InventoryModule:GetAmountByConfigId(70069)
        local count2 = ModuleRefer.InventoryModule:GetAmountByConfigId(70072)
        local count3 = ModuleRefer.InventoryModule:GetAmountByConfigId(70073)
        local bubble
        if count1 + countSpecial1 + countSpecial2 > 0 then
            bubble = rotRoot:Find("ui3d_bubble_egg/p_rotation/p_position/p_egg_3")
        elseif count2 > 0 then
            bubble = rotRoot:Find("ui3d_bubble_egg/p_rotation/p_position/p_egg_2")
        elseif count3 > 0 then
            bubble = rotRoot:Find("ui3d_bubble_egg/p_rotation/p_position/p_egg_1")
        end
        if bubble and Utils.IsNotNull(bubble) then
            return true, {
                type = GuideConst.TargetTypeEnum.Transform,
                target = bubble.transform,
                range = zoneCfg:Range()
            }
        elseif rotRoot and Utils.IsNotNull(rotRoot) then
            return true, {
                type = GuideConst.TargetTypeEnum.Transform,
                target = rotRoot.transform,
                range = zoneCfg:Range()
            }
        else
            errorInfo = string.format('查找建筑泡泡失败 ElementId:%d',elementId)
        end
    else
        errorInfo = string.format('查找温泉蛋失败, ElementId:%d',elementId)
    end
    return false, errorInfo
end

function GuideTargetGetters.GetStepTarget_CityFurnitureRewardBubble(zoneCfg)
    ---@type MyCity
    local myCity = GuideUtils.FindMyCity()
    local elementName =  zoneCfg:CtrlName()
    local elementId = string.IsNullOrEmpty(elementName) and 0 or tonumber(elementName)
    local tile = nil
    local tiles = myCity:GetFurnitureTilesByFurnitureType(elementId)
    if tiles and #tiles > 0 then
        tile = GuideUtils.GetNearestTile(tiles)
    end
    local errorInfo
    if not tile then
        errorInfo = string.format('查找家具失败, ElementId:%d',elementId)
    else
        local rotRoot = tile.tileView:GetAssetAttachTrans(true)
        local bubble = rotRoot:Find("ui3d_bubble_group/p_rotation/p_position")
        if bubble and Utils.IsNotNull(bubble) then
            return true, {
                type = GuideConst.TargetTypeEnum.Transform,
                target = bubble.transform,
                range = zoneCfg:Range()
            }
        elseif rotRoot and Utils.IsNotNull(rotRoot) then
            return true, {
                type = GuideConst.TargetTypeEnum.Transform,
                target = rotRoot.transform,
                range = zoneCfg:Range()
            }
        else
            errorInfo = string.format('查找家具失败 ElementId:%d',elementId)
        end
    end
    return false, errorInfo
end

function GuideTargetGetters.GetStepTarget_CityGroundCoord(zoneCfg)
    local errorInfo
    ---@type MyCity
    local myCity = GuideUtils.FindMyCity()
    if not myCity then
        errorInfo = string.format('当前找不到myCity')
    end
    local gridConfig = myCity.gridConfig
    local coord = zoneCfg:WorldPos()
    local coordX = coord:X()
    local coordY = coord:Y()
    if not gridConfig:IsLocationValid(coordX, coordY) then
        errorInfo = string.format('指定的坐标不在city 的范围内 coordX:, coordY:',coordX, coordY)
    end
    if errorInfo then
        return false, errorInfo
    end
    ---@type StepTargetData
    local ret = {}
    ret.type = GuideConst.TargetTypeEnum.WorldPos
    ret.position = myCity:GetWorldPositionFromCoord(coordX, coordY)
    ret.range = zoneCfg:Range()
    return ret
end

function GuideTargetGetters.GetStepTarget_NearbyCity(zoneCfg)
    local castle = ModuleRefer.PlayerModule:GetCastle()
    if not castle then
        return false, string.format('查找玩家主城失败')
    end
    local basePos = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
    local baseX, baseZ = KingdomMapUtils.ParseBuildingPos(basePos)
    local coord = CS.DragonReborn.Vector2Short(baseX, baseZ)
    local filter = function(vx, vy, level, territoryConfig, villageConfig)
        return villageConfig:SubType() == require("MapBuildingSubType").City
    end
    local pos, _, _, _ = ModuleRefer.TerritoryModule:GetNearestTerritoryPosition(coord, 0, filter)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = pos,
        range = zoneCfg:Range()
    }
end

function GuideTargetGetters.GetStepTarget_NearbyStronghold(zoneCfg)
    local castle = ModuleRefer.PlayerModule:GetCastle()
    if not castle then
        return false, string.format('查找玩家主城失败')
    end
    local basePos = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
    local baseX, baseZ = KingdomMapUtils.ParseBuildingPos(basePos)
    local coord = CS.DragonReborn.Vector2Short(baseX, baseZ)
    local filter = function(vx, vy, level, territoryConfig, villageConfig)
        return villageConfig:SubType() == require("MapBuildingSubType").Stronghold
    end
    local pos, _, _, _ = ModuleRefer.TerritoryModule:GetNearestTerritoryPosition(coord, 0, filter)
    return true, {
        type = GuideConst.TargetTypeEnum.WorldPos,
        position = pos,
        range = zoneCfg:Range()
    }
end

local Map = {
    [GuideZoneType.UICtrl] = GuideTargetGetters.GetStepTarget_UIElement,
    [GuideZoneType.CityBuilding] = GuideTargetGetters.GetStepTarget_CityBuilding,
    [GuideZoneType.CityFurniture] = GuideTargetGetters.GetStepTarget_CityFurniture,
    [GuideZoneType.CityNPC] = GuideTargetGetters.GetStepTarget_CityNpc,
    [GuideZoneType.CityResource] = GuideTargetGetters.GetStepTarget_CityResource,
    [GuideZoneType.CityZone] = GuideTargetGetters.GetStepTarget_CityZone,
    [GuideZoneType.CityCreepBlock] = GuideTargetGetters.GetStepTarget_CityCreepBlock,
    [GuideZoneType.CitySpawner] = GuideTargetGetters.GetStepTarget_CitySpawner,
    [GuideZoneType.BuildingRepair] = GuideTargetGetters.GetStepTarget_CityBuildingBubble,
    [GuideZoneType.SafeAreaWall] = GuideTargetGetters.GetStepTarget_CityAreaWallBubble,
    [GuideZoneType.KingdomBuild] = GuideTargetGetters.GetStepTarget_KingdomBuilding,
    [GuideZoneType.KingdomMob] = GuideTargetGetters.GetStepTarget_KingdomMob,
    [GuideZoneType.KingdomTroop] = GuideTargetGetters.GetStepTarget_KingdomTroop,
    [GuideZoneType.WorldPos] = GuideTargetGetters.GetStepTarget_WorldPos,
    [GuideZoneType.ScreenPos] = GuideTargetGetters.GetStepTarget_ScreenPos,
    [GuideZoneType.CityCreepElement] = GuideTargetGetters.GetStepTarget_CityCreepElement,
    [GuideZoneType.KingdomResource] = GuideTargetGetters.GetStepTarget_KingdomResource,
    [GuideZoneType.KingdomCreep] = GuideTargetGetters.GetStepTarget_KingdomCreep,
    [GuideZoneType.KingdomMonster] = GuideTargetGetters.GetStepTarget_KingdomMonster,
    [GuideZoneType.KingdomMonsterLevel] = GuideTargetGetters.GetStepTarget_KingdomMonsterLevel,
    [GuideZoneType.CitySLGMonster] = GuideTargetGetters.GetStepTarget_KingdomMonster,
    [GuideZoneType.KingdomMistCell] = GuideTargetGetters.GetStepTarget_KingdomMistCell,
    [GuideZoneType.KingdomMine] = GuideTargetGetters.GetStepTarget_KingdomMine,
    [GuideZoneType.WorldExpedition] = GuideTargetGetters.GetStepTarget_WorldExpedition,
    [GuideZoneType.WorldFakeExpedition] = GuideTargetGetters.GetStepTarget_WorldFakeExpedition,
    [GuideZoneType.WorldExpeditionLevel] = GuideTargetGetters.GetStepTarget_WorldExpeditionLevel,
    [GuideZoneType.KingdomResourceLevel] = GuideTargetGetters.GetStepTarget_KingdomResourceLevel,
    [GuideZoneType.WorldPet] = GuideTargetGetters.GetStepTarget_WorldPet,
    [GuideZoneType.KingdomCreepLevel] = GuideTargetGetters.GetStepTarget_KingdomCreepLevel,
    [GuideZoneType.CityResourceType] = GuideTargetGetters.GetStepTarget_CityResourceType,
    [GuideZoneType.KingdomSLGInteractor] = GuideTargetGetters.GetStepTarget_KingdomSlgInteractor,
    [GuideZoneType.FindListNPC] = GuideTargetGetters.GetStepTarget_GetCityPetList,
    [GuideZoneType.FindListPetWorld] = GuideTargetGetters.GetStepTarget_GetWorldPetList,
    [GuideZoneType.FindRewardRadarTask] = GuideTargetGetters.GetStepTarget_RewardRadarTask,
    [GuideZoneType.WorldRewardInteractor] = GuideTargetGetters.GetStepTarget_WorldRewardInteractor,
    [GuideZoneType.KingdomTerritory] = GuideTargetGetters.GetStepTarget_KingdomTerritory,
    [GuideZoneType.NearlyWorldExpedition] = GuideTargetGetters.GetStepTarget_NearlyWorldExpedition,
    [GuideZoneType.CityElementResType] = GuideTargetGetters.GetStepTarget_CityElementResType,
    [GuideZoneType.CityRoom] = GuideTargetGetters.GetStepTarget_CityRoom,
    [GuideZoneType.CitizenBubble] = GuideTargetGetters.GetStepTarget_CitizenBubble,
    [GuideZoneType.CitizenPetBubble] = GuideTargetGetters.GetStepTarget_CityEggFurnitureBubble,
    [GuideZoneType.FurResBubble] = GuideTargetGetters.GetStepTarget_CityFurnitureRewardBubble,
    [GuideZoneType.CityCoord] = GuideTargetGetters.GetStepTarget_CityGroundCoord,
    [GuideZoneType.NearByCity] = GuideTargetGetters.GetStepTarget_NearbyCity,
    [GuideZoneType.NearByStronghold] = GuideTargetGetters.GetStepTarget_NearbyStronghold,
}

---@param zoneType number
---@return fun(number):boolean, StepTargetData | string
function GuideTargetGetters.GetTargetGetter(zoneType)
    local getter = Map[zoneType]
    if not getter then
        return function()
            return false, string.format('未找到对应的获取目标方法, zoneType:%d', zoneType)
        end
    end
    return getter
end

return GuideTargetGetters