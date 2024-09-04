local UIMediatorNames = require('UIMediatorNames')
local BaseModule = require("BaseModule")
local ProtocolId = require("ProtocolId")
local Delegate = require("Delegate")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require('ModuleRefer')
local EventConst = require("EventConst")
local ToastFuncType = require("ToastFuncType")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
local GuideUtils = require("GuideUtils")
local KingdomMapUtils = require("KingdomMapUtils")
local SEEnvironment = require("SEEnvironment").Instance()
local ServiceDynamicDescHelper = require("ServiceDynamicDescHelper")
local DBEntityPath = require("DBEntityPath")
local UIAsyncDataProvider = require("UIAsyncDataProvider")
local SimpleToastHolder = require("SimpleToastHolder")

---@class ToastModule : BaseModule
local ToastModule = class('ToastModule', BaseModule)

local MaxSimpleToastCount = 3

function ToastModule:ctor()
    self._currentSimpleToastRuntimeId = -1
    self._storyPlayingBlockToast = false
    self.blockToast = false
    ---@type SimpleToastHolder[]
    self._currentSimpleToasts = {}
end

function ToastModule:OnRegister()
    self.cacheToast = {}
    self.cacheMarqueeToast = {}
    local playerData = ModuleRefer.PlayerModule:GetPlayer()
    self.recordPower = playerData.PlayerWrapper2.PlayerPower.TotalPower
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.CommonToast, Delegate.GetOrCreate(self, self.OnServerToastResponse))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.Marquee, Delegate.GetOrCreate(self, self.OnServerMarqueeToast))
    g_Game.ServiceManager:AddResponseCallback(ProtocolId.ToastNotice, Delegate.GetOrCreate(self, self.OnServerNoticeToast))
    g_Game.EventManager:AddListener(EventConst.CITY_SET_ACTIVE, Delegate.GetOrCreate(self, self.TriggerCacheToast))
    g_Game.EventManager:AddListener(EventConst.ENTER_KINGDOM_MAP_START, Delegate.GetOrCreate(self, self.TriggerCacheToast))
    g_Game.EventManager:AddListener(EventConst.SE_START_LOADING, Delegate.GetOrCreate(self, self.BlockToast))
    g_Game.EventManager:RemoveListener(EventConst.SE_EXIT,Delegate.GetOrCreate(self,self.IngoreBlockToast))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPower.TotalPower.MsgPath, Delegate.GetOrCreate(self,self.OnPlayerInfoChanged))
    g_Game.EventManager:AddListener(EventConst.LEAVE_KINGDOM_MAP_START, Delegate.GetOrCreate(self, self.OnLeaveKingdomScene))
end

function ToastModule:OnRemove()
    self.cacheToast = {}
    self.cacheMarqueeToast = {}
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.CommonToast, Delegate.GetOrCreate(self, self.OnServerToastResponse))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.Marquee, Delegate.GetOrCreate(self, self.OnServerMarqueeToast))
    g_Game.ServiceManager:RemoveResponseCallback(ProtocolId.ToastNotice, Delegate.GetOrCreate(self, self.OnServerNoticeToast))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SET_ACTIVE, Delegate.GetOrCreate(self, self.TriggerCacheToast))
    g_Game.EventManager:RemoveListener(EventConst.ENTER_KINGDOM_MAP_START, Delegate.GetOrCreate(self, self.TriggerCacheToast))
    g_Game.EventManager:RemoveListener(EventConst.SE_START_LOADING, Delegate.GetOrCreate(self, self.BlockToast))
    g_Game.EventManager:RemoveListener(EventConst.SE_EXIT,Delegate.GetOrCreate(self,self.IngoreBlockToast))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPower.TotalPower.MsgPath, Delegate.GetOrCreate(self,self.OnPlayerInfoChanged))
    g_Game.EventManager:RemoveListener(EventConst.LEAVE_KINGDOM_MAP_START, Delegate.GetOrCreate(self, self.OnLeaveKingdomScene))
end

function ToastModule:IngoreBlockToast()
    self.blockToast = false
end

function ToastModule:BlockToast()
    self.blockToast = true
end

function ToastModule:SetStoryPlayingBlockToast(isBlocked)
    if self._storyPlayingBlockToast == isBlocked then
        return
    end
    self._storyPlayingBlockToast = isBlocked
    if isBlocked then
        self:CloseSimpleToast()
        self:ClostTopToast()
        g_Game.UIManager:CloseAllByName(UIMediatorNames.JumpToastMediator)
        g_Game.UIManager:CloseAllByName(UIMediatorNames.RunToastMediator)
        g_Game.UIManager:CloseAllByName(UIMediatorNames.WorldEventDetailMediator)
        g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonNotifyPopupMediator)
        g_Game.UIManager:CloseAllByName(UIMediatorNames.WorldConquerFailTipMediator)
    end
end

function ToastModule:OnServerToastResponse(isSuccess, data)
    if isSuccess and data then
        if data.Params and next(data.Params) then
            self:AddSimpleToast(I18N.GetWithParamList(data.Key, data.Params))
        else
            self:AddSimpleToast(I18N.Get(data.Key))
        end
    end
end

function ToastModule:AddSimpleToast(content)
    if self._storyPlayingBlockToast or self:IsCountdownToastShow() then
        return
    end
    g_Game.UIManager:Open(UIMediatorNames.SimpleToastMediator, {msg = content}, function(mediator)
        local holder = SimpleToastHolder.new(mediator)
        for i, toast in ipairs(self._currentSimpleToasts) do
            if not toast:IsAlive() then
                toast:Release()
                table.remove(self._currentSimpleToasts, i)
            end
        end
        for _, toast in ipairs(self._currentSimpleToasts) do
            toast:MoveUp()
        end
        if #self._currentSimpleToasts >= MaxSimpleToastCount then
            self._currentSimpleToasts[1]:Release()
            table.remove(self._currentSimpleToasts, 1)
        end
        self._currentSimpleToasts[#self._currentSimpleToasts + 1] = holder
    end, true)
end

function ToastModule:CloseSimpleToast()
    if self._currentSimpleToastRuntimeId > 0 then
        g_Game.UIManager:Close(self._currentSimpleToastRuntimeId)
        self._currentSimpleToastRuntimeId = -1
    end
end

---@param param TopToastParameter
function ToastModule:AddTopToast(param)
    self:ClostTopToast()
    if self._storyPlayingBlockToast or self:IsCountdownToastShow() then
        return
    end
    self._currentTopToastRuntimeId = g_Game.UIManager:Open(UIMediatorNames.TopToastMediator, param)
end

function ToastModule:ClostTopToast()
    if self._currentTopToastRuntimeId and self._currentTopToastRuntimeId > 0 then
        g_Game.UIManager:Close(self._currentTopToastRuntimeId)
        self._currentTopToastRuntimeId = -1
    end
end

---@param param TextToastMediatorParameter
---@return number @runtimeId
function ToastModule:ShowTextToast(param)
    return g_Game.UIManager:Open(UIMediatorNames.TextToastMediator, param)
end

---@param content string
---@param clickTrans CS.UnityEngine.RectTransform|nil
---@return number @runtimeId
function ToastModule:SimpleShowTextToastTip(content, clickTrans)
    ---@type TextToastMediatorParameter
    local param = {}
    param.content = content
    param.clickTransform = clickTrans
    return g_Game.UIManager:Open(UIMediatorNames.TextToastMediator, param)
end

---@param param WorldEventDetailMediatorParameter
---@return number @runtimeId
function ToastModule:ShowWorldEventDetail(param)
    return g_Game.UIManager:Open(UIMediatorNames.WorldEventDetailMediator, param)
end
function ToastModule:CancelTextToast(uiRuntimeId)
    if uiRuntimeId then
        g_Game.UIManager:Close(uiRuntimeId)
    end
end

---@param content string
---@param imageId number|string|nil
---@param colorStr string @hex code
function ToastModule:AddJumpToast(content, imageId, colorStr)
    if self._storyPlayingBlockToast or self:IsCountdownToastShow() then
        return
    end
    if not g_Game.UIManager:IsOpenedByName(UIMediatorNames.JumpToastMediator) then
        g_Game.UIManager:Open(UIMediatorNames.JumpToastMediator, {content = content, imageId = imageId, color = colorStr})
    else
        g_Game.EventManager:TriggerEvent(EventConst.UI_EVENT_JUMP_TOAST_NEW, content, imageId, colorStr)
    end
end

---@param data wrpc.ToastNoticeRequest
function ToastModule:OnServerMarqueeToast(isSuccess, data)
    local isUnLock = ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(NewFunctionUnlockIdDefine.RunToast)
    if not isUnLock then
        return
    end
    if self._storyPlayingBlockToast or self:IsCountdownToastShow() then
        return
    end
    if self.blockToast then
        self.cacheMarqueeToast[#self.cacheMarqueeToast + 1] = {isSuccess = isSuccess, data = data}
        return
    end
    if isSuccess and data then
        local configId = data.ConfigId
        local toastCfg = ConfigRefer.Toast:Find(configId)
        local content = data.Content
        local result = ServiceDynamicDescHelper.ParseWithI18N(toastCfg:Content(), toastCfg:ContentDescLength(), toastCfg, toastCfg.ContentDesc
        , content.StringParams
        , content.IntParams
        , content.FloatParams
        , content.ConfigParams)
        if not g_Game.UIManager:IsOpenedByName(UIMediatorNames.RunToastMediator) then
            g_Game.UIManager:Open(UIMediatorNames.RunToastMediator, {content = result, configId = configId})
        else
            g_Game.EventManager:TriggerEvent(EventConst.UI_EVENT_RUN_TOAST_NEW, {content = result, configId = configId})
        end
    end
end

function ToastModule:TriggerCacheMarqueeToast()
    self.blockToast = false
    for _, data in ipairs(self.cacheMarqueeToast) do
        self:OnServerMarqueeToast(data.isSuccess, data.data)
    end
    self.cacheMarqueeToast = {}
end

function ToastModule:TriggerCacheToast()
    self.blockToast = false
    for _, data in ipairs(self.cacheToast) do
        self:OnServerNoticeToast(data.isSuccess, data.data)
    end
    self.cacheToast = {}
end

---@param data wrpc.ToastNoticeRequest
function ToastModule:OnServerNoticeToast(isSuccess, data)
    if SEEnvironment or self.blockToast then
        self.cacheToast[#self.cacheToast + 1] = {isSuccess = isSuccess, data = data}
        return
    end
    if self._storyPlayingBlockToast or self:IsCountdownToastShow() or self:IsInCityExploreMode() then
        return
    end
    if isSuccess and data then
        local configId = data.ConfigId
        local toastCfg = ConfigRefer.Toast:Find(configId)
        if toastCfg:FuncType() == ToastFuncType.ExpeditionNotice and not KingdomMapUtils.IsMapState() then
            return
        end
        local content = data.Title
        local title = ServiceDynamicDescHelper.ParseWithI18N(toastCfg:Title(), toastCfg:TitleDescLength(), toastCfg, toastCfg.TitleDesc
        , content.StringParams
        , content.IntParams
        , content.FloatParams
        , content.ConfigParams)

        content = data.Content
        local result = ServiceDynamicDescHelper.ParseWithI18N(toastCfg:Content(), toastCfg:ContentDescLength(), toastCfg, toastCfg.ContentDesc
        , content.StringParams
        , content.IntParams
        , content.FloatParams
        , content.ConfigParams)

        ---@type CommonNotifyPopupMediatorParameter
        local noticeData = {}
        noticeData.btnText = I18N.Get("goto")
        noticeData.title = title
        noticeData.textBlood = ""
        noticeData.icon = toastCfg:Icon()
        noticeData.content = result
        noticeData.duration = toastCfg:Duration()
        noticeData.funcType = toastCfg:FuncType()
        if toastCfg:Duration() and toastCfg:Duration() > 0 then
            noticeData.endTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor() + toastCfg:Duration()
        end
        noticeData.fromServer = true
        noticeData.acceptAction = function()
            if data.Position and not (data.Position.X == 0 and data.Position.Y == 0 and data.Position.Z == 0) then
                local triggerFunc = function()
                    local myCityPosition = CS.Grid.MapUtils.CalculateCoordToTerrainPosition(data.Position.X, data.Position.Y, KingdomMapUtils.GetMapSystem())
                    KingdomMapUtils.MoveAndZoomCamera(myCityPosition, KingdomMapUtils.GetCameraLodData().mapCameraEnterSize)
                end
                if KingdomMapUtils.IsCityState() then
                    KingdomMapUtils.GetKingdomScene():LeaveCity(function()
                        triggerFunc()
                    end)
                else
                    triggerFunc()
                end
            else
                if toastCfg:TriggerGuide() > 0 then
                    GuideUtils.GotoByGuide(toastCfg:TriggerGuide(), false)
                end
            end
        end
        if not g_Game.UIManager:IsOpenedByName(UIMediatorNames.CommonNotifyPopupMediator) then
            g_Game.UIManager:Open(UIMediatorNames.CommonNotifyPopupMediator, noticeData)
        else
            g_Game.EventManager:TriggerEvent(EventConst.UI_EVENT_NOTIFY_POPUP_NEW, noticeData)
        end
    end
end

---@param data CommonNotifyPopupMediatorParameter
function ToastModule:CustomeAddNoticeToast(data)
    if self._storyPlayingBlockToast or self:IsCountdownToastShow() or self:IsInCityExploreMode() then
        return
    end
    if not g_Game.UIManager:IsOpenedByName(UIMediatorNames.CommonNotifyPopupMediator) then
        g_Game.UIManager:Open(UIMediatorNames.CommonNotifyPopupMediator, data)
    else
        g_Game.EventManager:TriggerEvent(EventConst.UI_EVENT_NOTIFY_POPUP_NEW, data)
    end
end

---@param data WorldConquerFailTipMediatorParameter
function ToastModule:AddWorldConquerFailTip(data)
    if self._storyPlayingBlockToast or self:IsCountdownToastShow() or self:IsInCityExploreMode() then
        return
    end
    if not g_Game.UIManager:IsOpenedByName(UIMediatorNames.WorldConquerFailTipMediator) then
        g_Game.UIManager:Open(UIMediatorNames.WorldConquerFailTipMediator, data)
    else
        g_Game.EventManager:TriggerEvent(EventConst.UI_WORLD_CONQUER_FAIL_TIP_NEW, data)
    end
end

function ToastModule:BlockPower()
    self.blockPower = true
    local playerData = ModuleRefer.PlayerModule:GetPlayer()
    self.blockPowerNum = playerData.PlayerWrapper2.PlayerPower.TotalPower
end

function ToastModule:IngoreBlockPower()
    self.blockPower = false
    local playerData = ModuleRefer.PlayerModule:GetPlayer()
    local curPower = playerData.PlayerWrapper2.PlayerPower.TotalPower
    if self.blockPowerNum and self.blockPowerNum < curPower then
         ---@type UIAsyncDataProvider
         local provider = UIAsyncDataProvider.new()
         local name = UIMediatorNames.PowerToastMediator
         local param = {power = curPower - self.blockPowerNum}
         local check = UIAsyncDataProvider.CheckTypes.CheckAll ~ UIAsyncDataProvider.CheckTypes.DoNotShowInGuidance
         provider:SetOtherMediatorCheckType(0)
         provider:AddOtherMediatorBlackList(UIMediatorNames.PowerToastMediator)
         provider:AddOtherMediatorBlackList(UIMediatorNames.LoadingPageMediator)
         provider:AddOtherMediatorBlackList(UIMediatorNames.PetCaptureMediator)
         provider:Init(name, nil, check, nil, false, param)
         g_Game.UIAsyncManager:AddAsyncMediator(provider)
    end
end

function ToastModule:OnPlayerInfoChanged()
    if self.blockPower then
        return
    end
    local playerData = ModuleRefer.PlayerModule:GetPlayer()
    local curPower = playerData.PlayerWrapper2.PlayerPower.TotalPower
    if self.recordPower then
        if self.recordPower > 0 and curPower > self.recordPower then
            -- if not g_Game.UIManager:IsOpenedByName(UIMediatorNames.PowerToastMediator) then
            --     g_Game.UIManager:Open(UIMediatorNames.PowerToastMediator, {power = curPower - self.recordPower})
            -- else
            --     g_Game.EventManager:TriggerEvent(EventConst.UI_POWER_TOAST_REFRESH, {power = curPower - self.recordPower})
            -- end
            ---@type UIAsyncDataProvider
            local provider = UIAsyncDataProvider.new()
            local name = UIMediatorNames.PowerToastMediator
            local param = {power = curPower - self.recordPower}
            local check = UIAsyncDataProvider.CheckTypes.DoNotShowInGVE | UIAsyncDataProvider.CheckTypes.DoNotShowInSE
            | UIAsyncDataProvider.CheckTypes.DoNotShowOnOtherMediator
            provider:SetOtherMediatorCheckType(0)
            provider:AddOtherMediatorBlackList(UIMediatorNames.PowerToastMediator)
            provider:AddOtherMediatorBlackList(UIMediatorNames.LoadingPageMediator)
            provider:AddOtherMediatorBlackList(UIMediatorNames.PetCaptureMediator)
            provider:Init(name, nil, check, nil, false, param)
            g_Game.UIAsyncManager:AddAsyncMediator(provider)
        elseif curPower < self.recordPower then

        end
    end
    self.recordPower = curPower
end

function ToastModule:OnLeaveKingdomScene()
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CountdownToastMediator)
end

function ToastModule:IsCountdownToastShow()
    return g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.CountdownToastMediator) ~= nil
end

function ToastModule:IsInCityExploreMode()
    local city = ModuleRefer.CityModule:GetMyCity()
    if city then
        return city:IsInSingleSeExplorerMode() or city:IsInSeBattleMode() or city:IsInRecoverZoneEffectMode()
    end
    return false
end

---@param parameter CountdownToastMediatorParamter
function ToastModule:ShowCountdownToast(parameter)
    self:CloseSimpleToast()
    self:ClostTopToast()
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CountdownToastMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.JumpToastMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.RunToastMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.WorldEventDetailMediator)
    g_Game.UIManager:CloseAllByName(UIMediatorNames.CommonNotifyPopupMediator)

    g_Game.UIManager:Open(UIMediatorNames.CountdownToastMediator, parameter)
end

return ToastModule
