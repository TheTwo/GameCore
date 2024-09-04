local RuntimeDebugSettingsKeyDefine = require("RuntimeDebugSettingsKeyDefine")
local UnityEngine = CS.UnityEngine
local PlayerPrefs = UnityEngine.PlayerPrefs
---@type DeviceUtil
local DeviceUtil = require('DeviceUtil')

---@class GMPanelRuntimeDebugSettings
local RuntimeDebugSettings = class('RuntimeDebugSettings')
RuntimeDebugSettings.KEY_STORE = "Debug_RuntimeDebugSettings_KEY_STORE"

RuntimeDebugSettings.FPS_MODE_60 = 1
RuntimeDebugSettings.FPS_MODE_30 = 2
RuntimeDebugSettings.FPS_MODE_dynamic = 3
RuntimeDebugSettings.FPS_MODE_off = 0

RuntimeDebugSettings.CFG_SERVER_CMD_PORT = 9868

function RuntimeDebugSettings:ctor()
    self.allKeys = {}
    table.clear(self.allKeys)
    local storedKeys = PlayerPrefs.GetString(RuntimeDebugSettings.KEY_STORE, "")
    if not string.IsNullOrEmpty(storedKeys) then
        local array = string.split(storedKeys, ';')
        table.sort(array)
        for _,v in ipairs(array) do
            table.insert(self.allKeys, v)
        end
    end
end

function RuntimeDebugSettings:GetAllKeys(ret)
    for _,v in ipairs(self.allKeys) do
        table.insert(ret, v)
    end
end

---@param key string
---@return boolean,string
function RuntimeDebugSettings:GetString(key)
    self:CheckKey(key)
    if not table.ContainsValue(self.allKeys, key) then
        return false, string.Empty
    end
    return true, PlayerPrefs.GetString(key)
end

---@param key string
---@return boolean, number | "Integer"
function RuntimeDebugSettings:GetInt(key)
    self:CheckKey(key)
    if not table.ContainsValue(self.allKeys, key) then
        return false, 0
    end
    return true, PlayerPrefs.GetInt(key)
end

---@param key string
---@return boolean, number | "Float"
function RuntimeDebugSettings:GetFloat(key)
    self:CheckKey(key)
    if not table.ContainsValue(self.allKeys, key) then
        return false, 0.0
    end
    return true, PlayerPrefs.GetFloat(key)
end

---@param key string
---@param v string
function RuntimeDebugSettings:SetString(key, v)
    self:CheckKey(key)
    if not table.ContainsValue(self.allKeys, key) then
        table.insert(self.allKeys, key)
        self:SaveKeys()
    end
    PlayerPrefs.SetString(key, v)
end

---@param key string
---@param v number | "Integer"
function RuntimeDebugSettings:SetInt(key, v)
    self:CheckKey(key)
    if not table.ContainsValue(self.allKeys, key) then
        table.insert(self.allKeys, key)
        self:SaveKeys()
    end
    PlayerPrefs.SetInt(key, v)
end

---@param key string
---@param v number | "Float"
function RuntimeDebugSettings:SetFloat(key, v)
    self:CheckKey(key)
    if not table.ContainsValue(self.allKeys, key) then
        table.insert(self.allKeys, key)
        self:SaveKeys()
    end
    PlayerPrefs.SetFloat(key, v);
end

---@param key string
function RuntimeDebugSettings:Delete(key)
    self:CheckKey(key)
    local removeIndex = table.removebyvalue(self.allKeys, key)
    if removeIndex ~= 0 then
        PlayerPrefs.DeleteKey(key)
        self:SaveKeys()
    end
end

---@param key string
function RuntimeDebugSettings:CheckKey(key)
    if type(key) == "string" then
        return true
    end
    error("key:" .. tostring(key) .. "is not string!")
    return false
end

function RuntimeDebugSettings:SaveKeys()
    table.sort(self.allKeys)
    PlayerPrefs.SetString(RuntimeDebugSettings.KEY_STORE, table.concat(self.allKeys,';'))
end

function RuntimeDebugSettings:CleanUpAll()
    if #self.allKeys > 0 then
        for _, i in ipairs(self.allKeys) do
            PlayerPrefs.DeleteKey(i)
        end
        table.clear(self.allKeys)
        PlayerPrefs.DeleteKey(RuntimeDebugSettings.KEY_STORE)
    end
end

---@return boolean,string,number,string,string
function RuntimeDebugSettings:GetOverrideServerConfig()
    local has,str = self:GetString(RuntimeDebugSettingsKeyDefine.DebugOverrideServer)
    if has then
        local sp = string.split(str, ';')
        if #sp > 2 then
            return true, sp[1], tonumber(sp[2]), sp[3], sp[4], sp[5] or string.Empty
        end
    end
    return false, string.Empty, 0, string.Empty, string.Empty, string.Empty
end

function RuntimeDebugSettings:SetOverrideServerConfig(ip, port, name, id, gmPage)
    local save = {[1] = ip, [2] = tostring(port), [3] = name, [4] = id, [5] = gmPage}
    self:SetString(RuntimeDebugSettingsKeyDefine.DebugOverrideServer, table.concat(save, ';'))
end

function RuntimeDebugSettings:ClearOverrideServerConfig()
    self:Delete(RuntimeDebugSettingsKeyDefine.DebugOverrideServer)
end

---@return boolean,string
function RuntimeDebugSettings:GetOverrideAccountConfig()
    return self:GetString(RuntimeDebugSettingsKeyDefine.DebugOverrideAccount)
end

function RuntimeDebugSettings:SetOverrideAccountConfig(account)
    self:SetString(RuntimeDebugSettingsKeyDefine.DebugOverrideAccount, account)
end

function RuntimeDebugSettings:GetHistoryAccountConfig()
    return self:GetString(RuntimeDebugSettingsKeyDefine.DebugHistoryAccount)
end

function RuntimeDebugSettings:SetHistoryAccountConfig(list)
    self:SetString(RuntimeDebugSettingsKeyDefine.DebugHistoryAccount, table.concat(list, "\n"))
end

function RuntimeDebugSettings:ClearOverrideAccountConfig()
    self:Delete(RuntimeDebugSettingsKeyDefine.DebugOverrideAccount)
end

function RuntimeDebugSettings:GetOverrideToken()
    return self:GetString(RuntimeDebugSettingsKeyDefine.DebugOverrideToken)
end

function RuntimeDebugSettings:SetOverrideToken(token)
    self:SetString(RuntimeDebugSettingsKeyDefine.DebugOverrideToken, token)
end

function RuntimeDebugSettings:ClearOverrideToken()
    self:Delete(RuntimeDebugSettingsKeyDefine.DebugOverrideToken)
end

---@return boolean,number
function RuntimeDebugSettings:GetDeviceLevel()
    return self:GetInt(RuntimeDebugSettingsKeyDefine.DebugDeviceLevel)
end

function RuntimeDebugSettings:SetDeviceLevel(level)
    self:SetInt(RuntimeDebugSettingsKeyDefine.DebugDeviceLevel, level)
end

function RuntimeDebugSettings:ClearDeviceLevel()
    self:Delete(RuntimeDebugSettingsKeyDefine.DebugDeviceLevel)
end

function RuntimeDebugSettings:IsLowMemoryDevice()
	local has, value = self:GetInt(RuntimeDebugSettingsKeyDefine.DebugLowMemoryDevice)
	if has then
		return value == 1
	else
		return DeviceUtil.IsLowMemoryDevice()
	end
end

function RuntimeDebugSettings:SetLowMemoryDevice(flag)
	self:SetInt(RuntimeDebugSettingsKeyDefine.DebugLowMemoryDevice, flag and 1 or 0)
end

function RuntimeDebugSettings:ResetLowMemoryDevice()
	self:Delete(RuntimeDebugSettingsKeyDefine.DebugLowMemoryDevice)
end

---@return boolean,string,string
function RuntimeDebugSettings:GetPandaConnection()
	local hostHas,host = self:GetString(RuntimeDebugSettingsKeyDefine.DebugPandaConnection .. "_HOST")
	local portHas,port = self:GetString(RuntimeDebugSettingsKeyDefine.DebugPandaConnection .. "_PORT")
	return hostHas and portHas, host, port
end

function RuntimeDebugSettings:SetPandaConnection(host, port)
	self:SetString(RuntimeDebugSettingsKeyDefine.DebugPandaConnection .. "_HOST", host)
	self:SetString(RuntimeDebugSettingsKeyDefine.DebugPandaConnection .. "_PORT", port)
end

function RuntimeDebugSettings:GetConnectionType()
	return self:GetInt(RuntimeDebugSettingsKeyDefine.DebugConnectionType)
end

function RuntimeDebugSettings:SetConnectionType(value)
	self:SetInt(RuntimeDebugSettingsKeyDefine.DebugConnectionType, value)
end

function RuntimeDebugSettings:GetMcpPreferTCP()
	return self:GetInt(RuntimeDebugSettingsKeyDefine.DebugMcpPreferTcp)
end

function RuntimeDebugSettings:SetMcpPreferTCP(flag)
	self:SetInt(RuntimeDebugSettingsKeyDefine.DebugMcpPreferTcp, flag and 1 or 0)
end

function RuntimeDebugSettings:GetKcpLogEnabled()
	return self:GetInt(RuntimeDebugSettingsKeyDefine.DebugKcpLogEnabled)
end

function RuntimeDebugSettings:SetKcpLogEnabled(flag)
	self:SetInt(RuntimeDebugSettingsKeyDefine.DebugKcpLogEnabled, flag and 1 or 0)
end

function RuntimeDebugSettings:GetCloudScreenFaseMode()
    local has, value = self:GetInt(RuntimeDebugSettingsKeyDefine.DebugCloudScreenFastMode)
    if not has then return false end
    return value == 1
end

function RuntimeDebugSettings:SetCloudScreenFaseMode(faseModeOn)
    self:SetInt(RuntimeDebugSettingsKeyDefine.DebugCloudScreenFastMode, faseModeOn and 1 or 0)
end

RuntimeDebugSettings.Instance = RuntimeDebugSettings.Instance or RuntimeDebugSettings.new()
return RuntimeDebugSettings.Instance
