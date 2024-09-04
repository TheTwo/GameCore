local BistateButton = require("BistateButton")
local GveBistateButton = class("GveBistateButton", BistateButton)
local Delegate = require("Delegate")

function GveBistateButton:OnCreate()
    self.statusCtrl = self.CSComponent.gameObject:GetComponent(typeof(CS.StatusRecordParent))
    self.button = self:Button("child_comp_btn_b_s", Delegate.GetOrCreate(self, self.OnClick))
    self.disableButton = self:Button("child_comp_btn_d_s", Delegate.GetOrCreate(self, self.DisableClick))
    self.buttonText = self:Text("p_text_b")
    self.disabledButtonText = self:Text("p_text_d")
end

---@param param BistateButtonParameter
function GveBistateButton:RefreshIconState(param)
    return
end

return GveBistateButton