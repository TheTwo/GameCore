local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local GuideConst = require('GuideConst')

---@class HudLandformSwitchStrategyCellData
---@field type number @-1联盟 -2通讯
---@field isSelect boolean @是否选中
---@field desc string @描述

---@class HudLandformSwitchStrategyCell:BaseTableViewProCell
---@field new fun():HudLandformSwitchStrategyCell
---@field super BaseTableViewProCell
local HudLandformSwitchStrategyCell = class('HudLandformSwitchStrategyCell', BaseTableViewProCell)

function HudLandformSwitchStrategyCell:OnCreate()
    ---@type CS.StatusRecordParent
	self.toggle = self:BindComponent("child_toggle_dot", typeof(CS.StatusRecordParent))
    self.btnToggle = self:Button("p_btn", Delegate.GetOrCreate(self, self.OnClick))
    self.txtLandName = self:Text("p_text_strategy")

    self.btnTips = self:Button("p_btn_detail_communicate", Delegate.GetOrCreate(self, self.OnTipsClick))
end

---@param data HudLandformSwitchStrategyCellData
function HudLandformSwitchStrategyCell:OnFeedData(data)
    self.data = data

    self:RefreshUI()
end

function HudLandformSwitchStrategyCell:RefreshUI()
    self.txtLandName.text = self.data.desc

    if self.data.isSelect then
        self.toggle:ApplyStatusRecord(1)
        self.txtLandName.fontStyle = CS.UnityEngine.FontStyle.Bold
    else
        self.toggle:ApplyStatusRecord(0)
        self.txtLandName.fontStyle = CS.UnityEngine.FontStyle.Normal
    end

    -- 通讯范围，显示tips按钮
    self.btnTips:SetVisible(self.data.type == -2)
end

function HudLandformSwitchStrategyCell:OnClick()
    if self.data.onClick then
        self.data.onClick(self.data.type)
    end
end

function HudLandformSwitchStrategyCell:OnTipsClick()
    ModuleRefer.GuideModule:CallGuide(GuideConst.CallID.HudLandformCommunication)
end

return HudLandformSwitchStrategyCell