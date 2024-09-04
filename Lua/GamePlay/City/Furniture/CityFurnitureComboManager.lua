---@class CityFurnitureComboManager
---@field new fun():CityFurnitureComboManager
local CityFurnitureComboManager = class("CityFurnitureComboManager")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

---@param city City
function CityFurnitureComboManager:Initialize(city)
    self.city = city
    self.comboMap = {}

    self:LoadData()
    g_Game.EventManager:AddListener(EventConst.CITY_PLACE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurniturePlaced))
    g_Game.EventManager:AddListener(EventConst.CITY_STORAGE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureStorage))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_ADD, Delegate.GetOrCreate(self, self.OnBuildingAdd))
    g_Game.EventManager:AddListener(EventConst.CITY_GRID_ON_CELL_REMOVE, Delegate.GetOrCreate(self, self.OnBuildingRemove))
end

function CityFurnitureComboManager:Release()
    g_Game.EventManager:RemoveListener(EventConst.CITY_PLACE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurniturePlaced))
    g_Game.EventManager:RemoveListener(EventConst.CITY_STORAGE_FURNITURE, Delegate.GetOrCreate(self, self.OnFurnitureStorage))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_ADD, Delegate.GetOrCreate(self, self.OnBuildingAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_GRID_ON_CELL_REMOVE, Delegate.GetOrCreate(self, self.OnBuildingRemove))

    self.comboMap = nil
    self.city = nil
end

function CityFurnitureComboManager:LoadData()
    local castle = self.city:GetCastle()
    local furnitureMap = castle.CastleFurniture
    for id, buildingInfo in pairs(castle.BuildingInfos) do
        local lvCell = ModuleRefer.CityConstructionModule:GetBuildingLevelConfigCellByTypeId(buildingInfo.BuildingType, buildingInfo.Level)
        if lvCell:FurnitureCombinationsLength() == 0 then
            goto continue
        end

        local TypeToCount = {}
        local furnitures = buildingInfo.InnerFurniture
        for _, furId in ipairs(furnitures) do
            local furLvCell = ConfigRefer.CityFurnitureLevel:Find(furnitureMap[furId].ConfigId)
            local typ = furLvCell:Type()
            TypeToCount[typ] = (TypeToCount[typ] or 0) + 1
        end

        for i = 1, lvCell:FurnitureCombinationsLength() do
            local match = true
            local comboId = lvCell:FurnitureCombinations(i)
            local comboCell = ConfigRefer.CityFurnitureCombination:Find(comboId)
            for j = 1, comboCell:FurnitureListLength() do
                local cfg = comboCell:FurnitureList(j)
                if (TypeToCount[cfg:Type()] or 0) < cfg:Count() then
                    match = false
                    break
                end 
            end

            if match then
                self.comboMap[id] = i
            end
        end

        ::continue::
    end
end

---@param city City
function CityFurnitureComboManager:OnFurniturePlaced(city, x, y)
    if self.city ~= city then return end

    local cell = city.grid:GetCell(x, y)
    if not cell then
        return
    end

    if not cell:IsBuilding() then
        return
    end

    local lvCell = ConfigRefer.BuildingLevel:Find(cell.configId)
    if lvCell:FurnitureCombinationsLength() == 0 then
        return
    end

    local castle = city:GetCastle()
    local furnitureMap = castle.CastleFurniture
    local buildingInfo = castle.BuildingInfos[cell.tileId]
    local TypeToCount = {}
    local furnitures = buildingInfo.InnerFurniture
    for _, furId in ipairs(furnitures) do
        local furLvCell = ConfigRefer.CityFurnitureLevel:Find(furnitureMap[furId].ConfigId)
        local typ = furLvCell:Type()
        TypeToCount[typ] = (TypeToCount[typ] or 0) + 1
    end

    for i = 1, lvCell:FurnitureCombinationsLength() do
        local match = true
        local comboId = lvCell:FurnitureCombinations(i)
        local comboCell = ConfigRefer.CityFurnitureCombination:Find(comboId)
        for j = 1, comboCell:FurnitureListLength() do
            local cfg = comboCell:FurnitureList(j)
            if (TypeToCount[cfg:Type()] or 0) < cfg:Count() then
                match = false
                break
            end 
        end

        if match then
            if self.comboMap[cell.tileId] ~= i  then
                self:PlayChange(cell, lvCell, self.comboMap[cell.tileId], i)
            end
            return
        end
    end
end

---@param city City
function CityFurnitureComboManager:OnFurnitureStorage(city, x, y, sizeX, sizeY)
    if self.city ~= city then return end

    local cell = city.grid:GetCell(x, y)
    if not cell then
        return
    end

    if not cell:IsBuilding() then
        return
    end

    if not self.comboMap[cell.tileId] then
        return
    end

    local lvCell = ConfigRefer.BuildingLevel:Find(cell.configId)
    if lvCell:FurnitureCombinationsLength() == 0 then
        return
    end

    local castle = city:GetCastle()
    local furnitureMap = castle.CastleFurniture
    local buildingInfo = castle.BuildingInfos[cell.tileId]
    if buildingInfo == nil then
        return
    end

    local TypeToCount = {}
    local furnitures = buildingInfo.InnerFurniture
    for _, furId in ipairs(furnitures) do
        local furLvCell = ConfigRefer.CityFurnitureLevel:Find(furnitureMap[furId].ConfigId)
        local typ = furLvCell:Type()
        TypeToCount[typ] = (TypeToCount[typ] or 0) + 1
    end

    for i = 1, lvCell:FurnitureCombinationsLength() do
        local match = true
        local comboId = lvCell:FurnitureCombinations(i)
        local comboCell = ConfigRefer.CityFurnitureCombination:Find(comboId)
        for j = 1, comboCell:FurnitureListLength() do
            local cfg = comboCell:FurnitureList(j)
            if (TypeToCount[cfg:Type()] or 0) < cfg:Count() then
                match = false
                break
            end 
        end

        if match then
            if self.comboMap[cell.tileId] ~= i  then
                self:PlayChange(cell, lvCell, self.comboMap[cell.tileId], i)
            end
            return
        end
    end

    self:PlayChange(cell, lvCell, self.comboMap[cell.tileId], nil)
end

function CityFurnitureComboManager:OnBuildingAdd(city, x, y)
    if self.city ~= city then return end

    local cell = city.grid:GetCell(x, y)
    if not cell:IsBuilding() then
        return
    end

    local lvCell = ConfigRefer.BuildingLevel:Find(cell.configId)
    if lvCell:FurnitureCombinationsLength() == 0 then
        return
    end

    local castle = city:GetCastle()
    local furnitureMap = castle.CastleFurniture
    local buildingInfo = castle.BuildingInfos[cell.tileId]
    local TypeToCount = {}
    local furnitures = buildingInfo.InnerFurniture
    for _, furId in ipairs(furnitures) do
        local furLvCell = ConfigRefer.CityFurnitureLevel:Find(furnitureMap[furId].ConfigId)
        local typ = furLvCell:Type()
        TypeToCount[typ] = (TypeToCount[typ] or 0) + 1
    end

    for i = 1, lvCell:FurnitureCombinationsLength() do
        local match = true
        local comboId = lvCell:FurnitureCombinations(i)
        local comboCell = ConfigRefer.CityFurnitureCombination:Find(comboId)
        for j = 1, comboCell:FurnitureListLength() do
            local cfg = comboCell:FurnitureList(j)
            if (TypeToCount[cfg:Type()] or 0) < cfg:Count() then
                match = false
                break
            end 
        end

        if match then
            if self.comboMap[cell.tileId] ~= i  then
                self:PlayChange(cell, lvCell, self.comboMap[cell.tileId], i)
            end
            return
        end
    end
end

---@param cell CityGridCell
function CityFurnitureComboManager:OnBuildingRemove(city, cell)
    if not cell or cell.tileId == 0 then
        return
    end
    
    self.comboMap[cell.tileId] = nil
end

---@param cell CityGridCell
---@param lvCell BuildingLevelConfigCell
function CityFurnitureComboManager:PlayChange(cell, lvCell, from, to)
    self.comboMap[cell.tileId] = to
    local tile = self.city.gridView:GetCellTile(cell.x, cell.y)
    if tile == nil then
        return
    end

    if from == nil and to ~= nil then
        local comboId = lvCell:FurnitureCombinations(to)
        local comboCell = ConfigRefer.CityFurnitureCombination:Find(comboId)    
        self:PlayFurnitureComboUpLevel(tile, comboCell)
    elseif from ~= nil and to == nil then
        local fromComboId = lvCell:FurnitureCombinations(from)
        local fromComboCell = ConfigRefer.CityFurnitureCombination:Find(fromComboId)
        self:PlayFurnitureComboDownLevel(tile, fromComboCell, nil)
    elseif from < to then
        local comboId = lvCell:FurnitureCombinations(to)
        local comboCell = ConfigRefer.CityFurnitureCombination:Find(comboId)    
        self:PlayFurnitureComboUpLevel(tile, comboCell)
    elseif from > to then
        local comboId = lvCell:FurnitureCombinations(to)
        local comboCell = ConfigRefer.CityFurnitureCombination:Find(comboId)
        local fromComboId = lvCell:FurnitureCombinations(from)
        local fromComboCell = ConfigRefer.CityFurnitureCombination:Find(fromComboId)
        self:PlayFurnitureComboDownLevel(tile, fromComboCell, comboCell)
    end
end

---@param tile CityCellTile
---@param combo CityFurnitureCombinationConfigCell
function CityFurnitureComboManager:PlayFurnitureComboUpLevel(tile, combo)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_EDIT_MODE_PLAY_COMBO_LEVEL_UP, tile, combo)
end

---@param tile CityCellTile
---@param fromCombo CityFurnitureCombinationConfigCell
---@param toCombo CityFurnitureCombinationConfigCell|nil
function CityFurnitureComboManager:PlayFurnitureComboDownLevel(tile, fromCombo, toCombo)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_EDIT_MODE_PLAY_COMBO_LEVEL_DOWN, tile, fromCombo, toCombo)
end

return CityFurnitureComboManager