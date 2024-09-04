local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIHelper = require("UIHelper")
local ColorConsts = require("ColorConsts")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummaryBuffDetailCellData
---@field pIcon string
---@field pName string
---@field pValue string
---@field aIcon string
---@field aName string
---@field aValue string

---@class AllianceTerritoryMainSummaryBuffDetailCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryBuffDetailCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryBuffDetailCell = class('AllianceTerritoryMainSummaryBuffDetailCell', BaseTableViewProCell)

function AllianceTerritoryMainSummaryBuffDetailCell:OnCreate(param)
    self._p_resources_league = self:GameObject("p_resources_league")
    self._p_icon_resources_league = self:Image("p_icon_resources_league")
    self._p_text_resources_league = self:Text("p_text_resources_league")
    self._p_text_time_league = self:Text("p_text_time_league")
end

---@param data AllianceTerritoryMainSummaryBuffDetailCellData
function AllianceTerritoryMainSummaryBuffDetailCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.aIcon, self._p_icon_resources_league)
    self._p_text_resources_league.text = data.aName
    self._p_text_time_league.text = data.aValue
    self._p_text_time_league.color = UIHelper.TryParseHtmlString(ColorConsts.quality_green)
end

return AllianceTerritoryMainSummaryBuffDetailCell
