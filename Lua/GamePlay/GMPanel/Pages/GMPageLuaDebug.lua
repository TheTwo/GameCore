local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local RuntimeDebugSettings = require("RuntimeDebugSettings")
local BaseUIComponent = require("BaseUIComponent")

---@class GMPageLua:GMPage
local GMPageLuaDebug = class('GMPageLuaDebug', GMPage)

function GMPageLuaDebug:ctor()
    self._luapandaHost = "127.0.0.1"
    self._luaPandaPort = "8818"
    local has,host,port = RuntimeDebugSettings:GetPandaConnection()
    if has then
        self._luapandaHost = host
        self._luaPandaPort = port
    end
end

function GMPageLuaDebug:OnGUI()
    if GUILayout.Button("Reload Lua") then
        self:ReloadLua()
    end

    GUILayout.BeginHorizontal()
    GUILayout.Label("LuaPandaHost:", GUILayout.shrinkWidth)
    self._luapandaHost = GUILayout.TextField(self._luapandaHost)
    GUILayout.Label("LuaPandaIp:", GUILayout.shrinkWidth)
    self._luaPandaPort = GUILayout.TextField(self._luaPandaPort)
    if GUILayout.Button("Start") then
        RuntimeDebugSettings:SetPandaConnection(self._luapandaHost, self._luaPandaPort)
        require("LuaPanda").start(self._luapandaHost, tonumber(self._luaPandaPort))
    end
    if GUILayout.Button("Stop") then
        require("LuaPanda").disconnect()
    end
    GUILayout.EndHorizontal()

    if UNITY_EDITOR then
        if GUILayout.Button("RestartEditorDebugger") then
            g_Game.ReleaseDebugger()
            g_Game.ConnectDebugger()
        end
    end

    GUILayout.BeginHorizontal()
    GUILayout.Label("Lua文件名:", GUILayout.shrinkWidth)
    self._inputRequire = GUILayout.TextArea(self._inputRequire, GUILayout.expandWidth)
    if GUILayout.Button("重新Require", GUILayout.MaxWidth(100)) then
        if not (self._inputRequire == nil or self._inputRequire == '') then
            if package.loaded[self._inputRequire] then
                package.loaded[self._inputRequire]=nil
                require(self._inputRequire)
            else
                error("只能重新require已经require过的文件!")
            end
        else
            error("输入的文件名为空!")
        end
    end
    GUILayout.EndHorizontal()

    GUILayout.BeginHorizontal()
    if GUILayout.Button("ReLoad All UI Lua", GUILayout.MaxWidth(300)) then
        ReloadLightClass("BaseUIComponent")
        for name, module in pairs(package.loaded) do
            if type(module) ~= "table" then goto continue end
            if rawget(module, '__class') and IsDerivedFrom(module.__class, BaseUIComponent.__class) then
                ReloadLightClass(name)
            end
            ::continue::
        end
        print("ReLoad All UI Lua Success!")
    end
    GUILayout.Label("关闭界面重启后生效", GUILayout.shrinkWidth)
    GUILayout.EndHorizontal()
end

function GMPageLuaDebug:ReloadLua()
    local reloadList = require("ReloadList")
    local ReloadLightClass = ReloadLightClass
    for _, v in pairs(reloadList) do
        ReloadLightClass(v)
    end
    package.loaded["ReloadList"] = nil
end

return GMPageLuaDebug