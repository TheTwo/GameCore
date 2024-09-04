
---@class CityRepairBlockBase
---@field GetCity fun(self:CityRepairBlockBase):City|MyCity
---@field Contains fun(self:CityRepairBlockBase,x:number,y:number):boolean

---@class CityBuildingRepairBlock:CityRepairBlockBase
---@field new fun(building:CityBuilding, cfgId:number, info:wds.BuidingBlockRepairInfo):CityBuildingRepairBlock
local CityBuildingRepairBlock = sealedClass("CityBuildingRepairBlock")
local ConfigRefer = require("ConfigRefer")
local InventoryUIHelper = require("InventoryUIHelper")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")

---@param building CityBuilding
---@param cfgId number
---@param info wds.BuildingBlockRepairInfo
function CityBuildingRepairBlock:ctor(building, cfgId, info)
    self.building = building
    self.id = cfgId
    self.info = info

    local cfg = ConfigRefer.BuildingBlock:Find(self.id)
    self.x, self.y = building.x + cfg:X(), building.y + cfg:Y()
    self.sizeX, self.sizeY = cfg:SizeX(), cfg:SizeY()
    self.cfg = cfg

    self.baseRepaired = self:IsBaseRepaired()
    self.wallRepaired = {}
    for i = 1, self.info.WallRepairCostBits:Count() do
        self.wallRepaired[i] = self:IsWallRepaired(i)
    end
end

function CityBuildingRepairBlock:GetCity()
    return self.building.mgr.city
end

---@param info wds.BuidingBlockRepairInfo
function CityBuildingRepairBlock:UpdateInfo(info)
    self.info = info

    local baseRepaired = self:IsBaseRepaired()
    if baseRepaired ~= self.baseRepaired then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_BASE_REPAIR_FINISH, self)
    end
    self.baseRepaired = baseRepaired

    for i = 1, self.info.WallRepairCostBits:Count() do
        local wallFinished = self:IsWallRepaired(i)
        if wallFinished ~= self.wallRepaired[i] then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_REPAIR_BLOCK_WALL_REPAIR_FINISH, self, i)
        end
        self.wallRepaired[i] = wallFinished
    end
end

function CityBuildingRepairBlock:Contains(x, y)
    return self.x <= x and x < self.x + self.sizeX and self.y <= y and y < self.y + self.sizeY
end

function CityBuildingRepairBlock:IsValid()
    return self.building:GetRepairBlockByCfgId(self.cfg:Id()) == self
end

function CityBuildingRepairBlock:IsPolluted()
    return self.building:IsPolluted()
end

function CityBuildingRepairBlock:IsBaseRepaired()
    return self.info.BaseRepaired
end

function CityBuildingRepairBlock:IsWallRepaired(wallIdx)
    return (self.info.WallRepairProgress & (1 << (wallIdx - 1))) > 0
end

---@return ItemIconData[] 只显示当前仍然需要的
function CityBuildingRepairBlock:GetRepairBaseCostItemIconData()
    local ret = {}
    local itemGroup = ConfigRefer.ItemGroup:Find(self.cfg:BaseRepairCost())
    if not itemGroup then return ret end

    local costBit = self.info.BaseRepairCostBits
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        if (costBit & (1 << (i - 1))) == 0 then
            local data = InventoryUIHelper.GetItemIconDataFromItemGroupInfo(itemGroup:ItemGroupInfoList(i), true)
            data.hideBtnDelete = true
            data.showTips = false
            data.costCount = data.addCount
            data.customTopStr = "-" .. data.costCount
            data.addCount = nil
            table.insert(ret, data)
        end
    end
    return ret
end

---@return {icon:string, text:string, showCheck:boolean}[]
function CityBuildingRepairBlock:GetRepairBaseBubbleNeedData()
    local ret = {}
    local itemGroup = ConfigRefer.ItemGroup:Find(self.cfg:BaseRepairCost())
    if not itemGroup then return ret end

    local costBit = self.info.BaseRepairCostBits
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        local info = itemGroup:ItemGroupInfoList(i)
        local itemCfg = ConfigRefer.Item:Find(info:Items())
        local showCheck = (costBit & (1 << (i - 1))) ~= 0
        local text = showCheck and string.Empty or ("%d/%d"):format(0, info:Nums())
        local datum = {icon = itemCfg:Icon(), text = text, showCheck = showCheck}
        table.insert(ret, datum)
    end
    return ret
end

function CityBuildingRepairBlock:IsLastBaseRepairCost()
    local itemGroup = ConfigRefer.ItemGroup:Find(self.cfg:BaseRepairCost())
    if not itemGroup then return false end
    local costBit = self.info.BaseRepairCostBits
    local remainType = 0
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        if (costBit & (1 << i - 1)) == 0 then
            remainType = remainType + 1
        end
    end
    return remainType == 1
end

function CityBuildingRepairBlock:GetRepairWallCostItemIconData(wallIdx)
    local ret = {}
    if wallIdx <= 0 or wallIdx > self.cfg:RepairWallsLength() then
        return ret
    end
    local wallInfo = self.cfg:RepairWalls(wallIdx)
    local itemGroup = ConfigRefer.ItemGroup:Find(wallInfo:Cost())
    if not itemGroup then return ret end

    local costBit = self.info.WallRepairCostBits[wallIdx]
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        if (costBit & (1 << (i - 1))) == 0 then
            local data = InventoryUIHelper.GetItemIconDataFromItemGroupInfo(itemGroup:ItemGroupInfoList(i), true)
            data.hideBtnDelete = true
            data.showTips = false
            data.costCount = data.addCount
            data.customTopStr = "-" .. data.costCount
            data.addCount = nil
            table.insert(ret, data)
        end
    end
    return ret
end

---@return {icon:string, text:string, showCheck:boolean}[]
function CityBuildingRepairBlock:GetRepairWallBubbleNeedData(wallIdx)
    local ret = {}
    if wallIdx <= 0 or wallIdx > self.cfg:RepairWallsLength() then
        return ret
    end
    local wallInfo = self.cfg:RepairWalls(wallIdx)
    local itemGroup = ConfigRefer.ItemGroup:Find(wallInfo:Cost())
    if not itemGroup then return ret end

    local costBit = self.info.WallRepairCostBits[wallIdx]
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        local info = itemGroup:ItemGroupInfoList(i)
        local itemCfg = ConfigRefer.Item:Find(info:Items())
        local showCheck = (costBit & (1 << (i - 1))) ~= 0
        local text = showCheck and string.Empty or ("%d/%d"):format(0, info:Nums())
        local datum = {icon = itemCfg:Icon(), text = text, showCheck = showCheck}
        table.insert(ret, datum)
    end
    return ret
end


function CityBuildingRepairBlock:IsLastWallRepairCost(wallIdx)
    if wallIdx <= 0 or wallIdx > self.cfg:RepairWallsLength() then
        return false
    end

    local wallInfo = self.cfg:RepairWalls(wallIdx)
    local itemGroup = ConfigRefer.ItemGroup:Find(wallInfo:Cost())
    if not itemGroup then return false end

    local costBit = self.info.WallRepairCostBits[wallIdx]
    local remainType = 0
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        if (costBit & (1 << i - 1)) == 0 then
            remainType = remainType + 1
        end
    end
    return remainType == 1
end

function CityBuildingRepairBlock:IsBaseRepairCostEnough()
    local itemGroup = ConfigRefer.ItemGroup:Find(self.cfg:BaseRepairCost())
    if not itemGroup then return false end
    local costBit = self.info.BaseRepairCostBits
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        if (costBit & (1 << i - 1)) == 0 then
            local info = itemGroup:ItemGroupInfoList(i)
            if ModuleRefer.InventoryModule:GetAmountByConfigId(info:Items()) < info:Nums() then
                return false
            end
        end
    end
    return true
end

function CityBuildingRepairBlock:IsWallRepairCostEnough(wallIdx)
    local itemGroup = ConfigRefer.ItemGroup:Find(self.cfg:RepairWalls(wallIdx):Cost())
    if not itemGroup then return false end
    local costBit = self.info.WallRepairCostBits[wallIdx]
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        if (costBit & (1 << i - 1)) == 0 then
            local info = itemGroup:ItemGroupInfoList(i)
            if ModuleRefer.InventoryModule:GetAmountByConfigId(info:Items()) < info:Nums() then
                return false
            end
        end
    end
    return true
end

return CityBuildingRepairBlock