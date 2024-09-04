local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')
local I18N = require('I18N')
local DBEntityPath = require('DBEntityPath')
local ModuleRefer = require('ModuleRefer')
local ReceiveDailyRewardParameter = require('ReceiveDailyRewardParameter')
local ConfigeRefer = require('ConfigRefer')
local ActivityShopConst = require('ActivityShopConst')
local NotificationType = require('NotificationType')
---@class ActivityShopCyclePack : BaseUIComponent
local ActivityShopCyclePack = class('ActivityShopCyclePack', BaseUIComponent)

function ActivityShopCyclePack:OnCreate()
    self.textTitle = self:Text('p_text_title', ActivityShopConst.I18N_KEYS.TITLE_DAILY)
    self.textSubTitle = self:Text('p_text_title_1', ActivityShopConst.I18N_KEYS.DESC_DAILY)
    self.btnClosedChest = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnClosedChestClicked))
    self.textClosedChest = self:Text('p_text_gift', ActivityShopConst.I18N_KEYS.NAME_DAILY_GIFT)
    self.btnOpenChest = self:Button('p_btn_open', Delegate.GetOrCreate(self, self.OnBtnOpenChestClicked))
    self.textOpenChest = self:Text('p_text_claimed', ActivityShopConst.I18N_KEYS.CLAIMED_DAILY_GIFT)
    self.tablePack = self:TableViewPro('p_table_pack')

    self.textTime = self:Text('p_text_time', ActivityShopConst.I18N_KEYS.TIME_DAILY)
    self.textTimeDetail = self:Text('p_text_time_1')

    self.giftNotifyNode = self:LuaObject('child_reddot_default')
    self.vxTrigger = self:AnimTrigger('vx_trigger')
end

function ActivityShopCyclePack:OnFeedData(param)
    if not param then
        return
    end
    self.isClaimed = not self:IsDailyRewardCanClaim()
    self.packGroups = param.openedPackGroups
    self.tabId = param.tabId

    local notifyLogicNode = ModuleRefer.NotificationModule:GetDynamicNode(
        ActivityShopConst.NotificationNodeNames.ActivityShopPack .. ActivityShopConst.DALIY_GIFT_PSEUDO_ID,
        NotificationType.ACTIVITY_SHOP_PACK)
    ModuleRefer.NotificationModule:AttachToGameObject(notifyLogicNode, self.giftNotifyNode.go, self.giftNotifyNode.redDot)

    self:FillTable()
    self:InitInfo()
    self:TimeSecTicker()
end

function ActivityShopCyclePack:OnShow()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.TimeSecTicker))
end

function ActivityShopCyclePack:OnHide()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.TimeSecTicker))
end

function ActivityShopCyclePack:InitInfo()
    self.btnClosedChest.gameObject:SetActive(not self.isClaimed)
    self.btnOpenChest.gameObject:SetActive(self.isClaimed)
    if not self.isClaimed then
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    else
        self.vxTrigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
    ModuleRefer.ActivityShopModule:UpdateRedDotByGroupId(ActivityShopConst.DALIY_GIFT_PSEUDO_ID, not self.isClaimed)
end

function ActivityShopCyclePack:FillTable()
    table.sort(self.packGroups, ModuleRefer.ActivityShopModule.GoodsIsSoldOutComparator)
    self.tablePack:Clear()
    for i, id in ipairs(self.packGroups) do
        local param = {
            index = i,
            packGroupId = id,
        }
        self.tablePack:AppendData(param)
    end
end

function ActivityShopCyclePack:IsDailyRewardCanClaim()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local nextCanClaimTime = player.PlayerWrapper2.PlayerPay.NextDailyRewardDayBegin.Seconds
    return curTime > nextCanClaimTime
end

function ActivityShopCyclePack:OnBtnClosedChestClicked()
    local parameter = ReceiveDailyRewardParameter.new()
    parameter.args.ItemGroupId = ConfigeRefer.ConstMain:PayDailyReward()
    local lockable = self.btnClosedChest.transform
    parameter:SendOnceCallback(lockable, nil, nil, function(_, isSuccess, _)
        if isSuccess then
            self.isClaimed = true
            self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2, Delegate.GetOrCreate(self, self.InitInfo))
        end
    end)
end

function ActivityShopCyclePack:TimeSecTicker()
    local d, h, m, s = ModuleRefer.ActivityShopModule:GetTabRemainingTimeInDHMS(self.tabId)
    self.textTimeDetail.text = I18N.GetWithParams(ActivityShopConst.I18N_KEYS.TIME_DETAIL_DAILY, string.format('%02d:%02d:%02d', h, m, s))
end

return ActivityShopCyclePack