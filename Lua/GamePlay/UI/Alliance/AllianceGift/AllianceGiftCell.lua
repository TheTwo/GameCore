local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")
local UIMediatorNames = require("UIMediatorNames")
local ItemPopType = require("ItemPopType")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceGiftCellData
---@field serverData wds.AllianceGiftInfo
---@field host AllianceGiftMediator

---@class AllianceGiftCell:BaseTableViewProCell
---@field new fun():AllianceGiftCell
---@field super BaseTableViewProCell
local AllianceGiftCell = class('AllianceGiftCell', BaseTableViewProCell)

function AllianceGiftCell:ctor()
    AllianceGiftCell.super.ctor(self)
    self._timerAdd = false
end

function AllianceGiftCell:OnCreate(param)
    self._p_icon_gift = self:Image("p_icon_gift", Delegate.GetOrCreate(self, self.OnClickGiftIcon))
    self._p_icon_gift.raycastTarget = true
    self._p_time = self:GameObject("p_time")
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")
    self._p_dated = self:GameObject("p_dated")
    self._p_text_dated = self:Text("p_text_dated", "alliance_gift_expire")
    self._p_text_name = self:Text("p_text_name")
    self._p_text_player = self:Text("p_text_player")
    self._p_group_resources = self:GameObject("p_group_resources")
    ---@type CommonPairsQuantity[]
    self._p_resources = {}
    self._p_resources[1] = self:LuaObject("p_resources_1")
    self._p_resources[2] = self:LuaObject("p_resources_2")
    self._p_btn_claim = self:Button("p_btn_claim", Delegate.GetOrCreate(self, self.OnClickBtnClaim))
    self._p_icon_received = self:GameObject("p_icon_received")
end

---@param data AllianceGiftCellData
function AllianceGiftCell:OnFeedData(data)
    self._giftInfo = data.serverData
    self._host = data.host
    local config = ConfigRefer.AllianceGift:Find(self._giftInfo.ConfigId)
    self._p_text_name.text = I18N.Get(config:Name())
    self._p_text_player.text = I18N.GetWithParams(config:Desc(),self._giftInfo.SourceName)
    if not self._giftInfo.IsGet then
        g_Game.SpriteManager:LoadSprite(config:Icon(), self._p_icon_gift)
        self._p_group_resources:SetVisible(false)
    else
        g_Game.SpriteManager:LoadSprite(config:IconOpen(), self._p_icon_gift)
        self._p_group_resources:SetVisible(true)
        ---@type CommonPairsQuantityParameter
        local addExp = {}
        addExp.itemIcon = 'sp_icon_league_bonus_points'
        addExp.num1 = ("+%d"):format(config:AddExp())
        addExp.num2 = ''
        self._p_resources[1]:FeedData(addExp)
        ---@type CommonPairsQuantityParameter
        local addCoin = {}
        addCoin.itemIcon = 'sp_icon_item_league_key'
        addCoin.num1 = ("+%d"):format(config:AddPoint())
        addCoin.num2 = ''
        self._p_resources[2]:FeedData(addCoin)
    end
    self._child_time:RecycleTimer()
    if self._giftInfo.IsGet then
        self._p_time:SetVisible(false)
        self._p_icon_received:SetVisible(true)
        self._p_btn_claim:SetVisible(false)
        self._p_dated:SetVisible(false)
    else
        self._p_icon_received:SetVisible(false)
        local nowTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
        local isExpired = nowTime > self._giftInfo.ExpirationTime.ServerSecond
        UIHelper.SetGray(self._p_btn_claim.gameObject, isExpired)
        ---@type CommonTimerData
        local timerData = {}
        if not isExpired then
            self._p_btn_claim:SetVisible(true)
            self._p_time:SetVisible(true)
            timerData.endTime = self._giftInfo.ExpirationTime.ServerSecond
            timerData.needTimer = true
            timerData.callBack = Delegate.GetOrCreate(self, self.OnExpiredTimeEnd)
            self._child_time:FeedData(timerData)
            self._p_dated:SetVisible(false)
        else
            self._p_btn_claim:SetVisible(false)
            self._p_dated:SetVisible(true)
            self._p_time:SetVisible(false)
        end
    end
end

function AllianceGiftCell:OnRecycle()
    self._child_time:RecycleTimer()
end

function AllianceGiftCell:OnClose(param)
    self._child_time:RecycleTimer()
end

function AllianceGiftCell:OnExpiredTimeEnd()
    self._p_icon_received:SetVisible(false)
    self._p_btn_claim:SetVisible(true)
    UIHelper.SetGray(self._p_btn_claim.gameObject, true)
    self._child_time.timerText.text = I18N.Get("alliance_gift_expire")
end

function AllianceGiftCell:OnClickBtnClaim()
    if not self._giftInfo or self._giftInfo.IsGet then
        return
    end
    if self._host and self._host:IsPlayingEffect() then return end
    local giftId = self._giftInfo.GiftID
    ModuleRefer.AllianceModule:GetAllianceGiftReward(self._p_btn_claim.transform, giftId, function(cmd, isSuccess, rsp)
        ---@type AllianceGiftMediator
        local ui = self:GetParentBaseUIMediator()
        if isSuccess then
			g_Game.SoundManager:Play("sfx_se_world_alliancegift_key")
            if ui and ui.LocalSetCellIsGet then
                ui:LocalSetCellIsGet(giftId)
            end
            if rsp and not table.isNilOrZeroNums(rsp.Reward) then
                local dummyData = wrpc.PushRewardRequest.New(nil, wds.enum.ItemProfitType.ItemAddByOpenBox, ItemPopType.PopTypeLightReward,nil)
                for itemId, count in pairs(rsp.Reward) do
                    dummyData.ItemID:Add(itemId)
                    dummyData.ItemCount:Add(count)
                end
                ModuleRefer.RewardModule:ShowLightReward(dummyData)
            end
        else
            if ui and ui.FetchData then
                ui:FetchData()
            end
        end
    end)
end

function AllianceGiftCell:OnClickGiftIcon()
    if not self._giftInfo then
        return
    end
    ---@type GiftTipsUIMediatorParameter
    local param = {}
    param.clickTrans = self._p_icon_gift.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
    param.listInfo = {}
    param.listInfo[1] = {titleText = I18N.Get("alliance_gift_details_title")}
    local config = ConfigRefer.AllianceGift:Find(self._giftInfo.ConfigId)
    local randomBox = ConfigRefer.RandomBox:Find(config:Reward())
    local totalWeight = 0
    for i = 1, randomBox:GroupInfoLength() do
        local groupInfo = randomBox:GroupInfo(i)
        totalWeight = totalWeight + groupInfo:Weights()
    end
    for i = 1, randomBox:GroupInfoLength() do
        local groupInfo = randomBox:GroupInfo(i)
        local groupItem = ConfigRefer.ItemGroup:Find(groupInfo:Groups())
        local localWeight = 0
        for j = 1, groupItem:ItemGroupInfoListLength() do
            local itemInfo = groupItem:ItemGroupInfoList(j)
            localWeight = localWeight + itemInfo:Weights()
        end
        for j = 1, groupItem:ItemGroupInfoListLength() do
            local itemInfo = groupItem:ItemGroupInfoList(j)
            ---@type GiftTipsListInfoCell
            local cellData = {}
            cellData.itemId = itemInfo:Items()
            cellData.itemCount = itemInfo:Nums()
            cellData.iconShowCount = true
            local weight = (localWeight > 0 and (itemInfo:Weights() / localWeight) or 0) * (totalWeight > 0 and groupInfo:Weights() / totalWeight or 0)
            cellData.itemCountText = (("%0.1f%%"):format(weight * 100))
            table.insert(param.listInfo, cellData)
        end
    end
    g_Game.UIManager:Open(UIMediatorNames.GiftTipsUIMediator, param)
end

return AllianceGiftCell
