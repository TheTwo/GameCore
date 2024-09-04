local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local TimeFormatter = require("TimeFormatter")
local ConfigRefer = require("ConfigRefer")
local AllianceCurrencyLogType = require("AllianceCurrencyLogType")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceStoreHouseResLogCellParameter
---@field serverData wds.AllianceCurrencyLog

---@class AllianceStoreHouseResLogCell:BaseTableViewProCell
---@field new fun():AllianceStoreHouseResLogCell
---@field super BaseTableViewProCell
local AllianceStoreHouseResLogCell = class('AllianceStoreHouseResLogCell', BaseTableViewProCell)

function AllianceStoreHouseResLogCell:OnCreate(param)
    ---@type PlayerInfoComponent
    self._child_ui_head_player = self:LuaObject("child_ui_head_player")
    self._p_text_detail_desc = self:Text("p_text_detail_desc")
    self._p_text_time = self:Text("p_text_time")
    self._p_table_res_cost = self:TableViewPro("p_table_res_cost")
end

---@param data AllianceStoreHouseResLogCellParameter
function AllianceStoreHouseResLogCell:OnFeedData(data)
    self._p_text_time.text = TimeFormatter.AllianceCurrencyLogTime(data.serverData.Time.Seconds, g_Game.ServerTime:GetServerTimestampInSeconds())
    local logContent = ModuleRefer.AllianceModule.ParseAllianceCurrencyLog(data.serverData)
    self._p_text_detail_desc.text = logContent
    self._child_ui_head_player:FeedData(data.serverData.PortraitInfo)
    if self._p_table_res_cost.DataCount <= 0 then
        self._p_table_res_cost:AppendData(data.serverData)
    else
        self._p_table_res_cost:ReplaceData(0, data.serverData)
    end
end

function AllianceStoreHouseResLogCell:OnRecycle()
    self._p_table_res_cost:Clear()
end

return AllianceStoreHouseResLogCell