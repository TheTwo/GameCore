local Utils = require("Utils")
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ArtResourceUtils = require("ArtResourceUtils")
local SEEnvironment = require("SEEnvironment")
local BehaviourManager = require("BehaviourManager")
local KingdomScene = require("KingdomScene")
local TimelineGameEventDefine = require("TimelineGameEventDefine")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")

local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper

---@class StoryTimeline
---@field new fun():StoryTimeline
local StoryTimeline = class('StoryTimeline')

---@param config TimelineInfoConfigCell
function StoryTimeline.BuildWithConfig(config)
    local ret = StoryTimeline.new()
    local res = config:Path()
    local hideElements = {}
    for i = 1, config:TempHideCityElementLength() do
        hideElements[config:TempHideCityElement(i)] = true
    end
    if type(res) == 'number' then
        ret:FillData(config:Id(), ArtResourceUtils.GetItem(res), config:NoBlockGesture(), hideElements)
    else
        ret:FillData(config:Id(), res, config:NoBlockGesture(), hideElements)
    end
    return ret
end

function StoryTimeline:ctor()
    self._id = 0
    self._assetPath = nil
    self._noBlockGesture = false
    ---@type table<number, boolean>
    self._hideElements = nil
    
    self._assetReady = false
    self._isPlaying = false
    self._isPausing = false
    self._isStop = false
    
    self._createHelper = GameObjectCreateHelper.Create()
    
    ---@type CS.CG.Plot.PlotDirector
    self._director = nil
    ---@type CS.UnityEngine.GameObject
    self._timelineGo = nil

    ---@type boolean
    self._cameraSetup = false
    ---@type number @cameraCullMask
    self._lastCameraCullingMask = nil
    ---@type CS.UnityEngine.Camera[] @cameras in timeline
    self._timelineCameras = nil
    ---@type table<CS.UnityEngine.Light, number>
    self._overrideLights = {}
    ---@type BlockGestureRef
    self._blockRef = nil
    self._lastShadowCascadeCount = nil
    ---@type CS.CityFogController
    self._lastFogController = nil
    self._controlUiRuntimeId = nil
end

---@param id number
---@param assetPath string
---@param noBlockGesture boolean
---@param hideElements table<number, boolean>
function StoryTimeline:FillData(id, assetPath, noBlockGesture, hideElements)
    self._id = id
    self._assetPath = assetPath
    self._noBlockGesture = noBlockGesture
    self._hideElements = hideElements
end

---@param autoPlay boolean
function StoryTimeline:PrepareAsset(autoPlay)
    if not self._noBlockGesture then
        self._blockRef = g_Game.GestureManager:SetBlockAddRef()
    elseif self._blockRef then
        self._blockRef:UnRef()
        self._blockRef = nil
    end
    g_Logger.Log("开始创建storytimeline 资源， 当前frame:%s", CS.UnityEngine.Time.frameCount)
    self._createHelper:Create(self._assetPath, nil, function(go)
        if self._isStop then
            return
        end
        if Utils.IsNull(go) then
            g_Logger.Error("Timeline asset:%s not found!", self._assetPath)
            self:OnPlayEnd(false)
            return
        end
        self._timelineGo = go
        self._timelineGo:SetVisible(false)
        self._director = self._timelineGo:GetComponentInChildren(typeof(CS.CG.Plot.PlotDirector), true)
        if Utils.IsNull(self._director) then
            g_Logger.Error("Timeline asset:%s has no PlotDirector", self._assetPath)
            self:OnPlayEnd(false)
            return
        end
        if Utils.IsNotNull(self._director.reference)  then
            if self._director.reference.HideSceneLight then
                self:SetupSceneLight(false, self._timelineGo)
            end
            if self._director.reference.useInCityMode then
                local scene = g_Game.SceneManager.current
                if scene and scene:GetName() == KingdomScene.Name then
                    ---@type KingdomScene
                    local kingdomScene = scene
                    local city = kingdomScene:GetCurrentViewedCity()
                    if city then
                        self._timelineGo.transform:SetParent(city:GetRoot().transform, false)
                        self._timelineGo.transform.position = city.zeroPoint
                        if self._director.reference.HideFogInCity then
                            self:SetupHideCityFog(false, city.fogController)
                        end
                    else
                        g_Logger.Error("CurrentViewedCity is nil!")
                    end
                else
                    g_Logger.Error("not in KingdomScene!")
                end
            end
        end
        self._director.director.playOnAwake = false
        g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_HIDE_CITY_ELEMENTS_REFRESH, self._hideElements)
        g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_DIALOG_NEED_PAUSE, Delegate.GetOrCreate(self, self.OnDialogRequirePause))
        g_Game.EventManager:AddListener(EventConst.STORY_TIMELINE_UI_CONTROL_SKIP, Delegate.GetOrCreate(self, self.OnUIControlSkip))
        g_Logger.Log("创建storytimeline 资源回调， 当前frame:%s", CS.UnityEngine.Time.frameCount)
        self:OnAssetReady(autoPlay)
    end, 0, true)
end

function StoryTimeline:Play()
    if self._isPlaying and not self._isPausing then
        return
    end
    self._isPlaying = true
    self._isPausing = false
    self._isStop = false
    if not self._assetReady then
        return
    end
    if Utils.IsNull(self._timelineGo) then
        return
    end
    self._timelineGo:SetVisible(true)
    if Utils.IsNull(self._director) then
        return
    end
    ModuleRefer.StoryModule:SetStoryTimelinePlaying(true)
    if not self._lastShadowCascadeCount then
        local set,oldValue = CS.RenderExtension.RenderUtil.SetUrpShadowCasCadeCount(1)
        if set then
            self._lastShadowCascadeCount = oldValue
        end
    end
    self._director:Play(false)
    self._director.director:Evaluate()
end

function StoryTimeline:Pause()
    if self._isStop or not self._isPlaying or self._isPausing then
        return
    end
    self._isPausing = true
    if not self._assetReady then
        return
    end
    if Utils.IsNull(self._director) then
        return
    end
    self._director:Pause()
end

function StoryTimeline:PauseForDialog()
    if self._isStop then
        return
    end
    if not self._assetReady then
        return
    end
    if Utils.IsNull(self._director) then
        return
    end
    self._director:SpeedPause()
end

function StoryTimeline:ResumeForDialog()
    if self._isStop then
        return
    end
    if not self._assetReady then
        return
    end
    if Utils.IsNull(self._director) then
        return
    end
    self._director:SpeedResume()
end

---@param isSkip boolean
function StoryTimeline:Stop(isSkip)
    ModuleRefer.StoryModule:SetStoryTimelinePlaying(false)
    self:OnPlayEnd(isSkip)
end

---@param play boolean
function StoryTimeline:OnAssetReady(play)
    self._assetReady = true
    
    self:SetupCamera(false, self._timelineGo)
    
    self._director:RegisterOnPlayed(Delegate.GetOrCreate(self, self.DirectorCallPlayStart))
    self._director:RegisterOnPaused(Delegate.GetOrCreate(self, self.DirectorCallPlayPause))
    self._director:RegisterOnStopped(Delegate.GetOrCreate(self, self.DirectorCallPlayStop))

    local behaviourManager = BehaviourManager.Instance()
    self._director.OnBehaviourStart = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourStart)
    self._director.OnBehaviourEnd = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourEnd)
    self._director.OnBehaviourPause = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourPause)
    self._director.OnBehaviourResume = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourResume)
    self._director.OnBehaviourTick = Delegate.GetOrCreate(behaviourManager, behaviourManager.OnBehaviourTick)
    
    g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_ASSET_READY, self._id)
    ---@type StoryTimelineControlMediatorParameter
    local param = {}
    param.onSkipClick = function() 
        g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_UI_CONTROL_SKIP)
        return true
    end
    self._controlUiRuntimeId = g_Game.UIManager:Open(UIMediatorNames.StoryTimelineControlMediator, param)
    if not play then
        return
    end
    self:Play()
end

function StoryTimeline:OnPlayEnd(isSkip)
    if self._isStop then
        return
    end
    self._isStop = true
    self._isPausing = false
    self._isPlaying = false
    if Utils.IsNotNull(self._director) then
        self._director:Stop()
        self._director:ClearOnBehaviourCGLuaCallbacks()
    end
    CS.ScreenFadeEffectManager.Instance:DeactivateScreenFade()
    self:SetupCamera(true)
    self:SetupSceneLight(true)
    self:SetupHideCityFog(true)
    self._director = nil
    if Utils.IsNotNull(self._timelineGo) then
        self._timelineGo:SetVisible(false)
        GameObjectCreateHelper.DestroyGameObject(self._timelineGo)
    end
    self._timelineGo = nil
    g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_STOP, self._id)
    ModuleRefer.StoryModule:SetStoryTimelinePlaying(false)
    g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_HIDE_CITY_ELEMENTS_REFRESH, nil)
    if self._lastShadowCascadeCount then
        CS.RenderExtension.RenderUtil.SetUrpShadowCasCadeCount(self._lastShadowCascadeCount)
        self._lastShadowCascadeCount = nil
    end
    if self._blockRef then
        self._blockRef:UnRef()
    end
    self._blockRef = nil
end

function StoryTimeline:Release()
    BehaviourManager.Instance():OnTimelineExit()
    BehaviourManager.Instance():CleanUp()
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_DIALOG_NEED_PAUSE, Delegate.GetOrCreate(self, self.OnDialogRequirePause))
    g_Game.EventManager:RemoveListener(EventConst.STORY_TIMELINE_UI_CONTROL_SKIP, Delegate.GetOrCreate(self, self.OnUIControlSkip))
    if self._controlUiRuntimeId then
        g_Game.UIManager:Close(self._controlUiRuntimeId)
    end
    self._controlUiRuntimeId = nil
    self:SetupCamera(true, self._timelineGo)
    self:SetupSceneLight(true)
    self:SetupHideCityFog(true)
    if Utils.IsNotNull(self._createHelper) then
        self._createHelper:CancelAllCreate()
    end
    if Utils.IsNotNull(self._timelineGo) then 
        GameObjectCreateHelper.DestroyGameObject(self._timelineGo)
    end
    self._timelineGo = nil
    ModuleRefer.StoryModule:SetStoryTimelinePlaying(false)
    if self._lastShadowCascadeCount then
        CS.RenderExtension.RenderUtil.SetUrpShadowCasCadeCount(self._lastShadowCascadeCount)
        self._lastShadowCascadeCount = nil
    end
    if self._blockRef then
        self._blockRef:UnRef()
    end
    self._blockRef = nil
end

function StoryTimeline:OnDialogRequirePause(pause)
    if self._isStop then
        return
    end
    if pause then
        self:PauseForDialog()
    else
        self:ResumeForDialog()
    end
end

function StoryTimeline:DirectorCallPlayStart(director)
    self._isPlaying = true
    self._isPausing = false
    self._isStop = false
    g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_GAME_EVENT_START, { TimelineGameEventDefine.HUD_HIDE_PART, "everyThingButNotbossInfo"})
    g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_START, self._id)
end

function StoryTimeline:DirectorCallPlayPause(director)
    self._isPausing = true
    g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_PAUSE, self._id)
end

function StoryTimeline:DirectorCallPlayStop(director)
    g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_GAME_EVENT_END, { TimelineGameEventDefine.HUD_HIDE_PART, "everyThingButNotbossInfo"})
    self:OnPlayEnd(false)
end

function StoryTimeline:SetupCamera(isRestore, assetGo)
    if isRestore and not self._cameraSetup then
        return
    end
    if not isRestore and self._cameraSetup then
        return
    end
    ---@type CS.UnityEngine.Camera
    local camera
    if g_Game.SceneManager.current then
        if g_Game.SceneManager.current:GetName() == "KingdomScene" then
            -- kingdom/city
            ---@type KingdomScene
            local kingdomScene = g_Game.SceneManager.current
            camera = kingdomScene.basicCamera:GetUnityCamera()
        else
            -- se
            camera = SEEnvironment.Instance()._camera
        end
    end
    if isRestore then
        self._cameraSetup = false
        if Utils.IsNotNull(camera) then
            camera.enabled = true
        end
    else
        if Utils.IsNotNull(camera) then
            camera.enabled = false
        end
        self._cameraSetup = true
    end
end

---@param isRestore boolean
---@param timelineRoot CS.UnityEngine.GameObject
function StoryTimeline:SetupSceneLight(isRestore, timelineRoot)
    if isRestore then
        for light, lastEnabled in pairs(self._overrideLights) do
            if Utils.IsNotNull(light) then
                light.enabled = lastEnabled > 0 and true or false
            end
        end
        table.clear(self._overrideLights)
    else
        local timelineLightsSets = {}
        local timelineLights = timelineRoot:GetComponentsInChildren(typeof(CS.UnityEngine.Light), true)
        for i = 0, timelineLights.Length - 1 do
            timelineLightsSets[timelineLights[i]] = true
        end
        ---@type CS.UnityEngine.Light[]
        local sceneAllLight = CS.UnityEngine.Object.FindObjectsByType(typeof(CS.UnityEngine.Light), CS.UnityEngine.FindObjectsInactive.Include, CS.UnityEngine.FindObjectsSortMode.None)
        for i = 0, sceneAllLight.Length - 1 do
            local light = sceneAllLight[i]
            if not timelineLightsSets[light] then
                self._overrideLights[light] = light.enabled and 1 or 0
                light.enabled = false
            end
        end
    end
end

---@param isRestore boolean
---@param fogController CS.CityFogController
function StoryTimeline:SetupHideCityFog(isRestore, fogController)
    if isRestore then
        if Utils.IsNotNull(self._lastFogController) then
            self._lastFogController:SwitchFog(true)
        end
    else
        if Utils.IsNotNull(fogController) then
            self._lastFogController = fogController
            fogController:SwitchFog(false)
        end
    end
end

function StoryTimeline:OnUIControlSkip()
    g_Game.EventManager:TriggerEvent(EventConst.STORY_TIMELINE_GAME_EVENT_END, { TimelineGameEventDefine.HUD_HIDE_PART, "everyThing"})
    self:OnPlayEnd(true)
end

return StoryTimeline

