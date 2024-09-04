local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetResourcePollutedPlus:CityTileAsset
---@field new fun():CityTileAssetResourcePollutedPlus
local CityTileAssetResourcePollutedPlus = class("CityTileAssetResourcePollutedPlus", CityTileAsset)
local Quaternion = CS.UnityEngine.Quaternion
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local Utils = require("Utils")

function CityTileAssetResourcePollutedPlus:ctor()
    CityTileAsset.ctor(self)
    self.duration = 2    
end

function CityTileAssetResourcePollutedPlus:GetPrefabName()
    if self:IsPolluted() then
        local cell = self.tileView.tile:GetCell()
        local element = self:GetCity().elementManager:GetElementById(cell.tileId)
        local eleResCfg = element.resourceConfigCell
        ---TODO:
        if eleResCfg and false then

        end
    end
    return string.Empty
end

function CityTileAssetResourcePollutedPlus:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end
    
    local cell = self.tileView.tile:GetCell()
    local pos = self:GetCity():GetCenterWorldPositionFromCoord(cell.x, cell.y, cell.sizeX, cell.sizeY)
    go.transform:SetPositionAndRotation(pos, Quaternion.identity)

    self.go = go
    local animation = self.go:GetComponentInChildren(typeof(CS.UnityEngine.Animation))
    self.animation = animation
    self:CheckUseCustomFadeOut()
    if self:IsPolluted() and self.pollutedEnter then
        self.pollutedEnter = nil
        if not self.useCustomFadeOut then
            self:PollutedFadeIn(go)
        end
    end
end

function CityTileAssetResourcePollutedPlus:OnAssetUnload()
    if not self:IsPolluted() and self.pollutedExit then
        self.pollutedExit = nil
        if self.useCustomFadeOut then
            self:PlayCustomDeadAnim()
        else
            self:PollutedFadeOut(self.go)
        end
    end
    self.go = nil
    self.scale = nil
    self.pollutedDeadAnim = nil
    self.pollutedInteractAnim = nil
    self.customFadeOutLength = nil
    self.useCustomFadeOut = nil
    self.interactAnimLength = nil
    self.useInteractAnim = nil
end

function CityTileAssetResourcePollutedPlus:GetScale()
    if self.scale == nil or self.scale == 0 then return 1 end
    return self.scale
end

function CityTileAssetResourcePollutedPlus:CheckUseCustomFadeOut()
    self.useCustomFadeOut = false
    if Utils.IsNull(self.animation) then return end
    if string.IsNullOrEmpty(self.pollutedDeadAnim) then return end
    
    local clip = self.animation:GetClip(self.pollutedDeadAnim)
    if Utils.IsNull(clip) then return end

    self.customFadeOutLength = clip.length
    self.useCustomFadeOut = true
end

function CityTileAssetResourcePollutedPlus:IsPolluted()
    local cell = self.tileView.tile:GetCell()
    if cell == nil then return false end

    return self:GetCity().elementManager:IsPolluted(cell.tileId)
end

function CityTileAssetResourcePollutedPlus:OnTileViewInit()
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExited))
end

function CityTileAssetResourcePollutedPlus:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExited))
end

function CityTileAssetResourcePollutedPlus:OnPollutedEnter(id)
    local cell = self.tileView.tile:GetCell()
    if not cell then return end
    if cell.tileId ~= id then return end
    self.pollutedEnter = true
    self:Show()
end

function CityTileAssetResourcePollutedPlus:OnPollutedExited(id)
    local cell = self.tileView.tile:GetCell()
    if not cell then return end
    if cell.tileId ~= id then return end
    if Utils.IsNull(self.go) then return end
    self.pollutedExit = true
    self:Hide()
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetResourcePollutedPlus:PollutedFadeIn(go)
    local scale = self:GetScale()
    go.transform.localScale = CS.UnityEngine.Vector3(scale, 0, scale)
    go.transform:DOScaleY(scale, self.duration)
    go.transform.localPosition = go.transform.localPosition - CS.UnityEngine.Vector3.down * 0.5
    go.transform:DOBlendableLocalMoveBy(CS.UnityEngine.Vector3.up * 0.5, self.duration)
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetResourcePollutedPlus:PollutedFadeOut(go)
    go.transform.localScale = CS.UnityEngine.Vector3.one * self:GetScale()
    go.transform:DOScaleY(0, self.duration)
    go.transform:DOBlendableLocalMoveBy(CS.UnityEngine.Vector3.down * 0.5, self.duration)
end

function CityTileAssetResourcePollutedPlus:PlayCustomDeadAnim()
    self.animation:Play(self.pollutedDeadAnim)
end

function CityTileAssetResourcePollutedPlus:GetFadeOutDuration()
    if self.useCustomFadeOut then
        return self.customFadeOutLength
    end
    return self.duration
end

return CityTileAssetResourcePollutedPlus