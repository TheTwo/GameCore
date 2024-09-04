local UIMediatorNames = require('UIMediatorNames')
local BaseModule = require("BaseModule")
local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")
local Delegate = require("Delegate")
local I18N = require("I18N")
local EventConst = require("EventConst")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local Utils = require("Utils")
local GuideUtils = require("GuideUtils")
local SystemEntryLockedPerformanceType = require("SystemEntryLockedPerformanceType")
local SystemEntryScopeType = require("SystemEntryScopeType")

---@class NewFunctionUnlockModule : BaseModule
local NewFunctionUnlockModule = class('NewFunctionUnlockModule', BaseModule)

function NewFunctionUnlockModule:ctor()
end

function NewFunctionUnlockModule:OnRegister()
    self.newFunctionList = {}
    self.unlockedNewFunction = {}
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.SystemEntry.OpenSystems.MsgPath,Delegate.GetOrCreate(self,self.RefreshNewFunction))
end

function NewFunctionUnlockModule:OnRemove()
    self:ClearNewFunctionList()
    self.unlockedNewFunction = {}
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.SystemEntry.OpenSystems.MsgPath,Delegate.GetOrCreate(self,self.RefreshNewFunction))
end

function NewFunctionUnlockModule:RefreshNewFunction(_, changedData)
    if not changedData.Add then
        return
    end
    ---@type table<number, wds.boolean>
    local newFunctions = changedData.Add
    local newFunctionList = {}
    for k, v in pairs(newFunctions) do
        -- --已解锁，则跳过
        -- if self.unlockedNewFunction[k] then
        --     goto continue
        -- end
        self.unlockedNewFunction[k] = true
        newFunctionList[#newFunctionList + 1] = k
        -- ::continue::
    end

    --根据优先级排序
    if #newFunctionList > 1 then
        table.sort(newFunctionList, function(l, r)
            local l_cfg = ConfigRefer.SystemEntry:Find(l)
            local r_cfg = ConfigRefer.SystemEntry:Find(r)
            return l_cfg:PopTipsPriority() < r_cfg:PopTipsPriority()
        end)
    end

    for i = 1, #newFunctionList do
        self:UnlockNewFunction(newFunctionList[i])
    end
    g_Game.EventManager:TriggerEvent(EventConst.SYSTEM_ENTRY_OPEN, newFunctionList)
end

function NewFunctionUnlockModule:AddToNewFunctionList(id, btnGO)
    if not btnGO then
        return
    end
    if not self.newFunctionList then
        self.newFunctionList = {}
    end
    local cfg = ConfigRefer.SystemEntry:Find(id)
    if not cfg then
        return
    end
    if not self.newFunctionList[id] then
        self.newFunctionList[id] = btnGO
    end
    local isHide = cfg:LockedPerformance() == SystemEntryLockedPerformanceType.Hide
    if self:CheckNewFunctionIsUnlocked(id) then
        if isHide then
            btnGO:SetActive(true)
        else
            --TODO 解锁按钮
        end
    else
        -- if isHide then
        --     btnGO:SetActive(false)
        -- else
        --     btnGO:SetActive(true)
        --     --TODO 上锁
        -- end
    end
end

function NewFunctionUnlockModule:ClearNewFunctionList()
    self.newFunctionList = {}
end

function NewFunctionUnlockModule:UnlockNewFunction(id)
    local cfg = ConfigRefer.SystemEntry:Find(id)
    if not cfg then
        return
    end
    if cfg:PopAnimation() then
        g_Game.UIManager:Open(UIMediatorNames.NewFunctionUnlockMediator, {FunctionId = id})
    else
        local guideCallId = cfg:GuideOnClose()
        if guideCallId > 0 then
            local guideCall = ConfigRefer.GuideCall:Find(guideCallId)
            if not guideCall then
                g_Logger.Error("UnlockNewFunction FunctionID:%s, GuideCallId:%s, GuideCall config is nil", id, guideCallId)
                return
            end
            GuideUtils.GotoByGuide(guideCallId)
        end
    end
end

function NewFunctionUnlockModule:ShowUnlockNewFunction(id)
    if not self.unlockedNewFunction[id] then
        return
    end
    local cfg = ConfigRefer.SystemEntry:Find(id)
    if not cfg then
        return
    end
    local btnGO = self.newFunctionList[id]
    if cfg:LockedPerformance() == SystemEntryLockedPerformanceType.Locked and Utils.IsNotNull(btnGO) then
        --TODO 解锁动画
    elseif cfg:LockedPerformance() == SystemEntryLockedPerformanceType.Hide and Utils.IsNotNull(btnGO)  then
        btnGO:SetActive(true)
    else
        --TODO 其他表现
    end
    local guideCallId = cfg:GuideOnClose()
    if guideCallId > 0 then
        local guideCall = ConfigRefer.GuideCall:Find(guideCallId)
        if not guideCall then
            g_Logger.Error("ShowUnlockNewFunction FunctionID:%s, GuideCallId:%s, GuideCall config is nil", id, guideCallId)
            return
        end
        GuideUtils.GotoByGuide(guideCallId)
    end
end

function NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(id)
    local config = ConfigRefer.SystemEntry:Find(id)
    if config and config:ScopeType() == SystemEntryScopeType.Kingdom then
        return ModuleRefer.KingdomModule:IsSystemOpen(id)
    end
    local versionCheck = false
    if config then
        versionCheck = ModuleRefer.AppInfoModule:IsCSharpVersionMatch(config:CSharpVersion())
    end

    local player = ModuleRefer.PlayerModule:GetPlayer()
    if not player or not player.PlayerWrapper2 or not player.PlayerWrapper2.SystemEntry then
        return false, versionCheck
    end
    local openSystems = player.PlayerWrapper2.SystemEntry.OpenSystems
    if not openSystems then
        return false, versionCheck
    end
    if openSystems[id] then
        if not self.unlockedNewFunction[id] then
            self.unlockedNewFunction[id] = true
        end
        return true, versionCheck
    end
    return false, versionCheck
end

---@return string
function NewFunctionUnlockModule:BuildLockedTip(id)
    local config = ConfigRefer.SystemEntry:Find(id)
    if config then
        local tipI18n = config:LockedTips()
        if not string.IsNullOrEmpty(tipI18n) then
            local params = config:LockedTipsPrm()
            if string.IsNullOrEmpty(params) then
                return I18N.Get(config:LockedTips())
            else
                return I18N.GetWithParams(config:LockedTips(), params)
            end
        end
    end
    return string.Empty
end

---@return boolean
function NewFunctionUnlockModule:ShowLockedTipToast(id)
    local config = ConfigRefer.SystemEntry:Find(id)
    if config then
        local tipI18n = config:LockedTips()
        if not string.IsNullOrEmpty(tipI18n) then
            local params = config:LockedTipsPrm()
            if string.IsNullOrEmpty(params) then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(config:LockedTips()))
            else
                ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams(config:LockedTips(), params))
            end
            return true
        end
    end
    return false
end

local UI2SystemId = {
    [UIMediatorNames.HeroCardMediator] = NewFunctionUnlockIdDefine.Global_gacha,
    [UIMediatorNames.HuntingMainMediator] = NewFunctionUnlockIdDefine.Hunting,
    [UIMediatorNames.ReplicaPVPMainMediator] = NewFunctionUnlockIdDefine.Pvp,
    [UIMediatorNames.RadarMediator] = NewFunctionUnlockIdDefine.CityRadar,
}

---@return boolean
function NewFunctionUnlockModule:CheckUIMediatorIsOpen(mediatorName)
    local sysId = UI2SystemId[mediatorName]
    if not sysId then
        return true
    end
    local cfg = ConfigRefer.SystemEntry:Find(sysId)
    if not cfg then
        return true
    end
    if not self:CheckNewFunctionIsUnlocked(sysId) then
        self:ShowLockedTipToast(sysId)
        return false
    end
    return true
end

return NewFunctionUnlockModule
