local BaseModule = require("BaseModule")
local ProtocolId = require("ProtocolId")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local ArtResourceUtils = require("ArtResourceUtils")
local KingdomMapUtils = require("KingdomMapUtils")
local KingdomScene = require("KingdomScene")
local AllianceBattleType = require("AllianceBattleType")
local FPXSDKBIDefine = require("FPXSDKBIDefine")

---@class ServerPushNoticeModule:BaseModule
---@field new fun():BaseModule
---@field super BaseModule
local ServerPushNoticeModule = class('ServerPushNoticeModule', BaseModule)

function ServerPushNoticeModule:ctor()
    BaseModule.ctor(self)
    self._allowMask = 0
    ---@type table<wrpc.PushNoticeType, fun(data:wrpc.PushNoticeRequest):fun()>
    self.type2Processor = {}
    self.type2Processor[wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleActivated] = Delegate.GetOrCreate(self, self.OnPushAllianceActivityBattleActivied)
    self.type2Processor[wrpc.PushNoticeType.PushNoticeType_AllianceActivityBattleStart] = Delegate.GetOrCreate(self, self.OnPushAllianceActivityBattleStart)
    ---@type {type:wrpc.PushNoticeType,action:fun()}[]
    self._inQueueAction = {}
end

function ServerPushNoticeModule:OnRegister()
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.PushNotice, Delegate.GetOrCreate(self, self.OnServerPushNotice))
end

function ServerPushNoticeModule:OnRemove()
    self._allowMask = 0
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.PushNotice, Delegate.GetOrCreate(self, self.OnServerPushNotice))
end

---@param type wrpc.PushNoticeType
---@return boolean
function ServerPushNoticeModule:IsAllow(type)
    local flag = 1 << type
    local allow = flag & self._allowMask
    return allow ~= 0
end

---@param type wrpc.PushNoticeType
function ServerPushNoticeModule:AddAllowMask(type)
    local flag = 1 << type
    local oldValue = self._allowMask
    self._allowMask = self._allowMask | flag
    if oldValue ~= self._allowMask then
        self:TriggerQueueCheck()
        return true
    end
    return false
end

---@param type wrpc.PushNoticeType
function ServerPushNoticeModule:RemoveAllowMask(type)
    local flag = ~(1 << type)
    local oldValue = self._allowMask
    self._allowMask = self._allowMask & flag
    if oldValue ~= self._allowMask then
        self:TriggerQueueCheck()
        return true
    end
    return false
end

function ServerPushNoticeModule:TriggerQueueCheck()
    local toRemoveIndex = {}
    for i, v in ipairs(self._inQueueAction) do
        if self:IsAllow(v.type) then
            table.insert(toRemoveIndex, i)
            v.action()
        end
    end
    for i = #toRemoveIndex, 1, -1 do
        table.remove(self._inQueueAction, toRemoveIndex[i])
    end
end

function ServerPushNoticeModule:AddToQueue(noticeType, action)
    if self:IsAllow(noticeType) then
        action()
        return
    end
    table.insert(self._inQueueAction, {type=noticeType, action=action})
end

---@param isSuccess boolean
---@param data wrpc.PushNoticeRequest
function ServerPushNoticeModule:OnServerPushNotice(isSuccess, data)
    if isSuccess and data then
        local processor =  self.type2Processor[data.Type]
        if processor then
            local action = processor(data)
            if action then
                self:AddToQueue(data.Type, action)
            end
        end
    end
end

---@param data wrpc.PushNoticeRequest
---@return fun()
function ServerPushNoticeModule:OnPushAllianceActivityBattleActivied(data)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return nil
    end
    -- if ModuleRefer.AllianceModule:IsAllianceLeader() then
    --     return nil
    -- end
    local activityBattleId = data.Param.ActivityBattleId
    local battleData = ModuleRefer.AllianceModule:GetAllianceActivityBattleData(activityBattleId)
    if not battleData then
        return
    end
    local cfgId = battleData.CfgId
    return function()
        if not ServerPushNoticeModule.CheckCaneEnterActivityBattle() then
            return
        end
        if not ModuleRefer.AllianceModule:GetAllianceActivityBattleData(activityBattleId) then
            return
        end
        if not ModuleRefer.AllianceModule:CheckBehemothUnlock(false) then
            return
        end
        local config = ConfigRefer.AllianceBattle:Find(cfgId)
        if not config then
            return
        end
        if config:Type() == AllianceBattleType.BehemothBattle then
            ---@type CommonNotifyPopupMediatorParameter
            local noticeData = {}
            noticeData.btnText = I18N.Get("alliance_battle_button3")
            noticeData.title = I18N.GetWithParams("alliance_battle_toast3", I18N.Get(config:LangKey()))
            noticeData.textBlood = "100%"
            noticeData.icon = ArtResourceUtils.GetUIItem(config:BossIcon())
            noticeData.context = activityBattleId
            noticeData.acceptAction = function(battleId)

                local keyMap = FPXSDKBIDefine.ExtraKey.activity_banner
                local extraData = {}
                extraData[keyMap.alliance_id] = ModuleRefer.AllianceModule:GetAllianceId()
                ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.activity_banner, extraData)

                -----@type ActivityCenterOpenParam
                local tabId = ConfigRefer.AllianceConsts:BehemothActiviyChallengeTab()
                ModuleRefer.ActivityCenterModule:GotoActivity(tabId)
            end
            ModuleRefer.ToastModule:CustomeAddNoticeToast(noticeData)
        end
    end
end

---@param data wrpc.PushNoticeRequest
---@return fun()
function ServerPushNoticeModule:OnPushAllianceActivityBattleStart(data)
    if not ModuleRefer.AllianceModule:IsInAlliance() then
        return nil
    end
    if ModuleRefer.AllianceModule:IsAllianceLeader() then
        return nil
    end
    local activityBattleId = data.Param.ActivityBattleId
    local battleData = ModuleRefer.AllianceModule:GetAllianceActivityBattleData(activityBattleId)
    if not battleData then
        return
    end
    local cfgId = battleData.CfgId
    return function()
        if not ServerPushNoticeModule.CheckCaneEnterActivityBattle() then
            return
        end
        if not ModuleRefer.AllianceModule:GetAllianceActivityBattleData(activityBattleId) then
            return
        end
        if not ModuleRefer.AllianceModule:CheckBehemothUnlock(false) then
            return
        end
        local config = ConfigRefer.AllianceBattle:Find(cfgId)
        if not config then
            return
        end
        if config:Type() == AllianceBattleType.BehemothBattle then
            ---@type CommonNotifyPopupMediatorParameter
            local noticeData = {}
            noticeData.btnText = I18N.Get("alliance_battle_button3")
            noticeData.title = I18N.GetWithParams("alliance_battle_toast4", I18N.Get(config:LangKey()))
            noticeData.textBlood = "100%"
            noticeData.icon = ArtResourceUtils.GetUIItem(config:BossIcon())
            noticeData.context = activityBattleId
            noticeData.acceptAction = function(battleId)

                local keyMap = FPXSDKBIDefine.ExtraKey.activity_banner
                local extraData = {}
                extraData[keyMap.alliance_id] = ModuleRefer.AllianceModule:GetAllianceId()
                ModuleRefer.FPXSDKModule:TrackCustomBILog(FPXSDKBIDefine.EventName.activity_banner, extraData)

                local tabId = ConfigRefer.AllianceConsts:BehemothActiviyChallengeTab()
                ModuleRefer.ActivityCenterModule:GotoActivity(tabId)
            end
            ModuleRefer.ToastModule:CustomeAddNoticeToast(noticeData)
        end
    end
end

---@return boolean
function ServerPushNoticeModule.CheckCaneEnterActivityBattle()
    local scene = g_Game.SceneManager.current
    if not scene or scene:GetName() ~= KingdomScene.Name then
        return false
    end
    return true
end

return ServerPushNoticeModule