local Delegate = require("Delegate")
local UIMediatorNames = require('UIMediatorNames')
local BaseTableViewProCell = require("BaseTableViewProCell")

---@class AllianceTerritoryMainSummaryTitleCell:BaseTableViewProCell
---@field new fun():AllianceTerritoryMainSummaryTitleCell
---@field super BaseTableViewProCell
local AllianceTerritoryMainSummaryTitleCell = class('AllianceTerritoryMainSummaryTitleCell', BaseTableViewProCell)

function AllianceTerritoryMainSummaryTitleCell:OnCreate(param)
    self._p_text_summary = self:Text("p_text_summary")
    self._p_btn_summary = self:Button("p_btn_summary", Delegate.GetOrCreate(self, self.OnClickBtnFold))
    self._p_icon_arrow_a = self:GameObject("p_icon_arrow_a")
    self._p_icon_arrow_b = self:GameObject("p_icon_arrow_b")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetailTip))
    self.p_btn_storehouse = self:Button("p_btn_storehouse", Delegate.GetOrCreate(self, self.OnClickStorage))
    self.p_text_storehouse = self:Text("p_text_storehouse","Alliance_resource_cangku")
end

---@param data AllianceTerritoryMainSummaryTitleCellData
function AllianceTerritoryMainSummaryTitleCell:OnFeedData(data)
    self._data = data
    self._p_text_summary.text = data.titleContent
    self._p_btn_detail:SetVisible(data.detailBtn ~= nil)
    self.p_btn_storehouse:SetVisible(data.checkStorage ~= nil)

    if not self._data:ShowExpandBtn() then return end
    self._p_icon_arrow_a:SetVisible(not self._data:IsExpanded() and self._data:ShowExpandBtn())
    self._p_icon_arrow_b:SetVisible(self._data:IsExpanded() and self._data:ShowExpandBtn())
end

function AllianceTerritoryMainSummaryTitleCell:OnClickBtnFold()
    if not self._data:ShowExpandBtn() then return end
    self._data:SetExpanded(not self._data:IsExpanded())
    self:GetTableViewPro():UpdateData(self._data)
    self._p_icon_arrow_a:SetVisible(not self._data:IsExpanded())
    self._p_icon_arrow_b:SetVisible(self._data:IsExpanded())
end

function AllianceTerritoryMainSummaryTitleCell:OnClickDetailTip()
    if not self._data or not self._data.detailBtn then return end
    self._data.detailBtn(self._p_btn_detail.transform)
end

function AllianceTerritoryMainSummaryTitleCell:OnClickStorage()
    ---@type AllianceStoreHouseMediatorParameter
    local param = {}
    param.backNoAni = true
    g_Game.UIManager:Open(UIMediatorNames.AllianceStoreHouseMediator, param)
end

return AllianceTerritoryMainSummaryTitleCell