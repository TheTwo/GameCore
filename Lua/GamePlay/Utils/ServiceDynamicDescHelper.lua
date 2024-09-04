local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")

---@class ServiceDynamicDescHelper
local ServiceDynamicDescHelper = sealedClass('ServiceDynamicDescHelper')

---@param i18Key string @I18NKey
---@param paramsCount number
---@param provider table|nil
---@param getter fun(provider:table,index:number):string|fun(index:number):string
---@param stringParams string[]
---@param intParams number[]
---@param floatParams number[]
---@param configParams number[]
---@return string
function ServiceDynamicDescHelper.ParseWithI18N(i18Key, paramsCount, provider, getter
    , stringParams
    , intParams
    , floatParams
    , configParams)
    if string.IsNullOrEmpty(i18Key) then
        return string.Empty
    end
    if paramsCount <= 0 then
        return I18N.Get(i18Key)
    end
    local strIndex = 1
    local intIndex = 1
    local configIndex = 1
    local i18nParameters = {}
    stringParams = stringParams or {}
    intParams = intParams or {}
    floatParams = floatParams or {}
    configParams = configParams or {}
    for i = 1, paramsCount do
        local paramConfig = provider ~= nil and getter(provider, i) or getter(i)
        if paramConfig == "Server@string" then
            table.insert(i18nParameters, stringParams[strIndex])
            strIndex = strIndex + 1
        elseif paramConfig == "Server@int" then
            table.insert(i18nParameters, tostring(math.floor((intParams[intIndex] or 0) + 0.5)))
            intIndex = intIndex + 1
        elseif paramConfig == "Server@float" then
            table.insert(i18nParameters, tostring(floatParams[intIndex] or 0))
            intIndex = intIndex + 1
        elseif string.StartWith(paramConfig, "Config@") then
            local configId = configParams[configIndex]
            configIndex = configIndex + 1
            local configPart = string.sub(paramConfig, 8)
            local configName = configPart
            local configColumnName = string.Empty
            local findPos = string.find(configPart, "%.")
            if findPos then
                configName = string.sub(configPart, 1, findPos - 1)
                configColumnName = string.sub(configPart, findPos + 1)
            end
            if string.IsNullOrEmpty(configColumnName) then
                table.insert(i18nParameters, "nil")
                goto ParseAllianceCurrencyLog_Next_Parameter
            end
            local config = ConfigRefer[configName]
            if not config then
                table.insert(i18nParameters, "nil")
                goto ParseAllianceCurrencyLog_Next_Parameter
            end
            local configCell = config:Find(configId)
            if not configCell then
                table.insert(i18nParameters, "nil")
                goto ParseAllianceCurrencyLog_Next_Parameter
            end
            try_catch(function()
                local valueFunction = configCell[configColumnName]
                local configValue = valueFunction(configCell)
                local i18nContent = I18N.Get(configValue)
                table.insert(i18nParameters, i18nContent)
            end, function()
                table.insert(i18nParameters, "nil")
            end)
        end
        ::ParseAllianceCurrencyLog_Next_Parameter::
    end
    return I18N.GetWithParams(i18Key, table.unpack(i18nParameters))
end

return ServiceDynamicDescHelper