local RuntimeDebugSettings = require("RuntimeDebugSettings")
local LoginAccountSetting = {}

function LoginAccountSetting:GetAndSaveAccount()
    local account
    local has, cache = RuntimeDebugSettings:GetOverrideAccountConfig()
    if not has then
        math.newrandomseed()
        local dateTable = os.date("*t")
        account = ("%04d_%02d_%02d_%s"):format(dateTable.year, dateTable.month, dateTable.day, tostring(math.random()):sub(3))
    else
        account = cache
    end
    RuntimeDebugSettings:SetOverrideAccountConfig(account)
    return not has, account
end

function LoginAccountSetting:ClearAccount()
    RuntimeDebugSettings:ClearOverrideAccountConfig()
end

return LoginAccountSetting