local BaseUIMediator = require('BaseUIMediator')
local UIHelper = require('UIHelper')
local TimerUtility = require('TimerUtility')
local EventConst = require('EventConst')

---@class ChildInitData
---@field id number
---@field childName string
---@field priority number
---@field childOpenParams any
---@field isOpen boolean

---@class BaseUIMediatorWithManualCreateTab : BaseUIMediator
---@field selectType number @当前选中的tabId
---@field targetChildInitMask number @目标子预制体初始化掩码
---@field curChildInitMask number @当前子预制体初始化掩码
---@field tabId2TableIndex table<number, number> @tabId到tableTabs索引的映射
---@field childKeys table<number, number> @子预制体索引表
---@field neededChildren table<number, ChildInitData> @需要加载的子预制体表
---@field tabComps table<number, BaseUIComponent> @子预制体Lua组件表
---@field generatorNodeName string @生成节点名
---@field TEST_PREFAB_NAMES table<number, string> @测试预制体名称表
---@field cfgTable Config @配置表
---@field goLoadMask CS.UnityEngine.GameObject @加载遮罩，可选
---@field uiLockData table @UI锁数据
---@field loadingTimer Timer @加载超时计时器
---@field delayedInitTimer Timer @延迟初始化计时器
---@field isTimeOut boolean @是否超时
---@field tableTabs CS.TableViewPro @tab控件
local BaseUIMediatorWithManualCreateTab = class('BaseUIMediatorWithManualCreateTab', BaseUIMediator)

local TIMEOUT_THRESHOLD_SEC = 3

function BaseUIMediatorWithManualCreateTab:ctor()
    BaseUIMediator.ctor(self)

    self.selectType = nil

    self.targetChildInitMask = 0

    self.curChildInitMask = 0

    ---@type table<number, number>
    self.tabId2TableIndex = {}

    ---@type table<number, number>
    self.childKeys = {}

    ---@type table<number, ChildInitData>
    self.neededChildren = {}

    ---@type table<number, BaseUIComponent>
    self.tabComps = {}

    self.generatorNodeName = ''

    -- 需要在开发阶段显示的子预制体名称，用于配置尚未到位的情况
    -- 仅在DEBUG及Editor生效
    self.TEST_PREFAB_NAMES = {
        -- [1] = 'test_child'
    }

    ---@type CS.TableViewPro
    self.cfgTable = nil
end

function BaseUIMediatorWithManualCreateTab:CheckMembers()
    assert(self.generatorNodeName and self.generatorNodeName ~= '', 'generatorNodeName is nil or empty')
    assert(self.tableTabs, 'tableTabs is nil')
    assert(self.cfgTable, 'cfgTable is nil')
end

function BaseUIMediatorWithManualCreateTab:Init()
    self:CheckMembers()
    self:UpdateTabOpenState()
    self:GetNeededChildContent()
    for _, key in ipairs(self.childKeys) do
        self:GenerateComp(self.neededChildren[key])
    end
    self.uiLockData = {fullScreen = true}
    self.loadingTimer = TimerUtility.DelayExecute(function()
        if self.targetChildInitMask == self.curChildInitMask then return end
        self.selectType = nil
        self:DelayInitContent(10)
        local missedTabIdsMask = self.targetChildInitMask ~ self.curChildInitMask
        for i = 1, 32 do
            if (missedTabIdsMask & (1 << i)) ~= 0 then
                g_Logger.Error('加载子预制体%s超时, 请检查配置填写及场景挂载是否正确', self.neededChildren[i].childName)
            end
        end
        self.isTimeOut = true
    end, TIMEOUT_THRESHOLD_SEC)
    UIHelper.UILock(self.uiLockData)
end

function BaseUIMediatorWithManualCreateTab:Release()
    if self.delayedInitTimer then
        TimerUtility.StopAndRecycle(self.delayedInitTimer)
        self.delayedInitTimer = nil
    end

    if self.loadingTimer then
        TimerUtility.StopAndRecycle(self.loadingTimer)
        self.loadingTimer = nil
    end

    UIHelper.UIUnlock(self.uiLockData)
end

function BaseUIMediatorWithManualCreateTab:GenerateComp(childData)
    if not (childData or {}).childName then
        return
    end
    CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, childData.childName, self.generatorNodeName, function()
        g_Game.EventManager:TriggerEvent(EventConst.ON_CREATE_CHILD, childData.index)
    end,false)
end

function BaseUIMediatorWithManualCreateTab:OnCreateChild(index)
    if not self.neededChildren[index] then return end
    self.tabComps[index] = self:LuaObject(self.neededChildren[index].childName)
    self.tabComps[index]:SetVisible(false)
    if not self.isTimeOut then
        self.curChildInitMask = self.curChildInitMask | (1 << index)
    end
    if self.targetChildInitMask == self.curChildInitMask and not self.isTimeOut then
        self:DelayInitContent(10)
    elseif self.isTimeOut then
        self:RefreshTabs()
    end
end

function BaseUIMediatorWithManualCreateTab:GetNeededChildContent()
    for _, tab in self.cfgTable:ipairs() do
        if self:IsTabOpen(tab) or tab:Keep() then
            local childInitData = {}
            childInitData.index = tab:Id()
            childInitData.childName = tab:PrefabName()
            childInitData.priority = tab:Priority()
            local openParams = {}
            openParams.tabId = tab:Id()
            childInitData.childOpenParams = openParams
            if childInitData.childName and childInitData.childName ~= '' then
                self.neededChildren[tab:Id()] = childInitData
                self.targetChildInitMask = self.targetChildInitMask | (1 << tab:Id())
            end
        end
    end

    if UNITY_DEBUG or UNITY_EDITOR then
        for fakeId, name in pairs(self.TEST_PREFAB_NAMES) do
            for _, v in pairs(self.neededChildren) do
                if v.childName == name then
                    g_Logger.Error('测试预制体名称%s与正式预制体名称重复, 测试预制体将不会加载', name)
                    goto continue
                end
            end
            local childInitData = {}
            childInitData.index = fakeId
            childInitData.childName = name
            childInitData.priority = 99
            local openParams = {}
            openParams.tabId = fakeId
            openParams.isTest = true
            childInitData.childOpenParams = openParams
            self.neededChildren[fakeId] = childInitData
            self.targetChildInitMask = self.targetChildInitMask | (1 << fakeId)
            ::continue::
        end
    end

    self.childKeys = {}
    for k, _ in pairs(self.neededChildren) do
        table.insert(self.childKeys, k)
    end

    table.sort(self.childKeys, function(a, b)
        return self.neededChildren[a].priority < self.neededChildren[b].priority
    end)

    self:PostGetNeededChildContent()
end

function BaseUIMediatorWithManualCreateTab:DelayInitContent(delayFrameCount)
    self.delayedInitTimer = TimerUtility.DelayExecuteInFrame(function()
        if self.goLoadMask then
            self.goLoadMask:SetActive(false)
        end
        self:RefreshTabs()
        local openIndex = 1
        if self.selectType then
            openIndex = self.tabId2TableIndex[self.selectType]
        end
        repeat
            if not openIndex then break end
            local childKey = self.childKeys[openIndex]
            if not childKey then break end
            local child = self.neededChildren[childKey]
            if not child then break end
            local id = child.index
            self.tableTabs:SetToggleSelectIndex(openIndex - 1)
            self:OnSelectTab(id, true)
            UIHelper.UIUnlock(self.uiLockData)
            self:OnInitFinish(self.isTimeOut)
            return
        until true
        if self.tableTabs.DataCount > 0 then
            self.tableTabs:SetToggleSelectIndex(0)
            self:OnSelectTab(self.neededChildren[self.childKeys[1]].index, true)
        end
        UIHelper.UIUnlock(self.uiLockData)
        self:OnInitFinish(self.isTimeOut)
    end, delayFrameCount, true)
end

function BaseUIMediatorWithManualCreateTab:RefreshTabs()
    self.tableTabs:Clear()
    for i, key in ipairs(self.childKeys) do
        if self.curChildInitMask & (1 << key) == 0 then
            goto continue
        end
        local child = self.neededChildren[key]
        if child then
            local param = {}
            param.id = child.childOpenParams.tabId
            param.isTest = child.childOpenParams.isTest
            self.tableTabs:AppendData(param)
            self.tabId2TableIndex[child.childOpenParams.tabId] = i
        end
        ::continue::
    end
end

function BaseUIMediatorWithManualCreateTab:OnSelectTab(tabId, isRefresh)
    if tabId == self.selectType and not isRefresh then
        return
    end
    if self.curChildInitMask & (1 << tabId) ~= 0 then
        for id, comp in pairs(self.tabComps) do
            comp:SetVisible(id == tabId)
            if id == tabId then
                comp:FeedData(self.neededChildren[tabId].childOpenParams)
            end
        end
    end
    self.selectType = tabId
    self:PostOnSelectTab(tabId, isRefresh)
end

---@virtual
function BaseUIMediatorWithManualCreateTab:IsTabOpen(tab)
    g_Logger.ErrorChannel('BaseUIMediatorWithManualCreateTab', 'IsTabOpen is not implemented.')
    return true
end

---@virtual
function BaseUIMediatorWithManualCreateTab:UpdateTabOpenState()
end

---@virtual
function BaseUIMediatorWithManualCreateTab:PostGetNeededChildContent()
end

---@virtual
function BaseUIMediatorWithManualCreateTab:PostOnSelectTab(tabId, isRefresh)
end

---@virtual
function BaseUIMediatorWithManualCreateTab:OnInitFinish(isTimeOut)
end

return BaseUIMediatorWithManualCreateTab