local runtimeDebugSettings = require("RuntimeDebugSettings")
local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local rapidJson = require("rapidjson");
local UnityEngine = CS.UnityEngine
local UnityWebRequest = UnityEngine.Networking.UnityWebRequest

---@class GMPageSelectServer:GMPage
local GMPageSelectServer = class('GMPageSelectServer', GMPage)

function GMPageSelectServer:ctor()
    self._loaded = false
    self._addr = string.Empty
    self._port = 0
    self._svrName = string.Empty
    self._svrId = string.Empty
    ---@type {addr:string,port:number,name:string,server_id:string,addr_http_cmd:string}[]
    self._serverList = {}
    self._webRequestOperation = nil
    self._scrollPos = UnityEngine.Vector2.zero
    self._nameFilter = ''
    self._nameLower = ''
end

function GMPageSelectServer:OnShow()
    if not self._loaded then
        -- self:RefreshServerList()
    end
end

function GMPageSelectServer:OnHide()
    self._webRequestOperation = nil
end

function GMPageSelectServer:OnGUI()
    if not self._loaded then
        GUILayout.Label("请求服务器列表中.....")
        return
    end
    if GUILayout.Button("重启游戏") then
        g_Game:RestartGame()
        return
    end
    GUILayout.BeginHorizontal()
    GUILayout.Label("Name", GUILayout.shrinkWidth)
    self._svrName = GUILayout.TextField(self._svrName, GUILayout.expandWidth)
    GUILayout.Label("Addr", GUILayout.shrinkWidth)
    self._addr = GUILayout.TextField(self._addr, GUILayout.expandWidth)
    GUILayout.Label("Port", GUILayout.shrinkWidth)
    self._port = tonumber(GUILayout.TextField(tostring(self._port), GUILayout.expandWidth))
    GUILayout.Label("SvrId",GUILayout.shrinkWidth)
    self._svrId = GUILayout.TextField(self._svrId, GUILayout.expandWidth)
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    if GUILayout.Button("设置为Server") then
        runtimeDebugSettings:SetOverrideServerConfig(self._addr, self._port, self._svrName,self._svrId, "")
        g_Game:RestartGame()
    end
    if GUILayout.Button("恢复默认Server设置") then
        self._addr = string.Empty
        self._port = 0
        self._svrName = string.Empty
        self._svrId = string.Empty
        runtimeDebugSettings:ClearOverrideServerConfig()
        g_Game:RestartGame()
    end
    if GUILayout.Button("请求刷新服务器列表") then
        self:RefreshServerList()
    end
    GUILayout.EndHorizontal()
    GUILayout.BeginHorizontal()
    GUILayout.Label("Filter:", GUILayout.shrinkWidth)
    self._nameFilter = GUILayout.TextField(self._nameFilter, GUILayout.expandWidth)
    if not string.IsNullOrEmpty(self._nameFilter) then
        self._nameLower = string.lower(self._nameFilter)
    else
        self._nameLower = string.Empty
    end
    GUILayout.EndHorizontal()
    self._scrollPos = GUILayout.BeginScrollView(self._scrollPos)
    for _,v in ipairs(self._serverList) do
        if not string.IsNullOrEmpty(self._nameLower) then
            if not string.match(v.nameLow, self._nameLower) then
                goto continue
            end
        end
        if GUILayout.Button(string.format("Name:%s Addr:%s Port:%d ServId:%d", v.name, v.addr, v.port, v.server_id), GUILayout.GetButtonLeftSkin(), GUILayout.expandWidth) then
            self._addr = v.addr
            self._port = v.port
            self._svrName = v.name
            self._svrId = v.server_id
            local gmPage = v.addr_http_cmd or ""
            runtimeDebugSettings:SetOverrideServerConfig(self._addr, self._port, self._svrName,self._svrId, gmPage)
            g_Game:RestartGame()
            break
        end
        ::continue::
    end
    GUILayout.EndScrollView()
end

function GMPageSelectServer:Tick()
    if self._loaded then
        return
    end
    if not (nil == self._webRequestOperation) then
        if self._webRequestOperation.isDone then
            self._loaded = true
            local operation = self._webRequestOperation
            self._webRequestOperation = nil
            self:DecodeServerList(operation)
            operation.webRequest:Dispose()
        end
    end
end

function GMPageSelectServer:DecodeServerList(requestOperation)
    table.clear(self._serverList)
    if nil == requestOperation or nil == requestOperation.webRequest or nil == requestOperation.webRequest.downloadHandler then
        return
    end
    local retJsonText = requestOperation.webRequest.downloadHandler.text
    g_Logger.LogChannel(nil, "DecodeServerList:%s", retJsonText)
    if string.IsNullOrEmpty(retJsonText) then
        return
    end
    local terms = rapidJson.decode(retJsonText);
    if nil == terms then
        return
    end
    local server = terms["server"]
    if nil == server then
        return
    end
    self:DecodeServerListImp(server)
end

function GMPageSelectServer:DecodeServerListImp(server)
    for _,v in pairs(server) do
        table.insert(self._serverList, {name = v["name"], addr = v["addr"], port = v["port"], id = v['id'], nameLow = string.lower(v["name"]),  addr_http_cmd = v['addr_http_cmd'], server_id = v['server_id'], priority = checknumber(v['priority'])})
    end
    table.sort(self._serverList, function(l, r)
        if l.priority ~= r.priority then
            return l.priority > r.priority
        else
            return string.compare(l.name, r.name)
        end
    end)
end

function GMPageSelectServer:RefreshServerList()
    self._loaded = false
    table.clear(self._serverList)
    self._addr = string.Empty
    self._port = 0
    self._svrName = string.Empty
    self._svrId = string.Empty
    local n,a,p,s,i = runtimeDebugSettings:GetOverrideServerConfig()
    if n then
        self._addr = a
        self._port = p
        self._svrName = s
        self._svrId = i
    end
    --self._webRequestOperation = UnityWebRequest.Get("http://10.7.70.51:9898/"):SendWebRequest()
    self._webRequestOperation = UnityWebRequest.Get("http://10.7.70.51/serverlist/"):SendWebRequest()
    --self._webRequestOperation = UnityWebRequest.Get("http://dev.ssr.funplus.io/serverlist"):SendWebRequest()
end

function GMPageSelectServer:SetServerListFromManifest(serverList)
    table.clear(self._serverList)
    self._addr = string.Empty
    self._port = 0
    self._svrName = string.Empty
    self._svrId = string.Empty
    local n,a,p,s,i = runtimeDebugSettings:GetOverrideServerConfig()
    if n then
        self._addr = a
        self._port = p
        self._svrName = s
        self._svrId = i
    end
    self._loaded = true
    self:DecodeServerListImp(serverList)
end

return GMPageSelectServer