local ActivityAllianceBossConst = {}

local I18N_KEY = {
    TITLE = 'alliance_challengeactivity_title_name',
    TITLE_DESC = 'alliance_challengeactivity_tips_describe',
    LABEL_SELECT_TIME = 'alliance_behemoth_power17',
    LABEL_REGISTERED_COUNT = 'alliance_challengeactivity_title_number',
    LABEL_MY_TROOP = '*我的部队',
    TITLE_INFO = '*玩法说明',
    TITLE_REWARD = 'alliance_behemoth_challenge_gift1',
    LABEL_BOSS = '*出战巨兽',
    LABEL_REWARD = 'alliance_behemoth_challenge_gift1',
    BTN_CANCEL = '*取消',
    TOAST_NO_AUTH = 'alliance_challengeactivity_tips_manageReservation',
    TOAST_TROOP_NO_AUTH = '*R3及以上成员可以参与挑战，其他玩家可观战',
    TOAST_NOT_READY = 'alliance_challengeactivity_tips_application',
    TOAST_NOT_TIME = 'alliance_challengeactivity_tips_notopen',
    TOAST_INSUFF_TROOP = 'alliance_challengeactivity_tips_condition',
    TOAST_BATTLE_END = 'alliance_challengeactivity_state_end',
    CONFIRM_TITLE = 'alliance_challengeactivity_button_reservation',
    CONFIRM_REGISTER_CONTENT = 'alliance_challengeactivity_pop_number',
    REWARD_TITLE_VICTORY = 'alliance_behemoth_challenge_gift2',
    REWARD_TITLE_RANK = 'alliance_behemoth_challenge_gift3',
    REWARD_TITLE_PARTICIPATE = 'alliance_behemoth_challenge_gift4',
    REWARD_TITLE_OBSERVE = 'alliance_behemoth_challenge_gift5',
    REWARD_TITLE_UPGRADE = 'alliance_behemoth_challenge_gift6',
    RULE_CONTENT = "alliance_challengeactivity_rule",
    RULE_TITLE = "alliance_behemothbuild_rule_behemothmain",
    LABEL_TROOPS = "alliance_challengeactivity_title_enroll",
    LABEL_OBSERVE = "*观战人数：",
    LABEL_REGISTERED = "alliance_challengeactivity_title_total",
}

ActivityAllianceBossConst.I18N_KEY = I18N_KEY

local ROLE = {
    R4 = 4,
    R3 = 3,
    NOT_PARTICIPATED = 2,
}

ActivityAllianceBossConst.ROLE = ROLE

local BATTLE_STATE = {
    PREVIEW = 1,
    REGISTER = 2,
    WAITING = 3,
    BATTLE = 4,
    END = 5,
}

ActivityAllianceBossConst.BATTLE_STATE = BATTLE_STATE

local REWARD_TYPE = {
    VICTORY = 1,
    RANK = 2,
    PARTICIPATE = 3,
    OBSERVE = 4,
    UPGRADE = 5,
}

ActivityAllianceBossConst.REWARD_TYPE = REWARD_TYPE

local REWARD_TYPE_NAME = {
    [REWARD_TYPE.VICTORY] = I18N_KEY.REWARD_TITLE_VICTORY,
    [REWARD_TYPE.RANK] = I18N_KEY.REWARD_TITLE_RANK,
    [REWARD_TYPE.PARTICIPATE] = I18N_KEY.REWARD_TITLE_PARTICIPATE,
    [REWARD_TYPE.OBSERVE] = I18N_KEY.REWARD_TITLE_OBSERVE,
    [REWARD_TYPE.UPGRADE] = I18N_KEY.REWARD_TITLE_UPGRADE,
}

ActivityAllianceBossConst.REWARD_TYPE_NAME = REWARD_TYPE_NAME

local REWARD_TYPE_ORDER = {
    REWARD_TYPE.VICTORY,
    REWARD_TYPE.RANK,
    REWARD_TYPE.PARTICIPATE,
    REWARD_TYPE.OBSERVE,
    REWARD_TYPE.UPGRADE,
}

ActivityAllianceBossConst.REWARD_TYPE_ORDER = REWARD_TYPE_ORDER

return ActivityAllianceBossConst