local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local AllianceBossEventRewardState = require("AllianceBossEventRewardState")

---@class AllianceBossEventRewardParameter
---@field index number
---@field score number
---@field itemGroupID number
---@field type number @wrpc.AllianceScoreRewardReceiveType
---@field posX number
---@field activityExpeditionConfig AllianceActivityExpeditionConfigCell

---@class AllianceBossEventRewardCell : BaseTableViewProCell
local AllianceBossEventRewardCell = class("AllianceBossEventRewardCell", BaseTableViewProCell)

function AllianceBossEventRewardCell:OnCreate()
    self.transform = self:Transform('')
    self.rectTransform = self:RectTransform('')
    self.p_btn_reward = self:Button('p_btn_reward', Delegate.GetOrCreate(self, self.OnBtnClick))
    self.p_img_claim = self:GameObject("p_img_claim")
    self.p_icon_reward_n = self:GameObject("p_icon_reward_n")
    self.p_icon_reward_open = self:GameObject("p_icon_reward_open")
    self.p_text_reward_num = self:Text("p_text_reward_num")
end

---@param param AllianceBossEventRewardParameter
function AllianceBossEventRewardCell:OnFeedData(param)
    self.param = param

    local state = ModuleRefer.AllianceBossEventModule:GetStageRewardState(self.param.activityExpeditionConfig, self.param.type, self.param.index)
    local canClaim = state == AllianceBossEventRewardState.CanClaim
    local claimed = state == AllianceBossEventRewardState.Claimed
    local notClaimed = state == AllianceBossEventRewardState.NotClaimed
    self.p_img_claim:SetVisible(canClaim)
    self.p_icon_reward_n:SetVisible(canClaim or notClaimed)
    self.p_icon_reward_open:SetVisible(claimed)
    
    self.p_text_reward_num.text = self.param.score

    self.transform.localPosition = CS.UnityEngine.Vector3(param.posX - self.rectTransform.rect.width / 2, self.transform.localPosition.y, self.transform.localPosition.z)
end

function AllianceBossEventRewardCell:OnBtnClick()
    local state = ModuleRefer.AllianceBossEventModule:GetStageRewardState(self.param.activityExpeditionConfig, self.param.type, self.param.index)
    if state == AllianceBossEventRewardState.CanClaim then
        ModuleRefer.AllianceBossEventModule:RequestClaimReward(self.param.activityExpeditionConfig, self.param.index, self.param.type)
    else
        self:ShowRewardDetail()
    end
    
end

function AllianceBossEventRewardCell:ShowRewardDetail()
    ---@type GiftTipsUIMediatorParameter
    local param = {}
    param.clickTrans = self.rectTransform
    param.listInfo = {}
    param.listInfo[1] = {titleText = I18N.Get("alliance_gift_details_title")}
    
    local itemGroupConfig = ConfigRefer.ItemGroup:Find(self.param.itemGroupID)
    local length = itemGroupConfig:ItemGroupInfoListLength()
    for i = 1, length do
        local itemInfo = itemGroupConfig:ItemGroupInfoList(i)
        ---@type GiftTipsListInfoCell
        local cellData = {}
        cellData.itemId = itemInfo:Items()
        cellData.itemCount = itemInfo:Nums()
        cellData.iconShowCount = true
        table.insert(param.listInfo, cellData)
    end
    g_Game.UIManager:Open(UIMediatorNames.GiftTipsUIMediator, param)
end

return AllianceBossEventRewardCell