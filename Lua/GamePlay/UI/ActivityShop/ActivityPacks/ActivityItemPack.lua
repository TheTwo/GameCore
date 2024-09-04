local BaseActivityPack = require("BaseActivityPack")
local Delegate = require('Delegate')
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
---@class ActivityItemPack : BaseActivityPack
local ActivityItemPack = class("ActivityItemPack", BaseActivityPack)

function ActivityItemPack:PostOnCreate()
    self.imgPack = self:Image("p_img_package")
end

function ActivityItemPack:PostOnFeedData(param)
    local packId = ModuleRefer.ActivityShopModule:GetFirstAvaliableGoodInGroup(self.packGroupId)
    local packCfg = ConfigRefer.PayGoods:Find(packId)
    if not packCfg then return end
    self:LoadSprite(packCfg:Icon(), self.imgPack)
end

function ActivityItemPack:PostInitGroupInfoParam()
    self.groupInfoParam.type = nil
end

return ActivityItemPack