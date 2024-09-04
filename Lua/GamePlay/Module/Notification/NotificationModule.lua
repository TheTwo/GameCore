local BaseModule = require("BaseModule")

---通用通知模块
---@class NotificationModule : BaseModule
local NotificationModule = class("NotificationModule", BaseModule)

local NotificationManager = CS.Notification.NotificationManager
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")

---@param self NotificationModule
function NotificationModule:ctor()
    self._countChangedCallbackList = {}
end

---@param self NotificationModule
---@return void
function NotificationModule:Init()
    -- 清理
    self:Release()

    -- 加载配置表
    for _, conf in ConfigRefer.NotificationNode:ipairs() do
        local type = conf:Id()
        if (type > 0) then
            --g_Logger.Log("Add type %s", type)
            NotificationManager.Instance:AddType(type)
        end
        if (conf:FatherNode() > 0) then
            --g_Logger.Log("Add type %s as parent of type %s", conf:FatherNode(), type)
            NotificationManager.Instance:AddParentType(type, conf:FatherNode())
        end
        if (conf:IfBase()) then
            --g_Logger.Log("Set type %s as terminal", type)
            NotificationManager.Instance:SetTerminalType(type)
        end
        if (conf:IfTemplate()) then
            --g_Logger.Log("Set type %s as template", type)
            NotificationManager.Instance:SetTemplateType(type)
        end
        if (conf:AutoDisappearTime() > 0) then
         --   g_Logger.Log("Set type %s auto read time %s", type, conf:AutoDisappearTime())
            NotificationManager.Instance:AddAutoReadTime(type, conf:AutoDisappearTime())
        end
    end

    -- 初始化完成
    NotificationManager.Instance:MarkInit()
end

function NotificationModule:OnRegister()
    self:Init()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecondTick))
end

function NotificationModule:OnRemove()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecondTick))
    self:Release()
end

-- 清理
---@param self NotificationModule
---@return void
function NotificationModule:Release()
    self._countChangedCallbackList = {}
    NotificationManager.Instance:Clear()
end

function NotificationModule:SecondTick()
    -- 自动已读处理
    NotificationManager.Instance:RefreshAutoRead()
end

--- 获取通知管理器C#对象单例
---@param self NotificationModule
---@return CS.Notification.NotificationManager
function NotificationModule:GetManager()
    return NotificationManager.Instance
end

-- 创建或动态节点
---@param self NotificationModule
---@param uniqueName string 惟一名
---@param type number 通知类型
---@param go CS.UnityEngine.GameObject 游戏对象
---@param toggleObject CS.UnityEngine.GameObject 显隐对象
---@param textObject CS.UnityEngine.UI.Text 文本对象
---@param customTextFunc function<number, CS.UnityEngine.UI.Text> 自定义红点文字显示 (通知数量, 文本对象)
---@return CS.Notification.NotificationDynamicNode
function NotificationModule:GetOrCreateDynamicNode(uniqueName, type, go, toggleObject, textObject, customTextFunc)
    return NotificationManager.Instance:GetOrCreateDynamicNode(uniqueName, type, go, toggleObject, textObject, customTextFunc)
end

--- 获取动态节点
---@param self NotificationModule
---@param uniqueName string 惟一名
---@param type number 通知类型
---@return CS.Notification.NotificationDynamicNode
function NotificationModule:GetDynamicNode(uniqueName, type)
    return NotificationManager.Instance:GetDynamicNode(uniqueName, type)
end

--- 销毁动态节点
---@param self NotificationModule
---@param dynamicNode CS.Notification.NotificationDynamicNode
---@param disposeAllSubNodes boolean 是否销毁所有子节点
function NotificationModule:DisposeDynamicNode(dynamicNode, disposeAllSubNodes)
    if (not dynamicNode) then return end
    NotificationManager.Instance:DisposeDynamicNode(dynamicNode, disposeAllSubNodes)
end

--- 将动态节点附加到游戏对象
---@param self NotificationModule
---@param dynamicNode CS.Notification.NotificationDynamicNode 动态节点
---@param go CS.UnityEngine.GameObject 游戏对象
---@param toggleObject CS.UnityEngine.GameObject 显隐对象
---@param textObject CS.UnityEngine.UI.Text 文本对象
---@param customTextFunc fun(count:number, label:CS.UnityEngine.UI.Text) 自定义红点文字显示 (通知数量, 文本对象)
function NotificationModule:AttachToGameObject(dynamicNode, go, toggleObject, textObject, customTextFunc)
    if (not dynamicNode or not go) then return end
    NotificationManager.Instance:AttachToGameObject(dynamicNode, go, toggleObject, textObject, customTextFunc)
end

--- 从游戏对象移除动态节点
---@param self NotificationModule
---@param go CS.UnityEngine.GameObject 游戏对象
---@param removeComponent boolean 是否移除组件
---@return CS.Notification.NotificationDynamicNode
function NotificationModule:RemoveFromGameObject(go, removeComponent)
    if (not go) then return nil end
    return NotificationManager.Instance:RemoveFromGameObject(go, removeComponent)
end

--- 将动态节点添加到父节点
---@param self NotificationModule
---@param dynamicNode CS.Notification.NotificationDynamicNode 节点
---@param parentNode CS.Notification.NotificationDynamicNode 父节点
---@param clearParentPriorityCondition boolean 清除优先条件
function NotificationModule:AddToParent(dynamicNode, parentNode, clearParentPriorityCondition)
    if (not dynamicNode or not parentNode) then return end
    if (clearParentPriorityCondition == nil) then clearParentPriorityCondition = true end
    NotificationManager.Instance:AddToParent(dynamicNode, parentNode, clearParentPriorityCondition)
end

--- 将动态从父节点中移除
---@param self NotificationModule
---@param dynamicNode CS.Notification.NotificationDynamicNode 节点
---@param parent CS.Notification.NotificationDynamicNode 父节点
function NotificationModule:RemoveFromParent(dynamicNode, parent)
    if (not dynamicNode or not parent) then return end
    NotificationManager.Instance:RemoveFromParent(dynamicNode, parent)
end

--- 获取静态通知数量
---@param self NotificationModule
---@param type number 通知类型
---@return number
function NotificationModule:GetStaticNotificationCount(type)
    return NotificationManager.Instance:GetStaticNotificationCount(type)
end

--- 设置动态节点的通知数量
---@param self NotificationModule
---@param dynamicNode CS.Notification.NotificationDynamicNode 节点
---@param count number 数量
function NotificationModule:SetDynamicNodeNotificationCount(dynamicNode, count)
    if (not dynamicNode or count < 0) then return end
    --g_Logger.Log("Set node count %s to %s", dynamicNode.UniqueName, count)
    NotificationManager.Instance:SetDynamicNodeNotificationCount(dynamicNode, count)
end

-- 设置静态通知数量
---@param self NotificationModule
---@param type number 通知类型
---@param count number 通知数量
---@return void
function NotificationModule:SetStaticNotificationCount(type, count)
    if (not type or type < 0) then return end
    local oldCount = NotificationManager.Instance:GetStaticNotificationCount(type)
    local deltaCount = count - oldCount
    NotificationManager.Instance:SetStaticNotificationCount(type, count)
    self:InvokeStaticCountChangedListeners(type, oldCount, oldCount + deltaCount)
end

--- 添加静态通知数量变更监听
---@param self NotificationModule
---@param type number 通知类型
---@param listener function<number, number> 监听回调 (原数量, 新数量)
function NotificationModule:AddStaticCountChangedListener(type, listener)
    if (not listener) then return end
    if (not self._countChangedCallbackList[type]) then
        self._countChangedCallbackList[type] = {}
    end
    table.insert(self._countChangedCallbackList[type], listener)
end

--- 移除静态通知数量变更监听
---@param self NotificationModule
---@param type number 通知类型
---@param listener function<number, number> 监听回调 (原数量, 新数量)
function NotificationModule:RemoveStaticCountChangedListener(type, listener)
    if (not listener) then return end
    if (not self._countChangedCallbackList[type]) then return end
    for index, func in pairs(self._countChangedCallbackList[type]) do
        if (func == listener) then
            self._countChangedCallbackList[type][index] = nil
        end
    end
end

--- 清除静态通知数量变更监听
---@param self NotificationModule
---@param type number 通知类型
function NotificationModule:ClearStaticCountChangedListener(type)
    if (not self._countChangedCallbackList[type]) then return end
    self._countChangedCallbackList[type] = nil
end

---@param self NotificationModule
---@param type number 通知类型
---@param oldCount number 原数量
---@param newCount number 新数量
function NotificationModule:InvokeStaticCountChangedListeners(type, oldCount, newCount)
    if (not self._countChangedCallbackList[type]) then return end
    for _, func in pairs(self._countChangedCallbackList[type]) do
        if (func) then
            func(oldCount, newCount)
        end
    end
end

---@param self NotificationModule
---@param node CS.Notification.NotificationDynamicNode
function NotificationModule:RemoveAllChildren(node)
	NotificationManager.Instance:RemoveAllChildren(node)
end

---@param self NotificationModule
---@param node CS.Notification.NotificationDynamicNode
function NotificationModule:RemoveFromAllParents(node)
	NotificationManager.Instance:RemoveFromAllParents(node)
end

return NotificationModule
