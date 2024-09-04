local SystemLanguage = CS.UnityEngine.SystemLanguage

local LanguageSetting = 
{
    languages = 
    {
        --{
        --    locale = "ar",
        --    language = SystemLanguage.Arabic
        --},
        {
            locale = "zh-CN",
            language = SystemLanguage.ChineseSimplified
        },
        {
            locale = "zh-CN",
            language = SystemLanguage.Chinese
        },
        --{
        --    locale = "zh-TW",
        --    language = SystemLanguage.ChineseTraditional
        --},
        --{
        --    locale = "nl",
        --    language = SystemLanguage.Dutch
        --},
        {
            locale = "en",
            language = SystemLanguage.English
        },
        {
            locale = "fr",
            language = SystemLanguage.French
        },
        {
            locale = "de",
            language = SystemLanguage.German
        },
--[[        {
            locale = "id",
            language = SystemLanguage.Indonesian
        },]]
        --{
        --    locale = "it",
        --    language = SystemLanguage.Italian
        --},
        --{
        --    locale = "ja",
        --    language = SystemLanguage.Japanese
        --},
        --{
        --    locale = "ko",
        --    language = SystemLanguage.Korean
        --},
        --{
        --    locale = "no",
        --    language = SystemLanguage.Norwegian
        --},
        --{
        --    locale = "pl",
        --    language = SystemLanguage.Polish
        --},
        --{
        --    locale = "pt",
        --    language = SystemLanguage.Portuguese
        --},
        --{
        --    locale = "ru",
        --    language = SystemLanguage.Russian
        --},
        --{
        --    locale = "es",
        --    language = SystemLanguage.Spanish
        --},
        --{
        --    locale = "sv",
        --    language = SystemLanguage.Swedish
        --},
        --{
        --    locale = "th",
        --    language = SystemLanguage.Thai
        --},
        --{
        --    locale = "tr",
        --    language = SystemLanguage.Turkish
        --},
        --{
        --    locale = "el",
        --    language = SystemLanguage.Greek
        --},
        --{
        --    locale = "vi",
        --    language = SystemLanguage.Vietnamese
        --},
        --{
        --    locale = "tl",
        --    language = SystemLanguage.Unknown,
        --    overrideBCP47Code = "en",
        --},
        --{
        --    locale = "my",
        --    language = SystemLanguage.Unknown,
        --    overrideBCP47Code = "en",
        --}
    },
    localization = 
    {
        --"en",
        --"ru",
        --"de",
        --"fr",
        --"ko",
        --"ja",
        --"it",
        --"zh-TW",
        --"pl",
        --"pt",
        --"nl",
        --"id",
        --"th",
        --"sv",
        --"es",
        --"tr",
        --"vi",
        --"ar",
        --"my"
        "en",
        "zh-CN",
        "ar",
    },
    translator = 
    {
        "en",
        "fr",
        "ru",
        "de",
        "it",
        "ja",
        "ko",
        "id",
        "pl",
        "pt",
        "nl",
        "es",
        "th",
        "tr",
        "no",
        "sv",
        "zh-CN",
        "zh-TW",
        "el",
        "vi",
        "tl",
        "ar",
        "ms"
    },
    ---@type table<string, string>
    bcp47CodeMap = {}
}

for _, v in pairs(LanguageSetting.languages) do
    local bcp47Code = v.locale
    if v.overrideBCP47Code then
        bcp47Code = v.overrideBCP47Code
    end
    LanguageSetting.bcp47CodeMap[v.locale] = bcp47Code
    ---check locale code is valid
    --try_catch(
    --    function()
    --        local info = CS.System.Globalization.CultureInfo(bcp47Code)
    --        v.cultureInfo = info
    --        g_Logger.Log("test pass:culture Info:locale:%s=>%s", v.locale, tostring(info))
    --    end,
    --    function(e)
    --        g_Logger.Error("failed on:%s", v.locale)
    --    end
    --)
end

return LanguageSetting
