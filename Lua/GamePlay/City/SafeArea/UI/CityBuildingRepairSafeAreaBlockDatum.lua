local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local InventoryUIHelper = require("InventoryUIHelper")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local UIMediatorNames = require("UIMediatorNames")
local DBEntityPath = require("DBEntityPath")
local CityRepairSafeAreaBlock = require("CityRepairSafeAreaBlock")

local CityBuildingRepairBlockDatum = require("CityBuildingRepairBlockDatum")

---@class CityBuildingRepairSafeAreaBlockDatum:CityBuildingRepairBlockDatum
---@field new fun():CityBuildingRepairSafeAreaBlockDatum
---@field super CityBuildingRepairBlockDatum
local CityBuildingRepairSafeAreaBlockDatum = class('CityBuildingRepairSafeAreaBlockDatum', CityBuildingRepairBlockDatum)

function CityBuildingRepairSafeAreaBlockDatum:ctor()
    ---@type number
    self._wallId = nil
    ---@type City
    self._city = nil
    ---@type CitySafeAreaWallManager
    self._wallMgr = nil
    ---@type CitySafeAreaWallConfigCell
    self._config = nil
    ---@type CityRepairSafeAreaBlock
    self._repairBlock = nil
    ---@type number
    self._repairCostBits = nil
end

---@param city City
---@param wallId number
function CityBuildingRepairSafeAreaBlockDatum:Setup(city, wallId)
    self._city = city
    self._wallId = wallId
    self._wallMgr = city.safeAreaWallMgr
    self._config = ConfigRefer.CitySafeAreaWall:Find(self._wallId)
    self._repairBlock = CityRepairSafeAreaBlock.new()
    self._repairBlock:Setup(self._city, self._wallId)
    self._repairCostBits = 0--self._city:GetCastle().RepairingSafeWalls[self._wallId] or 0
    return self
end

function CityBuildingRepairSafeAreaBlockDatum:RequestCost(itemId)
    local itemGroup = ConfigRefer.ItemGroup:Find(self._config:Cost())
    for i = 1, itemGroup:ItemGroupInfoListLength() do
        local info = itemGroup:ItemGroupInfoList(i)
        if info:Items() == itemId then
            ModuleRefer.CitySafeAreaModule:RequestAddMatToRepairWall(self._wallId, i -1)
            return true
        end
    end
    return false
end

function CityBuildingRepairSafeAreaBlockDatum:GetCostItemIconData()
    local ret = {}
    local itemGroup = ConfigRefer.ItemGroup:Find(self._config:Cost())
    if not itemGroup then
        return ret
    end
    local costBit = self._repairCostBits
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
function CityBuildingRepairSafeAreaBlockDatum:GetBubbleNeedData()
    local ret = {}
    local itemGroup = ConfigRefer.ItemGroup:Find(self._config:Cost())
    if not itemGroup then return ret end

    local costBit = self._repairCostBits
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

function CityBuildingRepairSafeAreaBlockDatum:GetRepairBlock()
    return self._repairBlock
end

function CityBuildingRepairSafeAreaBlockDatum:AddEventListener()
    g_Game.EventManager:AddListener(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnWallStatusChanged))
    --g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.RepairingSafeWalls.MsgPath, Delegate.GetOrCreate(self, self.OnRepairSafeAreaWallStatusChanged))
end

function CityBuildingRepairSafeAreaBlockDatum:RemoveEventListener()
    --g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.RepairingSafeWalls.MsgPath, Delegate.GetOrCreate(self, self.OnRepairSafeAreaWallStatusChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SAFE_AREA_WALL_STATUS_REFRESH, Delegate.GetOrCreate(self, self.OnWallStatusChanged))
end

---@param castleBriefId number
function CityBuildingRepairSafeAreaBlockDatum:OnWallStatusChanged(castleBriefId)
    if not self._city or self._city.uid ~= castleBriefId then
        return
    end
    local status = ModuleRefer.CitySafeAreaModule:GetWallStatus(self._wallId)
    if status ~= 0 then
        return
    end
    g_Game.UIManager:UIMediatorCloseSelfByName(UIMediatorNames.CityBuildingRepairBlockBaseUIMediator)
end

---@param entity wds.CastleBrief
function CityBuildingRepairSafeAreaBlockDatum:OnRepairSafeAreaWallStatusChanged(entity, _)
    if not self._city or self._city.uid ~= entity.ID then
        return
    end
    self._repairCostBits = 0 --self._city:GetCastle().RepairingSafeWalls[self._wallId] or 0
end

function CityBuildingRepairSafeAreaBlockDatum:TriggerFlashEvent(flag)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_SAFE_AREA_WALL_OR_DOOR_SELECT_FILLED, self._city.uid, self._wallId, flag)
end

return CityBuildingRepairSafeAreaBlockDatum