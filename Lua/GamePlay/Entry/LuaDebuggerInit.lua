---@class LuaDebuggerInit
local LuaDebuggerInit = {}
LuaDebuggerInit._editorSaveKey = "LuaDebuggerChoice_Editor_Save_Key"
LuaDebuggerInit._disable = 0
LuaDebuggerInit._emmyLuaDebugger = 1
LuaDebuggerInit._luaPandaDebugger = 2
LuaDebuggerInit._debuggerStarted = LuaDebuggerInit._disable
---@type "EmmyLuaDebug"|"LuaPanda"
LuaDebuggerInit._currentDebugger = nil

function LuaDebuggerInit.ConnectDebugger()
    if UNITY_EDITOR then
        if LuaDebuggerInit._debuggerStarted ~= LuaDebuggerInit._disable then
            LuaDebuggerInit.ReleaseDebugger()
        end
        local EditorNameSpace = CS.UnityEditor
        if not EditorNameSpace then
            return
        end
        local EditorPrefs = EditorNameSpace.EditorPrefs
        if not EditorPrefs then
            return
        end
        local choice = EditorPrefs.GetInt(LuaDebuggerInit._editorSaveKey, LuaDebuggerInit._disable)
        if choice == LuaDebuggerInit._emmyLuaDebugger then
            LuaDebuggerInit._currentDebugger = require("EmmyLuaDebug")
            if LuaDebuggerInit._currentDebugger then
                LuaDebuggerInit._currentDebugger.InitEmmyLuaDebug()
            end
        elseif choice == LuaDebuggerInit._luaPandaDebugger then
            LuaDebuggerInit._currentDebugger = require("LuaPanda")
            if LuaDebuggerInit._currentDebugger then
                LuaDebuggerInit._currentDebugger.start("127.0.0.1",8818)
            end
        end
        LuaDebuggerInit._debuggerStarted = choice
    end
end

function LuaDebuggerInit.ReleaseDebugger()
    if UNITY_EDITOR then
        if LuaDebuggerInit._debuggerStarted == LuaDebuggerInit._disable then
            return
        end
        if LuaDebuggerInit._debuggerStarted == LuaDebuggerInit._emmyLuaDebugger then
            if LuaDebuggerInit._currentDebugger then
                LuaDebuggerInit._currentDebugger.StopEmmyLuaDebug()
            end
        elseif LuaDebuggerInit._debuggerStarted == LuaDebuggerInit._luaPandaDebugger then
            if LuaDebuggerInit._currentDebugger then
                LuaDebuggerInit._currentDebugger.disconnect()
            end
        end
        LuaDebuggerInit._currentDebugger = nil
        LuaDebuggerInit._debuggerStarted = LuaDebuggerInit._disable
    end
end

function LuaDebuggerInit.__DoOnUnload()
    LuaDebuggerInit.ReleaseDebugger()
end

return LuaDebuggerInit

