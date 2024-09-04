---@class CityLegoBuilding
---@field new fun(manager, id):CityLegoBuilding
local CityLegoBuilding = sealedClass("CityLegoBuilding")
local RectDyadicMap = require("RectDyadicMap")
local CityLegoDefine = require("CityLegoDefine")
local WallSide = require("WallSide")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local LegoBlockType = require("LegoBlockType")
local ColorUtil = require("ColorUtil")
local CityLegoBuffCalculatorWds = require("CityLegoBuffCalculatorWds")
local RoomSize = require("RoomSize")
local CityWorkFormula = require("CityWorkFormula")
local ModuleRefer = require("ModuleRefer")
local NpcServiceObjectType = require("NpcServiceObjectType")
local NpcServiceType = require("NpcServiceType")
local I18N = require("I18N")
local Utils = require("Utils")
local UIMediatorNames = require("UIMediatorNames")
local ManualResourceConst = require("ManualResourceConst")

local CityTileAssetLegoBuildingFloor = require("CityTileAssetLegoBuildingFloor")
local CityTileAssetLegoBuildingWall = require("CityTileAssetLegoBuildingWall")
local CityTileAssetLegoBuildingBlock = require("CityTileAssetLegoBuildingBlock")
local CityTileAssetLegoBuildingDecoration = require("CityTileAssetLegoBuildingDecoration")
local CityTileAssetLegoBuildingUnlockBubble = require("CityTileAssetLegoBuildingUnlockBubble")
local CityTileAssetLegoBuildingRecommandFormula = require("CityTileAssetLegoBuildingRecommandFormula")
local CityTileAssetLegoBuildingExpireFormula = require("CityTileAssetLegoBuildingExpireFormula")
local CityTileAssetLegoBuildingName = require("CityTileAssetLegoBuildingName")
local CityTileAssetLegoBuildingLockedServiceBubble = require("CityTileAssetLegoBuildingLockedServiceBubble")

local CityWallOrDoorNavmeshDatum = require("CityWallOrDoorNavmeshDatum")
local CityLegoBuffToastUIParameter = require("CityLegoBuffToastUIParameter")

local CityLegoFloor = require("CityLegoFloor")
local CityLegoWall = require("CityLegoWall")
local CityLegoBlock = require("CityLegoBlock")
local CityLegoRoof = require("CityLegoRoof")
local CityLegoFreeDecoration = require("CityLegoFreeDecoration")
local CityTileAssetLegoBuildingRoof = require("CityTileAssetLegoBuildingRoof")

local CityLegoBuffCalculatorTemp = require("CityLegoBuffCalculatorTemp")
local CityLegoBuffProvider_FurnitureCfg = require("CityLegoBuffProvider_FurnitureCfg")
local CityLegoBuffUnit = require("CityLegoBuffUnit")
local CityLegoBuffProviderType = require("CityLegoBuffProviderType")

local NotificationType = require("NotificationType")

local Vector3 = CS.UnityEngine.Vector3
local DefalutHeight = 0.5

local function GetBoldNumber(number)
    return string.format("<b>%.0f</b>", number)
end

---@param manager CityLegoBuildingManager
---@param payload wds.CastleBuilding
function CityLegoBuilding:ctor(manager, id, payload)
    self.manager = manager
    self.id = id
    self.payload = payload
    self.city = self.manager.city

    self.x = payload.Pos.X
    self.z = payload.Pos.Y

    self.sizeX = payload.SizeX
    self.sizeZ = payload.SizeY

    self:InitData()
    self.buffCalculator = CityLegoBuffCalculatorWds.new(self)
    self.dynamicNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode(
        ("[%d]CityLegoBuilding_NewBuff"):format(self.id),
        NotificationType.CITY_LEGOBUILDING_NEW_BUFF
    )
end

function CityLegoBuilding:InitData()
    self.roomLightColor = nil
    self.roomLightDir = nil
    self.roomGiColor = nil
    
    self.roomLocked = self.payload.Locked
    self.roomCfgId = self.payload.RoomConfigId
    self.roomLevel = self.payload.RoomLevel
    self.roomStyleIdx = self:CalculateRoomStyleIdx(self.roomCfgId, self.roomLevel)
    self.roomNameBuff = self.payload.BuffList:Count() > 0 and self.payload.BuffList[1] or 0
    self.roomScore = self.payload.Score

    local roomCfg = ConfigRefer.Room:Find(self.roomCfgId)
    self.roomLegoBpCfgId = self.payload.Locked and roomCfg:LockedLayout() or roomCfg:Layout()

    self.unlockedBuffMap = {}
    self.roomHasNewBuff = false
    local lvCfg = self:GetCurrentRoomLevelCfg()
    for i = 1, lvCfg:RoomTagBuffsLength() do
        self.unlockedBuffMap[lvCfg:RoomTagBuffs(i)] = true
    end

    --- 地板需要做面积检查
    self.floorPosMap = RectDyadicMap.new(512, 512)
    ---@type CityLegoFloor[]
    self.floors = {}
    ---@type CityLegoWall[]
    self.walls = {}
    self.wallPosMap = RectDyadicMap.new(512, 512)
    ---@type CityLegoBlock[]
    self.blocks = {}
    ---@type CityLegoFreeDecoration[]
    self.decorations = {}
    ---@type CityLegoRoof[]
    self.roofs = {}
    --- 屋顶需要根据邻居关系确定部分组件是否显示
    self.roofPosMap = RectDyadicMap.new(512, 512)

    local size = CityLegoDefine.BlockSize
    local legoBluePrintCfg = ConfigRefer.LegoBluePrint:Find(self.roomLegoBpCfgId)
    self.legoBluePrintCfg = legoBluePrintCfg
    self.heightOffset = self.legoBluePrintCfg:HeightOffset()
    self.baseOffset = Vector3.up * (self.heightOffset * self.city.scale)

    if legoBluePrintCfg ~= nil then
        for i = 1, legoBluePrintCfg:BlocksLength() do
            local blockInst = legoBluePrintCfg:Blocks(i)
            local blockInstCfg = ConfigRefer.LegoBlockInstance:Find(blockInst)
            
            local blockCfgId = blockInstCfg:Type()
            local blockCfg = ConfigRefer.LegoBlock:Find(blockCfgId)
            local blockType = blockCfg:Type()
            if blockType == LegoBlockType.Base then
                local floor = CityLegoFloor.new(self, blockInstCfg)
                table.insert(self.floors, floor)
            elseif blockType == LegoBlockType.Door or blockType == LegoBlockType.Wall then
                local wall = CityLegoWall.new(self, blockInstCfg)
                table.insert(self.walls, wall)
                local wallPosCache = self.wallPosMap:Get(wall.floorX, wall.floorZ)
                if wallPosCache == nil then
                    wallPosCache = {}
                    self.wallPosMap:Add(wall.floorX, wall.floorZ, wallPosCache)
                end
                wallPosCache[wall.side] = wall
            elseif blockType == LegoBlockType.Free then
                local block = CityLegoBlock.new(self, blockInstCfg)
                table.insert(self.blocks, block)
            elseif blockType == LegoBlockType.Roof then
                local roof = CityLegoRoof.new(self, blockInstCfg)
                table.insert(self.roofs, roof)
            end
        end

        for i = 1, legoBluePrintCfg:FreeDecorationsLength() do
            local decorationInst = legoBluePrintCfg:FreeDecorations(i)
            local decorationInstCfg = ConfigRefer.LegoFreeDecorationInstance:Find(decorationInst)
            local decoration = CityLegoFreeDecoration.new(self, decorationInstCfg)
            table.insert(self.decorations, decoration)
        end
    end

    for _, v in ipairs(self.floors) do
        for i = 0, size - 1 do
            for j = 0, size - 1 do
                if not self.floorPosMap:TryAdd(v.x + i, v.z + j, v) then
                    g_Logger.ErrorChannel("CityLegoBuilding", "[LegoBP:%d]地板[InstanceId:%d 与 %d]位置配置重叠: %d, %d", self.legoBluePrintCfg:Id(), v.payload:Id(), self.floorPosMap:Get(v.x+i, v.z+j).payload:Id(), v.x, v.z)
                end
            end
        end
    end

    for _, v in ipairs(self.roofs) do
        if not self.roofPosMap:TryAdd(v.x, v.z, v) then
            g_Logger.TraceChannel("Repeated Roof at %d, %d", v.x, v.z)
        end
    end

    for _, v in ipairs(self.floors) do
        g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_FLOOR_ADD, self.city, v.x, v.z)
    end

    self:GenerateNavmeshData()
    self:GenerateBlackFurnitureTypeMap()
end

function CityLegoBuilding:Release()
    for _, v in ipairs(self.floors) do
        g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_FLOOR_REMOVE, self.city, v.x, v.z)
    end
end

---@param payload wds.CastleBuilding
function CityLegoBuilding:UpdatePayload(payload)
    self.payload = payload

    local posChanged = payload.Pos.X ~= self.x or payload.Pos.Y ~= self.z
    if posChanged then
        local oldX, oldZ = self.x, self.z
        self.x = payload.Pos.X
        self.z = payload.Pos.Y
        
        g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_BUILDING_MOVE, self.city, self, oldX, oldZ, self.x, self.z, self.sizeX, self.sizeZ)
    end

    local sizeChanged = payload.SizeX ~= self.sizeX or payload.SizeY ~= self.sizeZ
    if sizeChanged then
        local oldSizeX, oldSizeZ = self.sizeX, self.sizeZ
        self.sizeX = payload.SizeX
        self.sizeZ = payload.SizeY

        g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_BUILDING_RESIZE, self.city, self, oldSizeX, oldSizeZ, self.sizeX, self.sizeZ, self.x, self.z)
    end

    local newRoomStyleIdx = self:CalculateRoomStyleIdx(payload.RoomConfigId, payload.RoomLevel)
    local styleChange = self.roomStyleIdx ~= newRoomStyleIdx
    local oldRoomCfgId = self.roomCfgId
    local roomChanged = self.roomCfgId ~= payload.RoomConfigId
    if posChanged or roomChanged or styleChange then
        for _, v in ipairs(self.floors) do
            g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_FLOOR_REMOVE, self.city, v.x, v.z)
        end
    end

    local roomNameBuff = payload.BuffList:Count() > 0 and payload.BuffList[1] or 0
    local oldRoomNameBuff = self.roomNameBuff
    local roomNameBuffChanged = self.roomNameBuff ~= roomNameBuff
    local oldRoomLocked = self.roomLocked
    local lockedChange = self.roomLocked ~= payload.Locked
    local roomCfg = ConfigRefer.Room:Find(payload.RoomConfigId)
    local roomLegoBpCfgId = payload.Locked and roomCfg:LockedLayout() or roomCfg:Layout()
    local legoBpChanged = self.roomLegoBpCfgId ~= roomLegoBpCfgId

    self.roomCfgId = payload.RoomConfigId
    self.roomLevel = payload.RoomLevel
    self.roomStyleIdx = newRoomStyleIdx
    self.roomNameBuff = roomNameBuff
    self.roomLocked = payload.Locked
    self.roomLegoBpCfgId = roomLegoBpCfgId
    self.legoBluePrintCfg = ConfigRefer.LegoBluePrint:Find(self.roomLegoBpCfgId)

    local unlockedBuffMap = {}
    local lvCfg = self:GetCurrentRoomLevelCfg()
    for i = 1, lvCfg:RoomTagBuffsLength() do
        unlockedBuffMap[lvCfg:RoomTagBuffs(i)] = true
    end

    local hasNewBuff = false
    for newBuffId, flag in pairs(unlockedBuffMap) do
        if not self.unlockedBuffMap[newBuffId] then
            hasNewBuff = true
            break
        end
    end

    self.roomHasNewBuff = hasNewBuff
    self.unlockedBuffMap = unlockedBuffMap
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.dynamicNode, self.roomHasNewBuff and 1 or 0)

    local fullChanged = legoBpChanged or roomChanged or styleChange
    if fullChanged then
        self:ClearTileViewAssets()
        self:InitData()
        self:AddTileViewAssetsFromData()
    elseif posChanged then
        self:UpdateAllUnitsPayload()
    end

    if lockedChange and not fullChanged then
        if self.tileView then
            if self.bubbleAsset then
                self.tileView:RemoveAsset(self.bubbleAsset)
                self.bubbleAsset = nil
            end
            if self:HasRepairBubble() then
                self.bubbleAsset = CityTileAssetLegoBuildingUnlockBubble.new(self)
                self.tileView:AddAsset(self.bubbleAsset)
            end
        end
    end

    self.buffCalculator:Update()

    if posChanged or roomChanged or styleChange then
        for _, v in ipairs(self.floors) do
            g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_FLOOR_ADD, self.city, v.x, v.z)
        end
    end

    if lockedChange then
        if not self.roomLocked then
            ModuleRefer.GuideModule:CallGuide(33)
        end
        g_Game.SoundManager:Play("sfx_ui_cleanup")
    end

    if roomNameBuffChanged or roomChanged then
        local oldName = string.Empty
        if oldRoomNameBuff ~= 0 then
            oldName = I18N.Get(ConfigRefer.RoomTagBuff:Find(oldRoomNameBuff):BuffName())
        elseif oldRoomLocked then
            oldName = I18N.Get(ConfigRefer.Room:Find(oldRoomCfgId):LockedName())
        else
            oldName = I18N.Get(ConfigRefer.Room:Find(oldRoomCfgId):Name())
        end

        local newName = string.Empty
        local attrId = nil
        if self.roomNameBuff ~= 0 then
            local newBuffCfg = ConfigRefer.RoomTagBuff:Find(self.roomNameBuff)
            newName = I18N.Get(newBuffCfg:BuffName())
            attrId = newBuffCfg:GolbalAttr()
        elseif self.roomLocked then
            newName = I18N.Get(ConfigRefer.Room:Find(self.roomCfgId):LockedName())
        else
            newName = I18N.Get(ConfigRefer.Room:Find(self.roomCfgId):Name())
        end

        local param = CityLegoBuffToastUIParameter.new(oldName, newName, attrId)
        g_Game.UIManager:Open(UIMediatorNames.CityLegoBuffToastUIMediator, param)
    end

    if roomChanged or legoBpChanged then
        for i, furnitureId in ipairs(self.payload.InnerFurnitureIds) do
            local furniture = self.city.furnitureManager:GetFurnitureById(furnitureId)
            if furniture then
                local tile = self.city.gridView:GetFurnitureTile(furniture.x, furniture.y)
                if tile then
                    tile:UpdatePosition(self.city:GetWorldPositionFromCoord(tile.x, tile.y))
                end
            end
        end
        for id, element in pairs(self.city.elementManager.eleResHashMap) do
            if element.x >= self.x and element.x < self.x + self.sizeX and element.y >= self.z and element.y < self.z + self.sizeZ then
                local tile = self.city.gridView:GetCellTile(element.x, element.y)
                if tile then
                    tile:UpdatePosition(self.city:GetWorldPositionFromCoord(tile.x, tile.y))
                end
            end
        end
    end

    if fullChanged and self.tileView ~= nil then
        self:PlayVfx()
    end

    local score = self.payload.Score
    local oldScore = self.roomScore
    local scoreChanged = self.roomScore ~= score
    self.roomScore = score
    if scoreChanged then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_BUILDING_SCORE_CHANGE, self, oldScore, score)
    end
    if not fullChanged and posChanged then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_LEGO_BUILDING_VIEW_POS_CHANGE, self.city, self)
    end
    if posChanged or sizeChanged then
        self:GenerateNavmeshData()
    end
end

function CityLegoBuilding:UpdateAllUnitsPayload()
    local size = CityLegoDefine.BlockSize
    self.floorPosMap:Clear()
    for _, v in ipairs(self.floors) do
        v:UpdatePosition()
        for i = 0, size - 1 do
            for j = 0, size - 1 do
                if not self.floorPosMap:TryAdd(v.x + i, v.z + j, v) then
                    g_Logger.ErrorChannel("CityLegoBuilding", "[LegoBP:%d]地板[InstanceId:%d 与 %d]位置配置重叠: %d, %d", self.legoBluePrintCfg:Id(), v.payload:Id(), self.floorPosMap:Get(v.x+i, v.z+j).payload:Id(), v.x, v.z)
                end
            end
        end
    end

    self.wallPosMap:Clear()
    for _, wall in ipairs(self.walls) do
        wall:UpdatePosition()
        local wallPosCache = self.wallPosMap:Get(wall.floorX, wall.floorZ)
        if wallPosCache == nil then
            wallPosCache = {}
            self.wallPosMap:Add(wall.floorX, wall.floorZ, wallPosCache)
        end
        wallPosCache[wall.side] = wall
    end

    self.roofPosMap:Clear()
    for _, v in ipairs(self.roofs) do
        v:UpdatePosition()
        if not self.roofPosMap:TryAdd(v.x, v.z, v) then
            g_Logger.TraceChannel("Repeated Roof at %d, %d", v.x, v.z)
        end
    end

    for _, v in ipairs(self.blocks) do
        v:UpdatePosition()
    end

    for _, v in ipairs(self.decorations) do
        v:UpdatePosition()
    end
end

---@return CityTileViewLegoBuilding
function CityLegoBuilding:GetOrCreateTileView()
    if self.tileView == nil then
        self.tileView = self:CreateTileViewImp()
        self:AddTileViewAssetsFromData()
    end
    return self.tileView
end

---@private
function CityLegoBuilding:CreateTileViewImp()
    local CityTileViewLegoBuilding = require("CityTileViewLegoBuilding")
    local tileView = CityTileViewLegoBuilding.new(self.id)
    return tileView
end

function CityLegoBuilding:UnloadTileView()
    self.tileView = nil
end

function CityLegoBuilding:AddTileViewAssetsFromData()
    if not self.tileView then return end

    for _, v in ipairs(self.floors) do
        if v:HasIndoorPart() then
            self.tileView:AddAsset(CityTileAssetLegoBuildingFloor.new(self, v, true))
        end
        if v:HasOutsidePart() then
            self.tileView:AddAsset(CityTileAssetLegoBuildingFloor.new(self, v, false))
        end
    end

    for _, v in ipairs(self.walls) do
        if v:HasIndoorPart() then
            self.tileView:AddAsset(CityTileAssetLegoBuildingWall.new(self, v, true))
        end
        if v:HasOutsidePart() then
            self.tileView:AddAsset(CityTileAssetLegoBuildingWall.new(self, v, false))
        end
    end

    for _, v in ipairs(self.blocks) do
        if v:HasIndoorPart() then
            self.tileView:AddAsset(CityTileAssetLegoBuildingBlock.new(self, v, true))
        end
        if v:HasOutsidePart() then
            self.tileView:AddAsset(CityTileAssetLegoBuildingBlock.new(self, v, false))
        end
    end

    for _, v in ipairs(self.roofs) do
        if v:HasIndoorPart() then
            self.tileView:AddAsset(CityTileAssetLegoBuildingRoof.new(self, v, true))
        end
        if v:HasOutsidePart() then
            self.tileView:AddAsset(CityTileAssetLegoBuildingRoof.new(self, v, false))
        end
    end

    for _, v in ipairs(self.decorations) do
        self.tileView:AddAsset(CityTileAssetLegoBuildingDecoration.new(self, v))
    end

    if self:HasRepairBubble() then
        self.bubbleAsset = CityTileAssetLegoBuildingUnlockBubble.new(self)
        self.tileView:AddAsset(self.bubbleAsset)
    end

    if self:IsShowRecommendFormula() then
        self.formulaAsset = CityTileAssetLegoBuildingRecommandFormula.new(self)
        self.tileView:AddAsset(self.formulaAsset)
    end

    if self:IsShowExpireFormula() then
        self.expireFormulaAsset = CityTileAssetLegoBuildingExpireFormula.new(self, self.expireBuffCfg)
        self.tileView:AddAsset(self.expireFormulaAsset)
    end

    if self:IsShowName() then
        self.nameAsset = CityTileAssetLegoBuildingName.new(self)
        self.tileView:AddAsset(self.nameAsset)
    end

    if self:IsShowLockedServiceBubble() then
        self.lockedServiceBubbleAsset = CityTileAssetLegoBuildingLockedServiceBubble.new(self, self.lockedServiceCfg)
        self.tileView:AddAsset(self.lockedServiceBubbleAsset)
    end
end

function CityLegoBuilding:UpdateUnlockBubble()
    if not self.tileView then return end

    if self:HasRepairBubble() then
        if self.bubbleAsset == nil then
            self.bubbleAsset = CityTileAssetLegoBuildingUnlockBubble.new(self)
            self.tileView:AddAsset(self.bubbleAsset)
        end
    else
        if self.bubbleAsset then
            self.tileView:RemoveAsset(self.bubbleAsset)
            self.bubbleAsset = nil
        end
    end
end

function CityLegoBuilding:ClearTileViewAssets()
    if not self.tileView then return end

    self.tileView:RemoveAllAssets()
    self.formulaAsset = nil
    self.expireFormulaAsset = nil
    self.nameAsset = nil
    self.lockedServiceBubbleAsset = nil
    self.bubbleAsset = nil
end

function CityLegoBuilding:FloorContains(x, y)
    return self.floorPosMap:Contains(x, y)
end

function CityLegoBuilding:GetBaseOffset()
    return self.baseOffset
end

---@return CityLegoWall[]
function CityLegoBuilding:GetWallsAtExceptSide(x, y, z, side)
    local ret = {}
    local cache = self.wallPosMap:Get(x, z)
    if cache == nil then
        return ret
    end

    for k, v in pairs(cache) do
        if k ~= side then
            table.insert(ret, v)
        end
    end
    return ret
end

function CityLegoBuilding:GetBaseAt(x, y, z)
    return self.floorPosMap:Get(x, z)
end

function CityLegoBuilding:GetRoomCfgId()
    return self.roomCfgId
end

function CityLegoBuilding:GetRoomLevel()
    return self.roomLevel
end

function CityLegoBuilding:GetCurrentRoomLevelCfg()
    return self.manager:GetRoomLevelCfg(self.roomCfgId, self.roomLevel)
end

---Lua的数组从1开始
function CityLegoBuilding:CalculateRoomStyleIdx(roomCfgId, roomLevel)
    local levelCfg = self.manager:GetRoomLevelCfg(roomCfgId, roomLevel)
    if levelCfg ~= nil then
        return levelCfg:Style() + 1
    end
    return 1
end

function CityLegoBuilding:GetRoomStyle()
    return self.roomStyleIdx
end

function CityLegoBuilding:InsideRoomBase(x, z)
    local floorX = math.floor(x)
    local floorZ = math.floor(z)
    return self.floorPosMap:Contains(floorX, floorZ)
end

function CityLegoBuilding:GetRoomLightColor()
    if self.roomLightColor == nil then
        self.roomLightColor = ColorUtil.FromColor32Cfg(self.legoBluePrintCfg:RoomLightColor())
    end
    return self.roomLightColor
end

function CityLegoBuilding:GetRoomLightDir()
    if self.roomLightDir == nil then
        local dirCfg = self.legoBluePrintCfg:RoomLightDir()
        self.roomLightDir = CS.UnityEngine.Vector3(dirCfg:X(), dirCfg:Y(), dirCfg:Z())
    end
    return self.roomLightDir
end

function CityLegoBuilding:GetRoomGi()
    if self.roomGiColor == nil then
        self.roomGiColor = ColorUtil.FromColor32Cfg(self.legoBluePrintCfg:RoomGiColor())
    end
    return self.roomGiColor
end

---@param dirX number @-1, 0, 1
---@param dirY number @-1, 0, 1
function CityLegoBuilding:HasRoofNeighborAt(x, y, dirX, dirY)
    local size = CityLegoDefine.BlockSize
    return self.roofPosMap:Contains(x + math.sign(dirX) * size, y + math.sign(dirY) * size)
end

function CityLegoBuilding:GenerateNavmeshData()
    ---@type CityWallOrDoorNavmeshDatum[]
    self.navmeshData = {}
    local minX, minY, maxX, maxY
    for x, y, cache in self.wallPosMap:pairs() do
        if not minX or x < minX then minX = x end
        if not minY or y < minY then minY = y end
        if not maxX or x > maxX then maxX = x end
        if not maxY or y > maxY then maxY = y end
    end

    if not minX or not minY or not maxX or not maxY then
        return self.navmeshData
    end

    for j = minY, maxY, 3 do
        ---@type CityLegoWall
        local beginTop, beginBottom = nil, nil
        local lengthTop, lengthBottom = 0, 0
        for i = minX, maxX, 3 do
            local cache = self.wallPosMap:Get(i, j)
            if cache then
                ---@type CityLegoWall
                local wall = cache[WallSide.Top]
                if wall then
                    if beginTop == nil then
                        beginTop = wall
                        lengthTop = 3
                    elseif wall.isDoor ~= beginTop.isDoor then
                        self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginTop.floorX, beginTop.floorZ+3, lengthTop, false, beginTop.isDoor, nil, WallSide.Top))
                        beginTop = wall
                        lengthTop = 3
                    else
                        lengthTop = lengthTop + 3
                    end
                else
                    if beginTop ~= nil then
                        self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginTop.floorX, beginTop.floorZ+3, lengthTop, false, beginTop.isDoor, nil, WallSide.Top))
                        beginTop = nil
                        lengthTop = 0
                    end
                end

                wall = cache[WallSide.Bottom]
                if wall then
                    if beginBottom == nil then
                        beginBottom = wall
                        lengthBottom = 3
                    elseif wall.isDoor ~= beginBottom.isDoor then
                        self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginBottom.floorX, beginBottom.floorZ, lengthBottom, false, beginBottom.isDoor, nil, WallSide.Bottom))
                        beginBottom = wall
                        lengthBottom = 3
                    else
                        lengthBottom = lengthBottom + 3
                    end
                else
                    if beginBottom ~= nil then
                        self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginBottom.floorX, beginBottom.floorZ, lengthBottom, false, beginBottom.isDoor, nil, WallSide.Bottom))
                        beginBottom = nil
                        lengthBottom = 0
                    end
                end
            else
                if beginTop ~= nil then
                    self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginTop.floorX, beginTop.floorZ+3, lengthTop, false, beginTop.isDoor, nil, WallSide.Top))
                    beginTop = nil
                    lengthTop = 0
                end
                if beginBottom ~= nil then
                    self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginBottom.floorX, beginBottom.floorZ, lengthBottom, false, beginBottom.isDoor, nil, WallSide.Bottom))
                    beginBottom = nil
                    lengthBottom = 0
                end
            end
        end
        if beginTop ~= nil then
            self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginTop.floorX, beginTop.floorZ+3, lengthTop, false, beginTop.isDoor, nil, WallSide.Top))
        end
        if beginBottom ~= nil then
            self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginBottom.floorX, beginBottom.floorZ, lengthBottom, false, beginBottom.isDoor, nil, WallSide.Bottom))
        end
    end

    for i = minX, maxX, 3 do
        ---@type CityLegoWall
        local beginLeft, beginRight = nil, nil
        local lengthLeft, lengthRight = 0, 0
        for j = minY, maxY, 3 do
            local cache = self.wallPosMap:Get(i, j)
            if cache then
                ---@type CityLegoWall
                local wall = cache[WallSide.Left]
                if wall then
                    if beginLeft == nil then
                        beginLeft = wall
                        lengthLeft = 3
                    elseif wall.isDoor ~= beginLeft.isDoor then
                        self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginLeft.floorX, beginLeft.floorZ, lengthLeft, true, beginLeft.isDoor, nil, WallSide.Left))
                        beginLeft = wall
                        lengthLeft = 3
                    else
                        lengthLeft = lengthLeft + 3
                    end
                else
                    if beginLeft ~= nil then
                        self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginLeft.floorX, beginLeft.floorZ, lengthLeft, true, beginLeft.isDoor, nil, WallSide.Left))
                        beginLeft = nil
                        lengthLeft = 0
                    end
                end

                wall = cache[WallSide.Right]
                if wall then
                    if beginRight == nil then
                        beginRight = wall
                        lengthRight = 3
                    elseif wall.isDoor ~= beginRight.isDoor then
                        self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginRight.floorX+3, beginRight.floorZ, lengthRight, true, beginRight.isDoor, nil, WallSide.Right))
                        beginRight = wall
                        lengthRight = 3
                    else
                        lengthRight = lengthRight + 3
                    end
                else
                    if beginRight ~= nil then
                        self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginRight.floorX+3, beginRight.floorZ, lengthRight, true, beginRight.isDoor, nil, WallSide.Right))
                        beginRight = nil
                        lengthRight = 0
                    end
                end
            else
                if beginLeft ~= nil then
                    self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginLeft.floorX, beginLeft.floorZ, lengthLeft, true, beginLeft.isDoor, nil, WallSide.Left))
                    beginLeft = nil
                    lengthLeft = 0
                end
                if beginRight ~= nil then
                    self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginRight.floorX+3, beginRight.floorZ, lengthRight, true, beginRight.isDoor, nil, WallSide.Right))
                    beginRight = nil
                    lengthRight = 0
                end
            end
        end
        if beginLeft ~= nil then
            self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginLeft.floorX, beginLeft.floorZ, lengthLeft, true, beginLeft.isDoor, nil, WallSide.Left))
        end
        if beginRight ~= nil then
            self:AppendNavmeshWallData(self.navmeshData, CityWallOrDoorNavmeshDatum.new(beginRight.floorX+3, beginRight.floorZ, lengthRight, true, beginRight.isDoor, nil, WallSide.Right))
        end
    end
    return self.navmeshData
end

---@param datum CityWallOrDoorNavmeshDatum
function CityLegoBuilding:AppendNavmeshWallData(array, datum)
    if datum.walkable then
        if datum.isVertical then
            table.insert(array, CityWallOrDoorNavmeshDatum.new(datum.x, datum.y, 1, true, false, nil, datum.side))
            table.insert(array, CityWallOrDoorNavmeshDatum.new(datum.x, datum.y+1, 1, true, true, nil, datum.side))
            table.insert(array, CityWallOrDoorNavmeshDatum.new(datum.x, datum.y+2, 1, true, false, nil, datum.side))
        else
            table.insert(array, CityWallOrDoorNavmeshDatum.new(datum.x, datum.y, 1, false, false, nil, datum.side))
            table.insert(array, CityWallOrDoorNavmeshDatum.new(datum.x+1, datum.y, 1, false, true, nil, datum.side))
            table.insert(array, CityWallOrDoorNavmeshDatum.new(datum.x+2, datum.y, 1, false, false, nil, datum.side))
        end
    else
        table.insert(array, datum)
    end
end

function CityLegoBuilding:GenerateBlackFurnitureTypeMap()
    self.blackTypeMap = {}
    local roomCfg = ConfigRefer.Room:Find(self.roomCfgId)
    for i = 1, roomCfg:FurnitureBlockListLength() do
        self.blackTypeMap[roomCfg:FurnitureBlockList(i)] = true
    end
end

---@param changeIds table<number, boolean>
function CityLegoBuilding:OnFurnitureBatchUpdate(changeIds)
    self.buffCalculator:OnFurnitureUpdate(changeIds)
end

function CityLegoBuilding:GetCurrentBuffCfg()
    if self.payload.BuffList:Count() == 0 then
        return nil
    end

    return ConfigRefer.RoomTagBuff:Find(self.payload.BuffList[1])
end

function CityLegoBuilding:GetNameI18N()
    local buffCfg = self:GetCurrentBuffCfg()
    if buffCfg == nil then
        local roomCfg = ConfigRefer.Room:Find(self.roomCfgId)
        if self.roomLocked then
            return roomCfg:LockedName()
        else
            return roomCfg:Name()
        end
    end
    return buffCfg:BuffName()
end

function CityLegoBuilding:GetIcon()
    local buffCfg = self:GetCurrentBuffCfg()
    if buffCfg == nil then
        local roomCfg = ConfigRefer.Room:Find(self.roomCfgId)
        return roomCfg:Icon()
    end
    return buffCfg:BuffIcon()
end

function CityLegoBuilding:GetRoomUILeftToggleIcon()
    local roomCfg = ConfigRefer.Room:Find(self.roomCfgId)
    return roomCfg:IconToggle()
end

function CityLegoBuilding:GetDescriptionI18N()
    local buffCfg = self:GetCurrentBuffCfg()
    if buffCfg == nil then
        local roomCfg = ConfigRefer.Room:Find(self.roomCfgId)
        return roomCfg:Desc()
    end
    return buffCfg:BuffDesc()
end

function CityLegoBuilding:GetMainFurnitureLevel()
    if self.payload.MainFurnitureId == 0 then
        return 0
    end
    local furniture = self.city.furnitureManager:GetFurnitureById(self.payload.MainFurnitureId)
    if furniture == nil then
        return 0
    end

    return furniture.level
end

function CityLegoBuilding:GetMaxCitizenCount()
    local roomCfg = ConfigRefer.Room:Find(self.roomCfgId)
    local basic = roomCfg:HeroLimit()
    for i, v in ipairs(self.payload.InnerFurnitureIds) do
        local furniture = self.city.furnitureManager:GetFurnitureById(v)
        if furniture then
            local furTypeCfg = ConfigRefer.CityFurnitureTypes:Find(furniture.furType)
            basic = basic + furTypeCfg:CitizenCapInc()
        end
    end
    return basic
end

function CityLegoBuilding:GetFreeCitizenInBuilding()
    if self.payload.InnerHeroIds:Count() == 0 then
        return nil
    end

    for _, v in ipairs(self.payload.InnerHeroIds) do
        local workId = self.city.cityWorkManager:GetCitizenRelativeWorkId(v)
        if workId == 0 then
            return v
        end
    end

    return nil
end

---@param workCfg CityWorkConfigCell
function CityLegoBuilding:GetBestFreeCitizenForWork(workCfg)
    if self.payload.InnerHeroIds:Count() == 0 then
        return nil
    end

    local freeCitizens = {}
    for _, v in ipairs(self.payload.InnerHeroIds) do
        local workId = self.city.cityWorkManager:GetCitizenRelativeWorkId(v)
        if workId == 0 then
            table.insert(freeCitizens, v)
        end
    end

    local powerValue = nil
    local bestCitizenId = nil
    for i, v in ipairs(freeCitizens) do
        local power = CityWorkFormula.GetWorkPower(workCfg, nil, nil, v, true)
        if powerValue == nil or power > powerValue then
            powerValue = power
            bestCitizenId = v
        end
    end

    return bestCitizenId
end

function CityLegoBuilding:GetScoreProgress()
    local nextLevelCfg = self.manager:GetRoomLevelCfg(self.roomCfgId, self.roomLevel + 1)
    if nextLevelCfg == nil then
        return 1
    else
        local currentLevelCfg = self:GetCurrentRoomLevelCfg()
        local max = nextLevelCfg:Score() - currentLevelCfg:Score()
        local current = self.payload.Score - currentLevelCfg:Score()
        return math.clamp01(current / max)
    end
end

function CityLegoBuilding:GetCurrentMaxScore()
    local nextLevelCfg = self.manager:GetRoomLevelCfg(self.roomCfgId, self.roomLevel + 1)
    if nextLevelCfg == nil then
        return self:GetCurrentRoomLevelCfg():Score()
    else
        return nextLevelCfg:Score()
    end
end

function CityLegoBuilding:GetScoreText(boldCurrent, boldTarget)
    local nextLevelCfg = self.manager:GetRoomLevelCfg(self.roomCfgId, self.roomLevel + 1)
    if nextLevelCfg == nil then
        local currentLvCfg = self:GetCurrentRoomLevelCfg()
        local current = boldCurrent and GetBoldNumber(self.payload.Score) or tostring(self.payload.Score)
        local target = boldTarget and GetBoldNumber(currentLvCfg:Score()) or tostring(currentLvCfg:Score())
        return string.format("%s/%s", current, target)
    else
        local current = boldCurrent and GetBoldNumber(self.payload.Score) or tostring(self.payload.Score)
        local target = boldTarget and GetBoldNumber(nextLevelCfg:Score()) or tostring(nextLevelCfg:Score())
        return string.format("%s/%s", current, target)
    end
end

function CityLegoBuilding:GetBorder()
    local expandX, expandZ = 5, 5
    return self.x - expandX, self.z - expandZ, self.x + expandX + self.sizeX - 1, self.z + expandZ + self.sizeZ - 1
end

function CityLegoBuilding:RequestSelectBuff(selectedBuffs, callback)
    self.manager:RequestSelectBuff(self, selectedBuffs, callback) 
end

function CityLegoBuilding:Besides(x, y)
    return x >= self.x and x < self.x + self.sizeX and y >= self.z and y < self.z + self.sizeZ
end

function CityLegoBuilding:GetRoomSizeEnum()
    local roomCfg = ConfigRefer.Room:Find(self.roomCfgId)
    return roomCfg:Size()
end

---@private
function CityLegoBuilding:HasRepairBubble()
    self.commitItemMap = nil
    self.needItemMap = nil
    self.serviceGroup = nil
    self.serviceId = nil

    if not self.payload.Locked then return false end

    local serviceMap = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.Building)
    local serviceGroup = serviceMap[self.id]
    if serviceGroup == nil then return false end
    self.serviceGroup = serviceGroup

    local isOnlyCommit, serviceId, _, _  = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(serviceGroup, NpcServiceType.CommitItem)
    if not isOnlyCommit then return false end
    self.serviceId = serviceId

    self.commitItemMap = ModuleRefer.StoryPopupTradeModule:GetServicesInfo(NpcServiceObjectType.Building, self.id, serviceId)
    self.needItemMap = ModuleRefer.StoryPopupTradeModule:GetNeedItems(serviceId)
    
    return true
end

function CityLegoBuilding:RequestToUnlock()
    if not self.serviceGroup then return false end

    ModuleRefer.PlayerServiceModule:InteractWithTarget(NpcServiceObjectType.Building, self.id)
    return true
end

function CityLegoBuilding:GetWorldCenter()
    return self.city:GetCenterWorldPositionFromCoord(self.x, self.z, self.sizeX, self.sizeZ)
end

---@param cfgId number @CityFurnitureLevel-Id
---@return boolean 是否需要显示一个气泡
function CityLegoBuilding:TryShowRecommendFormula(cfgId)
    if not self:IsUnlocked() then return false end
    if self:IsFogMask() then return false end

    local lvCfg = ConfigRefer.CityFurnitureLevel:Find(cfgId)
    local buffCfgLists, roomLvCfg = ModuleRefer.CityLegoBuffModule:GetNewBuffCfgListByAddFurniture(self, lvCfg)
    if #buffCfgLists == 0 then return false end

    local tempCalculator = CityLegoBuffCalculatorTemp.new()
    local furnitureProvider = CityLegoBuffProvider_FurnitureCfg.new(lvCfg)
    
    for _, v in ipairs(self.buffCalculator:GetAllPrividers()) do
        tempCalculator:AppendProvider(v)
    end

    ---@type table<number, CityLegoBuffUnit>
    local buffUnitMap = {}
    --- 先找出当前还没有生效，且与本家具能产生关联的Buff
    for i, v in ipairs(buffCfgLists) do
        local buffCfgId = v:Id()
        --- 如果当前建筑上记录的已生效的buff中已经有这个buff了，就不用再显示推荐了
        if self.buffCalculator.buffMap[buffCfgId] and self.buffCalculator.buffMap[buffCfgId].valid then
            goto continue
        end

        local buffUnit = CityLegoBuffUnit.new(v)
        buffUnit:UpdateValidState(self.buffCalculator)

        local isRelative = false
        --- 当前buff未生效，但缺失的Tag本家具并不能提供，则也不显示推荐
        for lackCfgId, count in pairs(buffUnit.lackTagMap) do
            if furnitureProvider.tagMap[lackCfgId] then
                isRelative = true
                break
            end
        end

        if not isRelative then
            goto continue
        end

        buffUnitMap[buffCfgId] = buffUnit
        ::continue::
    end

    if next(buffUnitMap) == nil then return false end

    local activeBuffCfgs = {}
    local inactiveBuffCfgs = {}
    --- 把本家具的buffProvider加入到临时计算器中
    tempCalculator:AppendProvider(furnitureProvider)

    for buffCfgId, buffUnit in pairs(buffUnitMap) do
        if buffUnit:UpdateValidState(tempCalculator) then
            table.insert(activeBuffCfgs, {buffCfg = buffUnit.buffCfg, level = buffUnit.buffCfg:Level(), id = buffCfgId})
        else
            table.insert(inactiveBuffCfgs, {buffCfg = buffUnit.buffCfg, lackCount = buffUnit:GetLackTagCount(), level = buffUnit.buffCfg:Level(), id = buffCfgId})
        end
    end

    if #activeBuffCfgs > 0 then
        table.sort(activeBuffCfgs, function(a, b)
            if a.level ~= b.level then
                return a.level > b.level
            end
            return a.id > b.id
        end)
        self.recommendBuffCfg = activeBuffCfgs[1].buffCfg
        self.recommendComplete = true
    elseif #inactiveBuffCfgs > 0 then
        table.sort(inactiveBuffCfgs, function(a, b)
            if a.lackCount ~= b.lackCount then
                return a.lackCount < b.lackCount
            end
            if a.level ~= b.level then
                return a.level > b.level
            end
            return a.id > b.id
        end)
        self.recommendBuffCfg = inactiveBuffCfgs[1].buffCfg
        self.recommendComplete = false
    end

    if self.recommendBuffCfg ~= nil then
        self.relativeFurnitureCfg = lvCfg
        
        if self.tileView and not self.formulaAsset then
            self.formulaAsset = CityTileAssetLegoBuildingRecommandFormula.new(self, self.recommendBuffCfg, self.relativeFurnitureCfg, self.recommendComplete)
            self.tileView:AddAsset(self.formulaAsset)
        end
        return true
    else
        return false
    end
end

function CityLegoBuilding:HideRecommendFormula()
    self.recommendBuffCfg = nil
    self.relativeFurnitureCfg = nil
    self.recommendComplete = nil

    if self.tileView and self.formulaAsset then
        self.tileView:RemoveAsset(self.formulaAsset)
        self.formulaAsset = nil
    end
end

function CityLegoBuilding:IsShowRecommendFormula()
    return self.recommendBuffCfg ~= nil and self.relativeFurnitureCfg ~= nil
end

function CityLegoBuilding:IsShowExpireFormula()
    return self.expireBuffCfg ~= nil
end

function CityLegoBuilding:IsShowName()
    return self.manager:NeedShowBuildingName()
end

---@return boolean, RoomTagBuffConfigCell[]
function CityLegoBuilding:IsBuffExpireDueToFurnitureRemove(furnitureId)
    --- 没有生效buff时不需要显示
    if self.payload.BuffList:Count() == 0 then return false end

    local furniture = self.city.furnitureManager:GetFurnitureById(furnitureId)
    local targetLvCfg, roomCfg = ModuleRefer.CityLegoBuffModule:GetLevelCfgByRemoveFurniture(self, furniture)
    local willActiveBuffIdMap = {}
    for i = 1, targetLvCfg:RoomTagBuffsLength() do
        willActiveBuffIdMap[targetLvCfg:RoomTagBuffs(i)] = true
    end 

    local tempCalculator = CityLegoBuffCalculatorTemp.new()
    local providers = self.buffCalculator:GetAllPrividers()
    for _, v in ipairs(providers) do
        if v:GetType() == CityLegoBuffProviderType.Furniture and v.funitureId == furnitureId then
            goto continue
        end
        tempCalculator:AppendProvider(v)
        ::continue::
    end

    local willExpireBuffCfgs = {}
    for _, v in ipairs(self.payload.BuffList) do
        local buffCfg = ConfigRefer.RoomTagBuff:Find(v)
        if not willActiveBuffIdMap[v] then
            table.insert(willExpireBuffCfgs, buffCfg)
        else
            local buffUnit = CityLegoBuffUnit.new(buffCfg)
            if not buffUnit:UpdateValidState(tempCalculator) then
                table.insert(willExpireBuffCfgs, buffCfg)
            end
        end
    end

    if #willExpireBuffCfgs == 0 then return false end

    return true, willExpireBuffCfgs
end

function CityLegoBuilding:TryShowBuffExpireFormula(furnitureId)
    local flag, willExpireBuffCfgs = self:IsBuffExpireDueToFurnitureRemove(furnitureId)
    if not flag then return false end

    self.expireBuffCfg = willExpireBuffCfgs[1]
    if self.tileView and not self.expireFormulaAsset then
        self.expireFormulaAsset = CityTileAssetLegoBuildingExpireFormula.new(self, self.expireBuffCfg)
        self.tileView:AddAsset(self.expireFormulaAsset)
    end
    return true
end

function CityLegoBuilding:HideBuffExpireFormula()
    self.expireBuffCfg = nil

    if self.tileView and self.expireFormulaAsset then
        self.tileView:RemoveAsset(self.expireFormulaAsset)
        self.expireFormulaAsset = nil
    end
end

function CityLegoBuilding:IsUnlocked()
    return not self.roomLocked
end

function CityLegoBuilding:IsFogMask()
    for i = self.x, self.x + self.sizeX - 1 do
        for j = self.z, self.z + self.sizeZ - 1 do
            if self.city:IsFogMask(i, j) then
                return true
            end
        end
    end
    return false
end

function CityLegoBuilding:DontHasRoof()
    return next(self.roofs) == nil
end

function CityLegoBuilding:PlayVfx()
    local roomCfg = ConfigRefer.Room:Find(self.roomCfgId)
    local sizeEnum = roomCfg:Size()
    local vfxPath, vfxRotation = nil, nil
    if sizeEnum == RoomSize.SmallHor or sizeEnum == RoomSize.SmallVer then
        vfxPath = ManualResourceConst.vfx_city_gaibianfangjianleixing_9_12
    elseif sizeEnum == RoomSize.MiddleHor or sizeEnum == RoomSize.MiddleVer then
        vfxPath = ManualResourceConst.vfx_city_gaibianfangjianleixing_12_15
    elseif sizeEnum == RoomSize.LargeHor or sizeEnum == RoomSize.LargeVer then
        vfxPath = ManualResourceConst.vfx_city_gaibianfangjianleixing_15_18
    end

    if sizeEnum == RoomSize.SmallHor or sizeEnum == RoomSize.MiddleHor or sizeEnum == RoomSize.LargeHor then
        vfxRotation = 0
    elseif sizeEnum == RoomSize.SmallVer or sizeEnum == RoomSize.MiddleVer or sizeEnum == RoomSize.LargeVer then
        vfxRotation = 90
    end

    if vfxPath and vfxRotation then
        local handle = CS.DragonReborn.VisualEffect.VisualEffectHandle()
        handle:Create(vfxPath, "CityLegoBuilding", self.tileView.root.transform, function(flag, obj, tHandle)
            if not flag then return end
            if not self.city then return end
            if not self.tileView then return end
            if Utils.IsNull(self.tileView.root) then return end
            tHandle.Effect.transform.position = self.city:GetCenterWorldPositionFromCoord(self.x, self.z, self.sizeX, self.sizeZ)
            if vfxRotation ~= 0 then
                tHandle.Effect.transform.rotation = CS.UnityEngine.Quaternion.Euler(0, vfxRotation, 0)
            end
        end)
    end
end

function CityLegoBuilding:ShowScore()
    local roomCfg = ConfigRefer.Room:Find(self.roomCfgId)
    if not roomCfg then return false end

    return roomCfg:LevelInfosLength() > 1
end

function CityLegoBuilding:ClearNewBuffHint()
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(self.dynamicNode, 0)
end

function CityLegoBuilding:Movable()
    if self.payload.InnerFurnitureIds:Count() == 0 then return true end

    for _, v in ipairs(self.payload.InnerFurnitureIds) do
        local furniture = self.city.furnitureManager:GetFurnitureById(v)
        if furniture and not furniture:Movable() then
            return false
        end
    end

    return true
end

function CityLegoBuilding:GetNotMovableReason()
    for _, v in ipairs(self.payload.InnerFurnitureIds) do
        local furniture = self.city.furnitureManager:GetFurnitureById(v)
        if furniture and not furniture:Movable() then
            if furniture:IsProducing() then
                return I18N.Get("toast_room_cantmove_working")
            elseif furniture:IsPolluted() then
                return I18N.Get("toast_room_cantmove_creep")
            elseif furniture:IsLocked() then
                return I18N.Get("toast_room_cantmove_unrepair")
            else
                return I18N.GetWithParams("toast_cantmove_room_fur_config", furniture:GetName())
            end
        end
    end

    return string.Empty
end

function CityLegoBuilding:ShowName()
    if not self.tileView then return end

    if self.nameAsset == nil then
        self.nameAsset = CityTileAssetLegoBuildingName.new(self)
        self.tileView:AddAsset(self.nameAsset)
    end
end

function CityLegoBuilding:HideName()
    if not self.tileView then return end

    if self.nameAsset then
        self.tileView:RemoveAsset(self.nameAsset)
        self.nameAsset = nil
    end
end

function CityLegoBuilding:IsShowLockedServiceBubble()
    return self.showLockedServiceBubble
end

---@param npcServiceCfg NpcServiceConfigCell
function CityLegoBuilding:ShowLockedServiceBubble(npcServiceCfg)
    self.showLockedServiceBubble = true
    self.lockedServiceCfg = npcServiceCfg

    if self.tileView and not self.lockedServiceBubbleAsset then
        self.lockedServiceBubbleAsset = CityTileAssetLegoBuildingLockedServiceBubble.new(self, npcServiceCfg)
        self.tileView:AddAsset(self.lockedServiceBubbleAsset)
    end
end

function CityLegoBuilding:HideLockedServiceBubble()
    self.showLockedServiceBubble = false
    self.lockedServiceCfg = nil

    if self.tileView and self.lockedServiceBubbleAsset then
        self.tileView:RemoveAsset(self.lockedServiceBubbleAsset)
        self.lockedServiceBubbleAsset = nil
    end
end

return CityLegoBuilding