local GUILayout = require("GUILayout")
local RuntimeDebugSettings = require("RuntimeDebugSettings")
local ModuleRefer = require('ModuleRefer')
local GMPage = require("GMPage")

---@class GMPageAccount:GMPage
local GMPageAccount = class('GMPageAccount', GMPage)

function GMPageAccount:OnShow()
    local has
    local account
    has, account = RuntimeDebugSettings:GetOverrideAccountConfig()
    if has then
        self._curAccount = account
        self._overrideAccount = account
    else
        self._curAccount = string.Empty
        self._overrideAccount = string.Empty
    end

    local token
    has, token = RuntimeDebugSettings:GetOverrideToken()
    if has then
        self._overrideToken = token
    else
        self._overrideToken = string.Empty
    end

    local historyAccount
    has, historyAccount = RuntimeDebugSettings:GetHistoryAccountConfig()
    if has then
        self._historyAccount = string.split(historyAccount, "\n")
    else
        self._historyAccount = {}
    end
    self._btnWidth = GUILayout.Width(140)
    self._delWidth = GUILayout.Width(40)
    self._delList = {}
    local safeId 
    has, safeId = RuntimeDebugSettings:GetString('safe_id')
    if has then
        self._safeId = safeId
    else
        self._safeId = string.Empty
    end
    local password
    has, password = RuntimeDebugSettings:GetString('safe_password')
    if has then
        self._safePassword = password
    else
        self._safePassword = string.Empty
    end
    local skipNewbie
    has, skipNewbie = RuntimeDebugSettings:GetInt('skip_newbie')
    if has then
        self._skipNewbie = skipNewbie
    else
        self._skipNewbie = 0
    end
end

function GMPageAccount:OnGUI()
    GUILayout.BeginHorizontal()
    GUILayout.Label("当前覆盖账户(为空则是默认):", GUILayout.shrinkWidth)
    self._overrideAccount = GUILayout.TextField(self._overrideAccount)
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("覆写登录Token(登录后清空):", GUILayout.shrinkWidth)
    self._overrideToken = GUILayout.TextArea(self._overrideToken)
    if GUILayout.Button("设置覆盖Token", GUILayout.MinWidth(180)) then
        RuntimeDebugSettings:SetOverrideToken(self._overrideToken)
        g_Game:RestartGame()
    end
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    if GUILayout.Button("清除覆盖账户") then
        self._overrideAccount = string.Empty
        RuntimeDebugSettings:ClearOverrideAccountConfig()
    end
    GUILayout.FlexibleSpace()
    if GUILayout.Button("设置覆盖账户") then
        self:OverrideAccount(self._overrideAccount)
    end
    if GUILayout.Button("重启") then
        g_Game:RestartGame();
    end
    if GUILayout.Button("随机新账号重启") then
        self:AddToHistory(self._overrideAccount)
        RuntimeDebugSettings:ClearOverrideAccountConfig()
        g_Game:RestartGame()
    end
    GUILayout.EndHorizontal()

    local player = ModuleRefer.PlayerModule:GetPlayer()
    if player then
        GUILayout.BeginHorizontal()
        GUILayout.Label("PlayerID:")
        GUILayout.TextField(tostring(player.ID))
        GUILayout.EndHorizontal()
    end
    GUILayout.BeginHorizontal()
    local n,a,p,s,i,singleGmPage = RuntimeDebugSettings:GetOverrideServerConfig()
    if GUILayout.Button('打开GM页面') then       
        local server = ''
        server = s
        local guid = tostring(player.ID)
        local url = string.format('http://dev.ssr.funplus.io:81/?server=%s&entity=%s',server,guid)
        CS.UnityEngine.Application.OpenURL(url)
    end
    if not string.IsNullOrEmpty(singleGmPage) and not string.IsNullOrEmpty(s) then
        if GUILayout.Button("单服GM") then
            local url = string.format("http://%s/debug/?server=%s&entity=%s", singleGmPage, s, tostring(player.ID))
            CS.UnityEngine.Application.OpenURL(url)
        end
    end
    GUILayout.EndHorizontal()

    GUILayout.Label("内网身份信息：")
    GUILayout.BeginHorizontal()
    GUILayout.Label("内网身份ID:", GUILayout.Width(75))
    self._safeId = GUILayout.TextField(self._safeId, GUILayout.Width(120))
    GUILayout.Label("内网身份密码:", GUILayout.Width(85))
    self._safePassword = GUILayout.PasswordField(self._safePassword, string.byte("*"), GUILayout.Width(120))
    if GUILayout.Button("保存") then
        RuntimeDebugSettings:SetString('safe_id', self._safeId)
        RuntimeDebugSettings:SetString('safe_password', self._safePassword)
        g_Logger.Log('set safe info %s %s', self._safeId, self._safePassword)
    end
    GUILayout.EndHorizontal()

    GUILayout.Label("历史账号")
    for i, v in ipairs(self._historyAccount) do
        GUILayout.BeginHorizontal()
        if GUILayout.Button(v) then
            self:OverrideAccount(v)
        end
        if GUILayout.Button("用此号重启", self._btnWidth) then
            self:OverrideAccount(v)
            g_Game:RestartGame();
        end
        if GUILayout.Button("删除", self._delWidth) then
            table.insert(self._delList, v)
        end
        GUILayout.EndHorizontal()
    end

    if #self._delList > 0 then
        while #self._delList > 0 do
            table.removebyvalue(self._historyAccount, table.remove(self._delList))
        end
        RuntimeDebugSettings:SetHistoryAccountConfig(self._historyAccount)
    end
end

function GMPageAccount:OverrideAccount(account)
    if not string.IsNullOrEmpty(account) then
        if account ~= self._curAccount then
            self:AddToHistory(self._curAccount)
        end
        self._overrideAccount = account
        RuntimeDebugSettings:SetOverrideAccountConfig(self._overrideAccount)
    end
end

function GMPageAccount:AddToHistory(account)
    local idx = table.indexof(self._historyAccount, account)
    if idx > 0 then
        local value = table.remove(self._historyAccount, idx)
        table.insert(self._historyAccount, 1, value)
    else
        table.insert(self._historyAccount, 1, account)
    end
    while #self._historyAccount > 8 do
        table.remove(self._historyAccount)
    end
    RuntimeDebugSettings:SetHistoryAccountConfig(self._historyAccount)
end

return GMPageAccount