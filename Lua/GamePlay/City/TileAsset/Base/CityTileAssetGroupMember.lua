local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetGroupMember:CityTileAsset,ICityTileAssetGroupMember
---@field new fun():CityTileAssetGroupMember
local CityTileAssetGroupMember = class("CityTileAssetGroupMember", CityTileAsset)

---@param group CityTileAssetGroup
function CityTileAssetGroupMember:ctor(group)
    CityTileAsset.ctor(self)
    self.parent = group
end

---@return string @返回一个Group内的唯一名, 用于ForceRefresh时刷新判断是否是同一对象
function CityTileAssetGroupMember:GetCustomNameInGroup()
    ---must override
    return string.Empty
end

return CityTileAssetGroupMember