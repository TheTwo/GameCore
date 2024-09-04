local GUILayout = require("GUILayout")
local GMPage = require("GMPage")

---@class GMPageNetwork:GMPage
local GMPageNetwork = class('GMPageNetwork', GMPage)

GMPageNetwork.CodecMap = {
    [0] = "AutoFit",
    [1] = "Protobuf",
    [2] = "Json",
    [3] = "MsgPack",
}

local function GetCodecString(codec)
    return GMPageNetwork.CodecMap[codec] or string.format("unknow:%s", tostring(codec))
end

GMPageNetwork.InfoCollection = {
    --{"---------------- Watcher ----------------", function(...) return nil end},
    --{"Connection Status", function(ConnectStatus, connect) return ConnectStatus.state or string.Empty end},
    --{"Address", function(ConnectStatus, connect) return ConnectStatus.addr or string.Empty end},
    --{"Port", function(ConnectStatus, connect) return tostring(ConnectStatus.port) end},
    --{"Name", function(ConnectStatus, connect) return ConnectStatus.name or string.Empty end},
    {"---------------- Connection Detail ----------------", function(...) return nil end},
    {"Codec", function(ConnectStatus, connect) return GetCodecString(connect:GetCodec()) end},
    {"ConnId", function(ConnectStatus, connect) return tostring(connect:GetConnId()) end},
    {"FingerPrint", function(ConnectStatus, connect) return tostring(connect:GetFingerPrint()) end},
    {"ServerId", function(ConnectStatus, connect) return connect:GetServerId() or string.Empty end},
    --{"LastError", function(ConnectStatus, connect) return connect:GetError() or string.Empty end},
}

if not GMPageNetwork.InfoCollectionLowerAdd then
    GMPageNetwork.InfoCollectionLowerAdd = true
    for _,i in ipairs(GMPageNetwork.InfoCollection) do
        i[3] = string.lower(i[1])
    end
end

function GMPageNetwork:ctor()
    self._scrollPos = CS.UnityEngine.Vector2.zero
    self._filter = nil
    self._netFullScreenLockDelay = string.Empty
end

function GMPageNetwork:OnShow()
    self._netFullScreenLockDelay = tostring(CS.NetLockDelayActive.MillisecondsDelayShowAni)
end

function GMPageNetwork:OnGUI()
    if g_Game and g_Game.ServiceManager and g_Game.ServiceManager.connect then
        local ConnectStatus = g_Game.ServiceManager.ConnectStatus
        local connect = g_Game.ServiceManager.connect:GetWatcherConnect()
        GUILayout.BeginHorizontal()
        GUILayout.Label("Search:",GUILayout.shrinkWidth)
        self._filter = GUILayout.TextField(self._filter, GUILayout.expandWidth)
        if GUILayout.Button("Copy", GUILayout.shrinkWidth) then
            self:Copy(ConnectStatus, connect)
        end
        GUILayout.EndHorizontal()
        local filter
        local inFilterMode = not string.IsNullOrEmpty(self._filter)
        if inFilterMode then
            filter = string.lower(self._filter)
        end
        self._scrollPos = GUILayout.BeginScrollView(self._scrollPos)
        for _,i in ipairs(self.InfoCollection) do
            local content = i[2](ConnectStatus, connect)
            if nil == content then
                if not inFilterMode then
                    GUILayout.Label(i[1])
                end
            else
                if (not inFilterMode) or string.find(i[3], filter) then
                    GUILayout.Label(string.format("%s:%s", i[1], content))
                end
            end
        end
        GUILayout.EndScrollView()
        GUILayout.BeginHorizontal()
        if GUILayout.Button("暂停Watcher解析") then
            g_Game.ServiceManager:PauseSerializeDeserializeLua()
        end
        if GUILayout.Button("恢复Watcher解析") then
            g_Game.ServiceManager:RecoverSerializeDeserializeLua()
        end
        GUILayout.EndHorizontal()
        if GUILayout.Button("断线重连") then
            g_Game.ServiceManager:OnDisconnected()
        end 
    else
        GUILayout.Label("unknown...")
    end
    GUILayout.BeginHorizontal()
    local localHas = CS.UnityEngine.PlayerPrefs.HasKey("MillisecondsDelayShowAni")
    if localHas then
        GUILayout.Label("网络全屏锁转圈延迟(GM已保存):")
    else
        GUILayout.Label("网络全屏锁转圈延迟:")
    end
    self._netFullScreenLockDelay = GUILayout.TextField(self._netFullScreenLockDelay)
    if GUILayout.Button("设置") then
        local t = tonumber(self._netFullScreenLockDelay)
        if t then
            CS.NetLockDelayActive.MillisecondsDelayShowAni = t
            CS.LoadingFlag.DelayShow = t / 1000.0
            CS.UnityEngine.PlayerPrefs.SetInt("MillisecondsDelayShowAni", t)
        else
            self._netFullScreenLockDelay = CS.NetLockDelayActive.MillisecondsDelayShowAni
        end
    end
    if localHas then
        if GUILayout.Button("清除GM设置") then
            CS.UnityEngine.PlayerPrefs.DeleteKey("MillisecondsDelayShowAni")
        end
    end
    GUILayout.EndHorizontal()
end

function GMPageNetwork:Copy(ConnectStatus, connect)
    local toCopy = {}
    for _,i in ipairs(self.InfoCollection) do
        local content = i[2](ConnectStatus, connect)
        if nil == content then
            table.insert(toCopy, i[1])
        else
            table.insert(toCopy,string.format("%s:%s", i[1], content))
        end
    end
    CS.UnityEngine.GUIUtility.systemCopyBuffer = table.concat(toCopy, '\n')
end

return GMPageNetwork