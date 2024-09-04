---Scene Name: scene_se_tips_rewards
local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require("Delegate")
local DBEntityPath = require('DBEntityPath')
local ModuleRefer = require("ModuleRefer")
local ItemPopType = require("ItemPopType")

---@class UIRewardTipsMediator : BaseUIMediator
local UIRewardTipsMediator = class('UIRewardTipsMediator', BaseUIMediator)

function UIRewardTipsMediator:OnCreate()
    self.titleText = self:Text("p_text_title", "battlepass_tab_all_claim_btn_title")
    self.table = self:TableViewPro("p_table")
    self.claimButton = self:Button("p_btn_claim", Delegate.GetOrCreate(self, self.OnClaim))
    self.claimText = self:Text("p_text", "alliance_behemothCage_button_get")
end

function UIRewardTipsMediator:OnShow(param)
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper3.PlayerRewardBox.MsgPath, Delegate.GetOrCreate(self, self.PlayerRewardBoxChanged))
    self:Refresh()
end

function UIRewardTipsMediator:OnHide(param)
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper3.PlayerRewardBox.MsgPath, Delegate.GetOrCreate(self, self.PlayerRewardBoxChanged))
end

function UIRewardTipsMediator:OnClaim()
    local param = require("PlayerOneClickGetRewardBoxParameter").new()
    param:Send()

    local data = self:MakeRewardAnimData()
    ModuleRefer.RewardModule:ShowLightReward(data)

    self:CloseSelf()
end

function UIRewardTipsMediator:PlayerRewardBoxChanged()
    self:Refresh()
end

function UIRewardTipsMediator:Refresh()
    self.table:Clear()
    
    local boxes = ModuleRefer.PlayerModule:GetRewardBoxes()
    for _, box in ipairs(boxes) do
        self.table:AppendData(box)
    end
end

function UIRewardTipsMediator:MakeRewardAnimData()
    local data =
    {
        ItemCount = {},
        ItemID = {},
        ProfitReason = wds.enum.ItemProfitType.ItemAddPay,
        PopType = ItemPopType.PopTypeLightReward,
        Pos = {X = 0, Y = 0},
    }

    local boxes = ModuleRefer.PlayerModule:GetRewardBoxes()
    for _, box in ipairs(boxes) do
        for _, attachment in ipairs(box.AttachmentList) do
            table.insert(data.ItemCount, attachment.ItemNum)
            table.insert(data.ItemID, attachment.ItemID)
        end
    end

    return data
end

return UIRewardTipsMediator