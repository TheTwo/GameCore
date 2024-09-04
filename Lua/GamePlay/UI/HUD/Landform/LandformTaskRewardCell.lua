local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local LandformTaskState = require("LandformTaskState")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")

---@class LandformTaskRewardCellParameter
---@field index number
---@field landformConfigID number
---@field posX number
---@field score number
---@field state number
---@field itemGroupID number

---@class LandformTaskRewardCell : BaseUIComponent
---@field param LandformTaskRewardCellParameter
local LandformTaskRewardCell = class("LandformTaskRewardCell", BaseUIComponent)

function LandformTaskRewardCell:OnCreate(param)
    self.transform = self:Transform('')
    self.rectTransform = self:RectTransform('')
    self.p_img_light = self:GameObject("p_img_light")
    self.p_img_reward_n = self:Image("p_img_reward_n")
    self.p_img_reward_open = self:Image("p_img_reward_open")
    self.p_text_progress = self:Text("p_text_progress")
    self.p_btn_reward = self:Button("p_btn_reward", Delegate.GetOrCreate(self, self.OnRewardClicked))
end

---@param param LandformTaskRewardCellParameter
function LandformTaskRewardCell:OnFeedData(param)
    self.param = param
    
    self.transform.localPosition = CS.UnityEngine.Vector3(param.posX - self.rectTransform.rect.width, self.transform.localPosition.y, self.transform.localPosition.z)

    g_Game.SpriteManager:LoadSpriteAsync(("sp_shop_pack_close_0%s"):format(self.param.index), self.p_img_reward_n)
    g_Game.SpriteManager:LoadSpriteAsync(("sp_shop_pack_open_0%s"):format(self.param.index), self.p_img_reward_open)

    local canClaim = param.state == LandformTaskState.CanClaim
    local claimed = param.state == LandformTaskState.Claimed
    local notClaimed = param.state == LandformTaskState.NotClaimed
    self.p_img_light:SetVisible(canClaim)
    self.p_img_reward_n:SetVisible(canClaim or notClaimed)
    self.p_img_reward_open:SetVisible(claimed)
    self.p_text_progress.text = param.score
end

function LandformTaskRewardCell:OnRewardClicked()
    if self.param.state == LandformTaskState.CanClaim then
        ModuleRefer.LandformTaskModule:RequestClaimReward(self.param.landformConfigID, self.param.score)
    else
        self:ShowRewardDetail()
    end
end

function LandformTaskRewardCell:ShowRewardDetail()
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

return LandformTaskRewardCell