local SdkCrashlytics = require("SdkCrashlytics")
local GUILayout = require("GUILayout")
local UnityUtils = CS.UnityEngine.Diagnostics.Utils
local UnityForcedCrashCategory = CS.UnityEngine.Diagnostics.ForcedCrashCategory

local GMPage = require("GMPage")

---@class GMPageExceptionTest:GMPage
---@field new fun():GMPageExceptionTest
---@field super GMPage
local GMPageExceptionTest = class('GMPageExceptionTest', GMPage)

function GMPageExceptionTest:ctor()
    self._testMsg = string.Empty
    self._delayTime = 0
    self._scrollPosition = CS.UnityEngine.Vector2.zero
end

function GMPageExceptionTest:OnGUI()
    self._scrollPosition = GUILayout.BeginScrollView(self._scrollPosition)
    GUILayout.BeginHorizontal()
    if GUILayout.Button("一键崩溃") then
        debug.manual_crush()
    end
    if GUILayout.Button("一键爆栈") then
        debug.manual_stackoverflow()
    end
    if GUILayout.Button("弹出重启窗") then
        g_Game:RestartGameWithCode(1)
    end
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("异常信息:", GUILayout.shrinkWidth)
    self._testMsg = GUILayout.TextField(self._testMsg)
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("延迟触发:", GUILayout.shrinkWidth)
    self._delayTime = tonumber(GUILayout.TextField(tostring(self._delayTime)))
    GUILayout.EndHorizontal()
    if GUILayout.Button("c# 定时异常") then
        SdkCrashlytics.DebugTestTriggerException(self._testMsg, self._delayTime)
    end
    GUILayout.Label("Unity Diagnostics 手动触发异常:", GUILayout.shrinkWidth)
    if GUILayout.Button("AccessViolation") then
        UnityUtils.ForceCrash(UnityForcedCrashCategory.AccessViolation)
    end
    if GUILayout.Button("FatalError") then
        UnityUtils.ForceCrash(UnityForcedCrashCategory.FatalError)
    end
    if GUILayout.Button("Abort") then
        UnityUtils.ForceCrash(UnityForcedCrashCategory.Abort)
    end
    if GUILayout.Button("PureVirtualFunction") then
        UnityUtils.ForceCrash(UnityForcedCrashCategory.PureVirtualFunction)
    end
    if GUILayout.Button("MonoAbort") then
        UnityUtils.ForceCrash(UnityForcedCrashCategory.MonoAbort)
    end
    GUILayout.EndScrollView()
end

return GMPageExceptionTest