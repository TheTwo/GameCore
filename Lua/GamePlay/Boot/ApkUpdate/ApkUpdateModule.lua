local BaseModule = require ('BaseModule')
local I18N = require("I18N")

---@class ApkUpdateModule:BaseModule
local ApkUpdateModule = class('ApkUpdateModule', BaseModule)

function ApkUpdateModule:OnRegister()
    
end

function ApkUpdateModule:OnRemove()
    self.manifest = nil
end

function ApkUpdateModule:CacheManifest(manifest)
    self.manifest = manifest
end

function ApkUpdateModule:MustUpdateApk()
    return self.manifest and self.manifest['upgrade_info'] and self.manifest['upgrade_info']['type'] == 3
end

function ApkUpdateModule:CanUpdateApk()
    return self.manifest and self.manifest['upgrade_info'] and self.manifest['upgrade_info']['type'] == 2
end

function ApkUpdateModule:UrlTo()
    if self.manifest and self.manifest['upgrade_info'] and self.manifest['upgrade_info']['upgrade_url'] then
        CS.UnityEngine.Application.OpenURL(fix_url(self.manifest['upgrade_info']['upgrade_url']))
    end
end

function ApkUpdateModule:CheckApkNeedUpdate()
    return self:MustUpdateApk() or self:CanUpdateApk()
end

function ApkUpdateModule:ShowApkUpdateUI(onCancelCallback)
    if self:MustUpdateApk() then
        self:ShowApkMustUpdateUI(onCancelCallback)
    elseif self:CanUpdateApk() then
        self:ShowApkCanUpdateUI(onCancelCallback)
    end
end

function ApkUpdateModule:ShowApkMustUpdateUI(onCancelCallback)
    ---@type SystemCommonPopupUIData
    local data = {
        styleBitMask = 6,
        content = I18N.Get("notify_version_update_goto_store01"),
        onConfirm = function()
            self:UrlTo()
        end,
        onCancel = function()
            if onCancelCallback then onCancelCallback() end
            CS.UnityEngine.Application.Quit()
        end,
    }
    g_Game.UIManager:Open("SystemCommonPopupUIMediator", data)
end

function ApkUpdateModule:ShowApkCanUpdateUI(onCancelCallback)
    ---@type SystemCommonPopupUIData
    local data = {
        styleBitMask = 7,
        content = I18N.Get("notify_version_update_goto_store02"),
        onConfirm = function()
            self:UrlTo()
        end,
        onCancel = function()
            if onCancelCallback then onCancelCallback() end
            return true
        end,
        onClose = function()
            if onCancelCallback then onCancelCallback() end
            return true
        end,
    }
    g_Game.UIManager:Open("SystemCommonPopupUIMediator", data)
end

return ApkUpdateModule