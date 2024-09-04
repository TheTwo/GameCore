local CityTileAsset = require("CityTileAsset")
---@class CityTileAssetNpcPollutedPlus:CityTileAsset
---@field new fun():CityTileAssetNpcPollutedPlus
local CityTileAssetNpcPollutedPlus = class("CityTileAssetNpcPollutedPlus", CityTileAsset)
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local Quaternion = CS.UnityEngine.Quaternion
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")

function CityTileAssetNpcPollutedPlus:ctor()
    CityTileAsset.ctor(self)
    self.duration = 2
end

function CityTileAssetNpcPollutedPlus:GetPrefabName()
    if self:IsPolluted() then
        local cell = self.tileView.tile:GetCell()
        local elementCfg = ConfigRefer.CityElementData:Find(cell.configId)
        local npcCfg = ConfigRefer.CityElementNpc:Find(elementCfg:ElementId())
        if npcCfg:PollutedPlusModel() > 0 then
            self.scale = ArtResourceUtils.GetItem(npcCfg:PollutedPlusModel(), "ModelScale")
            self.pollutedDeadAnim = npcCfg:PollutedPlusModelDeadAnim()
            self.pollutedInteractAnim = npcCfg:PollutedPlusModelInteractAnim()
            return ArtResourceUtils.GetItem(npcCfg:PollutedPlusModel())
        else
            return string.Empty
        end
    end
    return string.Empty
end

function CityTileAssetNpcPollutedPlus:OnAssetLoaded(go, userdata)
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
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, Delegate.GetOrCreate(self, self.OnNpcClicked))
end

function CityTileAssetNpcPollutedPlus:OnAssetUnload()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, Delegate.GetOrCreate(self, self.OnNpcClicked))
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

function CityTileAssetNpcPollutedPlus:GetScale()
    if self.scale == nil or self.scale == 0 then return 1 end
    return self.scale
end

function CityTileAssetNpcPollutedPlus:CheckUseCustomFadeOut()
    self.useCustomFadeOut = false
    if Utils.IsNull(self.animation) then return end
    if string.IsNullOrEmpty(self.pollutedDeadAnim) then return end
    
    local clip = self.animation:GetClip(self.pollutedDeadAnim)
    if Utils.IsNull(clip) then return end

    self.customFadeOutLength = clip.length
    self.useCustomFadeOut = true
end

function CityTileAssetNpcPollutedPlus:CheckUseInteractAnim()
    self.useInteractAnim = false
    if Utils.IsNull(self.animation) then return end
    if string.IsNullOrEmpty(self.pollutedInteractAnim) then return end

    local clip = self.animation:GetClip(self.pollutedInteractAnim)
    if Utils.IsNull(clip) then return end
    
    self.interactAnimLength = clip.length
    self.useInteractAnim = true
end

function CityTileAssetNpcPollutedPlus:IsPolluted()
    local cell = self.tileView.tile:GetCell()
    if cell == nil then return false end
    local elementCfg = ConfigRefer.CityElementData:Find(cell.configId)
    local npcCfg = ConfigRefer.CityElementNpc:Find(elementCfg:ElementId())
    return npcCfg:Model() > 0 and self:GetCity().elementManager:IsPolluted(cell.tileId)
end

function CityTileAssetNpcPollutedPlus:OnTileViewInit()
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExited))
end

function CityTileAssetNpcPollutedPlus:OnTileViewRelease()
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExited))
end

function CityTileAssetNpcPollutedPlus:OnPollutedEnter(id)
    local cell = self.tileView.tile:GetCell()
    if not cell then return end
    if cell.tileId ~= id then return end
    self.pollutedEnter = true
    self:Show()
end

function CityTileAssetNpcPollutedPlus:OnPollutedExited(id)
    local cell = self.tileView.tile:GetCell()
    if not cell then return end
    if cell.tileId ~= id then return end
    if Utils.IsNull(self.go) then return end
    self.pollutedExit = true
    self:Hide()
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetNpcPollutedPlus:PollutedFadeIn(go)
    local scale = self:GetScale()
    go.transform.localScale = CS.UnityEngine.Vector3(scale, 0, scale)
    go.transform:DOScaleY(scale, self.duration)
    go.transform.localPosition = go.transform.localPosition - CS.UnityEngine.Vector3.down * 0.5
    go.transform:DOBlendableLocalMoveBy(CS.UnityEngine.Vector3.up * 0.5, self.duration)
end

---@param go CS.UnityEngine.GameObject
function CityTileAssetNpcPollutedPlus:PollutedFadeOut(go)
    go.transform.localScale = CS.UnityEngine.Vector3.one * self:GetScale()
    go.transform:DOScaleY(0, self.duration)
    go.transform:DOBlendableLocalMoveBy(CS.UnityEngine.Vector3.down * 0.5, self.duration)
end

function CityTileAssetNpcPollutedPlus:PlayCustomDeadAnim()
    self.animation:Play(self.pollutedDeadAnim)
end

function CityTileAssetNpcPollutedPlus:GetFadeOutDuration()
    if self.useCustomFadeOut then
        return self.customFadeOutLength
    end
    return self.duration
end

---@param context ClickNpcEventContext
function CityTileAssetNpcPollutedPlus:OnNpcClicked(context)
    if not self.useInteractAnim then return end
    if context == nil then return end
    if context.cityUid ~= self:GetCity().uid then return end
    if context.elementConfigID ~= self.tileView.tile:GetCell().configId then return end
    if not self.lastPlayTime or self.lastPlayTime + self.interactAnimLength < g_Game.RealTime.time then
        self.lastPlayTime = g_Game.RealTime.time
        self.animation:Play(self.pollutedInteractAnim)
    end
end

return CityTileAssetNpcPollutedPlus