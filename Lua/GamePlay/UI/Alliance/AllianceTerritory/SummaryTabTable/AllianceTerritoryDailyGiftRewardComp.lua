local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')

local BaseTableViewProCell = require("BaseTableViewProCell")
local AllianceTerritoryDailyGiftRewardComp = class('AllianceTerritoryDailyGiftRewardComp', BaseTableViewProCell)

function AllianceTerritoryDailyGiftRewardComp:OnCreate(param)
    self.p_progress = self:Slider('p_progress')
    self.p_influence_normal = self:GameObject('p_influence_normal')
    self.p_influence_reach = self:GameObject('p_influence_reach')
    self.p_table_reward = self:TableViewPro('p_table_reward')
    self.p_text_quantity = self:Text('p_text_quantity')
end

function AllianceTerritoryDailyGiftRewardComp:OnFeedData(data)
    self.p_text_quantity.text = data.value
    self.p_influence_normal:SetVisible(not data.isReach)
    self.p_influence_reach:SetVisible(data.isReach)
    self.p_text_quantity.color = data.isReach and UIHelper.TryParseHtmlString(ColorConsts.white) or UIHelper.TryParseHtmlString(ColorConsts.white_grey)
    self.p_progress:SetVisible(not data.isLast)
    self.p_progress.value = data.percent
    self.p_table_reward:Clear()
    for i = 1, data.itemGroup:ItemGroupInfoListLength() do
        local itemGroup = data.itemGroup:ItemGroupInfoList(i)
        local iconData = {}
        iconData.configCell = ConfigRefer.Item:Find(itemGroup:Items())
        iconData.count = itemGroup:Nums()
        self.p_table_reward:AppendData(iconData)
    end
end

return AllianceTerritoryDailyGiftRewardComp
