local BaseUIComponent = require('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local BattlePassConst = require('BattlePassConst')
local FunctionClass = require('FunctionClass')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local HeroUIUtilities = require('HeroUIUtilities')
local UIHelper = require('UIHelper')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local CommonGotoDetailDefine = require('CommonGotoDetailDefine')
---@class BattlePassPage : BaseUIComponent
local BattlePassPage = class('BattlePassPage', BaseUIComponent)

---@class BattlePassPageParam
---@field nodeIndex number
---@field itemId number

function BattlePassPage:ctor()
    self.nodeIndex = nil
    self.heroId = nil
    self.petId = nil
    self.heroResCfg = nil
    self.generatedSpine = nil
    ---@type CS.DragonReborn.AssetTool.GameObjectCreateHelper
    self.creater = CS.DragonReborn.AssetTool.GameObjectCreateHelper.Create()
end

function BattlePassPage:OnCreate()
    self.imgHero = self:Image('p_icon_big_reward_hero')
    self.imgItem = self:Image('p_icon_big_reward')
    self.goSpine = self:GameObject('p_spine')
    self.textQuality = self:Text('p_text_quality')
    self.textName = self:Text('p_text_reward_name')
    self.textDesc = self:Text('p_text_pet_desc')
    ---@see CommonGotoDetail
    self.luaGoto = self:LuaObject('child_activity_detail')

    self.imgHero.gameObject:SetActive(false)
    self.imgItem.gameObject:SetActive(false)

    self.animTrigger = self:AnimTrigger('trigger_page')
end

---@param param BattlePassPageParam
function BattlePassPage:OnFeedData(param)
    if not param then
        return
    end
    local cfg
    if param.itemId then
        cfg = ConfigRefer.Item:Find(param.itemId)
    else
        local id = ModuleRefer.BattlePassModule:GetCurOpeningBattlePassId()
        local nodeIndex = param.nodeIndex
        local nodeInfo = ModuleRefer.BattlePassModule:GetRewardInfosByCfgId(id)[nodeIndex]
        local advReward = nodeInfo.adv
        local showReward = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(advReward)[1]
        cfg = showReward.configCell
    end

    if not cfg then return end

    if cfg:FunctionClass() == FunctionClass.AddHero then
        self.heroId = tonumber(cfg:UseParam(1))
        self:InitHeroInfo(self.heroId)
    elseif cfg:FunctionClass() == FunctionClass.AddPet then
        self.petId = tonumber(cfg:UseParam(1))
        self:InitPetInfo(self.petId)
    else
        self:InitItemInfo(cfg)
    end
end

function BattlePassPage:OnShow()
    g_Game.EventManager:AddListener(EventConst.BATTLEPASS_UNLOCK_VIP_OPEN, Delegate.GetOrCreate(self, self.OnUnlockVipOpen))
    g_Game.EventManager:AddListener(EventConst.BATTLEPASS_UNLOCK_VIP_CLOSE, Delegate.GetOrCreate(self, self.OnUnlockVipClose))
end

function BattlePassPage:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.BATTLEPASS_UNLOCK_VIP_OPEN, Delegate.GetOrCreate(self, self.OnUnlockVipOpen))
    g_Game.EventManager:RemoveListener(EventConst.BATTLEPASS_UNLOCK_VIP_CLOSE, Delegate.GetOrCreate(self, self.OnUnlockVipClose))
    if self.generatedSpine then
        CS.DragonReborn.AssetTool.GameObjectCreateHelper.DestroyGameObject(self.generatedSpine)
        self.generatedSpine = nil
    end
end

function BattlePassPage:OnUnlockVipOpen()
    self.animTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function BattlePassPage:OnUnlockVipClose()
    self.animTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
end

function BattlePassPage:InitHeroInfo(heroId)
    local heroCfg = ConfigRefer.Heroes:Find(heroId)
    local index = heroCfg:Quality() + 1
    local heroResId = heroCfg:ClientResCfg()
    self.heroResCfg = ConfigRefer.HeroClientRes:Find(heroResId)
    self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(index - 1))
    self.textQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(index - 1))
    self.textName.text = I18N.Get(heroCfg:Name())
    local heroSpineCell = ConfigRefer.ArtResourceUI:Find(self.heroResCfg:Spine())
    if heroSpineCell then
        if self.generatedSpine then return end
        self.goSpine.gameObject:SetActive(true)
        self.imgHero.gameObject:SetActive(false)
        UIHelper.SimpleCreateSpine(self.creater, self.goSpine.transform, heroSpineCell, function (go)
            self.generatedSpine = go
        end)
    else
        local heroBodyPaintId = self.heroResCfg:HalfBodyPaint()
        local heroBodyPaint = ConfigRefer.ArtResourceUI:Find(heroBodyPaintId):Path()
        self.imgHero.gameObject:SetActive(true)
        self.goSpine.gameObject:SetActive(false)
        g_Game.SpriteManager:LoadSprite(heroBodyPaint, self.imgHero)
    end
end

function BattlePassPage:InitPetInfo(petId)
    local petCfg = ConfigRefer.Pet:Find(petId)
    local index = petCfg:Quality()
    local petSpineCell = ConfigRefer.ArtResourceUI:Find(petCfg:Spine())
    self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(index))
    self.textQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(index))
    self.textName.text = I18N.Get(petCfg:Name())
    self.textDesc.text = I18N.Get("bundle_white_bear_desc")
    ---@type CommonGotoDetailParam
    local data = {}
    data.displayMask = CommonGotoDetailDefine.DISPLAY_MASK.BTN_GOTO
    data.configId = petCfg:Id()
    data.type = CommonGotoDetailDefine.TYPE.PET
    self.luaGoto:FeedData(data)
    if petSpineCell then
        if self.generatedSpine then return end
        self.goSpine.gameObject:SetActive(true)
        self.imgItem.gameObject:SetActive(false)
        UIHelper.SimpleCreateSpine(self.creater, self.goSpine.transform, petSpineCell, function (go)
            self.generatedSpine = go
        end)
    else
        self.goSpine.gameObject:SetActive(false)
        self.imgItem.gameObject:SetActive(true)
        self:LoadSprite(petCfg:ShowPortrait(), self.imgItem)
    end
end

function BattlePassPage:InitItemInfo(cfg)
    self.textName.text = I18N.Get(cfg:NameKey())
    local index = cfg:Quality() - 1
    self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(index - 1))
    self.textQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(index - 1))
    self.imgItem.gameObject:SetActive(true)
    g_Game.SpriteManager:LoadSprite(cfg:Icon(), self.imgItem)
end

return BattlePassPage