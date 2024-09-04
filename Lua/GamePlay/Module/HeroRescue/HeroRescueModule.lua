local BaseModule = require('BaseModule')
local ModuleRefer = require('ModuleRefer')
local DBEntityPath = require('DBEntityPath')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local Utils = require("Utils")
local EventConst = require("EventConst")
local I18N = require("I18N")
local TimerUtility = require("TimerUtility")
local UIMediatorNames = require("UIMediatorNames")
local NotificationType = require("NotificationType")
local CityConst = require('CityConst')
local KingdomMapUtils = require('KingdomMapUtils')
local NpcServiceObjectType = require('NpcServiceObjectType')
local CityZoneStatus = require("CityZoneStatus")

---@class HeroRescueModule
local HeroRescueModule = class('HeroRescueModule', BaseModule)
function HeroRescueModule:ctor()

end

function HeroRescueModule:OnRegister()
end

function HeroRescueModule:SetUp()
    self:RefreshRedDot()
    self:InitItemZone()
    g_Game.EventManager:AddListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RefreshRedDot))
end

function HeroRescueModule:OnRemove()
    g_Game.EventManager:RemoveListener(EventConst.ITEM_COUNT_ALL_CHANGED, Delegate.GetOrCreate(self, self.RefreshRedDot))
end

function HeroRescueModule:IsHeroNeedRescue()
    local npcId = ConfigRefer.CityConfig:RescueBeauty()
    local serviceGroupId = ConfigRefer.CityElementNpc:Find(npcId):ServiceGroupId()
    local serviceMap = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)
    local serviceGroup
    for k, v in pairs(serviceMap) do
        if v.ServiceGroupTid == serviceGroupId then
            serviceGroup = v
            break
        end
    end
    local npcValid = serviceGroup ~= nil and serviceGroup.Services[serviceGroupId] and serviceGroup.Services[serviceGroupId].State == 1
    local city = ModuleRefer.CityModule.myCity
    local zone = city.zoneManager:GetZoneById(ConfigRefer.CityConfig:RescueBeautyZone())
    local zoneValid = zone and zone.status >= CityZoneStatus.Explored or false

    return npcValid and zoneValid
end

function HeroRescueModule:GetHeroRescueServiceGroup()
    local npcId = ConfigRefer.CityConfig:RescueBeauty()
    local serviceGroupId = ConfigRefer.CityElementNpc:Find(npcId):ServiceGroupId()
    local serviceMap = ModuleRefer.PlayerServiceModule:GetServiceMapByObjectType(NpcServiceObjectType.CityElement)
    local serviceGroup
    for k, v in pairs(serviceMap) do
        if v.ServiceGroupTid == serviceGroupId then
            serviceGroup = v
            break
        end
    end

    return serviceGroup
end

function HeroRescueModule:RefreshCameraSizeLimit()
    ---@type KingdomScene
    local kingdomScene = g_Game.SceneManager.current
    if kingdomScene then
        ---@type KingdomSceneStateInCity
        local state = kingdomScene.stateMachine:GetCurrentState()
        if state and state.SetCameraSize then
            state:TempSetCameraSize(CityConst.CITY_RECOMMEND_CAMERA_SIZE)
        end
    end
end

function HeroRescueModule:DisplayItems()
    local targets = {}
    for k, v in pairs(self.heroItemZone) do
        table.insert(targets, k)
    end
    local city = ModuleRefer.CityModule.myCity
    self:SetManualShowItemBubble(true)
    city.camera:ForceGiveUpTween()
    city.camera.enablePinch = true
    self:RefreshCameraSizeLimit()
    g_Game.EventManager:TriggerEvent(EventConst.UI_HERO_RESCUE_FIRST_TIME_SHOW_BUBBLE)
    city.camera:ZoomTo(CityConst.CITY_RECOMMEND_CAMERA_SIZE, 0.2, function()
        city.camera.enablePinch = false
        self:SingleDisplayItem(1, targets)
    end)

    -- city.camera:ZoomTo(30, 0.2, function()
    --     city.camera.enablePinch = false
    --     self:SingleDisplayItem(1, targets)
    -- end)
end

function HeroRescueModule:SingleDisplayItem(index, targets)
    if index > #targets then
        self:SetManualShowItemBubble(false)
        return
    end
    local callback = function()
        index = index + 1
        self:SingleDisplayItem(index, targets)
    end
    self:GotoItemZone(index, callback)
end

function HeroRescueModule:GotoItemZone(index, callback)
    local city = ModuleRefer.CityModule.myCity
    local pos = self:GetItemBubblePos(index)

    local cityPos = city:GetCenterWorldPositionFromCoord(pos:X(), pos:Y(), 1, 1)
    city.camera:ForceGiveUpTween()
    city.camera:LookAt(cityPos, 1, callback)
end

function HeroRescueModule:GetItemBubblePos(index)
    local cfg = ConfigRefer.HeroRescue:Find(1)
    local pos = cfg:PopPos(index)
    return pos
end

function HeroRescueModule:GetItemBubbleIndexByZoneId(zone)
    local cfg = ConfigRefer.HeroRescue:Find(1)
    for i = 1, cfg:ZoneLength() do
        if cfg:Zone(i) == zone then
            return i
        end
    end
    return nil
end

function HeroRescueModule:InitItemZone()
    -- 只有一个美女
    local cfg = ConfigRefer.HeroRescue:Find(1)
    self.heroItemZone = {}
    for i = 1, cfg:ZoneLength() do
        self.heroItemZone[cfg:Zone(i)] = true
    end
end

function HeroRescueModule:GetItemCount()
    local cureItemGroup = ConfigRefer.ItemGroup:Find(ConfigRefer.HeroRescue:Find(1):CureItemGroup())
    local itemId = cureItemGroup:ItemGroupInfoList(1):Items()
    local has = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
    return has
end

function HeroRescueModule:GetItemIcon()
    return ConfigRefer.ArtResourceUI:Find(ConfigRefer.HeroRescue:Find(1):Icon()):Path()
end

function HeroRescueModule:IsItemZone(zoneIndex)
    return self.heroItemZone[zoneIndex] ~= nil
end

function HeroRescueModule:RefreshRedDot()
    local reddotNode = ModuleRefer.NotificationModule:GetOrCreateDynamicNode("RescueBeauty_1_", NotificationType.RESCUE_BEAUTY_USE_ITEM)
    local has = self:GetItemCount()
    ModuleRefer.NotificationModule:SetDynamicNodeNotificationCount(reddotNode, has > 0 and 1 or 0)
end

function HeroRescueModule:GetCountdownEndTime(cfgId)
    local cfg = ConfigRefer.HeroRescue:Find(cfgId)
    local startT = g_Game.PlayerPrefsEx:GetInt('HeroRescue_Countdown_' .. cfgId)
    local endT = startT + cfg:Countdown()
    return endT
end

function HeroRescueModule:SetCountdown(cfgId)
    local countdown = g_Game.PlayerPrefsEx:GetInt('HeroRescue_Countdown_' .. cfgId, 0)
    if countdown == 0 then
        local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        g_Game.PlayerPrefsEx:SetInt('HeroRescue_Countdown_' .. cfgId, curTime)
    end
end
function HeroRescueModule:GetFirstOpen()
    local res = g_Game.PlayerPrefsEx:GetInt('HeroRescue_FirstOpen_', 0)
    return res
end

function HeroRescueModule:SetFirstOpen()
    g_Game.PlayerPrefsEx:SetInt('HeroRescue_FirstOpen_', 1)
end

function HeroRescueModule:GetManualShowItemBubble()
    return self.heroRescueCameraGuide
end

function HeroRescueModule:SetManualShowItemBubble(res)
    self.heroRescueCameraGuide = res
end

-- 预加载美女模型
function HeroRescueModule:PreloadModel()
    local needPreload = self:IsHeroNeedRescue()
    if not needPreload then
        return
    end

    self.cfgId = 1
    self.cfg = ConfigRefer.HeroRescue:Find(self.cfgId)
    local artConf = ConfigRefer.ArtResource:Find(self.cfg:ShowModel())
    g_Game.UIManager:SetupUI3DModelView(nil, artConf:Path(), ConfigRefer.ArtResource:Find(self.cfg:ShowBackground()):Path(), nil, function(viewer)
        if not viewer then
            return
        end
        g_Game.UIManager:CloseUI3DView(nil)
    end)
end

return HeroRescueModule
