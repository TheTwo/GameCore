
---@class BaseParameter
---@field userdata any
---@field msg AbstractRpc
local cls = class('BaseParameter')

function cls:ctor()
    self.userdata = nil
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function cls:Send(lockable, userdata, guaranteeCommit, simpleErrorOverride)
    local ProtocolId = require("ProtocolId")
    if g_Game.ServiceManager.blockMsgSend and
        self.msg.msgId ~= ProtocolId.Login and
        self.msg.msgId ~= ProtocolId.SendClientDataReadyRe then return end

    ---@type UILockData
    local lockableData = {
        fullScreen = false,
        trans = {}
    }
    if lockable then
        if type(lockable) == 'table' then
            table.addrange(lockableData.trans, lockable)
        else
            table.insert(lockableData.trans,lockable)
        end
    end
    g_Game.ServiceManager:Send(self.msg, lockableData, userdata, guaranteeCommit, simpleErrorOverride)
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param userdata any
---@param guaranteeCommit any
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
function cls:SendOnceCallback(lockable, userdata, guaranteeCommit, callback, simpleErrorOverride)
    if callback then
        local msgId = self.GetMsgId()
        local cmd = self
        cmd.__tempWaitCallback = function(isSuccess, rsp)
            g_Game.ServiceManager:RemoveResponseCallback(msgId, self.__tempWaitCallback)
            cmd.__tempWaitCallback = nil
            if callback then
                callback(cmd, isSuccess, rsp)
            end
        end
        g_Game.ServiceManager:AddResponseCallback(self.GetMsgId(), self.__tempWaitCallback)
    end
    self:Send(lockable, userdata, guaranteeCommit, simpleErrorOverride)
end

---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
---@param fullScreenPosInView CS.UnityEngine.Vector2|nil
function cls:SendWithFullScreenLock(userdata, guaranteeCommit, simpleErrorOverride, fullScreenPosInView)
    local LoginParameter = require("LoginParameter")
    if g_Game.ServiceManager.blockMsgSend and self.msg.msgId ~= LoginParameter.GetMsgId() then return end
    
    ---@type UILockData
    local lockableData = {
        fullScreen = true,
        trans = nil,
        fullScreenPosInView = fullScreenPosInView
    }
    g_Game.ServiceManager:Send(self.msg, lockableData, userdata, guaranteeCommit, simpleErrorOverride)
end

---@param userdata any
---@param guaranteeCommit any
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
---@param simpleErrorOverride fun(msgId:number,errorCode:number,jsonTable:table):boolean
---@param fullScreenPosInView CS.UnityEngine.Vector2|nil
function cls:SendWithFullScreenLockAndOnceCallback(userdata, guaranteeCommit, callback, simpleErrorOverride, fullScreenPosInView)
    if callback then
        local msgId = self.GetMsgId()
        local cmd = self
        cmd.__tempWaitCallback = function(isSuccess, rsp)
            g_Game.ServiceManager:RemoveResponseCallback(msgId, self.__tempWaitCallback)
            cmd.__tempWaitCallback = nil
            if callback then
                callback(cmd, isSuccess, rsp)
            end
        end
        g_Game.ServiceManager:AddResponseCallback(self.GetMsgId(), self.__tempWaitCallback)
    end
    self:SendWithFullScreenLock(userdata, guaranteeCommit, simpleErrorOverride, fullScreenPosInView)
end

return cls