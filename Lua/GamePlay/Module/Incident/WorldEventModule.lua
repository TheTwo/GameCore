local BaseModule = require('BaseModule')
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local KingdomMapUtils = require("KingdomMapUtils")
local TimerUtility = require('TimerUtility')
local PlayType = require('PlayType')
local DBEntityType = require('DBEntityType')
local EventConst = require('EventConst')
local DBEntityPath = require('DBEntityPath')
local Delegate = require('Delegate')
local UIMediatorNames = require('UIMediatorNames')
local UIAsyncDataProvider = require('UIAsyncDataProvider')
local ManualResourceConst = require('ManualResourceConst')
local ManualUIConst = require('ManualUIConst')
local GuideFingerUtil = require('GuideFingerUtil')
local I18N = require('I18N')
local ProgressType = require('ProgressType')
local AllianceExpeditionOpenType = require('AllianceExpeditionOpenType')
local ToastFuncType = require("ToastFuncType")
local ObjectType = require('ObjectType')
local MathUtils = require('MathUtils')
local TimeFormatter = require('TimeFormatter')
local ProtocolId = require('ProtocolId')
local CommonConfirmPopupMediatorDefine = require('CommonConfirmPopupMediatorDefine')
local NotificationType = require('NotificationType')
local WorldEventDefine = require('WorldEventDefine')
local AllianceExpeditionCreateType = require('AllianceExpeditionCreateType')
local ActivityCenterConst = require('ActivityCenterConst')

local Vector3 = CS.UnityEngine.Vector3
local PooledGameObjectCreateHelper = CS.DragonReborn.AssetTool.PooledGameObjectCreateHelper
local SceneLoadUtility = CS.DragonReborn.AssetTool.SceneLoadUtility

---@class WorldEventModule
local WorldEventModule = class('WorldEventModule', BaseModule)
local UseItemWorldExpeditionTemplateId = {20027, 20028}
local UseItemAllianceExpeditionId = {13, 14}

function WorldEventModule:GetUseItemId(index)
    return UseItemWorldExpeditionTemplateId[index]
end

-- 是否为 大嘴鸟小事件
function WorldEventModule:IsExpeditionUseItem(expeditionCfgId)
    for k, v in pairs(UseItemWorldExpeditionTemplateId) do
        if expeditionCfgId == v then
            return true
        end
    end
    return false
end

function WorldEventModule:OnRegister()
    self.filterType = wrpc.RadarEntityType.RadarEntityType_Expedition
    self.createHelper = PooledGameObjectCreateHelper.Create("WorldEvent")
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceExpedition.Expeditions.MsgPath, Delegate.GetOrCreate(self, self.OnEventSettle))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceExpedition.Expeditions.MsgPath, Delegate.GetOrCreate(self, self.CheckAllianceEventPreviewToast))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.AllianceExpeditionActivatorUseRet, Delegate.GetOrCreate(self, self.OnUseItem))

    self.PopUpTable = {}
    self.ToastTable = {}
    self.showToast = false
end

function WorldEventModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceExpedition.Expeditions.MsgPath, Delegate.GetOrCreate(self, self.OnEventSettle))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceWrapper.AllianceExpedition.Expeditions.MsgPath, Delegate.GetOrCreate(self, self.CheckAllianceEventPreviewToast))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.AllianceExpeditionActivatorUseRet, Delegate.GetOrCreate(self, self.OnUseItem))

    self.ToastTable = {}
end

function WorldEventModule:SetUp()
    self:UpdateWorldEventRedDots()
end

function WorldEventModule:SetWorldEventByPanel(entity, isBigEvent)
    self.worldEventEntity = entity
    self.isBigEvent = isBigEvent
end

function WorldEventModule:SetFilterType(filterType)
    self.filterType = filterType
end

function WorldEventModule:GetFilterType()
    return self.filterType
end

function WorldEventModule:CheckIsShow(uniqueId, typeId, calculatePosition)
    ---@type wds.Expedition
    local entity = g_Game.DatabaseManager:GetEntity(uniqueId, typeId)
    if not entity then
        return
    end

    local inAlliance = true
    local isAlliance = false
    local config = ConfigRefer.WorldExpeditionTemplate:Find(entity.ExpeditionInfo.Tid)
    local progressType = config:ProgressType()
    if progressType == ProgressType.Alliance then
        isAlliance = true
        local useItemEventId = self:GetPersonalOwnAllianceExpedition()
        -- 本联盟的小事件 特殊处理 非本人召唤的不显示
        if entity.ExpeditionInfo.Tid == UseItemWorldExpeditionTemplateId[1] or entity.ExpeditionInfo.Tid == UseItemWorldExpeditionTemplateId[2] then
            local player = ModuleRefer.PlayerModule:GetPlayer()
            if entity.Owner.ExclusivePlayerId == player.ID then
                inAlliance = true
            else
                inAlliance = false
            end
            -- 非本联盟的联盟世界事件 不显示
        elseif entity.Owner.ExclusiveAllianceId ~= ModuleRefer.AllianceModule:GetAllianceId() then
            inAlliance = false
        end
    end
    -- 个人世界事件只有自己能看到
    local isMine = entity.Owner.ExclusivePlayerId == ModuleRefer.PlayerModule:GetPlayer().ID
    -- 多人世界事件都能看到
    local isMulti = entity.Owner.ExclusivePlayerId == 0

    local canShow = (isMulti or (not isMulti and isMine))
    if isAlliance then
        canShow = inAlliance
    end
    local isInTime = true
    if entity.ExpeditionInfo.ActivateEndTime > 0 then
        isInTime = entity.ExpeditionInfo.ActivateEndTime > g_Game.ServerTime:GetServerTimestampInSeconds()
    end
    local mapSystem = KingdomMapUtils.GetMapSystem()
    local lod = mapSystem.Lod
    local isInLod = lod <= 2

    local eventCfg = ConfigRefer.WorldExpeditionTemplate:Find(entity.ExpeditionInfo.Tid)
    if not eventCfg then
        return
    end
    local percent = 0
    if eventCfg:PlayType() == PlayType.Boss then
        local bossID = entity.ExpeditionInfo.ProgressRelatedEntityId
        local bossEntity = g_Game.DatabaseManager:GetEntity(bossID, DBEntityType.MapMob)
        if bossEntity then
            percent = math.clamp(1 - bossEntity.Battle.Hp / bossEntity.Battle.MaxHp, 0, 1)
        end
    else
        local progress = 0
        progress = entity.ExpeditionInfo.PersonalProgress[ModuleRefer.PlayerModule:GetPlayer().ID] or 0
        percent = math.clamp(progress / eventCfg:MaxProgress(), 0, 1)
    end
    local isFinish = percent >= 1
    local pos = calculatePosition()
    local coord = CS.Grid.MapUtils.CalculateWorldPositionToCoord(pos, KingdomMapUtils.GetStaticMapData())
    local fogCellUnlocked = true
    -- local fogCellUnlocked = ModuleRefer.MapFogModule:IsFogUnlocked(coord.X, coord.Y)
    return canShow and isInLod and isInTime and not isFinish and fogCellUnlocked
end

function WorldEventModule:LoadWorldCompletedEffect(parent)
    local handle = self.createHelper:Create(ManualResourceConst.vfx_w_world_event_circle_complete_yellow, parent, function(go)
        go.transform.localPosition = Vector3.zero
        go.transform.localScale = Vector3.one * 0.5
        go.transform.eulerAngles = Vector3.one
        go.transform:SetParent(nil)
    end)
    TimerUtility.DelayExecute(function()
        handle:Delete()
    end, 1.5)
end

function WorldEventModule:IsWorldEventActive(uniqueId)
    ---@type wds.Expedition
    local entity = g_Game.DatabaseManager:GetEntity(uniqueId, DBEntityType.Expedition)
    if not entity then
        return false
    end
    return entity.ExpeditionInfo.State == wds.ExpeditionState.ExpeditionActive
end

function WorldEventModule:RefreshProgress()
    g_Game.EventManager:TriggerEvent(EventConst.WORLD_EVENT_PROGRESS)
end

function WorldEventModule:GetAllianceExpeditions()
    local allianceInfo = ModuleRefer.AllianceModule:GetMyAllianceData()
    if allianceInfo then
        return allianceInfo.AllianceWrapper.AllianceExpedition.Expeditions
    end
    return nil
end

function WorldEventModule:GetAllianceActivityExpeditionByExpeditionID(id)
    local data = self:GetAllianceExpeditions()
    if not data then
        return nil
    end

    for k, v in pairs(data) do
        if v.ExpeditionConfigId == id then
            return v
        end
    end

    return nil
end

function WorldEventModule:GetAllianceActivityExpeditionByConfigID(id, isPlayerOwn)
    local data = self:GetAllianceExpeditions()
    if not data then
        return nil
    end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    for k, v in pairs(data) do
        if v.ConfigId == id then
            if isPlayerOwn then
                if v.CreatePlayerId == player.ID then
                    return v
                end
            else
                return v
            end
        end
    end

    return nil
end

-- 检查是否个人使用道具召唤过一个世界事件
function WorldEventModule:GetPersonalOwnAllianceExpedition()
    local data = self:GetAllianceExpeditions()
    if not data then
        return nil
    end
    local player = ModuleRefer.PlayerModule:GetPlayer()
    for k, v in pairs(data) do
        for i = 1, ConfigRefer.AllianceConsts:AllianceUseItemExpeditionsLength() do
            local tabCfg = ConfigRefer.AllianceConsts:AllianceUseItemExpeditions(i)
            local id = ConfigRefer.ActivityCenterTabs:Find(tabCfg):RefAllianceActivityExpedition(1)
            if v.ConfigId == id and v.CreatePlayerId == player.ID then
                return id
            end
        end
    end

    return nil
end

---@return table<number, wds.PlayerAllianceExpeditionRecord> | MapField
function WorldEventModule:GetAllianceExpeditionRecord()
    local record = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerExpeditions.AllianceExpeditionRecord
    return record
end

function WorldEventModule:GetAllianceEventTime(ConfigId, isPreview)
    local curTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    local cfg = ConfigRefer.AllianceActivityExpedition:Find(ConfigId)
    if not cfg then
        return 0, 0, 0
    end
    local activity
    if isPreview then
        activity = cfg:Preview()
    else
        activity = cfg:Activities(1)
    end

    local cfg2 = ConfigRefer.ActivityTemplate:Find(activity)
    if cfg2 == nil then
        return 0, 0, 0
    end

    local startT, endT = ModuleRefer.ActivityCenterModule:GetActivityStartEndTimeByActivityTemplateId(cfg2:Id())
    local endTime = endT.Seconds
    local remainTime = endTime - curTime
    return startT.Seconds, endTime, remainTime
end

function WorldEventModule:GetActivityCountDown(activityID)
    local kingdom = ModuleRefer.KingdomModule:GetKingdomEntity()
    local activityInfo = kingdom.ActivityInfo.Activities[activityID]
    if not activityInfo then
        return 0, 0
    end

    local activityStartT = activityInfo.StartTime.Seconds
    local activityEndT = activityInfo.EndTime.Seconds
    return activityStartT, activityEndT
end

function WorldEventModule:GetSpawnerUnit(expeditionID)
    local res = {}
    local expeditionCfg = ConfigRefer.WorldExpeditionTemplate:Find(expeditionID)
    local spawner = expeditionCfg:SpawnerBase()
    -- local editor = expeditionCfg:EditorName()

    -- Spawn类型的 有进度值。
    if spawner > 0 then
        local spawnerbaseCfg = ConfigRefer.SpawnerBaseRule:Find(spawner)
        for i = 1, spawnerbaseCfg:UnitsLength() do
            local cfg = ConfigRefer.SpawnerUnit:Find(spawnerbaseCfg:Units(i))
            local param = {}
            param.maxValue = cfg:SpawnMaxCount()
            param.spawnType = cfg:ObjectType()
            param.spawnID = cfg:Tid()
            res[i] = param
        end
    else
        -- TODO: 编辑器类型的 没有进度值 尚未处理

        for i = 1, 2 do
            local param = {}
            param.maxValue = 0
            res[i] = param
        end
    end

    return res
end

function WorldEventModule:NeedAcceptAllianceEvent(ConfigId)
    local entity = self:GetExpeditionEntity(ConfigId)
    return entity and entity.ExpeditionInfo.State == wds.ExpeditionState.ExpeditionNotice or false
end

function WorldEventModule:GetExpeditionEntity(ConfigId)
    local expeditionInfo = self:GetAllianceActivityExpeditionByConfigID(ConfigId)
    if not expeditionInfo then
        return nil
    end

    local entity = g_Game.DatabaseManager:GetEntity(expeditionInfo.ExpeditionEntityId, DBEntityType.Expedition)
    return entity
end

function WorldEventModule:GetPersonalRewardByExpeditionID(expeditionId)
    local cfg = ConfigRefer.WorldExpeditionTemplate:Find(expeditionId)
    local res = {}
    for i = 1, cfg:PartProgressRewardLength() do
        local temp = {}
        temp.progress = cfg:PartProgressReward(i):Progress()
        temp.reward = cfg:PartProgressReward(i):Reward()
        res[i] = temp
    end
    return res
end

function WorldEventModule:GetPersonalExpeditionInfo(expeditionID)
    local joinExpeditions = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerExpeditions.JoinExpeditions
    for k, v in pairs(joinExpeditions) do
        if v.ExpeditionInstanceTid == expeditionID then
            return v
        end
    end
    return {Progress = 0, PersonalProgress = 0, stageRewardState = {}}
end

-- 联盟世界事件结算
function WorldEventModule:OnEventSettle(entity, changedData)
    if changedData and changedData.Add and type(changedData.Add) == 'table' then
        for k, v in pairs(changedData.Add) do
            if v.Status == wds.AllianceExpeditionStatus.AllianceExpeditionStatusSettling then
                self:TryOpenSettlePanel(v.ExpeditionEntityId)
                return
            end
        end
    end
end

function WorldEventModule:TryOpenSettlePanel(ExpeditionEntityId)
    local entity = g_Game.DatabaseManager:GetEntity(ExpeditionEntityId, DBEntityType.Expedition)
    if not entity then
        return
    end
    local allianceCfgId = self:GetAllianceActivityExpeditionByExpeditionID(entity.ExpeditionInfo.Tid).ConfigId
    local allianceCfg = ConfigRefer.AllianceActivityExpedition:Find(allianceCfgId)
    local type = allianceCfg:OpenType()
    local createType = allianceCfg:CreateType()
    -- 使用道具小事件 不显示结算
    if createType == AllianceExpeditionCreateType.ItemActivator then
        return
    end

    -- 联盟小事件，没参加不显示结算界面
    local ProgressList = entity.ExpeditionInfo.PersonalProgress
    local sum = 0
    for k, v in pairs(ProgressList) do
        sum = sum + v
    end

    if type == AllianceExpeditionOpenType.Manual then
        local selfID = ModuleRefer.PlayerModule:GetPlayer().ID
        local isJoin = false
        for k, v in pairs(ProgressList) do
            if k == selfID then
                isJoin = true
                break
            end
        end
        if not isJoin then
            return
        end
    end

    if sum > 0 then
        self:AllianceEventSettlement(ProgressList)
    end
end

-- 联盟世界事件结算界面
function WorldEventModule:AllianceEventSettlement(ProgressList)
    local name = UIMediatorNames.AllianceWorldEventSettlementMediator
    local check = UIAsyncDataProvider.CheckTypes.DoNotShowInGVE | UIAsyncDataProvider.CheckTypes.DoNotShowInSE | UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator |
                      UIAsyncDataProvider.CheckTypes.DoNotShowInCitySE
    local failStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
    local param = {ProgressList = ProgressList, isWin = true}
    local provider = UIAsyncDataProvider.new()
    provider:Init(name, nil, check, failStrategy, false, param)
    provider:SetOtherMediatorCheckType(g_Game.UIManager.UIMediatorType.Dialog | g_Game.UIManager.UIMediatorType.Popup)
    g_Game.UIAsyncManager:AddAsyncMediator(provider)
end

-- 联盟世界事件预告toast
function WorldEventModule:CheckAllianceEventPreviewToast(entity, changedData)
    if changedData and changedData.Add and type(changedData.Add) == 'table' then
        for k, v in pairs(changedData.Add) do
            local expedition = g_Game.DatabaseManager:GetEntity(v.ExpeditionEntityId, DBEntityType.Expedition)
            if expedition and expedition.ExpeditionInfo.State == wds.ExpeditionState.ExpeditionActive then
                if v.Progress == 0 and self.ToastTable[expedition.ID] then
                    self:OpenPreviewToast(expedition)
                    self.ToastTable[expedition.ID] = nil
                end
            elseif expedition and expedition.ExpeditionInfo.State == wds.ExpeditionState.ExpeditionNotice then
                if not self.ToastTable[expedition.ID] then
                    self.ToastTable[expedition.ID] = true
                end
            end
        end
    end
end

function WorldEventModule:OpenPreviewToast(entity)
    local config = ConfigRefer.WorldExpeditionTemplate:Find(entity.ExpeditionInfo.Tid)

    local name = UIMediatorNames.CommonNotifyPopupMediator
    local check = UIAsyncDataProvider.CheckTypes.DoNotShowInGVE | UIAsyncDataProvider.CheckTypes.DoNotShowInSE | UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator |
                      UIAsyncDataProvider.CheckTypes.DoNotShowInCitySE
    local failStrategy = UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable
    local param = {}
    param.entity = entity
    param.title = I18N.GetWithParams("Radar_discover_elite", I18N.Get(config:Name()))
    param.textBlood = ""
    param.funcType = ToastFuncType.ExpeditionNotice
    param.content = I18N.GetWithParams("WorldExpedition_share_title", I18N.Get(config:Name()))
    param.duration = 2
    param.fromServer = false
    param.acceptAction = function()
        local scene = g_Game.SceneManager.current
        local pos = entity.MapBasics.Position
        if scene:IsInCity() then
            local callback = function()
                local myCityPosition = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(math.floor(pos.X), math.floor(pos.Y), KingdomMapUtils.GetMapSystem())
                KingdomMapUtils.MoveAndZoomCamera(myCityPosition, KingdomMapUtils.GetCameraLodData().mapCameraEnterSize)
            end
            scene:LeaveCity(callback)
        else
            local myCityPosition = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(math.floor(pos.X), math.floor(pos.Y), KingdomMapUtils.GetMapSystem())
            KingdomMapUtils.MoveAndZoomCamera(myCityPosition, KingdomMapUtils.GetCameraLodData().mapCameraEnterSize)
        end
    end

    local provider = UIAsyncDataProvider.new()
    provider:Init(name, nil, check, failStrategy, false, param)
    provider:SetOtherMediatorCheckType(g_Game.UIManager.UIMediatorType.Dialog | g_Game.UIManager.UIMediatorType.Popup)
    g_Game.UIAsyncManager:AddAsyncMediator(provider)
end

-- 上锁
function WorldEventModule:SetShowToast(isShow)
    if self.showToast ~= isShow then
        self.showToast = isShow
    end
end

function WorldEventModule:GetShowToast()
    return self.showToast
end

-- 从圈内 镜头跳转到世界事件圈内的野怪/交互物上
function WorldEventModule:GotoSpawernUnit(spawnID, spawnType, expeditionId)
    local entityType
    if spawnType == ObjectType.SlgMob then
        entityType = DBEntityType.MapMob
    elseif spawnType == ObjectType.SlgInteractor then
        entityType = DBEntityType.SlgInteractor
    end

    local target
    local entities = g_Game.DatabaseManager:GetEntitiesByType(entityType)
    for k, v in pairs(entities) do
        if v.LevelEntityInfo.LevelEntityId == expeditionId then
            if spawnType == ObjectType.SlgMob and spawnID == v.MobInfo.MobID then
                target = v
                break
            elseif spawnType == ObjectType.SlgInteractor and spawnID == v.Interactor.ConfigID then
                target = v
                break
            end
        end
    end

    if not target then
        return false
    end

    local startCoorPos = target.MapBasics.Position
    local startWorldPos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(math.floor(startCoorPos.X), math.floor(startCoorPos.Y), KingdomMapUtils.GetMapSystem())
    KingdomMapUtils.GetBasicCamera():ForceGiveUpTween()
    KingdomMapUtils.MoveAndZoomCamera(startWorldPos, KingdomMapUtils.GetCameraLodData().mapCameraEnterSize, nil, nil, nil, function()
        GuideFingerUtil.ShowGuideFingerByWorldPos(startWorldPos)
    end)

    return true
end

-- 从任意位置 镜头跳转到世界事件圈内的野怪上
function WorldEventModule:GotoAllianceExpedition(cfgId, isPlayerOwn)
    local allianceEventInfo = self:GetAllianceActivityExpeditionByConfigID(cfgId, isPlayerOwn)
    if allianceEventInfo == nil then
        return
    end
    local x, z = KingdomMapUtils.ParseCoordinate(allianceEventInfo.BornPos.X, allianceEventInfo.BornPos.Y)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.EarthRevivalMediator)
    local pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(x, z, KingdomMapUtils.GetMapSystem())
    local mapBasic = self:GetRandomWorldEventMobPos()
    if mapBasic then
        local tempx, tempz = KingdomMapUtils.ParseCoordinate(mapBasic.Position.X, mapBasic.Position.Y)
        pos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(tempx, tempz, KingdomMapUtils.GetMapSystem())
    end

    local camerMoveCallBack = function()
        GuideFingerUtil.ShowGuideFingerByWorldPos(pos)
        if not ModuleRefer.MapFogModule:IsFogUnlocked(x, z) then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("Radar_mist_condition"))
            return
        end
    end
    self:GotoPos(pos, camerMoveCallBack)
end

function WorldEventModule:GotoPos(pos, camerMoveCallBack)
    KingdomMapUtils.GetBasicCamera():ForceGiveUpTween()
    KingdomMapUtils.GetBasicCamera():ZoomTo(KingdomMapUtils.GetCameraLodData().mapCameraEnterSize)
    KingdomMapUtils.GetBasicCamera():LookAt(pos, 2, camerMoveCallBack)
end

function WorldEventModule:GetRandomWorldEventMobPos()
    ---@type wds.MapMob
    local troops = g_Game.DatabaseManager:GetEntitiesByType(DBEntityType.MapMob)
    for _, troop in pairs(troops) do
        if troop.Owner.SpawnerId == self.ExpeditionEntityId then
            return troop.MapBasics
        end
    end
end

-- 大事件 抛物线刷怪特效
function WorldEventModule:SpawnProjectile(entity)
    local startScreenPos = Vector3(-CS.UnityEngine.Screen.width, CS.UnityEngine.Screen.height / 2, 0)
    local startWorldPos = KingdomMapUtils.ScreenToWorldPosition(startScreenPos) + Vector3(0, 500, 0)

    local endCoorPos = entity.MapBasics.Position
    local endWorldPos = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(math.floor(endCoorPos.X), math.floor(endCoorPos.Y), KingdomMapUtils.GetMapSystem()) + Vector3(0, 1, 0)

    local fly_duration = 2
    local stay_duration = 1

    local root = SceneLoadUtility.GetRoot('grid_map_system')
    local projectileVfx = CS.DragonReborn.VisualEffect.VisualEffectHandle()
    local spawnVfx = CS.DragonReborn.VisualEffect.VisualEffectHandle()

    -- Test ManualResourceConst.ui_hud_city_vfx_word_event_trail
    projectileVfx:Create(ManualResourceConst.ui_hud_city_vfx_word_event_trail, ManualResourceConst.ui_hud_city_vfx_word_event_trail, root.transform, function(success, obj, handle)
        if success then
            -- 拖尾特效
            local go = handle.Effect.gameObject
            go.transform.position = startWorldPos
            go.transform.localScale = Vector3.one * 5

            -- 俯视角
            local pivot = Vector3(0, 1, 0)
            MathUtils.Paracurve(go.transform, go.transform.position, endWorldPos, pivot, 10, 8, fly_duration)

            -- 拖尾结束生成菌毯瘤
            TimerUtility.DelayExecute(function()
                go:SetVisible(false)
                spawnVfx:Create("fx_monster_juntang_born", "fx_monster_juntang_born", root.transform, function(success, obj, handle)
                    if success then
                        -- 菌毯瘤特效
                        local go = handle.Effect.gameObject
                        go.transform.position = startWorldPos
                        go.transform.localScale = Vector3.one * 5
                        -- 菌毯瘤结束 显示野怪
                        TimerUtility.DelayExecute(function()
                            -- TODO:怪物初始时fly_duration+stay_duration内不能移动
                            -- spawnVfx:Delete()
                            -- projectileVfx:Delete()
                        end, stay_duration)
                    end
                end, nil, 0, false, false)
            end, fly_duration)
        end
    end, nil, 0, false, false)

end

-- 世界事件预告特效点击/拖曳部队 toast
function WorldEventModule:GetPreviewPrompt()
    if self.isBigEvent then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_worldevent_open_requirement"))
    else
        local allianceExpeditionsInfo = self:GetAllianceActivityExpeditionByExpeditionID(self.worldEventEntity.ExpeditionInfo.Tid)
        local curTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        local startT = allianceExpeditionsInfo.StartActiveTime
        local remainT = TimeFormatter.SimpleFormatTime(math.max(0, startT - curTime))
        ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("alliance_worldevent_open_times", remainT))
    end
end

-- 区分大小联盟世界事件
function WorldEventModule:IsAllianceBigWorldEvent(expeditionID)
    local allianceExpedition = self:GetAllianceActivityExpeditionByExpeditionID(expeditionID)
    if allianceExpedition == nil then
        return false
    end

    local allianceCfgId = allianceExpedition.ConfigId
    local allianceCfg = ConfigRefer.AllianceActivityExpedition:Find(allianceCfgId)
    if allianceCfg == nil then
        g_Logger.Error("Missing AllianceActivityExpedition: " .. allianceCfgId)
        return false
    end

    local type = allianceCfg:OpenType()
    if type == AllianceExpeditionOpenType.Manual then
        return true
    else
        return false
    end
end

function WorldEventModule:GetAllianceExpeditionCfgByLands(AllianceExpeditions)
    local allianceCenter = ModuleRefer.VillageModule:GetCurrentEffectiveAllianceCenterVillage()
    if not allianceCenter then
        return nil
    end

    local territoryID = allianceCenter.VID
    local territoryConfig = ConfigRefer.Territory:Find(territoryID)
    local land = territoryConfig:LandId()
    for k, v in pairs(AllianceExpeditions) do
        local cfg = ConfigRefer.AllianceActivityExpedition:Find(v)
        for i = 1, cfg:LandsLength() do
            if cfg:Lands(i) == land then
                return v
            end
        end
    end
    return nil
end

-- 获得事件类型
function WorldEventModule:CheckEventType(entity)
    local isMine = entity.Owner.ExclusivePlayerId == ModuleRefer.PlayerModule:GetPlayer().ID
    local isMulti = entity.Owner.ExclusivePlayerId == 0 and entity.Owner.ExclusiveAllianceId == 0
    local isAlliance = entity.Owner.ExclusiveAllianceId == ModuleRefer.AllianceModule:GetAllianceId()
    local isBigEvent = false
    if isAlliance then
        isBigEvent = self:IsAllianceBigWorldEvent(entity.ExpeditionInfo.Tid)
    end
    return isMine, isMulti, isAlliance, isBigEvent
end

function WorldEventModule:GetWorldEventPanelIconByEntity(entity)
    local isMine, isMulti, isAlliance, isBigEvent = self:CheckEventType(entity)
    if isMine or isMulti then
        return ManualUIConst.sp_world_base_2
    elseif isAlliance then
        if isBigEvent then
            return ManualUIConst.sp_world_base_4
        else
            return ManualUIConst.sp_world_base_3
        end
    end
    return string.empty
end

function WorldEventModule:GetWorldEventPanelBaseByEntity(entity)
    local isMine, isMulti, isAlliance, isBigEvent = self:CheckEventType(entity)
    if isMine or isMulti then
        return ManualUIConst.sp_base_world_event_toast_2
    elseif isAlliance then
        if isBigEvent then
            return ManualUIConst.sp_base_world_event_toast_4
        else
            return ManualUIConst.sp_base_world_event_toast_3
        end
    end
    return string.empty
end

function WorldEventModule:GetWorldEventPanelEventIconByEntity(entity)
    local isMine, isMulti, isAlliance, isBigEvent = self:CheckEventType(entity)
    if isMine or isMulti then
        return ManualUIConst.sp_comp_icon_worldevent
    elseif isAlliance then
        if isBigEvent then
            return ManualUIConst.sp_comp_icon_worldevent_league
        else
            return ManualUIConst.sp_comp_icon_worldevent_multi
        end
    end
    return string.empty
end

function WorldEventModule:GetWorldEventIconByEntity(entity)
    local isMine, isMulti, isAlliance, isBigEvent = self:CheckEventType(entity)
    if isMine or isMulti then
        return ManualUIConst.sp_radar_icon_worldevent
    elseif isAlliance then
        if isBigEvent then
            return ManualUIConst.sp_radar_icon_worldevent_league
        else
            return ManualUIConst.sp_radar_icon_worldevent_multi
        end
    end
    return string.empty
end

function WorldEventModule:GetWorldEventIconByConfigID(configID)
    local configInfo = ConfigRefer.WorldExpeditionTemplate:Find(configID)
    if not configInfo then
        return string.Empty
    end
    local progressType = configInfo:ProgressType()
    if progressType == ProgressType.Personal then
        return ManualUIConst.sp_radar_icon_worldevent
    elseif progressType == ProgressType.Alliance then
        if self:IsAllianceBigWorldEvent(configID) then
            return ManualUIConst.sp_radar_icon_worldevent_league
        else
            return ManualUIConst.sp_radar_icon_worldevent_multi
        end
    end
end

function WorldEventModule:GetWorldEventIconBaseByEntity(entity)
    local isMine, isMulti, isAlliance, isBigEvent = self:CheckEventType(entity)
    if isMine or isMulti then
        return ManualUIConst.sp_world_base_2
    elseif isAlliance then
        if isBigEvent then
            return ManualUIConst.sp_world_base_4
        else
            return ManualUIConst.sp_world_base_3
        end
    end
    return string.empty
end

function WorldEventModule:GetWorldEventLodIconBaseByEntity(entity)
    local isMine, isMulti, isAlliance, isBigEvent = self:CheckEventType(entity)
    if isMine or isMulti then
        return ManualUIConst.sp_icon_lod_world_base_2
    elseif isAlliance then
        if isBigEvent then
            return ManualUIConst.sp_icon_lod_world_base_4
        else
            return ManualUIConst.sp_icon_lod_world_base_3
        end
    end
    return string.empty
end

function WorldEventModule:GetWorldEventIconBaseByConfigID(configID)
    local configInfo = ConfigRefer.WorldExpeditionTemplate:Find(configID)
    if not configInfo then
        return string.Empty
    end
    local progressType = configInfo:ProgressType()
    if progressType == ProgressType.Personal then
        return ManualUIConst.sp_world_base_2
    elseif progressType == ProgressType.Alliance then
        if self:IsAllianceBigWorldEvent(configID) then
            return ManualUIConst.sp_world_base_4
        else
            return ManualUIConst.sp_world_base_3
        end
    end
end

-- 小事件用 - 获取对应开启的活动
function WorldEventModule:GetActiveActivity(allianceExpeditionCfg)
    local kingdom = ModuleRefer.KingdomModule:GetKingdomEntity()
    for i = 1, allianceExpeditionCfg:ActivitiesLength() do
        local activity = allianceExpeditionCfg:Activities(i)
        local activityInfo = kingdom.ActivityInfo.Activities[activity]

        if activityInfo.Open then
            return activity
        end
    end
    g_Logger.Log("没有activity打开")
    return nil
end

function WorldEventModule:GotoUseItemExpedition()
    local cfgId = self:GetPersonalOwnAllianceExpedition()
    g_Game.UIManager:CloseAllByName(UIMediatorNames.BagMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.EarthRevivalMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.RadarMediator)

    local scene = g_Game.SceneManager.current
    if scene:IsInCity() then
        local callback = function()
            self:GotoAllianceExpedition(cfgId, true)
        end
        scene:LeaveCity(callback)
    else
        self:GotoAllianceExpedition(cfgId, true)
    end
end

function WorldEventModule:ValidateItemUse(item, itemCount, uid, notGoto)
    self.notGotoItem = notGoto
    local alliance = ModuleRefer.AllianceModule:GetMyAllianceData()
    if not alliance then
        ---@type CommonConfirmPopupMediatorParameter
        local confirmParameter = {}
        confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
        confirmParameter.confirmLabel = I18N.Get("confirm")
        confirmParameter.cancelLabel = I18N.Get("cancle")
        confirmParameter.content = I18N.GetWithParams("alliance_activity_pet_24")
        confirmParameter.title = I18N.Get("alliance_worldevent_chat_title")
        confirmParameter.onConfirm = function()
            g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonConfirmPopupMediator)
            g_Game.UIManager:Open(UIMediatorNames.AllianceInitialMediator)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
        return
    end

    if itemCount > 0 then
        local isOwn = self:GetPersonalOwnAllianceExpedition()
        if isOwn then
            -- 存在召唤的怪
            ---@type CommonConfirmPopupMediatorParameter
            local data = {}
            data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
            data.title = I18N.Get("pet_fountain_level_up_tips_name")
            data.content = I18N.Get("alliance_activity_pet_06")
            data.confirmLabel = I18N.Get("world_qianwang")
            data.onConfirm = function(context)
                self:GotoUseItemExpedition()
                return true
            end
            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
            return false
        else
            -- 可以使用道具
            if uid == nil and item then
                uid = ModuleRefer.InventoryModule:GetUidByConfigId(item)
            end

            local UseItemParameter = require('UseItemParameter')
            local msg = UseItemParameter.new()
            msg.args.ComponentID = uid
            msg.args.Num = 1
            msg:Send()
            return true
        end
    else
        return false
    end
end

function WorldEventModule:OnUseItem(isSuccess, data)
    local errCode = data.ErrCode
    if isSuccess and errCode == 0 then
        if self.notGotoItem then
            return
        end
        self:GotoUseItemExpedition()
        self:UpdateWorldEventRedDots()
    else
        -- TODO: 各种错误码的多语言
        ---@type CommonConfirmPopupMediatorParameter
        -- local data = {}
        -- data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.Confirm | CommonConfirmPopupMediatorDefine.Style.ExitBtn
        -- data.title = I18N.Get("error_feedback_title")
        -- data.content = I18N.Get(ConfigRefer.ErrCodeI18N:Find("errCode_"..errCode):LanguageKey())
        -- data.onConfirm = function(context)
        --     return true
        -- end
        -- g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, data)
    end
end

function WorldEventModule:UpdateWorldEventRedDots()
    -- local notificationModule = ModuleRefer.NotificationModule
    -- local redot = notificationModule:GetOrCreateDynamicNode("WORLD_EVENT_USEITEM", NotificationType.WORLD_EVENT_USEITEM)
    -- local needDots, item1, item2 = self:CheckWorldEventUseItem()
    -- notificationModule:SetDynamicNodeNotificationCount(redot, item1 + item2)
end

-- 获得世界事件消耗道具
function WorldEventModule:CheckWorldEventUseItem(tabId)
    local id = ConfigRefer.ActivityCenterTabs:Find(tabId):RefAllianceActivityExpedition(1)
    -- for i = 1, ConfigRefer.AllianceConsts:AllianceUseItemExpeditionsLength() do
    --     local tabCfg =ConfigRefer.AllianceConsts:AllianceUseItemExpeditions(i)
    --     id = ConfigRefer.ActivityCenterTabs:Find(tabCfg):RefAllianceActivityExpedition(1)
    -- end

    local cfg = ConfigRefer.AllianceActivityExpedition:Find(id)
    local isOpen = ModuleRefer.ActivityCenterModule:IsActivityTemplateOpen(cfg:Activities(1))
    if not isOpen then
        return false, 0, 0
    end

    -- 两个道具的个数
    local item1 = cfg:UseItems(1)
    local item2 = cfg:UseItems(2)
    local uid1 = ModuleRefer.InventoryModule:GetUidByConfigId(item1)
    local uid2 = ModuleRefer.InventoryModule:GetUidByConfigId(item2)
    local count1 = uid1 and 1 or 0
    local count2 = uid2 and 1 or 0
    if count1 + count2 <= 0 then
        return false, 0, 0
    end

    return true, count1, count2
end

function WorldEventModule:GetMonsterNameByAllianceExpeditionId(id)
    local cfg = ConfigRefer.AllianceActivityExpedition:Find(id)
    local expedition = cfg:Expeditions(1)
    local monsterName1 = ConfigRefer.WorldExpeditionTemplate:Find(expedition):Name()
    expedition = cfg:Expeditions(2)
    local monsterName2 = ConfigRefer.WorldExpeditionTemplate:Find(expedition):Name()
    return I18N.Get(monsterName1), I18N.Get(monsterName2)
end

---@param worldEventEntity wds.Expedition
function WorldEventModule:IsAllianceBoss(worldEventEntity)
    local activityExpeditionConfig = ModuleRefer.AllianceBossEventModule:GetCurrentActivityExpeditionConfig()
    if activityExpeditionConfig then
        local expeditionConfig = ModuleRefer.AllianceBossEventModule:GetCurrentExpeditionConfig(activityExpeditionConfig)
        return worldEventEntity and worldEventEntity.ExpeditionInfo.Tid == expeditionConfig:Id()
    end
end

function WorldEventModule:IsPersonalAllianceExpeditionOpen()
    local isOpen = self:IsActivityOpen(UseItemAllianceExpeditionId[1])
    local cfg
    local item1
    local item2
    if isOpen then
        cfg = ConfigRefer.AllianceActivityExpedition:Find(UseItemAllianceExpeditionId[1])
        item1 = cfg:UseItems(1)
        item2 = cfg:UseItems(2)
        return self:IsActivityOpen(UseItemAllianceExpeditionId[1]), item1, item2
    else
        cfg = ConfigRefer.AllianceActivityExpedition:Find(UseItemAllianceExpeditionId[2])
        item1 = cfg:UseItems(1)
        item2 = cfg:UseItems(2)
        return self:IsActivityOpen(UseItemAllianceExpeditionId[2]), item1, item2
    end
end

function WorldEventModule:IsActivityOpen(eventCfgId)
    local cfgId = eventCfgId
    if not cfgId or cfgId == 0 then
        return false
    end
    local startT, endT, remainT = self:GetAllianceEventTime(cfgId, true)
    local curT = g_Game.ServerTime:GetServerTimestampInSeconds()
    -- 预告时间默认开启
    if not (curT > startT and curT < endT) then
        -- 正常活动时间
        startT, endT, remainT = self:GetAllianceEventTime(cfgId, false)
        if curT > startT and curT < endT then
            return true
        else
            return false
        end
    end
    return true
end

return WorldEventModule
