--多个编辑器同时运行项目只有第一个可以调试，如果需要同时调试可以修改端口号
--只处理OSX，win平台可以使用附加调试插件不需要改代码

local EmmyLuaDebugPort_Connect = 9966
local EmmyLuaDebugPort_Listen = 9967
local EmmyLuaDebugger = nil

local function InitEmmyLuaDebug()
    if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.OSXEditor
    or CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor
    then

        local corePath = CS.UnityEngine.Application.dataPath
        if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.OSXEditor then
            corePath = corePath .. "/../Tools/emmyluaDebug/emmy/mac/?.dylib"
        else
            corePath = corePath .. "/../Tools/emmyluaDebug/emmy/windows/x64/?.dll"
        end
        package.cpath = package.cpath .. ";" .. corePath
        EmmyLuaDebugger = require('emmy_core')
        local status, stackInfo = pcall(function()
            EmmyLuaDebugger.tcpConnect('localhost', EmmyLuaDebugPort_Connect)
        end
        )  
        if not status then
            g_Logger.Log('[EmmyDebug] Listening IDE '..EmmyLuaDebugPort_Listen)
            EmmyLuaDebugger.tcpListen('localhost', EmmyLuaDebugPort_Listen)
        end
    end
end


local function StopEmmyLuaDebug()
    if CS.UnityEngine.Application.isEditor and EmmyLuaDebugger ~= nil then
        EmmyLuaDebugger.stop()
        EmmyLuaDebugger = nil
    end
end

return {
    InitEmmyLuaDebug = function()
        local finally = try_catch(InitEmmyLuaDebug, function(error)
            CS.UnityEngine.Debug.LogError(error)
        end)

        if finally then
            StopEmmyLuaDebug()
        end
    end,

    StopEmmyLuaDebug = StopEmmyLuaDebug
}