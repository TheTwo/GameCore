---@class ShareChatItemParam
---@field x number
---@field y number
---@field level number
---@field name string           名称
---@field resourceYield number  资源产量
---@field combatValue number    推荐战力
---@field type number           类型
---@field configID number       配置ID
---@field shareTime number     分享时间(开始时间，用来计算生命周期)
---@field shareDesc string      分享内容
---@field customPic string
---@field context any|nil
local ShareChatItemParam = sealedClass("ShareChatItemParam")

return ShareChatItemParam