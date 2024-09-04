local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local GUIPanelScope = require('GUIPanelScope')

---@class GMPageToServerCmd:GMPage
---@field new fun():GMPageToServerCmd
---@field super GMPage
local GMPageToServerCmd = class('GMPageToServerCmd', GMPage)

function GMPageToServerCmd:ctor()
    self._nameFilter = ''
    self._nameLower = ''
    self._scrollPos = CS.UnityEngine.Vector2.zero
    self._scrollPos2 = CS.UnityEngine.Vector2.zero
    self._scrollPos3 = CS.UnityEngine.Vector2.zero

    self._selectedArgs = {}

    self.selectionWidth = GUILayout.Width(80)
    self.cmdHeight = GUILayout.Height(200)
    self.cmdWidth = GUILayout.Width(800)

    -- self.selectionWidth = GUILayout.Width(120)

end

function GMPageToServerCmd:OnShow()
    self._cmdProvider = self.panel._serverCmdProvider
    if self._cmdProvider and self._cmdProvider:NeedRefresh() then
        self._cmdProvider:RefreshCmdList()
    end
end

function GMPageToServerCmd:OnGUI()
    local provider = self._cmdProvider
    if not provider then
        return
    end
    if not provider:IsReady() then
        if provider:IsEmptySingleGm() then
            GUILayout.Label("找不到单服GM.....")
            return
        end
        if provider:IsInRequest() then
            GUILayout.Label("刷新GM列表中.....")
        end
        return
    end
    local webUrl = provider:GetWebUrl()
    if not string.IsNullOrEmpty(webUrl) then
        GUILayout.Label(("WebUrl:%s"):format(webUrl))
    end
    GUILayout.BeginHorizontal()
    if GUILayout.Button("刷新列表", GUILayout.shrinkWidth) then
        provider:RefreshCmdList()
        return
    end
    if not string.IsNullOrEmpty(webUrl) and GUILayout.Button("网页版", GUILayout.shrinkWidth) then
        CS.UnityEngine.Application.OpenURL(webUrl)
    end
    GUILayout.Label("Filter:", GUILayout.shrinkWidth)
    self._nameFilter = GUILayout.TextField(self._nameFilter, GUILayout.expandWidth)
    if not string.IsNullOrEmpty(self._nameFilter) then
        self._nameLower = string.lower(self._nameFilter)
    else
        self._nameLower = string.Empty
    end
    GUILayout.EndHorizontal()

    self._scrollPos = GUILayout.BeginScrollView(self._scrollPos)
    for index, v in provider:PairsCmd() do
        if not string.IsNullOrEmpty(self._nameLower) then
            if (not string.IsNullOrEmpty(v.cmd) and not string.match(v.cmd, self._nameLower)) 
                    and (not string.IsNullOrEmpty(v.desc) and not string.match(v.desc, self._nameLower)) then
                goto continue
            end
        end
        GUILayout.BeginHorizontal()
        GUILayout.Label(v.cmd .. ':' .. v.desc, GUILayout.expandWidth)
        if provider:SelectedIndex() ~= index then
            if GUILayout.Button("Select", GUILayout.shrinkWidth) then
                provider:SetSelected(index)
            end
        end
        GUILayout.EndHorizontal()
        ::continue::
    end
    GUILayout.EndScrollView()
    local selected = provider:GetSelected()
    if selected then
        GUILayout.FlexibleSpace()
        GUILayout.BoxLine(GUILayout.expandWidth, GUILayout.Height(2))
        GUILayout.BeginHorizontal()
        GUILayout.Label(selected.cmd .. ':' .. selected.desc, GUILayout.expandHeight)
        if GUILayout.Button("Send", GUILayout.shrinkWidth) then
            self:SendCmd()
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
                provider:SetSelectedArg(i, GUILayout.TextField(provider:GetSelectedArg(i) or ''))
                GUILayout.EndHorizontal()
            end
        end
    end
end

function GMPageToServerCmd:SendCmd()
    self._cmdProvider:SendSelected()
end

function GMPageToServerCmd:OnHide()
    self._cmdProvider = nil
end

return GMPageToServerCmd
