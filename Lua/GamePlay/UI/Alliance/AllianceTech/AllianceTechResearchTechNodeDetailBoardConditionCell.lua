local Delegate = require("Delegate")
local EventConst = require("EventConst")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local UIHelper = require("UIHelper")
local AllianceTechConditionHelper = require("AllianceTechConditionHelper")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTechResearchTechNodeDetailBoardConditionCell:BaseTableViewProCell
---@field new fun():AllianceTechResearchTechNodeDetailBoardConditionCell
---@field super BaseTableViewProCell
local AllianceTechResearchTechNodeDetailBoardConditionCell = class('AllianceTechResearchTechNodeDetailBoardConditionCell', BaseTableViewProCell)

function AllianceTechResearchTechNodeDetailBoardConditionCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._requireGroupId = nil
    self._isRequireOk = false
end

function AllianceTechResearchTechNodeDetailBoardConditionCell:OnCreate(_)
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnClickSelf))
    self._p_icon_skill = self:Image("p_icon_skill")
    self._p_text_name_skill = self:Text("p_text_name_skill")
    ---@type CommonPairsQuantity
    self._p_text_progress = self:LuaBaseComponent("p_text_progress")
    self._p_img_jump = self:GameObject("p_img_jump")
    self._p_icon_reach = self:GameObject("p_icon_reach")
end

---@param data AllianceTechCondition
function AllianceTechResearchTechNodeDetailBoardConditionCell:OnFeedData(data)
    self._data = data
    self:Refresh()
end

function AllianceTechResearchTechNodeDetailBoardConditionCell:Refresh()
    local isRequireOk,requireName,requireIcon,requireCurrentValueStr,requireCurrentNeedValueStr, requireGroupId = AllianceTechConditionHelper.Parse(self._data)
    self._isRequireOk = isRequireOk
    self._p_text_name_skill.text = requireName
    self._requireGroupId = requireGroupId
    g_Game.SpriteManager:LoadSprite(requireIcon, self._p_icon_skill)
    ---@type CommonPairsQuantityParameter
    local p = {}
    p.num1 = self._isRequireOk and requireCurrentValueStr or UIHelper.GetColoredText(requireCurrentValueStr, CommonItemDetailsDefine.TEXT_COLOR.RED)
    p.num2 = ("/%s"):format(requireCurrentNeedValueStr)
    self._p_text_progress:FeedData(p)
    self._p_img_jump:SetVisible(not self._isRequireOk)
    self._p_icon_reach:SetVisible(self._isRequireOk)
end

function AllianceTechResearchTechNodeDetailBoardConditionCell:OnClickSelf()
    if self._isRequireOk then
        return
    end
    g_Game.EventManager:TriggerEvent(EventConst.UI_ALLIANCE_TECH_FOCUS_ON_GROUP, self._requireGroupId, true)
end

return AllianceTechResearchTechNodeDetailBoardConditionCell