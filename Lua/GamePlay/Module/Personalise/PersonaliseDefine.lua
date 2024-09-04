local UIHelper = require('UIHelper')

---@class PersonaliseDefine
local PersonaliseDefine = {}

---@class PersonaliseDefine.CASTLE_TYPE
PersonaliseDefine.CASTLE_TYPE = {
    Kingdom = 1,
    City = 2,
}

---@class PersonaliseDefine.QUALITY_COLOR
PersonaliseDefine.QUALITY_COLOR = {
    "#488a02",
    "#4a8ddf",
    "#b259e6",
    "#f9751c",
}

---@class PersonaliseDefine.QUALITY_NAME
PersonaliseDefine.QUALITY_NAME = {
    "skincollection_rarity1",
    "skincollection_rarity2",
    "skincollection_rarity3",
    "skincollection_rarity4",
}

---@class PersonaliseDefine.TITLE_QUALITY_BASE
PersonaliseDefine.TITLE_QUALITY_BASE = {
    "sp_personalis_base_title_2",
    "sp_personalis_base_title_3",
    "sp_personalis_base_title_4",
    "sp_personalis_base_title_5",
}

---@class PersonaliseDefine.TIME_STATUS
PersonaliseDefine.TIME_STATUS = {
    None = 0,
    Locked = 1,
    TimeLimited = 2,
    Forever = 3,
}

---@class PersonaliseDefine.TIME_STATUS_NAME
PersonaliseDefine.TIME_STATUS_NAME = {
    'skincollection_notowned',
    'skincollection_timelimitedforuse',
    'skincollection_ownedpermanently',
}

---@class PersonaliseDefine.BTN_STATUS
PersonaliseDefine.BTN_STATUS = {
    None = 0,
    Using = 1,          --使用中
    CanChange = 2,      --可更换
    CanUnlock = 3,      --可解锁
    CannotUnlock = 4,   --不可解锁
}

PersonaliseDefine.KingdomBaseIcon = "sp_personalise_img_area"
PersonaliseDefine.CityBaseIcon = "sp_personalise_img_area"

PersonaliseDefine.DefaultCastleSkinID = 1000
PersonaliseDefine.DefaultHeadFrameID = 2000
PersonaliseDefine.DefaultTitleID = 3000

PersonaliseDefine.DefaultModelBackgroundConfigID = 40000

PersonaliseDefine.IgnoreAttrTypeID = 1

return PersonaliseDefine