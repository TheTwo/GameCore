local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local Utils = require("Utils")
local CityTilePriority = require("CityTilePriority")
local ArtResourceUtils = require("ArtResourceUtils")
local ConfigTimeUtility = require("ConfigTimeUtility")
local ArtResourceConsts = require("ArtResourceConsts")
local NpcServiceType = require("NpcServiceType")
local NpcServiceObjectType = require("NpcServiceObjectType")
local AudioConsts = require("AudioConsts")
local CityNpcType = require("CityNpcType")
local TimeFormatter = require("TimeFormatter")
local TimerUtility = require("TimerUtility")

local CityTileAssetBubble = require("CityTileAssetBubble")

---@class CityTileAssetNpcBubbleCommon:CityTileAssetBubble
---@field new fun():CityTileAssetNpcBubbleCommon
---@field super CityTileAssetBubble
local CityTileAssetNpcBubbleCommon = class('CityTileAssetNpcBubbleCommon', CityTileAssetBubble)

function CityTileAssetNpcBubbleCommon:ctor()
    CityTileAssetBubble.ctor(self)
    self.isUI = true
    ---@type CS.UnityEngine.GameObject
    self._go = nil
    ---@type City3DBubbleStandard
    self._bubble = nil
    self._inTimeline = false
    ---@type CS.UnityEngine.GameObject
    self._visibleRoot = nil
    self._inSelfCity = false
    self._isSeEntry = false
    self._useMainAssetBoundForPos = false
    self._hideByStory = nil
    self._treasureProgressTick = false
    self._tickTempHide = false
    ---@type {duration:number, endTime:number}|nil
    self._treasureProgress = nil
    self._tempHideEndTime = nil

    self._firstRechargeProgressTick = false
    ---@type {startTime:number, endTime:number}|nil
    self._firstRechargeProgress = nil

end

function CityTileAssetNpcBubbleCommon:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    local tile = self.tileView.tile
    local city = tile:GetCity()
    self._inSelfCity = city:IsMyCity()
    self._cityCamera = city:GetCamera()
    self._showCheckTeamPosChange = false
    self._elementId = self.tileView.tile:GetCell().configId
    self._cityUid = city.uid
    self._npcId = ConfigRefer.CityElementData:Find(self._elementId):ElementId()

    local player = ModuleRefer.PlayerModule:GetPlayer()
    self._playerId = (city:IsMyCity() and player ~= nil) and player.ID or 0
    self._npcCfg = ConfigRefer.CityElementNpc:Find(self._npcId)
    self._isTreasureBox = self._npcCfg:Type() == CityNpcType.Treasure

    local iconId = self._npcCfg:InteractIcon()
    self._interactIcon = iconId > 0 and ArtResourceUtils.GetUIItem(iconId) or 'sp_city_icon_chat'
    self._pollutedOverrideIcon = self._npcCfg:PollutedOverrideInteractIcon()
    
    g_Game.EventManager:AddListener(EventConst.CITY_FOG_UNLOCK_CHANGED, Delegate.GetOrCreate(self, self.OnFogStatusChanged))
    ModuleRefer.PlayerServiceModule:AddServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.OnNpcServiceChanged))
    g_Game.EventManager:AddListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self, self.OnNpcAcceptedChaptersChanged))
    g_Game.EventManager:AddListener(EventConst.STROY_FINISHE_LOG_SERVER_INFO_CHANGED, Delegate.GetOrCreate(self, self.Refresh))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_NPC_TREASURE_REFRESH, Delegate.GetOrCreate(self, self.OnTreasureRefresed))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_NPC_BUBBLE_TMP_HIDE, Delegate.GetOrCreate(self, self.OnTempHide))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_NPC_BUBBLE_RANGE_EVENT_UPDATE, Delegate.GetOrCreate(self, self.OnCityElementNpcBubbleRangeEventUpdate))
end

function CityTileAssetNpcBubbleCommon:OnTileViewRelease()
    self:SetupTreasureProgress(false)
    self:SetupTempHideTimer(false)
    self:SetupFirstRechargeProgress(false)
    self._tempHideEndTime = nil
    self._treasureProgress = nil
    g_Game.EventManager:RemoveListener(EventConst.CITY_FOG_UNLOCK_CHANGED, Delegate.GetOrCreate(self, self.OnFogStatusChanged))
    ModuleRefer.PlayerServiceModule:RemoveServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.OnNpcServiceChanged))
    g_Game.EventManager:RemoveListener(EventConst.QUEST_DATA_WATCHER_EVENT, Delegate.GetOrCreate(self, self.OnNpcAcceptedChaptersChanged))
    g_Game.EventManager:RemoveListener(EventConst.STROY_FINISHE_LOG_SERVER_INFO_CHANGED, Delegate.GetOrCreate(self, self.Refresh))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_NPC_TREASURE_REFRESH, Delegate.GetOrCreate(self, self.OnTreasureRefresed))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_NPC_BUBBLE_TMP_HIDE, Delegate.GetOrCreate(self, self.OnTempHide))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_NPC_BUBBLE_RANGE_EVENT_UPDATE, Delegate.GetOrCreate(self, self.OnCityElementNpcBubbleRangeEventUpdate))
    CityTileAssetBubble.OnTileViewRelease(self)
end

function CityTileAssetNpcBubbleCommon:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end

    if self:ShouldShow() then
        return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_group)
    end
    return string.Empty
end

function CityTileAssetNpcBubbleCommon:OnAssetLoaded(go, userdata)
    self._useMainAssetBoundForPos = false
    CityTileAssetBubble.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end
    local behaviour = go:GetLuaBehaviour("City3DBubbleStandard")
    if not behaviour or not behaviour.Instance then
        return
    end
    self._bubble = behaviour.Instance
    if not self._bubble then
        return
    end
    self._go = go
    if not self:TrySetPosToMainAssetAnchor(self._bubble.transform) then
        if self._npcCfg and self._npcCfg:IsHuman() then
            local modelCfg = ConfigRefer.ArtResource:Find(self._npcCfg:Model())
            local city = self:GetCity()
            local height = modelCfg:CapsuleHeight() * city.scale
            go.transform.position = CityTileAssetBubble.SuggestCellCenterPositionWithHeight(city, self.tileView.tile:GetCell(), height * 1.2)
        else
            self._useMainAssetBoundForPos = true
            local bounds = self.tileView:ReadBlackboard(self.tileView.Key.MainAssetBounds)
            self:OnMainAssetBoundsChanged(self.tileView.Key.MainAssetBounds, bounds)
        end
    end
    self._visibleRoot = self._bubble.p_bubble
    self:DoRefreshBubble(true)
    self.tileView:AddBlackboardListener(self.tileView.Key.MainAssetBounds, Delegate.GetOrCreate(self, self.OnMainAssetBoundsChanged))
    if Utils.IsNotNull(self._visibleRoot) then
        self._visibleRoot:SetVisible(true)
    end
end

function CityTileAssetNpcBubbleCommon:OnAssetUnload(go, fade)
    self:SetupTreasureProgress(false)
    self:SetupTempHideTimer(false)
    self:SetupFirstRechargeProgress(false)
    self._useMainAssetBoundForPos = false
    self.tileView:RemoveBlackboardListener(self.tileView.Key.MainAssetBounds, Delegate.GetOrCreate(self, self.OnMainAssetBoundsChanged))
    if self._bubble and fade and fade > 0 then
        self._bubble:PlayOutAni()
    end
    if self._bubble then
        self._bubble:ShowBubbleIconEffect(nil)
    end
    self:StopTimer()
    self._bubble = nil
    if not fade or fade <= 0 then
        g_Logger.Log("fast hide")
    end
    CityTileAssetBubble.OnAssetUnload(self, go, fade)
end

function CityTileAssetNpcBubbleCommon:Refresh()
    local canShow = self:CheckCanShow()
    if not canShow then
        self:Hide()
        return
    end
    if not self:ShouldShow()then
        self:Hide()
        return
    end
    if not self.handle then
        self:Show()
    elseif self._bubble then
        self:DoRefreshBubble(false)
    end
end

function CityTileAssetNpcBubbleCommon:ShouldShow()
    self._isSeEntry = false
    if not self._inSelfCity then
        return false
    end
    if not self._npcCfg or self._npcCfg:NoInteractable() or self._npcCfg:NoneBubble() then
        return false
    end
    local city = self:GetCity()
    local x,y = self.tileView.tile.x,self.tileView.tile.y
    if city:IsFogMask(x, y) then
        return false
    end
    local isInSingleSeExplorerMode = city:IsInSingleSeExplorerMode()
    if isInSingleSeExplorerMode and self._npcCfg:NoInteractableInSEExplore() then
        return false
    end
    if self:IsPolluted() and self._npcCfg:PollutedHideBubble() then
        return false
    end
    if self._tempHideEndTime and self._tempHideEndTime > g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then
        return false
    end
    self._tempHideEndTime = nil
    if self._radarTask then
        return true
    end
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local preTask = self._npcCfg:Precondition()
    if preTask ~= 0 then
        local QuestModule = ModuleRefer.QuestModule
        if not QuestModule:IsInBitMap(preTask, player.PlayerWrapper.Task.FinishedBitMap) then
            return false
        end
    end
    local explorerMgr = city.cityExplorerManager
    local zoneMgr = city.zoneManager
    if not explorerMgr or not zoneMgr then
        return false
    end
    local isSingleSeExplorerZoneOpenDoorNpc, zoneId = zoneMgr:IsSingleExplorerOpenNpcLink(self._elementId)
    if isInSingleSeExplorerMode then
        if isSingleSeExplorerZoneOpenDoorNpc then
            return false
        end
        if not city.cityExplorerManager:CheckShowUnderExploreModeByRangeEvent(self._elementId) then
            return false
        end
    elseif zoneMgr:IsInSingleSeExplorerZone(x, y) and not isSingleSeExplorerZoneOpenDoorNpc then
        return false
    elseif isSingleSeExplorerZoneOpenDoorNpc then
        local zone = zoneMgr:GetZoneById(zoneId)
        if not zone or not zone:IsHideFog() then
            return false
        end
    end
    local hasChapterTask = ModuleRefer.QuestModule.Chapter:CheckIsShowCityElementNpcHeadIcon(self._npcId)
    if hasChapterTask then
        local story = self._npcCfg:InitStoryTaskId()
        if story ~= 0 and not ModuleRefer.StoryModule:IsPlayerStoryTaskFinished(story) then
            return true
        end
        return false
    end
    -- if isSingleSeExplorerZoneOpenDoorNpc then
    --     return true
    -- end
    local npcData = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[self._elementId]
    if not npcData and not self._isTreasureBox then
        return false
    end
    if ModuleRefer.PlayerServiceModule:IsAllServiceCompleteOnNpc(npcData, true) and not self._isTreasureBox then
        return false
    end

    local isShowCommit = self._npcId == ConfigRefer.CityConfig:RescueBeauty() and self:GetCity():IsInSingleSeExplorerMode()
    local isOnlyCommit = not isShowCommit and ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(npcData, NpcServiceType.CommitItem)
    if isOnlyCommit then
        return false
    end
    self._isSeEntry = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(npcData, NpcServiceType.EnterScene)
    if not self._isSeEntry then
        self._isSeEntry = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(npcData, NpcServiceType.CatchPet)
    end
    return true
end

---@param city MyCity
function CityTileAssetNpcBubbleCommon:OnFogStatusChanged(city)
    if not self._cityUid or not city or self._cityUid ~= city.uid then
        return
    end
    self:Refresh()
end

---@param entity wds.Player
---@param changedData table
function CityTileAssetNpcBubbleCommon:OnNpcServiceChanged(entity, changedData)
    if entity.ID ~= self._playerId or not changedData then
        return
    end
    ---@type table<number, wds.CastleTreasureInfo>
    local AddMap = changedData.Add
    ---@type table<number, wds.CastleTreasureInfo>
    local RemoveMap = changedData.Remove
    if (AddMap and AddMap[self._elementId]) or (RemoveMap and RemoveMap[self._elementId]) then
        self:Refresh()
    elseif changedData[self._elementId] then
        self:Refresh()
    end
end

---@param entity wds.Player
function CityTileAssetNpcBubbleCommon:OnNpcAcceptedChaptersChanged(entity, changedData)
    --if entity.ID ~= self._playerId or not changedData then
    --    return
    --end
    -----@type table<number, wds.ElementNpcAcceptedChapters>
    --local AddMap = changedData.Add
    -----@type table<number, wds.ElementNpcAcceptedChapters>
    --local RemoveMap = changedData.Remove
    --if (AddMap and AddMap[self._elementId]) or (RemoveMap and RemoveMap[self._elementId]) then
    --    self:Refresh()
    --elseif changedData[self._elementId] then
    --    self:Refresh()
    --end
    self:Refresh()
end

---@param city MyCity
---@param elementId number
---@param targetPos CS.UnityEngine.Vector3
---@return ClickNpcEventContext
function CityTileAssetNpcBubbleCommon.MakeClickNpcMsgContext(city, elementId)
    local eleConfig = ConfigRefer.CityElementData:Find(elementId)
    local elePos = eleConfig:Pos()
    local npcConfig = ConfigRefer.CityElementNpc:Find(eleConfig:ElementId())
    local pos = city:GetElementNpcInteractPos(elePos:X(), elePos:Y(), npcConfig)
    ---@type ClickNpcEventContext
    local context = {}
    context.cityUid = city.uid
    context.elementConfigID = elementId
    context.targetPos = pos
    return context
end

function CityTileAssetNpcBubbleCommon:OnClickIcon(_)
    local tile = self.tileView.tile
    local city = tile:GetCity()
    local cell = tile:GetCell()
    local context = CityTileAssetNpcBubbleCommon.MakeClickNpcMsgContext(city, cell.configId)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, context)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
    return true
end

function CityTileAssetNpcBubbleCommon:OnClickTreasure(_)
    local city = self:GetCity()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_CLICK_GET_TREASURE,city.uid, self.tileView.tile:GetCell().configId)
    return true
end

function CityTileAssetNpcBubbleCommon:GetPriorityInView()
    return CityTilePriority.BUBBLE - CityTilePriority.NPC
end

---@param key string
---@param value CS.UnityEngine.Bounds
function CityTileAssetNpcBubbleCommon:OnMainAssetBoundsChanged(key, value)
    if not self._useMainAssetBoundForPos then
        return
    end
    if self._npcCfg and self._npcCfg:IsHuman() then
        return
    end
    if Utils.IsNull(self._go) then
        return
    end
    local go = self._go
    if value then
        local center = value.center
        center.y = value.max.y
        go.transform.position = center
    else
        local suggestLocalPos = CityTileAssetBubble.SuggestBubblePosition(self.tileView.tile:GetCell(), go)
        go.transform.localPosition = suggestLocalPos
    end
end

function CityTileAssetNpcBubbleCommon:DoRefreshBubble(needReset)
    if needReset then
        self._bubble:Reset()
    end
    local showDanger = self:IsPolluted()
    local city = self:GetCity()
    local clickCall= Delegate.GetOrCreate(self, self.OnClickIcon)
    local icon,iconAni = self:GetIcon()
    local bgIcon,effect = self:GetIconEffectAndBg()
    local lastInfo = self._treasureProgress
    self._radarTask = ModuleRefer.RadarModule:GetCityRadarTask(self._elementId)
    self._treasureProgress = self.tileView.tile:GetCity().cityExplorerManager:GetCurrentOpenTreasureProgress(self._elementId)
    if self._treasureProgress then
        if not lastInfo then
            self._bubble:ShowProgress(0, icon, false, nil, showDanger):ShowBubbleBackIcon(bgIcon):ShowBubbleIconEffect(effect)
        end
        self:TickTreasureProgress(0)
    elseif self._radarTask then
        --雷达气泡优先级高于se entry
        icon = self._radarTask.icon
        bgIcon = self._radarTask.frame
        self._bubble:ShowBubble(icon, false, false, false):ShowDangerImg(false):ShowBubbleBackIcon(bgIcon):ShowBubbleIconEffect(effect)
        self._bubble:SetBubbleVerticalPos()
        self:StopTimer()
        self.timer = TimerUtility.IntervalRepeat(function()
            self:TickSetTrigger()
        end, 0.5, -1)
    elseif self._npcId == ConfigRefer.CityConfig:FirstRechargeNpc() then
        self._bubble:ShowProgress(1, icon, false, false):ShowBubbleIcon(nil)
        self._firstRechargeProgress = ModuleRefer.ActivityShopModule:GetFirstRechargeBubbleProgress()
        self:TickFirstRechargeProgress(0)
    elseif self._isSeEntry then
        self._bubble:ShowBubble(icon, true, false, false):ShowDangerImg(showDanger):ShowBubbleSeBackIcon(bgIcon):ShowBubbleIconEffect(effect)
    else
        self._bubble:ShowBubble(icon, false, false, false):ShowDangerImg(showDanger):ShowBubbleBackIcon(bgIcon):ShowBubbleIconEffect(effect)
    end
    self:SetupTreasureProgress(self._treasureProgress ~= nil)
    self:SetupTempHideTimer(self._tempHideEndTime ~= nil)
    self:SetupFirstRechargeProgress(self._firstRechargeProgress ~= nil)
    self._bubble:SetOnTrigger(clickCall, self.tileView.tile)
    if iconAni == 1 then
        self._bubble:PlayRewardAnim()
    elseif iconAni == 2 then
        self._bubble:PlayTaskHintAnim()
    end
end

function CityTileAssetNpcBubbleCommon:IsPolluted()
    local cell = self.tileView.tile:GetCell()
    if cell == nil then return false end
    return self:GetCity().elementManager:IsPolluted(cell.configId)
end

---@return string,number|nil
function CityTileAssetNpcBubbleCommon:GetIcon()
    if self:IsPolluted() and not string.IsNullOrEmpty(self._pollutedOverrideIcon) then
        return self._pollutedOverrideIcon
    end
    local hasChapterTask = ModuleRefer.QuestModule.Chapter:CheckIsShowCityElementNpcHeadIcon(self._npcId)
    if hasChapterTask then
        if self._npcCfg and self._npcCfg:InitStoryTaskId() ~= 0 then
            if not ModuleRefer.StoryModule:IsPlayerStoryTaskFinished(self._npcCfg:InitStoryTaskId()) then
                return "sp_hud_icon_taskstip", 2
            end
        end
        return "sp_city_icon_chat"
    end
    local npcData = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[self._elementId]
    if npcData then
        local config = ConfigRefer.NpcServiceGroup:Find(npcData.ServiceGroupTid)
        local rewardAni = nil
        if ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(npcData, NpcServiceType.ReceiveItem) then
            rewardAni = 1
        end
        if config and not string.IsNullOrEmpty(config:Icon()) then
            return config:Icon(), rewardAni
        end
    end
    return self._interactIcon
end

function CityTileAssetNpcBubbleCommon:GetIconEffectAndBg()
    local hasTask,npcData,bgIcon,effect
    ---@type NpcServiceGroupConfigCell
    local config
    if self:IsPolluted() then
        goto continue
    end
    hasTask = ModuleRefer.QuestModule.Chapter:CheckIsShowCityElementNpcHeadIcon(self._npcId)
    if hasTask then
        goto continue
    end
    npcData = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[self._elementId]
    if npcData then
        config = ConfigRefer.NpcServiceGroup:Find(npcData.ServiceGroupTid)
        bgIcon = config:BubbleIconBg()
        effect = config:BubbleIconEffect()
        if not string.IsNullOrEmpty(bgIcon) then
            return bgIcon, effect
        else
            if self._isSeEntry then
                return self._bubble.GetDefaultSeBg(), effect
            else
                return self._bubble.GetDefaultNormalBg(), effect
            end
        end
    end
    ::continue::
    if self._isSeEntry then
        return self._bubble.GetDefaultSeBg(), string.Empty
    else
        return self._bubble.GetDefaultNormalBg(), string.Empty
    end
end

function CityTileAssetNpcBubbleCommon:CheckCanShow()
    local ret = CityTileAssetNpcBubbleCommon.super.CheckCanShow(self)
    if ret then
        self._hideByStory = nil
    elseif ModuleRefer.StoryModule:IsStoryTimelineOrDialogPlaying() then
        self._hideByStory = true
    end
    return ret
end

function CityTileAssetNpcBubbleCommon:ForceRefresh()
    CityTileAssetNpcBubbleCommon.super.ForceRefresh(self)
end

function CityTileAssetNpcBubbleCommon:GetFadeOutDuration()
    if self._hideByStory then
        self._hideByStory = nil
        return 0
    end
    return self._bubble and self._bubble:GetFadeOutDuration() or CityTileAssetBubble.GetFadeOutDuration(self)
end

function CityTileAssetNpcBubbleCommon:ShowInSingleSeExplorerMode()
    return true
end

function CityTileAssetNpcBubbleCommon:OnTreasureRefresed(cityUid, elementId)
    if elementId ~= self._elementId or cityUid ~= self.tileView.tile:GetCity().uid then return end
    self:Refresh()
end

function CityTileAssetNpcBubbleCommon:OnTempHide(cityUid, elementId, hideTime)
    if elementId ~= self._elementId or cityUid ~= self.tileView.tile:GetCity().uid then return end
    if hideTime then
        self._tempHideEndTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + hideTime
    else
        self._tempHideEndTime = nil
    end
    self:Refresh()
end

function CityTileAssetNpcBubbleCommon:OnCityElementNpcBubbleRangeEventUpdate(cityUid, idMap)
    if cityUid ~= self.tileView.tile:GetCity().uid then return end
    if idMap[self._elementId] == nil then return end
    self:Refresh()
end

function CityTileAssetNpcBubbleCommon:SetupTreasureProgress(add)
    if not self._treasureProgressTick and add then
        self._treasureProgressTick = true
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.TickTreasureProgress))
    elseif self._treasureProgressTick and not add then
        self._treasureProgressTick = false
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TickTreasureProgress))
    end
end

function CityTileAssetNpcBubbleCommon:TickTreasureProgress(dt)
    if not self._treasureProgress then return end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local endTime = self._treasureProgress.endTime
    if endTime < nowTime then
        self._bubble:UpdateProgress(1)
        self:SetupTreasureProgress(false)
        self._treasureProgress = nil
    else
        local duration = self._treasureProgress.duration
        local progress = math.inverseLerp(endTime - duration, endTime, nowTime)
        self._bubble:UpdateProgress(progress)
    end
end

function CityTileAssetNpcBubbleCommon:TickTempHide(dt)
    if not self._tickTempHide then return end
    if not self._tempHideEndTime or self._tempHideEndTime < g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() then
        self._tempHideEndTime = nil
        self:SetupTempHideTimer(false)
        self:Refresh()
    end
end

function CityTileAssetNpcBubbleCommon:SetupTempHideTimer(add)
    if not self._tickTempHide and add then
        self._tickTempHide = true
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.TickTempHide))
    elseif self._tickTempHide and not add then
        self._tickTempHide = false
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TickTempHide))
    end
end

function CityTileAssetNpcBubbleCommon:SetupFirstRechargeProgress(add)
    if not self._firstRechargeProgressTick and add then
        self._firstRechargeProgressTick = true
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.TickFirstRechargeProgress))
        g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecTickFirstRechargeProgress))
    elseif self._firstRechargeProgressTick and not add then
        self._firstRechargeProgressTick = false
        g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecTickFirstRechargeProgress))
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.TickFirstRechargeProgress))
    end
end

function CityTileAssetNpcBubbleCommon:TickFirstRechargeProgress(dt)
    if not self._firstRechargeProgress then return end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local startTime = self._firstRechargeProgress.startTime
    local endTime = self._firstRechargeProgress.endTime
    if endTime < nowTime then
        self._bubble:UpdateProgress(0)
        self:SetupFirstRechargeProgress(false)
        self._firstRechargeProgressEndTime = nil
    else
        local progress = 1 - (nowTime - startTime) / (endTime - startTime)
        self._bubble:UpdateProgress(progress)
        self._bubble.p_bubble:SetActive(false) -- todo 看看是什么把p_bubble显示出来了
    end
end

function CityTileAssetNpcBubbleCommon:SecTickFirstRechargeProgress()
    if not self._firstRechargeProgress then return end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local endTime = self._firstRechargeProgress.endTime
    self._bubble:ShowTimeText(TimeFormatter.SimpleFormatTime(endTime - nowTime))
end

-- 偶现雷达气泡点击事件被莫名注销的情况，先加个Tick
function CityTileAssetNpcBubbleCommon:TickSetTrigger()
    if self._bubble and self._radarTask and self._bubble.callback == nil then
        self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickIcon), nil)
    end
end

function CityTileAssetNpcBubbleCommon:StopTimer()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end

return CityTileAssetNpcBubbleCommon