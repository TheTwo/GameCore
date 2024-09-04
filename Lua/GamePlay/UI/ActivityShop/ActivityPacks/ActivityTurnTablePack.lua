local BaseActivityPack = require("BaseActivityPack")
local Delegate = require('Delegate')
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
---@class ActivityTurnTablePack : BaseActivityPack
local ActivityTurnTablePack = class("ActivityTurnTablePack", BaseActivityPack)

function ActivityTurnTablePack:ctor()
end

function ActivityTurnTablePack:PostOnCreate()
    self.p_img_hero = self:Image("p_img_hero")
    self.p_text_reward_name = self:Text("p_text_reward_name")
end

function ActivityTurnTablePack:PostOnFeedData()
    local heroId = self.gotoDetailParam.configId
    if not heroId or heroId <= 0 then
        g_Logger.ErrorChannel('ActivityTurnTablePack', '转盘礼包没有配置Goto')
        return
    end

    local heroCfg = ConfigRefer.Heroes:Find(heroId)
    local heroImgId = ConfigRefer.HeroClientRes:Find(heroCfg:ClientResCfg()):BodyPaint()
    self:LoadSprite(heroImgId, self.p_img_hero)

    self.p_text_reward_name.text = I18N.Get(heroCfg:Name())
end

return ActivityTurnTablePack