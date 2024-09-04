local BaseUIComponent = require("BaseUIComponent")
local Delegate = require('Delegate')
local BistateButtonDefine = require("BistateButtonDefine")
---@class BistateButtonSmall : BaseUIComponent
local BistateButtonSmall = class('BistateButtonSmall', BaseUIComponent)

---@class BistateButtonSmallParam
---@field buttonText string
---@field disableButtonText string
---@field buttonType number @BistateButtonDefine.BUTTON_TYPE
---@field onClick fun()
---@field disableClick fun()

function BistateButtonSmall:OnCreate()
    self.statusCtrl = self.CSComponent.gameObject:GetComponent(typeof(CS.StatusRecordParent))
    self.button = self:Button("child_comp_btn_b_s", Delegate.GetOrCreate(self, self.OnClick))
    self.disableButton = self:Button("child_comp_btn_d_s", Delegate.GetOrCreate(self, self.DisableClick))
    self.buttonText = self:Text('p_text')
    self.disableButtonText = self:Text('p_text_d_s')
    self.imgBase = self:Image('p_base')
end

---@param param BistateButtonSmallParam
function BistateButtonSmall:OnFeedData(param)
    self.buttonText.text = param.buttonText
    if param.disableButtonText then
        self.disableButtonText.text = param.disableButtonText
    else
        self.disableButtonText.text = param.buttonText
    end
    self.onClick = param.onClick
    self.disableClick = param.disableClick
    self.buttonType = param.buttonType or BistateButtonDefine.BUTTON_TYPE.PINK
end

function BistateButtonSmall:SetType()
    local btnInfo = BistateButtonDefine.BTN_INFO[self.buttonType]
    g_Game.SpriteManager:LoadSprite(btnInfo.baseIcon, self.imgBase)
    self.buttonText.color = btnInfo.textColor
end

function BistateButtonSmall:OnClick()
    if self.onClick then
        self.onClick()
    end
end

function BistateButtonSmall:DisableClick()
    if self.disableClick then
        self.disableClick()
    end
end

---@param enabled boolean
function BistateButtonSmall:SetEnabled(enabled)
	if (self._enabled == enabled) then return end
	self._enabled = enabled
    if (enabled) then
        self.statusCtrl:SetState(0)
    else
        self.statusCtrl:SetState(1)
    end
end

---@param text string
function BistateButtonSmall:SetButtonText(text)
    if (self.buttonText) then
        self.buttonText.text = text
    end
    if (self.disableButtonText) then
        self.disableButtonText.text = text
    end
end

return BistateButtonSmall