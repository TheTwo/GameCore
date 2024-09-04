local ModuleRefer = require('ModuleRefer')
local BaseModule = require('BaseModule')
local ConfigRefer = require('ConfigRefer')
local UIMediatorNames = require("UIMediatorNames")
local I18N = require('I18N')
local Delegate = require('Delegate')
local ProtocolId = require('ProtocolId')
local EventConst = require('EventConst')
local KingdomMapUtils = require('KingdomMapUtils')
local Utils = require('Utils')
local CameraUtils = require('CameraUtils')
local LandformDisplayMode = require('LandformDisplayMode')
local QualityColorHelper = require("QualityColorHelper")
local ConfigTimeUtility = require("ConfigTimeUtility")
local TimeFormatter = require("TimeFormatter")

local MapUtils = CS.Grid.MapUtils


---@class LandformModule : BaseModule
local LandformModule = class('LandformModule', BaseModule)

-- 10s之内不再显示圈层切换
local PROTECT_TIME_MS = 10 * 1000
local SCREEN_CENTER = CS.UnityEngine.Vector3(0.5, 0.5, 0)
local PLANE = CS.UnityEngine.Plane(CS.UnityEngine.Vector3.up, CS.UnityEngine.Vector3.zero)

local LOD_STRATEGY_MIN = 4
local LOD_STRATEGY_MAX = 8
local LOD_LANDFORM_MIN = 6
local LOD_LANDFORM_MAX = 8

function LandformModule:ctor()
    self.isLandSelectMode = false

    -- 触发圈层变化的参数记录
    self.lastTileX = 0
    self.lastTileZ = 0
    self.lastLandCfgId = 0
    self.lastTimestamp = 0

    LOD_STRATEGY_MIN = ConfigRefer.ConstBigWorld:LodStrategyMin() + 1
    LOD_STRATEGY_MAX = ConfigRefer.ConstBigWorld:LodStrategyMax() + 1
    LOD_LANDFORM_MIN = ConfigRefer.ConstBigWorld:LodLandformMin() + 1
    LOD_LANDFORM_MAX = ConfigRefer.ConstBigWorld:LodLandformMax() + 1
end

function LandformModule:OnRegister()
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.UnlockNewLandform, Delegate.GetOrCreate(self, self.OnUnlockNewLandform))

    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
end

function LandformModule:OnRemove()
    -- 重载此函数
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.UnlockNewLandform, Delegate.GetOrCreate(self, self.OnUnlockNewLandform))

    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
end

function LandformModule:OnSecondTicker()
    -- 条件检测
    if not KingdomMapUtils.IsMapState() then return end
    if KingdomMapUtils.GetLOD() > 2 then return end

    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if not scene then return end
    if scene:GetName() ~= "KingdomScene" then return end
    if scene:IsInCity() then return end

    if Utils.IsNull(scene.staticMapData)
        or Utils.IsNull(scene.basicCamera)
        or Utils.IsNull(scene.basicCamera.mainCamera) then
        return
    end

    local unitsPerTileX = scene.staticMapData.UnitsPerTileX or 0
    local UnitsPerTileZ = scene.staticMapData.UnitsPerTileZ or 0
    if unitsPerTileX <= 0 or UnitsPerTileZ <= 0 then 
        return 
    end

    local ray = scene.basicCamera.mainCamera:ViewportPointToRay(SCREEN_CENTER)
    local pos = CameraUtils.GetHitPointLinePlane(ray, PLANE)
    if not pos then
        return
    end

    local tileX = math.floor(pos.x / unitsPerTileX)
    local tileZ = math.floor(pos.z / UnitsPerTileZ)
    if tileX == self.lastTileX and tileZ == self.lastTileZ then
        return
    end

    local landCfgId = ModuleRefer.TerritoryModule:GetLandCfgIdAt(tileX, tileZ) or 0
    if landCfgId <= 0 then
        return
    end

    if self.lastLandCfgId == landCfgId then
        return
    end

    -- 更新记录信息
    self.lastLandCfgId = landCfgId
    self.lastTileX = tileX
    self.lastTileZ = tileZ

    local now = g_Game.ServerTime:GetServerTimestampInMilliseconds()
    if now - self.lastTimestamp < PROTECT_TIME_MS then
        return
    end

    -- 满足条件，触发圈层切换提示
    self.lastTimestamp = now
    
    ---@type NewLandformMediatorParameter
    local param = {}
    param.landCfgId = landCfgId
    g_Game.UIManager:Open(UIMediatorNames.NewLandformMediator, param)
end

function LandformModule:Test()
    ---@type NewLandformMediatorParameter
    local param = {}
    param.landCfgId = 200001
    g_Game.UIManager:Open(UIMediatorNames.NewLandformMediator, param)
end

---@param success boolean
---@param data wrpc.UnlockNewLandformRequest
function LandformModule:OnUnlockNewLandform(success, data)
    if not success then return end

    local landCfgId = data.LandformTid
    g_Logger.Log('try open LandformUnlockMediator %s', landCfgId)

    ---@type LandformUnlockMediatorParameter
    local param = {}
    param.landCfgId = landCfgId
    g_Game.UIManager:Open(UIMediatorNames.LandformUnlockMediator, param)
end

function LandformModule:EnterLandSelectMode()
    self.isLandSelectMode = true
end

function LandformModule:ExitLandSelectMode()
    self.isLandSelectMode = false
end

function LandformModule:IsLandSelectMode()
    return self.isLandSelectMode
end

function LandformModule:IsFeatureOpen()
    local systemEntryId = ConfigRefer.ConstMain:Landmodel()
    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(systemEntryId)
end

function LandformModule:Initialize()
    self.index_id_map = {}
    self.id_index_map = {}
    for _, cell in ConfigRefer.Land:ipairs() do
        self.index_id_map[cell:LayerNum()] = cell:Id()
        self.id_index_map[cell:Id()] = cell:LayerNum()
    end
end

---@param id number @LandConfigCell Id
---@return number @LandConfigCell LayerNum
function LandformModule:GetIndexFromId(id)
    return self.id_index_map[id] or -1
end

---@param index number @LandConfigCell LayerNum
---@return number @LandConfigCell Id
function LandformModule:GetIdFromIndex(index)
    return self.index_id_map[index] or -1
end

---@return number @LandConfigCell id
function LandformModule:GetMyLandCfgId()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    return player.PlayerWrapper3.Landform.CurLandform
end

function LandformModule:IsValidLandform(landformConfigID)
    local landformConfig = ConfigRefer.Land:Find(landformConfigID)
    return landformConfig and landformConfig:ActivityTasksLength() > 0
end

---@param landCfgId number @LandConfigCell Id
---@return boolean
function LandformModule:IsPlayerUnlock(landCfgId)
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local IsPlayerUnlock = player.PlayerWrapper3.Landform.UnlockedLandform[landCfgId] or false
    return IsPlayerUnlock
end

function LandformModule:IsLandUnlock(tileX, tileZ)
    local landCfgId = ModuleRefer.TerritoryModule:GetLandCfgIdAt(tileX, tileZ)
    return self:IsLandformUnlockByCfgId(landCfgId)
end

function LandformModule:IsLandformUnlockByCfgId(landCfgId)
    local landCfgCell = ConfigRefer.Land:Find(landCfgId)
    if not landCfgCell then
        g_Logger.Error('获取不到圈层信息,landCfgId %s', landCfgId)
        return false
    end

    local isSystemUnlock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(landCfgCell:SystemEntryId())
    local isPlayerUnlock = self:IsPlayerUnlock(landCfgId)
    return isSystemUnlock and isPlayerUnlock
end

function LandformModule:IsLandformSystemUnlockAt(tileX, tileZ)
    local landCfgId = ModuleRefer.TerritoryModule:GetLandCfgIdAt(tileX, tileZ)
    return self:IsLandformSystemUnlock(landCfgId)
end

function LandformModule:IsLandformSystemUnlock(landCfgId)
    local landCfgCell = ConfigRefer.Land:Find(landCfgId)
    if not landCfgCell then
        g_Logger.Error('获取不到圈层信息 landCfgId %s', landCfgId)
        return false
    end

    return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(landCfgCell:SystemEntryId())
end

function LandformModule:GetLastSystemUnlockLandFormId()
    local isUnlock = false
    local id
    for k,v in ConfigRefer.Land:ipairs() do
        isUnlock = self:IsLandformSystemUnlock(v:Id())
        if isUnlock then
            id = v:Id()
        end
    end
    return id
end

function LandformModule:GetLastPlayerUnlockLandFormId()
    local castleLevel = ModuleRefer.PlayerModule:StrongholdLevel()
    local id
    for k,v in ConfigRefer.Land:ipairs() do
        if castleLevel >= v:UnlockCondMainCityLevel() and v:IsShow() then
            id = v:Id()
        end
    end
    return id
end


function LandformModule:CheckLandformUnlock(landformConfigID)
    local landCfgCell = ConfigRefer.Land:Find(landformConfigID)
    if landCfgCell then
        local kingdom = ModuleRefer.KingdomModule:GetKingdomEntity()
        local unlock = kingdom.SystemEntry.OpenSystems[landCfgCell:SystemEntryId()]
        local systemEntryCfg = ConfigRefer.SystemEntry:Find(landCfgCell:SystemEntryId())
        return unlock, I18N.GetWithParams(systemEntryCfg:LockedTips(), systemEntryCfg:LockedTipsPrm())
    end
    return false, string.Empty
end

function LandformModule:GetLandformOpenHint(landformConfigID, isSettleCastle)
    if not landformConfigID then
        return true, string.Empty
    end
    
    local landConfig = ConfigRefer.Land:Find(landformConfigID)
    local systemEntryID = isSettleCastle and landConfig:SystemEntryId() or landConfig:MistUnlockSystemEntryId()
    local systemEntry = ConfigRefer.SystemEntry:Find(systemEntryID)
    local landformUnlockTime = ModuleRefer.KingdomModule:GetKingdomTime() + ConfigTimeUtility.NsToSeconds(systemEntry:UnlockServerOpenTime())
    local serverTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local remainTime = math.max(landformUnlockTime - serverTime, 0)
    if remainTime > 0 then
        local remainTimeStr = TimeFormatter.SimpleFormatTimeWithDay(remainTime)
        local tip = I18N.GetWithParams(systemEntry:LockedTips(), remainTimeStr)
        local unlocked = self:IsLandformUnlockByCfgId(landformConfigID)
        if not unlocked then
            return unlocked, tip
        end
    end

    local isPermitMoveCity = landConfig:IsPermitMoveCity()
    local territoryOK = ModuleRefer.TerritoryModule:CheckAllianceTerritoryMeetLandform(landformConfigID)
    if not isPermitMoveCity and not territoryOK then
        return false, isSettleCastle and I18N.Get("landtask_info_move_city_2") or I18N.Get("mist_info_dispelled_after")
    end
    
    local castleLevel = ModuleRefer.PlayerModule:StrongholdLevel()
    local targetLevel = 1--ConfigRefer.Land:Find(landformConfigID):MistLevel()
    if castleLevel < 1 then
        return false, I18N.GetWithParams("landtask_info_move_city_1", targetLevel)
    end
    
    return true, string.Empty
end

function LandformModule:GotoLandform(landformConfigID)
    local gotoFunc = function()
        local targetTerritory = ModuleRefer.MapFogModule:GetUnlockedMistsOfLandform(landformConfigID)
        if targetTerritory and targetTerritory > 0 then
            local territoryConfig = ConfigRefer.Territory:Find(targetTerritory)
            local pos = territoryConfig:VillagePosition()
            local position = MapUtils.CalculateCoordToWorldPosition(pos:X(), pos:Y(), KingdomMapUtils.GetStaticMapData())
            local size = KingdomMapUtils.GetCameraLodData().mapCameraEnterSize
            KingdomMapUtils.MoveAndZoomCamera(position, size)
        end
    end
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Dialog)
    g_Game.UIManager:CloseAllByType(CS.DragonReborn.UI.UIMediatorType.Popup)
    if not KingdomMapUtils.IsMapState() then
        KingdomMapUtils.GetKingdomScene():LeaveCity(gotoFunc)
    else
        gotoFunc()
    end
end

---@param landCfgCell LandConfigCell
function LandformModule:GetUnlockWorldStageDesc(landCfgCell)
    local systemEntryCfgCell = ConfigRefer.SystemEntry:Find(landCfgCell:SystemEntryId())
    if not systemEntryCfgCell then
        return string.Empty
    end

    local worldStageCfgCell = ConfigRefer.WorldStage:Find(systemEntryCfgCell:UnlockWorldStage())
    if worldStageCfgCell then
        return I18N.GetWithParams('bw_info_movecity_open_circle', I18N.Get(worldStageCfgCell:Name()))
    end

    worldStageCfgCell = ModuleRefer.WorldTrendModule:GetStageConfigByStageIndex(systemEntryCfgCell:UnlockWorldStageIndex())
    if worldStageCfgCell then
        return I18N.GetWithParams('bw_info_movecity_open_circle', I18N.Get(worldStageCfgCell:Name()))
    end
    return nil
end

---@param cfgId number @KmonsterDataConfigCell Id
---@return number @ArtResourceUI Id
function LandformModule:GetMiniIconFromKmonsterDataCfgId(cfgId)
    local monsterCfgCell = ConfigRefer.KmonsterData:Find(cfgId)
    if not monsterCfgCell then
        g_Logger.Error('GetMiniIconFromKmonsterDataCfgId failed, monsterCfgCell %s is nil', cfgId)
        return 0
    end

    if monsterCfgCell:HeroLength() <= 0 then
        g_Logger.Error('GetMiniIconFromKmonsterDataCfgId failed, monsterCfgCell %s HeroLength is 0', cfgId)
        return 0
    end

    local heroInfo = monsterCfgCell:Hero(1)
    local heroNpcCfgCell = ConfigRefer.HeroNpc:Find(heroInfo:HeroConf())
    if not heroNpcCfgCell then
        g_Logger.Error('GetMiniIconFromKmonsterDataCfgId failed, heroNpcCfgCell %s is nil', heroInfo:HeroConf())
        return 0
    end

    local heroesCfgCell = ConfigRefer.Heroes:Find(heroNpcCfgCell:HeroConfigId())
    if not heroesCfgCell then
        g_Logger.Error('GetMiniIconFromKmonsterDataCfgId %s failed, heroesCfgCell %s is nil', heroNpcCfgCell:HeroConfigId())
        return 0
    end

    local heroClientResCfgCell = ConfigRefer.HeroClientRes:Find(heroesCfgCell:ClientResCfg())
    if not heroClientResCfgCell then
        g_Logger.Error('GetMiniIconFromKmonsterDataCfgId %s failed, heroClientResCfgCell %s is nil', heroesCfgCell:ClientResCfg())
        return 0
    end

    local icon = heroClientResCfgCell:HeadMini()
    local baseIcon = QualityColorHelper.GetQualityCircleBaseIcon(heroesCfgCell:Quality(), QualityColorHelper.Type.Hero)
    return icon, baseIcon
end

function LandformModule:GetNameFromKmonsterDataCfgId(cfgId)
    local monsterCfgCell = ConfigRefer.KmonsterData:Find(cfgId)
    if not monsterCfgCell then
        g_Logger.Error('GetNameFromKmonsterDataCfgId failed, monsterCfgCell %s is nil', cfgId)
        return string.Empty
    end
    return monsterCfgCell:Name()
end

function LandformModule:GetDescFromKmonsterDataCfgId(cfgId)
    local monsterCfgCell = ConfigRefer.KmonsterData:Find(cfgId)
    if not monsterCfgCell then
        g_Logger.Error('GetDescFromKmonsterDataCfgId failed, monsterCfgCell %s is nil', cfgId)
        return string.Empty
    end
    return monsterCfgCell:Introduction()
end

function LandformModule:GetRewardsFromKmonsterDataCfgId(cfgId)
    local monsterCfgCell = ConfigRefer.KmonsterData:Find(cfgId)
    if not monsterCfgCell then
        g_Logger.Error('GetRewardsFromKmonsterDataCfgId failed, monsterCfgCell %s is nil', cfgId)
        return 0
    end
    return monsterCfgCell:DropShow()
end

---@param cfgId number @PetConfigCell Id
---@return number @ArtResourceUI Id
function LandformModule:GetMiniIconFromPetCfgId(cfgId)
    local petCfgCell = ConfigRefer.Pet:Find(cfgId)
    if not petCfgCell then
        g_Logger.Error('GetMiniIconFromPetCfgId failed, petCfgCell %s is nil', cfgId)
        return 0
    end
    local icon = petCfgCell:Icon()
    local baseIcon = QualityColorHelper.GetQualityCircleBaseIcon(petCfgCell:Quality(), QualityColorHelper.Type.Pet)
    return icon, baseIcon 
end

---@param cfgId number @PetConfigCell Id
---@return string
function LandformModule:GetNameFromPetCfgId(cfgId)
    local petCfgCell = ConfigRefer.Pet:Find(cfgId)
    if not petCfgCell then
        g_Logger.Error('GetNameFromPetCfgId failed, petCfgCell %s is nil', cfgId)
        return string.Empty
    end
    return petCfgCell:Name()
end

---@param cfgId number @PetConfigCell Id
---@return string
function LandformModule:GetDescFromPetCfgId(cfgId)
    local petCfgCell = ConfigRefer.Pet:Find(cfgId)
    if not petCfgCell then
        g_Logger.Error('GetDescFromPetCfgId failed, petCfgCell %s is nil', cfgId)
        return string.Empty
    end
    
    local itemId = petCfgCell:SourceItems(1)
    local itemCfgCell = ConfigRefer.Item:Find(itemId)
    return itemCfgCell:DescKey()
end

---@param cfgId number @PetConfigCell Id
---@return string
function LandformModule:GetItemIDFromPetCfgId(cfgId)
    local petCfgCell = ConfigRefer.Pet:Find(cfgId)
    if not petCfgCell then
        g_Logger.Error('GetDescFromPetCfgId failed, petCfgCell %s is nil', cfgId)
        return string.Empty
    end

    local itemId = petCfgCell:SourceItems(1)
   return itemId 
end

---@param cfgId number @FixedMapBuilding Id
---@return number @ArtResourceUI Id
function LandformModule:GetMiniIconFromResourceFieldCfgId(cfgId)
    local config = ConfigRefer.FixedMapBuilding:Find(cfgId)
    if not config then
        g_Logger.Error('GetMiniIconFromResourceFieldCfgId failed, config %s is nil', cfgId)
        return 0
    end
    local icon = config:BubbleImage()
    local baseIcon = QualityColorHelper.GetQualityCircleBaseIcon(1, QualityColorHelper.Type.Item)
    return icon, baseIcon
end

---@param cfgId number @FixedMapBuilding Id
---@return string
function LandformModule:GetNameFromResourceFieldCfgId(cfgId)
    local config = ConfigRefer.FixedMapBuilding:Find(cfgId)
    if not config then
        g_Logger.Error('GetNameFromResourceFieldCfgId failed, config %s is nil', cfgId)
        return string.Empty
    end
    return config:Name()
end

---@param cfgId number @FixedMapBuilding Id
---@return string
function LandformModule:GetDescFromResourceFieldCfgId(cfgId)
    local config = ConfigRefer.FixedMapBuilding:Find(cfgId)
    if not config then
        g_Logger.Error('GetDescFromResourceFieldCfgId failed, config %s is nil', cfgId)
        return string.Empty
    end
    return config:Des()
end

function LandformModule:GetRewardsFromResourceFieldCfgId(cfgId)
    local config = ConfigRefer.FixedMapBuilding:Find(cfgId)
    if not config then
        g_Logger.Error('GetRewardsFromResourceFieldCfgId failed, config %s is nil', cfgId)
        return 0
    end
    return config:DropShow()
end

return LandformModule
