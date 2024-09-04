local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local QualityColorHelper = require("QualityColorHelper")
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")
---@class ActivityLandformRewardCell : BaseTableViewProCell
local ActivityLandformRewardCell = class("ActivityLandformRewardCell", BaseTableViewProCell)

---@class ActivityLandformRewardCellData
---@field index number
---@field landExploreId number
---@field activityRewardId number
---@field posX number

function ActivityLandformRewardCell:ctor()
    self.canReceive = false
    self.received = false
    self.rewardItemGroupId = 0
end

function ActivityLandformRewardCell:OnCreate()
    self.textScore = self:Text("p_text_score")
    self.btnReward = self:Button("p_btn_reward", Delegate.GetOrCreate(self, self.OnRewardBtnClick))

    self.goReceived = self:GameObject("p_received")
    self.luaReddot = self:LuaObject("child_reddot_default")

    self.imgIcon = self:Image("p_img")
    self.imgBase = self:Image("p_base")

    self.goRoot = self:GameObject("")
    self.rectTransform = self:RectTransform("")

    self.goClaim = self:GameObject("p_claim")
end

---@param data ActivityLandformRewardCellData
function ActivityLandformRewardCell:OnFeedData(data)
    self.data = data

    local curScore = ModuleRefer.ActivityLandformModule:GetCurScore(data.landExploreId)
    local rewardScore = ModuleRefer.ActivityLandformModule:GetRewardScore(data.landExploreId, data.index)
    self.received = ModuleRefer.ActivityLandformModule:IsRewardReceived(data.landExploreId, data.index)
    self.canReceive = curScore >= rewardScore and not self.received

    self.goClaim:SetActive(self.canReceive)

    self.textScore.text = rewardScore
    self.goReceived:SetActive(self.received)
    self.luaReddot:SetVisible(self.canReceive)

    self.rewardItemGroupId = ModuleRefer.ActivityLandformModule:GetRewardItemGroupId(data.landExploreId, data.index)
    local displayItem = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(self.rewardItemGroupId)[1]
    local icon = displayItem.configCell:Icon()
    g_Game.SpriteManager:LoadSprite(icon, self.imgIcon)

    local quality = displayItem.configCell:Quality()
    local baseFrame = QualityColorHelper.GetQualityCircleBaseIcon(quality, QualityColorHelper.Type.Item)
    g_Game.SpriteManager:LoadSprite(baseFrame, self.imgBase)

    local pos = self.goRoot.transform.localPosition
    pos.x = data.posX - self.rectTransform.rect.width / 2
    pos.y = pos.y - self.rectTransform.rect.height / 2
    self.goRoot.transform.localPosition = pos
end

function ActivityLandformRewardCell:OnRewardBtnClick()
    if self.canReceive then
        ModuleRefer.ActivityLandformModule:ReceiveReward(self.data.activityRewardId, self.data.index, self.btnReward.transform)
    else
        local items = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(self.rewardItemGroupId)
        local rewardLists = {{titleText = I18N.Get("landexplore_reward_list")}}
        for _, item in ipairs(items) do
            rewardLists[#rewardLists + 1] = {itemId = item.configCell:Id(), itemCount = item.count}
        end
        local giftTipsParam = {listInfo = rewardLists, clickTrans = self.btnReward.gameObject.transform,
            maxHeight = 800, shouldAdapt = true}
        g_Game.UIManager:Open(UIMediatorNames.GiftTipsUIMediator, giftTipsParam)
    end
end

return ActivityLandformRewardCell