local BaseActivityPack = require("BaseActivityPack")
local Delegate = require('Delegate')
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
---@class ActivityHeroPack : BaseActivityPack
local ActivityHeroPack = class("ActivityHeroPack", BaseActivityPack)

function ActivityHeroPack:ctor()
    self.generatedSpine = nil
    ---@type CS.DragonReborn.AssetTool.GameObjectCreateHelper
    self.creater = GameObjectCreateHelper.Create()
end

function ActivityHeroPack:PostOnCreate()
    self.root = self:GameObject("p_root")
    self.btnClose = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.OnCloseBtnClick))
    self.statusCtrl = self:StatusRecordParent("")
    self.imgHero = self:Image("p_img_hero")
    self.goSpine = self:GameObject("p_spine")
end

function ActivityHeroPack:OnHide()
    if self.generatedSpine then
        GameObjectCreateHelper.DestroyGameObject(self.generatedSpine)
        self.generatedSpine = nil
    end
end

function ActivityHeroPack:PostOnFeedData(param)
    if self.isShop then
        self.statusCtrl:ApplyStatusRecord(0)
    else
        self.statusCtrl:ApplyStatusRecord(1)
    end
    local heroId = self.gotoDetailParam.configId
    if not heroId or heroId == 0 then
        return
    end
    local heroConfig = ConfigRefer.Heroes:Find(heroId)
    local clientRes = ConfigRefer.HeroClientRes:Find(heroConfig:ClientResCfg())
    local heroSpineCell = ConfigRefer.ArtResourceUI:Find(clientRes:Spine())
    if heroSpineCell and self.goSpine then
        if self.generatedSpine then return end
        self.imgHero.gameObject:SetActive(false)
        self.goSpine:SetActive(true)
        UIHelper.SimpleCreateSpine(self.creater, self.goSpine.transform, heroSpineCell, function (go)
            self.generatedSpine = go
        end)
    else
        if self.goSpine then
            self.goSpine:SetActive(false)
        end
        self.imgHero.gameObject:SetActive(true)
        self:LoadSprite(clientRes:BodyPaint(), self.imgHero)
    end
end

function ActivityHeroPack:OnCloseBtnClick()
    self:GetParentBaseUIMediator():CloseSelf()
end

return ActivityHeroPack