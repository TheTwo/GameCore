local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local GuideUtils = require("GuideUtils")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class SEExploreSettlementStrengthenCellData
---@field index number
---@field minSubType number @PowerSubType
---@field config PowerProgressResourceConfigCell

---@class SEExploreSettlementStrengthenCell:BaseTableViewProCell
---@field new fun():SEExploreSettlementStrengthenCell
---@field super BaseTableViewProCell
local SEExploreSettlementStrengthenCell = class('SEExploreSettlementStrengthenCell', BaseTableViewProCell)

function SEExploreSettlementStrengthenCell:ctor()
    SEExploreSettlementStrengthenCell.super.ctor(self)
    ---@type PowerProgressResourceConfigCell
    self.config = nil
end

function SEExploreSettlementStrengthenCell:OnCreate(param)
    self._p_text_detail = self:Text("p_text_detail")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGoto))
    self._p_icon_finish = self:GameObject("p_icon_finish")
    self._p_icon_lock = self:GameObject("p_icon_lock")
end

---@param data SEExploreSettlementStrengthenCellData
function SEExploreSettlementStrengthenCell:OnFeedData(data)
    local playerData = ModuleRefer.PlayerModule:GetPlayer()
    local subTypePowers = playerData.PlayerWrapper2.PlayerPower.SubTypePowers
    local strongHoldLv = ModuleRefer.PlayerModule:StrongholdLevel()
    local recommendCfg = ConfigRefer.RecommendPowerTable:Find(strongHoldLv)
    local subTypePower = recommendCfg:SubTypePowers(data.index)
    local subType = subTypePower:SubType()
    local subPower = subTypePower:PowerValue()
    local curPower = subTypePowers[subType] or 0
    if subPower <= 0 then
        subPower = 1
    end
    local percent = curPower / subPower
    self.config = data.config
    self._p_text_detail.text = I18N.Get(self.config:Name())
    if percent >= 1.2 then
        self._p_icon_finish:SetVisible(true)
        self._p_btn_goto:SetVisible(false)
        self._p_icon_lock:SetVisible(false)
    else
        self._p_icon_finish:SetVisible(false)
        self._p_btn_goto:SetVisible(true)
        self._p_icon_lock:SetVisible(false)
    end
end

function SEExploreSettlementStrengthenCell:OnClickGoto()
    if self.config then
        if GuideUtils.GotoByGuide(self.config:UIGoto()) then
            self:GetParentBaseUIMediator():CloseSelf()
        end
    end
end

return SEExploreSettlementStrengthenCell