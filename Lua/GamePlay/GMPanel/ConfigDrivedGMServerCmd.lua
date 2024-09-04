local rapidJson = require("rapidjson")
local RuntimeDebugSettings = require("RuntimeDebugSettings")
local ConfigRefer = require("ConfigRefer")
local UnityWebRequest = CS.UnityEngine.Networking.UnityWebRequest
local ModuleRefer = require("ModuleRefer")
---@class ConfigDrivedGMServerCmd:GMServerCmd
local ConfigDrivedGMServerCmd = class('ConfigDrivedGMServerCmd')

---@class CfgGMServerCmdArg
---@field Name string
---@field Pos1 number
---@field Pos2 number

---@class CfgGMServerCmdPair
---@field Name string
---@field System number
---@field GMCommands string[]
---@field GMArgs CfgGMServerCmdArg[]

---@param panel GMPanel
function ConfigDrivedGMServerCmd:ctor(panel)
    ---@private
    ---@type boolean
    self._isReady = false
    ---@private
    ---@type boolean
    self._singleGmEmpty = false
    ---@private
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
    self._cmdSystemTypes = {}
    ---@type table<string, GMServerCmdPair>
    self._cmdList = {}
    ---@type number
    self._selectedTypeIndex = 0
    ---@type string[][]
    self._selectedArgsList = {}
    ---@type table<number, number>
    self._typeIndex2Id = {}
    self._rspTxt = string.Empty
end

function ConfigDrivedGMServerCmd:IsReady()
    return self._isReady
end

function ConfigDrivedGMServerCmd:IsInRequest()
    return self._webRequestOperation ~= nil
end

function ConfigDrivedGMServerCmd:NeedRefresh()
    return not self._isReady and self._webRequestOperation == nil and not self._singleGmEmpty
end

function ConfigDrivedGMServerCmd:IsEmptySingleGm()
    return self._singleGmEmpty
end

function ConfigDrivedGMServerCmd:Release()
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

function ConfigDrivedGMServerCmd:PairsCmd(typeName)
    return pairs(self._cmdList[typeName])
end

function ConfigDrivedGMServerCmd:RefreshCmdList()
    self._isReady = false
    self._selectedIndex = 0
    table.clear(self._cmdList)
    self._singleGmEmpty = false
    self._singleGmBase = string.Empty
    self._singleGmUrl = string.Empty

    table.clear(self._cmdSystemTypes)
    local hasCfg = false
    for i, type in ConfigRefer.GmSystemType:ipairs() do
        self._cmdSystemTypes[type:Id()] = type:Name()
        self._cmdList[type:Name()] = {}
        self._typeIndex2Id[i] = type:Id()
        hasCfg = true
    end

    if hasCfg == false then
        self._singleGmEmpty = true
        return
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
    local url = string.format("http://%s/system/GMLists", singleGmPage)
    self._webRequestOperation = UnityWebRequest.Get(url):SendWebRequest()
end

function ConfigDrivedGMServerCmd:DecodeServerGMCmd(requestOperation)
    for _, v in pairs(self._cmdList) do
        table.clear(v)
    end
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
    ---@type _, CfgGMServerCmdPair
    for _, cmdContent in pairs(data) do
        local systemName = self._cmdSystemTypes[cmdContent.System]
        if not systemName then
            g_Logger.ErrorChannel('ConfigDrivedGMServerCmd', 'systemName is nil, system:%s', cmdContent.System)
            goto continue
        end
        table.insert(self._cmdList[systemName], cmdContent)
        ::continue::
    end
    self._isReady = true
end

function ConfigDrivedGMServerCmd:SetSelectedArgsList(index, pos, content)
    if not self._selectedArgsList[index] then
        self._selectedArgsList[index] = {}
    end
    self._selectedArgsList[index][pos] = content
end

function ConfigDrivedGMServerCmd:GetSelectedArg(index, pos)
    return (self._selectedArgsList[index] or {})[pos]
end

function ConfigDrivedGMServerCmd:SetSelected(index)
    if not self._selectedTypeIndex or self._selectedTypeIndex == 0 then
        self._selectedTypeIndex = 1
    end
    local selectedType = self:SelectedType()
    if index < 0 or index > #self._cmdList[selectedType] then
        return
    end
    if self._selectedIndex == index then
        return
    end
    self._selectedArgsList = {}
    for i, v in ipairs(self._cmdList[selectedType][index].GMArgs) do
        self._selectedArgsList[v.Pos1] = {}
    end
    self._selectedIndex = index
end

---@return CfgGMServerCmdPair
function ConfigDrivedGMServerCmd:GetSelected()
    local selectedType = self:SelectedType()
    return self._cmdList[selectedType][self._selectedIndex]
end

function ConfigDrivedGMServerCmd:SendSelected()
    local selected = self:GetSelected()
    if not selected then
        return
    end
    for i, cfgCmd in ipairs(selected.GMCommands) do
        ---@type GMServerCmdPair
        local cmd = {}
        cmd.cmd = cfgCmd
        self:SendCmd(cmd, self._selectedArgsList[i])
    end
end

function ConfigDrivedGMServerCmd:SendCmd(cmd, args)
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

function ConfigDrivedGMServerCmd:Tick()
    if not (nil == self._webRequestOperation) then
        if self._webRequestOperation.isDone then
            local operation = self._webRequestOperation
            self._webRequestOperation = nil
            self:DecodeServerGMCmd(operation)
            operation.webRequest:Dispose()
        end
    end
end

function ConfigDrivedGMServerCmd:TryMatchSingleGm(serverList)
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

function ConfigDrivedGMServerCmd:GetWebUrl()
    return self._singleGmBase
end

function ConfigDrivedGMServerCmd:GetCmdSystemTypes()
    return self._cmdSystemTypes
end

function ConfigDrivedGMServerCmd:GetRspText()
    return self._rspTxt
end

---@param typeName string
---@return GMServerCmdPair[]
function ConfigDrivedGMServerCmd:GetCmdListByTypeName(typeName)
    return self._cmdList[typeName]
end

function ConfigDrivedGMServerCmd:SelectedType()
    local index = self._typeIndex2Id[self._selectedTypeIndex]
    return self._cmdSystemTypes[index]
end

function ConfigDrivedGMServerCmd:GetSelectedTypeIndex()
    return self._selectedTypeIndex
end

function ConfigDrivedGMServerCmd:SetSelectType(index)
    self._selectedTypeIndex = index
end

return ConfigDrivedGMServerCmd