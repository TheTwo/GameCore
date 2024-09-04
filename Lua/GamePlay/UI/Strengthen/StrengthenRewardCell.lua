local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require("ModuleRefer")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local UIMediatorNames = require("UIMediatorNames")
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local ReceivePowerProgressRewardParameter = require('ReceivePowerProgressRewardParameter')

---@class StrengthenRewardCell:BaseUIComponent
local StrengthenRewardCell = class('StrengthenRewardCell', BaseTableViewProCell)

function StrengthenRewardCell:OnCreate()
    self.goCircle = self:GameObject('vx_novice_circle_high')
    self.sliderGrogressPower = self:Slider('p_grogress_power')
    self.btnBubbleReward = self:Button('p_btn_bubble_reward', Delegate.GetOrCreate(self, self.OnBtnBubbleRewardClicked))
    self.imgImgFarme = self:Image('p_img_farme')
    self.goStatusA = self:GameObject('p_status_a')
    self.imgIconItem = self:Image('p_icon_item')
    self.textQuantity = self:Text('p_text_quantity')
    self.goStatusB = self:GameObject('p_status_b')
    self.textProgress = self:Text('p_text_progress')
    self.animtriggerTriggerReward = self:AnimTrigger('trigger_reward')
end

function StrengthenRewardCell:OnFeedData(id)
    local playerData =  ModuleRefer.PlayerModule:GetPlayer()
    local curPowerIndex = playerData.PlayerWrapper2.PowerProgress.ReachedMaxPowerProgressId or 0
    local canRewardIndexs = playerData.PlayerWrapper2.PowerProgress.CanReceiveRewardProgressIds
    self.id = id
    local config = ConfigRefer.PowerProgress:Find(id)
    local curPowerValue = config:PowerValue()
    self.textProgress.text = curPowerValue
    local curPower = playerData.PlayerWrapper2.PlayerPower.TotalPower
    local lastIndexPower = 0
    if id > 1 then
        lastIndexPower = ConfigRefer.PowerProgress:Find(id - 1):PowerValue()
    end
    local offsetValue = curPowerValue - lastIndexPower
    local progress = curPower - lastIndexPower
    self.sliderGrogressPower.value = math.clamp(progress / offsetValue, 0, 1)
    local isCanReward = curPowerIndex >= id and table.ContainsValue(canRewardIndexs, id)
    local isGotReward = curPowerIndex >= id and not table.ContainsValue(canRewardIndexs, id)
    self.goStatusA:SetActive(isCanReward)
    self.goStatusB:SetActive(isGotReward)
    local itemInfo = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(config:Reward())[1]
    self.textQuantity.text = "x" .. itemInfo.count
    g_Game.SpriteManager:LoadSprite(config:Icon(), self.imgIconItem)
    g_Game.SpriteManager:LoadSprite('sp_item_frame_circle_'..tostring(itemInfo.configCell:Quality()), self.imgImgFarme)
    if isCanReward then
        self.animtriggerTriggerReward:PlayAll(FpAnimTriggerEvent.Custom1)
    else
        self.animtriggerTriggerReward:ResetAll(FpAnimTriggerEvent.Custom1)
    end
    self.isCanReward = isCanReward
    self.itemId = itemInfo.configCell:Id()
    self.goCircle:SetActive(isCanReward and not isGotReward)
end

function StrengthenRewardCell:OnBtnBubbleRewardClicked(args)
    if self.isCanReward then
        local onFinish = function()
            local param = ReceivePowerProgressRewardParameter.new()
            param.args.PowerProgressId = self.id
            param:Send(self.btnBubbleReward.transform)
        end
        self.animtriggerTriggerReward:PlayAll(FpAnimTriggerEvent.Custom2, onFinish)
    else
        local param = {
            itemId = self.itemId,
            itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM,
        }
        g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
    end
end

return StrengthenRewardCell
