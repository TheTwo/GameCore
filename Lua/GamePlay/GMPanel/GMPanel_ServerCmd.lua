local Delegate = require("Delegate")
local GUIPanelScope = require("GUIPanelScope")
local GUILayout = require("GUILayout")
local GMAggregateServerCmd = require("GMAggregateServerCmd")
local SdkCrashlytics = require("SdkCrashlytics")
local GMPageUtils = require("GMPageUtils")

---@class GMPanel_ServerCmd
local GMPanel_ServerCmd = class('GMPanel_ServerCmd')

local PanelTargetX = 640
local PanelTargetY = 360

local function LogExceptionOrError(result)
    if not SdkCrashlytics.LogCSException(result) then
        SdkCrashlytics.LogLuaErrorAsException(result)
    end
end

function GMPanel_ServerCmd:ctor(panel)
    self.panel = panel
    self.scope = GUIPanelScope.new()
    self.showSelf = false
    self.types = nil
    self.windowId = nil
    self.guiOnWindowDelegate = nil
    self.selectionWidth = GUILayout.Width(PanelTargetX / 6)
    ---@type GMAggregateServerCmd
    self._serverCmd = GMAggregateServerCmd.new(panel)
    self.selectionScrollPos = CS.UnityEngine.Vector2.zero
    self.contentSelectionScrollPos = CS.UnityEngine.Vector2.zero
    self.selectionWidthModify = function(offset)
        return GUILayout.Width(PanelTargetX / 6 + offset)
    end

    self.maxCols = g_Game.PlayerPrefsEx:GetInt("GMPanel_ServerCmd_MaxCols", 1)
end

function GMPanel_ServerCmd:Init()
    self.guiOnWindowDelegate = g_Game.debugSupport.CallOnGuiWindowsEvent
    self.windowId = 10902
    g_Game:AddOnGUIWindow(Delegate.GetOrCreate(self, self.OnWindowCallBack))
    g_Game:AddOnGUI(Delegate.GetOrCreate(self, self.OnGUI))
end

function GMPanel_ServerCmd:Release()
    g_Game:RemoveGUIWindow(Delegate.GetOrCreate(self, self.OnWindowCallBack))
    g_Game:RemoveOnGUI(Delegate.GetOrCreate(self, self.OnGUI))
end

function GMPanel_ServerCmd:Tick()
    if self.showSelf and self._serverCmd then
        self._serverCmd:Tick()
    end
end

function GMPanel_ServerCmd:OnGUI()
    try_catch_traceback(function ()
        self:OnGUIImp()
    end, LogExceptionOrError)
end

function GMPanel_ServerCmd:OnGUIImp()
    local hasScope = false
    if self.showSelf then
        self:DrawPanel(self.scope:Begin(PanelTargetX, PanelTargetY))
        hasScope = true
    end
    if hasScope then
        self.scope:End()
    end
end

function GMPanel_ServerCmd:OnWindowCallBack(id)
    if id ~= self.windowId then return end
    GUILayout.BeginHorizontal(GUILayout.expandWidth)
    try_catch_traceback(function ()
        self:DrawSelection()
        self:DrawContent()
    end, LogExceptionOrError)
    GUILayout.EndHorizontal()
end

function GMPanel_ServerCmd:DrawPanel(rect)
    if self.guiOnWindowDelegate then
        GUILayout.Window(self.windowId, rect, self.guiOnWindowDelegate, "快速GM点击直接发送, 普通GM点击后填写参数发送")
    end
end

function GMPanel_ServerCmd:DrawSelection()
    GUILayout.BeginVertical(GUILayout.shrinkWidth, self.selectionWidth)
    if GUILayout.ColoredButton('关闭面板', CS.UnityEngine.Color.red) then
        self.panel:CloseServerCmdWindow()
        self.panel:PanelShow(false)
    end
    if GUILayout.ColoredButton('返回', CS.UnityEngine.Color.yellow) then
        self.panel:CloseServerCmdWindow()
    end
    if GUILayout.Button('刷新') then
        self._serverCmd:RefreshCmdList()
        return
    end
    self.selectionScrollPos = GUILayout.BeginScrollViewWithVerticalBar(self.selectionScrollPos, GUILayout.shrinkWidth)
    local selectedTypeIndex = self._serverCmd:GetSelectedTypeIndex()
    if selectedTypeIndex > 0 then
        local skin = GUILayout.GetUnitySkin("verticalScrollbar")
        local btnSzie = self.selectionWidthModify(-skin.fixedWidth - skin.margin.left - 8)
        local selected = GUILayout.SelectionGrid(selectedTypeIndex - 1, self._serverCmd:GetCmdSystemTypes(), 1, GUILayout.shrinkWidth, GUILayout.shrinkHeight, btnSzie) + 1
        if selected ~= selectedTypeIndex then
            self._serverCmd:SetSelectType(selected)
            self.showRsp = false
        end
    end
    GUILayout.EndScrollView()

    GUILayout.BeginHorizontal()
    GUILayout.Label("每行数量:", GUILayout.shrinkWidth)
    local maxCols = tonumber(GUILayout.TextField(tostring(self.maxCols or ""), GUILayout.expandWidth))
    if maxCols ~= self.maxCols then
        self.maxCols = maxCols
        g_Game.PlayerPrefsEx:SetInt("GMPanel_ServerCmd_MaxCols", self.maxCols)
    end
    GUILayout.EndHorizontal()

    GUILayout.EndVertical()
end

function GMPanel_ServerCmd:DrawContent()
    GUILayout.BeginVertical(GUILayout.expandWidth)
    if not self._serverCmd:IsReady() then
        GUILayout.Label("Loading...")
        GUILayout.EndVertical()
        return
    end
    local selectedTypeIndex = self._serverCmd:GetSelectedTypeIndex()
    if selectedTypeIndex > 0 then
        self.contentSelectionScrollPos = GUILayout.BeginScrollViewWithVerticalBar(self.contentSelectionScrollPos, GUILayout.expandWidth)
        local selectedTypeName = self._serverCmd:SelectedType()
        local maxCols = math.clamp((self.maxCols or 1), 1, 5)
        local colCount = 1
        -- GUILayout.BeginVertical(GUILayout.expandWidth)
        if self._serverCmd:HasAggGMCmdsByType(selectedTypeName) then
            GUILayout.Label("快速GM")
        end
        ---@type _, CfgGMServerCmdPair
        for k, v in self._serverCmd:PairsCmd(selectedTypeName) do
            if colCount == 1 then
                GUILayout.BeginHorizontal(GUILayout.expandWidth)
            end
            local color, content = GMPageUtils.GetXmlColorAndContent(v.desc)
            local style = CS.UnityEngine.GUIStyle(GUILayout.gui_cs.skin.button)
            if color then
                style.normal.textColor = color
                style.hover.textColor = color
                style.active.textColor = color
            end
            if GUILayout.Button(content, style, GUILayout.Width(PanelTargetX * (4.5 / 6) / maxCols)) then
                self._serverCmd:SendCmd(v)
                self.showRsp = true
            end
            colCount = colCount + 1
            if colCount > maxCols then
                GUILayout.EndHorizontal()
                colCount = 1
            end
        end
        if colCount > 1 then
            GUILayout.EndHorizontal()
        end

        colCount = 1

        if self._serverCmd:HasNonAggGMCmdsByType(selectedTypeName) then
            GUILayout.Label("普通GM")
        end
        for k, v in self._serverCmd:PairsNonAggCmd(selectedTypeName) do
            if colCount == 1 then
                GUILayout.BeginHorizontal(GUILayout.expandWidth)
            end
            local color, content = GMPageUtils.GetXmlColorAndContent(v.desc)
            local style = CS.UnityEngine.GUIStyle(GUILayout.gui_cs.skin.button)
            if color then
                style.normal.textColor = color
                style.hover.textColor = color
                style.active.textColor = color
            end
            if GUILayout.Button(content, style, GUILayout.Width(PanelTargetX * (4.5 / 6) / maxCols)) then
                self._serverCmd:SetSelected(v)
            end
            colCount = colCount + 1
            if colCount > maxCols then
                GUILayout.EndHorizontal()
                colCount = 1
            end
        end

        if colCount > 1 then
            GUILayout.EndHorizontal()
        end

        -- GUILayout.EndVertical()
        GUILayout.EndScrollView()
        local rsp = self._serverCmd:GetRspText()
        if rsp and rsp ~= string.Empty and self.showRsp then
            GUILayout.Label(rsp)
        end
        ---@type CfgGMServerCmdPair
        local selected = self._serverCmd:GetSelected()
        if selected then
            GUILayout.FlexibleSpace()
            GUILayout.BoxLine(GUILayout.expandWidth, GUILayout.Height(2))
            GUILayout.BeginHorizontal()
            GUILayout.Label(selected.desc, GUILayout.expandHeight)
            if GUILayout.Button("Send", GUILayout.shrinkWidth) then
                self._serverCmd:SendSelected()
                self.showRsp = true
            end
            GUILayout.EndHorizontal()
            local maxLength = 50
            if selected.arg and #selected.arg > 0 then
                for i, v in ipairs(selected.arg) do
                    GUILayout.BeginHorizontal()
                    if string.len(v) > maxLength then
                        v = string.sub(v, 1, maxLength) .. ".."
                    end
                    GUILayout.Label((v or "") .. ":", GUILayout.shrinkWidth)
                    self._serverCmd:SetSelectedArg(i, GUILayout.TextField(self._serverCmd:GetSelectedArg(i) or ''))
                    GUILayout.EndHorizontal()
                end
            end
        end
    end
    GUILayout.EndVertical()
end

function GMPanel_ServerCmd:PanelShow(show)
    self.showSelf = show
    if self.showSelf then
        self:BlockGesture()
        if self._serverCmd and self._serverCmd:NeedRefresh() then
            self._serverCmd:RefreshCmdList()
        end
    else
        self.showRsp = false
        self:UnblockGesture()
    end
end

function GMPanel_ServerCmd:BlockGesture()
    if not self.blockGestureRef then
        self.blockGestureRef = g_Game.GestureManager:SetBlockAddRef()
    end
end

function GMPanel_ServerCmd:UnblockGesture()
    if self.blockGestureRef then
        self.blockGestureRef:UnRef()
        self.blockGestureRef = nil
    end
end

return GMPanel_ServerCmd