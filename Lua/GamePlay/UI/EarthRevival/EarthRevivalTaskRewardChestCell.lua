local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")
local ReceivePlanProgressRewardParameter = require("ReceivePlanProgressRewardParameter")
---@class EarthRevivalTaskRewardChestCell : BaseTableViewProCell
local EarthRevivalTaskRewardChestCell = class("EarthRevivalTaskRewardChestCell", BaseTableViewProCell)

---@class EarthRevivalTaskRewardChestCellParam
---@field neededPoints number
---@field canClaim boolean
---@field claimed boolean
---@field index number
---@field rewardId number
---@field selectedStage number
---@field lastNeededPoints number
---@field curPoints number

function EarthRevivalTaskRewardChestCell:OnCreate()
    self.sliderProgress = self:Slider('p_progress')
    self.goClaim = self:GameObject('p_img_claim')
    self.btnReward = self:Button('p_btn_reward', Delegate.GetOrCreate(self, self.OnBtnRewardClick))
    self.imgIconReward = self:Image('p_icon_reward')
    self.goReward = self:GameObject('p_icon_reward')
    self.goRewardOpen = self:GameObject('p_icon_reward_open')
    self.textPoints = self:Text('p_text_reward_num')
    self.notifyNode = self:LuaObject('child_reddot_default')
    self.vxTrigger = self:AnimTrigger('vx_trigger_task_reward')
end

---@param param EarthRevivalTaskRewardChestCellParam
function EarthRevivalTaskRewardChestCell:OnFeedData(param)
    self.neededPoints = param.neededPoints
    self.canClaim = param.canClaim
    self.index = param.index
    self.lastNeededPoints = param.lastNeededPoints
    self.curPoints = param.curPoints
    self.selectedStage = param.selectedStage
    self.claimed = param.claimed

    self.textPoints.text = self.neededPoints
    local percent = (self.curPoints - self.lastNeededPoints) / (self.neededPoints - self.lastNeededPoints)
    self.sliderProgress.value = percent

    self.rewardId = ModuleRefer.EarthRevivalModule.taskModule:GetProgressRewardsByCfgId(self.selectedStage)[self.index]
    self.rewardList = ModuleRefer.EarthRevivalModule.taskModule:GetProgressRewardInItemIconData(self.selectedStage, self.index)

    if self.canClaim then
        self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
    else
        self.vxTrigger:ResetAll(CS.FpAnimation.CommonTriggerType.Custom1)
    end
    self.goReward:SetActive(not self.claimed)
    self.goRewardOpen:SetActive(self.claimed)
end

function EarthRevivalTaskRewardChestCell:OnBtnRewardClick()
    if self.canClaim then
        local msg = ReceivePlanProgressRewardParameter.new()
        msg.args.PlanConfigId = self.selectedStage
        msg.args.Progress = self.neededPoints
        msg:SendOnceCallback(self.btnReward.transform, nil, nil, function (_, isSuccess, _)
            if isSuccess then
                ModuleRefer.EarthRevivalModule.taskModule:UpdateReddot()
                self.vxTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
            end
        end)
    else
        ---@type GiftTipsUIMediatorParameter
        local data = {}
        data.arrowDirection = -1
        data.clickTrans = self.btnReward.transform
        local listInfo = {}
        for _, reward in ipairs(self.rewardList) do
            local info = {}
            info.itemId = reward.configCell:Id()
            info.itemCount = reward.count
            table.insert(listInfo, info)
        end
        data.listInfo = listInfo
        g_Game.UIManager:Open(UIMediatorNames.GiftTipsUIMediator, data)
    end
end

return EarthRevivalTaskRewardChestCell