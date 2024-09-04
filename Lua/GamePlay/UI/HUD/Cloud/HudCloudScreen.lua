local BaseUIMediator = require("BaseUIMediator")
local CloudDownloadState = require("CloudDownloadState")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")
local TimerUtility = require("TimerUtility")

---@class HudCloudScreenParam
---@field isFadeOut boolean
---@field assetBundles "CS.System.Collections.Generic.List<string>"
---@field onReady fun()
---@field isDebug boolean
---@field fastMode boolean

---@class HudCloudScreen:BaseUIMediator
---@field fadeIn boolean
---@field fadeOut boolean
---@field duration number
local HudCloudScreen = class("HudCloudScreen", BaseUIMediator)

function HudCloudScreen.GetFade()
	local deviceLevel = g_Game.PerformanceLevelManager:GetDeviceLevel()
	if deviceLevel == CS.DragonReborn.Performance.DeviceLevel.High then
		return 0.2,0.02
	elseif deviceLevel == CS.DragonReborn.Performance.DeviceLevel.Medium then
		return 0.3,0.0333
	end
	return 0.5,0.05
end

function HudCloudScreen:ctor()
	---@type CS.UnityEngine.Animator
	self.animator = nil
    ---@type table<CS.UnityEngine.CanvasGroup>
    self.enterCanvasGroups = nil
    ---@type table<CS.UnityEngine.CanvasGroup>
    self.leaveCanvasGroups = nil
    ---@type CS.UnityEngine.GameObject
	self.loadingPos = nil
	---@type CS.UnityEngine.UI.Slider
	self.downloadSlider = nil
	---@type HudCloudScreenParam
	self.param = nil
    
	self.logChanel = "HudClound"
	self.downloadState = CloudDownloadState.NO_DOWNLOAD
	self.totalByte = 0
	self.isCoverDone = false
	self.uncoverEventReceived = false
	self.onUncover = nil
	self.timer = nil
	self.fadeDuration = 0.5
	self.fadeDurationMaxStep = 0.05
end

---@param param HudCloudScreenParam
function HudCloudScreen:OnCreate(param)
    self.enterCanvasGroups = {}
    table.insert(self.enterCanvasGroups, self:BindComponent("p_fx_bigmap_cloud_qiehuan_enter", typeof(CS.UnityEngine.CanvasGroup)))

    self.leaveCanvasGroups = {}
    table.insert(self.leaveCanvasGroups, self:BindComponent("p_fx_bigmap_cloud_qiehuan_leave", typeof(CS.UnityEngine.CanvasGroup)))
    
	self.loadingPos = self:GameObject("p_loading_progress");
	self.downloadSlider = self:BindComponent("p_progress_bar_loading", typeof(CS.UnityEngine.UI.Slider))
end

---@param param HudCloudScreenParam
function HudCloudScreen:OnOpened(param)
	self.param = param
	self.fadeDuration,self.fadeDurationMaxStep = HudCloudScreen.GetFade()
	if param and param.fastMode then
		self.fadeDuration = 0
	end
    
	g_Game.EventManager:TriggerEvent(EventConst.HUD_CLOUD_SCREEN_OPEN)
	g_Game.EventManager:AddListener(EventConst.CLOUD_UNCOVER, Delegate.GetOrCreate(self, self.OnCloudUncover))
	g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
	self:StartDownLoadBundle()
    self:StartFadeIn()

	ModuleRefer.PerformanceModule:SetLoadingFinish(false)
    g_Game.PerformanceLevelManager:SetLoadingFinish(false)
end

---@param param HudCloudScreenParam
function HudCloudScreen:OnClose(param)
	g_Game.EventManager:TriggerEvent(EventConst.HUD_CLOUD_SCREEN_CLOSE)
	g_Game.EventManager:RemoveListener(EventConst.CLOUD_UNCOVER, Delegate.GetOrCreate(self, self.OnCloudUncover))
	g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))

	ModuleRefer.PerformanceModule:SetLoadingFinish(true)
    g_Game.PerformanceLevelManager:SetLoadingFinish(true)

	self.isCoverDone = false
	self.uncoverEventReceived = false;
	self.onUncover = nil

	if self.timer then
		self.timer:Stop()
		self.timer = nil
	end
end

function HudCloudScreen:IsPreventESC()
	return true
end

function HudCloudScreen:StartDownLoadBundle()
	local bundles = self.param.assetBundles
	if bundles ~= nil and bundles.Count > 0 then
		local onProgress = Delegate.GetOrCreate(self, self.DownloadProgress)
		local onFinish = Delegate.GetOrCreate(self, self.DownloadFinish)
		local totalByte = 0
		
		local isDebug = self.param.isDebug
		if isDebug then
			totalByte = ModuleRefer.AssetSyncModule:FakeSyncAssetBundles(bundles, onProgress, onFinish)
		else
			totalByte = ModuleRefer.AssetSyncModule:SyncAssetBundles(bundles, onProgress, onFinish, true)
		end

		if totalByte > 0 then
			self.downloadState = CloudDownloadState.NEED_DOWNLOAD
			self.totalByte = totalByte
		else
			self.downloadState = CloudDownloadState.NO_DOWNLOAD
			self:TryTriggerReady()
		end
	else
		self.downloadState = CloudDownloadState.NO_DOWNLOAD
		self:TryTriggerReady()
	end

	if Utils.IsNotNull(self.downloadSlider) then
		self.downloadSlider:SetVisible(self.downloadState == CloudDownloadState.NEED_DOWNLOAD)
		self.downloadSlider.value = 0
	end
end

function HudCloudScreen:DownloadProgress(curCount, maxCount, downloadedBytes, totalBytes)
	if Utils.IsNotNull(self.downloadSlider) then
		local ratio = downloadedBytes / totalBytes
		self.downloadSlider:DOValue(ratio, 0.2)
	end
end

function HudCloudScreen:DownloadFinish()
	g_Logger.LogChannel(self.logChanel, "Download finished.")
	self.downloadState = CloudDownloadState.DOWNLOAD_DONE
	self:TryTriggerReady()
	self:TryPlayUncoverAnimation()
end

function HudCloudScreen:OnCloudUncover(evt)
	g_Logger.LogChannel(self.logChanel, "Received uncover request.")
	self.uncoverEventReceived = true
	self.onUncover = evt.onUncover
	self:TryPlayUncoverAnimation()
end

function HudCloudScreen:OnCoverDone(param)
    g_Logger.LogChannel(self.logChanel, "Received animator cover done event.")
    self.isCoverDone = true
    self.delayCoverDone = true
end

function HudCloudScreen:OnUncoverDone(param)
    g_Logger.LogChannel(self.logChanel, "Received animator uncover done event.")
    self.delayUncoverDone = true
end

function HudCloudScreen:TryPlayUncoverAnimation()
	if not self.uncoverEventReceived or not self.isCoverDone or self.downloadState == CloudDownloadState.NEED_DOWNLOAD then
		return
	end

	g_Logger.LogChannel(self.logChanel, "Play uncover animation.")

	if self.downloadState == CloudDownloadState.DOWNLOAD_DONE then
		--为了保证进度条走到头再打开雾，延迟0.5秒触发打开动画
		self.timer = TimerUtility.DelayExecute(function()
            self:StartFadeOut(self.param.isFadeOut)
        end, 0.5)
	else
        self.timer = TimerUtility.DelayExecuteInFrame(function()
            self:StartFadeOut(self.param.isFadeOut)
        end)
    end
end

function HudCloudScreen:TryTriggerReady()
	if not self.isCoverDone or self.downloadState == CloudDownloadState.NEED_DOWNLOAD then
		return
	end

	if self.param.onReady then
		self.param.onReady()
	end
    
end

function HudCloudScreen:OnTick(dt)
	if self.delayCoverDone then
		self.delayCoverDone = nil
		self:TryTriggerReady()
		self:TryPlayUncoverAnimation()
		return
	end

	if self.delayUncoverDone then
		self.delayUncoverDone = nil
		g_Game.UIManager:Close(self:GetRuntimeId())
		if self.onUncover then
			self.onUncover()
		end
	end
	dt = math.min(self.fadeDurationMaxStep, dt)
    if self.fadeIn then
        self:FadeIn(dt)
    end
    if self.fadeOut then
        self:FadeOut(dt)
    end
end

function HudCloudScreen:StartFadeIn()
    self.fadeIn = true
    self.duration = self.fadeDuration
    self:SetAlpha(self.enterCanvasGroups, 0)
    self:SetAlpha(self.leaveCanvasGroups, 0)
end

---@param isFadeOut boolean @comment 云彩动画类型，true为云散开，false为云闭合
function HudCloudScreen:StartFadeOut(isFadeOut)
    self.fadeOut = true
    self.duration = self.fadeDuration
	if self.param and self.param.fastMode then
		self:SetAlpha(self.enterCanvasGroups, 0)
		self:SetAlpha(self.leaveCanvasGroups, 0)
	else
		self:SetAlpha(self.enterCanvasGroups, isFadeOut and 1 or 0)
    	self:SetAlpha(self.leaveCanvasGroups, isFadeOut and 0 or 1)
	end
end

function HudCloudScreen:FadeIn(dt)
    if self.fadeIn then
        self.duration = self.duration - dt
		if not self.param or not self.param.fastMode then
			local t = self.duration / self.fadeDuration
			local alpha = math.clamp01(1 - t)
			local canvasGroups = self.param.isFadeOut and self.enterCanvasGroups or self.leaveCanvasGroups
			self:SetAlpha(canvasGroups, alpha)
		end
        if self.duration <= 0 then
            self:OnCoverDone()
            self.fadeIn = false
        end
    end
end

function HudCloudScreen:FadeOut(dt)
    if self.fadeOut then
        self.duration = self.duration - dt
		if not self.param or not self.param.fastMode then
			local t = self.duration / self.fadeDuration
			local alpha = math.clamp01(t)
			local canvasGroups = self.param.isFadeOut and self.enterCanvasGroups or self.leaveCanvasGroups
			self:SetAlpha(canvasGroups, alpha)
		end
        if self.duration <= 0 then
            self:OnUncoverDone()
            self.fadeOut = false
        end
    end
end

---@param canvasGroups table<CS.UnityEngine.CanvasGroup>
function HudCloudScreen:SetAlpha(canvasGroups, value)
    ---@param canvasGroup CS.UnityEngine.CanvasGroup
    for _, canvasGroup in ipairs(canvasGroups) do
        canvasGroup.alpha = value
    end
end

return HudCloudScreen