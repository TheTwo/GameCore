local BaseUIComponent = require ('BaseUIComponent')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local FunctionClass = require('FunctionClass')
local ItemType = require('ItemType')
local UIHeroLocalData = require('UIHeroLocalData')
local I18N = require('I18N')
local Delegate = require('Delegate')
local UIHelper = require('UIHelper')
local UIMediatorNames = require('UIMediatorNames')
local PlayerGetAutoRewardParameter = require('PlayerGetAutoRewardParameter')
local HeroUIUtilities = require('HeroUIUtilities')
local Utils = require('Utils')
---@class Accumulate : BaseUIComponent
local Accumulate = class('Accumulate', BaseUIComponent)
---@sence sence_child_shop_accumulated_gift_pack

local BANNER_ITEM_TYPE = {
    HERO = 1,
    PET = 2,
    NORMAL = 3,
}

local SPRITE_NAME_EACH_STAGE = {
    'sp_activity_icon_gift_1',
    'sp_hero_egril_m',
    'sp_activity_icon_gift_2',
    'sp_hero_egril_m',
    'sp_activity_icon_gift_3',
    'sp_hero_egril_m',
    'sp_activity_icon_gift_4',
}

local THRESHOLD_NODE_INDEX = 4

function Accumulate:OnCreate()
    self.textActivityTitle = self:Text('p_text_acitivity_title', 'activity_acc_top-up_title')
    self.textActivityTime = self:Text('p_text_acitivity_time', 'activity_acc_top-up_time_1')
    self.emojiText = self:LuaObject('ui_emoji_text')

    self.imgHero = self:Image('p_acitivity_pic_hero')
    self.imgPet = self:Image('p_acitivity_pic_pet')
    self.imgNormal = self:Image('p_acitivity_pic_norm')
    self.imgNeedItemIcon = self:Image('p_required_item_icon')

    self.btnGotoDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.GoToDetail))
    self.textRewardName = self:Text('p_text_name', '*Reward Name')
    self.imgIconQuality = self:Image('p_icon_quality')
    self.textGoto = self:Text('p_text_hero_detail', '*Goto')

    self.btnNext = self:Button('p_btn_next', Delegate.GetOrCreate(self, self.Next))
    self.btnPrev = self:Button('p_btn_previous', Delegate.GetOrCreate(self, self.Prev))

    self.tableReward = self:TableViewPro('p_table_reward')

    self.btnClaim = self:Button('child_comp_btn_b_l', Delegate.GetOrCreate(self, self.Claim))
    self.goNumClaim = self:GameObject('p_number_bl')
    self.imgBtnClaimItemIcon = self:Image('p_icon_item_bl')
    self.textBtnClaim = self:Text('p_text', 'activity_acc_top-up_btn_claim')
    self.textClaimNumGreen = self:Text('p_text_num_green_bl')
    self.textClaimNum = self:Text('p_text_num_wilth_bl')

    self.btnRecharge = self:Button('p_btn_goto_recharge', Delegate.GetOrCreate(self, self.GoToRecharge))
    self.goNumRecharge = self:GameObject('p_resouce_e')
    self.imgBtnRechargeItemIcon = self:Image('p_icon_e')
    self.textBtnRecharge = self:Text('p_text_e', 'activity_acc_top-up_btn')
    self.textRechargeNumRed = self:Text('p_text_num_red_e')
    self.textRechargeNum = self:Text('p_text_num_e')

    self.goClaimed = self:GameObject('p_claimed')
    self.textClaimed = self:Text('p_text_claimed', 'activity_acc_top-up_btn_claimed')

    self.textNum = self:Text('p_text_progress')
    self.textNum1 = self:Text('p_text_num_1')

    self.btnInfoDetail = self:Button('p_btn_info_detail', Delegate.GetOrCreate(self, self.OnBtnInfoDetailClicked))

    self.goGroupHero = self:GameObject('p_group_hero')
    self.bannerDisplayCtrl = {}
    self.bannerDisplayCtrl[BANNER_ITEM_TYPE.HERO] = self.goGroupHero
    self.bannerDisplayCtrl[BANNER_ITEM_TYPE.PET] = self.imgPet.gameObject
    self.bannerDisplayCtrl[BANNER_ITEM_TYPE.NORMAL] = self.imgNormal.gameObject
    self.textQuality = self:Text('p_text_quality')

    self.vxTrigger = self:AnimTrigger('vx_trigger')
    self.goVxRibbon = self:GameObject('vx_caidai')
    self.goVxSmoke = self:GameObject('vx_smoke')

    self.goReddotNext = self:GameObject('p_reddot_next')
    self.goReddotPrev = self:GameObject('p_reddot_previous')

    self.goAccTag = self:GameObject('p_btn_recharge_points')
    self.goAccTag:SetActive(false)

    self.firstOpen = true
end

function Accumulate:OnFeedData(params)
    if not params then
        return
    end
    self.tabId = params.tabId
    self.actId = ConfigRefer.ActivityCenterTabs:Find(self.tabId):RefActivityReward()
    self.configId = ConfigRefer.ActivityRewardTable:Find(self.actId):RefConfig()
    self.cfg = ConfigRefer.AccRecharge:Find(self.configId)
    self.nodesLength = self:GetNodesLength()
    self.neededItemId = self.cfg:RefItem()
    g_Game.SpriteManager:LoadSprite(ConfigRefer.Item:Find(self.neededItemId):Icon(), self.imgNeedItemIcon)
    self.receivedCache = {}
    self:GetHeroPiece2HeroId()
    self:UpdateReceivedCache()
    self.curNodeIndex = self:GetFirstUnclaimedIndex()
    self:UpdateContent(self.curNodeIndex)
    if not ModuleRefer.ActivityCenterModule.isDoOnceLogicFinished then
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        ModuleRefer.ActivityCenterModule.isDoOnceLogicFinished = true
    end
end

function Accumulate:OnShow()
    if self.firstOpen then
        self.firstOpen = false
    else
        self.vxTrigger:FinishAll(CS.FpAnimation.CommonTriggerType.OnStart)
    end
    if self.isDirty then
        self:UpdateContent(self.curNodeIndex)
        self.isDirty = false
    end
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
end

function Accumulate:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.SecTick))
end

function Accumulate:SecTick()
    local _, endTime = ModuleRefer.ActivityCenterModule:GetActivityStartEndTime(self.actId)
    if not endTime then return end
    local remainingTime = endTime.ServerSecond - g_Game.ServerTime:GetServerTimestampInSeconds()
    local day = math.floor(remainingTime / 86400)
    local hour = math.floor((remainingTime % 86400) / 3600)
    local min = math.floor((remainingTime % 3600) / 60)
    local sec = remainingTime % 60
    if self.textActivityTime then
        self.textActivityTime.text = I18N.GetWithParams('activity_acc_top-up_time_1', day, string.format(' %02d:%02d:%02d', hour, min, sec))
    end
end

function Accumulate:UpdateReceivedCache()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local ReceivedIndex = player.PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].AccRechargeParam.ReceivedIndex
    for _, index in ipairs(ReceivedIndex) do
        self.receivedCache[index + 1] = true
    end
end

function Accumulate:UpdateContent(nodeIndex)
    self.nodesLength = self:GetNodesLength()
    self:UpdateRightGroups(nodeIndex)
    self:UpdateBanner(nodeIndex)
end

function Accumulate:UpdateRightGroups(nodeIndex)
    if nodeIndex > self.nodesLength or nodeIndex < 1 then
        return
    end
    self.btnNext.gameObject:SetActive(nodeIndex ~= self.nodesLength)
    self.btnPrev.gameObject:SetActive(nodeIndex ~= 1)

    self.goReddotNext:SetActive(self:IsRewardCanClaimAfterThisNode(nodeIndex))
    self.goReddotPrev:SetActive(self:IsRewardCanClaimBeforeThisNode(nodeIndex))

    local curValue = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].AccRechargeParam.Value
    local neededValue = self.cfg:Nodes(nodeIndex):Value()

    self.btnClaim.gameObject:SetActive(curValue >= neededValue and not self.receivedCache[nodeIndex])

    self.btnRecharge.gameObject:SetActive(curValue < neededValue and not self.receivedCache[nodeIndex])

    self.goClaimed:SetActive(self.receivedCache[nodeIndex])
    self.textNum.text = I18N.Get('activity_acc_top-up_stage_desc_1')
    self.textNum1.text = string.format('%d / %d', curValue, neededValue)

    local emojiText = Utils.Strip(I18N.GetWithParams('activity_acc_top-up_desc', '[a01]', neededValue))
    self.emojiText:FeedData({text = emojiText})

    local rewardGroupId = self.cfg:Nodes(nodeIndex):Reward()
    local rewardItems = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewardGroupId)
    self.tableReward:Clear()
    for _, item in ipairs(rewardItems) do
        local data = {}
        data.configCell = item.configCell
        data.count = item.count
        data.showTips = true
        self.tableReward:AppendData(data)
    end
    local firstItem = rewardItems[1]
    self.quality = firstItem.configCell:Quality()
    if firstItem.configCell:FunctionClass() == FunctionClass.AddHero then
        self.heroId = firstItem.configCell:UseParam(1)
        self.itemType = BANNER_ITEM_TYPE.HERO
    elseif firstItem.configCell:FunctionClass() == FunctionClass.AddPet then
        self.petId = firstItem.configCell:UseParam(1)
        self.itemType = BANNER_ITEM_TYPE.PET
    elseif firstItem.configCell:Type() == ItemType.HeroPiece then
        self.heroId = self.heroPiece2HeroId[firstItem.configCell:Id()]
        self.itemType = BANNER_ITEM_TYPE.HERO
    else
        self.itemId = firstItem.configCell:Id()
        self.itemType = BANNER_ITEM_TYPE.NORMAL
    end
    self.btnGotoDetail.gameObject:SetActive(self.itemType ~= BANNER_ITEM_TYPE.NORMAL)
end

function Accumulate:UpdateBanner(nodeIndex)
    for type, img in pairs(self.bannerDisplayCtrl) do
        img:SetActive(type == self.itemType)
    end
    if self.itemType == BANNER_ITEM_TYPE.HERO then
        if not self.heroId or self.heroId == 0 then self.heroId = 101 end
        local heroCfg = ConfigRefer.Heroes:Find(self.heroId)
        local heroResId = heroCfg:ClientResCfg()
        local heroResCfg = ConfigRefer.HeroClientRes:Find(heroResId)
        local heroBodyPaintId = heroResCfg:HalfBodyPaint()
        local heroBodyPaint = ConfigRefer.ArtResourceUI:Find(heroBodyPaintId):Path()
        local index = heroCfg:Quality() + 1
        g_Game.SpriteManager:LoadSprite(heroBodyPaint, self.imgHero)
        self.textRewardName.text = I18N.Get(heroCfg:Name())
        self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(index - 1))
        self.textQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(index - 1))
    elseif self.itemType == BANNER_ITEM_TYPE.PET then
        local petCfg = ConfigRefer.Pet:Find(self.petId)
        local index = petCfg:Quality()
        self:LoadSprite(petCfg:ShowPortrait(), self.imgPet)
        self.textRewardName.text = I18N.Get(petCfg:Name())
        self.textQuality.text = I18N.Get(HeroUIUtilities.GetQualityText(index - 1))
        self.textQuality.color = UIHelper.TryParseHtmlString(HeroUIUtilities.GetQualityColor(index - 1))
    else
        g_Game.SpriteManager:LoadSprite(SPRITE_NAME_EACH_STAGE[nodeIndex], self.imgNormal)
        self.textRewardName.text = ''
        self.textQuality.text = ''
    end
    self.textGoto.text = I18N.Get('activity_acc_top-up_btn_deets')
    g_Game.SpriteManager:LoadSprite(UIHeroLocalData.QUALITY_IMAGE[self.quality - 1], self.imgIconQuality)
end

function Accumulate:Next()
    if self.curNodeIndex < self.nodesLength then
        self.curNodeIndex = self.curNodeIndex + 1
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2, function()
            self:UpdateContent(self.curNodeIndex)
            self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom4)
        end)
    end
end

function Accumulate:Prev()
    if self.curNodeIndex > 1 then
        self.curNodeIndex = self.curNodeIndex - 1
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3, function()
            self:UpdateContent(self.curNodeIndex)
            self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom5)
        end)
    end
end

function Accumulate:GoToRecharge()
    self.isDirty = true
    g_Game.UIManager:Open(UIMediatorNames.ActivityShopMediator, {tabId = 9})
end

function Accumulate:GoToDetail()
    if self.itemType == BANNER_ITEM_TYPE.HERO and self.heroId and self.heroId > 0 then
        self.isDirty = true
        local heroType = ConfigRefer.Heroes:Find(self.heroId):Type()
        g_Game.UIManager:Open(UIMediatorNames.UIHeroMainUIMediator, {id = self.heroId, type = heroType})
    elseif self.itemType == BANNER_ITEM_TYPE.PET and self.petId and self.petId > 0 then
        self.isDirty = true
        local petType = ConfigRefer.Pet:Find(self.petId):Type()
        g_Game.UIManager:Open(UIMediatorNames.UIPetMediator, {selectedType = petType})
    end
end

function Accumulate:Claim()
    local canClaimIndex = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].AccRechargeParam.NodeIndex
    if self.curNodeIndex > canClaimIndex then
        return
    end
    local param = PlayerGetAutoRewardParameter.new()
    local op = wrpc.PlayerGetAutoReward()
    op.ConfigId = self.actId
    op.Arg1 = self.curNodeIndex - 1
    param.args.Op = op
    param:SendOnceCallback(self.btnClaim.gameObject, nil, nil, function(_, isSuccess, _)
        if isSuccess then
            self:UpdateReceivedCache()
            self:UpdateContent(self.curNodeIndex)
            self:Next()
        end
    end)
end

function Accumulate:OnBtnInfoDetailClicked()
    ---@type TextToastMediatorParameter
    local tipParam = {}
    tipParam.clickTransform = self.btnInfoDetail.gameObject.transform
    tipParam.content = I18N.Get('activity_acc_top-up_txt')
    ModuleRefer.ToastModule:ShowTextToast(tipParam)
end

function Accumulate:GetHeroPiece2HeroId()
    self.heroPiece2HeroId = {}
    for _, hero in ConfigRefer.Heroes:ipairs() do
        local heroPieceId = hero:PieceId()
        self.heroPiece2HeroId[heroPieceId] = hero:Id()
    end
end

function Accumulate:GetNodesLength()
    local l = 0
    for i = 1, self.cfg:NodesLength() do
        local rewardId = self.cfg:Nodes(i):Reward()
        if not rewardId or rewardId == 0 then
            break
        end
        l = l + 1
    end
    local curValue = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].AccRechargeParam.Value
    if curValue < self.cfg:Nodes(THRESHOLD_NODE_INDEX):Value() then
        return l - 2
    end
    return l
end

function Accumulate:GetFirstUnclaimedIndex()
    local firstUnclaimedIndex = 1
    for i = 1, self.nodesLength do
        if not self.receivedCache[i] then
            firstUnclaimedIndex = i
            break
        end
    end
    return firstUnclaimedIndex
end

function Accumulate:IsRewardCanClaimAfterThisNode(nodeIndex)
    local curValue = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].AccRechargeParam.Value
    for i = nodeIndex + 1, self.nodesLength do
        local neededValue = self.cfg:Nodes(i):Value()
        if curValue >= neededValue and not self.receivedCache[i] then
            return true
        end
    end
    return false
end

function Accumulate:IsRewardCanClaimBeforeThisNode(nodeIndex)
    local curValue = ModuleRefer.PlayerModule:GetPlayer().PlayerWrapper2.PlayerAutoReward.Rewards[self.actId].AccRechargeParam.Value
    for i = nodeIndex - 1, 1, -1 do
        local neededValue = self.cfg:Nodes(i):Value()
        if curValue >= neededValue and not self.receivedCache[i] then
            return true
        end
    end
    return false
end

return Accumulate