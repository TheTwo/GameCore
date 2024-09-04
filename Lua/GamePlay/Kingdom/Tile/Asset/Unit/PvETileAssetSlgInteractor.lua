local PvPTileAssetUnit = require("PvPTileAssetUnit")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local TimeFormatter = require('TimeFormatter')
local TimerUtility = require('TimerUtility')
local ConfigTimeUtility = require("ConfigTimeUtility")
local ArtResourceUtils = require('ArtResourceUtils')
local KingdomTouchInfoHelper = require('KingdomTouchInfoHelper')
local EventConst = require('EventConst')
local SLGSelectManager = require("SLGSelectManager")
local KingdomMapUtils = require("KingdomMapUtils")
local Utils = require('Utils')
local DBEntityPath = require("DBEntityPath")
local ManualResourceConst = require("ManualResourceConst")
local ObjectType = require('ObjectType')
local PoolUsage = require("PoolUsage")
local PooledGameObjectHandle = CS.DragonReborn.AssetTool.PooledGameObjectHandle
local PooledGameObjectCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
local DBEntityType = require('DBEntityType')

---@class PvETileAssetSlgInteractor : MapTileAssetUnit
---@field isSelected boolean
local PvETileAssetSlgInteractor = class("PvETileAssetSlgInteractor", PvPTileAssetUnit)

function PvETileAssetSlgInteractor:ctor(fromType, useDefaultPos, backToSceneTid)
    PvPTileAssetUnit.ctor(self)
    self.fromType = fromType
    self.fade = true
    self.useDefaultPos = useDefaultPos
    self.backToSceneTid = backToSceneTid
end

function PvETileAssetSlgInteractor:GetLodPrefabName(lod)
    if KingdomMapUtils.InMapNormalLod(lod) then
        local entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
        if not entity then
            return string.Empty
        end
        self.configId = entity.Interactor.ConfigID
        local conf = ConfigRefer.Mine:Find(self.configId)
        -- g_Logger.Error(ArtResourceUtils.GetItem(conf:InteractModel()))
        if conf then
            return ArtResourceUtils.GetItem(conf:InteractModel())
        end
    end
    return string.Empty
end

-- function PvETileAssetSlgInteractor:GetPosition()
--     return self:CalculateCenterPosition()
-- end

function PvETileAssetSlgInteractor:OnConstructionSetup()
    PvETileAssetSlgInteractor.super.OnConstructionSetup(self)
    self.entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if not self.entity then
        return
    end

    if Utils.IsNull(self:GetAsset()) then
        return
    end

    -- self:GetAsset().transform.name = "SLGInteractor" .. self.entity.ID
    self:GetAsset().transform.gameObject:SetActive(false)
    g_Game.EventManager:AddListener(EventConst.ON_SLG_START_INTREACTOR, Delegate.GetOrCreate(self, self.PushCallBackInteract))
    g_Game.EventManager:AddListener(EventConst.ON_SLG_END_ONCE_INTREACTOR, Delegate.GetOrCreate(self, self.PushOneInteract))
    g_Game.EventManager:AddListener(EventConst.ON_SLG_END_ALL_INTREACTOR, Delegate.GetOrCreate(self, self.PushEndInteract))
    g_Game.EventManager:AddListener(EventConst.ON_SLG_BREAK_ALL_INTREACTOR, Delegate.GetOrCreate(self, self.PushBreakInteract))
    g_Game.EventManager:AddListener(EventConst.MAP_SELECT_BUILDING, Delegate.GetOrCreate(self, self.OnSelected))
    g_Game.EventManager:AddListener(EventConst.MAP_UNSELECT_BUILDING, Delegate.GetOrCreate(self, self.OnUnselected))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.SlgInteractor.Interactor.State.MsgPath, Delegate.GetOrCreate(self, self.OnInteractorStateChanged))
    self.slgHandle = nil
    self.configId = self.entity.Interactor.ConfigID
    local conf = ConfigRefer.Mine:Find(self.entity.Interactor.ConfigID)
    local createHelper = ModuleRefer.RadarModule:GetCreateHelper()
    local vfxRoot = self:GetAsset().transform.transform:Find("p_vfx")
    if Utils.IsNotNull(vfxRoot) and not self.slgEffectHandle then
        self.slgEffectHandle = createHelper:Create(ArtResourceUtils.GetItem(conf:InteractEffect()), vfxRoot.transform, Delegate.GetOrCreate(self, self.OnLoadEffect))
    end
    self.interactState = self.entity.Interactor.State
    self.isSeMapInstance = conf:MapInstanceId() > 0
    if self.isSeMapInstance and self.interactState.CannotEnterSe and not self.CombatEffectHandle then
        self.CombatEffectHandle = createHelper:Create(ManualResourceConst.vfx_w_bigmap_fighting, self:GetAsset().transform, Delegate.GetOrCreate(self, self.OnLoadFightingEffect))
    end

    local scale = ArtResourceUtils.GetScale(conf:InteractModel())
    if scale > 0 then
        self:GetAsset().transform.localScale = CS.UnityEngine.Vector3.one * scale
    end
    self:LoadDelEffect()

    --世界事件内 采集物头顶hud
    if self.entity.LevelEntityInfo and self.entity.LevelEntityInfo.LevelEntityId > 0 and (self.entity.Owner.ExclusivePlayerId == 0 or self.entity.Owner.ExclusivePlayerId == ModuleRefer.SlgModule:MySelf().ID) then
        if ModuleRefer.WorldEventModule:IsWorldEventActive(self.entity.LevelEntityInfo.LevelEntityId) then
            self._pooledCreateHelper = PooledGameObjectCreateHelper.Create("SlgInteractorHud")
            self._pooledCreateHelper:Create("troop_hud", self:GetAsset().transform, function(go)
                if (Utils.IsNotNull(go)) then
                    go.transform.localPosition = CS.UnityEngine.Vector3.zero
                    go.transform.localScale = CS.UnityEngine.Vector3.one
                    local troopHud = go:GetLuaBehaviour('TroopHUD').Instance
                    local entity = g_Game.DatabaseManager:GetEntity(self.entity.LevelEntityInfo.LevelEntityId, DBEntityType.Expedition)
                    troopHud:SetWorldEventIcon(entity)
                    troopHud:InteractorSetup()
                end
            end)
        end
    end
end

function PvETileAssetSlgInteractor:OnConstructionShutdown()
    local createHelper = ModuleRefer.RadarModule:GetCreateHelper()
    if self.slgEffectHandle then
        createHelper:Delete(self.slgEffectHandle)
    end
    self.slgEffectHandle = nil
    if self.birthEffectHandle then
        createHelper:Delete(self.birthEffectHandle)
    end
    self.birthEffectHandle = nil
    if self.CombatEffectHandle then
        createHelper:Delete(self.CombatEffectHandle)
    end
    self.CombatEffectHandle = nil
    if self.delayShowTimer then
        TimerUtility.StopAndRecycle(self.delayShowTimer)
    end
    self.delayShowTimer = nil
    if self.slgTimer then
        self.slgTimer:Stop()
        self.slgTimer = nil
    end
    self.isSeMapInstance = false
    g_Game.EventManager:RemoveListener(EventConst.ON_SLG_START_INTREACTOR, Delegate.GetOrCreate(self, self.PushCallBackInteract))
    g_Game.EventManager:RemoveListener(EventConst.ON_SLG_END_ONCE_INTREACTOR, Delegate.GetOrCreate(self, self.PushOneInteract))
    g_Game.EventManager:RemoveListener(EventConst.ON_SLG_END_ALL_INTREACTOR, Delegate.GetOrCreate(self, self.PushEndInteract))
    g_Game.EventManager:RemoveListener(EventConst.ON_SLG_BREAK_ALL_INTREACTOR, Delegate.GetOrCreate(self, self.PushBreakInteract))
    g_Game.EventManager:RemoveListener(EventConst.MAP_SELECT_BUILDING, Delegate.GetOrCreate(self, self.OnSelected))
    g_Game.EventManager:RemoveListener(EventConst.MAP_UNSELECT_BUILDING, Delegate.GetOrCreate(self, self.OnUnselected))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.SlgInteractor.Interactor.State.MsgPath, Delegate.GetOrCreate(self, self.OnInteractorStateChanged))
end

function PvETileAssetSlgInteractor:OnInteractorStateChanged(entity, _)
    if not entity or entity.ID ~= self.entity.ID then
        return
    end
    local createHelper = ModuleRefer.RadarModule:GetCreateHelper()

    -- 挑战失败，删除特效
    if self.isSeMapInstance and self.interactState.CannotEnterSe and not entity.Interactor.State.CannotEnterSe then
        if self.CombatEffectHandle then
            createHelper:Delete(self.CombatEffectHandle)
        end
        self.CombatEffectHandle = nil
        self.interactState.CannotEnterSe = entity.Interactor.State.CannotEnterSe
        return
    end

    -- 开始挑战，添加特效
    if self.isSeMapInstance and not self.interactState.CannotEnterSe and entity.Interactor.State.CannotEnterSe then
        self.CombatEffectHandle = createHelper:Create(ManualResourceConst.vfx_w_bigmap_fighting, self:GetAsset().transform, Delegate.GetOrCreate(self, self.OnLoadFightingEffect))
        self.interactState.CannotEnterSe = entity.Interactor.State.CannotEnterSe
        return
    end
end

function PvETileAssetSlgInteractor:OnSelected(entity)
    if entity == nil then
        return
    end

    if entity.ID == self.view:GetUniqueId() then
        if self.progressBar then
            self.progressBar:UseSmallState(false)
        end
    end
end

function PvETileAssetSlgInteractor:OnUnselected(entity)
    if entity == nil then
        return
    end

    if entity.ID == self.view:GetUniqueId() then
        if self.progressBar then
            self.progressBar:UseSmallState(true)
        end
    end
end

function PvETileAssetSlgInteractor:PushCallBackInteract(msg)
    if msg and msg.InteractorId == self.entity.ID then
        local createHelper = ModuleRefer.RadarModule:GetCreateHelper()
        if not self.slghandle then
            self.slghandle = createHelper:Create("ui3d_bubble_map_progress", self:GetAsset().transform, Delegate.GetOrCreate(self, self.OnCountdownCreate))
        end
    end
end

function PvETileAssetSlgInteractor:PushEndInteract(msg)
    if msg and msg.InteractorId == self.entity.ID then
        self:RefreshBubble()
        if Utils.IsNotNull(self.dieEffect) then
            self.dieEffect:SetActive(true)
        end
        if Utils.IsNotNull(self:GetAsset()) then
            self:GetAsset().transform.gameObject:SetActive(false)
        end
    end
end

function PvETileAssetSlgInteractor:PushBreakInteract(msg)
    if msg and msg.InteractorId == self.entity.ID then
        self:RefreshBubble()
    end
end

function PvETileAssetSlgInteractor:PushOneInteract(msg)
    if msg and msg.InteractorId == self.entity.ID then
        self:RefreshBubble()

        local configId = self.entity.Interactor.ConfigID
        local mineConf = ConfigRefer.Mine:Find(configId)
        if not mineConf or mineConf:MapInstanceId() < 1 then
            -- 不是SE入口
            return
        end

        local x = self.entity.MapBasics.BuildingPos.X
        local z = self.entity.MapBasics.BuildingPos.Y

        local selectTroopData = ModuleRefer.SlgModule.selectManager:GetFirstSelected()
        local troopId = SLGSelectManager.GetSelectTroopDataId(selectTroopData)
        if troopId <= 0 then
            local _, troop = ModuleRefer.SlgModule.troopManager:GetOneIdleTroop()
            if troop == nil then
                return
            end
            troopId = troop.troopId
        end

        local position = KingdomTouchInfoHelper.GetWorldPosition(x, z)

        local context = {
            troopId = troopId,
            worldPos = position,
            gridPos = CS.DragonReborn.Vector2Short(x, z),
            interactorId = self.entity.ID,
            interactorConfId = configId,
            fromType = self.fromType,
            useDefaultPos = self.useDefaultPos,
            backToSceneTid = self.backToSceneTid,
        }

        local result, menuDatum = ModuleRefer.SEPreModule:CreateTouchMenuForWorld(context, not ModuleRefer.SlgModule:IsTroopVisible(troopId))

        g_Game.EventManager:TriggerEvent(EventConst.ON_TROOP_ENTER_EVENT_TRIGGER, {
            teamId = troopId,
            onClick = function()
                ModuleRefer.SEPreModule:CreateTouchMenuForWorld(context)
            end,
            tipData = {
                tipType = 1, -- in world
                gridPos = CS.DragonReborn.Vector2Short(x, z),
                interactorConfId = configId,
            },
            menuDatum = menuDatum,
        })
    end
end

function PvETileAssetSlgInteractor:OnCountdownCreate(go)
    self.configId = self.entity.Interactor.ConfigID
    local conf = ConfigRefer.Mine:Find(self.configId)
    local progressBar = go:GetComponent(typeof(CS.DragonReborn.LuaBehaviour)).Instance
    progressBar:UseSmallState(true)
    progressBar:DisplayRedBar(false)
    progressBar:EnableTrigger(false)
    if conf:MapInstanceId() > 0 then

    else
        progressBar:UpdateIcon(conf:ShowIcon())
    end
    local scale = ArtResourceUtils.GetScale(conf:InteractModel())
    local resultScale = 1
    local offset = 50
    if scale > 0 then
        resultScale = resultScale / scale
        offset = offset / scale
    end
    go.transform.localScale = CS.UnityEngine.Vector3.one * resultScale
    -- progressBar:UpdateLocalScale(CS.UnityEngine.Vector3(resultScale, resultScale, resultScale))
    progressBar:UpdateLocalOffset(CS.UnityEngine.Vector3(0, 100, 0))
    local duration = ConfigTimeUtility.NsToSeconds(conf:InteractTime())
    progressBar:UpdateProgress(0)
    progressBar:HideDesc()
    progressBar:UpdateTime(TimeFormatter.SimpleFormatTime(duration))
    self.startTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    self.slgTimer = TimerUtility.StartFrameTimer(function()
        local pastTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() - self.startTime
        progressBar:UpdateProgress(pastTime / duration)
        progressBar:UpdateTime(TimeFormatter.SimpleFormatTime(math.floor(duration - pastTime)))
        if self:IsFinished() then
            self:RefreshBubble()
        end
    end, 1, -1)
    self.progressBar = progressBar
end

function PvETileAssetSlgInteractor:OnLoadEffect(go)
    local conf = ConfigRefer.Mine:Find(self.configId)
    local scale = ArtResourceUtils.GetScale(conf:InteractModel())
    if scale > 0 then
        go.transform.localScale = CS.UnityEngine.Vector3.one * 10 * conf:InteractEffectScale() / scale
    else
        go.transform.localScale = CS.UnityEngine.Vector3.one * 10 * conf:InteractEffectScale()
    end
end

function PvETileAssetSlgInteractor:OnLoadFightingEffect(go)
    local conf = ConfigRefer.Mine:Find(self.configId)
    local scale = ArtResourceUtils.GetScale(conf:InteractModel())
    if scale > 0 then
        go.transform.localScale = CS.UnityEngine.Vector3.one * 30 * conf:InteractEffectScale() / scale
    else
        go.transform.localScale = CS.UnityEngine.Vector3.one * 30 * conf:InteractEffectScale()
    end
end

function PvETileAssetSlgInteractor:IsFinished()
    if not self.startTime then
        return true
    end
    local conf = ConfigRefer.Mine:Find(self.entity.Interactor.ConfigID)
    local pastTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() - self.startTime
    local duration = ConfigTimeUtility.NsToSeconds(conf:InteractTime())
    return pastTime > duration
end

function PvETileAssetSlgInteractor:RefreshBubble()
    if self.slgTimer then
        self.slgTimer:Stop()
        self.slgTimer = nil
    end
    self.startTime = nil
    if self.slghandle then
        local createHelper = ModuleRefer.RadarModule:GetCreateHelper()
        createHelper:Delete(self.slghandle)
    end
    self.slghandle = nil
end

function PvETileAssetSlgInteractor:LoadDelEffect()
    local createHelper = ModuleRefer.RadarModule:GetCreateHelper()
    if not self.dieEffectHandle then
        local conf = ConfigRefer.Mine:Find(self.configId)
        local prefabName = ArtResourceUtils.GetItem(conf:DieEffect())
        if prefabName then
            if self:GetAsset() then
                local parent = KingdomMapUtils.GetMapSystem().Parent
                local position = self:GetAsset().transform.position
                self.dieEffectHandle = createHelper:Create(prefabName, parent, function(go)
                    go.transform.localScale = CS.UnityEngine.Vector3.one * 15
                    go.transform.position = position
                    self.dieEffect = go
                    self.dieEffect:SetActive(false)
                end)
            end
        end
    end
end

function PvETileAssetSlgInteractor:GetEnableFadeOut()
    return self:GetFadeOutDuration() > 0
end

function PvETileAssetSlgInteractor:GetEnableFadeIn()
    return self:GetFadeInDuration() > 0
end

function PvETileAssetSlgInteractor:GetFadeOutDuration()
    if self.configId then
        local conf = ConfigRefer.Mine:Find(self.configId)
        return conf:DieEffectDelay() > 0 and conf:DieEffectDelay() or 0.1
    else
        return 0
    end
end

function PvETileAssetSlgInteractor:GetFadeInDuration()
    self.entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    if self.entity == nil or self.entity.Interactor == nil then
        return 0
    end

    local conf = ConfigRefer.Mine:Find(self.entity.Interactor.ConfigID)
    if conf == nil then
        return 0
    end

    return conf:BirthEffectDelay() > 0 and conf:BirthEffectDelay() or 0.1
end

function PvETileAssetSlgInteractor:FadeOut(duration)
    TimerUtility.DelayExecute(function()
        local createHelper = ModuleRefer.RadarModule:GetCreateHelper()
        if self.dieEffectHandle then
            createHelper:Delete(self.dieEffectHandle)
        end
        self.dieEffectHandle = nil
    end, duration)
end

function PvETileAssetSlgInteractor:FadeIn(duration)
    if Utils.IsNull(self:GetAsset()) then
        return
    end
    if not self:CanShow() then
        return
    end
    self.entity = g_Game.DatabaseManager:GetEntity(self.view.uniqueId, self.view.typeId)
    local createHelper = ModuleRefer.RadarModule:GetCreateHelper()
    if self.entity and not self.birthEffectHandle then
        local conf = ConfigRefer.Mine:Find(self.entity.Interactor.ConfigID)
        local prefabName = ArtResourceUtils.GetItem(conf:BirthEffect())
        local parent = KingdomMapUtils.GetMapSystem().Parent
        if prefabName then
            self.birthEffectHandle = createHelper:Create(prefabName, parent, function(go)
                go.transform.localScale = CS.UnityEngine.Vector3.one * 15
                go.transform.position = self:GetAsset().transform.position
            end)
        end
    end
    self.delayShowTimer = TimerUtility.DelayExecute(function()
        self:GetAsset().transform.gameObject:SetActive(true)
    end, duration)
end

function PvETileAssetSlgInteractor:Show()
    self:OnShow()
    self:ShowInternal(self:GetEnableFadeIn())
end

function PvETileAssetSlgInteractor:Hide()
    self:HideInternal(self:GetEnableFadeOut())
    self:OnHide()
end

function PvETileAssetSlgInteractor:CheckIsCanShow()
    if self:CanShow() then
        self:Show()
    else
        self:Hide()
    end
end

function PvETileAssetSlgInteractor:CanShow()
    if not self.entity then
        return false
    end
    -- 个人交互物只有自己能看到
    local isMine = self.entity.Owner.ExclusivePlayerId == ModuleRefer.PlayerModule:GetPlayer().ID
    local isMulti = self.entity.Owner.ExclusivePlayerId == 0 and self.entity.Owner.ExclusiveAllianceId == 0
    local isAlliance = self.entity.Owner.ExclusiveAllianceId == ModuleRefer.AllianceModule:GetAllianceId()
    return isMulti or isMine or isAlliance
end

return PvETileAssetSlgInteractor
