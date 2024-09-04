---
--- 客户端数据Key
--- 每个账号在服务端只能存储100个客户端数据, 因此在此处定义各模块使用的Key的范围与值
local ClientDataKeys = {
    --- 游戏设置
    GameSetting = {
        --- 语言代码
        LanguageCode = 1,

    },
    
    --- 游戏数据
    GameData = {
        --- 引导进度
        GuideProgress = 10001,
        GuideFinish = 10002,
        GuideFinishCount = 10100,
        GuideFinishMin = 11000, --11000到11999都为引导预留
        GuideFinishMax = 11999,
        ClickVillage = 40000,
        JoinAllianceGuide = 50000,      --第一次加入联盟时的迁城引导
        WorldTrendGuide = 50001,      --第一次打开天下大势界面引导
        AllianceLeaderFirstGuide = 50002, --盟主首次开启联盟界面引导
        AllianceCenterJumpGuide = 50003,

        ActivityCenterTab = 60000,      --活动中心tab红点状态
        AllianceRecruitMsg = 70000,      --联盟招募消息
        AllianceRecruitMsgCD = 70001,      --联盟招募消息CD

        FirstTimeOpenRechargePopup = 80000, --首次打开充值弹窗

        NoMoreDisplayExchangePanel_SpeedUp = 90001, --一键加速不再显示确认
        NoMoreDisplayExchangePanel_Supply = 90002, --一键补充不再显示确认

        DefeatedTime = 100000 -- 上次击飞的时间
    }
}

return ClientDataKeys