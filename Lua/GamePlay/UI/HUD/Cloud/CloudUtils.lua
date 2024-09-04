local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")

---@class CloudUtils
local CloudUtils = {}

---@param isFadeOut boolean @comment 云彩动画类型，true为云散开，false为云闭合
---@param onReady fun() @comment 通知上层逻辑，资源已就绪并且云已完全闭合，可以进行初始化逻辑
---@param bundles CS.System.Collections.Generic.List(typeof(CS.System.String)) @comment 云闭合时需要加载的资源
---@param isDebug boolean @comment 是否启用Debug模式
function CloudUtils.Cover(isFadeOut, onReady, bundles, isDebug)
    if isDebug == nil then
        local ModuleRefer = require("ModuleRefer")
        isDebug = ModuleRefer.AssetSyncModule:NeedSkipSyncState()
    end

    ---@type HudCloudScreenParam
    local param = 
    { 
        isFadeOut = isFadeOut,
        assetBundles = bundles, 
        onReady = onReady, 
        isDebug = isDebug 
    }
    if UNITY_DEBUG or UNITY_RUNTIME_ON_GUI_ENABLED then
        local setting = require("RuntimeDebugSettings")
        if setting and setting:GetCloudScreenFaseMode() then
            param.fastMode = true
        end
    end

    g_Game.UIManager:Open(UIMediatorNames.HudCloudScreen, param)
end

---@param onUncover fun() @comment 通知上层逻辑，云已经完全散开
function CloudUtils.Uncover(onUncover)
    local data = 
    {
        onUncover = onUncover 
    }
    g_Game.EventManager:TriggerEvent(EventConst.CLOUD_UNCOVER, data)
end

--在GM的LUA调试工具中执行此测试代码
function CloudUtils.TestCloud()
    local function OnReady()
        CloudUtils.Uncover()
    end

    local bundles = CS.System.Collections.Generic.List(typeof(CS.System.String))()
    bundles:Add("1")
    bundles:Add("2")
    bundles:Add("3")
    CloudUtils.Cover(false, OnReady, bundles, true)
end

--在GM的LUA调试工具中执行此测试代码
function CloudUtils.TestCloud1()
    local function OnReady()
        CloudUtils.Uncover()
    end

    CloudUtils.Cover(false, OnReady, nil, true)
end

return CloudUtils