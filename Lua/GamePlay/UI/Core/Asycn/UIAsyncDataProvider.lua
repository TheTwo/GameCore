local ModuleRefer = require("ModuleRefer")
local UIManager = require("UIManager")
local SeSence = require("SeScene")
local Utils = require("Utils")
local GuideType = require("GuideType")
local UIMediatorNames = require("UIMediatorNames")
---@class UIAsyncDataProvider
---@field new fun():UIAsyncDataProvider
local UIAsyncDataProvider = class('UIAsyncDataProvider')

---@class UIAsyncDataProvider.CheckTypes
local CheckTypes = {
    None = 0,
    DoNotShowInTimeLine = 1 << 0,
    DoNotShowInGuidance = 1 << 1,
    DoNotShowInSE = 1 << 2,
    DoNotShowOnOtherMediator = 1 << 3,
    DoNotShowInGVE = 1 << 4,
    DoNotShowInCitySE = 1 << 5,
    DoNotShowInCityZoneRecoverState = 1 << 6,
    GlobalBlock = 1 << 7,
    CustomChecker = 0x80000000,
    CheckAll = 0xFFFFFFFF,
}

UIAsyncDataProvider.CheckTypes = CheckTypes

---@class UIAsyncDataProvider.StrategyOnCheckFailed
local StrategyOnCheckFailed = {
    Cancel = 1, -- 取消显示
    DelayToNextCurrentTiming = 2, -- 移动至延迟队列，下一次当前设置的时机到来时重新检查，不影响原队列的后续弹出
    DelayToAnyTimeAvailable = 3, -- 移动至延迟队列，尝试在任何时机重新检查，不影响原队列的后续弹出
    Block = 4, -- 阻塞队列，直到当前阻塞的因素消失后立即弹出
    Custom = 99
}

UIAsyncDataProvider.StrategyOnCheckFailed = StrategyOnCheckFailed

---@class UIAsyncDataProvider.PopupTimings
local PopupTimings = {
    AnyTime = 0, -- 立即显示
    EnterCity = 1,
    EnterMap = 2
}

UIAsyncDataProvider.PopupTimings = PopupTimings

UIAsyncDataProvider.MediatorTypes = UIManager.UIMediatorType

function UIAsyncDataProvider:ctor()
    self._showLog = true
    self.mediatorName = nil
    self.openParam = nil
    self.removed = false
    self.shouldCheckTimeLine = false
    self.shouldCheckGuidance = false
    self.shouldCheckSE = false
    self.shouldCheckOtherMediator = false
    self.shouldCheckCustom = false
    self.priority = 0
    self.otherMediatorWhiteList = {}
    self.otherMediatorBlackList = {}

    self.runtimeId = -1

    self.openFunc = nil
    self.customChecker = function()
        g_Logger.Warn('Custom checker is not set for aysnc provider %s', self.mediatorName)
        return true
    end
    self.customOnOpened = function() end
end

---@param self UIAsyncDataProvider
---@param mediatorName string
---@param popupTiming number @UIAsyncDataProvider.PopupTimings 默认AnyTime
---@param checkTypes number @UIAsyncDataProvider.CheckTypes 默认CheckAll, 当DoNotShowOnOtherMediator选中时，可以通过SetOtherMediatorCheckType筛选不允许覆盖的Mediator类型，默认不允许在其他Dialog和Popup上显示
---@param checkFailedStrategy number @UIAsyncDataProvider.StrategyOnCheckFailed 默认DelayToAnyTimeAvailable
---@param shouldKeep boolean 是否在打开后保留在队列中，默认false
---@param openParam any
function UIAsyncDataProvider:Init(mediatorName, popupTiming, checkTypes, checkFailedStrategy, shouldKeep, openParam)
    local types = checkTypes or CheckTypes.CheckAll
    self.shouldCheckTimeLine = (CheckTypes.DoNotShowInTimeLine & types) ~= 0
    self.shouldCheckGuidance = (CheckTypes.DoNotShowInGuidance & types) ~= 0
    self.shouldCheckSE = (CheckTypes.DoNotShowInSE & types) ~= 0
    self.shouldCheckGve = (CheckTypes.DoNotShowInGVE & types) ~= 0
    self.shouldCheckOtherMediator = (CheckTypes.DoNotShowOnOtherMediator & types) ~= 0
    self.shouldCheckCustom = (CheckTypes.CustomChecker & types) ~= 0
    self.shouldCheckCitySE = (CheckTypes.DoNotShowInCitySE & types) ~= 0
    self.shouldCheckCityRecoverState = (CheckTypes.DoNotShowInCityZoneRecoverState & types) ~= 0
    self.checkFailedStrategy = checkFailedStrategy or StrategyOnCheckFailed.DelayToAnyTimeAvailable
    self.mediatorName = mediatorName
    self.popupTiming = popupTiming or PopupTimings.AnyTime
    self.shouldKeep = shouldKeep or false
    self.openParam = openParam
end

function UIAsyncDataProvider:Release()
    self.mediatorName = nil
    self.openParam = nil
    self.removed = nil
    self.popupTiming = nil
    self.shouldCheckTimeLine = nil
    self.shouldCheckGuidance = nil
    self.shouldCheckSE = nil
    self.shouldCheckGve = nil
    self.shouldCheckOtherMediator = nil
    self.shouldCheckCustom = nil
    self.customChecker = nil
end

--- 设置自定义检查器
---@param checker fun():boolean
function UIAsyncDataProvider:SetCustomChecker(checker)
    self.customChecker = checker
end

--- 设置自定义检查失败时的回调
---@param onCheckFailed fun(asyncId: number, failedTypeMask: number, timing: number)
function UIAsyncDataProvider:SetCustomCheckFailedCallback(onCheckFailed)
    self.customOnCheckFailed = onCheckFailed
end

--- 设置自定义打开时的回调
---@param onOpened fun(asyncId: number, timing: number)
function UIAsyncDataProvider:SetCustomOnOpenedCallback(onOpened)
    self.customOnOpened = onOpened
end

--- 设置不允许覆盖的meditaor类型
---@param self UIAsyncDataProvider
---@param type number
function UIAsyncDataProvider:SetOtherMediatorCheckType(type)
    self.otherMediatorCheckType = type
end

--- 设置优先级
---@param priority number
function UIAsyncDataProvider:SetPriority(priority)
    self.priority = priority
end

--- 设置是否显示日志
---@param show boolean
function UIAsyncDataProvider:SetShowLog(show)
    self._showLog = show
end

--- 设置通过函数打开UI
---@param func fun()
function UIAsyncDataProvider:SetOpenFunc(func)
    self.openFunc = func
end

--- 获取mediator名称
---@return string
function UIAsyncDataProvider:GetMediatorName()
    return self.mediatorName
end

---@param runtimeId number
function UIAsyncDataProvider:SetRunTimeId(runtimeId)
    self.runtimeId = runtimeId
end

---@return number
function UIAsyncDataProvider:GetRunTimeId()
    return self.runtimeId
end

---@param asyncId number
function UIAsyncDataProvider:SetAsyncId(asyncId)
    self.asyncId = asyncId
end

---@return number
function UIAsyncDataProvider:GetAsyncId()
    return self.asyncId
end

--- 处理少数情况下mediator没有通过UIManager.Close关闭，关闭后mediators[runtimeId] ~= nil
---@param mediator BaseUIMediator
---@return boolean
function UIAsyncDataProvider:IsMediatorActuallyClosed(mediator)
    return Utils.IsNull(mediator.CSComponent) or mediator._closingAnim
end

---@param self UIAsyncDataProvider
---@return number 返回一个指示没有通过检查的BitMask
function UIAsyncDataProvider:Check()
    local checkFailedMask = 0
    checkFailedMask = checkFailedMask | self:CheckTimeLine()
    checkFailedMask = checkFailedMask | self:CheckGuidance()
    checkFailedMask = checkFailedMask | self:CheckSE()
    checkFailedMask = checkFailedMask | self:CheckGve()
    checkFailedMask = checkFailedMask | self:CheckOtherMediator()
    checkFailedMask = checkFailedMask | self:CheckCustom()
    checkFailedMask = checkFailedMask | self:CheckCitySE()
    checkFailedMask = checkFailedMask | self:CheckCityRecoverZoneEffect()
    checkFailedMask = checkFailedMask | self:CheckGlobalBlock()
    return checkFailedMask
end

--- 添加一个mediator到白名单，当CheckTypes.DoNotShowOnOtherMediator选中时，可以通过该方法添加允许覆盖的Mediator
---@param self UIAsyncDataProvider
---@param mediatorName UIMediatorNames
function UIAsyncDataProvider:AddOtherMediatorWhiteList(mediatorName)
    if not string.IsNullOrEmpty(mediatorName) then
        self.otherMediatorWhiteList[mediatorName] = true
    end
end

--- 添加一个mediator到黑名单，当CheckTypes.DoNotShowOnOtherMediator选中时，该mediator会无论检查类型强制阻塞队列
---@param self UIAsyncDataProvider
---@param mediatorName UIMediatorNames
function UIAsyncDataProvider:AddOtherMediatorBlackList(mediatorName)
    if not string.IsNullOrEmpty(mediatorName) then
        self.otherMediatorBlackList[mediatorName] = true
    end
end

function UIAsyncDataProvider:Open()
    if self.openFunc then
        self.openFunc()
    else
        g_Game.UIManager:Open(self.mediatorName, self.openParam)
    end
end

---@private
function UIAsyncDataProvider:CheckTimeLine()
    if not self.shouldCheckTimeLine then
        return 0
    end
    if ModuleRefer.StoryModule:IsStoryTimelineOrDialogPlaying() then
        self:Log('%s is blocked by timeline', self.mediatorName)
        return CheckTypes.DoNotShowInTimeLine
    else
        return 0
    end
end

---@private
function UIAsyncDataProvider:CheckGuidance()
    if not self.shouldCheckGuidance then
        return 0
    end
    local guideFingerMediator = g_Game.UIManager:FindUIMediatorByName(UIMediatorNames.UIGuideFingerMediator)
    local isGuideExecuting = ModuleRefer.GuideModule:IsExecuting()
    if guideFingerMediator and guideFingerMediator.guideType ~= GuideType.Goto then
        self:Log('%s is blocked by guidance', self.mediatorName)
        return CheckTypes.DoNotShowInGuidance
    elseif isGuideExecuting then
        self:Log('%s is blocked by guidance', self.mediatorName)
        return CheckTypes.DoNotShowInGuidance
    else
        return 0
    end
end

---@private
function UIAsyncDataProvider:CheckSE()
    if not self.shouldCheckSE then
        return 0
    end
    if g_Game.SceneManager:GetCurrentSceneName() == SeSence.Name then
        self:Log('%s is blocked by SE', self.mediatorName)
        return CheckTypes.DoNotShowInSE
    else
        return 0
    end
end

function UIAsyncDataProvider:CheckCitySE()
    if not self.shouldCheckCitySE then
        return 0
    end
    local city = ModuleRefer.CityModule:GetMyCity()
    if not city then
        return 0
    end
    if city:IsInSeBattleMode() or city:IsInSingleSeExplorerMode() or city:IsInRecoverZoneEffectMode() then
        self:Log('%s is blocked by City SE', self.mediatorName)
        return CheckTypes.DoNotShowInCitySE
    else
        return 0
    end
end

function UIAsyncDataProvider:CheckCityRecoverZoneEffect()
    if not self.shouldCheckCityRecoverState then
        return 0
    end
    local city = ModuleRefer.CityModule:GetMyCity()
    if not city then
        return 0
    end
    if city:IsInRecoverZoneEffectMode() then
        self:Log('%s is blocked by City RecoverZoneEffect', self.mediatorName)
        return CheckTypes.DoNotShowInCityZoneRecoverState
    else
        return 0
    end
end

---@private
function UIAsyncDataProvider:CheckGve()
    if not self.shouldCheckGve then
        return 0
    end
    if g_Game.SceneManager:GetCurrentSceneName() == require('SlgScene').Name then
        self:Log('%s is blocked by Gve', self.mediatorName)
        return CheckTypes.DoNotShowInGVE
    else
        return 0
    end
end

---@private
function UIAsyncDataProvider:CheckOtherMediator()
    if not self.shouldCheckOtherMediator then
        return 0
    end
    if self.otherMediatorCheckType == nil then
        self.otherMediatorCheckType = UIManager.UIMediatorType.Dialog | UIManager.UIMediatorType.Popup
    end
    for _, mediator in pairs(g_Game.UIManager.mediators) do
        if self:IsMediatorActuallyClosed(mediator) then
            goto continue
        end
        if self.otherMediatorBlackList[mediator:GetName()] then
            self:Log('%s is blocked by blacklist mediator %s', self.mediatorName, mediator:GetName())
            return CheckTypes.DoNotShowOnOtherMediator
        end
        if mediator:GetUIMediatorType() & self.otherMediatorCheckType ~= 0 and not self.otherMediatorWhiteList[mediator:GetName()] then
            self:Log('%s is blocked by other mediator %s', self.mediatorName, mediator:GetName())
            return CheckTypes.DoNotShowOnOtherMediator
        end
        ::continue::
    end
    return 0
end

---@private
function UIAsyncDataProvider:CheckCustom()
    if self.customChecker() then
        return 0
    else
        self:Log('%s is blocked by custom checker', self.mediatorName)
        return CheckTypes.CustomChecker
    end
end

function UIAsyncDataProvider:CheckGlobalBlock()
    if ModuleRefer.UIAsyncModule.globalBlock then
        self:Log('%s is blocked by global block', self.mediatorName)
        return CheckTypes.GlobalBlock
    else
        return 0
    end
end

function UIAsyncDataProvider:Log(str, ...)
    if not self._showLog then
        return
    end
    g_Logger.LogChannel('UIAsyncDataProvider', str, ...)
end

return UIAsyncDataProvider