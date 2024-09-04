local TileType = require('TileType')
local DBEntityType = require('DBEntityType')

local LuaTileView = CS.Grid.LuaTileView
local DecorationTileView = CS.Grid.DecorationTileView
local GameObjectTileView = CS.Grid.GameObjectTileView

---@class PvPTileViewFactory
local PvPTileViewFactory = class('PvPTileViewFactory')

local LuaTileTypeToViewMap =
{
    --Special Decoration
    [TileType.Bridge] = require('PvPTileViewBridge'),
    [TileType.Slope] = require('PvPTileViewSlope'),
    [TileType.Gate] = require('PvPTileViewGateDecoration'),

    --Unit
    [DBEntityType.CastleBrief] = require('PvPTileViewCity'),
    [DBEntityType.ResourceField] = require('PvPTileViewResourceField'),
    [DBEntityType.Village] = require('PvPTileViewVillage'),
    [DBEntityType.EnergyTower] = require('PvPTileViewEnergyTower'),
    [DBEntityType.TransferTower] = require('PvPTileViewTransferTower'),
    [DBEntityType.DefenceTower] = require('PvPTileViewDefenceTower'),
    [DBEntityType.MobileFortress] = require('PvPTileViewMobileFortress'),
    [DBEntityType.Expedition] = require('PvETileViewWorldEvent'),
    [DBEntityType.SlgInteractor] = require('PvETileViewSlgInteractor'),
    [DBEntityType.Pass] = require('PvPTileViewGate'),
    [DBEntityType.CommonMapBuilding] = require('PvPTileViewCommonMapBuilding'),
    [DBEntityType.BehemothCage] = require('PvPTileViewBehemothCage'),
    [DBEntityType.SlgCreepTumor] = require('PvETileViewCreepCenter'),

    --PlayerUnit
    --[wds.PlayerMapCreep.TypeHash] = require('PlayerTileViewCreepTumor'),
    [wds.SeEnter.TypeHash] = require('PlayerTileViewSlgInteractor'),
    [wds.PlayerRtBox.TypeHash] = require("PlayerTileViewWorldReward"),
    [wds.PetWildInfo.TypeHash] = require("PlayerTileViewPet"),

}

local DecorationTypes =
{
    TileType.Tree,
    TileType.Grass,
    TileType.Mountain,
    TileType.Symbols,
}

local ActorTypes =
{
    TileType.Actor,
}

function PvPTileViewFactory:GetDecorationTypes()
    return DecorationTypes
end

function PvPTileViewFactory:GetActorTypes()
    return ActorTypes
end

function PvPTileViewFactory:Create(type)
    --空地块不创建View，从而节省性能
    if type == TileType.None then
        return nil
    end

    local luaClass = LuaTileTypeToViewMap[type]
    if luaClass then
        return LuaTileView(luaClass.new())
    end

    return nil
end

return PvPTileViewFactory
