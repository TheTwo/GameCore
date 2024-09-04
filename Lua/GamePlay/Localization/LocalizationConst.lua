local Application = CS.UnityEngine.Application;

local LocalizationConst = 
{
    INIT_TERMS_CAPACITY = 15000,
    LANGUAGE_PREFS = "SSR_LANG",
    DEBUG_KEY_PREFS = "LANG_DEBUG",
    DEFAULT_LANG = "en",
    LANG_ZH_CN = 'zh-CN',
    BASE_STREAMING_PATH = Application.streamingAssetsPath .. "/GameAssets/Languages",
    BASE_PERSISTENT_PATH = Application.persistentDataPath .. "/GameAssets/Languages",
    PATH_RELATIVEPATH = "GameAssets/Languages",
}

return LocalizationConst;