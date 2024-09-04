local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local DBEntityPath = require("DBEntityPath")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local Utils = require("Utils")

local I18N = require("I18N")
local EventConst = require("EventConst")

---@class HUDExploreComponent:BaseUIComponent
---@field super BaseUIComponent
local HUDExploreComponent = class('HUDExploreComponent', BaseUIComponent)

function HUDExploreComponent:ctor()
    HUDExploreComponent.super.ctor(self)
    ---@type table<number, wds.TaskState>
    self._inShowItems = {}
    self._showAniItems = {}
    self._waitShowFinishedEnd = nil
    ---@type CS.UnityEngine.GameObject[]
    self._flyEffects = {}
    self._aniTime = 1
end

function HUDExploreComponent:OnCreate()
    self._p_btn_mission_explore_title = self:GameObject("p_btn_mission_explore_title")
    self._p_text_mission_explore_title = self:Text("p_text_mission_explore_title")
    self._p_text_mission_explore_number = self:Text("p_text_mission_explore_number")
    self._p_progress = self:Slider("p_progress")
    self._p_effect_target = self:Transform("p_effect_target")

    self._transform = self:Transform("")
    ---@see HUDExploreTask
    self._p_btn_mission_explore_content = self:LuaBaseComponent("p_btn_mission_explore_content")
    self._pool_expore_task = LuaReusedComponentPool.new(self._p_btn_mission_explore_content, self._transform)

    self._p_text_mission_explore = self:Text("p_text_mission_explore")
    self._go_base = self:GameObject("base")
end

function HUDExploreComponent:OnShow()
    local myCity = ModuleRefer.CityModule:GetMyCity()
    if myCity ~= nil and myCity.zoneManager:IsDataReady() then
        self:UpdatePanel()
    end
    self:SetupEvents(true)
end

function HUDExploreComponent:OnHide()
    self:SetupEvents(false)
end

function HUDExploreComponent:OnClose()
    self:SetupEvents(false)
end

function HUDExploreComponent:SetupEvents(add)
    if not self._eventsAdd and add then
        self._eventsAdd = true
        g_Game.EventManager:AddListener(EventConst.TASK_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnTaskDBChanged))
        g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.ZoneRecoverScore.MsgPath, Delegate.GetOrCreate(self, self.OnZoneScoreChanged))
        g_Game.EventManager:AddListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneStatusChanged))
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    elseif self._eventsAdd and not add then
        self._eventsAdd = false
        g_Game.EventManager:RemoveListener(EventConst.TASK_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnTaskDBChanged))
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.ZoneRecoverScore.MsgPath, Delegate.GetOrCreate(self, self.OnZoneScoreChanged))
        g_Game.EventManager:RemoveListener(EventConst.CITY_ZONE_STATUS_BATCH_CHANGED, Delegate.GetOrCreate(self, self.OnZoneStatusChanged))
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.Tick))
    end
end

function HUDExploreComponent:UpdateProgress()
    if self.focusZoneCfg == nil then
        return
    end
    local maxScore = self.focusZoneCfg:RecoverScore()
    self._p_text_mission_explore_title.text = I18N.GetWithParams("city_area_task7", I18N.Get(self.focusZoneCfg:Name()))
    self._p_text_mission_explore_number.text = ("%d/%d"):format(self.zoneScore, maxScore)
    if maxScore > 0 then
        self._p_progress.value = self.zoneScore / maxScore
    else
        self._p_progress.value = 1
    end
end

function HUDExploreComponent:UpdatePanel()
    local myCity = ModuleRefer.CityModule:GetMyCity()
    local castle = myCity:GetCastle()
    self.focusZoneCfg = nil
    local lastZoneScore = self.zoneScore
    self.zoneScore = 0

    for zoneId, zone in pairs(myCity.zoneManager.zoneIdMap or {}) do
        if zone:Explored() then
            self.focusZoneCfg = zone.config
            self.zoneScore = castle.ZoneRecoverScore[zoneId] or 0
            break
        end
    end

    if self.focusZoneCfg == nil then
        self._p_btn_mission_explore_title:SetActive(false)
        table.clear(self._inShowItems)
        table.clear(self._showAniItems)
        self._pool_expore_task:HideAll()
        self._go_base:SetActive(true)
        ---@see HUDExploreTask
        local item = self._pool_expore_task:GetItem()
        ---@type HUDExploreTaskData
        local param = {}
        param.taskId = 0
        param.content = I18N.Get("MVP12_chapter_task_9999")
        param.isFinished = false
        param.playFinished = false
        param.onverrideOnClick = function(param)
        end
        item:FeedData(param)
        return
    end
    self._p_text_mission_explore_title.text = I18N.GetWithParamList("city_area_task7", I18N.Get(self.focusZoneCfg:Name()))

    -- 非探索模式不显示具体探索任务
    if not myCity or not (myCity:IsInSingleSeExplorerMode() or myCity:IsInSeBattleMode()) then
        table.clear(self._inShowItems)
        table.clear(self._showAniItems)
        self._pool_expore_task:HideAll()
        self:UpdateProgress()
        self._go_base:SetActive(true)
        return
    end
    self._p_btn_mission_explore_title:SetActive(true)
    self._go_base:SetActive(true)
    if self._waitShowFinishedEnd then
        return
    end
    self._pool_expore_task:HideAll()
    local refTaskId = {}
    local scoreChanged = lastZoneScore ~= self.zoneScore
    local flyTarget = nil
    if scoreChanged and Utils.IsNotNull(self._p_effect_target) then
        local camera = g_Game.UIManager:GetUICamera()
        flyTarget = camera:WorldToScreenPoint(self._p_effect_target.position)
    end
    for i = 1, self.focusZoneCfg:RecoverTasksLength() do
        local taskId = self.focusZoneCfg:RecoverTasks(i)
        local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
        local oldState = self._inShowItems[taskId]
        local needShow = taskState == wds.TaskState.TaskStateCanFinish or taskState == wds.TaskState.TaskStateReceived
        local isFinishedShow = taskState == wds.TaskState.TaskStateCanFinish
        local needPlayFinish = oldState and oldState > 0 and oldState < wds.TaskState.TaskStateFinished and taskState == wds.TaskState.TaskStateFinished and not self._showAniItems[taskId]
        if needShow then
            ---@see HUDExploreTask
            local item = self._pool_expore_task:GetItem()
            ---@type HUDExploreTaskData
            local param = {}
            param.taskId = taskId
            param.content = ModuleRefer.QuestModule:GetTaskDescWithProgress(taskId, true)
            param.isFinished = isFinishedShow
            param.playFinished = false
            item:FeedData(param)
        elseif needPlayFinish then
            local item = self._pool_expore_task:GetItem()
            ---@type HUDExploreTaskData
            local param = {}
            param.taskId = taskId
            param.content = ModuleRefer.QuestModule:GetTaskDescWithProgress(taskId, true)
            param.isFinished = true
            param.playFinished = true
            param.playEffectScreenPos = flyTarget
            param.flyEffectHost = self
            item:FeedData(param)
            self._waitShowFinishedEnd = self._aniTime
            self._showAniItems[taskId] = true
        end
        refTaskId[taskId] = taskId
        self._inShowItems[taskId] = taskState
    end
    for taskId, _ in pairs(self._inShowItems) do
        if not refTaskId[taskId] then
            self._inShowItems[taskId] = nil
            self._showAniItems[taskId] = nil
        end
    end
    if not self._waitShowFinishedEnd then
        self:UpdateProgress()
    end
    for _, value in pairs(self._flyEffects) do
        if Utils.IsNotNull(value) then
            value.transform:SetAsLastSibling()
        end
    end
end

function HUDExploreComponent:OnTaskDBChanged()
    self:UpdatePanel()
end

---@param entity wds.CastleBrief
function HUDExploreComponent:OnZoneScoreChanged(entity, changeTable)
    local city = ModuleRefer.CityModule:GetMyCity()
    if city == nil or entity.ID ~= city.uid then
        return
    end

    if self.focusZoneCfg == nil then return end
    local Add = changeTable.Add or {}
    local Remove = changeTable.Remove or {}
    if Add[self.focusZoneCfg:Id()] or Remove[self.focusZoneCfg:Id()] then
        self:UpdatePanel()
    end
end

function HUDExploreComponent:OnZoneStatusChanged(city, addMap)
    if city ~= ModuleRefer.CityModule:GetMyCity() then
        return
    end

    self:UpdatePanel()
end

function HUDExploreComponent:Tick(dt)
    if not self._waitShowFinishedEnd then
        return
    end
    self._waitShowFinishedEnd = self._waitShowFinishedEnd - dt
    if #self._flyEffects > 0 then
        local lerp = math.inverseLerp(0, self._aniTime, 1 - math.max(0, self._waitShowFinishedEnd))
        local targetPos = self._p_effect_target.position
        for _, value in pairs(self._flyEffects) do
            if Utils.IsNotNull(value) then
                local currentPos = value.transform.position
                value.transform.position = CS.UnityEngine.Vector3.Lerp(currentPos, targetPos, lerp)
                value.transform:SetAsLastSibling()
            end
        end
    end
    if self._waitShowFinishedEnd <= 0 then
        self._waitShowFinishedEnd = nil
        table.clear(self._showAniItems)
        for _, value in pairs(self._flyEffects) do
            if Utils.IsNotNull(value) then
                CS.UnityEngine.Object.Destroy(value)
            end
        end
        table.clear(self._flyEffects)
        self:UpdatePanel()
    end
end

---@param effect CS.UnityEngine.GameObject
function HUDExploreComponent:AddFlyEffect(effect)
    if Utils.IsNull(effect) then
        return
    end
    if Utils.IsNull(self._p_effect_target) then
        CS.UnityEngine.Object.Destroy(effect)
        return
    end
    effect.transform:SetParent(self._transform, true)
    table.insert(self._flyEffects, effect)
    effect:SetActive(true)
    if effect.transform.childCount > 0 then
        local child = effect.transform:GetChild(0)
        if Utils.IsNotNull(child) then child:SetVisible(true) end
    end
    effect.transform:SetAsLastSibling()
end

return HUDExploreComponent