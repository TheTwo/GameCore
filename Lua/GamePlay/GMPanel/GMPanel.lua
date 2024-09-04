local Delegate = require("Delegate")
local GUIPanelScope = require("GUIPanelScope")
local GUILayout= require("GUILayout")
local GMPanelConfig = require("GMPanelConfig")
local RuntimeDebugSettings = require("RuntimeDebugSettings")
local RuntimeDebugSettingsKeyDefine = require("RuntimeDebugSettingsKeyDefine")
local UnityEngine= CS.UnityEngine
local Time = UnityEngine.Time
local Input = UnityEngine.Input
local KeyCode = UnityEngine.KeyCode
local ModuleRefer = require('ModuleRefer')
local DebugCmdParameter = require('DebugCmdParameter')
local SdkCrashlytics = require("SdkCrashlytics")
local StoryActionUtils = require("StoryActionUtils")
local GMServerCmd = require("GMServerCmd")
local EventConst = require("EventConst")
local GMPanel_ServerCmd = require("GMPanel_ServerCmd")
local GMPageUtils = require("GMPageUtils")

---@class GMPanel
---@field private scope GUIPanelScope
---@field private headerNames string[]
---@field private headers GMHeader[]
---@field private pageNames string[]
---@field private pages GMPage[]
---@field private showPanel boolean
---@field private showLogPanel boolean
---@field private lastShowPanel boolean
---@field private selectionScrollPos CS.UnityEngine.Vector2
---@field private pageContentScrollPos CS.UnityEngine.Vector2
---@field private selectionWidth "GUILayoutOption"
---@field private blockGestureRef BlockGestureRef
local GMPanel = class('GMPanel')
GMPanel.HeaderTargetX = 960
GMPanel.HeaderTargetY = 540
GMPanel.PanelTargetX = 640
GMPanel.PanelTargetY = 360
---@type GMPanel
GMPanel.Panel = nil
if UNITY_RUNTIME_ON_GUI_ENABLED then
    GMPanel.runtimeOff = false
else
    GMPanel.runtimeOff = true
end

local function LogExceptionOrError(result)
    if not SdkCrashlytics.LogCSException(result) then
        SdkCrashlytics.LogLuaErrorAsException(result)
    end
end

---@class GMPanelSetting
---@field hideHeader boolean
local GMPanelSetting = class('GMPanelSetting')
GMPanelSetting.hideHeader = true
GMPanelSetting.hideDebugConsole = false
function GMPanelSetting:get_enableServiceLog()
    return g_Game.ServiceManager.enableLog
end

function GMPanelSetting:set_enableServiceLog(value)
    if UNITY_EDITOR then
        CS.UnityEditor.EditorPrefs.SetInt("GMPanelEnableServiceManagerLog", value and 1 or 0)
    end
    g_Game.ServiceManager.enableLog = value
end

function GMPanelSetting:get_enableDatabaseLog()
    return g_Game.DatabaseManager.enableLog
end

function GMPanelSetting:set_enableDatabaseLog(value)
    if UNITY_EDITOR then
        CS.UnityEditor.EditorPrefs.SetInt("GMPanelEnableDatabaseManagerLog", value and 1 or 0)
    end
    g_Game.DatabaseManager.enableLog = value
end

local function FindConsoleModule()
    local genericBuilder = xlua.get_generic_method(CS.DragonReborn.FrameworkInterfaceManager, 'QueryFrameInterface')
    local queryFrameInterface = genericBuilder(CS.DragonReborn.IFrameworkInGameConsole)
    if queryFrameInterface then
        local ret,panel = queryFrameInterface()
        if ret then
            return panel
        end
    end
    return nil
end

function GMPanel:ctor()
    self.scope = GUIPanelScope.new()
    self.headerNames = {}
    self.headers = {}
    self.pageNames = {}
    self.pages = {}
    self.selectedPageIndex = 0
    self.showPanel = false
	self.showLogPanel = false
    self.lastShowPanel = false
    self.selectionScrollPos = UnityEngine.Vector2.zero
    self.selectionWidth = GUILayout.Width(GMPanel.PanelTargetX / 6)
    self.selectionWidthModify = function(offset)
        return GUILayout.Width(GMPanel.PanelTargetX / 6 + offset)
    end
    self.triggerDelay = nil
    self.panelWindowId = 10901
    self.logPanel = nil
    self.blockGestureRef = nil
    self.runTimeSettings = GMPanelSetting.new()
    local has, _ = RuntimeDebugSettings:GetInt(RuntimeDebugSettingsKeyDefine.DebugGMHeadersVisible)
    self.runTimeSettings.hideHeader = not ((UNITY_EDITOR or UNITY_DEBUG or UNITY_RUNTIME_ON_GUI_ENABLED or USE_UWA) and has)
    has,_ = RuntimeDebugSettings:GetInt(RuntimeDebugSettingsKeyDefine.DebugGMRuntimeConsoleVisible)
	self.runTimeSettings.hideDebugConsole = not (INGAME_CONSOLE_ENABLED and has)
	---@type CS.UnityEngine.CanvasGroup[]
    self._uiRoot = {}
    ---@type GMServerCmd
    self._serverCmdProvider = nil
    GMPanel.Panel = self
    self.serverCmdPanel = nil
end

function GMPanel:Init()
    self.guiOnWindowDelegate = g_Game.debugSupport.CallOnGuiWindowsEvent
    self.logPanel = FindConsoleModule()
    self.serverCmdPanel = GMPanel_ServerCmd.new(self)
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateUpdate))
    g_Game:AddOnGUI(Delegate.GetOrCreate(self, self.OnGUI))
    g_Game:AddOnDrawGizmos(Delegate.GetOrCreate(self, self.OnDrawGizmos))
    g_Game:AddOnGUIWindow(Delegate.GetOrCreate(self, self.OnWindowCallBack))
    g_Game.ServiceManager:AddResponseCallback(DebugCmdParameter.GetMsgId(),Delegate.GetOrCreate(self,self.OnCmdCallBack))
    self._serverCmdProvider = GMServerCmd.new(self)
    self:InitModel()
    if self.logPanel then
        if self.runTimeSettings.hideDebugConsole then
            self.logPanel:SetVisible(false)
        end
    end
    g_Game.EventManager:AddListener(EventConst.GAME_ERROR_CLEAR_TICK_DELEGATES, Delegate.GetOrCreate(self, self.OnErrorClearTick))
    CS.DragonReborn.FrameworkInterfaceManager.SetupLuaExecutor(GMPanel.LuaExecutor)
end

function GMPanel:Tick()
    if self.runtimeOff then
        return
    end
    for _,v in ipairs(self.headers) do
        v:Tick()
    end
    if self.showPanel then
        if self._serverCmdProvider then
            self._serverCmdProvider:Tick()
        end
        if self.selectedPageIndex > 0 then
            self.pages[self.selectedPageIndex]:Tick()
        end
    end
    if self.serverCmdPanel.showSelf then
        self.serverCmdPanel:Tick()
    end
    self:CheckTrigger()
end

function GMPanel:OnLateUpdate()
    -- if Input.GetMouseButtonDown(0) then
    --     if CS.UnityEngine.Rendering.OnDemandRendering.willCurrentFrameRender then
    --         CS.UnityEngine.Rendering.OnDemandRendering.renderFrameInterval = 1
    --         g_Logger.Error('set renderFrameInterval 1')
    --     end
    -- end

    -- if Input.GetMouseButtonUp(0) then
    --     if CS.UnityEngine.Rendering.OnDemandRendering.willCurrentFrameRender then
    --         CS.UnityEngine.Rendering.OnDemandRendering.renderFrameInterval = 2
    --         g_Logger.Error('set renderFrameInterval 2')
    --     end
    -- end
end

function GMPanel:TickEndOfFrame()
    
end

function GMPanel:Release()
    self:ReleaseModel()
    g_Game.EventManager:RemoveListener(EventConst.GAME_ERROR_CLEAR_TICK_DELEGATES, Delegate.GetOrCreate(self, self.OnErrorClearTick))
    g_Game:RemoveGUIWindow(Delegate.GetOrCreate(self, self.OnWindowCallBack))
    g_Game:RemoveOnGUI(Delegate.GetOrCreate(self, self.OnGUI))
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateUpdate))
    g_Game:RemoveOnDrawGizmos(Delegate.GetOrCreate(self, self.OnDrawGizmos))
    g_Game.ServiceManager:RemoveResponseCallback(DebugCmdParameter.GetMsgId(),Delegate.GetOrCreate(self,self.OnCmdCallBack))
    if self._serverCmdProvider then
        self._serverCmdProvider:Release()
    end
    self.logPanel = nil
    CS.DragonReborn.FrameworkInterfaceManager.SetupLuaExecutor(nil)
end

function GMPanel:OnGUI()
    if self.runtimeOff then
        return
    end
    try_catch_traceback(Delegate.GetOrCreate(self, self.OnGUIImp), LogExceptionOrError)
end

function GMPanel:OnGUIImp()
    local hasScope = false
    if not self.showPanel then
        if not self.runTimeSettings.hideHeader then
            self:DrawHeader(self.scope:Begin(GMPanel.HeaderTargetX, GMPanel.HeaderTargetY))
            hasScope = true
        end
    else
        self:DrawPanel(self.scope:Begin(GMPanel.PanelTargetX, GMPanel.PanelTargetY))
        hasScope = true
    end
    if hasScope then
        self.scope:End()
    end
end

function GMPanel:OnDrawGizmos()
    local KingdomMapUtils = require('KingdomMapUtils')
    ---@type CS.Grid.MapSystem
    local mapSystem = KingdomMapUtils.GetMapSystem()
    if mapSystem then
        mapSystem:DrawDebugInfo()
    end
end

function GMPanel:InitModel()
    for _,v in ipairs(GMPanelConfig.Headers) do
        table.insert(self.headerNames, v[1])
        table.insert(self.headers, v[2].new())
    end

    for _,v in ipairs(self.headers) do
        v:Init(self)
    end

    for _,v in ipairs(GMPanelConfig.Pages) do
        table.insert(self.pageNames, v[1])
        table.insert(self.pages, v[2].new())
    end

    for _,v in ipairs(self.pages) do
        v:Init(self)
    end
    self.serverCmdPanel:Init()
end

function GMPanel:ReleaseModel()
    self:PanelShow(false)
    self.selectedPageIndex = 0
    for _,v in ipairs(self.pages) do
        v:Release()
    end
    for _,v in ipairs(self.headers) do
        v:Release()
    end
    self.serverCmdPanel:Release()
end

function GMPanel:DrawHeader(rect)
    GUILayout.BeginArea(rect)
    GUILayout.BeginHorizontal(GUILayout.shrinkWidth, GUILayout.shrinkHeight)
    try_catch_traceback(function()
        for _,v in ipairs(self.headers) do
            v:OnGUI()
        end
    end, LogExceptionOrError)
    GUILayout.EndHorizontal()
    GUILayout.EndArea()
end

function GMPanel:GetCurrentConfigVersionStr()
    if not g_Game then return end
    if not g_Game.ConfigManager then return end
    if not g_Game.ConfigManager.GetRemoteConfigVersion then return end
    local branch, subvision = g_Game.ConfigManager:GetRemoteConfigVersion()
    if not branch and not subvision then return end
    local postFix = ''
    if USE_LOCAL_CONFIG then
        postFix = ":local"
    elseif USE_PRIVATE_SERVER_LOCAL_CONFIG then
        postFix = ":qa"
    end
    return ("%s/%s%s"):format(branch, subvision, postFix)
end

function GMPanel:DrawPanel(rect)
    if self.guiOnWindowDelegate then
        local versionStr = self:GetCurrentConfigVersionStr()
        if versionStr then
            GUILayout.Window(self.panelWindowId, rect, self.guiOnWindowDelegate, "GMPanel- F1 or 5 finger touch or control and [ and ] " .. versionStr)
        else
            GUILayout.Window(self.panelWindowId, rect, self.guiOnWindowDelegate, "GMPanel- F1 or 5 finger touch or control and [ and ] ")
        end
    end
end

function GMPanel:DrawPageSelection()
    GUILayout.BeginVertical(GUILayout.shrinkWidth, self.selectionWidth)
    if GUILayout.ColoredButton('关闭面板', CS.UnityEngine.Color.red) then
        self:PanelShow(false)
    end
    if GUILayout.ColoredButton('快速GM', CS.UnityEngine.Color.yellow) then
        self:OpenServerCmdWindow()
    end

    local rect = GUILayout.GetLastRect()
    GMPageUtils.DrawReddot(CS.UnityEngine.Vector2(rect.xMax - 2, rect.yMin + 2), 4)

    self.selectionScrollPos = GUILayout.BeginScrollViewWithVerticalBar(self.selectionScrollPos, GUILayout.shrinkWidth)

    if self.selectedPageIndex > 0 then
        local skin = GUILayout.GetUnitySkin("verticalScrollbar")
        local btnSzie = self.selectionWidthModify(-skin.fixedWidth - skin.margin.left - 8)
        local selected = GUILayout.SelectionGrid(self.selectedPageIndex - 1, self.pageNames, 1, GUILayout.shrinkWidth, GUILayout.shrinkHeight, btnSzie) + 1
        if self.selectedPageIndex ~= selected then
            self.pages[self.selectedPageIndex]:OnHide()
            self.selectedPageIndex = selected
            self.pages[self.selectedPageIndex]:OnShow()
        end
    end
    GUILayout.EndScrollView()
    GUILayout.EndVertical()
end

function GMPanel:DrawPageContent()
    GUILayout.BeginVertical(GUILayout.expandWidth)
    if self.selectedPageIndex > 0 then
        try_catch_traceback(function()
            self.pages[self.selectedPageIndex]:OnGUI()
        end, LogExceptionOrError)
    end
    GUILayout.EndVertical()
end

function GMPanel:PanelShow(show, keepUILock)
    if self.showPanel == show then
        return
    end
    self:TemporaryUIRootInteractable(not show)
    self.showPanel = show
    if self.showPanel then
        if self.selectedPageIndex == 0 and #self.pages > 0 then
            self.selectedPageIndex = 1
        end
        if not self.blockGestureRef then
            self.blockGestureRef = g_Game.GestureManager:SetBlockAddRef()
        end
        self.serverCmdPanel:PanelShow(false)
    else
        if self.blockGestureRef then
            self.blockGestureRef:UnRef()
        end
        self.blockGestureRef = nil
    end
    self:DoSwitchPageShow(self.showPanel)
    if self.logPanel then
        self.logPanel:SetVisible(not show and not self.runTimeSettings.hideDebugConsole)
    end
end

function GMPanel:OpenServerCmdWindow()
    self.serverCmdPanel:PanelShow(true)
    self:PanelShow(false)
    self:TemporaryUIRootInteractable(false)
end

function GMPanel:CloseServerCmdWindow()
    self.serverCmdPanel:PanelShow(false)
    self:TemporaryUIRootInteractable(true)
    self:PanelShow(true)
end

function GMPanel:IsPanelShow()
    return self.showPanel
end

---@generic T
---@param type T
---@return T
function GMPanel:FindPage(type)
    if not type then
        return nil
    end
    for i, v in pairs(self.pages) do
        if v.is and v:is(type) then
            return v
        end
    end
    return nil
end

---@param show boolean
function GMPanel:DoSwitchPageShow(show)
    if show then
        if not self.lastShowPanel then
            self.lastShowPanel = true
            if self.selectedPageIndex > 0 then
                self.pages[self.selectedPageIndex]:OnShow()
            end
        end
    else
        if self.lastShowPanel then
            self.lastShowPanel = false
            if self.selectedPageIndex > 0 then
                self.pages[self.selectedPageIndex]:OnHide()
            end
        end
    end
end

function GMPanel:CheckTrigger()
    if not self.guiOnWindowDelegate then
        return
    end
    if self.triggerDelay then
        self.triggerDelay = self.triggerDelay - Time.deltaTime
        if self.triggerDelay > 0 then
            return
        else
            self.triggerDelay = nil
        end
    end
    if Input.GetKeyUp(KeyCode.F1) 
        or Input.touchCount > 4 
        or ((Input.GetKey(KeyCode.LeftControl) or Input.GetKey(KeyCode.RightControl)) 
            and Input.GetKey(KeyCode.LeftBracket) and Input.GetKey(KeyCode.RightBracket)) then
        self.triggerDelay = 1
        if self.serverCmdPanel.showSelf then
            self:CloseServerCmdWindow()
        else
            self:PanelShow(not self.showPanel)
        end
    end

	if Input.GetKeyUp(KeyCode.F2) then
		self.showLogPanel = not self.showLogPanel
		self.logPanel:SetVisible(self.showLogPanel)
	end
end

function GMPanel:TemporaryUIRootInteractable(on)
    StoryActionUtils.TemporaryUIRootInteractable(on)
end

function GMPanel:OnWindowCallBack(id)
    if self.runtimeOff then
        return
    end
    if id ~= self.panelWindowId then
        return
    end
    GUILayout.BeginHorizontal(GUILayout.expandWidth)
    self:DrawPageSelection()
    self:DrawPageContent()
    GUILayout.EndHorizontal()
end


---@param cmd string
---@param ... number[]
function GMPanel:SendGMCmd(cmd,...)
    
    local playerId = ModuleRefer.PlayerModule:GetPlayer().ID
    if playerId > 0 then

        local param = DebugCmdParameter.new()
        param.args.Cmd = cmd
        param.args.EntityID = playerId

        for index, value in ipairs(table.pack(...)) do
            if not value then
                param.args.Args:Add('')
            else
                param.args.Args:Add(value)
            end
        end        

        param:Send()
    end
    
end

function GMPanel:OnCmdCallBack(res,message)
    if not res then
          g_Logger.Error(message)  
    end
end

function GMPanel:OnErrorClearTick()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.Tick))
end

function GMPanel:SetServerList(manifest)
    if manifest.server_list == nil then return end

    for index, name in ipairs(self.pageNames) do
        if name == "选服" then
            self.pages[index]:SetServerListFromManifest(manifest.server_list)
        end
    end
end

function GMPanel.LuaExecutor(codeStr)
    local f = load(codeStr)
    if not f then
        return false, "load code failed!"
    end
    local s, r = xpcall(f, debug.traceback)
    if s then
        return true, tostring(r)
    end
    return false, tostring(r)
end

return GMPanel
