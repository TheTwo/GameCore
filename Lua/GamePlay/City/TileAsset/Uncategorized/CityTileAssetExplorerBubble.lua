local Utils = require("Utils")
local CityTileAssetBubble = require("CityTileAssetBubble")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")

---@class CityTileAssetExplorerBubble:CityTileAssetBubble
---@field new fun():CityTileAssetExplorerBubble
---@field super CityTileAssetBubble
local CityTileAssetExplorerBubble = class('CityTileAssetExplorerBubble', CityTileAssetBubble)

function CityTileAssetExplorerBubble:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    return ArtResourceUtils.GetItem(ArtResourceConsts.city_bubble_explorer_camp_u2)
end

function CityTileAssetExplorerBubble:Refresh()
    self:Hide()
    self:Show()
end

---@param go CS.UnityEngine.GameObject
---@param userData CityGridCell
function CityTileAssetExplorerBubble:OnAssetLoaded(go, userData)
    CityTileAssetBubble.OnAssetLoaded(self, go, userData)
    if Utils.IsNull(go) then
        return
    end
    ---@type CityExplorerCampBubble
    local bubble = go:GetLuaBehaviour("CityExplorerCampBubble").Instance
    bubble:Init(userData)
end

function CityTileAssetExplorerBubble:GetPriorityInView()
    return -90
end

return CityTileAssetExplorerBubble