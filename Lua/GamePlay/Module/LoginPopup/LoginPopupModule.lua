local BaseModule = require('BaseModule')
local EventConst = require('EventConst')
local Delegate = require("Delegate")
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local UIAsyncDataProvider = require('UIAsyncDataProvider')
local PopUpWindomParameter = require('PopUpWindomParameter')
local DBEntityPath = require('DBEntityPath')
local ConfigRefer = require('ConfigRefer')
local UIManager = require('UIManager')
local ClientDataKeys = require('ClientDataKeys')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local KingdomMapUtils = require("KingdomMapUtils")
local SceneType = require("SceneType")
local HUDMapFunctionComponent = require("HUDMapFunctionComponent")
local Utils = require("Utils")

--- @class LoginPopupModule : BaseModule
local LoginPopupModule = class('LoginPopupModule', BaseModule)

local SHOW_NUM = {
    MORE = 3,
    LESS = 1,
}

LoginPopupModule.SHOW_NUM = SHOW_NUM

local POPUP_TIMING_MASK = {
    LOGIN_ENTER_CITY = 1,
    GAME_ENTER_CITY = 1 << 1,
}

local MAX_POPUP_NUM = {
    [POPUP_TIMING_MASK.LOGIN_ENTER_CITY] = SHOW_NUM.MORE,
    [POPUP_TIMING_MASK.GAME_ENTER_CITY] = SHOW_NUM.LESS,
}

function LoginPopupModule:ctor()
end

function LoginPopupModule:OnRegister()
    self._enterCityCount = 0

    ---@type table<number, string>
    self.mediatorNames = self:GetAllPopupMediatorNames()

    ---@type table<string, table<number, number>>
    self.popIdsEachMediator = {}

    ---@type table<number, boolean>
    self.popsOpenStatusCache = {}

    ---@type table<string, number>
    self.asyncHandleIdsEachMediator = {}

    ---@type table<number, number>
    self.popCountEachTiming = {}

    ---@type table<number, number>
    self.recycleMediatorList = {}

    self:AddBeatFlyPoppup()
    self:UpdateData()
    self:AddPopup()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.Window.MsgPath,Delegate.GetOrCreate(self,self.OnPopupListChange))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.BasicInfo.LastBeDefeatedTime.MsgPath, Delegate.GetOrCreate(self,self.OnBeatFly))
    g_Game.EventManager:AddListener(EventConst.CITY_SET_ACTIVE, Delegate.GetOrCreate(self, self.OnEnterCity))
end

function LoginPopupModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.Window.MsgPath,Delegate.GetOrCreate(self,self.OnPopupListChange))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.BasicInfo.LastBeDefeatedTime.MsgPath, Delegate.GetOrCreate(self,self.OnBeatFly))
    g_Game.EventManager:RemoveListener(EventConst.CITY_SET_ACTIVE, Delegate.GetOrCreate(self, self.OnEnterCity))
end

--- 数据更新 ---

function LoginPopupModule:UpdateData()
    self:GetPopupList()
    self:UpdatePopsOpenStatusCache()
    self:UpdatePopIdsEachMediator()
end

function LoginPopupModule:UpdatePopsOpenStatusCache()
    for _, pop in ConfigRefer.PopUpWindow:ipairs() do
        local popId = pop:Id()
        self.popsOpenStatusCache[popId] = false
    end
    for _, popId in ipairs(self._popList1) do
        self.popsOpenStatusCache[popId] = true
    end
    for _, popId in ipairs(self._popList2) do
        self.popsOpenStatusCache[popId] = true
    end
end

function LoginPopupModule:UpdatePopIdsEachMediator()
    for _, mediatorName in ipairs(self.mediatorNames) do
        self.popIdsEachMediator[mediatorName] = {}
    end
    for popId, isOpen in pairs(self.popsOpenStatusCache) do
        if isOpen then
            local pop = ConfigRefer.PopUpWindow:Find(popId)
            if pop == nil or Utils.IsNullOrEmpty(pop:MediatorName()) then goto continue end

            local mediatorName = pop:MediatorName()
            if mediatorName and mediatorName ~= '' and self.popIdsEachMediator[mediatorName] then
                table.insert(self.popIdsEachMediator[mediatorName], popId)
            end
            ::continue::
        end
    end
end

---@private
function LoginPopupModule:GetPopupList()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    self._popList1 = player.PlayerWrapper2.Window.List1
    self._popList2 = player.PlayerWrapper2.Window.List2
end

--- end of 数据更新 ---

--- Getters ---

---@private
function LoginPopupModule:GetAllPopupMediatorNames()
    local mediatorNames = {}
    for _, pop in ConfigRefer.PopUpWindow:ipairs() do
        local mediatorName = pop:MediatorName()
        if mediatorName and mediatorName ~= '' then
            if not UIMediatorNames[mediatorName] then
                g_Logger.Error('The mediator name %s is not exist, please check config.', mediatorName)
                goto continue
            end
            table.insert(mediatorNames, mediatorName)
        end
        ::continue::
    end
    return mediatorNames
end

---@private
---@param isGetAll boolean
function LoginPopupModule:GetPopIds(isGetAll)
    local isLogin = self:IsLogin()
    local popList = self._popList1
    if #popList == 0 then
        popList = self._popList2
    end

    if isGetAll then
        return popList
    end

    local showNum = self.SHOW_NUM.LESS
    if isLogin then
        showNum = self.SHOW_NUM.MORE
    end

    local popIds = {}
    for i = 1, showNum do
        local popId = popList[i]
        if popId then
            table.insert(popIds, popId)
        end
    end
    return popIds
end

---@public
function LoginPopupModule:GetAllAvailablePopIdsForPayGroups()
    local popIds = self:GetPopIds(true)
    local ret = {}
    for _, pop in ConfigRefer.PopUpWindow:ipairs() do
        local popId = pop:Id()
        local shouldKeep = pop:KeepShow()
        local groupId = pop:PayGroup()
        local isGroupAvaliable = ModuleRefer.ActivityShopModule:IsGoodsGroupOpen(groupId)
        if table.ContainsValue(popIds, popId) and isGroupAvaliable then
            table.insert(ret, popId)
        elseif shouldKeep and isGroupAvaliable then
            table.insert(ret, popId)
        end
    end
    return ret
end

---@public
---@param mediatorName string
---@param forceUpdate boolean
---@param keepFinished boolean
function LoginPopupModule:GetPopIdsByMediatorName(mediatorName, forceUpdate, keepFinished)
    if forceUpdate then
        self:UpdateData()
    end
    if not keepFinished then
        return self.popIdsEachMediator[mediatorName]
    else
        local popIds = {}
        for _, pop in ConfigRefer.PopUpWindow:ipairs() do
            local popId = pop:Id()
            local shouldKeep = pop:KeepShow()
            if pop:MediatorName() == mediatorName and (shouldKeep or self.popsOpenStatusCache[popId]) then
                table.insert(popIds, popId)
            end
        end
        return popIds
    end
end

--- end of Getters ---

---@private
function LoginPopupModule:AddPopup()
    self.popHandleIds = {}
    for mediatorName, popIds in pairs(self.popIdsEachMediator) do
        if #popIds > 0 then
            local popTiming = 0
            local popId = popIds[1]
            local pop = ConfigRefer.PopUpWindow:Find(popId)
            for i = 1, pop:PopUpTypeLength() do
                local popUpType = pop:PopUpType(i)
                popTiming = popTiming | popUpType
            end
            self:AddPopsMediator(mediatorName, popTiming)
        end
    end
end

function LoginPopupModule:OnEnterCity(flag)
    if not flag then
        for _, mediatorName in ipairs(self.recycleMediatorList) do
            self:RemovePopsMediator(mediatorName)
        end
        self.recycleMediatorList = {}
        return
    end
    self._enterCityCount = self._enterCityCount + 1
    self.popCountEachTiming[self:GetCurTiming()] = 0
end

function LoginPopupModule:OnPopupListChange(_, changedData, _)
    local addMap = {}
    local removeMap = {}

    if not changedData or (not changedData.List1 and not changedData.List2) then
        return
    end
    for key, list in pairs(changedData) do
        if key ~= 'List1' and key ~= 'List2' then
            goto continue
        end
        if list and list.Add then
            for k, v in pairs(list.Add) do
                addMap[k] = v
            end
        end
        if list and list.Remove then
            for k, v in pairs(list.Remove) do
                removeMap[k] = v
            end
        end
        ::continue::
    end
    self:UpdateData()
    if addMap then
        for _, popId in pairs(addMap) do
            local pop = ConfigRefer.PopUpWindow:Find(popId)
            if not pop then
                g_Logger.ErrorChannel('LoginPopupModule', '弹窗id=%d不存在, 请确认配置是否正确', popId)
                goto continue
            end
            local mediatorName = pop:MediatorName()
            local handleId = self.asyncHandleIdsEachMediator[mediatorName]
            if handleId then
                g_Game.UIAsyncManager:SetOpenParamByAsyncId(handleId, {popIds = self.popIdsEachMediator[mediatorName]})
            else
                local popTiming = 0
                for i = 1, pop:PopUpTypeLength() do
                    local popUpType = pop:PopUpType(i)
                    popTiming = popTiming | popUpType
                end
                self:AddPopsMediator(mediatorName, popTiming)
            end
            ::continue::
        end
    end

    if removeMap then
        for _, popId in pairs(removeMap) do
            local pop = ConfigRefer.PopUpWindow:Find(popId)
            if not pop then
                g_Logger.ErrorChannel('LoginPopupModule', '弹窗id=%d不存在, 请确认配置是否正确', popId)
                goto continue
            end
            local mediatorName = pop:MediatorName()
            local handleId = self.asyncHandleIdsEachMediator[mediatorName]
            if handleId and self.popIdsEachMediator[mediatorName] then
                if #self.popIdsEachMediator[mediatorName] == 0 then
                    self:RemovePopsMediator(mediatorName)
                else
                    g_Game.UIAsyncManager:SetOpenParamByAsyncId(handleId, {popIds = self.popIdsEachMediator[mediatorName]})
                end
            end
            ::continue::
        end
    end
    g_Game.EventManager:TriggerEvent(EventConst.ON_ACT_POPUP_LIST_CHANGE)
end

function LoginPopupModule:OnBeatFly(data, change)
    local myCastle = ModuleRefer.PlayerModule:GetCastle()
    if data.ID ~= myCastle.ID then
        return
    end

    self:AddBeatFlyPoppup()
end

function LoginPopupModule:AddBeatFlyPoppup()
    local myCastle = ModuleRefer.PlayerModule:GetCastle()
    local serverDefeatedTime = myCastle.BasicInfo.LastBeDefeatedTime
    local clientDefeatedTime = ModuleRefer.ClientDataModule:GetData(ClientDataKeys.GameData.DefeatedTime)
    clientDefeatedTime = string.IsNullOrEmpty(clientDefeatedTime) and 0 or tonumber(clientDefeatedTime)
    if serverDefeatedTime > clientDefeatedTime then
        if not HUDMapFunctionComponent.CanGotoKingdom() then
            ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.DefeatedTime, tostring(serverDefeatedTime))
            return
        end

        local timeSec = math.floor(serverDefeatedTime / 1000)
        local timeStr = TimeFormatter.TimeToDateTimeStringUseFormat(timeSec, "MM/dd/yyyy hh:mm:ss")
        timeStr = ("UTC %s"):format(timeStr)
        local descStr = I18N.GetWithParams("alert_popup_hq_attack", timeStr)
    
        ---@type CommonConfirmPopupMediatorParameter
        local data = {}
        data.styleBitMask = CommonConfirmPopupMediatorDefine.Style.Confirm
        data.title = I18N.Get("bestrongwarning_title")
        data.content = I18N.Get(descStr)
        data.confirmLabel = I18N.Get("confirm")
        data.onConfirm = function()
            ModuleRefer.ClientDataModule:SetData(ClientDataKeys.GameData.DefeatedTime, tostring(serverDefeatedTime))
            local position = myCastle.MapBasics.Position
            KingdomMapUtils.GotoCoordinate(position.X, position.Y, SceneType.SlgBigWorld)
            return true
        end

        ---@type UIAsyncDataProvider
        local provider = UIAsyncDataProvider.new()
        provider:Init(
            UIMediatorNames.CommonConfirmPopupMediator,
            UIAsyncDataProvider.PopupTimings.AnyTime,
            UIAsyncDataProvider.CheckTypes.CheckAll,
            UIAsyncDataProvider.StrategyOnCheckFailed.DelayToAnyTimeAvailable,
            false, data)
            
        provider:SetOtherMediatorCheckType(0)
        provider:AddOtherMediatorBlackList(UIMediatorNames.LoadingPageMediator)
        g_Game.UIAsyncManager:AddAsyncMediator(provider)
    end
end

---@private
function LoginPopupModule:ClearPops()
    for _, popHandleId in ipairs(self.popHandleIds) do
        g_Game.UIAsyncManager:RemoveAsyncMediator(popHandleId)
    end
end

function LoginPopupModule:RemovePopsMediator(mediatorName)
    local popHandleId = self.asyncHandleIdsEachMediator[mediatorName]
    if popHandleId then
        g_Game.UIAsyncManager:RemoveAsyncMediator(popHandleId)
        self.asyncHandleIdsEachMediator[mediatorName] = nil
    end
end

function LoginPopupModule:AddPopsMediator(mediatorName, popTiming)
    if Utils.IsNullOrEmpty(mediatorName) then
        return
    end
    ---@type UIAsyncDataProvider
    local provider = UIAsyncDataProvider.new()
    local mediator = mediatorName
    local timing = UIAsyncDataProvider.PopupTimings.EnterCity
    local checkType = UIAsyncDataProvider.CheckTypes.CheckAll
    local StrategyOnCheckFailed = UIAsyncDataProvider.StrategyOnCheckFailed.Custom
    local popIds = self.popIdsEachMediator[mediatorName]
    local openParams = {
        popIds = popIds,
    }
    provider:Init(mediator, timing, checkType, StrategyOnCheckFailed, true, openParams)
    provider:SetOtherMediatorCheckType(UIManager.UIMediatorType.Dialog | UIManager.UIMediatorType.Popup)
    provider:AddOtherMediatorBlackList(UIMediatorNames.LoadingPageMediator)
    provider:SetCustomChecker(function ()
        local isCurTiming = (self:GetCurTiming() & popTiming ~= 0)
        local isMaxNum = self.popCountEachTiming[self:GetCurTiming()] >= MAX_POPUP_NUM[self:GetCurTiming()]
        return isCurTiming and not isMaxNum
    end)
    provider:SetCustomCheckFailedCallback(function (id, failedTypeMask, curTiming)
        if failedTypeMask & UIAsyncDataProvider.CheckTypes.CustomChecker == 0 then
            g_Game.UIAsyncManager:OnCheckFailedDelayToAnyTimeAvailable(id, curTiming)
            -- 如果登录时弹窗在离开city时仍然没有满足弹出条件，则在UIAsyncManager中取消排队
            table.insert(self.recycleMediatorList, mediatorName)
        else
            g_Game.UIAsyncManager:OnCheckFailedDelayToNextCurrentTiming(id, curTiming)
        end
    end)
    provider:SetCustomOnOpenedCallback(function ()
        self.popCountEachTiming[self:GetCurTiming()] = self.popCountEachTiming[self:GetCurTiming()] + 1
    end)
    local popHandleId = g_Game.UIAsyncManager:AddAsyncMediator(provider)
    table.insert(self.popHandleIds, popHandleId)
    self.asyncHandleIdsEachMediator[mediatorName] = popHandleId
end

---@private
function LoginPopupModule:IsPopupListEmpty()
    return #self._popList1 == 0 and #self._popList2 == 0
end

function LoginPopupModule:IsLogin()
    return self._enterCityCount <= 1
end

function LoginPopupModule:GetCurTiming()
    if self:IsLogin() then
        return POPUP_TIMING_MASK.LOGIN_ENTER_CITY
    else
        return POPUP_TIMING_MASK.GAME_ENTER_CITY
    end
end

---@public
function LoginPopupModule:OnPopupShown(popIds)
    local msg = PopUpWindomParameter.new()
    msg.args.Ids:AddRange(popIds)
    msg:Send()
end

return LoginPopupModule