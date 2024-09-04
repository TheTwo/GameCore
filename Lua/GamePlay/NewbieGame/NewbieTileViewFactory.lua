local TileType = require('TileType')
local DBEntityType = require('DBEntityType')

local LuaTileView = CS.Grid.LuaTileView
local DecorationTileView = CS.Grid.DecorationTileView

---@class NewbieTileViewFactory
local NewbieTileViewFactory = class('NewbieTileViewFactory')

local LuaTileTypeToViewMap =
{
    [DBEntityType.FakeCastle] = require('NewbieTileViewCity'),
    [DBEntityType.Expedition] = require('PvETileViewWorldEvent'),
    [DBEntityType.SlgInteractor] = require('NewbieTileViewSlgInteractor'),
}

local CSTileTypeToViewMap =
{
    [TileType.Tree] = DecorationTileView,
    [TileType.Mountain] = DecorationTileView,
}

function NewbieTileViewFactory:Create(type)
    --空地块不创建View，从而节省性能
    if type == TileType.None then
        return nil
    end

    if DBEntityType.FakeCastle == type then
        local i = 0
    end

    local luaClass = LuaTileTypeToViewMap[type]
    if luaClass then
        return LuaTileView(luaClass.new())
    end

    local csClass = CSTileTypeToViewMap[type]
    if csClass then
        return csClass()
    end

    return nil
end

return NewbieTileViewFactory