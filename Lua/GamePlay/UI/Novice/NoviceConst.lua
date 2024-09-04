local NewFunctionUnlockIdDefine = require("NewFunctionUnlockIdDefine")

local NoviceConst = {
    MAX_DAY = 5,
    RewardStatus = {
        locked = 1,
        claimed = 2,
    },
    ActivityId = 1,
    RewardType = {
        Normal = 1,
        High = 2,
    },
    SpecialRewardFurnitureIndex = 2,
    SpecialRewardHeroIndex = 3,
    SpecialRewardPetIndex = 5,
    ScoreItemId = 125,
    NoviceNotificationNodeNames = {
        NoviceEntry = 'NoviceEntry',
        NoviceDayTab = 'NoviceDayTab_',
        NoviceReward = 'NoviceReward_',
        NovicePopupBtn = 'NovicePopupBtn',
    },
    I18NKeys = {
        TITLE = 'survival_rules_title',
        HUD_TITLE = 'survival_rules_title_hub',
        TIME = 'survival_rules_time',
        TABS = {
            'survival_rules_day1_tab',
            'survival_rules_day2_tab',
            'survival_rules_day3_tab',
            'survival_rules_day4_tab',
            'survival_rules_day5_tab',
        },
        TASK_TITLES = {
            'survival_rules_day1_title',
            'survival_rules_day2_title',
            'survival_rules_day3_title',
            'survival_rules_day4_title',
            'survival_rules_day5_title',
        },
        REWARD_UNCLAIM = 'survival_rules_reward_show_txt_unclaim',
        REWARD_CLAIMED = 'survival_rules_reward_show_txt_claimed',
        REWARD_TIP = 'survival_rules_stage_reward_txt',
        TAB_LOCK_TIP = 'survival_rules_day_unlock_tips',
        REWARD_TITLE = 'survival_rules_box_tips_title',
        BTN_CLAIM = 'survival_rules_task_claim',
        BTN_GOTO = 'survival_rules_task_goto',
        BTN_DETAIL = 'first_pay_hero_goto'
    },
    HERO_SYSTEM_ID = NewFunctionUnlockIdDefine.Global_hero,
    PET_SYSTEM_ID = NewFunctionUnlockIdDefine.Global_pet,
    SYS_SWITCH_ID = NewFunctionUnlockIdDefine.Global_survivals_rules,
    MaxSubTabCount = 3,
}

return NoviceConst