local ConfigRefer = require("ConfigRefer")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceCurrencyComponent:BaseUIComponent
---@field new fun():AllianceCurrencyComponent
---@field super BaseUIComponent
local AllianceCurrencyComponent = class('AllianceCurrencyComponent', BaseUIComponent)

function AllianceCurrencyComponent:OnCreate(param)
    self.tableviewproTableResources = self:TableViewPro('p_table_resources')
end

function AllianceCurrencyComponent:OnShow(param)
    self.tableviewproTableResources:Clear()
    for _, v in ConfigRefer.AllianceCurrency:ipairs() do
        self.tableviewproTableResources:AppendData({id = v:Id()}, 0)
    end
end

return AllianceCurrencyComponent