local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require("UIHelper")
local NotificationType = require("NotificationType")
local AudioConsts = require("AudioConsts")
local HeroUIUtilities = require('HeroUIUtilities')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')

---@class UIHeroHeadTableViewCell : BaseTableViewProCell
---@field data HeroConfigCache
local UIHeroHeadTableViewCell = class('UIHeroHeadTableViewCell', BaseTableViewProCell)

function UIHeroHeadTableViewCell:ctor()

end

function UIHeroHeadTableViewCell:OnCreate()
    -- self.btnHero = self:Button('p_btn_hero', Delegate.GetOrCreate(self, self.OnBtnHeroClicked))
    self.goGroupToken = self:GameObject('p_group_token')
    self.compGroupToken = self:LuaObject('p_group_token')
    self.notifyNode = self:LuaObject('child_reddot_default')

    --- @type HeroInfoItemSmallComponent
    self.hero = self:LuaObject('child_card_hero_s')
end

function UIHeroHeadTableViewCell:OnShow(param)
end

function UIHeroHeadTableViewCell:OnOpened(param)
end

function UIHeroHeadTableViewCell:OnClose(param)
end

---@param param HeroConfigCache
function UIHeroHeadTableViewCell:OnFeedData(param)
    self.hero:FeedData({heroData = param, onClick = Delegate.GetOrCreate(self, self.OnBtnHeroClicked)})
    self.data = param
    local hasHero = self.data:HasHero()
    self.hero:SetLock()

    self.goGroupToken:SetActive(not hasHero)
    if not hasHero then
        local pieceData = {}
        pieceData.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
        pieceData.itemId = self.data.configCell:PieceId()
        pieceData.num1 = ModuleRefer.InventoryModule:GetAmountByConfigId(self.data.configCell:PieceId())
        pieceData.num2 = self.data.configCell:ComposeNeedPiece()
        self.compGroupToken:FeedData(pieceData)
    end
    -- self:LoadSprite(HeroUIUtilities.GetQualitySpriteID(self.data.configCell:Quality()),self.imgFrameHead)
    self:CheckHeroRedState()
end

function UIHeroHeadTableViewCell:CheckHeroRedState()
    local heroHeadIconNode = ModuleRefer.NotificationModule:GetDynamicNode("HeroHeadIcon" .. self.data.id, NotificationType.HERO_HEAD_ICON)
    ModuleRefer.NotificationModule:AttachToGameObject(heroHeadIconNode, self.notifyNode.go, self.notifyNode.redDot)
    local isNew = ModuleRefer.HeroModule:CheckHeroHeadIconNew(self.data.id)
    -- 如果是新英雄则需要更换对应显示的红点类型
    if isNew then
        heroHeadIconNode.uiNode:ChangeToggleObject(self.notifyNode.redNew)
    else
        heroHeadIconNode.uiNode:ChangeToggleObject(self.notifyNode.redDot)
    end
end

function UIHeroHeadTableViewCell:Select(param)
    -- override
    ModuleRefer.HeroModule:SyncHeroRedDot(self.data.id, ModuleRefer.HeroModule.HeroRedDotMask.IsNew)
    local heroHeadIconNode = ModuleRefer.NotificationModule:GetDynamicNode("HeroHeadIcon" .. self.data.id, NotificationType.HERO_HEAD_ICON)
    ModuleRefer.NotificationModule:AttachToGameObject(heroHeadIconNode, self.notifyNode.go, self.notifyNode.redDot)
    heroHeadIconNode.uiNode:ChangeToggleObject(self.notifyNode.redDot)
    self.hero:ChangeStateSelect(true)
end

function UIHeroHeadTableViewCell:UnSelect(param)
    self.hero:ChangeStateSelect(false)
end

function UIHeroHeadTableViewCell:OnBtnHeroClicked(args)
    self:SelectSelf()
    -- g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_confirm)
end

function UIHeroHeadTableViewCell:RefreshLv(Level)
    self.hero:RefreshLv(Level)
end

return UIHeroHeadTableViewCell;
