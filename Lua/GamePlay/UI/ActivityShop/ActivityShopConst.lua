---@class ActivityShopConst
local ActivityShopConst = {
    PACK_NUM = 5,
    PACK_STATUS = {
        LOCKED = 1,
        UNLOCKED = 2,
    },
    DISCOUNT_TYPE = {
        SMALL = 1,
        NORMAL = 2,
        BIG = 3,
    },
    DISCOUNT_COFF = 100,
    I18N_KEYS = {
        NAME_HUD = 'bundle_center_hub',
        TITLE_DAILY = 'bundle_daily_title',
        DESC_DAILY = 'bundle_daily_desc',
        TIME_DAILY = 'bundle_daily_time_1',
        TIME_DETAIL_DAILY = 'bundle_daily_time_2',
        NAME_DAILY_GIFT = 'bundle_daily_freegift_name',
        CLAIMED_DAILY_GIFT = 'bundle_daily_freegift_claimed',
        LIMIT_TIMES = 'limited_buy_times',
        TITLE_OPTION = 'optional_supply_title',
        DESC_OPTION = 'optional_supply_desc',
        TIME_OPTION = 'optional_supply_time_1',
        TIME_DETAIL_OPTION = 'optional_supply_time_2',
        GUIDE_OPTION = 'optional_supply_guide_title',
        TIPS_TITLE_OPTION = 'optional_supply_chooseitem_title',
        TIPS_ON_NO_CHOOSE = 'optional_supply_tips',
        SOLD_OUT = 'general_sold_out_txt',
        GENERAL_LIMIT_TIMES = 'limited_buy_times',
        CONFIRM = 'general_confirm',
        TITLE_BUY_POP = 'general_buy_window_title',
        GENERAL_LIMIT_TEXT = 'general_buy_times_txt',
        GENERAL_LIMIT_NUM = 'general_buy_times_number',
    },
    NotificationNodeNames = {
        ActivityShopEntry = 'ActivityShopEntry',
        ActivityShopTab = 'ActivityShopTab_',
        ActivityShopPack = 'ActivityShopPack_',
        ActivityShopTabFake = 'ActivityShopTabFake_',
    },
    DALIY_GIFT_PSEUDO_ID = -1,
    DALIY_TAB_ID = 5,
    SYSTEM_ENTRY_ID = 21,
    GROUP_DETAIL_TYPE = {
        HERO = 1,
        PET = 2
    },
    BASE_IMG_QUALITY = {
        'sp_common_base_collect_s_01',
        'sp_common_base_collect_s_01',
        'sp_common_base_collect_s_02',
        'sp_common_base_collect_s_03',
        'sp_common_base_collect_s_04',
    }
}

return ActivityShopConst