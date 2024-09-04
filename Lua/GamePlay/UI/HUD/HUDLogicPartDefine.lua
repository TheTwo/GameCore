---@class HUDLogicPartDefine
local HUDLogicPartDefine = {
    none = 0,

    playInfoComp = 1 << 1,
    communityComp = 1 << 2,
    mapComp = 1 << 3,
    taskComp = 1 << 4,
    -- buildComp = 1 << 5,
    -- scienceComp = 1 << 6,
    resourceComp = 1 << 7,
    activityComp = 1 << 8,
    bottomComp = 1 << 9,
    popNoticeComp = 1 << 10,
    residentComp = 1 << 11,
    exploreComp = 1 << 12,
    troopComp = 1 << 13,
    injuredComp = 1 << 14,
    explorerFog = 1 << 15,
    lodHint = 1 << 17,
    bossInfoComp = 1 << 18,
    bossDmgRankComp = 1 << 19,
    worldEventComp = 1 << 20,
    activityNoticeComp = 1 << 21,
    utcClock = 1 << 22,

    --logic part
    inMyCity = 1 << 6 | 1 << 10 | 1 << 17 | 1 << 15,
    inOtherCity = 1 << 2 | 1 << 4 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 21 | 1 << 9 | 1 << 10 | 1 << 12 | 1 << 13 | 1 << 17 | 1 << 15,
    outCity = 1 << 5 | 1 << 6 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 17 | 1 << 15 | 1 << 20,
    inRadar = 1 << 4 | 1 << 5 | 1 << 6 |  1 << 7 | 1 << 8 | 1 << 21 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 17 | 1 << 15,
    inHighLod = 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5 | 1 << 6 |  1 << 7 | 1 << 8 | 1 << 21 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 20 | 1 << 22,
    worldEventPanel =  1 << 2 | 1 << 3 | 1 << 4,
    worldEventRecordOnOutCity =  1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 17 | 1 << 15,
    inCityOnlyShowRes = 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 8 | 1 << 21 | 1 << 9 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 22,
}
return HUDLogicPartDefine

