local CityTileAssetBubble = require("CityTileAssetBubble")
---@class CityTileAssetGroupMemberBubble:CityTileAssetBubble, ICityTileAssetGroupMember
---@field new fun():CityTileAssetGroupMemberBubble
local CityTileAssetGroupMemberBubble = class("CityTileAssetGroupMemberBubble", CityTileAssetBubble)

---@param group CityTileAssetGroup
function CityTileAssetGroupMemberBubble:ctor(group)
    CityTileAssetBubble.ctor(self)
    self.parent = group
end

---@return string @返回一个Group内的唯一名, 用于ForceRefresh时刷新判断是否是同一对象
function CityTileAssetGroupMemberBubble:GetCustomNameInGroup()
    ---must override
    return string.Empty
end

return CityTileAssetGroupMemberBubble