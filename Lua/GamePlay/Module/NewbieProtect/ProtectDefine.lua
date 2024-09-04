---@class ProtectDefine
local ProtectDefine = {}

---@class ProtectDefine.STATUS_TYPE
ProtectDefine.STATUS_TYPE = {
    Normal = 1,     
    Newbie_Protect = 2,     --新手保护
    Item_Protect = 3,     --普通道具保护
    War = 4,     --战争状态
}


ProtectDefine.Protection_NewbieProtectIndex = 1001
ProtectDefine.Protection_ItemProtectIndex = 1002
ProtectDefine.UserDefault_JoinUnionCDIndex = 2001
ProtectDefine.UserDefault_RelocateCDIndex = 2011

return ProtectDefine