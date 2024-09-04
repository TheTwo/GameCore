local ProtocolId = require('ProtocolId')
local Delegate = require('Delegate')
local BaseModule = require('BaseModule')
local hotfixLoadString
if _VERSION == "Lua 5.1" then
    hotfixLoadString = loadstring
else
    hotfixLoadString = load
end

---@class HotfixModule : BaseModule
local HotfixModule = class('HotfixModule', BaseModule)

function HotfixModule:ctor()

end

function HotfixModule:OnRegister()
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushClientHotFix, Delegate.GetOrCreate(self, self.DoHotfix))
end

function HotfixModule:OnRemove()
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushClientHotFix, Delegate.GetOrCreate(self, self.DoHotfix))
end

function HotfixModule:DoHotfix(success, fixCodeStr)
    local hotfixCode = hotfixLoadString(fixCodeStr.Data)
    if hotfixCode then
        local status, errorInfo = xpcall(hotfixCode, debug.traceback)
        if not status then
            g_Logger.Error(errorInfo)
        end
    end
end

return HotfixModule