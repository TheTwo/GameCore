local GUILayout = require("GUILayout")
local GMPage = require("GMPage")

---@class GMPageLua:GMPage
---@field _commandHistory debugLuaCommand[]
local GMPageLua = class('GMPageLua', GMPage)

---@class debugLuaCommand
---@field i number
---@field raw string
---@field c string
---@field r string
---@field s number | "0-none, 1-success, 2-failed"
local debugLuaCommand = class('debugLuaCommand')

---@param index number
---@param str string
function debugLuaCommand:ctor(index, str)
    self.i = index
    self.raw = str
    self.r = ''
    self.s = 0
end

---@return string
function debugLuaCommand:GetStatus()
    if self.s == 2 then
        return '✖'
    elseif self.s == 1 then
        return '✔'
    end
    return '?'
end

function GMPageLua:ctor()
    self._inputText = ""
    self._commandHistory = {}
    self._historyScrollPos = CS.UnityEngine.Vector2.zero
    self._inputHistory = {}
    for i = 1, 5 do
        local inputStr = g_Game.PlayerPrefsEx:GetString("CommandLua" .. i, '')
        if not string.IsNullOrEmpty(inputStr) then
            self._inputHistory[#self._inputHistory + 1] = inputStr
        end
    end
end

function GMPageLua:OnGUI()
    GUILayout.BeginVertical()
    self:DrawHistory()
    GUILayout.FlexibleSpace()
    self:DrawInputHistory()
    self:DrawInput()
    GUILayout.EndVertical()
end

function GMPageLua:DrawHistory()
    GUILayout.BeginVertical()
    self._historyScrollPos = GUILayout.BeginScrollView(self._historyScrollPos)
    for _,v in ipairs(self._commandHistory) do
        GUILayout.Label(string.format("[%d][%s]----------------\n%s\n----------------\nresult->", v.i, v:GetStatus(), v.raw))
        GUILayout.Label(v.r)
    end
    GUILayout.EndScrollView()
    GUILayout.EndVertical()
end

function GMPageLua:DrawInputHistory()
    GUILayout.BeginHorizontal(GUILayout.shrinkHeight, GUILayout.shrinkWidth)
    if #self._inputHistory > 0 then
        if GUILayout.Button("✖︎", GUILayout.Height(28), GUILayout.shrinkWidth) then
            for index, _ in ipairs(self._inputHistory) do
                g_Game.PlayerPrefsEx:DeleteKey("CommandLua" .. index)
                g_Game.PlayerPrefsEx:Save()
            end
            table.clear(self._inputHistory)
        end
    end
    for _, str in ipairs(self._inputHistory) do
        if GUILayout.Button(str, GUILayout.GetButtonLeftSkin(true, true), GUILayout.MaxWidth(88), GUILayout.Height(28)) then
            self._inputText = str
        end
    end
    GUILayout.EndHorizontal()
end

function GMPageLua:DrawInput()
    GUILayout.BeginHorizontal()
    self._inputText = GUILayout.TextArea(self._inputText, GUILayout.expandWidth)
    if GUILayout.Button("✔︎", GUILayout.MaxWidth(36)) then
        if not (self._inputText == nil or self._inputText == '') then
            local command = self:AddCommand(self._inputText)
            self:AddInputHistory(self._inputText)
            self._inputText = ""
            self:DoCommand(command)
        end
    end
    if GUILayout.Button("✖︎", GUILayout.MaxWidth(36))  then
        self._inputText = ""
    end
    if GUILayout.Button("CLS", GUILayout.MaxWidth(36)) then
        self:Clear()
    end
    GUILayout.EndHorizontal()
end

---@param str string
---@return debugLuaCommand
function GMPageLua:AddCommand(str)
    local c= debugLuaCommand.new(#self._commandHistory + 1, str)
    table.insert(self._commandHistory, c)
    return c
end

---@param c debugLuaCommand
function GMPageLua:DoCommand(c)
    local f = load(c.raw)
    c.s = 2
    if f then
        local s, r = xpcall(f, debug.traceback)
        if s then
            c.s = 1
            c.r = tostring(r)
            return
        end
        c.r = r
        return
    end
    c.r = "load failed"
end

function GMPageLua:Clear()
    table.clear(self._commandHistory)
end

function GMPageLua:AddInputHistory(str)
    for _, historyStr in ipairs(self._inputHistory) do
        if historyStr == str then
            return
        end
    end
    if #self._inputHistory >= 5 then
        table.remove(self._inputHistory, 1)
    end
    self._inputHistory[#self._inputHistory + 1] = str
    for index, inputStr in ipairs(self._inputHistory) do
        g_Game.PlayerPrefsEx:SetString("CommandLua" .. index, inputStr)
    end
end

return GMPageLua