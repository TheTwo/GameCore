local BaseTableViewProCell = require('BaseTableViewProCell')
local BattlePassConst = require('BattlePassConst')
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local Utils = require('Utils')
local ActivityRewardType = require('ActivityRewardType')
local ConfigRefer = require('ConfigRefer')
---@class BattlePassRewardCell : BaseTableViewProCell
local BattlePassRewardCell = class('BattlePassRewardCell', BaseTableViewProCell)

---@class BattlePassRewardCellParam
---@field isFixed boolean
---@field level number
---@field curAchievedLevel number

local LEVEL_ACHIEVE_STATUS = {
    [true] = 0,
    [false] = 1,
}

function BattlePassRewardCell:OnCreate()
    -- basic
    self.luaItemRewardBasic = self:LuaObject('p_item_basic_1') or self:LuaObject('p_item_basic_show_1')
    self.goBasicCanClaim = self:GameObject('p_img_receive_basic')
    self.btnBasic = self:Button('p_btn_basic', Delegate.GetOrCreate(self, self.OnBtnClaimNormalRewardClicked))
    self.gofixedBtnBasic = self:GameObject('p_btn_basic_1')

    -- better
    self.luaItemRewardAdv1 = self:LuaObject('p_item_better_1')  or self:LuaObject('p_item_better_show_1')
    self.goAdvCanClaim1 = self:GameObject('p_img_receive_better_1')
    self.luaItemRewardAdv2 = self:LuaObject('p_item_better_2') or self:LuaObject('p_item_better_show_2')
    self.goAdvCanClaim2 = self:GameObject('p_img_receive_better_2')
    self.btnAdv = self:Button('p_btn_better', Delegate.GetOrCreate(self, self.OnBtnClaimAdvRewardClicked))
    self.gofixedBtnAdv = self:GameObject('p_btn_better_1')
    self.itemRewardAdvCtrler = {
        {
            lua = self.luaItemRewardAdv1,
            goCanClaim = self.goAdvCanClaim1,
        },
        {
            lua = self.luaItemRewardAdv2,
            goCanClaim = self.goAdvCanClaim2,
        },
    }

    self.progressReward = self:Slider('p_progress_reward')

    -- lv
    self.textLvOff = self:Text('p_text_lv_off')
    self.textLv = self:Text('p_text_lv_show')
    self.goImgHandle = self:GameObject('p_img_handle')

    self.statusCtrlerLv = self:StatusRecordParent('lv')
end

---@param param BattlePassRewardCellParam
function BattlePassRewardCell:OnFeedData(param)
    if not param then
        return
    end
    self.actId = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.BattlePass)
    self.cfgId = ModuleRefer.BattlePassModule:GetCurOpeningBattlePassId()
    self.isFixed = param.isFixed
    self.level = param.level
    self.curAchievedLevel = param.curAchievedLevel
    self:UpdateData()
    if not self.isFixed then
        self.btnBasic.gameObject:SetActive(self.normalStatus == BattlePassConst.REWARD_STATUS.CLAIMABLE)
        self.btnAdv.gameObject:SetActive(self.advStatus == BattlePassConst.REWARD_STATUS.CLAIMABLE)
    else
        self.gofixedBtnBasic:SetActive(false)
        self.gofixedBtnAdv:SetActive(false)
    end

    self:SetLv()
    self:SetProgress()
    self:SetBasicItem()
    self:SetAdvItem()
    if not self.isFixed then
        g_Game.EventManager:TriggerEvent(EventConst.BATTLEPASS_REWARD_CELL_SHOW_HIDE, self.level, true)
    end
    g_Game.EventManager:AddListener(EventConst.BATTLEPASS_REWARD_CLAIM, Delegate.GetOrCreate(self, self.OnRewardClaim))
    g_Game.EventManager:AddListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnRewardClaim))
end

function BattlePassRewardCell:OnRecycle()
    if not self.isFixed then
        g_Game.EventManager:TriggerEvent(EventConst.BATTLEPASS_REWARD_CELL_SHOW_HIDE, self.level, false)
    end

    g_Game.EventManager:RemoveListener(EventConst.BATTLEPASS_REWARD_CLAIM, Delegate.GetOrCreate(self, self.OnRewardClaim))
    g_Game.EventManager:RemoveListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnRewardClaim))
end

function BattlePassRewardCell:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.BATTLEPASS_REWARD_CLAIM, Delegate.GetOrCreate(self, self.OnRewardClaim))
    g_Game.EventManager:RemoveListener(EventConst.PAY_SUCCESS, Delegate.GetOrCreate(self, self.OnRewardClaim))
end

function BattlePassRewardCell:OnBtnClaimNormalRewardClicked()
    local id = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.BattlePass)
    ModuleRefer.BattlePassModule:ClaimReward(id, BattlePassConst.REWARD_CLAIM_TYPE.ALL, self.level, self.btnAdv.transform)
end

function BattlePassRewardCell:OnBtnClaimAdvRewardClicked()
    local id = ModuleRefer.ActivityCenterModule:GetCurOpeningAutoRewardId(ActivityRewardType.BattlePass)
    ModuleRefer.BattlePassModule:ClaimReward(id, BattlePassConst.REWARD_CLAIM_TYPE.ALL, self.level, self.btnAdv.transform)
end

function BattlePassRewardCell:OnRewardClaim()
    if Utils.IsNull(self.CSComponent) then return end
    -- if self.isFixed then return end
    self:UpdateData()
    if not self.isFixed then
        self.btnBasic.gameObject:SetActive(self.normalStatus == BattlePassConst.REWARD_STATUS.CLAIMABLE)
        self.btnAdv.gameObject:SetActive(self.advStatus == BattlePassConst.REWARD_STATUS.CLAIMABLE)
    else
        self.gofixedBtnBasic:SetActive(false)
        self.gofixedBtnAdv:SetActive(false)
    end
    self:SetBasicItem()
    self:SetAdvItem()
end

function BattlePassRewardCell:UpdateData()
    ---@type BattlePassNodeInfo
    self.nodeInfo = ModuleRefer.BattlePassModule:GetRewardInfosByCfgId(self.cfgId)[self.level]
    self.isVIP = ModuleRefer.BattlePassModule:IsVIP(self.cfgId)

    self.normalStatus, self.advStatus = ModuleRefer.BattlePassModule:GetRewardStatus(self.cfgId, self.level)
end

function BattlePassRewardCell:SetLv()
    local level = self.level
    if self.isFixed then
        self.textLv.text = tostring(level)
    else
        self.textLvOff.text = tostring(level)
    end
end

function BattlePassRewardCell:SetProgress()
    if self.isFixed then return end
    self.progressReward.value = (self.curAchievedLevel >= self.level and 1) or 0
    self.goImgHandle:SetActive(self.curAchievedLevel == self.level)
end

function BattlePassRewardCell:SetBasicItem()
    local rewardItemGroupId = self.nodeInfo.normal
    if not rewardItemGroupId then
        return
    end
    local item = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewardItemGroupId)[1]
    item.showTips = true
    item.received = self.normalStatus == BattlePassConst.REWARD_STATUS.CLAIMED
    item.claimable = self.normalStatus == BattlePassConst.REWARD_STATUS.CLAIMABLE
    self.luaItemRewardBasic:FeedData(item)
end

function BattlePassRewardCell:SetAdvItem()
    local rewardItemGroupId = self.nodeInfo.adv
    if not rewardItemGroupId then
        return
    end
    local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(rewardItemGroupId)
    for k, v in pairs(self.itemRewardAdvCtrler) do
        local item = items[k]
        if item then
            v.lua:SetVisible(true)
            item.showTips = true
            item.locked = not self.isVIP
            item.received = self.advStatus == BattlePassConst.REWARD_STATUS.CLAIMED
            item.claimable = self.advStatus == BattlePassConst.REWARD_STATUS.CLAIMABLE or
                (self.curAchievedLevel >= self.level and not self.isVIP)
            v.lua:FeedData(item)
        else
            v.lua:SetVisible(false)
            -- v.goCanClaim:SetActive(false)
        end
    end
end

return BattlePassRewardCell