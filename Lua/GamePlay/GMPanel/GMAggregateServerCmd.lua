local RuntimeDebugSettings = require("RuntimeDebugSettings")
local UnityWebRequest = CS.UnityEngine.Networking.UnityWebRequest
local rapidJson = require("rapidjson")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")
local ConfigRefer = require("ConfigRefer")
---@class GMAggregateServerCmd
local GMAggreateServerCmd = class("GMAggreateServerCmd")

---@class GMAggreateServerCmdPair : GMServerCmdPair
---@field group string

---@param panel GMPanel
function GMAggreateServerCmd:ctor(panel)
    ---@type table<string, GMServerCmdPair>
    self._cmdList = {}
    ---@type table<string, GMServerCmdPair>
    self._nonAggCmdList = {}
    self._nonAggCmdList["其他"] = {}

    self._cmdSystemTypes = {}

    self._selectedTypeIndex = 0
    self._selectedIndex = 0
    self._isReady = false

    self._singleGmBase = string.Empty
    self._singleGmUrl = string.Empty

    self._singleGmEmpty = false

    ---@type CS.UnityEngine.Networking.UnityWebRequestAsyncOperation
    self._webRequestOperation = nil
    self._rspTxt = string.Empty

    ---@type table<string, GMServerCmdPair>
    self._nonAggregatedCmdsDict = {}

    self._selectedCmd = nil

    self._selectedArgs = {}
end

function GMAggreateServerCmd:IsReady()
    return self._isReady
end

function GMAggreateServerCmd:IsInRequest()
    return self._webRequestOperation ~= nil
end

function GMAggreateServerCmd:NeedRefresh()
    return not self._isReady and self._webRequestOperation == nil and not self._singleGmEmpty
end

function GMAggreateServerCmd:IsEmptySingleGm()
    return self._singleGmEmpty
end

function GMAggreateServerCmd:Release()
    self._isReady = false
    self._singleGmEmpty = true
    table.clear(self._cmdList)
    table.clear(self._cmdSystemTypes)
    if not (nil == self._webRequestOperation) then
        local operation = self._webRequestOperation
        self._webRequestOperation = nil
        operation.webRequest:Dispose()
    end
end

function GMAggreateServerCmd:Tick()
    if not (nil == self._webRequestOperation) then
        if self._webRequestOperation.isDone then
            local operation = self._webRequestOperation
            self._webRequestOperation = nil
            self:DecodeServerGMCmd(operation)
            operation.webRequest:Dispose()
        end
    end
end

function GMAggreateServerCmd:PairsCmd(typeName)
    return pairs(self._cmdList[typeName])
end

function GMAggreateServerCmd:PairsNonAggCmd(typeName)
    return pairs(self._nonAggCmdList[typeName])
end

function GMAggreateServerCmd:RefreshCmdList()
    self._isReady = false
    self._selectedIndex = 0
    table.clear(self._cmdList)
    self._singleGmEmpty = false
    self._singleGmBase = string.Empty
    self._singleGmUrl = string.Empty

    table.clear(self._cmdSystemTypes)

    ---@type number, GmSystemTypeConfigCell
    for _, v in ConfigRefer.GmSystemType:ipairs() do
        table.insert(self._cmdSystemTypes, v:Name())
        self._cmdList[v:Name()] = {}
    end

    self._selectedTypeIndex = 1

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

function GMAggreateServerCmd:DecodeServerGMCmd(requestOperation)
    for _, v in pairs(self._cmdList) do
        table.clear(v)
    end

    for _, v in pairs(self._nonAggCmdList) do
        table.clear(v)
    end

    self._selectedIndex = 0
    if nil == requestOperation or nil == requestOperation.webRequest or nil == requestOperation.webRequest.downloadHandler then
        return
    end
    local retJsonText = requestOperation.webRequest.downloadHandler.text
    g_Logger.LogChannel("GMAggreateServerCmd", "DecodeServerGMCmd:%s", retJsonText)
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
    ---@type number, GMAggreateServerCmdPair
    for _, cmdContent in pairs(data) do
        if not self:IsAggregateCmd(cmdContent) then
            self._nonAggregatedCmdsDict[cmdContent.cmd] = cmdContent
            goto continue
        end
        if cmdContent.desc == "(待补充)" then
            goto continue
        end
        if Utils.IsNullOrEmpty(cmdContent.group) then
            cmdContent.group = "其他"
        end
        if not table.ContainsValue(self._cmdSystemTypes, cmdContent.group) then
            table.insert(self._cmdSystemTypes, cmdContent.group)
            self._cmdList[cmdContent.group] = {}
        end
        table.insert(self._cmdList[cmdContent.group], cmdContent)
        ::continue::
    end

    for _, v in pairs(self._cmdList) do
        table.sort(v, function(a, b)
            return a.cmd < b.cmd
        end)
    end

    for _, v in ConfigRefer.GmSystemType:pairs() do
        local group = v:Name()
        if not self._nonAggCmdList[group] then
            self._nonAggCmdList[group] = {}
        end
        for i = 1, v:GMCommandsLength() do
            local cmd = v:GMCommands(i)
            local cmdContent = self._nonAggregatedCmdsDict[cmd]
            if cmdContent then
                table.insert(self._nonAggCmdList[group], cmdContent)
            end
        end
    end

    self._isReady = true
end

function GMAggreateServerCmd:TryMatchSingleGm(serverList)
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

function GMAggreateServerCmd:SetSelectType(index)
    self._selectedTypeIndex = index
end

function GMAggreateServerCmd:GetSelectedTypeIndex()
    return self._selectedTypeIndex
end

function GMAggreateServerCmd:SendCmd(cmd, args)
    if not cmd then
        return
    end
    if not args then args = {} end
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
        self._rspTxt = op.webRequest.downloadHandler.text
        op.webRequest:Dispose()
    end)
end

function GMAggreateServerCmd:SendSelected()
    local selected = self:GetSelected()
    if not selected then
        return
    end
    self:SendCmd(selected, self._selectedArgs)
end

---@param cmd GMServerCmdPair
function GMAggreateServerCmd:IsAggregateCmd(cmd)
    return string.find(cmd.cmd, "gmcommand") ~= nil
end

function GMAggreateServerCmd:GetCmdListByTypeName(typeName)
    return self._cmdList[typeName]
end

function GMAggreateServerCmd:SetSelected(cmd)
    self._selectedCmd = cmd
    table.clear(self._selectedArgs)
end

function GMAggreateServerCmd:GetSelected()
    return self._selectedCmd
end

function GMAggreateServerCmd:GetRspText()
    return self._rspTxt
end

function GMAggreateServerCmd:GetWebUrl()
    return self._singleGmBase
end

function GMAggreateServerCmd:GetCmdSystemTypes()
    return self._cmdSystemTypes
end

function GMAggreateServerCmd:SelectedType()
    return self._cmdSystemTypes[self._selectedTypeIndex]
end

function GMAggreateServerCmd:SetSelectedArg(index, arg)
    self._selectedArgs[index] = arg
end

function GMAggreateServerCmd:GetSelectedArg(index)
    return self._selectedArgs[index]
end

function GMAggreateServerCmd:HasAggGMCmdsByType(typeName)
    return self._cmdList[typeName] and #self._cmdList[typeName] > 0
end

function GMAggreateServerCmd:HasNonAggGMCmdsByType(typeName)
    return self._nonAggCmdList[typeName] and #self._nonAggCmdList[typeName] > 0
end

return GMAggreateServerCmd