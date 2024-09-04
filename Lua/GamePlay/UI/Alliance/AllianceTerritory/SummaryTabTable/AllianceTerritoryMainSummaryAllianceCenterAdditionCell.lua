local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummaryAllianceCenterAdditionCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryAllianceCenterAdditionCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryAllianceCenterAdditionCell = class('AllianceTerritoryMainSummaryAllianceCenterAdditionCell', BaseTableViewProCell)

function AllianceTerritoryMainSummaryAllianceCenterAdditionCell:OnCreate(param)
    self.imgIconAddtion = self:Image('p_icon_addtion')
    self.textAddtion = self:Text('p_text_addtion')
    self.textAddtionNumber = self:Text('p_text_addtion_number')
end

---@param data {strLeft:string,strRight:string,icon:string}
function AllianceTerritoryMainSummaryAllianceCenterAdditionCell:OnFeedData(data)
    g_Game.SpriteManager:LoadSprite(data.icon, self.imgIconAddtion)
    self.textAddtion.text = I18N.Get(data.strLeft)
    self.textAddtionNumber.text = data.strRight
end

return AllianceTerritoryMainSummaryAllianceCenterAdditionCell
