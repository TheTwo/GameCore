local CityTileAssetGroupMember = require("CityTileAssetGroupMember")
---@class CityTileAssetPollutedGroupMember:CityTileAssetGroupMember
---@field new fun():CityTileAssetPollutedGroupMember
local CityTileAssetPollutedGroupMember = class("CityTileAssetPollutedGroupMember", CityTileAssetGroupMember)
local Utils = require("Utils")

function CityTileAssetPollutedGroupMember:OnAssetLoaded(go, userdata)
    if Utils.IsNull(go) then return end
    self.go = go
    if self:IsPolluted() then
        CS.CityMatTransitionController.KeepPolluted(go)
    end
end

function CityTileAssetPollutedGroupMember:OnAssetUnload()
    CS.CityMatTransitionController.Clear(self.go)
    self.go = nil
end

function CityTileAssetPollutedGroupMember:IsPolluted()
    return false
end

function CityTileAssetPollutedGroupMember:IsMine(...)
    return false
end

function CityTileAssetPollutedGroupMember:OnPollutedEnter(...)
    if not self:IsMine(...) then return end
    if Utils.IsNull(self.go) then return end
    
    CS.CityMatTransitionController.PlayTransitionIn(self.go, 1)
end

function CityTileAssetPollutedGroupMember:OnPollutedExited(...)
    if not self:IsMine(...) then return end
    if Utils.IsNull(self.go) then return end
    
    CS.CityMatTransitionController.PlayTransitionOut(self.go, 1)
end

return CityTileAssetPollutedGroupMember