---@class RelocateCantPlaceReason
local RelocateCantPlaceReason = {
    OK = 0,
    InCD = 1,    --冷却中
    MistLimit = 2,    --迷雾未解锁
    AllianceLimit = 3,    --未加入联盟
    AllianceAreaLimit = 4,    --需要在联盟领土范围内
    SlgBlockLimit = 5,    --需要在主堡所在省
    PosLimit = 6,    --位置不合法
    TroopLimit = 7,    --部队未召回
    ItemLimit = 8,    --道具不足
    LandformLocked = 9,    --地貌未开放
    CastleLevel = 10,    --主堡等级不足
}


return RelocateCantPlaceReason