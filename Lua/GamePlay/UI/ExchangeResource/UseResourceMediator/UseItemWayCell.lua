local BaseTableViewProCell = require('BaseTableViewProCell')
local Delegate = require('Delegate')
local I18N = require('I18N')
local UseItemWayCell = class('UseItemWayCell',BaseTableViewProCell)

function UseItemWayCell:OnCreate(param)
    self.textDetail = self:Text('p_text_detail')
    self.textText = self:Text('p_text', I18N.Get("getmore_go"))
    self.btnGoto = self:Button('child_comp_btn_a_m_u2', Delegate.GetOrCreate(self, self.OnBtnGotoClicked))
end

---@param data GetMoreAcquisitionWayCellDataProvider
function UseItemWayCell:OnFeedData(data)
    self.provider = data
    self.textDetail.text = data:GetDesc()
    self.btnGoto.gameObject:SetActive(data:ShowGotoBtn())
end

function UseItemWayCell:OnBtnGotoClicked(args)
    self.provider:OnGoto(self:GetParentBaseUIMediator())
end

return UseItemWayCell
