local BaseModule = require('BaseModule')
local DBEntityType = require("DBEntityType")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local ProtectDefine = require("ProtectDefine")
local protectionType = require("ProtectionType")
local UseItemParameter = require('UseItemParameter')

---@class ProtectModule : BaseModule
local ProtectModule = class('ProtectModule', BaseModule)

function ProtectModule:ctor()
end

function ProtectModule:OnRegister()
    self:InitStatus()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.MapStates.StateWrapper.MsgPath, Delegate.GetOrCreate(self,self.OnChangeCastleState))
end

function ProtectModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.MapStates.StateWrapper.MsgPath, Delegate.GetOrCreate(self,self.OnChangeCastleState))
end

function ProtectModule:InitStatus()
    local stateWrapper = ModuleRefer.PlayerModule:GetCastle().MapStates.StateWrapper
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local protectConfig = ConfigRefer.Protection:Find(stateWrapper.ProtectionConfigId)
    local newbieProtect = false
    if protectConfig then
        newbieProtect = protectConfig:Type() == protectionType.NewbieProtection
    end
    local isNewbieStatus = stateWrapper.ProtectionExpireTime > curTime and newbieProtect
    local isItemProtectStatus = stateWrapper.ProtectionExpireTime > curTime and not newbieProtect
    local isWarStatus = stateWrapper.WarExpireTime > curTime
    if isNewbieStatus then
        self.status = ProtectDefine.STATUS_TYPE.Newbie_Protect
    elseif isItemProtectStatus then
        self.status = ProtectDefine.STATUS_TYPE.Item_Protect
    elseif isWarStatus then
        self.status = ProtectDefine.STATUS_TYPE.War
    else
        self.status = ProtectDefine.STATUS_TYPE.Normal
    end
end

function ProtectModule:GetProtectStatusByEntity(entity)
    if not entity then
        return
    end
    local stateWrapper = entity.MapStates.StateWrapper
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local protectConfig = ConfigRefer.Protection:Find(stateWrapper.ProtectionConfigId)
    local newbieProtect = false
    if protectConfig then
        newbieProtect = protectConfig:Type() == protectionType.NewbieProtection
    end
    local isNewbieStatus = stateWrapper.ProtectionExpireTime > curTime and newbieProtect
    local isItemProtectStatus = stateWrapper.ProtectionExpireTime > curTime and not newbieProtect
    local isWarStatus = stateWrapper.WarExpireTime > curTime
    if isNewbieStatus then
        return ProtectDefine.STATUS_TYPE.Newbie_Protect
    end

    if isItemProtectStatus then
        return ProtectDefine.STATUS_TYPE.Item_Protect
    end

    if isWarStatus then
        return ProtectDefine.STATUS_TYPE.War
    end
end

function ProtectModule:GetCurProtectStatus()
    return self.status
end

function ProtectModule:OnChangeCastleState(entity, _)
    if not entity then
        return
    end
    self.status = self:GetProtectStatusByEntity(entity)
end

function ProtectModule:OnUseProtectItem(uid)
    if self.status == ProtectDefine.STATUS_TYPE.Newbie_Protect or 
    self.status == ProtectDefine.STATUS_TYPE.Item_Protect then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("protect_toast_under_protection"))
        return false
    end
    if self.status == ProtectDefine.STATUS_TYPE.War then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("protect_toast_war_state"))
        return false
    end
    local msg = UseItemParameter.new()
    msg.args.ComponentID = uid
    msg.args.Num = 1
    msg:Send()
end

function ProtectModule:GetProtectStatusIconName(status)
    local spriteName = string.empty
    if status == ProtectDefine.STATUS_TYPE.Newbie_Protect then
        spriteName = "sp_hud_icon_status_defence"
    elseif status == ProtectDefine.STATUS_TYPE.Item_Protect then
        spriteName = "sp_hud_icon_status_shield"
    elseif status == ProtectDefine.STATUS_TYPE.War then
        spriteName = "sp_hud_icon_status_battle"
    end
    return spriteName
end

--保护时长
---@return number seconds
function ProtectModule:GetProtectDuration()
    local stateWrapper = ModuleRefer.PlayerModule:GetCastle().MapStates.StateWrapper
    local configID = stateWrapper.ProtectionConfigId
    local protectConfig = ConfigRefer.Protection:Find(configID)
    if not protectConfig then
        return 0
    end
    local Utils = require("Utils")
    return Utils.ParseDurationToSecond(protectConfig:Duration())
end

return ProtectModule