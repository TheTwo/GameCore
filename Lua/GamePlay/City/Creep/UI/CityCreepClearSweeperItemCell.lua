local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class CityCreepClearSweeperItemCell:BaseTableViewProCell
local CityCreepClearSweeperItemCell = class('CityCreepClearSweeperItemCell', BaseTableViewProCell)
local UIHelper = require("UIHelper")

---@class CityCreepClearSweeperItemData
---@field itemCfg ItemConfigCell
---@field count number
---@field durability number
---@field selected boolean
---@field onClick fun(itemCfg, customData)

function CityCreepClearSweeperItemCell:OnCreate()
    self.gameObject = self:GameObject("")
    self._child_item_standard_s = self:LuaObject("child_item_standard_s")
    self._p_group_durability = self:GameObject("p_group_durability")
    self._p_text_durability = self:Text("p_text_durability")
end

---@param data CityCreepClearSweeperItemData
function CityCreepClearSweeperItemCell:OnFeedData(data)
    self.data = data
    
    ---@type ItemIconData
    self.itemIconData = self.itemIconData or {}
    self.itemIconData.configCell = data.itemCfg
    self.itemIconData.count = data.count
    self.itemIconData.showDurability = false
    self.itemIconData.showCount = false
    self.itemIconData.showSelect = data.selected
    self.itemIconData.onClick = data.onClick
    self.itemIconData.customData = data
    self._child_item_standard_s:FeedData(self.itemIconData)

    local showDurability = data.durability > 0 and data.count > 0
    self._p_group_durability:SetActive(showDurability)
    if showDurability then
        self._p_text_durability.text = tostring(data.durability)
    end
    UIHelper.SetGray(self.gameObject, not showDurability)
end

return CityCreepClearSweeperItemCell