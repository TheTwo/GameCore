local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local DBEntityPath = require("DBEntityPath")
local ArtResourceConsts = require("ArtResourceConsts")
local ArtResourceUtils = require("ArtResourceUtils")
local Utils = require("Utils")
local CityTilePriority = require("CityTilePriority")
local NpcServiceType = require("NpcServiceType")
local ColorConsts = require("ColorConsts")
local NpcServiceObjectType = require("NpcServiceObjectType")
local NumberFormatter = require("NumberFormatter")
local AudioConsts = require("AudioConsts")
local UIMediatorNames = require('UIMediatorNames')
local CityTileAssetBubble = require("CityTileAssetBubble")

---@class CityTileAssetNpcCommitItemBubble:CityTileAssetBubble
---@field new fun():CityTileAssetNpcCommitItemBubble
---@field super CityTileAssetBubble
local CityTileAssetNpcCommitItemBubble = class('CityTileAssetNpcCommitItemBubble', CityTileAssetBubble)

function CityTileAssetNpcCommitItemBubble:ctor()
    CityTileAssetBubble.ctor(self)
    self.isUI = true
    ---@type CS.UnityEngine.GameObject
    self._go = nil
    ---@type City3DBubbleNeed
    self._bubble = nil
    self._inTimeline = false
    ---@type CS.UnityEngine.GameObject
    self._visibleRoot = nil
    self._inSelfCity = false
    ---@type NpcServiceConfigCell
    self._npcServiceConfig = nil
    ---@type number
    self._npcServiceId = nil
    ---@type wds.NpcService
    self._npcServiceData = nil
    ---@type table<number, fun()>
    self._itemCountUpdater = {}
    ---@type table<number, number>
    self._lakeItems = {}
    self._isPlayingLoopAni = false
    self._useMainAssetBoundForPos = false
end

function CityTileAssetNpcCommitItemBubble:OnTileViewInit()
    CityTileAssetBubble.OnTileViewInit(self)
    local tile = self.tileView.tile
    local city = tile:GetCity()
    self._inSelfCity = city:IsMyCity()
    self._cityCamera = city:GetCamera()
    self._showCheckTeamPosChange = false
    self._elementId = self.tileView.tile:GetCell().configId
    self._cityUid = city.uid
    local player = ModuleRefer.PlayerModule and ModuleRefer.PlayerModule:GetPlayer()
    self._playerId = city:IsMyCity() and player and player.ID or 0
    self._npcCfg = ConfigRefer.CityElementNpc:Find(ConfigRefer.CityElementData:Find(self._elementId):ElementId())

    ModuleRefer.PlayerServiceModule:AddServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.OnNpcServiceChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_FOG_UNLOCK_CHANGED, Delegate.GetOrCreate(self, self.OnFogStatusChanged))
    --g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_START, Delegate.GetOrCreate(self, self.OnTimelineStart))
    --g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_STOP, Delegate.GetOrCreate(self, self.OnTimelineEnd))
end

function CityTileAssetNpcCommitItemBubble:OnTileViewRelease()
    --g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_STOP, Delegate.GetOrCreate(self, self.OnTimelineEnd))
    --g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_START, Delegate.GetOrCreate(self, self.OnTimelineStart))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FOG_UNLOCK_CHANGED, Delegate.GetOrCreate(self, self.OnFogStatusChanged))
    ModuleRefer.PlayerServiceModule:RemoveServicesChanged(NpcServiceObjectType.CityElement, Delegate.GetOrCreate(self, self.OnNpcServiceChanged))
    CityTileAssetBubble.OnTileViewRelease(self)
end

function CityTileAssetNpcCommitItemBubble:GetPrefabName()
    if not self:CheckCanShow() then
        return string.Empty
    end
    if self:ShouldShow() then
        return ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_need)
    end
    return string.Empty
end

function CityTileAssetNpcCommitItemBubble:OnAssetLoaded(go, userdata)
    self._useMainAssetBoundForPos = false
    CityTileAssetBubble.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end
    local behaviour = go:GetLuaBehaviour("City3DBubbleNeed")
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
    self:DoRefreshBubble()
    self.tileView:AddBlackboardListener(self.tileView.Key.MainAssetBounds, Delegate.GetOrCreate(self, self.OnMainAssetBoundsChanged))
    self:RefreshTimelineHideShow()
end

function CityTileAssetNpcCommitItemBubble:OnAssetUnload(go, fade)
    self._useMainAssetBoundForPos = false
    for itemId, func in pairs(self._itemCountUpdater) do
        ModuleRefer.InventoryModule:RemoveCountChangeListener(itemId, func)
    end
    table.clear(self._itemCountUpdater)
    self.tileView:RemoveBlackboardListener(self.tileView.Key.MainAssetBounds, Delegate.GetOrCreate(self, self.OnMainAssetBoundsChanged))
    self._bubble = nil
    CityTileAssetBubble.OnAssetUnload(self, go, fade)
end

function CityTileAssetNpcCommitItemBubble:Refresh()
    local canShow = self:CheckCanShow()
    if not canShow then
        self:Hide()
        return
    end
    local shouldShow = self:ShouldShow()
    if not shouldShow then
        self:Hide()
    end
    if not self.handle then
        self:Show()
    elseif self._bubble then
        self:DoRefreshBubble()
        self:RefreshTimelineHideShow()
    end
end

function CityTileAssetNpcCommitItemBubble:ShouldShow()
    self._npcServiceConfig = nil
    self._npcServiceId = nil
    self._npcServiceData = nil
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
    if city:IsInSingleSeExplorerMode() and self._npcCfg:NoInteractableInSEExplore() then
        return false
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
    if not explorerMgr then
        return false
    end
    local npcData = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[self._elementId]
    if not npcData then
        return false
    end
    if ModuleRefer.PlayerServiceModule:IsAllServiceCompleteOnNpc(npcData, true) then
        return false
    end
    local isOnlyCommit, serviceId, _,npcServiceConfigCell  = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(npcData, NpcServiceType.CommitItem)
    if not isOnlyCommit or not npcServiceConfigCell then
        return false
    end
    self._npcServiceId = serviceId
    self._npcServiceConfig = npcServiceConfigCell
    self._npcServiceData = npcData
    return true
end

---@param city MyCity
function CityTileAssetNpcCommitItemBubble:OnFogStatusChanged(city)
    if not self._cityUid or not city or self._cityUid ~= city.uid then
        return
    end
    self:Refresh()
end

--function CityTileAssetNpcCommitItemBubble:OnTimelineStart()
--    self._inTimelineHide = true
--    self:RefreshTimelineHideShow()
--end
--
--function CityTileAssetNpcCommitItemBubble:OnTimelineEnd()
--    self._inTimelineHide = false
--    self:RefreshTimelineHideShow()
--end

function CityTileAssetNpcCommitItemBubble:RefreshTimelineHideShow()
    if Utils.IsNotNull(self._visibleRoot) then
        self._visibleRoot:SetVisible(not self._inTimelineHide)
        if not self._inTimelineHide then
            self._bubble:PlayLoopAnim()
        end
    else
        if self._isPlayingLoopAni then
            self._bubble:PlayLoopAnim()
        end
    end
end

---@param entity wds.Player
---@param changedData table
function CityTileAssetNpcCommitItemBubble:OnNpcServiceChanged(entity, changedData)
    if entity.ID ~= self._playerId or not changedData then
        return
    end
    ---@type table<number, wds.NpcServiceGroup>
    local AddMap = changedData.Add
    ---@type table<number, wds.NpcServiceGroup>
    local RemoveMap = changedData.Remove
    if (AddMap and AddMap[self._elementId]) or (RemoveMap and RemoveMap[self._elementId]) then
        self:Refresh()
    elseif changedData[self._elementId] then
        self:Refresh()
    end
end

---@param index number
---@param item City3DBubbleNeedItem
---@param userdata {i:number,c:number}
function CityTileAssetNpcCommitItemBubble:OnClickIcon(index, item, userdata)
    if self._npcCfg:Id() == ConfigRefer.CityConfig:RescueBeauty() then
        g_Game.UIManager:Open(UIMediatorNames.HeroRescueMediator)
        return
    end
    local InventoryModule = ModuleRefer.InventoryModule
    --if userdata and InventoryModule:GetAmountByConfigId(userdata.i) < userdata.c then
    --    InventoryModule:OpenExchangePanel({{id=userdata.i, num=userdata.c}})
    --    return true
    --end
    local openPanel = {}
    for itemId, lakeCount in pairs(self._lakeItems) do
        if InventoryModule:GetAmountByConfigId(itemId) < lakeCount then
            table.insert(openPanel, {id=itemId,num=lakeCount})
        end
    end
    if #openPanel > 0 then
        InventoryModule:OpenExchangePanel(openPanel)
        return true
    end
    
    local tile = self.tileView.tile
    local city = tile:GetCity()
    local cell = tile:GetCell()
    local eleConfig = ConfigRefer.CityElementData:Find(cell.configId)
    local elePos = eleConfig:Pos()
    local npcConfig = ConfigRefer.CityElementNpc:Find(eleConfig:ElementId())
    local pos = city:GetElementNpcInteractPos(elePos:X(), elePos:Y(), npcConfig)--CityTileAssetBubble.SuggestCellCenterPositionWithHeight(city, cell, 0, true)

    ---@type ClickNpcEventContext
    local context = {}
    context.cityUid = city.uid
    context.elementConfigID = cell.configId
    context.targetPos = pos
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, context)
    g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
    return true
end

function CityTileAssetNpcCommitItemBubble:GetPriorityInView()
    return CityTilePriority.BUBBLE - CityTilePriority.NPC
end

---@param key string
---@param value CS.UnityEngine.Bounds
function CityTileAssetNpcCommitItemBubble:OnMainAssetBoundsChanged(key, value)
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

function CityTileAssetNpcCommitItemBubble:DoRefreshBubble()
    self._isPlayingLoopAni = true
    local InventoryModule = ModuleRefer.InventoryModule
    for itemId, func in pairs(self._itemCountUpdater) do
        InventoryModule:RemoveCountChangeListener(itemId, func)
    end
    table.clear(self._itemCountUpdater)
    table.clear(self._lakeItems)
    self._bubble:Reset()
    local showDanger = self:IsPolluted()
    local tradeModule = ModuleRefer.StoryPopupTradeModule
    local serviceInfo = tradeModule:GetServicesInfo(NpcServiceObjectType.CityElement, self._elementId, self._npcServiceId)
    local needItems = tradeModule:GetNeedItems(self._npcServiceId)
    local ConfigItem = ConfigRefer.Item
    local idx = 1
    for _, v in pairs(needItems) do
        local itemId = v.id
        local count = v.count
        local addCount = serviceInfo[itemId] or 0
        local lakeCount = math.max(0, count - addCount)
        local itemConfig = ConfigItem:Find(itemId)
        local icon = itemConfig and itemConfig:Icon() or string.Empty
        local countTxt
        local showCheck = false
        if lakeCount > 0 then
            self._lakeItems[itemId] = lakeCount
            local hasCount = InventoryModule:GetAmountByConfigId(itemId)
            if hasCount < lakeCount then
                self._isPlayingLoopAni = false
                countTxt = ("<color=%s>%s</color>/%s"):format(ColorUtil.FromGammaStrToLinearStr(ColorConsts.warning),NumberFormatter.NumberAbbr(hasCount, true) ,NumberFormatter.NumberAbbr(lakeCount, true))
            else
                showCheck = true
                countTxt = ("<color=%s>%s</color>/%s"):format(ColorUtil.FromGammaStrToLinearStr(ColorConsts.quality_green),NumberFormatter.NumberAbbr(hasCount, true),NumberFormatter.NumberAbbr(lakeCount, true))
            end
            local cellIndex = idx
            local updateCount = function()
                local nowCount = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
                local text
                if nowCount < lakeCount then
                    text = ("<color=%s>%s</color>/%s"):format(ColorUtil.FromGammaStrToLinearStr(ColorConsts.warning),NumberFormatter.NumberAbbr(nowCount, true),NumberFormatter.NumberAbbr(lakeCount, true))
                else
                    if self._isPlayingLoopAni ~= true then
                        self._isPlayingLoopAni = true
                        self:RefreshTimelineHideShow()
                    end
                    text = ("<color=%s>%s</color>/%s"):format(ColorUtil.FromGammaStrToLinearStr(ColorConsts.quality_green),NumberFormatter.NumberAbbr(nowCount, true),NumberFormatter.NumberAbbr(lakeCount, true))
                end
                self._bubble:UpdateCustom(cellIndex, icon, text, nowCount >= lakeCount, {i=itemId, c=lakeCount})
            end
            self._itemCountUpdater[itemId] = updateCount
            InventoryModule:AddCountChangeListener(itemId, updateCount)
        else
            showCheck = true
            countTxt = ("%s"):format(count)
        end
        self._bubble:AppendCustom(icon, countTxt, showCheck, {i=itemId, c=lakeCount})
        idx = idx +1
    end
    self._bubble:ShowDangerImg(showDanger)
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickIcon), self.tileView.tile)
end

function CityTileAssetNpcCommitItemBubble:IsPolluted()
    local cell = self.tileView.tile:GetCell()
    if cell == nil then return false end
    return self:GetCity().elementManager:IsPolluted(cell.configId)
end

return CityTileAssetNpcCommitItemBubble