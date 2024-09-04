local CityTileAssetGroup = require("CityTileAssetGroup")
---@class CityTileAssetRepairBlockGroup:CityTileAssetGroup
---@field new fun(id:number, repairBlock:CityBuildingRepairBlock):CityTileAssetRepairBlockGroup
local CityTileAssetRepairBlockGroup = class("CityTileAssetRepairBlockGroup", CityTileAssetGroup)
local CityTileAssetRepairBlockBase = require("CityTileAssetRepairBlockBase")
local CityTileAssetRepairBlockWall = require("CityTileAssetRepairBlockWall")
local CityTileAssetRepairBlockBaseBubble = require("CityTileAssetRepairBlockBaseBubble")
local CityTileAssetRepairBlockWallBubble = require("CityTileAssetRepairBlockWallBubble")
local CityTileAssetRepairBlockPollutedPlus = require("CityTileAssetRepairBlockPollutedPlus")
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")

---@param repairBlock CityBuildingRepairBlock
function CityTileAssetRepairBlockGroup:ctor(id, repairBlock)
    CityTileAssetGroup.ctor(self)
    self.id = id
    self.repairBlock = repairBlock
end

function CityTileAssetRepairBlockGroup:GetCustomNameInGroup()
    return tostring(self.id)
end

function CityTileAssetRepairBlockGroup:GetCurrentMembers()
    local ret = {}
    local base = CityTileAssetRepairBlockBase.new(self, self.repairBlock)
    table.insert(ret, base)

    if not self.repairBlock:IsBaseRepaired() then
        table.insert(ret, CityTileAssetRepairBlockBaseBubble.new(self, self.repairBlock))
    end

    if self.repairBlock.cfg:ModelPollutedPlus() > 0 then
        table.insert(ret, CityTileAssetRepairBlockPollutedPlus.new(self, self.repairBlock))
    end

    for i = 1, self.repairBlock.cfg:RepairWallsLength() do
        local isFixed = self.repairBlock:IsWallRepaired(i)
        local wall = CityTileAssetRepairBlockWall.new(self, self.repairBlock, i)
        table.insert(ret, wall)

        if self.repairBlock:IsBaseRepaired() and not isFixed then
            table.insert(ret, CityTileAssetRepairBlockWallBubble.new(self, self.repairBlock, i))
        end
    end
    return ret
end

return CityTileAssetRepairBlockGroup