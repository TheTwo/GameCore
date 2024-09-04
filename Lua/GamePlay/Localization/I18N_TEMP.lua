---@class I18N_TEMP
---@field new fun():I18N_TEMP
local I18N_TEMP = {
    -- 自动生产
    btn_auto_produce = "Automatic production",
    -- 居民昏迷中,恢复健康后才可被派遣
    toast_citizen_isFainting = "Residents are in a coma and can only be dispatched after they recover their health",
    -- 居民正在恢复中,恢复健康后才可被派遣
    toast_citizen_isRecovering = "Residents are recovering and can only be dispatched after they recover their health",
    -- 未探索区域
    title_un_explored_area = "Unexplored area",
    -- 小队派遣中
    btn_explorer_running = "Team dispatching",
    -- 清理
    btn_clean = "Clean up",
    -- 挑战
    btn_se_challenge = "Challenge",
    -- 缺少抓捕道具，无法挑战
    hint_lake_catch_item = "Lack of capture props, unable to challenge",
    -- 来自镜像卡
    hint_from_mirror = "From mirror card",
    -- 建造日志
    content_build_log = "Build log",
    -- 拆除日志
    content_destroy_log = "Demolition log",
    -- 解散
    btn_dissolve = "Disband",
    -- 正在联盟战役中, 不能退盟
    toast_in_battle_no_quit = "Currently in alliance battle, cannot quit alliance",
    -- 没有更多消息了
    hint_no_more_message = "No more messages",
    -- 需要道具:
    hint_lake_item = "Need props:",
    -- [*系统消息]
    hint_system_message = "System message",
    -- 多选
    hint_multi_select = "Multi-select",    
    -- 当前编队错误
    toast_error_troop = "Current formation error",
    -- 解锁迷雾后可查看详情
    toast_need_unlock_fog = "Unlock the fog to view details",
    -- 前往
    btn_goto = "Go to",
    -- 城内地图
    title_in_city_map = "City map",
    -- 生产天赋
    text_produce_gift = "Produce talent",
    -- 总耗时
    text_cost_time = "Total time",
    -- 菌毯污染
    text_creep_polluted = "Fungal pollution",
    -- 效率 -50%
    text_efficient_low = "Efficiency -50%",
    -- 装有药剂的喷洒器
    text_med_container = "Sprayer with potion",
    -- 工作时长
    text_work_time = "Working hours",
    -- 入驻
    text_assign = "Settle in",
    -- 已入驻该小屋
    text_assign_already = "Already settled in this cabin",
    -- #清除周围菌毯后，可正常扩建
    hint_clean_to_upgrade = "After clearing the surrounding fungal mats, normal expansion can be carried out",
    -- 怪物信息
    text_monster_info = "Monster information",
    -- 这里是介绍。生化首领比普通丧尸更强，指挥官必须集结进攻，才有办法消灭！
    text_des_se_preview = "This is an introduction. Biochemical leaders are stronger than ordinary zombies. Commanders must gather attacks to eliminate them!",
    -- 属性预览
    text_se_preview_property = "Attribute preview",
    -- 副本属性
    text_se_property = "Dungeon attribute",
    -- 副本属性描述
    text_se_property_desc = "Dungeon attribute description",
    -- 大地图属性
    text_se_world_property = "World map attribute",
    -- 生产属性
    text_se_produce_property = "Production attribute",
    -- 信息
    text_alliance_info = "Information",
    -- 成员
    text_alliance_info_member = "Members",
    -- 世界上还未有联盟被创建
    hint_no_alliance = "No alliance has been created in the world yet",
    -- 倒计时结束后，申请列表中战力最高的成员将自动变为盟主；若无人申请，联盟将解散
    hint_alliance_leader_leave = "After the countdown ends, the member with the highest combat power in the application list will automatically become the leader; if no one applies, the alliance will be dissolved",
    -- 您目前已是盟主，可直接取消解散联盟
    hint_you_are_leader_can_dissolve = "You are currently the leader and can directly cancel the dissolution of the alliance",
    -- 解散
    text_dissolve = "Dissolve",
    -- 目前处于联盟解散等待期，在倒计时结束前，您可以随时取消解散。
    hint_wait_alliance_dissolve_can_revert = "Currently in the waiting period for alliance dissolution, you can cancel the dissolution at any time before the countdown ends.",
    -- 取消解散联盟
    text_cancel_dissolve_alliance = "Cancel dissolution of alliance",
    -- 恢复中
    text_citizen_recovering = "Recovering",
    -- 更新主题
    text_update_theme = "Update theme",
    -- 修复
    text_repair = "Repair",
    -- 切换账户
    text_change_account = "Change account",
    -- 商店
    text_shop = "Shop",
    -- 已使用
    text_used = "Used",
    -- 邮件数
    text_mail_count = "Number of emails",
    -- 删除
    text_mail_delete = "Delete",
    -- 收藏
    text_mail_mark = "Favorite",
    -- 上阵
    text_on_duty = "On duty",
    -- 客服
    text_service = "Customer service",
    -- 查看协议
    text_agreement = "View agreement",
    -- 故障上传
    text_bug_report = "Fault upload",
    -- 游戏不支持此设备运行
    hint_not_support_device = "The game does not support running on this device",
    -- 关闭游戏
    hint_close_game = "Close game",
    -- 点击选择宠物上阵
    hint_pick_pet = "Click to select pets to go into battle",
    -- EXCHANEXCH
    hint_exchange = "Settings",
    -- 兵种克制
    hint_troop_restraint = "Troop restraint",
    -- 弓兵
    text_troop_archers = "Archers",
    -- 枪兵
    text_troop_lancers = "Lancers",
    -- 骑兵
    text_troop_cavalry = "Cavalry",
    -- 步兵
    text_troop_infantry = "Infantry",

    -- 私聊
    chat_p2p_chat = "Private chat",
    -- 群组
    chat_group = "Group chat",
    -- 未知错误
    chat_error_unknown = "Unknown error",
    -- [不支持的消息类型]
    chat_type_not_supported = "[Unsupported message type]",
    -- [*图片]
    chat_type_image = "[Image]",
    -- [*语音]
    chat_type_voice = "[Voice]",
    -- 无昵称
    chat_no_name = "No nickname",
    -- 推荐战力：{1}
    text_power_recommended = "Recommended combat power: {1}",
    -- 当前战力：{1}
    text_power_current = "Current combat power: {1}",
    -- 点击选择宠物上阵
    hint_pick_pet = "Click to choose pets to go into battle",

    -- 已喷洒除菌毯药剂, 预计%d秒后可清除
    toast_creep_clean_time = "The antiseptic mat agent has been sprayed, it is estimated that it can be cleared in %d seconds.",
    -- 此房间规划没有可以放下门的位置，因此跳过
    toast_no_door_for_room = "There is no place to put the door in the planning of this room, so skip it.",
    -- 任务尚未全部完成
    toast_task_need = "The task is not yet completed.",
}

return I18N_TEMP
