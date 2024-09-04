local ConfigRefer = require("ConfigRefer")
local UIHelper = require("UIHelper")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceStoreHouseResLogTypeCell:BaseTableViewProCell
---@field new fun():AllianceStoreHouseResLogTypeCell
---@field super BaseTableViewProCell
local AllianceStoreHouseResLogTypeCell = class('AllianceStoreHouseResLogTypeCell', BaseTableViewProCell)

function AllianceStoreHouseResLogTypeCell:OnCreate(param)
    self._p_icon_res_cost = self:Image("p_icon_res_cost")
    self._p_text_res_cost_num = self:Text("p_text_res_cost_num")
end

---@param data wds.AllianceCurrencyLog
function AllianceStoreHouseResLogTypeCell:OnFeedData(data)
    local currencyConfig = ConfigRefer.AllianceCurrency:Find(data.CurrencyId)
    g_Game.SpriteManager:LoadSprite(UIHelper.IconOrMissing(currencyConfig and currencyConfig:Icon()), self._p_icon_res_cost)
    self._p_text_res_cost_num.text = tostring(data.CurrencyCount)
end

return AllianceStoreHouseResLogTypeCell