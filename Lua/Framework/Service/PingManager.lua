local BaseManager = require("BaseManager")
---@class PingManager:BaseManager
---@field new fun():PingManager
local PingManager = class("PingManager", BaseManager)
local Delegate = require("Delegate")
local SIGNAL_WAIT = -2

function PingManager:ctor()
    self.manager = watcher.PingManager.Get()
    self.waitingList = {}
    self.resultList = {}
    self.active = false
end

function PingManager:Reset()
    self.manager = nil
    self.waitingList = nil
    self.resultList = nil
    if self.active then
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    end
    self.active = false
end

function PingManager:OnTick()
    for host, v in pairs(self.waitingList) do
        local time = self.manager:GetPingResult(v.id)
        if time > SIGNAL_WAIT then
            g_Logger.LogChannel("PingManager", "Ping [%s] got result %d", host, time)
            self.resultList[host] = {time = time, port = v.port}
            self.waitingList[host] = nil
        end
    end

    if next(self.waitingList) == nil then
        self.active = false
        g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
        if self.onFinished then
            self.onFinished(self.manifest)
            self.onFinished = nil
            self.manifest = nil
        end
    end
end

---@private
function PingManager:StartPing(host, port)
    local id = self.manager:StartPingTask(host)
    self.waitingList[host] = {id = id, port = port}
    
    if not self.active then
        g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
        self.active = true
    end
end

---@param manifest {code:number, svrname:string, svrid:number, watcher:{stargate:{port:string, host:string}}, gates:{name:string, domain:string, addr:string}[]}
function PingManager:StartPingList(manifest, onFinished)
    if self.active then
        g_Logger.Error("Last Work Is Active")
        return
    end

    self.manifest = manifest
    self.onFinished = onFinished
    if type(self.manifest.gates) == "table" then
        for i, gate in ipairs(self.manifest.gates) do
            local startIdx, endIdx, host, port = string.find(gate.addr, ("([%d%.]+):(%d+)"))
            g_Logger.LogChannel("PingManager", "StartPing host : %s:%s", host, port)
            if host ~= nil then
                self:StartPing(host, port)
            else
                g_Logger.ErrorChannel("PingManager", "StartPing host is nil, info : %s", FormatTable(gate))
            end
        end
    else
        if self.onFinished then
            self.onFinished(self.manifest)
            self.onFinished = nil
            self.manifest = nil
        end
    end
end

function PingManager:GetFastestIp()
    local fastest = 1 << 31
    local ip = nil
    for host, v in pairs(self.resultList) do
        if v.time < 0 then goto continue end

        if v.time < fastest then
            fastest = v.time
            ip = host
        end
        ::continue::
    end

    if ip then
        return ip, self.resultList[ip].port
    end
    return nil
end

return PingManager