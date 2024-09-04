local LocalizationManager = require("LocalizationManager")
local I18N_TEMP = require("I18N_TEMP")
local I18N_PRESET = require("I18N_PRESET")
---@class I18N convenient interface
local I18N = class('I18N')

function I18N.Get(langKey)
    return g_Game.LocalizationManager:Get(langKey);
end

function I18N.GetWithParams(langKey, ...)
    return g_Game.LocalizationManager:GetWithParams(langKey, ...);
end

function I18N.GetWithParamList(langKey,table)
    if table then
        return g_Game.LocalizationManager:GetWithParamList(langKey,table)
    else
        return g_Game.LocalizationManager:Get(langKey);
    end
end

---@return I18N_TEMP
function I18N.Temp()
    return I18N_TEMP
end

---@return I18N_PRESET
function I18N.Preset()
    return I18N_PRESET
end

return I18N