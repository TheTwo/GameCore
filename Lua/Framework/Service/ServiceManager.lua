local Delegate = require("Delegate")
local ProtocolId = require("ProtocolId")
local ProtocolId2Name = require("ProtocolId2Name")
local UIHelper = require('UIHelper')
local SdkCrashlytics = require("SdkCrashlytics")
local ModuleRefer = require("ModuleRefer")
local EventConst = require("EventConst")
local Utils = require("Utils")

---@class ServiceManager
---@field new fun():ServiceManager
local ServiceManager = class('ServiceManager', require("BaseManager"))
local ClientType = {Tcp = 0, Kcp = 1, Mcp = 2}
local ClientTypeName = {
    [ClientType.Tcp] = "Tcp",
    [ClientType.Kcp] = "Kcp",
    [ClientType.Mcp] = "Mcp",
}
ServiceManager.ClientType = ClientType

---@class ServiceManagerStatusSummary
---@field Status number | "0:unknown" | "1:connecting" | "2:connected" | "-1:disconnected"
---@field Addr string
---@field Port number
---@field SvrName string
---@field ClientType number
---@field GetStatus fun(self:ServiceManagerStatusSummary):string

local function LogExceptionOrError(result)
    if not SdkCrashlytics.LogCSException(result) then
        SdkCrashlytics.LogLuaErrorAsException(result)
    end
end

function ServiceManager:SaveConnectParam(addr, port, svrName, svrId)
    self.addr = addr
    self.port = port
    self.svrName = svrName
    self.svrId = svrId
    g_Logger.Log('SaveConnectParam: addr %s, port %s, svrName %s, svrId %s', addr, port, svrName, svrId)
end

function ServiceManager:GetSavedConnectParam()
    return self.addr, self.port, self.svrName, self.svrId
end

function ServiceManager:ctor()
    self.enableLog = self:LogSwitch()
    self.addr = nil
    self.svrName = nil
    self.port = 0
    self.allCallback = {}
    self.connectCallback = {}
    self.disconnectCallback = {}
    ---@type Connect
    self.connect = nil
    ---@type table<CS.UnityEngine.RectTransform, boolean>
    self.uiLocker = {}

    self.deserializeMinMilliseconds = 10
    self.deserializeMaxMilliseconds = 15

    ---@param s ServiceManagerStatusSummary
    local function GetStatusFunc(s)
        if s.Status == 2 then
            return "⇅"
        end
        if s.Status == -1 then
            return "✘"
        end
        if s.Status == 1 then
            return "⥘"
        end
        return "?"
    end
    ---@type ServiceManagerStatusSummary
    self.statusSummary = {
        Status = 0,
        Addr = "",
        Port = 0,
        SvrName = nil,
        ClientType = 0,
        GetStatus = GetStatusFunc
    }
    self.reloginWhenKickout = true  
    self.blockMsgSend = false
end

function ServiceManager:Initialize()
    g_Game:AddSystemTicker(Delegate.GetOrCreate(self, self.Update), 1)
    SdkCrashlytics.RegisterProtocolId2Name(ProtocolId2Name)
    g_Logger.Log("Init ServiceManager.")
end

function ServiceManager:Reset()
    g_Logger.Log("Release Service.")

    if self.connect then
        self.connect:Dispose()
        self.connect = nil
    end
    self.enableLog = false
    self.blockMsgSend = false
    self.maxBackgroundTime = nil
    self.safeForegroundTime = nil
    self.maxHeaderCount = nil
    self.startBackgroundTime = nil
    self.startForegroundTime = nil
    self.addr = nil
    self.port = 0
    self.allCallback = {}
    self.connectCallback = {}
    self.disconnectCallback = {}
    g_Game:RemoveSystemTicker(Delegate.GetOrCreate(self, self.Update))
end

function ServiceManager:LogSwitch()
    if UNITY_EDITOR then
        return CS.UnityEditor.EditorPrefs.GetInt("GMPanelEnableServiceManagerLog") == 1
    else
        return false
    end
end

function ServiceManager:SetDeserializeMinMax(min, max)
    self.deserializeMinMilliseconds = min
    self.deserializeMaxMilliseconds = max
end

function ServiceManager:IsConnectionValid()
    return self.connect and self.connect:IsConnectionValid()
end

---@param addr string 服务器地址
---@param port number 服务器端口
function ServiceManager:Connect(addr, port, svrName, clientType)
    self.clientType = clientType or ClientType.Mcp
    self.statusSummary.Addr = addr
    self.statusSummary.Port = port
    self.statusSummary.SvrName = string.IsNullOrEmpty(svrName) and 'test' or svrName
    self.statusSummary.ClientType = self.clientType

    g_Logger.Trace(("连接类型:%s"):format(ClientTypeName[self.clientType]))
    local conn = require('Connect')
    self.connect = conn.new()
    self.connect:Initialize(addr, port, svrName, self.clientType)
    self.connect:SetDeserializeMinMilliseconds(self.deserializeMinMilliseconds)
    self.connect:SetDeserializeMaxMilliseconds(self.deserializeMaxMilliseconds)
    self.connect:SetConnectedCallback(Delegate.GetOrCreate(self, self.OnConnected))
    self.connect:SetDisconnectedCallback(Delegate.GetOrCreate(self, self.OnDisconnected))
    self.connect:SetHandshakedCallback(Delegate.GetOrCreate(self, self.OnHandshaked))
    self.connect:SetOnKickoutCallback(Delegate.GetOrCreate(self, self.OnKickout))
    self.connect:SetOnDataReceivedCallback(Delegate.GetOrCreate(self, self.OnDataReceived))

    SdkCrashlytics.RecordServerConnectInfo(addr, port, svrName)

    self.statusSummary.Status = 1
    self.connect:SetAccountId(self.accountId)
    self.connect:Connect()
    if self.enableLog then
        g_Logger.LogChannel('ServiceManager', "connect to server ip: %s, port: %s.", addr, port)
    end
end

function ServiceManager:Disconnect()
    g_Logger.ErrorChannel('ServiceManager', 'disconnect forwardly.')

    for _, v in pairs(self.disconnectCallback) do
        try_catch_traceback(v, LogExceptionOrError)
    end

    if self.connect then
        self.connect:Dispose()
        self.connect = nil
    end
    self.statusSummary.Status = -1
end

function ServiceManager:OnConnected()
    if self.enableLog then
        g_Logger.LogChannel('ServiceManager', 'on connected.')
    end
end

function ServiceManager:OnHandshaked()
    if self.enableLog then
        g_Logger.LogChannel('ServiceManager', 'on handshake success.')
    end
    for _, v in pairs(self.connectCallback) do
        try_catch_traceback(v, LogExceptionOrError)
    end
    self.statusSummary.Status = 2
    self.connect:StartPingPong()
end

function ServiceManager:OnDisconnected()
    g_Logger.Error("Start Reconnect.")
    self:RemoveAllLocker()
    ModuleRefer.ReloginModule:TryReconnect()
    -- self:RestartForOnDisconnected()
end

function ServiceManager:RestartForOnDisconnected()
    g_Logger.ErrorChannel('ServiceManager', 'connect disconnect.')
    ModuleRefer.FPXSDKModule:TrackCustomBILog("Disconnect")
    for _, v in pairs(self.disconnectCallback) do
        try_catch_traceback(v, LogExceptionOrError)
    end

    self.statusSummary.Status = -1
    if self.connect then
        self.connect:Dispose()
        self.connect = nil
    end

    local I18N = require("I18N")
    g_Game:RestartGameManually(("[NET]%s"):format(I18N.Get("error_feedback_title")), I18N.Get("system_restart_networkunstable"))
end

function ServiceManager:OnKickout(msg)
    if self.reloginWhenKickout then
        ModuleRefer.ReloginModule:TryReconnect()
    else
        g_Logger.Error(("been kickout, msg: %s"):format(tostring(msg)))
        ModuleRefer.FPXSDKModule:TrackCustomBILog("Kickout")
        local I18N = require("I18N")
        g_Game:RestartGameManually(("[NET-K]%s"):format(I18N.Get("error_feedback_title")), I18N.Get("system_restart_networkunstable"))
    end
end

function ServiceManager:OnDataReceived(header)
    if header.MsgId == 112 then
        g_Game.EventManager:TriggerEvent(EventConst.LOGIN_SELECT_SERVER_REQUEST, header)
    end
end

function ServiceManager:SetInitiativeDisconnectParam(maxTime, safeTime, maxHeaderCount)
    self.maxBackgroundTime = maxTime
    self.safeForegroundTime = safeTime
    self.maxHeaderCount = maxHeaderCount
end

function ServiceManager:IntoBackground()
    self.startBackgroundTime = CS.UnityEngine.Time.realtimeSinceStartup
end

function ServiceManager:IntoForeground()
    if not self.startBackgroundTime then return end
    if not self.maxBackgroundTime then return end
    if not self.maxHeaderCount then return end
    if not self.connect then return end

    self.startForegroundTime = CS.UnityEngine.Time.realtimeSinceStartup
    if UNITY_EDITOR then return end
    
    local backgroundTime = self.startForegroundTime - self.startBackgroundTime
    if backgroundTime > self.maxBackgroundTime then
        g_Logger.Error("后台时间过长,主动断开连接, self.startBackgroundTime:%.2f, self.startForegroundTime:%.2f backgroundTime:%.2f, maxBackgroundTime:%.2f", self.startBackgroundTime, self.startForegroundTime, backgroundTime, self.maxBackgroundTime)
        self:Disconnect()
        g_Game:RestartGame()
        return
    end
    local count = self.connect:GetInDeserializeQueueHeaderCount()
    if count > self.maxHeaderCount then
        g_Logger.Error("后台解析队列过长,主动断开连接, count:%s, maxHeaderCount:%s", tostring(count), tostring(self.maxHeaderCount))
        self:Disconnect()
        g_Game:RestartGame()
        return
    end
    self.startBackgroundTime = nil
end

function ServiceManager:SetAccountId(account)
    self.accountId = account
    if self.connect then
        self.connect:SetAccountId(account)
    end
end

function ServiceManager:SetCachedToken(token)
    self.token = token
end

function ServiceManager:Update()
    if self.connect then
        self.connect:Update()
    end

    self:CheckIfUILockerTimeout()
end

---@private
---@param lockable UILockData
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function ServiceManager:Send(req, lockable, userdata, guaranteeCommit, simpleErrorOverride)
    local connect = self.connect
    if connect == nil then
        return
    end

    local reqId = connect:GetNextRequestId()
    local msgName = req.msgName
    local msgId = req.msgId
    local protocolName = ProtocolId2Name[msgId]
    req.userdata = userdata
    UIHelper.UILock(lockable)
    if lockable then
        self.uiLocker[lockable] = g_Game.RealTime.realtimeSinceStartup
    end
    connect:RegisterReplyMessage(reqId, function(_, header)
        if header.MsgId ~= watcher.MsgId.SimpleError then
            local luaProto = header.LuaProto
            if luaProto then
                local code = luaProto["RetCode"] or luaProto["Retcode"]
                if code == nil or code == 0 then
                    if self.enableLog then
                        g_Logger.LogChannel('ServiceManager', "[↓][rpc.rsp.%s] with result:\n%s", msgName, luaProto)
                    end
                    self:OnResponse(msgId, true, luaProto, req)
                else
                    if ServiceManager.IsSystemError(code) then
                        g_Logger.ErrorChannel('ServiceManager', "[OnResponse]%s with error code: %d", msgName, code)
                        g_Game:RestartGameWithCode(code)
                    else
                        g_Logger.ErrorChannel('ServiceManager', "[↓][rpc.rsp.%s] with error: %s", msgName, luaProto)
                        self:OnResponse(msgId, false, luaProto, req, code)
                    end
                end
            else
                if self.enableLog and msgId ~= ProtocolId.Pong then
                    g_Logger.LogChannel('ServiceManager', "[↓][rpc.rsp.%s] with result:\n%s", msgName, luaProto)
                end
                self:OnResponse(msgId, true, luaProto, req)
            end
        else
            local errCode, simpleError = ServiceManager.DeserializeErrCodeFromHeaderJson(header.Json)
            if errCode then
                if ServiceManager.IsSystemError(errCode) then
                    g_Logger.ErrorChannel('ServiceManager', "[OnResponse SimpleError] with error code: %d", errCode)
                    g_Game:RestartGameWithCode(errCode)
                elseif ServiceManager.ExecSimpleErrorOverride(simpleErrorOverride, msgId, errCode, simpleError) then
                    g_Logger.TraceChannel("ServiceManager", "[↓][rpc.rsp.%s] with error has been override", msgName)
                else
                    g_Logger.ErrorChannel('ServiceManager', "[↓][rpc.rsp.%s] with error:\n%s", msgName, header.Json)
                    if UNITY_DEBUG or UNITY_EDITOR then
                        self:CommonErrorNoticeDev(errCode, ("[↓][rpc.rsp.%s]"):format(msgName), header.Json)
                    else
                        self:CommonErrorNotice(errCode)
                    end
                end
            else
                g_Logger.ErrorChannel('ServiceManager', "[↓][rpc.rsp.%s] with error:\n%s", msgName, header.Json)
            end
            self:OnResponse(msgId, false, nil, req, errCode)
        end
        if lockable then
            self.uiLocker[lockable] = nil
        end
        UIHelper.UIUnlock(lockable)
    end)

    if self.enableLog and msgId ~= ProtocolId.Pong and msgId ~= ProtocolId.SaveTroopPreset then
        g_Logger.LogChannel('ServiceManager', "[↑][rpc.req.%s] with argument:\n%s", msgName, req.request)
    end

    connect:Send(req.msgId, req, reqId)
    if msgId ~=ProtocolId.Pong then
        SdkCrashlytics.SetLastNetRequest(msgId, protocolName)
    end
end

---@private
function ServiceManager:OnResponse(msgId, isSuccess, data, req, errCode)
    local map = self.allCallback[msgId]
    if map then
        local toDone = {}
        for _, v in pairs(map) do
            table.insert(toDone, v)
        end

        for _, v in pairs(toDone) do
            try_catch_traceback_with_vararg(v, LogExceptionOrError, isSuccess, data, req, errCode)
        end
    end
end

function ServiceManager:OnPush(msgId, isSuccess, luaProto)
    local name = ProtocolId2Name[msgId]
    local code = luaProto["ErrCode"]
    if code == nil or code == 0 then
        if self.enableLog and msgId ~= ProtocolId.Ping and msgId ~= ProtocolId.PushServerTime then
            g_Logger.LogChannel('ServiceManager', "[↓][rpc.push.%s] with result:\n%s", name, FormatTable(luaProto))
        end
    else
        if ServiceManager.IsSystemError(code) then
            g_Logger.ErrorChannel('ServiceManager', "[OnPush]%s with error code: %d", tostring(name), code)
            g_Game:RestartGameWithCode(code)
        else
            g_Logger.ErrorChannel('ServiceManager', "[↓][rpc.push.%s] with error code %s", name, FormatTable(luaProto))
            if UNITY_DEBUG or UNITY_EDITOR then
                self:CommonErrorNoticeDev(code, ("[↓][rpc.push.%s]"):format(name), FormatTable(luaProto))
            else
                self:CommonErrorNotice(code)
            end
        end
    end
    local map = self.allCallback[msgId]
    if map then
        for _, v in pairs(map) do
            try_catch_traceback_with_vararg(v, LogExceptionOrError, isSuccess, luaProto)
        end
    end
    if msgId ~= ProtocolId.Ping then
        SdkCrashlytics.SetLastNetPush(msgId, name)
    end
end

function ServiceManager.IsSystemError(errCode)
    return errCode >= 20000 and errCode < 21000
end

---监听服务器连接事件
---@param callback fun():void
function ServiceManager:AddConnectCallback(callback)
    table.insert(self.connectCallback, callback)
end

---取消监听服务器连接事件
---@param callback fun():void
function ServiceManager:RemoveConnectCallback(callback)
    table.removebyvalue(self.connectCallback, callback, true)
end

---监听服务器断开连接事件
---@param callback fun():void
function ServiceManager:AddDisconnectCallback(callback)
    table.insert(self.disconnectCallback, callback)
end

---取消监听服务器断开连接事件
---@param callback fun():void
function ServiceManager:RemoveDisconnectCallback(callback)
    table.removebyvalue(self.disconnectCallback, callback, true)
end

---监听请求回应或Push消息
---@param msgId number use member of ProtocolId
---@param callback fun(isSuccess:boolean, rsp:table):void
function ServiceManager:AddResponseCallback(msgId, callback)
    local map = self.allCallback[msgId]
    if not map then
        map = {}
        self.allCallback[msgId] = map
    end
    table.insert(map, callback)
end

---取消监听请求回应或Push消息
---@param msgId number use member of ProtocolId
---@param callback fun(isSuccess:boolean, rsp:table):void
function ServiceManager:RemoveResponseCallback(msgId, callback)
    local map = self.allCallback[msgId]
    if map then
        table.removebyvalue(map, callback, true)
    end
end

function ServiceManager:GetPingMilliseconds()
    if self.connect then
        return self.connect:GetPingMilliseconds()
    end
    return -1
end

function ServiceManager:SetDeserializeMinMilliseconds(milliseconds)
    if self.connect then
        self.connect:SetDeserializeMinMilliseconds(milliseconds)
    end
    self.deserializeMinMilliseconds = milliseconds
end

function ServiceManager:SetDeserializeMaxMilliseconds(milliseconds)
    if self.connect then
        self.connect:SetDeserializeMaxMilliseconds(milliseconds)
    end
    self.deserializeMaxMilliseconds = milliseconds
end

function ServiceManager:CommonErrorNoticeDev(errCode, msgName, content)
    local cfg = g_Game:GetErrCodeI18NCfg(errCode)
    if cfg and cfg:ShowToastOnly() then
        local ModuleRefer = require("ModuleRefer")
        ModuleRefer.ToastModule:AddSimpleToast("[后端报错(Editor-Debug-Only)]"..g_Game:GetErrMsgWithCode(errCode))
        return
    end

    if cfg and cfg:BlockPopup() then
        return
    end

    local UIMediatorNames = require("UIMediatorNames")
    if g_Game.UIManager:IsOpenedByName(UIMediatorNames.CommonConfirmPopupMediator) then
        return
    end

    local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
    local I18N = require("I18N")
    local title = "未知系统"
    if cfg then
        title = string.IsNullOrEmpty(cfg:SystemName()) and "未命名系统" or cfg:SystemName()
    end
    local param = {
        content = ("%s\n[%s]:%s"):format(g_Game:GetErrMsgWithCode(errCode), msgName, content),
        styleBitMask = CommonConfirmPopupMediatorDefine.Style.Confirm | CommonConfirmPopupMediatorDefine.Style.ExitBtn,
        title = title,
        confirmLabel = I18N.Get("confirm"),
        onConfirm = function() return true end,
    }
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
end

function ServiceManager:CommonErrorNotice(errCode)
    local cfg = g_Game:GetErrCodeI18NCfg(errCode)
    if cfg and cfg:ShowToastOnly() then
        local ModuleRefer = require("ModuleRefer")
        ModuleRefer.ToastModule:AddSimpleToast(g_Game:GetErrMsgWithCode(errCode))
        return
    end

    if cfg and cfg:BlockPopup() then
        return
    end

    local UIMediatorNames = require("UIMediatorNames")
    if g_Game.UIManager:IsOpenedByName(UIMediatorNames.CommonConfirmPopupMediator) then
        return
    end
    
    local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
    local I18N = require("I18N")
    local param = {
        content = g_Game:GetErrMsgWithCode(errCode),
        styleBitMask = CommonConfirmPopupMediatorDefine.Style.Confirm | CommonConfirmPopupMediatorDefine.Style.ExitBtn,
        title = "System Error",
        confirmLabel = I18N.Get("confirm"),
        onConfirm = function() return true end,
    }
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
end

function ServiceManager:MCPPreferTCP(flag)
    if not self.connect then return end
    self.connect:SetMcpPreferTcp(flag)
end

function ServiceManager:SetKcpLogEnabled(flag)
    if not self.connect then return end
    self.connect:SetKcpLogEnabled(flag)
end

function ServiceManager:PauseSerializeDeserializeLua()
    if not self.connect then return end
    self.connect:PauseSerializeDeserializeLua()
end

function ServiceManager:RecoverSerializeDeserializeLua()
    if not self.connect then return end
    self.connect:RecoverSerializeDeserializeLua()
end

local CodecType_Json = watcher.CodecType.Json
local CommonMsgFlag_CMF_Request =  watcher.CommonMsgFlag.CMF_Request
function ServiceManager:SelectServerRequest(requestJson)
    if not self.connect then return end
    self.connect:AddPushSkip(112)
    local watcherConnect = self.connect.watcherConnect
    if watcherConnect then
        local header = watcherConnect:SpawnHeader()
        header.MsgId = 112
        header.Codec = CodecType_Json
        header.ComFlag = CommonMsgFlag_CMF_Request
        header.ReqId = self.connect:GetNextRequestId()
        header.Json = requestJson
        watcherConnect:Send(header)
    end
end

---@param json string
---@return table
function ServiceManager.ProcessSimpleErrorJson(json)
    local rapidJson = require("rapidjson")
    return rapidJson.decode(json)
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
---@param msgId number
---@param header any
---@return boolean
function ServiceManager.ExecSimpleErrorOverride(simpleErrorOverride, msgId, code, simpleError)
    if not simpleErrorOverride then
        return false
    end
    return simpleErrorOverride(msgId, code, simpleError)
end

function ServiceManager.DeserializeErrCodeFromHeaderJson(json)
    if string.IsNullOrEmpty(json) then return nil end

    local state, result = pcall(ServiceManager.ProcessSimpleErrorJson, json)
    if not state then
        return nil
    end

    local errorString = result["Err"]
    if not errorString or type(errorString) ~= 'string' then
        return nil
    end

    local erroCode = string.match(errorString, "%[%s*(%d+)[^%]]*%]")
    if erroCode then
        return tonumber(erroCode), result
    end
    return nil, nil
end

function ServiceManager:RemoveAllLocker()
    for rect, flag in pairs(self.uiLocker) do
        if Utils.IsNotNull(rect) then
            UIHelper.UIUnlock(rect)
        end
    end
    self.uiLocker = {}
end

function ServiceManager:CheckIfUILockerTimeout()
    for _, time in pairs(self.uiLocker) do
        if g_Game.RealTime.realtimeSinceStartup - time > 20 then
            self:RemoveAllLocker()
            self:RestartForOnDisconnected()
            break
        end
    end
end

return ServiceManager
