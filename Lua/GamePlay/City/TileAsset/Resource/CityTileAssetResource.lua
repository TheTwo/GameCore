local Utils = require("Utils")
local CityTrigger = require("CityTrigger")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local TimerUtility = require("TimerUtility")
local ArtResourceUtils = require("ArtResourceUtils")

local CityTileAssetPolluted = require("CityTileAssetPolluted")
---@class CityTileAssetResource:CityTileAssetPolluted
---@field new fun():CityTileAssetResource
---@field super CityTileAssetPolluted
local CityTileAssetResource = class("CityTileAssetResource", CityTileAssetPolluted)
local ConfigRefer = require("ConfigRefer")
local HitAnimNameHash = CS.UnityEngine.Animator.StringToHash("hit")

function CityTileAssetResource:ctor()
    CityTileAssetPolluted.ctor(self)
    self.allowSelected = true
    self.mayHideInExplore = false
    ---@type Timer
    self.delayCheckPollutedTimer = nil
end

function CityTileAssetResource:GetPrefabName()
    local cell = self.tileView.tile:GetCell()
    if cell == nil then
        g_Logger.Error("fatal error")
        return string.Empty
    end

    self.elementScale, self.elementYaw = 1, 0
    if cell.configId > 0 then
        local element = ConfigRefer.CityElementData:Find(cell.configId)
        if element == nil then
            g_Logger.Error(("Can't find config row id : %d in CityElementData"):format(cell.configId))
            return string.Empty
        end
        self.elementScale = element:Scale()
        self.elementYaw = element:Yaw()
    end

    local city = self:GetCity()
    if self.mayHideInExplore then
        if not self.tileView.tile:IsPolluted() and (city:IsInSingleSeExplorerMode() or city:IsInRecoverZoneEffectMode()) then
            return string.Empty
        end
    end
    ---@type CityElementResource
    local resource = city.elementManager:GetElementById(cell.tileId)
    if resource == nil then
        return string.Empty
    end
    local cfg = resource.resourceConfigCell
    local mdlId = cfg:Model()
    local elementDB = city:GetCastle().CastleElements.PollutedElements
    if elementDB[cell.configId] and cfg:PollutedModel() > 0 then
        mdlId = cfg:PollutedModel()
    end

    self.customScale = ArtResourceUtils.GetItem(mdlId, "ModelScale")
    return ArtResourceUtils.GetItem(mdlId)
end

function CityTileAssetResource:OnAssetLoaded(go, userdata)
    CityTileAssetPolluted.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then return end

    local city = self:GetCity()
    local tile = self.tileView.tile
    local legoBuilding = self.tileView.tile:GetLegoBuilding()
    if legoBuilding then
        go.transform.position = city:GetCenterWorldPositionFromCoord(tile.x, tile.y, tile:SizeX(), tile:SizeY()) + legoBuilding:GetBaseOffset()
    else
        go.transform.position = city:GetCenterWorldPositionFromCoord(tile.x, tile.y, tile:SizeX(), tile:SizeY())
    end

    self:ApplyRotation(go.transform, self.elementYaw or 0)
    local collider = go:GetComponentInChildren(typeof(CS.UnityEngine.Collider))
    if Utils.IsNotNull(collider) then
        local trigger = go:AddMissingLuaBehaviour("CityTrigger")
        trigger.Instance:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickTrigger), self.tileView.tile, false)
        self.cityTrigger = trigger.Instance
    end
    
    if city:IsMyCity() then
        city.elementResourceVfxPlayManager:RegisterGameObj(go, self.tileView.tile)
    end

    ---@type CS.UnityEngine.Animator
    self._animator = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator))
end

function CityTileAssetResource:OnAssetUnload(go, fade)
    if self.delayCheckPollutedTimer then
        local timer = self.delayCheckPollutedTimer
        self.delayCheckPollutedTimer = nil
        TimerUtility.StopAndRecycle(timer)
    end
    local city = self:GetCity()
    if city:IsMyCity() then
        city.elementResourceVfxPlayManager:UnregisterGameObj(go)
    end

    self:ApplyRotation(go.transform, 0)
    if self.cityTrigger then
        self.cityTrigger:SetOnTrigger(nil, nil, false)
        self.cityTrigger = nil
    end
    self.customScale = nil
    self.elementScale = nil
    self._animator = nil
    CityTileAssetPolluted.OnAssetUnload(self, go, fade)
end

---@param trans CS.UnityEngine.Transform
function CityTileAssetResource:ApplyRotation(trans, yaw)
    trans.localRotation = CS.UnityEngine.Quaternion.Euler(0, yaw, 0)
end

function CityTileAssetResource:GetScale()
    local scale = 1
    if self.customScale ~= nil and self.customScale ~= 0 then
        scale = scale * math.max(0.01, self.customScale)
    end
    if self.elementScale ~= nil and self.elementScale ~= 0 then
        scale = scale * math.max(0.01, self.elementScale)
    end
    return scale
end

function CityTileAssetResource:OnClickTrigger(trigger)
    if not self.tileView then return false end
    if not self.tileView.tile then return false end
    if self.tileView.tile:IsFogMask() then return false end
    local cell = self.tileView.tile:GetCell()
    if not cell then return false end
    -- g_Game.EventManager:TriggerEvent(EventConst.CITY_CLICK_RESOURCE, self:GetCity(), cell.tileId)
    --self:AutoEndSelect(3)
    self:OnClickCellTile(trigger)
    return true
end

function CityTileAssetResource:AutoEndSelect(delay) 
    self:SetSelected(true)
    TimerUtility.DelayExecute(function()
        self:SetSelected(false)
    end, delay)
end

function CityTileAssetResource:OnTileViewInit()
    CityTileAssetResource.super.OnTileViewInit(self)
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExit))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_RESOURCE_BE_HIT, Delegate.GetOrCreate(self, self.OnResourceBeHit))
    g_Game.EventManager:AddListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.CheckNeedHideInExplore))
    local cell = self.tileView.tile:GetCell()
    local city = self.tileView.tile:GetCity()
    local res = city.elementManager:GetElementById(cell.tileId)
    if res and res.resourceConfigCell then
        self.mayHideInExplore = res.resourceConfigCell:LinkSeMine() ~= 0
    else
        self.mayHideInExplore = false
    end
end

function CityTileAssetResource:OnTileViewRelease()
    CityTileAssetResource.super.OnTileViewRelease(self)
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExit))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_RESOURCE_BE_HIT, Delegate.GetOrCreate(self, self.OnResourceBeHit))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BUBBLE_STATE_CHANGE, Delegate.GetOrCreate(self, self.CheckNeedHideInExplore))
end

function CityTileAssetResource:IsMine(id)
    local cell = self.tileView.tile:GetCell()
    return cell.tileId == id
end

function CityTileAssetResource:IsPolluted()
    local cell = self.tileView.tile:GetCell()
    if cell == nil then return false end
    return self:GetCity().elementManager:IsPolluted(cell.tileId)
end

function CityTileAssetResource:OnResourceBeHit(elementId)
    if not self:IsMine(elementId) then return end
    if Utils.IsNull(self._animator) then return end

    return self._animator:Play(HitAnimNameHash)
end

function CityTileAssetResource:CheckNeedHideInExplore()
    if not self.mayHideInExplore then return end
    self:ForceRefresh()
end

function CityTileAssetResource:OnOnPollutedExitEnd(fadeDuration)
    local timer = self.delayCheckPollutedTimer
    self.delayCheckPollutedTimer = nil
    if timer then
        TimerUtility.StopAndRecycle(timer)
    end
    self.delayCheckPollutedTimer = TimerUtility.DelayExecute(Delegate.GetOrCreate(self, self.Refresh), fadeDuration, true)
end

return CityTileAssetResource