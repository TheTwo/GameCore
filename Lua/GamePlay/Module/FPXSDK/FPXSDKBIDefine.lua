---@class FPXSDKBIDefine
local FPXSDKBIDefine = {}

FPXSDKBIDefine.EventName = {
    alliance_battle = "alliance_battle",
    alliance_notice = "alliance_notice",
    alliance_creat = "alliance_creat",

    chat = "chat",

    adornment_page = "adornment_page",
    activity_notice = "activity_notice",
    activity_entrance = "activity_entrance",
    pet_share = "pet_share",
    strengthen = "strengthen",

    battle_entry_main = "battle_entry_main",
    battle_entry_sub = "battle_entry_sub",
    go_to = "go_to",
    condition_bundle_mediator = "condition_bundle_mediator",

    town_icon_mediator = "town_icon_mediator",
    activity_banner = "activity_banner",
    alliance_info_banner = "alliance_info_banner",
    alliance_battle_mediator = "alliance_battle_mediator",
    guide_step = "guide_step",

    pet_work_ui_click = "pet_work_ui_click",

    troop_add = "troop_add",
    build_pay = "build_pay",

    build_one_click_speed = "build_one_click_speed",
    supply_bubble_click = "supply_bubble_click",
}

FPXSDKBIDefine.ExtraKey = {
    alliance_battle = {
        battle_member_num = "battle_member_num",
        map_instance_id = "map_instance_id",
        alliance_create_date = "alliance_create_date",
        alliance_member_num = "alliance_member_num",
    },
    alliance_notice = {
        notice_text = "notice_text",
        alliance_create_date = "alliance_create_date",
        alliance_member_num = "alliance_member_num",
    },
    alliance_creat = {
        alliance_name = "alliance_name",
        alliance_icon = "alliance_icon",
        alliance_label = "alliance_label",
    },
    chat = {
        type = "type",  ---0=世界聊天频道 1 = 联盟聊天频道 2 = 私聊频道
        id = "id",      ---当联盟聊天时记录联盟id，当私聊时记录与此玩家发生对话的玩家uid
    },
    adornment_page = {
        ador_sub = "ador_sub",  --bool 是否点击进入子界面
        enter_type = "enter_type",  --进入界面方式 0=主界面进入 1=道具跳转
        sub_type = "sub_type",  --子界面类型 0=未进入子界面 1=头像框界面 2=主城皮肤界面 3=称号界面
    },
    activity_notice = {
        activity_id = "activity_id",  --活动id ActivityNoticeConfigCell:Id()
        all_activity_ids = "all_activity_ids",  --所有活动id ActivityNoticeConfigCell:Id()
    },
    activity_entrance = {
        activity_id = "activity_id", --活动id ActivityNoticeConfigCell:Id()
        all_activity_ids = "all_activity_ids",  --所有活动id ActivityNoticeConfigCell:Id()
    },
    pet_share = {
        pet_id = "pet_id",  --宠物唯一id
        pet_type = "pet_type",  --宠物类型
        pet_cfgId = "pet_cfgId",  --宠物配置id
    },
    strengthen = {
        power = "power",  --当前战力
    },
    battle_entry_main = {
        exist_id = "exist_id", -- 此时战役界面内所有玩法id（BattleEntry.csv)
        alliance_id = "alliance_id", -- 当前玩家所在联盟id
    },
    battle_entry_sub = {
        entry_id = "entry_id", -- 玩家所点击的玩法（BattleEntry.csv)
        alliance_id = "alliance_id", -- 当前玩家所在联盟id
    },
    go_to = {
        id = "id", --GotoId
    },
    condition_bundle_mediator = {
        bundle_name = "bundle_name", --礼包组名
        paygoods_name = "paygoods_name", --礼包名
        bundle_include_id = "bundle_include_id", --当前拍脸界面所包含的所有礼包组id
    },
    town_icon_mediator = {
        alliance_id = "alliance_id",
    },
    activity_banner = {
        alliance_id = "alliance_id",
    },
    alliance_info_banner = {
        alliance_id = "alliance_id",
        type = "type", -- 0-乡镇,1-关隘,2-巨兽
    },
    alliance_battle_mediator = {
        type = "type", -- 0-集结,1-攻城,2-活动
        alliance_id = "alliance_id",
    },
    guide_step = {
        id = "id", --GuideStepId
    },
    pet_work_ui_click = {
        type = "type",
        furniture_id = "furniture_id",
        bubble_type = "bubble_type",
    },
    troop_add = {
        troop_id = "troop_id",
        type = "type",
        troop_add_pop = "troop_add_pop",
        troop_add_btn = "troop_add_btn",
    },
    build_pay = {
        IAP_PRODUCT_NAME = "IAP_PRODUCT_NAME",
    },
    build_one_click_speed = {
        type = "type",
        id = "id",
        speed_time = "speed_time",
    },
    supply_bubble_click = {
        troop_id = "troop_id",
        hp_recover = "hp_recover",
        hero_recover = "hero_recover",
        pet_recover = "pet_recover",
        left_hp = "left_hp",
    },
}

return FPXSDKBIDefine