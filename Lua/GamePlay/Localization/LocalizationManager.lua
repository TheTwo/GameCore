local BaseManager = require("BaseManager")
local Logger = require("Logger")
local LanguageSetting = require("LanguageSetting")
local LocalizationConst = require("LocalizationConst")
local rapidJson = require("rapidjson");

local Application = CS.UnityEngine.Application;
local PlayerPrefs = CS.UnityEngine.PlayerPrefs;
local LangValidationHelper = CS.LangValidation.LangValidationHelper
local Dict_Str_Str = CS.System.Collections.Generic.Dictionary(CS.System.String, CS.System.String);

---@class LocalizationManager
---@field new fun():LocalizationManager
---@field private currentLanguage string
---@field private currentCultureInfo CS.System.Globalization.CultureInfo
---@field debugKeyMode boolean
---@field allTerms table<string, string>
local LocalizationManager = class("LocalizationManager", BaseManager)

function LocalizationManager:Initialize()
    ---@private
    ---@type CS.System.Globalization.CultureInfo
    self.fallBackCultureInfo = CS.System.Globalization.CultureInfo("en");
    self.debugKeyMode = PlayerPrefs.GetInt(LocalizationConst.DEBUG_KEY_PREFS, 0) == 1;
    self.currentLanguage = string.Empty;
    self.currentCultureInfo = nil
    self.allTerms = xlua.newtable(self.allTerms, LocalizationConst.INIT_TERMS_CAPACITY);

	self.currentCultureInfo = CS.System.Globalization.CultureInfo.CurrentCulture
	self.currentUICultureInfo = CS.System.Globalization.CultureInfo.CurrentUICulture
end

function LocalizationManager:Reset()
    self:Clear();
end

function LocalizationManager:GetCurrentLanguageIsoCode()
	return self.currentCultureInfo and self.currentCultureInfo.TwoLetterISOLanguageName
end

--Current Language
---@return string
function LocalizationManager:GetCurrentLanguage()
    if self.currentLanguage == string.Empty then
		local userLanguage = g_Game.PlayerPrefsEx:GetString('userLanguage',self:GetSystemLanguage());
        self:SetCurrentLanguage(userLanguage);
    end
    return self.currentLanguage;
end

---@param language string language type
function LocalizationManager:SetCurrentLanguage(language)
    self.currentLanguage = language;
    self:SetupCultureInfoFromLanguage(language)
end

function LocalizationManager:SetupCultureInfoFromLanguage(language)
    local bcp47Code = (not string.IsNullOrEmpty(language)) and LanguageSetting.bcp47CodeMap[language] or nil
    if not bcp47Code then
        self.currentCultureInfo = self.fallBackCultureInfo
        return
    end
    try_catch(function()
        self.currentCultureInfo = CS.System.Globalization.CultureInfo(bcp47Code)
    end, function()
        self.currentCultureInfo = self.fallBackCultureInfo
    end)
end

---@return string system language
function LocalizationManager:GetSystemLanguage()
     local systemLanguage = Application.systemLanguage;
     local result;
     for i = 1, #LanguageSetting.languages do
         local lang = LanguageSetting.languages[i];
         if lang.language == systemLanguage then
             result = lang.locale;
         end
     end
     if result == nil then
         result = LocalizationConst.DEFAULT_LANG;
     end
     return result;
end

function LocalizationManager:GetCultureInfo()
    if not self.currentCultureInfo then
        self:SetupCultureInfoFromLanguage(self.currentLanguage)
    end
    return self.currentCultureInfo
end

---@return table all localizations
function LocalizationManager:GetAllLanguages()
    return LanguageSetting.localization;
end

--Reload

---@param lang string
---@param isLoading boolean
function LocalizationManager:Reload(lang, isLoading)
    local path = self:GetSourcePath(lang, isLoading);
    local termsText
    if UNITY_EDITOR then
        termsText =  IOUtilsWrap.ReadGameAssetAsText(path)
    else
        termsText =  IOUtilsWrap.ReadGameAssetAsText(path, CS.DragonReborn.IOUtils.HasEncryptTag())
    end
    if string.IsNullOrEmpty(termsText) then
        Logger.Error("can't find language file in path " .. path);
        return
    end
    local terms = rapidJson.decode(termsText);

    for k, v in pairs(terms) do
        self.allTerms[k] = v;
    end
    
    --g_Game.EventManager:TriggerEvent(EventConst.LOCALIZATION_LANG_RELOADED, 
    --{
    --    lang = lang,
    --    isLoading = isLoading,
    --})
end

function LocalizationManager:Clear()
    self.allTerms = {};
end

---@param lang string
---@param isLoading boolean
---@return string path
function LocalizationManager:GetSourcePath(lang, isLoading)
    local basePath = LocalizationConst.PATH_RELATIVEPATH--//fromStreamingFolder and LocalizationConst.BASE_STREAMING_PATH or LocalizationConst.BASE_PERSISTENT_PATH;
    local phaseType = isLoading and "Loading" or "InGame";
    if UNITY_EDITOR then
        return string.format("%s/%s/language_%s.json", basePath, phaseType, lang);
    else
        return string.format("%s/%s/language_%s.jsonb", basePath, phaseType, lang);
    end
end

--Get Lang By Key
---@param langKey string
---@param doRecord boolean only for LangValidation recording
---@return string
function LocalizationManager:Get(langKey, doRecord)
    if self.debugKeyMode then
        return langKey;
    end

    if not self.allTerms then
        g_Logger.Error('LocalizationManager not ready!!!')
        return langKey
    end
    
    if self.allTerms[langKey] then
        local content = self.allTerms[langKey];
        if UNITY_DEBUG and doRecord == nil then
            self:LangValidationCache(content, langKey, nil);
        end
        return content;
    end
    return langKey;
end

---@param langKey string
---@return string
function LocalizationManager:GetWithParams(langKey, ...)    
    local params = table.pack(...);
    return self:InternalGetWithParam(langKey,params, params.n);
end


---@param langKey string
---@param paramList list
---@return string
function LocalizationManager:GetWithParamList(langKey, paramList)
    return self:InternalGetWithParam(langKey,paramList, #paramList);
end
---private
---@param langKey string
---@param paramList list
---@param length number @Length of paramList
---@return string
function LocalizationManager:InternalGetWithParam(langKey,paramList,length)
    local content = self:Get(langKey, true);
    if content == string.Empty or self.debugKeyMode then
        return content;
    end
        
    if paramList == nil or length < 1 then
        return content;
    end
    
    for index = 1, length do        
        content = string.gsub(
            content, 
            string.format('{%d}',index), 
            paramList[index] or string.Empty)        
    end

    if UNITY_DEBUG then
        self:LangValidationCache(content, langKey, paramList);
    end
    
    return content;
end

--Debug

---@return boolean is key mode?
function LocalizationManager:GetDebugKeyMode()
    return self.debugKeyMode;
end

---@param state boolean
function LocalizationManager:SetDebugKeyMode(state)
    if UNITY_DEBUG then
        self.debugKeyMode = state;
        PlayerPrefs.SetInt(LocalizationConst.DEBUG_KEY_PREFS, self.debugKeyMode and 1 or 0);
    end
end


---@param content string
---@param key string
---@param param list
function LocalizationManager:LangValidationCache(content, key, params)
    local dict = Dict_Str_Str();
    if params ~= nil then
        for index = 1, #params, 2 do
            local k = params[index];
            local v = params[index + 1];
            if k ~= nil then
                v = v or string.Empty;
                if not dict:ContainsKey(k) then
                    dict:Add(k, v);
                end
            end
        end
    end
    LangValidationHelper.LangValidationCacheKeyParameter(content, key, dict);
end

return LocalizationManager;
