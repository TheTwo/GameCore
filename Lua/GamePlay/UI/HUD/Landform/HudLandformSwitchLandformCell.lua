local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local I18N = require('I18N')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')
local EventConst = require('EventConst')

---@class HudLandformSwitchStrategyCellData
---@field landCfgCell LandConfigCell
---@field curSelectLandId number @当前选中的LandConfigCell Id

---@class HudLandformSwitchStrategyCell:BaseTableViewProCell
---@field new fun():HudLandformSwitchStrategyCell
---@field super BaseTableViewProCell
local HudLandformSwitchLandformCell = class('HudLandformSwitchLandformCell', BaseTableViewProCell)

function HudLandformSwitchLandformCell:OnCreate()
    ---@type CS.StatusRecordParent
	self.toggle = self:BindComponent("child_toggle_dot", typeof(CS.StatusRecordParent))
    self.btnToggle = self:Button("p_btn", Delegate.GetOrCreate(self, self.OnClick))
    self.txtLandName = self:Text("p_text_layer")
end

---@param data HudLandformSwitchStrategyCellData
function HudLandformSwitchLandformCell:OnFeedData(data)
    self.data = data

    self:RefreshUI()
end

function HudLandformSwitchLandformCell:RefreshUI()
    local isPlayerUnlock = ModuleRefer.LandformModule:IsPlayerUnlock(self.data.landCfgCell:Id())
    self.txtLandName.text = I18N.Get(self.data.landCfgCell:Name())
    if isPlayerUnlock then
        self.txtLandName.color = UIHelper.TryParseHtmlString(ColorConsts.army_green)
    else
        local color = UIHelper.TryParseHtmlString(ColorConsts.white)
        color.a = 0.6
        self.txtLandName.color = color
    end

    if self.data.curSelectLandId == self.data.landCfgCell:Id() then
        self.toggle:ApplyStatusRecord(1)
        self.txtLandName.fontStyle = CS.UnityEngine.FontStyle.Bold
    else
        self.toggle:ApplyStatusRecord(0)
        self.txtLandName.fontStyle = CS.UnityEngine.FontStyle.Normal
    end
end

function HudLandformSwitchLandformCell:OnClick()
    g_Game.EventManager:TriggerEvent(EventConst.ON_LANDFORM_SELECT, self.data.landCfgCell:Id())
end

return HudLandformSwitchLandformCell