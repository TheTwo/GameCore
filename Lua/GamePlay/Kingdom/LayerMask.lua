local LayerMask = CS.UnityEngine.LayerMask

---@class LayerMask
local LayerMask =
{
    CityStatic = LayerMask.GetMask("CityStatic"), -- Layer:CityStatic  for City terrain
    Default = LayerMask.GetMask("Default"),
    Tile = LayerMask.GetMask("Tile"),
    Tile3D = LayerMask.GetMask("Tile3D"),
    Tile2D = LayerMask.GetMask("Tile2D"),
    Kingdom = LayerMask.GetMask("Kingdom"), -- Layer:Kingdom  for soldiers
    SymbolMap = LayerMask.GetMask("SymbolMap"), -- Layer:Kingdom  for soldiers
    Scene3DUI = LayerMask.GetMask("Scene3DUI"), -- Layer:3DUI  for 3dui
    MapTerrain = LayerMask.GetMask("MapTerrain"), -- Layer:MapTerrain  for terrain prefab
    MapAboveFog = LayerMask.GetMask("MapAboveFog"), -- Layer:MapAboveFog  for objects above map fog
    SymbolMap = LayerMask.NameToLayer("SymbolMap"),
    SEFloor = LayerMask.GetMask("SE_Floor"),
}

return LayerMask