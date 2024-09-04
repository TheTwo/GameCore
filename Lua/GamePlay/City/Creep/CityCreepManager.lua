local CityManagerBase = require("CityManagerBase")
---@class CityCreepManager:CityManagerBase
---@field new fun():CityCreepManager
---@field originData table<number, number[]>
---@field areaTimer table<number, Timer>
local CityCreepManager = class("CityCreepManager", CityManagerBase)
local RectDyadicMap = require("RectDyadicMap")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local CreepStatus = require("CreepStatus")
local ConfigRefer = require("ConfigRefer")
local ManualResourceConst = require("ManualResourceConst")
local OnChangeHelper = require("OnChangeHelper")
local CityCreepType = require("CityCreepType")
local CameraConst = require("CameraConst")
local EventConst = require("EventConst")
local CityElementType = require("CityElementType")
local Utils = require("Utils")

function CityCreepManager.OnConfigLoaded()
    local CityCreepController = CS.CityCreepController
    local colorDying = ColorUtil.FromColor32Cfg(ConfigRefer.CityConfig:PollutedColorDying())
    local colorDead = ColorUtil.FromColor32Cfg(ConfigRefer.CityConfig:PollutedColorDead())
    local colorSelect = ColorUtil.FromColor32Cfg(ConfigRefer.CityConfig:PollutedChooseColor())
    local selectIntencity = ConfigRefer.CityConfig:PollutedChooseIntensity()
    local blinkSpeed = ConfigRefer.CityConfig:PollutedChooseBlinkSpeed()
    colorSelect.a = blinkSpeed
    CityCreepController.InitializeGlobalShaderProperties(colorDying, colorDead, colorSelect, selectIntencity)
end

---@param city MyCity
function CityCreepManager:DoDataLoad()
    self:InitCreepArea()
    self:InitOriginData()

    -- g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.MsgPath, Delegate.GetOrCreate(self, self.OnCastleCreepRelativeChanged))
    -- 菌毯已经没了 配合菌毯污染的效果也取了
    -- g_Game.EventManager:AddListener(EventConst.CITY_BUILDING_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnBuildingPollutedOut))
    -- g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnFurniturePollutedOut))
    -- g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnElementPollutedOut))
    return self:DataLoadFinish()
end

function CityCreepManager:DoViewLoad()
    self:InitController()
    -- self:ApplyBuffer()
    return self:ViewLoadFinish()
end

function CityCreepManager:DoDataUnload()
    -- g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.MsgPath, Delegate.GetOrCreate(self, self.OnCastleCreepRelativeChanged))
    -- 菌毯已经没了 配合菌毯污染的效果也取了
    -- g_Game.EventManager:RemoveListener(EventConst.CITY_BUILDING_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnBuildingPollutedOut))
    -- g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnFurniturePollutedOut))
    -- g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnElementPollutedOut))

    self.area = nil
    self.packBuffer = nil
    self.localRemove = nil
    self.originData = nil
end

function CityCreepManager:DoViewUnload()
    ---Do Nothing
end

---@param entity wds.CastleBrief
function CityCreepManager:OnCastleCreepRelativeChanged(entity, changeTable)
    if entity.ID ~= self.city.uid then return end

    if changeTable.CastleCreep and changeTable.CastleCreep.Info then
        local changedIdx = {}
        self:OnCreepInfoTrunkChanged(changeTable.CastleCreep.Info, changedIdx)
        local AddMap, RemoveMap, ChangeMap = self:GenerateSubChangeTable(changeTable.CastleCreep.Info, entity.Castle.CastleCreep)
        self:OnCreepInfoSubChanged(entity, AddMap, RemoveMap, ChangeMap, changedIdx)
        self:ApplyBufferPartial(changedIdx)
    end
end

---@private
function CityCreepManager:InitCreepArea()
    self.highlight = {}
    local gridConfig = self.city.gridConfig
    self.area = RectDyadicMap.new(gridConfig.cellsX, gridConfig.cellsY)
    self.idMap = RectDyadicMap.new(gridConfig.cellsX, gridConfig.cellsY)
    self.idLine = RectDyadicMap.new(gridConfig.cellsX, gridConfig.cellsY)
    self.localRemove = {}
    local castle = self.city:GetCastle()
    -- self:DeserializeImp(castle)
end

---@private
function CityCreepManager:InitOriginData()
    local castle = self.city:GetCastle()
    local creepData = castle.CastleCreep
    self.originData = {}

    for id, info in pairs(creepData.Info) do
        self.originData[id] = {}
        for idx, value in ipairs(info.Data) do
            self.originData[id][idx] = value
        end
    end
end

---@private
---@param creepInfo wds.CastleCreep
function CityCreepManager:GenerateSubChangeTable(changeTable, creepInfo)
    local idMap = {}
    for id, change in pairs(changeTable) do
        if not change.Data then
            goto continue
        end
        idMap[id] = id
        ::continue::
    end

    return self:GenerateChangeTableImp(idMap, creepInfo) 
end

function CityCreepManager:GenerateChangeTableImp(idMap, creepInfo)
    local AddMap, RemoveMap, ChangeMap = {}, {}, {}
    for id, _ in pairs(idMap) do
        local newData = creepInfo.Info[id] and creepInfo.Info[id].Data
        local oldLength = self.originData[id] ~= nil and #self.originData[id] or 0
        local newLength = newData ~= nil and #newData or 0

        if oldLength <= newLength then
            local subChange = {}
            local subAdd = {}
            for i = 1, newLength do
                if i > oldLength then
                    subAdd[i] = newData[i]
                    self.originData[id][i] = newData[i]
                elseif self.originData[id][i] ~= newData[i] then
                    subChange[i] = {self.originData[id][i], newData[i]}
                    self.originData[id][i] = newData[i]
                end
            end

            if next(subAdd) then
                AddMap[id] = subAdd
            end
            if next(subChange) then
                ChangeMap[id] = subChange
            end
        else
            local subChange = {}
            local subRemove = {}
            for i = 1, oldLength do
                if i > newLength then
                    subRemove[i] = self.originData[id][i]
                    self.originData[id][i] = nil
                elseif self.originData[id][i] ~= newData[i] then
                    subChange[i] = {self.originData[id][i], newData[i]}
                    self.originData[id][i] = newData[i]
                end
            end

            if next(subRemove) then
                RemoveMap[id] = subRemove
            end
            if next(subChange) then
                ChangeMap[id] = subChange
            end
        end
    end

    return AddMap, RemoveMap, ChangeMap
end

function CityCreepManager:InitController()
    self:InitCreepQuality()
    local gridConfig = self.city.gridConfig
    -- local reciprocal = 1 / (gridConfig.cellsX * gridConfig.unitsPerCellX * self.city.scale)
    -- self.creepController:Init(gridConfig.cellsX, gridConfig.cellsY, self.city.zeroPoint.x, self.city.zeroPoint.z, reciprocal,
    --     self.city.CityVfxRoot)
    -- self.creepDecorationController:Init(gridConfig.cellsX, gridConfig.cellsY, gridConfig.unitsPerCellX, gridConfig.unitsPerCellY,
    --     self.city.zeroPoint, self.city.scale, self.city.CityRoot.transform)
    local layer = CS.UnityEngine.LayerMask.NameToLayer("City")
    self.creepInstancingController:Init(gridConfig.cellsX, gridConfig.cellsY, self.city.zeroPoint.x, 
        self.city.zeroPoint.z, self.city.scale, CameraConst.PLANE, 0.1, layer)
    local colorDying = ColorUtil.FromColor32Cfg(ConfigRefer.CityConfig:PollutedColorDying())
    local colorDead = ColorUtil.FromColor32Cfg(ConfigRefer.CityConfig:PollutedColorDead())
    local colorSelect = ColorUtil.FromColor32Cfg(ConfigRefer.CityConfig:PollutedChooseColor())
    local blinkSpeed = ConfigRefer.CityConfig:PollutedChooseBlinkSpeed()
    local selectIntencity = ConfigRefer.CityConfig:PollutedChooseIntensity()
    colorSelect.a = blinkSpeed
    self.creepController.PollutedColorDying = colorDying
    self.creepController.PollutedColorDead = colorDead
    self.creepController.PollutedColorBlink = colorSelect
    self.creepController.PollutedBlinkIntensity = selectIntencity
end

function CityCreepManager:OnBasicResourceLoadFinish()
    self.creepController = self.city.creepController
    self.creepController.enabled = false
    self.creepInstancingController = self.city.creepInstancingController
    self.creepInstancingController.enabled = false
    self.creepDecorationController = self.city.creepDecorationController
    self.creepDecorationController.enabled = false
    self.creepInstancingController.scale = 0.2
end

function CityCreepManager:OnBasicResourceUnloadStart()
    self.creepDecorationController = nil
    self.creepController = nil
end

function CityCreepManager:OnCameraLoaded(camera)
    -- self.creepDecorationController:SetCamera(camera.mainCamera)
    self.creepInstancingController.drawCam = camera.mainCamera
end

function CityCreepManager:OnCameraUnload()
    -- self.creepDecorationController:SetCamera(nil)
end

function CityCreepManager:InitCreepQuality()
    local level = g_Game.PerformanceLevelManager.qualityLevelConfig:MinPerfLevel()
    self.creepController.MaskMulti = math.clamp(level+1, 1, 3)
end

---@private
---@param castle wds.Castle
function CityCreepManager:DeserializeImp(castle)
    local infos = castle.CastleCreep.Info
    for id, info in pairs(infos) do
        local sizeX = info.Width
        local sizeY = info.Height

        local originX = info.Pos.X
        local originY = info.Pos.Y

        local idx = 0
        for i, v in ipairs(info.Data) do
            for j = 0, 63 do
                local flag = (v & (1 << j)) ~= 0
                local x = (idx % sizeX) + originX
                local y = (idx // sizeX) + originY
                local key = self.area:Key(x, y)
                local creepValue = flag and CreepStatus.ACTIVE or nil
                if self.area.map[key] == CreepStatus.ACTIVE then
                    if creepValue == CreepStatus.ACTIVE then
                        g_Logger.Error("同一个点有两个菌毯数据")
                    end
                else
                    self.area.map[key] = creepValue
                    local idValue = flag and id or nil
                    if idValue and self.idMap.map[key] then
                        g_Logger.Error("同一个点归属于两片菌毯来源")
                    else
                        self.idMap.map[key] = idValue
                        self.idLine.map[key] = idx
                    end
                end
                idx = idx + 1

                if idx >= sizeX * sizeY then
                    break
                end
            end

            if idx >= sizeX * sizeY then
                break
            end
        end
    end
end

function CityCreepManager:OnCreepInfoTrunkChanged(changeTable, dirtyIdxMap)
    local add, remove, _ = OnChangeHelper.GenerateMapFieldChangeMap(changeTable, wds.CreepInfo)
    if add then
        for id, info in pairs(add) do
            local sizeX = info.Width
            local originX = info.Pos.X
            local originY = info.Pos.Y

            self.originData[id] = {}
            for idx, value in ipairs(info.Data) do
                local startIdx = (idx - 1) * 64
                for i = 0, 63 do
                    local flag = (value & (1 << i)) ~= 0
                    local x = ((startIdx + i) % sizeX) + originX
                    local y = ((startIdx + i) // sizeX) + originY
                    local key = self.area:Key(x, y)
                    local creepValue = flag and CreepStatus.ACTIVE or nil
                    if self.area.map[key] == CreepStatus.ACTIVE then
                        if creepValue == CreepStatus.ACTIVE then
                            g_Logger.Error("同一个点有两个菌毯数据")
                        end
                    else
                        self.area.map[key] = creepValue
                        local idValue = flag and id or nil
                        if idValue and self.idMap.map[key] and idValue ~= self.idMap.map[key] then
                            g_Logger.Error("(%d,%d)从菌毯块%d改成了菌毯块%d", x, y, self.idMap.map[key], idValue)
                        else
                            self.idMap.map[key] = idValue
                            self.idLine.map[key] = startIdx + i
                        end
                    end

                    dirtyIdxMap[key] = true
                end
                self.originData[id][idx] = value
            end
        end
    end

    if remove then
        for id, info in pairs(remove) do
            local sizeX = info.Width
            local originX = info.Pos.X
            local originY = info.Pos.Y

            for idx, value in pairs(self.originData[id]) do
                local startIdx = (idx - 1) * 64
                for i = 0, 63 do
                    local flag = (value & (1 << i)) ~= 0
                    if flag then
                        local x = ((startIdx + i) % sizeX) + originX
                        local y = ((startIdx + i) // sizeX) + originY
                        local key = self.area:Key(x, y)
                        self.area.map[key] = nil
                        self.idMap.map[key] = nil
                        self.idLine.map[key] = nil
                        dirtyIdxMap[key] = true
                    end
                end
            end
            self.originData[id] = nil
        end
    end
end

---@param entity wds.CastleBrief
function CityCreepManager:OnCreepInfoSubChanged(entity, AddMap, RemoveMap, ChangeMap, dirtyIdxMap)
    for id, subAdd in pairs(AddMap) do
        local info = entity.Castle.CastleCreep.Info[id]
        local sizeX = info.Width
        local originX = info.Pos.X
        local originY = info.Pos.Y

        for idx, value in pairs(subAdd) do
            local startIdx = (idx - 1) * 64
            for i = 0, 63 do
                local flag = (value & (1 << i)) ~= 0
                local x = ((startIdx + i) % sizeX) + originX
                local y = ((startIdx + i) // sizeX) + originY
                local key = self.area:Key(x, y)
                local creepValue = flag and CreepStatus.ACTIVE or nil
                if self.area.map[key] == CreepStatus.ACTIVE then
                    if creepValue == CreepStatus.ACTIVE then
                        g_Logger.Error("同一个点有两个菌毯数据")
                    end
                else
                    self.area.map[key] = creepValue
                    local idValue = flag and id or nil
                    if idValue and self.idMap.map[key] and idValue ~= self.idMap.map[key] then
                        g_Logger.Error("(%d,%d)从菌毯块%d改成了菌毯块%d", x, y, self.idMap.map[key], idValue)
                    else
                        self.idMap.map[key] = idValue
                        self.idLine.map[key] = startIdx + i
                    end
                end

                dirtyIdxMap[key] = true
            end
        end
    end

    for id, subRemove in pairs(RemoveMap) do
        local info = entity.Castle.CastleCreep.Info[id]
        local sizeX = info.Width
        local originX = info.Pos.X
        local originY = info.Pos.Y
        for idx, value in pairs(subRemove) do
            local startIdx = (idx - 1) * 64
            for i = 0, 63 do
                local flag = (value & (1 << i)) ~= 0
                if flag then
                    local x = ((startIdx + i) % sizeX) + originX
                    local y = ((startIdx + i) // sizeX) + originY
                    local key = self.area:Key(x, y)
                    self.area.map[key] = nil
                    self.idMap.map[key] = nil
                    self.idLine.map[key] = nil
                    dirtyIdxMap[key] = true
                end
            end
        end
    end

    for id, subChange in pairs(ChangeMap) do
        local info = entity.Castle.CastleCreep.Info[id]
        local sizeX = info.Width
        local originX = info.Pos.X
        local originY = info.Pos.Y
        for idx, fromTo in pairs(subChange) do
            local startIdx = (idx - 1) * 64
            local from = fromTo[1]
            local to = fromTo[2]

            local xor = from ~ to
            for i = 0, 63 do
                if (xor & (1 << i)) ~= 0 then
                    local flag = (to & (1 << i)) ~= 0
                    local x = ((startIdx + i) % sizeX) + originX
                    local y = ((startIdx + i) // sizeX) + originY
                    local creepValue = flag and CreepStatus.ACTIVE or CreepStatus.NONE
                    local key = self.area:Key(x, y)
                    self.area.map[key] = creepValue

                    local idValue = flag and id or nil
                    if idValue and self.idMap.map[key] and idValue ~= self.idMap.map[key] then
                        g_Logger.Error("(%d,%d)从菌毯块%d改成了菌毯块%d", x, y, self.idMap.map[key], idValue)
                    else
                        self.idMap.map[key] = idValue
                        self.idLine.map[key] = startIdx + i
                    end

                    dirtyIdxMap[key] = true
                end
            end
        end
    end
end

---@return boolean 某个坐标是否有菌毯
function CityCreepManager:IsAffect(x, y)
    local value = self.area:Get(x, y)
    return value ~= CreepStatus.NONE and value ~= nil
end

---@return boolean 某个坐标是否有菌毯：清理模式专用API
function CityCreepManager:IsAffectWithBlockCheck(x, y)
    local key = self.area:Key(x, y)
    if self.localRemove[key] then return false end
    return self.area.map[key] == CreepStatus.ACTIVE
end

---@private
function CityCreepManager:GenerateBuffer()
    local packTab = self:GetPackBuffer()

    local highlight = self.highlight or {}
    local highlightMap = {}
    for i, v in ipairs(highlight) do
        highlightMap[v] = true
    end

    for k, v in pairs(self.area.map) do
        if v ~= CreepStatus.NONE and not self.localRemove[k] then
            packTab[k] = v
            if highlightMap[k] then
                packTab[k] = packTab[k] | CreepStatus.SELECTED
            end
        end
    end

    return packTab
end

---@private
function CityCreepManager:GetPackBuffer()
    if self.packBuffer == nil then
        local gridConfig = self.city.gridConfig
        local x = gridConfig.cellsX
        local y = gridConfig.cellsY
        self.packBuffer = bytearray.new(x * y)
    end
    self.packBuffer:clear()
    return self.packBuffer
end

---@return CityElementDataConfigCell[]
function CityCreepManager:GetCreepNodeCollection()
    local ret = {}
    for _, cell in ConfigRefer.CityCreep:pairs() do
        local elementCfg = ConfigRefer.CityElementData:Find(cell:RelElement())
        if self.city.elementManager:Exist(elementCfg:Pos():X(), elementCfg:Pos():Y()) then
            table.insert(ret, elementCfg)
        end
    end
    return ret
end

---@param elementDataId number
function CityCreepManager:GetCreepConfig(elementDataId)
    for _, config in ConfigRefer.CityCreep:pairs() do
        if config:RelElement() == elementDataId then
            return config
        end
    end
    return nil
end

function CityCreepManager:CollectHighlight(x, y, ignoreId)
    local highlight = {}
    local id
    if not ignoreId then
        id = self.idMap:Get(x, y)
        if id == nil then return highlight end
    end

    local status = self.area:Get(x, y)
    if status == nil then return highlight end

    local start = {self.idMap:Key(x, y)}
    while #start > 0 do
        local cur = table.remove(start)
        if not highlight[cur - 1] and (ignoreId or self.idMap.map[cur] == id) and self.area.map[cur] == status then
            highlight[cur - 1] = true
            table.insert(start, cur + 1)
            table.insert(start, cur - 1)
            table.insert(start, cur + self.idMap.maxX)
            table.insert(start, cur - self.idMap.maxX)
        end
    end
    return highlight
end

function CityCreepManager:SelectHighlight(x, y)
    self.highlightX, self.highlightY = x, y
    local highlight = self:CollectHighlight(x, y)
    self:DOHighlight(highlight)
end

function CityCreepManager:CancelHighlight()
    self.highlightX, self.highlightY = nil, nil
    self:DOHighlight(nil)
end

function CityCreepManager:DOHighlight(highlight)
    table.clear(self.highlight)
    if highlight then
        for k, v in pairs(highlight) do
            if v then
                table.insert(self.highlight, k)
            end
        end
    end
    -- self.creepController:Highlight(self.highlight, #self.highlight)
    self.creepInstancingController:Highlight(self.highlight, #self.highlight)
end

function CityCreepManager:BlockCreepArea(minX, minY, maxX, maxY)
    local dirtyIdxMap = {}
    for y = minY, maxY do
        for x = minX, maxX do
            local key = self.area:Key(x, y)
            self.localRemove[key] = true
            dirtyIdxMap[key] = true
        end
    end

    self:ApplyBufferPartial(dirtyIdxMap)
end

function CityCreepManager:BlockCreepAreaPartial(minX, minY, maxX, maxY, tileCount)
    if tileCount == 0 then return end

    local dirtyIdxMap = {}
    local count = 0
    for y = minY, maxY do
        for x = minX, maxX do
            local key = self.area:Key(x, y)
            if self.area.map[key] == CreepStatus.ACTIVE then
                count = count + 1
                self.localRemove[key] = true
                dirtyIdxMap[key] = true
            end

            if count >= tileCount then
                break
            end
        end
        if count >= tileCount then
            break
        end
    end

    self:ApplyBufferPartial(dirtyIdxMap)
end

---@param areas {minX:number, minY:number, maxX:number, maxY:number}[]
function CityCreepManager:CancelBlockCreepAreas(areas)
    local dirtyIdxMap = {}
    for i, area in ipairs(areas) do
        for x = area.minX, area.maxX do
            for y = area.minY, area.maxY do
                local key = self.area:Key(x, y)
                self.localRemove[key] = nil
                dirtyIdxMap[key] = true
            end
        end
    end
    
    self:ApplyBufferPartial(dirtyIdxMap)
end

function CityCreepManager:CancelAllBlockCreepArea()
    local dirtyIdxMap = self.localRemove
    self.localRemove = {}
    self:ApplyBufferPartial(dirtyIdxMap)
end

function CityCreepManager:ApplyBuffer()
    local buffer = self:GenerateBuffer()
    local pointer, length = buffer:topointer()
    -- if Utils.IsNotNull(self.creepController) then
    --     self.creepController:LoadFromLuaTableRef(pointer, length)
    -- end
    if Utils.IsNotNull(self.creepInstancingController) then
        self.creepInstancingController:LoadFromLuaTableRef(pointer, length)
    end
    -- self.city.creepDecorationController:SyncBufferByLuaArrayTableRef(pointer, length)
end

function CityCreepManager:ApplyBufferPartial(dirtyIdxMap)
    local buffer = self:GetPackBuffer()
    local dirtyArray = {}
    local highlight = self.highlight or {}
    local highlightMap = {}
    for i, v in ipairs(highlight) do
        highlightMap[v] = true
    end

    for idx, _ in pairs(dirtyIdxMap) do
        buffer[idx] = self.area.map[idx] or CreepStatus.NONE
        if highlightMap[idx] and buffer[idx] > 0 then
            buffer[idx] = buffer[idx] | CreepStatus.SELECTED
        end
        if self.localRemove[idx] then
            buffer[idx] = CreepStatus.NONE
        end
        table.insert(dirtyArray, idx-1)
    end

    local pointer, size = buffer:topointer()
    -- if Utils.IsNotNull(self.creepController) then
    --     self.city.creepController:LoadFromLuaTableRefPartial(pointer, size, dirtyArray, #dirtyArray)
    -- end
    if Utils.IsNotNull(self.city.creepInstancingController) then
        self.city.creepInstancingController:LoadFromLuaTableRefPartial(pointer, size, dirtyArray, #dirtyArray)
    end
    -- if Utils.IsNotNull(self.city.creepDecorationController) then
    --     self.city.creepDecorationController:SyncBufferByLuaArrayTableRefPartial(pointer, size, dirtyArray, #dirtyArray)
    -- end
end

---@param cell CityCreepConfigCell
function CityCreepManager:GetKernelRelativeActiveNodeCount(cell)
    if cell == nil then return 0 end
    if cell:Type() == CityCreepType.Node then return 0 end

    local count = 0
    for i = 1, cell:ChildNodeLength() do
        local nodeCfgId = cell:ChildNode(i)
        local nodeCfg = ConfigRefer.CityCreep:Find(nodeCfgId)
        if nodeCfg == nil then goto continue end
        if nodeCfg:Type() ~= CityCreepType.Node then goto continue end
        local elementId = nodeCfg:RelElement()
        if elementId == 0 then goto continue end
        if self.city.elementManager:IsHidden(elementId) then goto continue end
        local elementCfg = ConfigRefer.CityElementData:Find(elementId)
        if elementCfg == nil then goto continue end
        if not self.city.elementManager:Exist(elementCfg:Pos():X(), elementCfg:Pos():Y()) then goto continue end
        local castle = self.city:GetCastle()
        local info = castle.CastleCreep.Info[nodeCfg:AreaId()]
        if info and not info.Removed then
            count = count + 1
        end
        ::continue::
    end
    return count
end

---@param creepId number CityCreep表的Id
function CityCreepManager:GetCreepDB(creepId)
    local castle = self.city:GetCastle()
    return castle.CastleCreep.Info[creepId]
end

---@param info wds.CreepInfo
function CityCreepManager:RespawnTime(info)
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    return info.RespawnTime or curTime + 10
end

function CityCreepManager:OnBuildingPollutedOut(buildingId)
    local building = self.city.buildingManager:GetBuilding(buildingId)
    if not building then return end
    local info = {x = building.x, y = building.y, sizeX = building.sizeX, sizeY = building.sizeY}
    self:PlayPollutedOutVfx(info)
end

function CityCreepManager:OnFurniturePollutedOut(furnitureId)
    local furniture = self.city.furnitureManager:GetFurnitureById(furnitureId)
    if not furniture then return end
    if not furniture.x or not furniture.y then return end
    local info = {x = furniture.x, y = furniture.y, sizeX = furniture.sizeX, sizeY = furniture.sizeY}
    self:PlayPollutedOutVfx(info)
end

function CityCreepManager:OnElementPollutedOut(elementDataId)
    local elementCfg = ConfigRefer.CityElementData:Find(elementDataId)
    if not elementCfg then return end
    local typ = elementCfg:Type()
    if typ == CityElementType.Npc then
        local npcCfg = ConfigRefer.CityElementNpc:Find(elementCfg:ElementId())
        if not npcCfg then return end
        local info = {x = elementCfg:Pos():X(), y = elementCfg:Pos():Y(), sizeX = npcCfg:SizeX(), sizeY = npcCfg:SizeY()}
        self:PlayPollutedOutVfx(info)
    elseif typ == CityElementType.Resource then
        local resCfg = ConfigRefer.CityElementResource:Find(elementCfg:ElementId())
        if not resCfg then return end
        local info = {x = elementCfg:Pos():X(), y = elementCfg:Pos():Y(), sizeX = resCfg:SizeX(), sizeY = resCfg:SizeY()}
        self:PlayPollutedOutVfx(info)
    end
end

---@param info {x:number, y:number, sizeX:number, sizeY:number}
function CityCreepManager:PlayPollutedOutVfx(info)
    if info.sizeX <= 3 or info.sizeY <= 3 then
        info.vfxSize = 2
        self.city.createHelper:Create(ManualResourceConst.vfx_w_common_build_clear_01, self.city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnPollutedOutVfxLoaded), info)
    elseif info.sizeX <= 5 or info.sizeY <= 5 then
        info.vfxSize = 4
        self.city.createHelper:Create(ManualResourceConst.vfx_w_common_build_clear_01_2, self.city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnPollutedOutVfxLoaded), info)
    else
        info.vfxSize = 10
        self.city.createHelper:Create(ManualResourceConst.vfx_w_common_build_clear_01_3, self.city.CityRoot.transform, Delegate.GetOrCreate(self, self.OnPollutedOutVfxLoaded), info)
    end
end

---@param info {x:number, y:number, sizeX:number, sizeY:number}
function CityCreepManager:OnPollutedOutVfxLoaded(go, info, handle)
    local Utils = require("Utils")
    if Utils.IsNull(go) then
        handle:Delete()
        return
    end

    go:SetLayerRecursively("City")
    local trans = go.transform
    local expandWidth, expandHeight = 1, 1
    local x, y = info.x - expandWidth / 2, info.y - expandHeight / 2
    local sizeX, sizeY = info.sizeX + expandWidth, info.sizeY + expandHeight
    trans.position = self.city:GetCenterWorldPositionFromCoord(x, y, sizeX, sizeY)
    trans.localScale = {x = sizeX / info.vfxSize, y = 1, z = sizeY / info.vfxSize}
    handle:Delete(5)
end

function CityCreepManager:CacheChangeInfo(info)
    for id, v in pairs(info) do
        if not info.Data then goto continue end
        self.changeCache[id] = id
        ::continue::
    end
end

function CityCreepManager:NeedLoadData()
    return true
end

function CityCreepManager:NeedLoadView()
    return true
end

return CityCreepManager