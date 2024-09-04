local LayerMask = CS.UnityEngine.LayerMask

local Layers =
{
    CityStatic = LayerMask.NameToLayer("CityStatic"),
    Default = LayerMask.NameToLayer("Default"),
    Tile = LayerMask.NameToLayer("Tile"),
    Tile3D = LayerMask.NameToLayer("Tile3D"),
    Tile2D = LayerMask.NameToLayer("Tile2D"),
    Kingdom = LayerMask.NameToLayer("Kingdom"),
    MapTerrain = LayerMask.NameToLayer("MapTerrain"),
    SymbolMap = LayerMask.NameToLayer("SymbolMap"),
    MapAboveFog = LayerMask.NameToLayer("MapAboveFog"),
    Scene3DUI = LayerMask.NameToLayer("Scene3DUI"),
    MapMark = LayerMask.NameToLayer("MapMark"),
    Character = LayerMask.NameToLayer("Character"),
    Selected = LayerMask.NameToLayer("Selected"),
}

return Layers