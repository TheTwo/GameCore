local UseLimitType = require("UseLimitType")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
---@class FunctionalItemDataProvider -- todo 继承一个BaseItemDataProvider, 如有必要
local FunctionalItemDataProvider = class("FunctionalItemDataProvider")

---@param itemCfg ItemConfigCell
function FunctionalItemDataProvider:ctor(itemCfg)
    self.itemCfgId = itemCfg:Id()
    self.uid = ModuleRefer.InventoryModule:GetUidByConfigId(self.itemCfgId)
    self.itemCfg = itemCfg
end

function FunctionalItemDataProvider:GetFunctionClass()
    return self.itemCfg:FunctionClass()
end

---virtual
function FunctionalItemDataProvider:CanUse()
    return false
end

function FunctionalItemDataProvider:GetUseText()
    return self.itemCfg:UseDesc()
end

---@return string
function FunctionalItemDataProvider:GetUnusableHint()
    if self.itemCfg:UseLimitType() == UseLimitType.UnlockSystem then
        local sysEntryId = self.itemCfg:UseLimitParam()
        if sysEntryId > 0 then
            local sysEntryCfg = ConfigRefer.SystemEntry:Find(sysEntryId)
            if sysEntryCfg then
                return sysEntryCfg:LockedTips()
            end
        end
    end
    return string.Empty
end

---virtual
---@param usageNum number
---@param callback fun()
function FunctionalItemDataProvider:Use(usageNum, callback)
    g_Logger.ErrorChannel("FunctionalItemDataProvider", "The virtual method 'Use' is not implemented.")
end

---@protected
function FunctionalItemDataProvider:DefaultUseChecker()
    if self.itemCfg:UseLimitType() == UseLimitType.UnlockSystem then
        local sysEntryId = self.itemCfg:UseLimitParam()
        if sysEntryId > 0 then
            return ModuleRefer.NewFunctionUnlockModule:CheckNewFunctionIsUnlocked(sysEntryId)
        end
    end
    return true
end

return FunctionalItemDataProvider