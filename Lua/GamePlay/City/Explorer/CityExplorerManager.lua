local CityManagerBase = require("CityManagerBase")
local UnitMoveManager = require("UnitMoveManager")
local UnitCitizenConfigWrapper = require("UnitCitizenConfigWrapper")
local ConfigRefer = require("ConfigRefer")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local CityUnitPathLine = require("CityUnitPathLine")
local DBEntityPath = require("DBEntityPath")
local DBEntityType = require("DBEntityType")
local ModuleRefer = require("ModuleRefer")
local CityExplorerStateDefine = require("CityExplorerStateDefine")
local CityExplorerTeam = require("CityExplorerTeam")
local BuildingType = require("BuildingType")
local SLGConst_Manual = require("SLGConst_Manual")
--local CastleUpdateSquadParameter = require("CastleUpdateSquadParameter")
local CastleGetTreasureParameter = require("CastleGetTreasureParameter")
local CityPathFindingUtils = require("CityPathFindingUtils")
local CastleUnlockZoneParameter = require("CastleUnlockZoneParameter")
local UIMediatorNames = require("UIMediatorNames")
local StoryDialogUIMediatorParameter = require("StoryDialogUIMediatorParameter")
local StoryDialogUIMediatorParameterChoiceProvider = require("StoryDialogUIMediatorParameterChoiceProvider")
local CityNpcType = require("CityNpcType")
local I18N = require("I18N")
local CityUtils = require("CityUtils")
local TimerUtility = require("TimerUtility")
local CityConst = require("CityConst")
local CityCitizenDefine = require("CityCitizenDefine")
local StoryDialogUiOptionCellType = require("StoryDialogUiOptionCellType")
local NpcServiceType = require("NpcServiceType")
local NpcServiceUnlockCondType = require("NpcServiceUnlockCondType")
local TaskRewardType = require("TaskRewardType")
local CityElementType = require("CityElementType")
local TouchMenuCellTextDatum = require("TouchMenuCellTextDatum")
local TouchMenuMainBtnDatum = require("TouchMenuMainBtnDatum")
local TouchMenuHelper = require("TouchMenuHelper")
local TouchMenuPageDatum = require("TouchMenuPageDatum")
local TouchMenuUIDatum = require("TouchMenuUIDatum")
local SEHudTroopMediatorDefine = require("SEHudTroopMediatorDefine")
local SLGTouchInjectedSelectedTarget = require("SLGTouchInjectedSelectedTarget")
local TouchMenuBasicInfoDatumSe = require("TouchMenuBasicInfoDatumSe")
local TouchMenuCellResourceDatum = require("TouchMenuCellResourceDatum")
local TouchMenuButtonTipsData = require("TouchMenuButtonTipsData")
local TouchMenuCellPairDatum = require("TouchMenuCellPairDatum")
local TouchMenuCellPairTimeDatum = require("TouchMenuCellPairTimeDatum")
local TMCellResourceDatumUnit = require("TMCellResourceDatumUnit")
local GuideUtils = require("GuideUtils")
local ArtResourceUtils = require("ArtResourceUtils")
local OnChangeHelper = require("OnChangeHelper")
local NpcLockedGotoProvider = require("NpcLockedGotoProvider")
local RPPType = require('RPPType')
local SlgBattlePowerHelper = require('SlgBattlePowerHelper')
local StoryDialogType = require("StoryDialogType")
local UIHelper = require("UIHelper")
local ConfigTimeUtility = require("ConfigTimeUtility")
local NpcServiceObjectType = require("NpcServiceObjectType")
local CityTileViewNpc = require("CityTileViewNpc")
local CityTileAssetNpcBubbleCommon = require("CityTileAssetNpcBubbleCommon")
local Utils = require("Utils")
local CityExplorerTeamDefine = require("CityExplorerTeamDefine")
local HomeSeInExploreParameter = require("HomeSeInExploreParameter")
local CreateHomeSeTroopParameter = require("CreateHomeSeTroopParameter")
local RecallHomeSeTroopParameter = require("RecallHomeSeTroopParameter")
local ReSetHomeSeTroopExpectSpawnerIdParameter = require("ReSetHomeSeTroopExpectSpawnerIdParameter")
local SlgUtils = require("SlgUtils")
local HUDSelectTroopList = require("HUDSelectTroopList")
local HUDTroopUtils = require("HUDTroopUtils")
local TouchMenuCellSeMonsterDatum = require("TouchMenuCellSeMonsterDatum")
local TouchMenuCellRewardDatum = require("TouchMenuCellRewardDatum")

local Color = CS.UnityEngine.Color


---@class CityExplorerData
---@field Id number
---@field Config UnitCitizenConfigWrapper
---@field InitPos CS.UnityEngine.Vector3 @ can nil
---@field HeroConfigId number

---@class CityExplorerManager:CityManagerBase
---@field new fun(city:MyCity, ...):CityExplorerManager
local CityExplorerManager = class('CityExplorerManager', CityManagerBase)

---@param city MyCity
function CityExplorerManager:ctor(city, ...)
    CityManagerBase.ctor(self, city, ...)
    self._hideAndPause = false
    self._playId = ModuleRefer.PlayerModule.playerId
    ---@type table<number, CityExplorerTeam>
    self._teams = {}
    ---@type table<number, CS.UnityEngine.Vector3>
    self._teamsCachedPos = {}
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
    self._goCreator = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper.Create("CityExplorerManager")

    ---@type table<number, CS.DragonReborn.Utilities.FindSmoothAStarPathHelper.PathHelperHandle>
    self._lastPathFindingHandleMap = {}
    self._flagToCreateExplorerTeam = false
    self.SLGTouchInjectedSelectedTarget = SLGTouchInjectedSelectedTarget.new(city)
    self._cacheNpcIdSet = {}
    self._lastCacheNpcIdSet = {}
    ---@type table<number, {duration:number, endTime:number, targetId:number}>
    self._tTickTreasureProgress = {}
    ---@type {presetIndex:number, targetPos:CS.UnityEngine.Vector3, elementConfigID:number, interactEndAction:CityExplorerTeamDefine.InteractEndAction}[]
    self._tickWaitTeamPosReady = {}
    self._allowShowLines = true
    self._teamTroopTriggerOn = true
    self._inBattleSpawnerMap = {}
    ---@type table<number, boolean>
    self._inRangeNpcMap = {}
    self._inRangeNpcChangedMap = {}
    ---@type CS.DragonReborn.RangeEventMgr
    self._singleExploreRangeEventMgr = nil
end

function CityExplorerManager:AddEvents()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, Delegate.GetOrCreate(self, self.OnClickNpc))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_SPAWNER_CLICK_TRIGGER, Delegate.GetOrCreate(self, self.OnClickSpawner))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_NPC_CLICK_GET_TREASURE, Delegate.GetOrCreate(self, self.OnCollectNpcTreasure))
    g_Game.EventManager:AddListener(EventConst.CITY_ELEMENT_CREEP_CLICK, Delegate.GetOrCreate(self, self.OnClickCreep))
    g_Game.EventManager:AddListener(EventConst.CITY_ORDER_EXPLORER_TEAM_INTERACT_TARGET, Delegate.GetOrCreate(self, self.OnInteractCityElement))
    g_Game.EventManager:AddListener(EventConst.CITY_ORDER_EXPLORER_TEAM_ZONE_CLICK, Delegate.GetOrCreate(self, self.OnClickZone))
    g_Game.EventManager:AddListener(EventConst.CITY_TRY_UNLOCK_ZONE, Delegate.GetOrCreate(self, self.OnTryUnlockZone))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.CheckAndBroadcastTeamPositionChanged))
    g_Game.DatabaseManager:AddEntityNewByType(DBEntityType.Hero, Delegate.GetOrCreate(self, self.OnSeHeroCreate))
    g_Game.DatabaseManager:AddEntityDestroyByType(DBEntityType.Hero, Delegate.GetOrCreate(self, self.OnSeHeroDestroyed))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnCityElementBatchEvt))
    self._singleExploreRangeEventMgr = CS.DragonReborn.RangeEventMgr(self._inRangeNpcMap, self._inRangeNpcChangedMap)
    if UNITY_DEBUG and UNITY_EDITOR then
        g_Game:AddOnDrawGizmos(Delegate.GetOrCreate(self, self.OnDebugGizmos))
    end
end

function CityExplorerManager:RemoveEvents()
    if UNITY_DEBUG and UNITY_EDITOR then
        g_Game:RemoveOnDrawGizmos(Delegate.GetOrCreate(self, self.OnDebugGizmos))
    end
    self._singleExploreRangeEventMgr:Dispose()
    self._singleExploreRangeEventMgr = nil
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnCityElementBatchEvt))
    g_Game.DatabaseManager:RemoveEntityDestroyByType(DBEntityType.Hero, Delegate.GetOrCreate(self, self.OnSeHeroDestroyed))
    g_Game.DatabaseManager:RemoveEntityNewByType(DBEntityType.Hero, Delegate.GetOrCreate(self, self.OnSeHeroCreate))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.CheckAndBroadcastTeamPositionChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ORDER_EXPLORER_TEAM_ZONE_CLICK, Delegate.GetOrCreate(self, self.OnClickZone))
    g_Game.EventManager:RemoveListener(EventConst.CITY_TRY_UNLOCK_ZONE, Delegate.GetOrCreate(self, self.OnTryUnlockZone))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ORDER_EXPLORER_TEAM_INTERACT_TARGET, Delegate.GetOrCreate(self, self.OnInteractCityElement))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_NPC_CLICK_GET_TREASURE, Delegate.GetOrCreate(self, self.OnCollectNpcTreasure))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_NPC_CLICK_TRIGGER, Delegate.GetOrCreate(self, self.OnClickNpc))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_SPAWNER_CLICK_TRIGGER, Delegate.GetOrCreate(self, self.OnClickSpawner))
    g_Game.EventManager:RemoveListener(EventConst.CITY_ELEMENT_CREEP_CLICK, Delegate.GetOrCreate(self, self.OnClickCreep))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.ScenePlayer.ScenePlayerPreset.PresetList.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetChanged))
end

---@param entity wds.ScenePlayer
function CityExplorerManager:OnTroopPresetChanged(entity, _)
    if not entity or entity.Owner.PlayerID ~= ModuleRefer.PlayerModule:GetPlayerId() then
        return
    end
    self:DoOnTroopPresetChanged()
end

function CityExplorerManager:DoOnTroopPresetChanged()
    self._inBattleSpawnerMap = {}
    ---@type wds.ScenePlayer[]
    local scenePlayers = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.ScenePlayer)
    if not scenePlayers then return end
    local myPlayerId = ModuleRefer.PlayerModule:GetPlayerId()
    local needKeepTeam = {}
    ---@type table<number, SEHero[]>
    local seUnitHeroes = {}
    if self.city.citySeManger._seEnvironment then
        local unitMgr = self.city.citySeManger._seEnvironment:GetUnitManager()
        if unitMgr then
            for _, seHero in pairs(unitMgr:GetHeroList()) do
                ---@type wds.Hero
                local entity = seHero:GetEntity()
                if entity and entity.Owner.PlayerID == myPlayerId then
                    local presetList = seUnitHeroes[entity.BasicInfo.PresetIndex]
                    if not presetList then
                        presetList = {}
                        seUnitHeroes[entity.BasicInfo.PresetIndex] = presetList
                    end
                    table.insert(presetList, seHero)
                end
            end
        end
    end
    for _, player in pairs(scenePlayers) do
        if player.Owner.PlayerID ~= myPlayerId then
            goto continue
        end
        local presetList = player.ScenePlayerPreset.PresetList
        if not presetList then
            goto continue
        end
        for _, info in pairs(presetList) do
            local team = self._teams[info.PresetIndex]
            if not team then
                team = CityExplorerTeam.new()
                self._teams[info.PresetIndex] = team
                team:Spawn(self, info.PresetIndex, player.ID)
                team:AddEvents()
                team:SetHideAndPause(self._hideAndPause)
                if seUnitHeroes[info.PresetIndex] then
                    for _, unit in pairs(seUnitHeroes[info.PresetIndex]) do
                        team:OnHeroCreate(unit)
                    end
                end
                team:WaitForSync()
                team:SyncFromData()
                team:SetAllowShowLine(self._allowShowLines)
                team:SetupSlgTroopTrigger(self._teamTroopTriggerOn)
                g_Game.TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_CREATE, team._teamPresetIdx, team)
            end
            needKeepTeam[info.PresetIndex] = true
        end
        ::continue::
    end
    for presetIndex, team in pairs(self._teams) do
        if not needKeepTeam[presetIndex] then
            team:RemoveEvents()
            team:Release()
            self._teams[presetIndex] = nil
            for i = #self._tickWaitTeamPosReady, 1,-1 do
                if self._tickWaitTeamPosReady[i].presetIndex == presetIndex then
                    table.remove(self._tickWaitTeamPosReady, i)
                end
            end
            g_Game.TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_DESTROY, presetIndex)
        end
    end
end

---@param evtInfo {Event:string, Add:table<number, boolean>, Remove:table<number, boolean>, Change:table<number, boolean>}
function CityExplorerManager:OnCityElementBatchEvt(city, evtInfo)
    if not city or city ~= self.city or not self.city:IsMyCity() or not evtInfo then
        return
    end
    local CityElementData = ConfigRefer.CityElementData
    if evtInfo.Add then
        for id, v in pairs(evtInfo.Add) do
            if v then
                local c = CityElementData:Find(id)
                if c and c:Type() == CityElementType.Npc then
                    self:RebuildNpcIdSet(self.city.elementManager.eleNpcHashMap)
                    return
                end
            end
        end
    end
    if evtInfo.Remove then
        for id, v in pairs(evtInfo.Remove) do
            if v then
                local c = CityElementData:Find(id)
                if c and c:Type() == CityElementType.Npc then
                    self:RebuildNpcIdSet(self.city.elementManager.eleNpcHashMap)
                    return
                end
            end
        end
    end
end

---@param elementStatus table<number, CityElementNpc>
function CityExplorerManager:RebuildNpcIdSet(elementStatus)
    self._cacheNpcIdSet,self._lastCacheNpcIdSet = self._lastCacheNpcIdSet,self._cacheNpcIdSet
    table.clear(self._cacheNpcIdSet)
    local CityElementData = ConfigRefer.CityElementData
    for id, v in pairs(elementStatus) do
        local c = CityElementData:Find(v.configId)
        if c and c:Type() == CityElementType.Npc then
            local npcCfgID = c:ElementId()
            if self._cacheNpcIdSet[npcCfgID] then
                g_Logger.Error("重复的npc id:%s, %s -> :%s", npcCfgID, self._cacheNpcIdSet[npcCfgID], id)
            end
            self._cacheNpcIdSet[npcCfgID] = id
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_ID_CACHE_REFRESH, self.city.uid ,self._lastCacheNpcIdSet, self._cacheNpcIdSet)
end

function CityExplorerManager:OnViewLoadFinish()
    self:AddEvents()
    self:RebuildNpcIdSet(self.city.elementManager.eleNpcHashMap)
    self:DoOnTroopPresetChanged()
end

function CityExplorerManager:DoViewUnload()
    for _, v in pairs(self._lastPathFindingHandleMap) do
        v:Release()
    end
    table.clear(self._lastPathFindingHandleMap)
    self:ClearAllCreateExplorers()
    self._goCreator:DeleteAll()
end

function CityExplorerManager:OnViewUnloadStart()
    self:RemoveEvents()
end

function CityExplorerManager:OnCityActive()
    self:CreateExplorers()
end

function CityExplorerManager:OnCityInactive()
    self:ClearAllCreateExplorers()
end

function CityExplorerManager:CreateExplorers()
    self._flagToCreateExplorerTeam = true
    self:DoCreateExplorers()
end

function CityExplorerManager:DoCreateExplorers()
    if not self._flagToCreateExplorerTeam then
        return
    end
    self._flagToCreateExplorerTeam = false
    self:DoOnTroopPresetChanged()
    if self.city and self.city:IsMyCity() then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_STATUES_UPDATE, self.city.uid)
    end
end

function CityExplorerManager:ClearAllCreateExplorers()
    self._flagToCreateExplorerTeam = false
    for _, team in pairs(self._teams) do
        local presetIndex = team._teamPresetIdx
        team:RemoveEvents()
        team:Release()
        g_Game.TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_DESTROY, presetIndex)
    end
    table.clear(self._teams)
end

function CityExplorerManager:SetHideAndPause(isHideAndPause)
    self._hideAndPause = isHideAndPause
    for _, team in pairs(self._teams) do
        team:SetHideAndPause(isHideAndPause)
    end
end

function CityExplorerManager:OnCameraSizeChanged(_, _)
end

function CityExplorerManager:Tick(deltaTimeSec)
    if self._hideAndPause then
        return
    end
    self:DoCreateExplorers()
    for _, team in pairs(self._teams) do
        team:Tick(deltaTimeSec)
    end
    local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    for elementId, delayInfo in pairs(self._tTickTreasureProgress) do
        if delayInfo.endTime <= nowTime then
            self._tTickTreasureProgress[elementId] = nil
            self:OnCollectNpcTreasure(self.city.uid, elementId)
        end
    end
    for index = #self._tickWaitTeamPosReady, 1,-1 do
        local content = self._tickWaitTeamPosReady[index]
        local team = self:GetTeamByPresetIndex(content.presetIndex)
        if team then
            local teamPos = team:GetPosition()
            if teamPos then
                table.remove(self._tickWaitTeamPosReady, index)
                self:DoContinueGoToNpcWithTeam(team._teamPresetIdx, teamPos, content.targetPos, content.elementConfigID, content.interactEndAction)
            end
        end
    end
    if self._singleExploreRangeEventMgr and self:NeedTickExploreRangeInCityState() then
        table.clear(self._inRangeNpcChangedMap)
        self._singleExploreRangeEventMgr:GetChangedResult()
        if not table.isNilOrZeroNums(self._inRangeNpcChangedMap) then
            local eleIdMap = {}
            for id, value in pairs(self._inRangeNpcChangedMap) do
                eleIdMap[id] = value
            end
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_BUBBLE_RANGE_EVENT_UPDATE, self.city.uid, eleIdMap)
        end
        local team = self:GetCurrentExploreModeSETeam()
        local teamPos = team and team:GetFormationCenterPos()
        if teamPos then
            self._singleExploreRangeEventMgr:AddOrUpdateMoveAgent(teamPos)
        else
            self._singleExploreRangeEventMgr:RemoveMoveAgent()
        end
        self._singleExploreRangeEventMgr:Update()
    end
end

---@return CS.UnityEngine.Vector3,wds.Vector2F
function CityExplorerManager:GetTeamPosition()
    for _, team in pairs(self._teams) do
        if team:HasHero() then
            local pos = team:GetPosition()
            if pos then
                local coordX,coordY = self.city:GetCoordFromPosition(pos, true)
                return pos, wds.Vector2F.New(coordX,coordY)
            end
        end
    end
    return nil,nil
end

---@return SETeam
function CityExplorerManager:GetCurrentExploreModeSETeam()
    local seEnvironment = self.city.citySeManger._seEnvironment
    if not seEnvironment then return nil end
    local teamMgr = seEnvironment:GetTeamManager()
    if not teamMgr then return nil end
    return teamMgr:GetOperatingTeam()
end

---@return table<number, CS.UnityEngine.Vector3>
function CityExplorerManager:GetTeamsPosition()
    return self._teamsCachedPos
end

---@param worldPos CS.UnityEngine.Vector3
---@return CS.UnityEngine.Vector3,wds.Vector2F,CityExplorerTeam
function CityExplorerManager:GetNearestIdleTeamAndPosition(worldPos, targetId, forceSelectOneIf)
    local choose = nil
    local distance = nil
    local choosePos = nil
    local ignoreTargetCheck = nil
    local ignoreTargetCheckDistance = nil
    local ignoreTargetCheckChoosePos = nil
    for _, team in pairs(self._teams) do
        if team:InExplore() or team:IsInBattle() then
            goto continue
        end
        if not team:HasHero() then
            goto continue
        end
        local pos = team:GetPosition()
        if not pos then
            goto continue
        end
        local dx
        local dy
        local d
        if forceSelectOneIf then
            dx,dy = math.abs(pos.x - worldPos.x), math.abs(pos.z - worldPos.z)
            d = dx * dx + dy * dy
            if not ignoreTargetCheck then
                ignoreTargetCheck = team
                ignoreTargetCheckDistance = d
                ignoreTargetCheckChoosePos = pos
            else
                if d < ignoreTargetCheckDistance then
                    ignoreTargetCheckDistance = d
                    ignoreTargetCheck = team
                    ignoreTargetCheckChoosePos = pos
                end
            end
        end
        if team._teamData:HasTarget() then
            if targetId and team._teamData._targetId == targetId then
                choose = team
                choosePos = pos
                break
            end
            if not team._teamData:IsTargetGround() then
                goto continue
            end
        end
        if not forceSelectOneIf then
            dx,dy = math.abs(pos.x - worldPos.x), math.abs(pos.z - worldPos.z)
            d = dx * dx + dy * dy
        end
        if not choose then
            choose = team
            distance = d
            choosePos = pos
        else
            if d < distance then
                distance = d
                choose = team
                choosePos = pos
            end
        end
        ::continue::
    end
    if choosePos then
        local coordX,coordY = self.city:GetCoordFromPosition(choosePos, true)
        return choosePos, wds.Vector2F.New(coordX,coordY),choose
    elseif ignoreTargetCheck then
        local coordX,coordY = self.city:GetCoordFromPosition(ignoreTargetCheckChoosePos, true)
        return ignoreTargetCheckChoosePos, wds.Vector2F.New(coordX,coordY),ignoreTargetCheck
    end
    return nil, nil, nil
end

function CityExplorerManager:GetAnyTeamTargetCityCoord()
    local seEnvironment = self.city.citySeManger._seEnvironment
    if not seEnvironment then return nil,nil end
    local mapInfo = seEnvironment:GetMapInfo()
    if Utils.IsNull(mapInfo) then return nil,nil end
    for _, team in pairs(self._teams) do
        if team:HasHero() and team._teamData:HasTarget() and team._teamData:HasTarget() then
            local path = team:GetCurrentMovePath()
            if path then
                local p = path[#path]
                local v3Pos = CS.UnityEngine.Vector3(p.X, p.Y, p.Z)
                local pos = mapInfo:ServerPos2Client(v3Pos)
                local coordX,coordY = self.city:GetCoordFromPosition(pos, true)
                return pos, wds.Vector2F.New(coordX,coordY)
            end
        end
    end
    return nil,nil
end

function CityExplorerManager:SetTeamSelected(isSelected)
    --self._team:SetShowSelected(isSelected)
end

function CityExplorerManager:ShowPopUpMenu(context,callback)
    local cityElementCfg
    local elementCfg = ConfigRefer.CityElementData:Find(context.elementConfigID)
    local elementType = elementCfg:Type()
    local elementId = elementCfg:ElementId()
    if elementType == CityElementType.Npc then
        cityElementCfg = ConfigRefer.CityElementNpc:Find(elementId)
    elseif elementType == CityElementType.Spawner then
        cityElementCfg = ConfigRefer.CityElementSpawner:Find(elementId)
    else
        if callback then
            callback()
        end
        return
    end
    local displayData = cityElementCfg:DisplayData()
    if not displayData or displayData <= 0 then
        if callback then
            callback()
        end
        return
    end

    local cfg = ConfigRefer.CityElementDisplayData:Find(displayData)
    local basicInfo = TouchMenuBasicInfoDatumSe.new()
    local img = cfg:Portrait()
    local descArgs = {}
	for i = 1, cfg:DescArgsLength() do
		descArgs[i] = I18N.Get(cfg:DescArgs(i))
	end
    local desc = I18N.GetWithParamList(cfg:Desc(), descArgs)
    basicInfo:SetName(I18N.Get(cfg:Name()))
    basicInfo:SetDesc(desc)
    if img and img ~= "" then
        basicInfo:SetImage(img)
    end

    local btn = TouchMenuMainBtnDatum.new()
    btn.onClick = function()
        g_Game.UIManager:CloseByName(UIMediatorNames.TouchMenuUIMediator)
        callback()
    end
    btn.label = I18N.Get(cfg:BtnDesc())
    local btnGroup = TouchMenuHelper.GetRecommendButtonGroupDataArray({btn})
    local uiDatum = TouchMenuHelper.GetSinglePageUIDatum(basicInfo, {}, btnGroup):SetPos(context.targetPos,1,1):SetClickEmptyClose(true)
    g_Game.UIManager:Open(UIMediatorNames.TouchMenuUIMediator, uiDatum)
end
---@param context ClickNpcEventContext
function CityExplorerManager:OnClickNpc(context)
    if self.city:IsInSingleSeExplorerMode() then
        self:OnConfirmNpc(context)
    else
        self:ShowPopUpMenu(context,function()
            self:OnConfirmNpc(context)
        end)
    end
end


---@class ClickNpcEventContext
---@field cityUid number
---@field elementConfigID number
---@field targetPos CS.UnityEngine.Vector3
---@field isClickCleanZoneFog boolean|nil
---@field disallowCheckToast boolean|nil
---@field selectedTroop number|nil
---@field selectedTroopPresetIdx number|nil
---@field isDragMoveToTarget boolean

---@param context ClickNpcEventContext
function CityExplorerManager:OnConfirmNpc(context)
    local cityUid = context.cityUid
    local elementConfigID = context.elementConfigID
    local targetPos = context.targetPos
    local isClickCleanZoneFog = context.isClickCleanZoneFog
    local disallowCheckToast = context.disallowCheckToast
    local selectedTroop = context.selectedTroop
    local selectedTroopPresetIdx = context.selectedTroopPresetIdx

    if cityUid ~= self.city.uid then
        return
    end
    if not selectedTroopPresetIdx and self.city:IsInSingleSeExplorerMode() then
        ---@type CityStateSeExplorerFocus
        local state = self.city.stateMachine:GetCurrentState()
        selectedTroopPresetIdx = state and state:GetCurrentPresetIndex()
        if selectedTroopPresetIdx then
            selectedTroopPresetIdx = selectedTroopPresetIdx + 1
        end
    end
    if isClickCleanZoneFog then
        if not self:CheckClickCleanZoneFog(not disallowCheckToast) then
            return
        end
    end
    --if not self:CheckRequireBuildingAndFurniture(not disallowCheckToast, isClickCleanZoneFog) then
    --    return
    --end
    local elementCfg = ConfigRefer.CityElementData:Find(elementConfigID)
    if not elementCfg then
        g_Logger.Error("elementConfigID:%s config is nil", elementConfigID)
        return
    end
    local npcCfg = ConfigRefer.CityElementNpc:Find(elementCfg:ElementId())
    if not npcCfg then
        g_Logger.Error("elementConfigID:%s npc:%s config is nil", elementConfigID, elementCfg:ElementId())
        return
    end
    if npcCfg:NoInteractable() then
        return
    end
    if npcCfg:Type() == CityNpcType.CitizenReceive then
        return
    end
    local isInSingleSeExplorerMode = self.city:IsInSingleSeExplorerMode()
    if isInSingleSeExplorerMode and npcCfg:NoInteractableInSEExplore() then
        return
    end
    local isOpenDoorNpc, openZoneId = self.city.zoneManager:IsSingleExplorerOpenNpcLink(elementConfigID)
    -- 在探索模式下 探索开门npc 点击就不用响应了
    if self.city:IsInSingleSeExplorerMode() then
        if isOpenDoorNpc then
            return
        end
    elseif isOpenDoorNpc then
        --- 开门npc 设计为探索中途退出 恢复的入口 若区域的迷雾没解 不能用
        local zone = self.city.zoneManager:GetZoneById(openZoneId)
        if not zone or zone:IsHideFogForExploring() then
            return
        end
        local uiParameter = self:BuildZoneCircleMenuInfo(zone, targetPos, nil, true)
        g_Game.UIManager:Open(UIMediatorNames.TouchMenuUIMediator, uiParameter)
        return
    end
    local noNeedTeam = false
    if npcCfg:NoNeedTeamInteract() then
        noNeedTeam = true
    end
    local teamPos
    ---@type CityExplorerTeam
    local team
    if not selectedTroop and not selectedTroopPresetIdx then
        local _
        teamPos,_,team = self:GetNearestIdleTeamAndPosition(targetPos, elementConfigID, false)
        if not noNeedTeam then
            if not self.city:IsInSingleSeExplorerMode() and not self.city:IsInSeBattleMode() then
                if npcCfg:Id() == ConfigRefer.CityConfig:RescueBeauty() then
                    g_Game.UIManager:Open(UIMediatorNames.HeroRescueMediator)
                    return
                end
                self:SelectPresetToNormalExplorTarget(elementConfigID, CityExplorerTeamDefine.InteractEndAction.ToIdleAndResetExpectSpawnerId)
            end
            return
        end
    else
        selectedTroopPresetIdx,selectedTroop = self:GetPresetIndexAndTroopId(selectedTroopPresetIdx, selectedTroop)
        for _, value in pairs(self._teams) do
            if (value._teamPresetIdx + 1) == selectedTroopPresetIdx then
                team = value
                break
            end
        end
        if team then
            teamPos = team:GetPosition()
        end
    end
    if not noNeedTeam and not teamPos then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("tips_troop_need_to_back"))
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_EXPLORER_RESPONSE_TO_NPC_CLICK, elementConfigID, targetPos)
        return
    end
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local preTask = npcCfg:Precondition()
    if preTask ~= 0 then
        local QuestModule = ModuleRefer.QuestModule
        if not QuestModule:IsInBitMap(preTask, player.PlayerWrapper.Task.FinishedBitMap) then
            g_Logger.Warn("前置任务条件不满足：%s, 跳过", preTask)
            local preTaskConfig = ConfigRefer.Task:Find(preTask)
            if preTaskConfig then
                local property = preTaskConfig:Property()
                if property and property:Goto() > 0 then
                    GuideUtils.GotoByGuide(property:Goto(), false)
                end
            else
                g_Logger.Error("nil task config for id:%s", preTask)
            end
            return
        end
    end
    local unlockZoneId = npcCfg:ExploreZone()
    if not isClickCleanZoneFog and unlockZoneId ~= 0 then
        local zone = self.city.zoneManager:GetZoneById(unlockZoneId)
        if not zone then
            g_Logger.Error("zone 没有数据 配置错误, NPC:%d", elementCfg:ElementId())
        else
            self:OnClickZone(self.city.uid, zone, targetPos, true)
        end
        return
    end
    local gridPos = elementCfg:Pos()
    local mainCell = self.city.grid:GetCell(gridPos:X(), gridPos:Y())
    if mainCell then
        local cityCellTile = self.city.gridView:GetCellTile(mainCell.x, mainCell.y)
        if cityCellTile and cityCellTile.tileView then
            cityCellTile.tileView:SetSelected(true)
            TimerUtility.DelayExecute(function()
                if cityCellTile.tileView then
                    cityCellTile.tileView:SetSelected(false)
                end
            end, 3)
        end
    end
    if noNeedTeam then
        if selectedTroopPresetIdx then
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_INTERACT_TARGET,cityUid,elementConfigID, nil, nil, true, selectedTroopPresetIdx)
        else
            g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_INTERACT_TARGET,cityUid,elementConfigID, team and team:GetPosition() or nil, selectedTroop, true)
        end
        return
    end
    local radius = self:GetTargetNpcRadius(elementConfigID) * 1.1

    if (targetPos - teamPos).magnitude <= radius then
        team:InteractTarget(elementConfigID)
        return
    elseif isInSingleSeExplorerMode and self._inRangeNpcMap[elementConfigID] == nil then
        return
    end
    local targetNpcList = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[elementConfigID]
    local isOnlySe,serviceId, retServiceState, retServiceCfg = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.EnterScene)
    if not isOnlySe then
        isOnlySe,serviceId, retServiceState, retServiceCfg = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.CatchPet)
    end
    if isOnlySe then
        if retServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
            if retServiceCfg then
                ModuleRefer.PlayerServiceModule:CheckShowTriggerRequireTaskGotoGuide(retServiceCfg)
            end
            return
        end
        if context.isDragMoveToTarget then
            self:MakeGotNpcAction(context, serviceId, team, teamPos, targetPos, elementConfigID, gridPos)
        else
            self:MakeGotSePanel(context, serviceId, team, teamPos, targetPos, elementConfigID, gridPos)
        end
        return
    end
    local isOnlyCommit,commitServiceId, commitRetServiceState, commitRetServiceCfg = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.CommitItem)
    if isOnlyCommit then
        if commitRetServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
            ModuleRefer.PlayerServiceModule:CheckShowTriggerRequireTaskGotoGuide(commitRetServiceState)
            return
        end
        if context.isDragMoveToTarget then
            self:MakeGotNpcAction(context, commitServiceId, team, teamPos, targetPos, elementConfigID, gridPos)
        else
            if ConfigRefer.CityConfig:RescueBeauty() == npcCfg:Id() then
                g_Game.UIManager:Open(UIMediatorNames.HeroRescueMediator)
                return
            end
            self:MakeGoToCommitItemPanel(context, commitServiceId, team, teamPos, targetPos, elementConfigID)
        end
        return
    end
    ---@type CityExplorerTeamDefine.InteractEndAction
    local interactEndAction = CityExplorerTeamDefine.InteractEndAction.ToIdle
    if not team:InExplore() then
        interactEndAction = CityExplorerTeamDefine.InteractEndAction.AutoRemove
    end
    self:DoContinueGoToNpcWithTeam(team._teamPresetIdx, teamPos, targetPos, elementConfigID, interactEndAction)
end

function CityExplorerManager:OnClickSpawner(context)
    if self.city:IsInSingleSeExplorerMode() then
        self:OnConfirmSpanwer(context)
    else
        self:ShowPopUpMenu(context,function()
            self:OnConfirmSpanwer(context)
        end)
    end
end

---@param context ClickNpcEventContext
function CityExplorerManager:OnConfirmSpanwer(context)
    local cityUid = context.cityUid
    local elementConfigID = context.elementConfigID
    local targetPos = context.targetPos
    local isClickCleanZoneFog = context.isClickCleanZoneFog
    local disallowCheckToast = context.disallowCheckToast
    local selectedTroop = context.selectedTroop
    local selectedTroopPresetIdx = context.selectedTroopPresetIdx

    if cityUid ~= self.city.uid then
        -- g_Logger.Error("yxj: "..debug.traceback())
        return
    end
    if not selectedTroopPresetIdx and self.city:IsInSingleSeExplorerMode() then
        ---@type CityStateSeExplorerFocus
        local state = self.city.stateMachine:GetCurrentState()
        selectedTroopPresetIdx = state and state:GetCurrentPresetIndex()
        if selectedTroopPresetIdx then
            selectedTroopPresetIdx = selectedTroopPresetIdx + 1
        end
    end
    if isClickCleanZoneFog then
        if not self:CheckClickCleanZoneFog(not disallowCheckToast) then
            -- g_Logger.Error("yxj: "..debug.traceback())
            return
        end
    end
    --if not self:CheckRequireBuildingAndFurniture(not disallowCheckToast, isClickCleanZoneFog) then
    --    return
    --end
    local elementCfg = ConfigRefer.CityElementData:Find(elementConfigID)
    if not elementCfg then
        g_Logger.Error("elementConfigID:%s config is nil", elementConfigID)
        return
    end
    local spawnerConfig = ConfigRefer.CityElementSpawner:Find(elementCfg:ElementId())
    if not spawnerConfig then
        g_Logger.Error("elementConfigID:%s spawner:%s config is nil", elementConfigID, elementCfg:ElementId())
        return
    end
    -- 在探索模式下 点击就不用响应了
    if self.city:IsInSingleSeExplorerMode() then
        -- g_Logger.Error("yxj: "..debug.traceback())
        return
    end
    local teamPos
    ---@type CityExplorerTeam
    local team
    if not selectedTroop and not selectedTroopPresetIdx then
        local _
        teamPos,_,team = self:GetNearestIdleTeamAndPosition(targetPos, elementConfigID, false)
        if not self.city:IsInSingleSeExplorerMode() and not self.city:IsInSeBattleMode() then
            self:SelectPresetToNormalExplorTarget(elementConfigID, CityExplorerTeamDefine.InteractEndAction.WaitBattleEnd)
        end
        -- g_Logger.Error("yxj: "..debug.traceback())
        return
    else
        selectedTroopPresetIdx,selectedTroop = self:GetPresetIndexAndTroopId(selectedTroopPresetIdx, selectedTroop)
        for _, value in pairs(self._teams) do
            if (value._teamPresetIdx + 1) == selectedTroopPresetIdx then
                team = value
                break
            end
        end
        if team then
            teamPos = team:GetPosition()
        end
    end
    if not teamPos then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("tips_troop_need_to_back"))
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_EXPLORER_RESPONSE_TO_NPC_CLICK, elementConfigID, targetPos)
        -- g_Logger.Error("yxj: "..debug.traceback())
        return
    end
    local radius = self:GetTargetNpcRadius(elementConfigID) * 1.1
    if (targetPos - teamPos).magnitude <= radius then
        team._teamData:SetInteractEndAction(CityExplorerTeamDefine.InteractEndAction.WaitBattleEnd)
        team:InteractTarget(elementConfigID)
        -- g_Logger.Error("yxj: "..debug.traceback())
        return
    end
    self:DoContinueGoToNpcWithTeam(team._teamPresetIdx, teamPos, targetPos, elementConfigID, CityExplorerTeamDefine.InteractEndAction.WaitBattleEnd)
end

---@param interactEndAction CityExplorerTeamDefine.InteractEndAction
function CityExplorerManager:DoContinueGoToNpcWithTeam(teamPresetIndex, teamPos, targetPos, elementConfigID, interactEndAction)
    local team = self:GetTeamByPresetIndex(teamPresetIndex)
    if not team or not teamPos then
        for index = #self._tickWaitTeamPosReady, 1, -1 do
            if self._tickWaitTeamPosReady[index].presetIndex == teamPresetIndex then
                self._tickWaitTeamPosReady[index].targetPos = targetPos
                self._tickWaitTeamPosReady[index].elementConfigID = elementConfigID
                self._tickWaitTeamPosReady[index].interactEndAction = interactEndAction
                return
            end
        end
        ---@type {presetIndex:number, targetPos:CS.UnityEngine.Vector3, elementConfigID:number, interactEndAction:CityExplorerTeamDefine.InteractEndAction}
        local pending = {}
        pending.presetIndex = teamPresetIndex
        pending.targetPos = targetPos
        pending.elementConfigID = elementConfigID
        pending.interactEndAction = interactEndAction
        table.insert(self._tickWaitTeamPosReady, pending)
        return
    end
    local lastPathFindingHandle = self._lastPathFindingHandleMap[teamPresetIndex]
    if lastPathFindingHandle then
        lastPathFindingHandle:Release()
    end
    self._lastPathFindingHandleMap[teamPresetIndex] = nil
    local pathFinding = self.city.cityPathFinding
    local mask = pathFinding.AreaMask.CityGround
    self._lastPathFindingHandleMap[teamPresetIndex] = pathFinding:FindPath(teamPos, targetPos, mask, function(waypoints)
        self._lastPathFindingHandleMap[teamPresetIndex] = nil
        if #waypoints > 1 then
            team:GoToTarget(waypoints[#waypoints], elementConfigID, false)
            team._teamData:SetInteractEndAction(interactEndAction)
            team:WaitForSync()
            self.city.citySeManger:SetSeCaptainClickMove(waypoints[#waypoints], teamPresetIndex)
        end
    end)
end

function CityExplorerManager:OnClickCreep(cityUid, targetId, targetPos)
    if cityUid ~= self.city.uid then
        return
    end
    local teamPos,_,team = self:GetNearestIdleTeamAndPosition(targetPos)
    if not teamPos then
        return
    end
    local elementCfg = ConfigRefer.CityElementData:Find(targetId)
    if not elementCfg then
        return
    end
    local npcCfg = ConfigRefer.CityElementNpc:Find(elementCfg:ElementId())
    if not npcCfg then
        return
    end
    local gridPos = elementCfg:Pos()
    local mainCell = self.city.grid:GetCell(gridPos:X(), gridPos:Y())
    if mainCell then
        local cityCellTile = self.city.gridView:GetCellTile(mainCell.x, mainCell.y)
        if cityCellTile and cityCellTile.tileView then
            cityCellTile.tileView:SetSelected(true)
            TimerUtility.DelayExecute(function()
                if cityCellTile.tileView then
                    cityCellTile.tileView:SetSelected(false)
                end
            end, 3)
        end
    end

    local radius = 0.5
    if (targetPos - teamPos).magnitude <= radius then
        team:InteractTarget(targetId)
        return
    end
    local teamPresetIdx = team._teamPresetIdx
    local lastPathFindingHandle = self._lastPathFindingHandleMap[teamPresetIdx]
    if lastPathFindingHandle then
        lastPathFindingHandle:Release()
    end
    self._lastPathFindingHandleMap[teamPresetIdx] = nil
    local pathFinding = self.city.cityPathFinding
    local mask = pathFinding.AreaMask.CityGround
    self._lastPathFindingHandleMap[teamPresetIdx] = pathFinding:FindPath(teamPos, targetPos, mask, function(waypoints)
        self._lastPathFindingHandleMap[teamPresetIdx] = nil
        if #waypoints > 1 then
            team:GoToTarget(waypoints[#waypoints], targetId, false)
            team:WaitForSync()
            self.city.citySeManger:SetSeCaptainClickMove(waypoints[#waypoints], teamPresetIdx)
        end
    end)
end

function CityExplorerManager:OnInteractCityElement(cityUid, elementId, teamPosition, troopId, isFromClick, troopPresetIdx)
    if cityUid ~= self.city.uid then
        return
    end
    if g_Game.UIManager:HasAnyDialogUIMediator() or g_Game.UIManager:HaveCullSceneUIMediator() then
        return
    end

    local cfg = ConfigRefer.CityElementData:Find(elementId)
    if not cfg then return end

    local typeEnum = cfg:Type()
    if typeEnum == CityElementType.Npc then
        self:OnInteractTargetNpc(cityUid, elementId, teamPosition, troopId, isFromClick, troopPresetIdx)
    elseif typeEnum == CityElementType.Creep then
        self:OnInteractTargetCreep(cityUid, elementId, teamPosition, isFromClick)
    end
end

---@param cityUid number
---@param targetId number
---@param teamPosition CS.UnityEngine.Vector3
---@param troopId number
---@param isFromClick boolean
function CityExplorerManager:OnInteractTargetNpc(cityUid, targetId, teamPosition, troopId, isFromClick, troopPresetIdx)
    if not self.city.stateMachine then
        return
    end
    if not self.city.stateMachine:IsCurrentState(CityConst.STATE_NORMAL) and not self.city.stateMachine:IsCurrentState(CityConst.STATE_CITY_SE_EXPLORER_FOCUS) then
        return
    end
    local cfg = ConfigRefer.CityElementData:Find(targetId)
    local npcCfg = ConfigRefer.CityElementNpc:Find(cfg:ElementId())
    if not npcCfg then
        return
    end
    local noNeedTeam = npcCfg:NoNeedTeamInteract()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local preTask = npcCfg:Precondition()
    if preTask ~= 0 then
        local QuestModule = ModuleRefer.QuestModule
        if not QuestModule:IsInBitMap(preTask, player.PlayerWrapper.Task.FinishedBitMap) then
            g_Logger.Warn("前置任务条件不满足：%s, 跳过", preTask)
            local preTaskConfig = ConfigRefer.Task:Find(preTask)
            if preTaskConfig then
                local property = preTaskConfig:Property()
                if property and property:Goto() > 0 then
                    GuideUtils.GotoByGuide(property:Goto(), false)
                end
            else
                g_Logger.Error("nil task config for id:%s", preTask)
            end
            return
        end
    end

    local targetNpcList = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[targetId]
    local isOnlySe,_,retServiceState,retServiceCfg = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.EnterScene)
    if not isOnlySe then
        isOnlySe,_, retServiceState, retServiceCfg = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.CatchPet)
    end
    if not noNeedTeam and not isOnlySe then
        if not isFromClick then
            -- local camera = self.city:GetCamera().mainCamera
            -- local viewPoint = camera:WorldToViewportPoint(teamPosition)
            -- if viewPoint.x <= 0 or viewPoint.y <= 0 or viewPoint.x >= 1 or viewPoint.y >= 1 then
            --     return
            -- end
        end
    else
        if retServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
            ModuleRefer.PlayerServiceModule:CheckShowTriggerRequireTaskGotoGuide(retServiceCfg)
            return
        end
    end
    local isOnlyCommit,_,commitRetServiceState,commitRetServiceCfg = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.CommitItem)
    if isOnlyCommit then
        if commitRetServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
            ModuleRefer.PlayerServiceModule:CheckShowTriggerRequireTaskGotoGuide(commitRetServiceCfg)
            return
        end
    end
    local isOnlyReceive,_,receiveItemRetServiceState,receiveItemRetServiceCfg = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.ReceiveItem)
    if isOnlyReceive then
        if receiveItemRetServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
            ModuleRefer.PlayerServiceModule:CheckShowTriggerRequireTaskGotoGuide(receiveItemRetServiceCfg)
            return
        end
    end
    if npcCfg:Type() == CityNpcType.Treasure then
        if self._tTickTreasureProgress[targetId] then
            return
        end
        ---@type {duration:number, endTime:number, targetId:number}
        local delayInfo  = {}
        delayInfo.targetId = targetId
        delayInfo.duration = ConfigTimeUtility.NsToSeconds(npcCfg:CostTime())
        delayInfo.endTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + delayInfo.duration
        self._tTickTreasureProgress[targetId] = delayInfo
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_TREASURE_REFRESH, self.city.uid, targetId)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_PLAY_INTERACE_AUDIO, self.city.uid, targetId)
        return
    end
    local openZoneId = self.city.zoneManager:GetOpenNpcLinkZoneId(targetId)
    if openZoneId then
        self:SelectPresetToExplorBrithPoint(targetId, openZoneId)
        return
    end
    if npcCfg:ExploreZone() ~= 0 then
        return
    end
    if npcCfg:Id() == ConfigRefer.CityConfig:FirstRechargeNpc() then
        local popId = ModuleRefer.ActivityShopModule:GetFirstRechargePopId()
        if not popId or popId <= 0 then
            g_Logger.ErrorChannel("CityExplorerManager", "首充礼包未解锁")
            return
        end
        ---@type UIFirstRechargeMediatorParam
        local data = {}
        data.isFromHud = true
        data.openPopId = popId
        g_Game.UIManager:Open(UIMediatorNames.UIFirstRechargeMediator, data)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_PLAY_INTERACE_AUDIO, self.city.uid, targetId)
        return
    --拯救美女
    elseif npcCfg:Id() == ConfigRefer.CityConfig:RescueBeauty() then
        local isFinishTask,finishTaskServiceId, finishTaskServiceState,_ = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.FinishTask)
        if isFinishTask and finishTaskServiceState == wds.NpcServiceState.NpcServiceStateCanReceive then
            self:RequestNpcService(targetId, finishTaskServiceId)
        end
        g_Game.UIManager:Open(UIMediatorNames.HeroRescueMediator)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_PLAY_INTERACE_AUDIO, self.city.uid, targetId)
        return
    end
    if targetNpcList then
        if targetNpcList.IsCoolDown then
            ModuleRefer.PlayerServiceModule:CreateWaitRespawnPanel(NpcServiceObjectType.CityElement, targetId)
            return
        end
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_PLAY_INTERACE_AUDIO, self.city.uid, targetId)
        self:ContinueOnTargetNpcListDataReady(npcCfg, targetId, troopId, troopPresetIdx)
    end
end

---@param cityUid number
---@param targetId number
---@param teamPosition CS.UnityEngine.Vector3
---@param isFromClick boolean
function CityExplorerManager:OnInteractTargetCreep(cityUid, targetId, teamPosition, isFromClick)
    if not self.city.stateMachine then
        return
    end
    if not self.city.stateMachine:IsCurrentState(CityConst.STATE_NORMAL) then
        return
    end
    local cfg = ConfigRefer.CityElementData:Find(targetId)
    local creepCfg = ConfigRefer.CityElementCreep:Find(cfg:ElementId())
    if not creepCfg then
        return
    end
    if not isFromClick then
        local camera = self.city:GetCamera().mainCamera
        local viewPoint = camera:WorldToViewportPoint(teamPosition)
        if viewPoint.x <= 0 or viewPoint.y <= 0 or viewPoint.x >= 1 or viewPoint.y >= 1 then
            return
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CREEP_NODE_SHOW_MENU, cityUid, targetId)
end

---@param npcCfg CityElementNpcConfigCell
---@param targetId number
---@param troopId number
---@param troopPresetIdx number|nil
function CityExplorerManager:ContinueOnTargetNpcListDataReady(npcCfg, targetId, troopId, troopPresetIdx)
    local targetNpcList = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[targetId]
    if not targetNpcList then
        return
    end
    local storyId = npcCfg:InitStoryTaskId()
    local hasAnyTask = ModuleRefer.QuestModule.Chapter:CheckIsShowCityElementNpcHeadIcon(npcCfg:Id())
    if storyId > 0 then
        if not hasAnyTask then
            local isOnlyReceive,serviceId,receiveItemRetServiceState,_ = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.ReceiveItem)
            if isOnlyReceive and receiveItemRetServiceState == wds.NpcServiceState.NpcServiceStateCanReceive then
                self:RequestNpcService(targetId, serviceId)
                return
            end
        end
        ModuleRefer.StoryModule:StoryStart(storyId, function(_, _)
            self:ContinueOnTargetNpcInitDialogEnd(targetNpcList, targetId, npcCfg, troopId, troopPresetIdx)
        end, true)
        return
    end
    local dialogId = npcCfg:InitDialogId()
    local dialog = ConfigRefer.StoryDialogGroup:Find(dialogId)
    local this = self
    if dialog then
        if not hasAnyTask then
            local isOnlyReceive,serviceId,receiveItemRetServiceState,_ = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.ReceiveItem)
            if isOnlyReceive and receiveItemRetServiceState == wds.NpcServiceState.NpcServiceStateCanReceive then
                self:RequestNpcService(targetId, serviceId)
                return
            end
        end
        local parameter = StoryDialogUIMediatorParameter.new()
        local t = parameter:SetDialogGroup(dialogId, function(uiRuntimeId)
            if uiRuntimeId then
                g_Game.UIManager:Close(uiRuntimeId)
            end
            this:ContinueOnTargetNpcInitDialogEnd(targetNpcList, targetId, npcCfg, troopId, troopPresetIdx) end)
        ModuleRefer.StoryModule:OpenDialogMediatorByType(t, parameter)
    else
        self:ContinueOnTargetNpcInitDialogEnd(targetNpcList, targetId, npcCfg, troopId, troopPresetIdx)
    end
end

---@param targetNpcList wds.NpcServiceGroup
---@param targetId number
---@param npcCfg CityElementNpcConfigCell
---@param troopId number|nil
---@param troopPresetIdx number|nil
function CityExplorerManager:ContinueOnTargetNpcInitDialogEnd(targetNpcList, targetId, npcCfg, troopId, troopPresetIdx)
    g_Game.UIManager:CloseByName(UIMediatorNames.StoryDialogUIMediator)
    if ModuleRefer.QuestModule.Chapter:CheckIsShowCityElementNpcHeadIcon(npcCfg:Id()) then
        ModuleRefer.QuestModule.Chapter:OpenNpcTaskCircleMenu(npcCfg:Id())
        return
    end
    local has,firstNotShownLockedService = ModuleRefer.PlayerServiceModule:HasInteractableService(targetNpcList)
    if not has then
        if firstNotShownLockedService then
            local ele = self.city.elementManager:GetElementById(targetId)
            if ele then
                local tile = self.city.gridView:GetCellTile(ele.x, ele.y)
                if tile then
                    if self.city.stateMachine:IsCurrentState(CityConst.STATE_NORMAL) then
                        g_Logger.Log("目标NPC:%s 显示首个锁定且 IsShowLockService 为false 的服务的要求条件", targetId)
                        self.city.stateMachine:WriteBlackboard("LockedNpcSelected", tile)
                        self.city.stateMachine:ChangeState(CityConst.STATE_LOCKED_NONE_SHOWN_SERVICE_NPC_SELECT)
                    end
                end
            end
        else
            g_Logger.Warn("目标NPC:%s 没有可用服务", targetId)
        end
        return
    end
    if self:OnSingleSEEntryService(targetNpcList, targetId, npcCfg, troopId, troopPresetIdx) then
        return
    end
    if ModuleRefer.PlayerServiceModule:OnSingleCommitItemService(NpcServiceObjectType.CityElement, targetNpcList, targetId, npcCfg) then
        return
    end
    local isOnlyReceive,serviceId,receiveItemRetServiceState,receiveItemRetServiceCfg = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.ReceiveItem)
    if isOnlyReceive then
        if receiveItemRetServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
            ModuleRefer.PlayerServiceModule:CheckShowTriggerRequireTaskGotoGuide(receiveItemRetServiceCfg)
            return
        end
        self:RequestNpcService(targetId, serviceId)
        return
    end
    local uiMediatorName = UIMediatorNames.StoryDialogUIMediator
    local parameter = StoryDialogUIMediatorParameter.new()
    local provider = StoryDialogUIMediatorParameterChoiceProvider.new()
    ---@type MakeNpcServiceOptionContext
    local contextProvider = {}
    contextProvider.IsPolluted = Delegate.GetOrCreate(self.city.elementManager, self.city.elementManager.IsPolluted)
    contextProvider.GetPresetIndexAndTroopId = Delegate.GetOrCreate(self, self.GetPresetIndexAndTroopId)
    contextProvider.GetPresetIndexAndTroopIdByPreset = Delegate.GetOrCreate(self, self.GetPresetIndexAndTroopIdByPreset)
    contextProvider.GetCenterWorldPositionFromCoord = Delegate.GetOrCreate(self.city, self.city.GetCenterWorldPositionFromCoord)
    provider:InitForNpc(npcCfg)
    for npcServiceId, serviceState in pairs(targetNpcList.Services) do
        local option = ModuleRefer.PlayerServiceModule:MakeNpcServiceOption(NpcServiceObjectType.CityElement,targetId, npcServiceId, uiMediatorName, serviceState.State, troopId, troopPresetIdx, contextProvider)
        if option then
            provider:AppendOption(option)
        end
    end
    --for _, serviceId in ipairs(targetNpcList.CanReceiveServiceIds) do
    --    local existed = targetNpcList.Services[serviceId]
    --    if not existed then
    --        local option = self:MakeNpcServiceOption(targetId, serviceId, uiMediatorName)
    --        if option then
    --            provider:AppendOption(option)
    --        end
    --    end
    --end
    if not npcCfg.InteractOptionNoCancel or not npcCfg:InteractOptionNoCancel() then
        ---@type StoryDialogUIMediatorParameterChoiceProviderOption
        local exitChoice = {}
        exitChoice.showNumberPair = false
        exitChoice.showIsOnGoing = false
        exitChoice.type = 0
        exitChoice.onClickOption = nil
        exitChoice.isOptionShowCreep = false
        if npcCfg:IsHuman() then
            exitChoice.content = I18N.Get("npc_service_btn_quit")
        else
            exitChoice.content = I18N.Get("npc_service_btn_quit")
        end
        provider:AppendOption(exitChoice)
    end
    parameter:SetChoiceProvider(provider)
    g_Game.UIManager:Open(uiMediatorName, parameter)
end

function CityExplorerManager:GetPresetIndexAndTroopId(troopPresetIdx, troopId)
    local p = ModuleRefer.PlayerModule:GetCastle().TroopPresets
    if troopPresetIdx then
        troopId = p.Presets[troopPresetIdx].TroopId
    elseif troopId then
        local presetArray = p.Presets or {}
        for i = 1, #presetArray do
            if presetArray[i] and presetArray[i].TroopId == troopId then
                troopPresetIdx = i
                break
            end
        end
    end
    return troopPresetIdx, troopId
end

---@param troopInfo TroopInfo
function CityExplorerManager:GetPresetIndexAndTroopIdByPreset(troopInfo)
    if not troopInfo or not troopInfo.preset then
        return
    end
    local troopId = nil
    local idx = nil
    local p = ModuleRefer.PlayerModule:GetCastle().TroopPresets
    local presets = p.Presets or {}
    for i = 1, #presets do
        local pre = presets[i]
        if pre.ID == troopInfo.preset.ID then
            idx = i
            troopId = troopInfo.troopId
            break
        end
    end
    return idx,troopId
end

---@param targetNpcList wds.NpcServiceGroup
---@param targetId number
---@param npcCfg CityElementNpcConfigCell
---@param troopId number|nil
---@param troopPresetIdx number|nil
---@return boolean
function CityExplorerManager:OnSingleSEEntryService(targetNpcList, targetId, npcCfg, troopId, troopPresetIdx)
    local ret, seServiceId, retServiceState, retServiceCfg = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.EnterScene)
    if not ret then
        ret, seServiceId, retServiceState, retServiceCfg = ModuleRefer.PlayerServiceModule:IsOnlyOneValidTypeService(targetNpcList, NpcServiceType.CatchPet)
        if not ret then
            return false
        end
    end

    if retServiceState == wds.NpcServiceState.NpcServiceStateBeLocked then
        ModuleRefer.PlayerServiceModule:CheckShowTriggerRequireTaskGotoGuide(retServiceCfg)
        return true
    end
    
    local npcElementId = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)[targetId].ObjectId
    local eleConfig = ConfigRefer.CityElementData:Find(npcElementId)
    local elePos = eleConfig:Pos()
    local npcPos = self.city:GetCenterWorldPositionFromCoord(elePos:X(), elePos:Y(), npcCfg:SizeX(), npcCfg:SizeY())
    if npcCfg:NoNeedTeamInteract() then
        troopPresetIdx, troopId = self:GetPresetIndexAndTroopId(troopPresetIdx, troopId)
        if troopPresetIdx then
            -- 需要使用部队，如SE
            if self.city.elementManager:IsPolluted(npcElementId) then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_clean_needed"))
                return true
            end

            local function RequestNpcService()
                local continueEnterScene = ModuleRefer.SEPreModule:GetContinueGoToSeInCity(troopId or 0, elePos, seServiceId, npcElementId, troopPresetIdx)
                self:RequestNpcService(targetId, seServiceId, function(success, rsp)
                    if success then
                        if continueEnterScene then
                            continueEnterScene()
                        end
                    end
                end)
            end

            local isPetCatch,costPPP, recommendPower, itemHas = ModuleRefer.SEPreModule.GetNpcServiceBattleInfo(seServiceId)
            --检查体力
            if costPPP > 0  then
                local player = ModuleRefer.PlayerModule:GetPlayer()
                local curPPP = player and player.PlayerWrapper2.Radar.PPPCur or 0
                if curPPP < costPPP then
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_tilibuzu"))
                    return true
                end
            end

            --检查战力
            local troopPower = ModuleRefer.SlgModule:GetTroopPowerByPresetIndex(troopPresetIdx)
            if troopPower < recommendPower then
                SlgBattlePowerHelper.ShowRaisePowerPopup(RPPType.Se,RequestNpcService,troopPresetIdx)
            else
                RequestNpcService()
            end
        else
            -- 不需要使用部队，如抓宠
            local onMenuGotToClick= function()
                ---@type HUDSelectTroopListData
                local selectTroopData = {}
                selectTroopData.filter = function(troopInfo)
                    return troopInfo ~= nil and troopInfo.preset ~= nil
                end

                selectTroopData.overrideItemClickGoFunc = function(troopItemData)
                    local idx, troopId = self:GetPresetIndexAndTroopIdByPreset(troopItemData.troopInfo)
                    if idx then
                        local continueEnterScene = ModuleRefer.SEPreModule:GetContinueGoToSeInCity(troopId or 0, elePos, seServiceId, npcElementId, idx)
                        self:RequestNpcService(targetId, seServiceId, function(success, rsp)
                            if success then
                                if continueEnterScene then
                                    continueEnterScene()
                                end
                            end
                        end)
                    else
                        g_Logger.Error("No troop here")
                    end
                end

                local isPetCatch,costPPP, recommendPower, itemHas = ModuleRefer.SEPreModule.GetNpcServiceBattleInfo(seServiceId)
                selectTroopData.isSE = true
                selectTroopData.catchPet = isPetCatch
                if isPetCatch then
                    local enterPetCatch = function()
                        local continueEnterScene = ModuleRefer.SEPreModule:GetContinueGoToSeInCity( 0, elePos, seServiceId, npcElementId, 1)
                        if continueEnterScene then
                            continueEnterScene()
                        end
                    end
                    local compareResult = (itemHas >= recommendPower) and 1 or 2
                    if compareResult == 2 then
                        SlgBattlePowerHelper.ShowRaisePowerPopup(RPPType.Pet,enterPetCatch)
                    else
                        enterPetCatch()
                    end
                else
                    selectTroopData.needPower = recommendPower
                    selectTroopData.recommendPower = recommendPower
                    selectTroopData.costPPP = costPPP
                    HUDTroopUtils.StartMarch(selectTroopData)
                end
            end

            ---@type CreateTouchMenuForCityContext
            local context = {}
            context.npcId = seServiceId
            context.troopId = nil
            context.troopPresetIdx = nil
            context.worldPos = npcPos
            context.overrideGoToFunc = onMenuGotToClick
            context.elementId = npcElementId
            context.cityPos = elePos
            context.isGoto = false
            if self.city.elementManager:IsPolluted(npcElementId) then
                context.targetIsPolluted = true
                context.pollutedHint = I18N.Get("creep_clean_needed")
            end
            ModuleRefer.SEPreModule:CreateTouchMenuForCity(context)
        end
        return true
    else
        troopPresetIdx, troopId = self:GetPresetIndexAndTroopId(troopPresetIdx, troopId)
        ---@type CreateTouchMenuForCityContext
        local context = {}
        context.npcId = seServiceId
        context.troopId = troopId
        context.troopPresetIdx = troopPresetIdx
        context.worldPos = npcPos
        context.overrideGoToFunc = nil
        context.elementId = npcElementId
        context.cityPos = elePos
        context.isGoto = false
        context.preSendEnterSceneOverride = function(continueEnterScene)
            self:RequestNpcService(targetId, seServiceId, function(success, rsp)
                if success then
                    if continueEnterScene then
                        continueEnterScene()
                    end
                end
            end)
        end
        if self.city.elementManager:IsPolluted(npcElementId) then
            context.targetIsPolluted = true
            context.pollutedHint = I18N.Get("creep_clean_needed")
        end
        ModuleRefer.SEPreModule:CreateTouchMenuForCity(context)
    end
    if troopId and ModuleRefer.SlgModule:IsTroopVisible(troopId) then
        self:SendTroopEnterTriggerEvent(targetId,seServiceId,npcElementId,elePos,targetNpcList,npcCfg, troopId, troopPresetIdx)
    end
    return true
end

function CityExplorerManager:SendTroopEnterTriggerEvent(targetId,seServiceId,npcElementId,elePos,targetNpcList,npcCfg, troopId, troopPresetIdx)
    local npcServiceCfg = ConfigRefer.NpcService:Find(seServiceId)
    local isInCityPetCatch = npcServiceCfg:ServiceType() == NpcServiceType.CatchPet
    g_Game.EventManager:TriggerEvent(EventConst.ON_TROOP_ENTER_EVENT_TRIGGER,{
        teamId = troopId,
        onClick = function()
            self:OnSingleSEEntryService(targetNpcList, targetId, npcCfg, troopId, troopPresetIdx)
        end,
        tipData = {
            tipType = isInCityPetCatch and 4 or 0, --in city
            targetId = targetId,
            npcId = seServiceId,
            elementId = npcElementId,
            cityPos = elePos
        }
    })
end

---@param targetAcceptedChapters wds.ElementNpcAcceptedChapters
function CityExplorerManager:HasAcceptedChapters(targetAcceptedChapters)
    if not targetAcceptedChapters or table.isNilOrZeroNums(targetAcceptedChapters.AcceptedChapters) then
        return false
    end
    return true
end

---@param cityElementTid number
---@param serviceId number
---@param callback fun(success:boolean, rsp:any)
function CityExplorerManager:RequestNpcService(cityElementTid, serviceId, callback)
    ModuleRefer.PlayerServiceModule:RequestNpcService(nil, NpcServiceObjectType.CityElement, cityElementTid, serviceId, nil, function(cmd, isSuccess, rsp)
        if callback then
            callback(isSuccess, rsp)
        end
    end)
end

---@param cityUid number
---@param treasureId number
function CityExplorerManager:OnCollectNpcTreasure(cityUid, treasureId)
    if cityUid ~= self.city.uid then
        return
    end
    local cmd = CastleGetTreasureParameter.new()
    cmd.args.TreasureId = treasureId
    cmd.args.IsExplore = self.city:IsInSingleSeExplorerMode()
    local uid = self.city.uid
    cmd:SendOnceCallback(nil,nil, nil, function(_, isSuccess, rsp)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_NPC_TREASURE_REFRESH, uid, treasureId) 
    end)
end

---@param npcCfg CityElementNpcConfigCell
function CityExplorerManager:DoGetTargetNpcRadius(npcCfg)
    local useOffsetOrigin = npcCfg:InteractOffsetOnOrigin()
    if useOffsetOrigin then
        return math.max(1, npcCfg:InteractRadius()) * self.city.scale
    end
    local sizeX = math.max(1, npcCfg:SizeX())
    local sizeY = math.max(1, npcCfg:SizeY())
    local sizeV = math.max(1, 0.5 * math.min(sizeX , sizeY)) * 1.414214
    return math.max(npcCfg:InteractRadius() + sizeV, 1.5) * self.city.scale
end

function CityExplorerManager:GetTargetNpcRadius(targetId)
    local cfg = ConfigRefer.CityElementData:Find(targetId)
    if not cfg then
        return self.city.scale
    end
    local npcCfg = ConfigRefer.CityElementNpc:Find(cfg:ElementId())
    if not npcCfg then
        return self.city.scale
    end
    return self:DoGetTargetNpcRadius(npcCfg)
end

function CityExplorerManager:GetTargetNpcRadiusSyncPosFix()
    return 0.5 * self.city.scale
end

function CityExplorerManager:CheckAndBroadcastTeamPositionChanged(dt)
    if table.isNilOrZeroNums(self._teams) then
        return
    end
    local needNotify = false
    table.clear(self._teamsCachedPos)
    for troopId, team in pairs(self._teams) do
        local pos = team:GetPosition()
        if not pos then
            goto continue
        end
        self._teamsCachedPos[troopId] = team:GetPosition()
        if team._stateMachine:IsCurrentState("CityExplorerTeamStateGoToTarget") then
            needNotify = true
        elseif team._teamData:GetAndResetForceNotifyPosFlag() then
            needNotify = true
        end
        if team._teamData:IsInMoving() then
            team._teamData:MarkLastMovingFlag(true)
        elseif team._teamData._lastMarkInMoving then
            team._teamData:MarkLastMovingFlag(false)
            if self.city:IsMyCity() then
                g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_STATUES_UPDATE, self.city.uid, troopId)
            end
        end
        ::continue::
    end
    if needNotify then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_MOVING_UPDATE, self.city, self._teamsCachedPos)
    end
end

---@param targetPos CS.UnityEngine.Vector3
---@param callback fun()
function CityExplorerManager:DoTeamTargetGround(targetPos, callback, selectedTroop)
    local teamPos
    ---@type CityExplorerTeam
    local team
    local _
    if not selectedTroop then
        teamPos,_,team = self:GetNearestIdleTeamAndPosition(targetPos)
    else
        team = self._teams[selectedTroop]
        if team then
            teamPos = team:GetPosition()
        end
    end
    if not teamPos then
        if callback then
            callback()
        end
        return
    end
    local teamPresetIndex = team._teamPresetIdx
    local lastPathFindingHandle = self._lastPathFindingHandleMap[teamPresetIndex]
    if lastPathFindingHandle then
        lastPathFindingHandle:Release()
    end
    self._lastPathFindingHandleMap[teamPresetIndex] = nil
    local pathFinding = self.city.cityPathFinding
    local mask = pathFinding.AreaMask.CityGround
    self._lastPathFindingHandleMap[teamPresetIndex] = pathFinding:FindPath(teamPos, targetPos, mask, function(waypoints)
        self._lastPathFindingHandleMap[teamPresetIndex] = nil
        if #waypoints > 1 then
            team:GoToTarget(waypoints[#waypoints], 0, true)
            team._teamData:SetInteractEndAction()
            team:WaitForSync()
            self.city.citySeManger:SetSeCaptainClickMove(waypoints[#waypoints], teamPresetIndex)
        end
        if callback then
            callback()
        end
    end)
end

function CityExplorerManager:OnTryUnlockZone(city, zone, hitPoint)
    if city ~= self.city.uid then return end
    if not zone then return end

    local canUnlock = self.city.zoneManager:IsCanShowUnlockBubble(zone)
    if not canUnlock then
        g_Game.UIManager:Open(UIMediatorNames.UIRaisePowerPopupMediator, self.city.zoneManager:GetZoneUnlockUIParam(zone))
        return
    end

    self.city.fogManager:SelectZone(zone.id)
    self.city.zoneManager:TempSelectedZone(zone.id)

    local param = self:BuildZoneCircleMenuInfo(zone, hitPoint, function()
        self.city.fogManager:UnSelectZone(zone.id)
        self.city.zoneManager:TempSelectedZone(nil)
    end)
    g_Game.UIManager:Open(UIMediatorNames.TouchMenuUIMediator, param)
end

---@param cityUid number
---@param zone CityZone
---@param hitPoint CS.UnityEngine.Vector3
---@param skipCheck boolean
function CityExplorerManager:OnClickZone(cityUid, zone, hitPoint, skipCheck, readyAndEnoughExecuteSendCmd)
    if cityUid ~= self.city.uid then
        return
    end
    if not zone then
        return
    end
    --if not self.city.zoneManager:CheckZonePreZoneCondition(zone, not skipCheck) then
    --    local tmp = {}
    --    local jumpZone = self.city.zoneManager:WalkCheckFirstZonePreZone(zone, tmp)
    --    if jumpZone and jumpZone ~= zone then
    --        local pos = jumpZone.config:RecoverPopPos()
    --        if pos:X() > 0 and pos:Y() > 0 then
    --            local cityPos = self.city:GetCenterWorldPositionFromCoord(pos:X(), pos:Y(), 1, 1)
    --            ---@type CS.UnityEngine.Vector3
    --            local viewPortPos = CS.UnityEngine.Vector3(0.45, 0.5, 0.0)
    --            self._city.camera:ForceGiveUpTween()
    --            self._city.camera:ZoomToWithFocusBySpeed(CityConst.CITY_RECOMMEND_CAMERA_SIZE, viewPortPos, cityPos)
    --        end
    --    end
    --    return
    --end
    if not self.city.zoneManager:IsCanShowUnlockBubble(zone) then
        return
    end
    local uiDatum
    local guide
    local isReady = self.city.zoneManager:CheckZonePreZoneCondition(zone, false)
    if isReady then
        isReady,guide = self.city.zoneManager:IsReadyForUnlock(zone)
        if isReady and readyAndEnoughExecuteSendCmd then
            local _, _, _, enough = self.city.zoneManager:GetZoneRequiredItem(zone)
            if enough then
                local cmd = CastleUnlockZoneParameter.new()
                cmd.args.ZoneId = zone.id
                cmd:Send()
                return
            end
        end
    end
    self.city.fogManager:SelectZone(zone.id)
    self.city.zoneManager:TempSelectedZone(zone.id)
    if isReady then
        uiDatum = self:BuildZoneCircleMenuInfo(zone, hitPoint,  function()
            self.city.fogManager:UnSelectZone(zone.id)
            self.city.zoneManager:TempSelectedZone(nil)
        end)
    else
        uiDatum = self:BuildGuideUnlockZoneCircleMenuInfo(zone, hitPoint, guide, function()
            self.city.fogManager:UnSelectZone(zone.id)
            self.city.zoneManager:TempSelectedZone(nil)
        end)
    end
    g_Game.UIManager:Open(UIMediatorNames.TouchMenuUIMediator, uiDatum)
end

---@param zone CityZone
---@param hitPoint CS.UnityEngine.Vector3
---@param closeCallback fun()
---@return TouchInfoData
function CityExplorerManager:BuildZoneCircleMenuInfo(zone, hitPoint, closeCallback, skipItemCheck)
    local basicInfo = TouchMenuBasicInfoDatumSe.new()
    basicInfo:SetImage(ArtResourceUtils.GetUIItem(zone.config:ExploreMenuImage())):SetDesc(I18N.Get(zone.config:ExploreDescription())):SetName(I18N.Get("mist_unlock"))
    local btn = TouchMenuMainBtnDatum.new()
    btn.label = I18N.Get("mist_clear")
    btn.onClick = function(data, btnTrans)
        if not skipItemCheck then
            local itemID, ownCount, needCount, enough = self.city.zoneManager:GetZoneRequiredItem(zone)
            if not enough then
                local itemInfo ={
                    id = itemID,
                    num = math.max(1, needCount - ownCount),
                }
                ModuleRefer.InventoryModule:OpenExchangePanel({itemInfo})
                return
            end
        end
        if not zone:SingleSeExplorerOnly() or self.city:IsInSingleSeExplorerMode() or zone.config:OpenDoorNpc() == 0 then
            local cmd = CastleUnlockZoneParameter.new()
            local zoneId = zone.id
            cmd.args.ZoneId = zoneId
            cmd:SendOnceCallback(btnTrans, nil, nil, function(_, isSuccess, rsp)
                if isSuccess then
                    self.city:LocalAddSeExploreZone(zoneId)
                end
            end)
        else
            self:SelectPresetToExplorBrithPointWithCallback(zone.config:OpenDoorNpc(), zone.id, function(presetIdx, coordX, coordY, dirX, dirY)
                local cmd = CastleUnlockZoneParameter.new()
                cmd.args.ZoneId = zone.id
                cmd:SendOnceCallback(btnTrans, nil, nil, function(cmd, isSuccess, rsp)
                    if isSuccess then
                        local team = self:GetTeamByPresetIndex(presetIdx)
                        if team then
                            self:SendDismissTeam(team, function(cmd, isSuccess, rsp)
                                self:CreateHomeSeTroop(presetIdx, coordX, coordY, nil, nil, nil, dirX, dirY, btnTrans)
                            end)
                        else
                            self:CreateHomeSeTroop(presetIdx, coordX, coordY, nil, nil, nil, dirX, dirY, btnTrans)
                        end
                    end
                end)
            end)
        end
        return false
    end
    if not skipItemCheck then
        self:SetRequiredItemInfo(btn, zone)
    end
    local btnGroup = TouchMenuHelper.GetRecommendButtonGroupDataArray({btn})
    local teamPower = 0
    local team = self:GetCurrentExploreModeSETeam()
    if team then
        teamPower = ModuleRefer.TroopModule:GetTroopPower(team._presetIdx + 1)
    else
        local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
        for _, troop in ipairs(troops) do
            if CityExplorerManager.SelectPresetToExploreBrithPointFilter(troop) then
                local power = ModuleRefer.TroopModule:GetTroopPowerByPreset(troop.preset)
                if power > teamPower then
                    teamPower = power
                end
            end
        end
    end
    local needPower = zone.config:ExploreNeedPower()
    local recommendPower = zone.config:ExploreRecommendPower()
    local seMonsterDatum = TouchMenuCellSeMonsterDatum.new(I18N.Get("explore_des_monster"))
    local rewardDatum = TouchMenuCellRewardDatum.new(I18N.Get("explore_des_reward"))
    for i = 1, zone.config:ExploreSeMonstersLength() do
        local seNpcConfigId = zone.config:ExploreSeMonsters(i)
        local seNpc = ConfigRefer.SeNpc:Find(seNpcConfigId)
        ---@type TMCellSeMonsterDatum
        local monsterDatum = {}
        monsterDatum.iconId = seNpc:MonsterInfoIcon()
        seMonsterDatum:AppendMonsterDatum(monsterDatum)
    end
    local defeatReward = zone.config:ExploreDropShow()
    local itemGroup = ConfigRefer.ItemGroup:Find(defeatReward)
    if itemGroup then
        for i = 1, itemGroup:ItemGroupInfoListLength() do
            local itemInfo = itemGroup:ItemGroupInfoList(i)
            ---@type ItemIconData
            local iconData = {}
            iconData.configCell = ConfigRefer.Item:Find(itemInfo:Items())
            iconData.count = itemInfo:Nums()
            iconData.useNoneMask = false
            rewardDatum:AppendItemIconData(iconData)
        end
    end
    ---@type TouchMenuPowerDatum
    local powerData = {}
    local compareResult = SlgBattlePowerHelper.ComparePower(teamPower, needPower, recommendPower)
    powerData.powerText = I18N.GetWithParams("explore_des_recommand", teamPower, recommendPower)
    powerData.powerIcon = SlgBattlePowerHelper.GetPowerCompareIcon(compareResult)
    local uiDatum = TouchMenuHelper.GetSinglePageUIDatum(basicInfo,
            {seMonsterDatum, rewardDatum}, btnGroup, nil, nil, nil, nil, powerData)
            :SetPos(hitPoint)
            :SetOnHideCallback(closeCallback)
            :SetClickEmptyClose(true)
    return uiDatum
end

---@param zone CityZone
function CityExplorerManager:BuildGuideUnlockZoneCircleMenuInfo(zone, hitPoint, callGuideId, closeCallback)
    ---@type CityZone|nil
    local needGotoZone
    if not self.city.zoneManager:CheckZonePreZoneCondition(zone, false) then
        local tmp = {}
        local jumpZone = self.city.zoneManager:WalkCheckFirstZonePreZone(zone, tmp)
        if jumpZone then--and jumpZone ~= zone then
            local pos = jumpZone.config:RecoverPopPos()
            if pos:X() > 0 and pos:Y() > 0 then
                needGotoZone = jumpZone
            end
        end
    end

    local basicInfo = TouchMenuBasicInfoDatumSe.new()
    basicInfo:SetImage(ArtResourceUtils.GetUIItem(zone.config:ExploreMenuImage()))
            :SetDesc(I18N.Get(zone.config:ExploreDescription()))
            :SetName(I18N.Get("mist_unlock"))
            --:SetCoord(zone.config:CenterPos():X(), zone.config:CenterPos():Y())


    local btn = TouchMenuMainBtnDatum.new()
    btn.label = I18N.Get("goto")
    btn.onClick = function()
        if needGotoZone then
            local pos = needGotoZone.config:RecoverPopPos()
            local cityPos = self.city:GetCenterWorldPositionFromCoord(pos:X(), pos:Y(), 1, 1)
            ---@type CS.UnityEngine.Vector3
            local viewPortPos = CS.UnityEngine.Vector3(0.45, 0.5, 0.0)
            self.city.camera:ForceGiveUpTween()
            self.city.camera:ZoomToWithFocusBySpeed(CityConst.CITY_RECOMMEND_CAMERA_SIZE, viewPortPos, cityPos)
            return false
        end
        if callGuideId and callGuideId > 0 then
            GuideUtils.GotoByGuide(callGuideId)
        end
        return false
    end
    local btnTipsDatta = TouchMenuButtonTipsData.new()
    if needGotoZone then
        btnTipsDatta:SetContent(I18N.GetWithParams("toast_city_zone_pre_zone", I18N.Get(needGotoZone.config:Name())))
    else
        btnTipsDatta:SetContent(self.city.zoneManager:GetZoneRecoverFirstNotMatchPreConditionContent(zone))
    end
    local btnGroup = TouchMenuHelper.GetRecommendButtonGroupDataArray({btn})
    local uiDatum = TouchMenuHelper.GetSinglePageUIDatum(basicInfo,
            nil, btnGroup, btnTipsDatta, nil, nil, nil)
            :SetPos(hitPoint)
            :SetOnHideCallback(closeCallback)
            :SetClickEmptyClose(true)
    return uiDatum
end

---@param btn TouchMenuMainBtnDatum
---@param zone CityZone
function CityExplorerManager:SetRequiredItemInfo(btn, zone)
    local itemID, ownCount, itemCount, enough = self.city.zoneManager:GetZoneRequiredItem(zone)
    local itemConfig = ConfigRefer.Item:Find(itemID)
    if not itemConfig then return end
    local extraColor = enough and "#00FF00FF" or "#FF0000FF"
    local extraLabel = string.format('<color=%s>%d</color>/%d', extraColor, ownCount, itemCount)
    btn:SetExtraImage(itemConfig:Icon())
    btn:SetExtraLabel(extraLabel)
end

function CityExplorerManager:CheckClickCleanZoneFog(showToast)
    return true
    --if self._city:IsMyCity() then
    --    local castle = self._city:GetCastle()
    --    local furnitures = castle.CastleFurniture
    --    for _, info in pairs(furnitures) do
    --        local lvCell = ConfigRefer.CityFurnitureLevel:Find(info.ConfigId)
    --        if CityCitizenDefine.CityFurnitureRadarTypeIds[lvCell:Type()] then
    --            return true
    --        end
    --    end
    --end
    --if showToast then
    --    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("tips_default_building_radar"))
    --end
    --return false
end

---@return boolean
function CityExplorerManager:CheckRequireBuildingAndFurniture(showToast, isClickCleanZoneFog)
    local sandTableMatch = false
    local radarMatch = not isClickCleanZoneFog
    if self.city:IsMyCity() then
        local cityFurnitureLevelCfg = ConfigRefer.CityFurnitureLevel
        local castle = self.city:GetCastle()
        for i, v in ConfigRefer.BuildingTypes:pairs() do
            local buildingTypeEnum = v:Type()
            if buildingTypeEnum == BuildingType.ExplorerCamp then
                if sandTableMatch then
                    goto continueLoopBuildingTypes
                end
            elseif buildingTypeEnum == BuildingType.Radar then
                if radarMatch then
                    goto continueLoopBuildingTypes
                end
            else
                goto continueLoopBuildingTypes
            end
            local buildings = ModuleRefer.CityConstructionModule:GetAllBuildingInfosByType(v:Id())
            if not buildings then
                goto continueLoopBuildingTypes
            end
            for _, building in pairs(buildings) do
                if not CityUtils.IsStatusReadyForFurniture(building.Status) then
                    goto continueLoopBuilding
                end
                local innerFurniture = building.InnerFurniture
                if not innerFurniture then
                    goto continueLoopBuilding
                end
                for _, furnitureId in pairs(innerFurniture) do
                    local f = castle.CastleFurniture[furnitureId]
                    if not f then
                        goto continueLoopBuildingInnerFurniture
                    end
                    local fCfg = cityFurnitureLevelCfg:Find(f.ConfigId)
                    if not fCfg then
                        goto continueLoopBuildingInnerFurniture
                    end
                    if buildingTypeEnum == BuildingType.ExplorerCamp then
                        if CityCitizenDefine.CityFurnitureExplorerTeamTypeIds[fCfg:Type()] then
                            sandTableMatch = true
                        end
                    elseif buildingTypeEnum == BuildingType.Radar then
                        if CityCitizenDefine.CityFurnitureRadarTypeIds[fCfg:Type()] then
                            radarMatch = true
                        end
                    end
                    if sandTableMatch and radarMatch then
                        return true
                    end
                    ::continueLoopBuildingInnerFurniture::
                end
                ::continueLoopBuilding::
            end
            ::continueLoopBuildingTypes::
        end
    end
    if showToast then
        if not sandTableMatch then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("tips_default_building_explorer_camp"))
        elseif not radarMatch then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("tips_default_building_radar"))
        end
    end
    return false
end

function CityExplorerManager:IsAnyTeamMoving()
    for i, v in pairs(self._teams) do
        if v._teamData:IsInMoving() then
            return true
        end
    end
    return false
end

---@param context ClickNpcEventContext
---@param serviceId number
---@param team CityExplorerTeam
---@param teamPos CS.UnityEngine.Vector3
---@param targetPos CS.UnityEngine.Vector3
---@param elementConfigID number
---@param cityPos Coordinate
function CityExplorerManager:MakeGotNpcAction(context, serviceId, team, teamPos, targetPos, elementConfigID, cityPos)
    if self.city.elementManager:IsPolluted(elementConfigID) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("creep_clean_needed"))
        return
    end
    self:DoContinueGoToNpcWithTeam(team._teamPresetIdx, teamPos, targetPos, elementConfigID)
end

---@param context ClickNpcEventContext
---@param serviceId number
---@param team CityExplorerTeam
---@param teamPos CS.UnityEngine.Vector3
---@param targetPos CS.UnityEngine.Vector3
---@param elementConfigID number
---@param cityPos Coordinate
function CityExplorerManager:MakeGotSePanel(context, serviceId, team, teamPos, targetPos, elementConfigID, cityPos)
    ---@type CreateTouchMenuForCityContext
    local menuContext = {}
    menuContext.npcId = serviceId
    menuContext.troopPresetIdx = team._teamPresetIdx + 1
    menuContext.worldPos = targetPos
    menuContext.overrideGoToFunc = function()
        self:DoContinueGoToNpcWithTeam(team._teamPresetIdx, teamPos, targetPos, elementConfigID)
    end
    menuContext.elementId = elementConfigID
    menuContext.cityPos = cityPos
    menuContext.preSendEnterSceneOverride = nil
    menuContext.isGoto = true
    if self.city.elementManager:IsPolluted(elementConfigID) then
        menuContext.targetIsPolluted = true
        menuContext.pollutedHint = I18N.Get("creep_clean_needed")
    end
    ModuleRefer.SEPreModule:CreateTouchMenuForCity(menuContext)
end

---@param context ClickNpcEventContext
---@param serviceId number
---@param team CityExplorerTeam
function CityExplorerManager:MakeGoToCommitItemPanel(context, serviceId, team, teamPos, targetPos, elementConfigID)
    local tradeModule = ModuleRefer.StoryPopupTradeModule
    local serviceInfo = tradeModule:GetServicesInfo(NpcServiceObjectType.CityElement, elementConfigID, serviceId)
    local needItems = tradeModule:GetNeedItems(serviceId)
    local basicInfo = TouchMenuBasicInfoDatumSe.new()
    local eleConfig = ConfigRefer.CityElementData:Find(elementConfigID)
    local npcConfig = ConfigRefer.CityElementNpc:Find(eleConfig:ElementId())
    basicInfo:SetImage(npcConfig:Image())
    basicInfo:SetName(I18N.Get(npcConfig:Name()))
    local resInfo = TouchMenuCellResourceDatum.new()
    for _, v in pairs(needItems) do
        local itemId = v.id
        local count = v.count
        local addCount = serviceInfo[itemId] or 0
        local lakeCount = math.max(0, count - addCount)
        if lakeCount > 0 then
            ---@type TMCellResourceDatumUnit
            local oneItemData = TMCellResourceDatumUnit.new()
            oneItemData.itemId = itemId
            oneItemData.curValue = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
            oneItemData.maxValue = lakeCount
            table.insert(resInfo.data, oneItemData)
        end
    end
    resInfo.count = #resInfo.data
    local btnInfo = TouchMenuMainBtnDatum.new(I18N.Get("setips_btn_go"), function()
        self:DoContinueGoToNpcWithTeam(team._teamPresetIdx, teamPos, targetPos, elementConfigID)
    end)
    local btnGroup = TouchMenuHelper.GetRecommendButtonGroupDataArray({btnInfo})
    local uiDatum = TouchMenuHelper.GetSinglePageUIDatum(basicInfo,
            {resInfo}, btnGroup, nil):SetPos(targetPos)
    g_Game.UIManager:CloseByName(UIMediatorNames.TouchMenuUIMediator)
    g_Game.UIManager:Open(UIMediatorNames.TouchMenuUIMediator, uiDatum)
end

---@return RaisePowerPopupParam
function CityExplorerManager:BuildNpcLockedTaskGotoParam(npcElementId)
    ---@type RaisePowerPopupParam
    local ret = {}
    ret.overrideDefaultProvider = NpcLockedGotoProvider.new(npcElementId)
    return ret
end

function CityExplorerManager:NeedLoadView()
    return true
end

function CityExplorerManager:HasNpc(npcConfigId)
    return npcConfigId and self._cacheNpcIdSet[npcConfigId] ~= nil
end

function CityExplorerManager:GetCityElementIdByNpcId(npcConfigId)
    return self._cacheNpcIdSet[npcConfigId] or 0
end

---@param callback fun(isSuccess:boolean, bubbleWorldPos:CS.UnityEngine.Transform, bubble:CityTileAssetNpcBubbleCommon)
function CityExplorerManager:FocusOnNpcByConfigId(npcConfigId, callback)
    if not npcConfigId or not self:HasNpc(npcConfigId) then
        if callback then
            callback(false)
        end
        return false
    end
    local npcConfig = ConfigRefer.CityElementNpc:Find(npcConfigId)
    if not npcConfig then
        if callback then
            callback(false)
        end
        return false 
    end
    local cfg = ConfigRefer.CityElementData:Find(self._cacheNpcIdSet[npcConfigId])
    if not cfg then
        if callback then
            callback(false)
        end
        return false 
    end
    
    local pos = cfg:Pos()
    local cityPos = self.city:GetCenterWorldPositionFromCoord(pos:X(), pos:Y(), npcConfig:SizeX(), npcConfig:SizeY())
    ---@type CS.UnityEngine.Vector3
    local viewPortPos = CS.UnityEngine.Vector3(0.5, 0.5, 0.0)
    self.city.camera:ForceGiveUpTween()
    self.city.camera:ZoomToWithFocusBySpeed(CityConst.CITY_RECOMMEND_CAMERA_SIZE, viewPortPos, cityPos, nil, function()
        if callback then
            local element = self.city.elementManager:GetElementById(self._cacheNpcIdSet[npcConfigId])
            if element then
                local cell = self.city.grid:GetCell(pos:X(), pos:Y())
                if cell and cell:IsNpc() then
                    local view = self.city.gridView:GetCellTile(cell.x, cell.y)
                    ---@type CityTileViewNpc
                    local npcTileView = view and view.tileView
                    if npcTileView and npcTileView:is(CityTileViewNpc) and npcTileView.gameObjs then
                        for i, v in pairs(npcTileView.gameObjs) do
                            if i:is(CityTileAssetNpcBubbleCommon) then
                                ---@type CityTileAssetNpcBubbleCommon
                                local bubbleCommon = i
                                if bubbleCommon._bubble and Utils.IsNotNull(bubbleCommon._bubble.trigger) then
                                    callback(true, bubbleCommon._bubble.trigger.transform, bubbleCommon)
                                    return
                                end
                            end
                        end
                    end
                end
            end
            callback(false)
        end
    end)
    return true
end

function CityExplorerManager:FocusOnTeamAndOpenOperateMenu(presetIndex)
    local team = self:GetTeamByPresetIndex(presetIndex)
    if not team then return end
    local pos = team:GetPosition()
    if not pos then return end
    local needEnterState = true
    if self.city.stateMachine:GetCurrentStateName() == CityConst.STATE_EXPLORER_TEAM_OPERATE_MENU then
        ---@type CityStateExplorerTeamOperateMenu
        local state = self.city.stateMachine:GetCurrentState()
        if state.team == team then
            needEnterState = false
        else
            state:ExitToIdleState()
        end
    end
    local camera = self.city:GetCamera()
    camera:ForceGiveUpTween()
    camera:LookAt(pos, 0.2, function()
        if not needEnterState then return end
        local targetTeam = self:GetTeamByPresetIndex(presetIndex)
        if not targetTeam then return end
        g_Game.EventManager:TriggerEvent(EventConst.CITY_ORDER_EXPLORER_TEAM_OPERATE_MENU, self.city.uid, targetTeam)
    end)
    return true
end

function CityExplorerManager:SelectTeam(presetIndex)
    for _, team in pairs(self._teams) do
        team:SetShowSelected(presetIndex == team._teamPresetIdx)
    end
end

function CityExplorerManager:IsInSingleSeExplorerZone(x, y)
    local zone = self.city.zoneManager:GetZone(x, y)
    if not zone then return false end
    return zone:SingleSeExplorerOnly()
end

function CityExplorerManager:SelectPresetToExplorBrithPoint(elementId, zoneId)
    self:SelectPresetToExplorBrithPointWithCallback(elementId, zoneId, function(presetIdx, coordX, coordY, dirX, dirY)
        local team = self:GetTeamByPresetIndex(presetIdx)
        if team then
            self:SendDismissTeam(team, function(cmd, isSuccess, rsp)
                self:CreateHomeSeTroop(presetIdx, coordX, coordY,nil, nil, nil, dirX, dirY)
            end)
        else
            self:CreateHomeSeTroop(presetIdx, coordX, coordY, nil, nil, nil, dirX, dirY)
        end
    end)
end

CityExplorerManager.needTroopStatus = {
    [wds.TroopPresetStatus.TroopPresetInHome] = true,
    [wds.TroopPresetStatus.TroopPresetIdle] = true
}

---@param troopInfo TroopInfo
function CityExplorerManager.SelectPresetToExploreBrithPointFilter(troopInfo)
    return troopInfo ~= nil and troopInfo.preset ~= nil and CityExplorerManager.needTroopStatus[troopInfo.preset.Status]
end

---@param callback fun(presetIdx:number, coordX:number, coordY:number, dirX:number, dirY:number)
function CityExplorerManager:SelectPresetToExplorBrithPointWithCallback(elementId, zoneId, callback)
    local zone = self.city.zoneManager:GetZoneById(zoneId)
    local offset = zone.config:OpenDoorNpcSeTeamBrithOffset()
    local npcElement = self.city.elementManager:GetElementById(elementId)
    if not npcElement then
        g_Logger.Error("elementId:%s 找不到对应npc", elementId)
        return
    end
    local coordX,coordY = npcElement.x + offset:X(),npcElement.y + offset:Y()
    local dir = zone.config:OpenDoorNpcSeTeamBrithDir()
    local dirX,dirY = dir:X(), dir:Y()
    ---@type HUDSelectTroopListData
    local selectTroopData = {}
    selectTroopData.filter = CityExplorerManager.SelectPresetToExploreBrithPointFilter
    selectTroopData.overrideItemClickGoFunc = function(troopItemData)
        local idx, _ = self:GetPresetIndexAndTroopIdByPreset(troopItemData.troopInfo)
        if SlgUtils.PresetAllHeroInjured(troopItemData.troopInfo.preset, ModuleRefer.SlgModule.battleMinHpPct) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('toast_hp0_march_alert'))
            return
        end
        if idx and callback then
            callback(idx - 1, coordX, coordY, dirX, dirY)
        end
    end
    selectTroopData.isSE = true
    selectTroopData.needPower = 0
    selectTroopData.recommendPower = 0
    selectTroopData.costPPP = 0

    local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
    local matchCount = 0
    ---@type HUDSelectTroopListItemData
    local firstMatch = nil
    for i, troop in pairs(troops) do
        if HUDTroopUtils.DoesPresetHaveAnyHero(troop.preset) then
            if not selectTroopData.filter(troop) then
                goto continue
            end
            if not firstMatch then
                firstMatch = HUDSelectTroopList.MakeHUDSelectTroopListItemData(i, troop, selectTroopData, nil)
            end
            matchCount = matchCount + 1
        end
        ::continue::
    end
    if matchCount == 1 then
        selectTroopData.overrideItemClickGoFunc(firstMatch)
        return
    end
    if matchCount <= 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("radartask_toast_troop_busy"))
        return
    end
    HUDTroopUtils.StartMarch(selectTroopData)
end

---@return number, number
function CityExplorerManager:GetNearestSafeAreaWallDoorPos(coordX, coordY)
    local mgr = self.city.safeAreaWallMgr
    ---@type {centerGridX:number,centerGridY:number}
    local choose = nil
    local distance = nil
    for _,_,wall in mgr:WallPairs() do
        if wall.isDoor then
            local tmpD = (coordX - wall.centerGridX) * (coordX - wall.centerGridX) + (coordY - wall.centerGridY) * (coordY - wall.centerGridY)
            if not choose then
                choose = {centerGridX = wall.centerGridX, centerGridY = wall.centerGridY}
                distance = tmpD
            elseif tmpD < distance then
                distance = tmpD
                choose = {centerGridX = wall.centerGridX, centerGridY = wall.centerGridY}
            end
        end
    end
    local furnitureMgr = self.city.furnitureManager
    for _, furniture, _ in furnitureMgr:PairsOfDoorListenerFurniture() do
        if furniture then
            local x, y = furniture:CenterGrid()
            local tmpD = (coordX - x) * (coordX - x) + (coordY - y) * (coordY - y)
            if not choose then
                choose = {centerGridX = x, centerGridY = y}
                distance = tmpD
            elseif tmpD < distance then
                distance = tmpD
                choose = {centerGridX = x, centerGridY = y}
            end
        end
    end
    if choose then
        return choose.centerGridX,choose.centerGridY
    end
    return nil, nil
end

---@param interactEndAction CityExplorerTeamDefine.InteractEndAction
function CityExplorerManager:SelectPresetToNormalExplorTarget(elementId, interactEndAction)
    local element = self.city.elementManager:GetElementById(elementId)
    if not element then return end
    local coordX, coordY = self:GetNearestSafeAreaWallDoorPos(element.x, element.y)
    if not coordX or not coordY then return end
    local targetPos = self.city:GetWorldPositionFromCoord(element.x, element.y)
    local expectSpawnerId = elementId
    if element:IsSpawner() then
        local expeditionSet = self.city.elementManager:GetSpawnerLinkExpeditionId(elementId)
        if not expeditionSet then return end
        expectSpawnerId = nil
        local isSet = false
        for expeditionId, _ in pairs(expeditionSet) do
            expectSpawnerId = expeditionId
            break
        end
        if not expectSpawnerId then return end
    end
    ---@type HUDSelectTroopListData
    local selectTroopData = {}
    local needTroopStatus = {}
    needTroopStatus[wds.TroopPresetStatus.TroopPresetInHome] = true
    needTroopStatus[wds.TroopPresetStatus.TroopPresetIdle] = true
    selectTroopData.filter = function(troopInfo)
        if not troopInfo or not troopInfo.preset then return false end
        local presetIndex,_ = self:GetPresetIndexAndTroopIdByPreset(troopInfo)
        if not presetIndex then return false end
        if not needTroopStatus[troopInfo.preset.Status] then return false end
        local team = self._teams[presetIndex - 1]
        if not team then return true end
        return team:InCanReSetTargetState()
    end
    selectTroopData.overrideItemClickGoFunc = function(troopItemData)
        local idx, _ = self:GetPresetIndexAndTroopIdByPreset(troopItemData.troopInfo)
        if idx then
            local presetIndex = idx - 1
            local team = self:GetTeamByPresetIndex(presetIndex)
            if team then
                self:ReSetHomeSeTroopExpectSpawnerId(presetIndex, expectSpawnerId, function()
                    self:SetTeamTarget(presetIndex, targetPos, elementId, interactEndAction)
                end)
            else
                if SlgUtils.PresetAllHeroInjured(troopItemData.troopInfo.preset, ModuleRefer.SlgModule.battleMinHpPct) then
                    ModuleRefer.ToastModule:AddSimpleToast(I18N.Get('toast_hp0_march_alert'))
                    return
                end
                self:CreateHomeSeTroop(presetIndex, coordX, coordY, true, expectSpawnerId, function()
                    self:SetTeamTarget(presetIndex, targetPos, elementId, interactEndAction)
                end)
            end
        end
    end
    selectTroopData.isSE = true
    selectTroopData.needPower = 0
    selectTroopData.recommendPower = 0
    selectTroopData.costPPP = 0
    local troops = ModuleRefer.SlgModule:GetMyTroops() or {}
    local matchCount = 0
    ---@type HUDSelectTroopListItemData
    local firstMatch = nil
    for i, troop in pairs(troops) do
        if HUDTroopUtils.DoesPresetHaveAnyHero(troop.preset) then
            if not firstMatch then
                firstMatch = HUDSelectTroopList.MakeHUDSelectTroopListItemData(i, troop, selectTroopData, nil)
            end
            matchCount = matchCount + 1
        end
        ::continue::
    end
    if matchCount == 1 then
        selectTroopData.overrideItemClickGoFunc(firstMatch)
        return
    end
    if matchCount <= 0 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("radartask_toast_troop_busy"))
        return
    end
    HUDTroopUtils.StartMarch(selectTroopData)
end

---@param interactEndAction CityExplorerTeamDefine.InteractEndAction
function CityExplorerManager:SetTeamTarget(presetIndex, targetPos, elementId, interactEndAction)
    local team = self._teams[presetIndex]
    if team then
        self:DoContinueGoToNpcWithTeam(presetIndex, team:GetPosition(), targetPos, elementId, interactEndAction)
    else
        self:DoContinueGoToNpcWithTeam(presetIndex, nil, targetPos, elementId, interactEndAction)
    end
end

function CityExplorerManager:HasInProgressOpenTreasure()
    return not table.isNilOrZeroNums(self._tTickTreasureProgress)
end

---@return {duration:number, endTime:number, targetId:number}|nil
function CityExplorerManager:GetCurrentOpenTreasureProgress(elementId)
    return self._tTickTreasureProgress[elementId]
end

---@return CityExplorerTeam
function CityExplorerManager:GetTeamByPresetIndex(presetIndex)
    for _, value in pairs(self._teams) do
        if value._teamPresetIdx == presetIndex then
            return value
        end
    end
    return nil
end

function CityExplorerManager:SetAllowShowLine(allow)
    self._allowShowLines = allow
    for _, value in pairs(self._teams) do
        value:SetAllowShowLine(allow)
    end
end

function CityExplorerManager:SetAllowTeamTroopTriggerOn(on)
    if self._teamTroopTriggerOn == on then return end
    self._teamTroopTriggerOn = on
    for _, value in pairs(self._teams) do
        value:SetupSlgTroopTrigger(on)
    end
end

function CityExplorerManager:ExitInExplorerMode(lockable, callback)
    if not self.city:IsInSingleSeExplorerMode() then
        return false
    end
    ---@type CityStateSeExplorerFocus
    local state = self.city.stateMachine:GetCurrentState()
    local presetIndex = state:GetCurrentPresetIndex()
    if not presetIndex then return false end
    --local sendCmd = HomeSeInExploreParameter.new()
    --sendCmd.args.InExplore = false
    --sendCmd.args.PresetIndex = presetIndex
    --sendCmd:SendOnceCallback(lockable, nil, nil, callback)
    local sendCmd = RecallHomeSeTroopParameter.new()
    sendCmd.args.PresetIndex = presetIndex
    sendCmd.args.Suc = true
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
    return true
end

function CityExplorerManager:CreateHomeSeTroop(presetIndex, coordX, coordY, slgMode, elementId, callback, dirX, dirY, lockable)
    local sendCmd = CreateHomeSeTroopParameter.new()
    sendCmd.args.PresetIndex = presetIndex
    sendCmd.args.InExplore = not slgMode
    sendCmd.args.BornPos.X = coordX
    sendCmd.args.BornPos.Y = coordY
    sendCmd.args.BornDir.X = dirX or 0
    sendCmd.args.BornDir.Y = dirY or 0
    sendCmd.args.ExpectSpawnerId = elementId or 0
    sendCmd.args.BornPos.Z = 0
    sendCmd:SendOnceCallback(lockable, nil, nil, function(cmd,isSuccess,rsp)
        if isSuccess  then
            if callback then
                callback()
            end
        end
    end)
end

function CityExplorerManager:ReSetHomeSeTroopExpectSpawnerId(presetIndex, elementId, callback, lockable)
    local sendCmd = ReSetHomeSeTroopExpectSpawnerIdParameter.new()
    sendCmd.args.PresetIndex = presetIndex
    sendCmd.args.ExpectSpawnerId = elementId or 0
    sendCmd:SendOnceCallback(lockable, nil, nil, function(cmd,isSuccess,rsp)
        if isSuccess then
            if callback then
                callback()
            end

            --切完都移动
            local entity = g_Game.DatabaseManager:GetEntity(elementId, DBEntityType.Expedition)
            if entity then
                local pos = CS.UnityEngine.Vector3(entity.MapBasics.Position.X,entity.MapBasics.Position.Y,entity.MapBasics.Position.Z)
                self.city.citySeManger:MoveToWorldPos(nil, presetIndex,pos)
            end
        end
    end)
end

---@param team CityExplorerTeam
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function CityExplorerManager:SendDismissTeam(team, callback, lockable)
    local sendCmd = RecallHomeSeTroopParameter.new()
    sendCmd.args.PresetIndex = team._teamPresetIdx
    sendCmd:SendOnceCallback(lockable, nil, nil, function(cmd,isSuccess,rsp)
        if isSuccess then
            if callback then
                callback()
            end
            -- ModuleRefer.ToastModule:AddSimpleToast("#部队已返回")
            local pos = team._teamTrigger._selectRing.transform.position
            CS.DragonReborn.SLG.Troop.TroopViewVfxUtilities.CreateVfx(SLGConst_Manual.troopDisapearVfxInCity,pos,CS.UnityEngine.Vector3.forward,0.4,2,1)
        end
    end)
end

function CityExplorerManager:NeedTickExploreRangeInCityState()
    return self.city:IsInSeBattleMode() or self.city:IsInSingleSeExplorerMode() or self.city:IsInRecoverZoneEffectMode()
end

function CityExplorerManager:CheckShowUnderExploreModeByRangeEvent(elementId)
    if not self:NeedTickExploreRangeInCityState() then return true end
    local showValue = self._inRangeNpcMap[elementId]
    return showValue == true
end

function CityExplorerManager:NpcNeedRegRangeEventAndParam(elementId)
    local config = ConfigRefer.CityElementData:Find(elementId)
    if not config or config:Type() ~= CityElementType.Npc then return false end
    local npcConfig = ConfigRefer.CityElementNpc:Find(config:ElementId())
    if not npcConfig or npcConfig:NoInteractable() or npcConfig:NoInteractableInSEExplore() then return false end
    local elePos = config:Pos()
    local worldPos = self.city:GetElementNpcInteractPos(elePos:X(), elePos:Y(), npcConfig)
    return true, worldPos, self:DoGetTargetNpcRadius(npcConfig)
end

function CityExplorerManager:RegNpcRangeEvent(elementId, worldPos, radius)
    self._singleExploreRangeEventMgr:AddOrUpdateListener(elementId, worldPos, radius)
end

function CityExplorerManager:UnRegNpcRangeEvent(elementId)
    if not self._singleExploreRangeEventMgr then return end
    self._singleExploreRangeEventMgr:RemoveListener(elementId)
end

function CityExplorerManager:OnDebugGizmos()
    if self._singleExploreRangeEventMgr then
        self._singleExploreRangeEventMgr:DebugDrawGizmos()
    end
end

return CityExplorerManager
