local BaseTableViewProCell = require('BaseTableViewProCell')
local MailUtils = require("MailUtils")

---@class UIRewardTipsCell : BaseTableViewProCell
local UIRewardTipsCell = class('UIRewardTipsCell',BaseTableViewProCell)

function UIRewardTipsCell:OnCreate()
    self.nameText = self:Text("p_text_name")
    ---@type CommonMonsterIconSmall
    self.monsterIcon = self:LuaObject("p_monster_s")
    self.rewardTable = self:TableViewPro("p_table_rewards")
    self.fistBloodTag = self:GameObject("p_tag")
    self.fistBloodTagText = self:Text("p_text_tag", "searchentity_info_firstkill_reward")
end

---@param data wds.RewardBoxInfo
function UIRewardTipsCell:OnFeedData(data)
    self.data = data
    self:Refresh()
end

function UIRewardTipsCell:Refresh()
    self.fistBloodTag:SetActive(false)
    local basicInfo = self.data.BasicInfo
    if basicInfo.Type == wds.RewardBoxType.RewardBoxType_OfflineTeamTrusteeship then
        self:UpdateMonsterInfo(basicInfo.ConfId)
    elseif basicInfo.Type == wds.RewardBoxType.RewardBoxType_LoseFocusSE then
        self:UpdateSeInfo(basicInfo.ConfId)
    elseif basicInfo.Type == wds.RewardBoxType.RewardBoxType_NormalMobLevelFirstKill then
        self:UpdateMonsterInfo(basicInfo.ConfId)
        self.fistBloodTag:SetActive(true)
    end

    self.rewardTable:Clear()

    local attachments = self.data.AttachmentList
    for _, value in ipairs(attachments) do
        self.rewardTable:AppendData(value)
    end
end

function UIRewardTipsCell:UpdateMonsterInfo(configId)
    local name, icon, level = MailUtils.GetMonsterNameIconLevel(configId)
    self.nameText.text = "Lv." .. level .. " " .. name
    self.monsterIcon:FeedData({
        sprite = icon
    })
end

function UIRewardTipsCell:UpdateSeInfo(configId)

end

return UIRewardTipsCell