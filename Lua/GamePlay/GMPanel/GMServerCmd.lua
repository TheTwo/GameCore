local RuntimeDebugSettings = require("RuntimeDebugSettings")
local rapidJson = require("rapidjson")
local ModuleRefer = require("ModuleRefer")
local UnityWebRequest = CS.UnityEngine.Networking.UnityWebRequest

---@class GMServerCmd
---@field new fun():GMServerCmd
local GMServerCmd = sealedClass('GMServerCmd')

---@class GMServerCmdPair
---@field cmd string
---@field desc string|nil
---@field arg nil|string[]
---@field needEntity boolean

---@param panel GMPanel
function GMServerCmd:ctor(panel)
    ---@private
    ---@type boolean
    self._isReady = false
    ---@private
    ---@type boolean
    self._singleGmEmpty = false
    ---@private
    ---@type GMServerCmdPair[]
    self._cmdList = {}
    ---@private
    ---@type CS.UnityEngine.Networking.UnityWebRequestAsyncOperation
    self._webRequestOperation = nil
    ---@private
    ---@type string|nil
    self._singleGmBase = string.Empty
    ---@private
    ---@type string|nil
    self._singleGmUrl = string.Empty
    ---@private
    ---@type number
    self._selectedIndex = 0
    ---@private
    ---@type string[]
    self._selectArgs = {}
    self._panel = panel
end

function GMServerCmd:IsReady()
    return self._isReady
end

function GMServerCmd:IsInRequest()
    return self._webRequestOperation ~= nil
end

function GMServerCmd:NeedRefresh()
    return not self._isReady and self._webRequestOperation == nil and not self._singleGmEmpty
end

function GMServerCmd:IsEmptySingleGm()
    return self._singleGmEmpty
end

function GMServerCmd:SetSelected(index)
    if index <= 0 or index > #self._cmdList then
        return
    end
    if self._selectedIndex == index then
        return
    end
    table.clear(self._selectArgs)
    self._selectedIndex = index
end

function GMServerCmd:GetSelectedArg(index)
    return self._selectArgs[index]
end

function GMServerCmd:SetSelectedArg(index, content)
    self._selectArgs[index] = content
end

function GMServerCmd:SelectedIndex()
    return self._selectedIndex
end

---@return GMServerCmdPair
function GMServerCmd:GetSelected()
    return self._cmdList[self._selectedIndex]
end

---@return fun():any,GMServerCmdPair
function GMServerCmd:PairsCmd()
    local key = nil
    ---@type GMServerCmdPair
    local value = nil
    return function()
        key, value = next(self._cmdList, key)
        if value then
            return key, value
        end
    end
end

function GMServerCmd:Release()
    self._isReady = false
    self._singleGmEmpty = true
    table.clear(self._cmdList)
    if not (nil == self._webRequestOperation) then
        local operation = self._webRequestOperation
        self._webRequestOperation = nil
        operation.webRequest:Dispose()
    end
end

function GMServerCmd:SendSelected()
    local selected = self:GetSelected()
    if not selected then
        return
    end
    self:SendCmd(selected, self._selectArgs)
end

---@param cmd GMServerCmdPair
---@param args string[]
function GMServerCmd:SendCmd(cmd, args)
    if not cmd then
        return
    end
    local id = ModuleRefer.PlayerModule.playerId
    local sendJson = {
        ["cmd"] = cmd.cmd,
        ["id"] = id,
        ["param"] = {
            args[1] or '',
            args[2] or '',
            args[3] or '',
            args[4] or '',
            args[5] or '',
        },
    }
    local sendUrl = self._singleGmUrl
    local sendJsonStr = rapidJson.encode(sendJson)
    ---@type CS.UnityEngine.Networking.UnityWebRequestAsyncOperation
    local op = CS.DragonReborn.Utilities.UnityWebRequestExt.SendPostJsonString(sendUrl, sendJsonStr)
    op:completed('+', function(asyncOp)
        if not string.IsNullOrEmpty(op.webRequest.error) then
            g_Logger.Error("SendTo:%s with:%s ret:%s", sendUrl, sendJsonStr, op.webRequest.error)
        end
        g_Logger.Log(op.webRequest.downloadHandler.text)
        op.webRequest:Dispose()
    end)
end

function GMServerCmd:Tick()
    if not (nil == self._webRequestOperation) then
        if self._webRequestOperation.isDone then
            local operation = self._webRequestOperation
            self._webRequestOperation = nil
            self:DecodeServerGMCmd(operation)
            operation.webRequest:Dispose()
        end
    end
end

function GMServerCmd:RefreshCmdList()
    self._isReady = false
    self._selectedIndex = 0
    table.clear(self._cmdList)
    self._singleGmEmpty = false
    self._singleGmBase = string.Empty
    self._singleGmUrl = string.Empty
    local n,a,p,s,i,singleGmPage = RuntimeDebugSettings:GetOverrideServerConfig()
    if string.IsNullOrEmpty(singleGmPage) then
        if self._panel then
            local serverList = self._panel:FindPage(require("GMPageSelectServer"))
            if serverList and serverList._serverList then
                singleGmPage = self:TryMatchSingleGm(serverList._serverList)
                if not string.IsNullOrEmpty(singleGmPage) then
                    goto RefreshCmdList_continue
                end
            end
        end
        self._singleGmEmpty = true
        return
    end
    ::RefreshCmdList_continue::
    self._singleGmBase = string.format("http://%s/debug", singleGmPage)
    self._singleGmUrl = string.format("http://%s/debug/cmd", singleGmPage)
    local url = string.format("http://%s/system/cmdlist", singleGmPage)
    self._webRequestOperation = UnityWebRequest.Get(url):SendWebRequest()
end

---@private
---@param requestOperation CS.UnityEngine.Networking.UnityWebRequestAsyncOperation
function GMServerCmd:DecodeServerGMCmd(requestOperation)
    table.clear(self._cmdList)
    self._selectedIndex = 0
    if nil == requestOperation or nil == requestOperation.webRequest or nil == requestOperation.webRequest.downloadHandler then
        return
    end
    local retJsonText = requestOperation.webRequest.downloadHandler.text
    g_Logger.LogChannel(nil, "DecodeServerGMCmd:%s", retJsonText)
    if string.IsNullOrEmpty(retJsonText) then
        return
    end
    local terms = rapidJson.decode(retJsonText);
    if nil == terms then
        return
    end
    local data = terms["data"]
    if not data then
        return
    end
    for _, cmdContent in pairs(data) do
        if cmdContent and cmdContent.arg and cmdContent.arg == rapidJson.null then
            cmdContent.arg = nil
        end
        table.insert(self._cmdList, cmdContent)
    end
    table.sort(self._cmdList, function(a, b)
        return a.cmd < b.cmd
    end)
    self._isReady = true
end

function GMServerCmd:SendAddItem(itemId, count)
    if not self._isReady then
        return false
    end
    if count <= 0 then
        return
    end
    ---@type GMServerCmdPair
    local cmd = {}
    cmd.cmd = "additem"
    local args = {tostring(itemId), tostring(count)}
    self:SendCmd(cmd, args)
    return true
end

---@param serverList {addr:string,port:number,name:string,server_id:string,addr_http_cmd:string}[]|nil
function GMServerCmd:TryMatchSingleGm(serverList)
    if not serverList then
        return string.Empty
    end
    local connect = g_Game.ServiceManager.connect
    if not connect then
        return string.Empty
    end
    local addr, port, svrName = connect.addr, connect.port, connect.svrName
    if string.IsNullOrEmpty(addr) then
        return string.Empty
    end
    for i, v in pairs(serverList) do
        if v.addr == addr and port == v.port and svrName == v.name and not string.IsNullOrEmpty(v.addr_http_cmd) then
            return v.addr_http_cmd
        end
    end
    return string.Empty
end

function GMServerCmd:GetWebUrl()
    return self._singleGmBase
end

return GMServerCmd