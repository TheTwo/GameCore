--[[
    bit描述地块的属性
]]--

---@class CityGridLayerMask
local CityGridLayerMask = {
    None = 0x00,                    ----0
    Furniture = 0x01,               ----1
    Building = 0x02,                ----2
    Npc = 0x04,                     ----4
    Resource = 0x08,                ----8
    Creep = 0x10,                   ----16
    SafeArea = 0x20,                ----32
    SafeAreaWall = 0x40,            ----64
    GeneratingRes = 0x80,           ----128
    LegoBase = 0x100,               ----256
    LegoBuilding = 0x200,           ----512
}

CityGridLayerMask.CellTileWithoutNpcFlag = CityGridLayerMask.Building | CityGridLayerMask.Resource | CityGridLayerMask.Creep
CityGridLayerMask.CellTileFlag = CityGridLayerMask.Building | CityGridLayerMask.Npc | CityGridLayerMask.Resource | CityGridLayerMask.Creep
CityGridLayerMask.PlacedFlag = CityGridLayerMask.Furniture | CityGridLayerMask.CellTileFlag | CityGridLayerMask.SafeAreaWall | CityGridLayerMask.GeneratingRes | CityGridLayerMask.LegoBuilding
CityGridLayerMask.PlacedWithoutLegoFlag = CityGridLayerMask.Furniture | CityGridLayerMask.CellTileFlag | CityGridLayerMask.SafeAreaWall | CityGridLayerMask.GeneratingRes
CityGridLayerMask.PlacedWithoutLegoFlagAndGeneratingRes = CityGridLayerMask.Furniture | CityGridLayerMask.CellTileFlag | CityGridLayerMask.SafeAreaWall

function CityGridLayerMask.HasBuilding(mask)
    return mask & CityGridLayerMask.Building ~= 0
end

function CityGridLayerMask.HasFurniture(mask)
    return mask & CityGridLayerMask.Furniture ~= 0
end

function CityGridLayerMask.HasNpc(mask)
    return mask & CityGridLayerMask.Npc ~= 0
end

function CityGridLayerMask.HasResource(mask)
    return mask & CityGridLayerMask.Resource ~= 0
end

function CityGridLayerMask.HasCreepNode(mask)
    return mask & CityGridLayerMask.Creep ~= 0
end

function CityGridLayerMask.IsPlaced(mask)
    return mask & CityGridLayerMask.PlacedFlag ~= 0
end

function CityGridLayerMask.IsPlacedExceptLego(mask)
    return mask & CityGridLayerMask.PlacedWithoutLegoFlag ~= 0
end

function CityGridLayerMask.IsPlacedWithoutLegoFlagAndGeneratingRes(mask)
    return mask & CityGridLayerMask.PlacedWithoutLegoFlagAndGeneratingRes ~= 0
end

function CityGridLayerMask.IsPlacedCellTile(mask)
    return mask & CityGridLayerMask.CellTileFlag ~= 0
end

function CityGridLayerMask.IsPlacedCellTileWithoutNpc(mask)
    return mask & CityGridLayerMask.CellTileWithoutNpcFlag ~= 0
end

function CityGridLayerMask.IsSafeArea(mask)
    return mask & CityGridLayerMask.SafeArea ~= 0
end

function CityGridLayerMask.IsSafeAreaWall(mask)
    return mask & CityGridLayerMask.SafeAreaWall ~= 0
end

function CityGridLayerMask.IsGeneratingRes(mask)
    return mask & CityGridLayerMask.GeneratingRes ~= 0
end

function CityGridLayerMask.IsInLego(mask)
    return mask & CityGridLayerMask.LegoBase ~= 0
end

function CityGridLayerMask.CanPlaceFurniture(mask)
    if CityGridLayerMask.IsPlacedExceptLego(mask) then
        return false
    end

    if CityGridLayerMask.LegoBuilding & mask ~= 0 then
        return CityGridLayerMask.LegoBase & mask ~= 0
    end

    return true
end

return CityGridLayerMask
