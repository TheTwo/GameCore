local EventConst = require('EventConst')
local BaseUIComponent = require('BaseUIComponent')
local Utils = require('Utils')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local ModuleRefer = require('ModuleRefer')

---@class BaseUIMediator : BaseUIComponent
---@field OnCreate fun(param:table)
---@field OnShow fun(param:table)
---@field OnOpened fun(param:table)
---@field OnFeedData fun(param:table)
---@field OnHide fun(param:table)
---@field OnClose fun(param:table)
---@field OnReOpen fun()
---@field OnTypeVisible fun(param:table)
---@field OnTypeInvisible fun(param:table)
---@field CSComponent CS.DragonReborn.UI.LuaUIMediator
local BaseUIMediator = class('BaseUIMediator',BaseUIComponent)

function BaseUIMediator:GetRuntimeId()
    if self.runtimeId == nil then
        if self.CSComponent ~= nil then
            self.runtimeId = self.CSComponent.RuntimeId;            
        end
    end
    return self.runtimeId
end
---@return number
function BaseUIMediator:GetUIMediatorType()
    if self.mtype == nil then
        if self.CSComponent ~= nil then
            self.mtype = self.CSComponent.UIMediatorTypeValue
        end
    end
    return self.mtype
end

function BaseUIMediator:ctor()
    BaseUIComponent.ctor(self)
end

--call from C#
-- function BaseUIMediator:OnCreate(param)
    
-- end

-- function BaseUIMediator:OnShow(param)
    
-- end

function BaseUIMediator:OnOpened(param)
    BaseUIComponent.OnOpened(self,param)
end

function BaseUIMediator:OnOpenedTrace(param)
    ModuleRefer.FPXSDKModule:TrackUIWindowOpen(self:GetName())
end

-- function BaseUIMediator:OnFeedData(param)

-- end

-- function BaseUIMediator:OnHide(param)
  
-- end

-- function BaseUIMediator:OnTypeVisible()
-- end

-- function BaseUIMediator:OnTypeInvisible()
-- end

function BaseUIMediator:OnClose(data)
    BaseUIComponent.OnClose(self,data)
end

function BaseUIMediator:OnCloseTrace(data)
    ModuleRefer.FPXSDKModule:TrackUIWindowClose(self:GetName())
end

---关闭窗口并清空窗口堆栈
function BaseUIMediator:CloseSelf(param,forceClose)   
    if  Utils.IsNull(self.CSComponent) or self._closingAnim then
        --说明窗口已经关闭
        return
    end
    self.CSComponent:StopAllAnim(FpAnimTriggerEvent.OnShow)
    if forceClose then
        g_Game.UIManager:Close(self:GetRuntimeId(),param,false)
    else
        if not self.CSComponent:TriggerAllAnim(FpAnimTriggerEvent.OnClose,function()
            self._closingAnim = false
            g_Game.UIManager:Close(self:GetRuntimeId(),param,false)
        end
        ) then
            g_Game.UIManager:Close(self:GetRuntimeId(),param,false)
        else
            self._closingAnim = true
        end
    end
end
---关闭窗口并打开上一个窗口
---窗口必需是Dialog类型的才能进入堆栈，其他类型的直接关闭窗口
function BaseUIMediator:BackToPrevious(param, skipHideAni, skipPreviousShowAni)
    if Utils.IsNull(self.CSComponent) or self._closingAnim then
        --说明窗口已经关闭
        return
    end
    self.CSComponent:StopAllAnim(FpAnimTriggerEvent.OnShow)
    if skipHideAni then
        self._closingAnim = false
        g_Game.UIManager:Close(self:GetRuntimeId(),param,true, skipPreviousShowAni)
    elseif not self.CSComponent:TriggerAllAnim(FpAnimTriggerEvent.OnClose,function()
        self._closingAnim = false
        g_Game.UIManager:Close(self:GetRuntimeId(),param,true, skipPreviousShowAni)
    end
    ) then
        g_Game.UIManager:Close(self:GetRuntimeId(),param,true, skipPreviousShowAni)
    else
        self._closingAnim = true
    end
end

function BaseUIMediator:TriggerShowMsg(uiName)
    g_Game.EventManager:TriggerEvent(EventConst.ON_UIMEDIATOR_OPENED,uiName)
end

function BaseUIMediator:TriggerHideMsg(uiName)
    g_Game.EventManager:TriggerEvent(EventConst.ON_UIMEDIATOR_CLOSEED,uiName)
end

function BaseUIMediator:StopAllAnim()
    if self._closingAnim then
        self._closingAnim = false
        self.CSComponent:StopAllAnim(FpAnimTriggerEvent.OnClose)
    end
end

function BaseUIMediator:GetParentBaseUIMediator()
    return self
end

function BaseUIMediator:GetTickerCache(alloc)
    if not self._timerCache then
        self._timerCache = {}
    end
    return self._timerCache
end

function BaseUIMediator:StopAllTimers()
    if not self._timerCache then return end
    local TimerUtility = require("TimerUtility")
    for timer, _ in pairs(self._timerCache) do
        TimerUtility.StopAndRecycle(timer)
    end
    self._timerCache = nil
end

---设置窗口异步加载标记，在加载完成后需要调用RemoveAsyncLoadFlag移除标记
---只在OnCreate中调用才有效果
function BaseUIMediator:SetAsyncLoadFlag()
    if Utils.IsNotNull(self.CSComponent) then
        self.CSComponent:SetAsyncLoadFlag()
    end
    
end

---完成异步加载后，移除窗口异步加载标记。然后才会正确进行窗口的打开流程
---在异步过程中，在这个方法被调用之前，不会调用OnOpened方法
function BaseUIMediator:RemoveAsyncLoadFlag()
    if Utils.IsNotNull(self.CSComponent) then
        self.CSComponent:RemoveAsyncLoadFlag()
    end
end

return BaseUIMediator