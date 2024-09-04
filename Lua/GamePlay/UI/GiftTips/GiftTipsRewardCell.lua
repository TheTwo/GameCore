local BaseTableViewProCell = require("BaseTableViewProCell")
local ConfigRefer = require('ConfigRefer')
local I18N = require("I18N")
local GiftTipsRewardCell = class("GiftTipsRewardCell", BaseTableViewProCell)

function GiftTipsRewardCell:OnCreate()
	self.compChildItemStandardS = self:LuaBaseComponent('child_item_standard_s')
    self.textName = self:Text('p_text_name')
    self.textQuantity = self:Text('p_text_quantity')
end

---@param data GiftTipsListInfoCell
function GiftTipsRewardCell:OnFeedData(data)
	if not data then
		return
	end
	local itemCfg = ConfigRefer.Item:Find(data.itemId)
	self.textName.text = I18N.Get(itemCfg:NameKey())
	if data.itemCountText then
		self.textQuantity.text = data.itemCountText
	else
		self.textQuantity.text = "x" .. data.itemCount
	end
	---@type ItemIconData
	local itemData = {
		configCell = itemCfg,
		showTips = true,
		showCount = data.iconShowCount or false,
		count = data.iconShowCount and data.itemCount or 0
	}
	self.compChildItemStandardS:FeedData(itemData)
end

return GiftTipsRewardCell