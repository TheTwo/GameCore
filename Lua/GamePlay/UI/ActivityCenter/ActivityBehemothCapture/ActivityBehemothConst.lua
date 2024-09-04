local ActivityBehemothConst = {}

local I18N_KEY = {
    DESC_BUILD = 'alliance_behemothactivity_describe_device',
    DESC_CAPTURE = "alliance_behemothactivity_describe_behemoth",
    TITLE_BUILD = 'alliance_behemothactivity_title_name2',
    TITLE_CAPTURE = "alliance_behemothcage_title_lion",
    LABEL_REWARD = 'alliance_behemothactivity_title_reward',
    LABEL_REWARD_DEVICE = 'alliance_behemothcage_title_buildreward',
    DESC_DEVICE_BUILT = 'alliance_behemothactivity_tips_devicebuild',
    DESC_CAGE_OCCUPIED = 'alliance_behemoth_cage_end',
    BTN_NOT_BUILT = 'alliance_behemothactivity_button_goto',
    BTN_LOCKED = 'alliance_behemoth_button_look',
    BTN_GOTO = 'alliance_challengeactivity_button_goto',
    TIPS_TIME_NOT_REACHED = 'alliance_behemoth_title_readytiem',
    TIPS_AVAILABLE = 'alliance_behemoth_state_capture',
    TIPS_LOCKED = 'alliance_behemoth_tipss1', --'alliance_behemoth_tips_unlock',
    TIPS_INFO = 'alliance_behemothactivity_rule_device2',
    DEVICE_NOT_BUILT = 'alliance_behemoth_notbuild',
    CLAIM_REWARD = 'alliance_behemothcage_button_get',
    TIPS_NEED_ALLIANCE_CENTER = "alliance_behemothactivity_tips_condition"
}

ActivityBehemothConst.I18N_KEY = I18N_KEY

local BOTTOM_CELL_TYPE = {
    DEVICE = 1,
    BEHEMOTH = 2,
}

ActivityBehemothConst.BOTTOM_CELL_TYPE = BOTTOM_CELL_TYPE

local TITLE_I18N_KEY = {
    [BOTTOM_CELL_TYPE.DEVICE] = I18N_KEY.TITLE_BUILD,
    [BOTTOM_CELL_TYPE.BEHEMOTH] = I18N_KEY.TITLE_CAPTURE,
}

ActivityBehemothConst.TITLE_I18N_KEY = TITLE_I18N_KEY

local DESC_I18N_KEY = {
    [BOTTOM_CELL_TYPE.DEVICE] = I18N_KEY.DESC_BUILD,
    [BOTTOM_CELL_TYPE.BEHEMOTH] = I18N_KEY.DESC_CAPTURE,
}

ActivityBehemothConst.DESC_I18N_KEY = DESC_I18N_KEY

ActivityBehemothConst.DEVICE_BG = 'sp_behemoth_base_device_bg'

ActivityBehemothConst.BATTLE_CFG_ID = 1

return ActivityBehemothConst