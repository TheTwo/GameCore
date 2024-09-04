local CityTileAssetPolluted = require("CityTileAssetPolluted")
---@class CityTileAssetFurniture:CityTileAssetPolluted
---@field new fun():CityTileAssetFurniture
---@field cityTrigger CityTrigger
---@field super CityTileAssetPolluted
local CityTileAssetFurniture = class("CityTileAssetFurniture", CityTileAssetPolluted)
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")
local EventConst = require("EventConst")
local OnChangeHelper = require("OnChangeHelper")
local CityWorkTargetType = require("CityWorkTargetType")
local CityFurnitureTypeNames = require("CityFurnitureTypeNames")
local ModuleRefer = require("ModuleRefer")

CityTileAssetFurniture.AnimatorStatus = {
    work = "work",
    work_fast = "work_fast",
    up = "up",
}

function CityTileAssetFurniture:ctor()
    CityTileAssetPolluted.ctor(self)
    self.allowSelected = true
    ---@type CS.UnityEngine.Animator
    self._animator = nil
    self._animatorState = {
        [CityTileAssetFurniture.AnimatorStatus.work] = false,
        [CityTileAssetFurniture.AnimatorStatus.work_fast] = false,
        [CityTileAssetFurniture.AnimatorStatus.up] = false,
    }
    ---@type CityFurnitureAnimationPlayEffectReceiver
    self._animatorEffectReceiver = nil
    ---@type CityFurnitureDogHouseUpgradePatch
    self._dogHouseUpgradePatch = nil
    self.syncLoaded = true
    ---@type CS.DragonReborn.SoundPlayingHandle|nil
    self._workSoundHandle = nil
end

function CityTileAssetFurniture:GetPrefabName()
    if self:SkipForSLGAsset() then
        return string.Empty
    end

    if self.tileView.tile:IsInner() and not self:GetCity().roofHide then
        return string.Empty
    end

    ---@type CityFurniture
    local furniture = self.tileView.tile:GetCell()
    local castleFurniture = self:GetCity().furnitureManager:GetCastleFurniture(furniture.singleId)
    if not castleFurniture then
        return string.Empty
    end

    if furniture:GetUpgradeCostTime() > 0
        and castleFurniture.LevelUpInfo.Working
        and castleFurniture.LevelUpInfo.CurProgress >= castleFurniture.LevelUpInfo.TargetProgress
        and furniture.furnitureCell:RibbonCuttingModel() > 0 then
        return string.Empty -- 等待剪彩
    else
        if self:HasSkin() then
            self.mdlId = self:GetSkinModelId()
        else 
            if furniture:IsOutside() then
                if furniture:IsLocked() then
                    self.mdlId = furniture.furnitureCell:ModelUnlock()
                else
                    self.mdlId = furniture.furnitureCell:Model()
                end
            else
                if furniture:IsLocked() then
                    self.mdlId = furniture.furnitureCell:ModelUnlockIndoor()
                else
                    self.mdlId = furniture.furnitureCell:ModelIndoor()
                end
            end
        end
    end

    return ArtResourceUtils.GetItem(self.mdlId)
end

function CityTileAssetFurniture:Hide()
    self.mdlId = nil
    CityTileAssetPolluted.Hide(self)
end

function CityTileAssetFurniture:GetScale()
    return ArtResourceUtils.GetItem(self.mdlId, "ModelScale")
end

function CityTileAssetFurniture:SkipForSLGAsset()
    local furniture = self.tileView.tile:GetCell()
    if furniture ~= nil then
        return furniture.battleState
    end
    return false
end

function CityTileAssetFurniture:HasSkin()
    ---@type CityFurniture
    local cell = self.tileView.tile:GetCell()
    if cell.furType == CityFurnitureTypeNames["1000101"] then
        return ModuleRefer.PersonaliseModule:CheckCastleUsingSkin()
    end
    return false
end

function CityTileAssetFurniture:GetSkinModelId()
    return ModuleRefer.PersonaliseModule:GetUsingCastleInnerSkin()
end

function CityTileAssetFurniture:OnRoofStateChanged(roofHide)
    if not self.tileView then return end
    if not self.tileView.tile then return end
    if not self.tileView.tile:IsInner() then return end
    if not roofHide then
        self:Hide()
    else
        self:Show()
    end
end

function CityTileAssetFurniture:GetPriorityInView()
    return 10
end

function CityTileAssetFurniture:OnAssetLoaded(go, userdata)
    CityTileAssetPolluted.OnAssetLoaded(self, go, userdata)
    ---@type CityFurniture
    local cell = self.tileView.tile:GetCell()
    local city = self:GetCity()
    local pos = city:GetCenterWorldPositionFromCoord(cell.x, cell.y, cell.sizeX, cell.sizeY)
    
    local angle = ArtResourceUtils.GetItem(self.mdlId, "ModelRotation", 2) or 0
    local rotation = CS.UnityEngine.Quaternion.Euler(0, angle, 0)
    go.transform.position = pos
    go.transform.localRotation = rotation
    local collider = go:GetComponentInChildren(typeof(CS.UnityEngine.Collider))
    if Utils.IsNotNull(collider) then
        local trigger = go:AddMissingLuaBehaviour("CityTrigger")
        self.cityTrigger = trigger.Instance
        self.cityTrigger:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self.tileView.tile, false)
        self.cityTrigger:SetOnPress(Delegate.GetOrCreate(self, self.OnPressDown), Delegate.GetOrCreate(self, self.OnPress), Delegate.GetOrCreate(self, self.OnPressUp))
    end
    self:BindAnimator(go)
    local behaviour = go:GetLuaBehaviour("CityFurnitureDogHouseUpgradePatch")
    if behaviour then
        self._dogHouseUpgradePatch = behaviour.Instance
    end
    self:RefreshDogHouseUpgradePatch(city)

    if cell:IsNew() then
        ---TODO:播放新增入场动画
        cell:ClearNewMark()
        self:ForceSetToAnimatorStatusUpDown()
    end
    self:SyncAnimatorStatus()
    self:SyncSound()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_MAIN_ASSET_LOADED, self._furnitureId, go)
end

function CityTileAssetFurniture:OnAssetUnload(go, fade)
    if self._workSoundHandle then
        g_Game.SoundManager:Stop(self._workSoundHandle)
    end
    self._workSoundHandle = nil
    self._dogHouseUpgradePatch = nil
    if Utils.IsNotNull(self._animator) then
        self._animator:SetBool(CityTileAssetFurniture.AnimatorStatus.work, false)
        self._animator:SetBool(CityTileAssetFurniture.AnimatorStatus.work_fast, false)
        self._animator:SetBool(CityTileAssetFurniture.AnimatorStatus.up, false)
        self._animator:CrossFade("idle", 0)
        self._animator:Update(0)
    end
    self._animator = nil
    if self.cityTrigger then
        self.cityTrigger:SetOnTrigger(nil, nil, false)
        self.cityTrigger:SetOnPress(nil, nil, nil)
        self.cityTrigger = nil
    end
    CityTileAssetPolluted.OnAssetUnload(self, go, fade)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_MAIN_ASSET_UNLOAD, self._furnitureId)
end

function CityTileAssetFurniture:OnClick()
    if self.tileView and self.tileView.tile then
        local city = self:GetCity()
        if city then
            if city.stateMachine.currentState.OnClickFurnitureTile then
                city.stateMachine.currentState:OnClickFurnitureTile(self.tileView.tile)
                return true
            end
        end
    end
end

function CityTileAssetFurniture:OnPressDown()
    if not self.tileView or not self.tileView.tile then return end
    local city = self:GetCity()
    if not city then return end

    if city.stateMachine.currentState.OnPressDownFurnitureTile then
        city.stateMachine.currentState:OnPressDownFurnitureTile(self.tileView.tile)
        return true
    end
end

function CityTileAssetFurniture:OnPress()
    if not self.tileView or not self.tileView.tile then return end
    local city = self:GetCity()
    if not city then return end

    if city.stateMachine.currentState.OnPressFurnitureTile then
        city.stateMachine.currentState:OnPressFurnitureTile(self.tileView.tile)
        return true
    end
end

function CityTileAssetFurniture:OnPressUp()
    if not self.tileView or not self.tileView.tile then return end
    local city = self:GetCity()
    if not city then return end

    if city.stateMachine.currentState.OnPressUpFurnitureTile then
        city.stateMachine.currentState:OnPressUpFurnitureTile(self.tileView.tile)
        return true
    end
end

function CityTileAssetFurniture:OnMoveBegin()
    self._animatorState[CityTileAssetFurniture.AnimatorStatus.up] = true
    self:SyncAnimatorStatus()
end

function CityTileAssetFurniture:OnMoveEnd()
    self._animatorState[CityTileAssetFurniture.AnimatorStatus.up] = false
    self:SyncAnimatorStatus()
end

---@param go CS.UnityEngine.Animator
function CityTileAssetFurniture:BindAnimator(go)
    self._animator = go:GetComponentInChildren(typeof(CS.UnityEngine.Animator), true)
    if Utils.IsNull(self._animator) then
        return
    end
    local has, trans = self:TryGetAnimationEffectAnchorPos(go)
    if not has then
        return
    end
    local luaBehaviour = self._animator.gameObject:GetLuaBehaviour("CityFurnitureAnimationPlayEffectReceiver")
    if Utils.IsNull(luaBehaviour) then
        return
    end
    self._animatorEffectReceiver = luaBehaviour.Instance
    if not self._animatorEffectReceiver then
        return
    end
    self._animatorEffectReceiver:SetEffectRoot(trans)
end

function CityTileAssetFurniture:TryGetAnimationEffectAnchorPos(go)
    ---@type CS.FXAttachPointHolder
    local comp = go:GetComponent(typeof(CS.FXAttachPointHolder))
    if Utils.IsNotNull(comp) then
        local anchorTrans = comp:GetAttachPoint('holder_fur_anim_vfx')
        if Utils.IsNotNull(anchorTrans) then
            return true, anchorTrans
        end
    end
    return false, nil
end

function CityTileAssetFurniture:ForceSetToAnimatorStatusUpDown()
    if Utils.IsNull(self._animator) then
        return
    end
    self._animator:SetBool(CityTileAssetFurniture.AnimatorStatus.up, true)
    self._animator:Update(0)
end

function CityTileAssetFurniture:SyncSound()
    if Utils.IsNull(self.go) then
        return
    end
    local hasWork = self._animatorState[CityTileAssetFurniture.AnimatorStatus.work] or self._animatorState[CityTileAssetFurniture.AnimatorStatus.work_fast]
    if hasWork then
        if not self._workSoundHandle then
            ---@type CityFurniture
            local cell = self.tileView.tile:GetCell()
            local audioId = cell.furnitureCell:WorkSound()
            if audioId ~= 0 then
                self._workSoundHandle = g_Game.SoundManager:PlayAudio(audioId, self.go)
            end
        end
    elseif self._workSoundHandle then
        g_Game.SoundManager:Stop(self._workSoundHandle)
        self._workSoundHandle = nil
    end
end

function CityTileAssetFurniture:SyncAnimatorStatus()
    if Utils.IsNull(self._animator) then
        return
    end
    for key, value in pairs(self._animatorState) do
        if not self._animator:HasParameter(key) then
            goto continue
        end
        local valueType = type(value)
        if valueType == 'boolean' then
            self._animator:SetBool(key, value)
        elseif valueType == 'number' then
            if math.isinteger(valueType) then
                self._animator:SetInteger(key, value)
            else
                self._animator:SetFloat(key, value)
            end
        end
        ::continue::
    end
end

function CityTileAssetFurniture:OnTileViewInit()
    CityTileAssetFurniture.super.OnTileViewInit(self)
    self._uid = self.tileView.tile:GetCity().uid
    self._furnitureId = self.tileView.tile:GetCell():UniqueId()
    self._citizenMgr = self.tileView.tile:GetCity().cityCitizenManager
    self:SetupEvents(true)
end

function CityTileAssetFurniture:OnTileViewRelease()
    CityTileAssetFurniture.super.OnTileViewRelease(self)
    self:SetupEvents(false)
    self._citizenMgr = nil
    if self._workSoundHandle then
        g_Game.SoundManager:Stop(self._workSoundHandle)
    end
    self._workSoundHandle = nil
end

function CityTileAssetFurniture:SetupEvents(add)
    if add and not self._eventsAdd then
        self._eventsAdd = true
        g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
        g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
        g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExit))
        g_Game.EventManager:AddListener(EventConst.CITY_SLG_ASSET_UPDATE, Delegate.GetOrCreate(self, self.OnSlgAssetUpdate))
        g_Game.EventManager:AddListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureLvUpStatusChange))
    elseif not add and self._eventsAdd then
        self._eventsAdd = false
        g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
        g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_POLLUTED_IN, Delegate.GetOrCreate(self, self.OnPollutedEnter))
        g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_POLLUTED_OUT, Delegate.GetOrCreate(self, self.OnPollutedExit))
        g_Game.EventManager:RemoveListener(EventConst.CITY_SLG_ASSET_UPDATE, Delegate.GetOrCreate(self, self.OnSlgAssetUpdate))
        g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureLvUpStatusChange))
    end
end

function CityTileAssetFurniture:OnFurnitureDataChanged(city, batchEvt)
    if not self._uid or self._uid ~= city.uid then return end
    if not batchEvt or not batchEvt.Change then return end
    if batchEvt.Change[self._furnitureId] then
        self:RefreshFurnitureAni()
    end
end

function CityTileAssetFurniture:RefreshFurnitureAni()
    local workStatus = self:GetWorkStatus()
    local oldWorkStatus = self._animatorState[CityTileAssetFurniture.AnimatorStatus.work]
    local oldFastWorkStatus = self._animatorState[CityTileAssetFurniture.AnimatorStatus.work_fast]
    self._animatorState[CityTileAssetFurniture.AnimatorStatus.work] = workStatus > 0 and true or false
    self._animatorState[CityTileAssetFurniture.AnimatorStatus.work_fast] = workStatus > 1 and true or false
    if oldWorkStatus ~= self._animatorState[CityTileAssetFurniture.AnimatorStatus.work] 
            or oldFastWorkStatus ~= self._animatorState[CityTileAssetFurniture.AnimatorStatus.work_fast] then
        self:SyncAnimatorStatus()
        self:SyncSound()
    end
end

---@return number @0-idle, 1-work, 2-fast work
function CityTileAssetFurniture:GetWorkStatus()
    local castleFurniture = self.tileView.tile:GetCastleFurniture()
    if castleFurniture.ProcessInfo.LeftNum > 0 then
        return 1
    end

    if castleFurniture.ResourceProduceInfo.ResourceType > 0 then
        return 1
    end
    
    return 0
end

function CityTileAssetFurniture:IsPolluted()
    ---@type CityFurniture
    local cell = self.tileView.tile:GetCell()
    return cell:IsPolluted()
end

function CityTileAssetFurniture:IsMine(id)
    ---@type CityFurniture
    local cell = self.tileView.tile:GetCell()
    return cell.singleId == id
end

function CityTileAssetFurniture:OnSlgAssetUpdate(typ, id)
    if typ ~= wds.CityBattleObjType.CityBattleObjTypeFurniture then return end

    local cell = self.tileView.tile:GetCell()
    if cell ~= nil and cell.singleId == id then
        self:ForceRefresh()
    end
end

---@param param {Event:string, Change:table<number, boolean>}
function CityTileAssetFurniture:OnFurnitureLvUpStatusChange(city, param)
    if not param or not param.Change then
        return
    end
    local cell = self.tileView.tile:GetCell()
    if not cell then
        return
    end
    local tileCity = self:GetCity()
    if not tileCity or tileCity ~= city then
        return
    end
    if not param.Change[cell.singleId] then
        return
    end
    self:RefreshDogHouseUpgradePatch(tileCity)
end

---@param city MyCity
function CityTileAssetFurniture:RefreshDogHouseUpgradePatch(city)
    if not city or not city:IsMyCity() then
        return
    end
    local cell = self.tileView.tile:GetCell()
    if not cell then
        return
    end
    if not self._dogHouseUpgradePatch then
        return
    end
    local furnitureInfo = city:GetCastle().CastleFurniture[cell.singleId]
    if not furnitureInfo or not furnitureInfo.LevelUpInfo then
        return
    end
    if furnitureInfo.LevelUpInfo.Working then
        self._dogHouseUpgradePatch:SetToUpgrade()
    else
        self._dogHouseUpgradePatch:ResetToNormal()
    end
end

return CityTileAssetFurniture