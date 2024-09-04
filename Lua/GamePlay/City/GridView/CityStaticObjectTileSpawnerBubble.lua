local ManualResourceConst = require("ManualResourceConst")
local Utils = require("Utils")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require('ModuleRefer')
local CityStaticObjectTile = require("CityStaticObjectTile")
local TimerUtility = require("TimerUtility")

---@class CityStaticObjectTileSpawnerBubble:CityStaticObjectTile
---@field new fun(gridView:CityGridView, spawner:CityElementSpawner):CityStaticObjectTileSpawnerBubble
---@field super CityStaticObjectTile
local CityStaticObjectTileSpawnerBubble = class('CityStaticObjectTileSpawnerBubble', CityStaticObjectTile)

---@param gridView CityGridView
---@param spawner CityElementSpawner
function CityStaticObjectTileSpawnerBubble:ctor(gridView, spawner)
    self.eleSpawner = spawner
    CityStaticObjectTileSpawnerBubble.super.ctor(self, gridView, spawner.x, spawner.y, 1, 1,ManualResourceConst.ui3d_bubble_group)
    ---@type CS.UnityEngine.GameObject
    self.goRoot = nil
    ---@type City3DBubbleStandard
    self.bubble = nil
    self.cityUid = gridView.city.uid
end

---@param go CS.UnityEngine.GameObject
function CityStaticObjectTileSpawnerBubble:OnAssetLoaded(go, userdata)
    g_Game.EventManager:AddListener(EventConst.CITY_SPAWNER_IN_BATTLE_REFRESH, Delegate.GetOrCreate(self, self.OnSpawnerBattleStatusChanged))
    CityStaticObjectTile.OnAssetLoaded(self, go, userdata)
    if Utils.IsNull(go) then
        return
    end
    go:SetLayerRecursively("Scene3DUI", true)
    self.goRoot = go
    local bar = go:GetLuaBehaviour("City3DBubbleStandard")
    if not bar then
        return
    end
    self.bubble = bar.Instance
    if not self.bubble then
        return
    end
    self.bubble:Reset()

    self.radarTask = ModuleRefer.RadarModule:GetCityRadarTask(self.eleSpawner.configId)
    if self.radarTask then
        self.bubble:ShowBubble(self.radarTask.icon, false, false, false):ShowBubbleBackIcon(self.radarTask.frame)
        self.bubble:SetBubbleVerticalPos()
        self:StopTimer()
        self.timer = TimerUtility.IntervalRepeat(function()
            self:TickSetTrigger()
        end, 0.5, -1)
    else
        self.bubble:ShowBubble("sp_comp_icon_radar_se", true, false, false):ShowBubbleSeBackIcon("sp_city_bubble_base_hurt")
    end
    self.bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickBubble), nil)
    self.bubble:EnableTrigger(true)
    self:OnSpawnerBattleStatusChanged(self.cityUid)
end

function CityStaticObjectTileSpawnerBubble:OnAssetUnload()
    g_Game.EventManager:RemoveListener(EventConst.CITY_SPAWNER_IN_BATTLE_REFRESH, Delegate.GetOrCreate(self, self.OnSpawnerBattleStatusChanged))
    self:StopTimer()
    if self.bubble then
        self.bubble:ClearTrigger()
    end
    self.bubble = nil
    self.goRoot = nil
end

function CityStaticObjectTileSpawnerBubble:OnClickBubble()
    ---@type ClickNpcEventContext
    local context = CityStaticObjectTileSpawnerBubble.MakeClickNpcMsgContext(self.tile.gridView.city, self.eleSpawner)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_ELEMENT_SPAWNER_CLICK_TRIGGER, context)
    return true
end

---@param city MyCity
---@param eleSpawner CityElementSpawner
---@param targetPos CS.UnityEngine.Vector3
---@return ClickNpcEventContext
function CityStaticObjectTileSpawnerBubble.MakeClickNpcMsgContext(city, eleSpawner)
    local eleConfig = ConfigRefer.CityElementData:Find(eleSpawner.configId)
    local elePos = eleConfig:Pos()
    local pos = city:GetWorldPositionFromCoord(elePos:X(), elePos:Y())
    ---@type ClickNpcEventContext
    local context = {}
    context.cityUid = city.uid
    context.elementConfigID = eleSpawner.id
    context.targetPos = pos
    return context
end

function CityStaticObjectTileSpawnerBubble:OnSpawnerBattleStatusChanged(cityUid)
    if self.cityUid ~= cityUid then return end
    local city = self.gridView.city
    local inBattle = city.elementManager:IsSpawnerLinkExpeditionInBattle(self.eleSpawner.id)
    if self.bubble then
        self.bubble:ShowRoot(not inBattle)
    end
end

-- 偶现雷达气泡点击事件被莫名注销的情况，先加个Tick
function CityStaticObjectTileSpawnerBubble:TickSetTrigger()
    if self.bubble and self.radarTask and self.bubble.callback == nil then
        self.bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClickBubble), nil)
    end
end

function CityStaticObjectTileSpawnerBubble:StopTimer()
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
end


return CityStaticObjectTileSpawnerBubble