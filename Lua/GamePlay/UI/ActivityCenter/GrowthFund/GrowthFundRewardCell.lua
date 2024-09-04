local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local GrowthFundConst = require('GrowthFundConst')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local DBEntityPath = require('DBEntityPath')
local PlayerGetAutoRewardParameter = require('PlayerGetAutoRewardParameter')
local Utils = require('Utils')
local ColorConsts = require('ColorConsts')
local UIHelper = require('UIHelper')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local TimerUtility = require('TimerUtility')
local ActivityCenterConst = require('ActivityCenterConst')
local ActivityRewardType = require('ActivityRewardType')
---@class GrowthFundRewardCell : BaseTableViewProCell
local GrowthFundRewardCell = class('GrowthFundRewardCell', BaseTableViewProCell)

---@class GrowthFundRewardCellData
---@field level number
---@field nodeInfo GrowthFundNodeInfo
---@field isFixed boolean

local REWARD_DISPLAY_TYPE = {
    NORMAL = 1,
    SPECIAL = 2,
}

local CLAIM_ANIM_TYPE = {
    [false] = CS.FpAnimation.CommonTriggerType.Custom1,
    [true] = CS.FpAnimation.CommonTriggerType.Custom2,
}

local ICON_DIAMOND = {
    'sp_item_icon_coin_01',
    'sp_item_icon_coin_02',
    'sp_item_icon_coin_03',
    'sp_item_icon_coin_04',
    'sp_item_icon_coin_05',
    'sp_item_icon_coin_06',
}

local MAX_LVL_PROGRESS_BASE_IMG = "sp_activity_growth_base_bar_bottom"
local MAX_LVL_PROGRESS_IMG = "sp_activity_growth_img_bar_bottom"

local NORMAL_LVL_PROGRESS_BASE_IMG = "sp_activity_growth_base_bar"
local NORMAL_LVL_PROGRESS_IMG = "sp_activity_growth_img_bar"

local LOCKED_COLOR = "#9C9C9C"

function GrowthFundRewardCell:OnCreate()
    -- self.sliderProgress = self:Slider('p_progress_reward')
    self.imgProgress = self:Image('p_progress_reward') or self:Image('p_progress_bottom')
    self.imgBase = self:Image('p_base')
    self.textLvl = self:Text('p_text')

    self.goRewardFree1 = self:GameObject('p_reward_free_1')
    self.luaRewardFree1 = self:LuaObject('p_item_free_1')
    self.goClaimRewardFree1 = self:GameObject('p_img_free_claim_1')

    self.goRewardFree2 = self:GameObject('p_reward_free_2')
    self.luaRewardFree2 = self:LuaObject('p_item_free_2')
    self.goClaimRewardFree2 = self:GameObject('p_img_free_claim_2')

    self.goRewardItem = self:GameObject('p_item')
    self.goRewardBetter1 = self:GameObject('p_reward_better_1')
    self.luaRewardBetter1 = self:LuaObject('p_item_better_1')
    self.goClaimRewardBetter1 = self:GameObject('p_img_better_claim_1')

    self.goRewardBetter2 = self:GameObject('p_reward_better_2')
    self.luaRewardBetter2 = self:LuaObject('p_item_better_2')
    self.goClaimRewardBetter2 = self:GameObject('p_img_better_claim_2')

    self.imgDiamond = self:Image('p_img_diamond')
    self.goClaimDiamond = self:GameObject('p_img_diamond_claim')
    self.textDiamond = self:Text('p_text_diamond')
    self.goDiamondClaimed = self:GameObject('p_diamond_claimed')
    self.imgFixedBtnDiamond = self:Image('p_btn_diamond')
    self.btnFixedDiamond = self:Button('p_btn_diamond', Delegate.GetOrCreate(self, self.OnBtnDiamondClicked))
    self.luaRewardBetter3 = self:LuaObject('p_item_better_3')

    self.goFixedClaimed = self:GameObject('p_claimed_better_show')
    self.imgPet = self:Image('p_img_pet')
    self.textPetDetail = self:Text('p_text_pet_detail')
    self.btnPetDetail = self:Button('p_btn_pet_detail', Delegate.GetOrCreate(self, self.OnBtnPetDetailClicked))
    self.btnPet = self:Button('p_btn_pet', Delegate.GetOrCreate(self, self.OnBtnPetClicked))

    self.btnFixedClaim = self:Button('p_btn_show_claim', Delegate.GetOrCreate(self, self.OnBtnFixedClaimClicked))
    self.btnFixedClaimFree = self:Button('p_btn_show_claim_l', Delegate.GetOrCreate(self, self.OnBtnFixedClaimFreeClicked))

    self.btnAllClaim = self:Button('p_btn_all_claim', Delegate.GetOrCreate(self, self.OnBtnAllClaimClicked))
    self.btnClaimFree = self:Button('p_btn_free_claim', Delegate.GetOrCreate(self, self.OnBtnClaimFreeClicked))

    self.animTriggerDiamond = self:AnimTrigger('p_diamond')
    self.animTriggerPet = self:AnimTrigger('p_btn_pet')

    self.rewardDisplayCtrler = {
        [REWARD_DISPLAY_TYPE.NORMAL] = {
            free = {
            {
                go = self.goRewardFree1,
                lua = self.luaRewardFree1,
                claim = self.goClaimRewardFree1,
            },
            {
                go = self.goRewardFree2,
                lua = self.luaRewardFree2,
                claim = self.goClaimRewardFree2,
            }},
            adv = {
            {
                go = self.goRewardBetter1,
                lua = self.luaRewardBetter1,
                claim = self.goClaimRewardBetter1,
            },
            {
                go = self.goRewardBetter2,
                lua = self.luaRewardBetter2,
                claim = self.goClaimRewardBetter2,
            }},
        },
        [REWARD_DISPLAY_TYPE.SPECIAL] = {
            {
                go = self.goRewardDiamond,
                text = self.textDiamond,
                claim = self.goClaimDiamond,
                claimed = self.goDiamondClaimed,
            }
        }
    }

    self.goVxDiamondClaimRing = self:GameObject('vfx_btn_diamond_claim_ring')
    self.goVxDiamondClaim = self:GameObject('vfx_btn_diamond_claim')
    self.goVxDiamondCommon = self:GameObject('vfx_btn_diamond_common')

    self.vxCtrler = {
        [false] = {
            self.goVxDiamondCommon
        },
        [true] = {
            self.goVxDiamondClaimRing,
            self.goVxDiamondClaim,
        }
    }
end

function GrowthFundRewardCell:PlayDiamondVx(isClaimable)
    if not self.vxCtrler then return end
    for _, go in ipairs(self.vxCtrler[isClaimable]) do
        go:SetActive(true)
    end
    for _, go in ipairs(self.vxCtrler[not isClaimable]) do
        go:SetActive(false)
    end
end

---@param param GrowthFundRewardCellData
function GrowthFundRewardCell:OnFeedData(param)
    if not param then return end
    self.level = param.level
    self.nodeInfo = param.nodeInfo
    self.cfgId = ModuleRefer.GrowthFundModule:GetCurOpeningGrowthFundCfgId()
    self.isFixed = param.isFixed
    self.freeRewardId = self.nodeInfo.normal
    self.advRewardId = self.nodeInfo.adv
    self:UpdateCellDisplay()

    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath,
    Delegate.GetOrCreate(self, self.OnDataChanged))
end

function GrowthFundRewardCell:OnRecycle()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerAutoReward.Rewards.MsgPath,
    Delegate.GetOrCreate(self, self.OnDataChanged))
end

function GrowthFundRewardCell:OnDataChanged()
    self:UpdateCellDisplay()
end

function GrowthFundRewardCell:UpdateCellDisplay()
    if Utils.IsNull(self.CSComponent) or not self.CSComponent or self.CSComponent == nil then return end
    local isVip = ModuleRefer.GrowthFundModule:IsVIP(self.cfgId)
    local curLevel = ModuleRefer.GrowthFundModule:GetProgressByCfgId(self.cfgId)
    local freeRewardStatus, advRewardStatus = ModuleRefer.GrowthFundModule:GetRewardStatus(self.cfgId, self.level)
    local isSp = false -- ModuleRefer.GrowthFundModule:IsSpecialReward(self.cfgId, self.level)
    self.isSp = false -- 2023.12 需求改动 - 取消特殊显示
    local freeRewardItems = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(self.freeRewardId)
    local advRewardItems = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(self.advRewardId)
    if Utils.IsNull(self.textLvl) then return end
    if self.level == ModuleRefer.GrowthFundModule:GetMaxLevelByCfgId(self.cfgId) then
        g_Game.SpriteManager:LoadSprite(MAX_LVL_PROGRESS_IMG, self.imgProgress)
        g_Game.SpriteManager:LoadSprite(MAX_LVL_PROGRESS_BASE_IMG, self.imgBase)
    else
        g_Game.SpriteManager:LoadSprite(NORMAL_LVL_PROGRESS_IMG, self.imgProgress)
        g_Game.SpriteManager:LoadSprite(NORMAL_LVL_PROGRESS_BASE_IMG, self.imgBase)
    end
    self.textLvl.text = self.level
    self.imgProgress.fillAmount = (self.level <= curLevel) and 1 or 0
    if self.level <= curLevel then
        self.textLvl.color = UIHelper.TryParseHtmlString(ColorConsts.black)
    else
        self.textLvl.color = UIHelper.TryParseHtmlString(ColorConsts.white)
    end
    if not self.isFixed then
        self.goRewardItem:SetActive(not isSp)
        self.btnAllClaim.gameObject:SetActive(advRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE)
        self.btnClaimFree.gameObject:SetActive(freeRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE)
    end
    if self.isFixed then
        self.goFixedClaimed:SetActive(advRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMED)
        self.btnFixedClaim.gameObject:SetActive(advRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE)
        self.btnFixedClaimFree.gameObject:SetActive(freeRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE
                                    and advRewardStatus ~= GrowthFundConst.REWARD_STATUS.CLAIMABLE)
    end
    for i, itemSlot in ipairs(self.rewardDisplayCtrler[REWARD_DISPLAY_TYPE.NORMAL].free) do
        if i > #freeRewardItems then
            itemSlot.go:SetActive(false)
            itemSlot.lua:SetVisible(false)
            itemSlot.claim:SetActive(false)
            itemSlot.claim:SetActive(false)
            goto continue
        end
        itemSlot.go:SetActive(true)
        itemSlot.lua:SetVisible(true)
        local item = freeRewardItems[i]
        item.showTips = true
        item.received = freeRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMED
        item.claimable = freeRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE
        item.unavailable = freeRewardStatus == GrowthFundConst.REWARD_STATUS.UNCLAIMABLE
        itemSlot.lua:FeedData(item)
        -- itemSlot.claim:SetActive(freeRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE)
        ::continue::
    end
    if not isSp and not self.isFixed then
        for i, itemSlot in ipairs(self.rewardDisplayCtrler[REWARD_DISPLAY_TYPE.NORMAL].adv) do
            if i > #advRewardItems then
                itemSlot.go:SetActive(false)
                itemSlot.lua:SetVisible(false)
                itemSlot.claim:SetActive(false)
                goto continue
            end
            itemSlot.go:SetActive(true)
            itemSlot.lua:SetVisible(true)
            local item = advRewardItems[i]
            item.showTips = true
            item.received = advRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMED
            item.claimable = advRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE
            item.unavailable = advRewardStatus == GrowthFundConst.REWARD_STATUS.UNCLAIMABLE
            itemSlot.lua:FeedData(item)
            -- itemSlot.claim:SetActive(advRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE)
            ::continue::
        end
    else
        if self.isFixed then
            local rewardPet = advRewardItems[2]
            local petId = tonumber(rewardPet.configCell:UseParam(1))
            local petCfg = ConfigRefer.Pet:Find(petId)
            self:LoadSprite(petCfg:Icon(), self.imgPet)
            self.textPetDetail.text = I18N.Get(petCfg:Name())
            self.petId = petId
            self.petItemId = rewardPet.configCell:Id()
            if advRewardStatus == GrowthFundConst.REWARD_STATUS.LOCKED or advRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMED then
                self.imgFixedBtnDiamond.color = UIHelper.TryParseHtmlString(LOCKED_COLOR)
            else
                self.imgFixedBtnDiamond.color = UIHelper.TryParseHtmlString(ColorConsts.white)
            end
            self.animTriggerPet:PlayAll(CLAIM_ANIM_TYPE[advRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE])
        else -- if isSp then
        end
        self:PlayDiamondVx(advRewardStatus == GrowthFundConst.REWARD_STATUS.CLAIMABLE)
    end
end

function GrowthFundRewardCell:OnBtnPetDetailClicked()
    if ModuleRefer.NewFunctionUnlockModule:CheckUIMediatorIsOpen(UIMediatorNames.UIPetMediator) then
        local petType = ConfigRefer.Pet:Find(self.petId):Type()
        g_Game.UIManager:Open(UIMediatorNames.UIPetMediator, {selectedType = petType})
    end
end

function GrowthFundRewardCell:OnBtnDiamondClicked()
    local param = {
        itemId = GrowthFundConst.SPECIE_ID,
        itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM,
    }
    g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end

function GrowthFundRewardCell:OnBtnPetClicked()
    local param = {
        itemId = self.petItemId,
        itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM,
    }
    g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end

function GrowthFundRewardCell:OnBtnAllClaimClicked()
    self:ClaimAll(self.btnAllClaim.gameObject.transform)
end

function GrowthFundRewardCell:OnBtnClaimFreeClicked()
    -- self:ClaimFree(self.btnClaimFree.gameObject.transform)
    self:ClaimAll(self.btnClaimFree.gameObject.transform)
end

function GrowthFundRewardCell:OnBtnFixedClaimClicked()
    self:ClaimAll(self.btnFixedClaim.gameObject.transform)
end

function GrowthFundRewardCell:OnBtnFixedClaimFreeClicked()
    self:ClaimFree(self.btnFixedClaimFree.gameObject.transform)
end

function GrowthFundRewardCell:ClaimAll(transform)
    local normalRewardStatus, advRewardStatus = ModuleRefer.GrowthFundModule:GetRewardStatus(self.cfgId, self.level)
    if normalRewardStatus ~= GrowthFundConst.REWARD_STATUS.CLAIMABLE and advRewardStatus ~= GrowthFundConst.REWARD_STATUS.CLAIMABLE then
        return
    end
    local op = wrpc.PlayerGetAutoReward()
    op.ConfigId = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.ProgressFund)
    op.Arg1 = GrowthFundConst.REWARD_CLAIM_TYPE.ALL
    op.Arg2 = self.level - 1
    local msg = PlayerGetAutoRewardParameter.new()
    msg.args.Op = op
    msg:SendOnceCallback(transform, nil, nil, function (_, isSuccess, _)
        if isSuccess then
            ModuleRefer.ActivityCenterModule:UpdateRedDotByTabId(ActivityCenterConst.GrowthFundTabId)
        end
    end)
end

function GrowthFundRewardCell:ClaimFree(transform)
    local normalRewardStatus, _ = ModuleRefer.GrowthFundModule:GetRewardStatus(self.cfgId, self.level)
    if normalRewardStatus ~= GrowthFundConst.REWARD_STATUS.CLAIMABLE then
        return
    end
    local op = wrpc.PlayerGetAutoReward()
    op.ConfigId = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.ProgressFund)
    op.Arg1 = GrowthFundConst.REWARD_CLAIM_TYPE.NORMAL
    op.Arg2 = self.level - 1
    local msg = PlayerGetAutoRewardParameter.new()
    msg.args.Op = op
    msg:Send(transform)
end

return GrowthFundRewardCell