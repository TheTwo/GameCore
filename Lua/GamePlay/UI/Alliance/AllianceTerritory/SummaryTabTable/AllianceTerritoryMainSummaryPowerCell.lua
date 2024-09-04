local BaseTableViewProCell = require("BaseTableViewProCell")
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EarthRevivalDefine = require('EarthRevivalDefine')
local CommonDailyGiftState = require('CommonDailyGiftState')
local AllianceModuleDefine = require('AllianceModuleDefine')
local NotificationType = require('NotificationType')
local UIMediatorNames = require('UIMediatorNames')
local ConfigRefer = require('ConfigRefer')

---@class AllianceTerritoryMainSummaryPowerCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryPowerCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryPowerCell = class('AllianceTerritoryMainSummaryPowerCell', BaseTableViewProCell)

function AllianceTerritoryMainSummaryPowerCell:OnCreate(param)
    self._p_text_power = self:Text("p_text_power", "Alliance_bj_shilizhi")
    self._p_text_power_numer = self:Text("p_text_power_numer")
    self.p_gift_daily = self:LuaObject('p_gift_daily')
end

---@param num number
function AllianceTerritoryMainSummaryPowerCell:OnFeedData(num)
    self.state = ModuleRefer.AllianceModule:GetDailyRewardState()
    self.num = num
    self._p_text_power_numer.text = tostring(num)

    ---@type CommonDailyGiftData
    local data = {}
    data.state = self.state
    data.customCloseIcon = EarthRevivalDefine.EarthRevivalNews_CanClaimRewardIcon
    data.customOpenIcon = EarthRevivalDefine.EarthRevivalNews_HasClaimRewardIcon
    data.onClickWhenClosed = Delegate.GetOrCreate(self, self.OnDailyRewardClick)
    data.onClickWhenOpened = Delegate.GetOrCreate(self, self.OnDailyRewardClick)
    self.p_gift_daily:FeedData(data)
    local redDotNode = self.p_gift_daily.child_reddot_default
    -- 设置红点
    local node = ModuleRefer.NotificationModule:GetDynamicNode(AllianceModuleDefine.NotifyNodeType.TerritoryDailyGift, NotificationType.ALLIANCE_TERRITORY_DAILY_GIFT)
    ModuleRefer.NotificationModule:AttachToGameObject(node, redDotNode.go, redDotNode.redDot)

end

function AllianceTerritoryMainSummaryPowerCell:OnDailyRewardClick()
    if self.state == CommonDailyGiftState.CanCliam then
        self.state = CommonDailyGiftState.HasCliamed
        self.p_gift_daily:ChangeState(self.state)
        local req = require('GetDailyFactionRewardParameter').new()
        req:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, isSuccess, rsp)
        if isSuccess then
           local cfg = ConfigRefer.AllianceConsts
            local lastIndex = cfg:FactionDailyRewardNeedFactionLength()
            local index = 0
            for i = 1, lastIndex do
                if self.num >= cfg:FactionDailyRewardNeedFaction(i) then
                    index = index + 1
                else
                    break
                end
            end
            index = math.min(index,lastIndex)
            local items = {}
            local itemGroupCfg = ConfigRefer.ItemGroup:Find(cfg:FactionDailyRewardItemGroup(index))
            local count = itemGroupCfg:ItemGroupInfoListLength()
            for i = 1, count do
                local itemGroup = itemGroupCfg:ItemGroupInfoList(i)
                table.insert(items, {id = itemGroup:Items(), count = itemGroup:Nums()})
            end
            g_Game.UIManager:Open(UIMediatorNames.UIRewardMediator, {itemInfo = items}) 
        end
    end)
    elseif self.state == CommonDailyGiftState.HasCliamed then
        g_Game.UIManager:Open(UIMediatorNames.AllianceTerritoryMainSummaryDailyGiftMediator, self.num)
    end

end

return AllianceTerritoryMainSummaryPowerCell
