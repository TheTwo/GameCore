local BaseUIComponent = require("BaseUIComponent")
local ColorConsts = require("ColorConsts")
local UIHelper = require("UIHelper")
local Delegate = require('Delegate')
local BistateButtonDefine = require("BistateButtonDefine")

---@class BistateButtonParameter
---@field onClick fun(clickData:any)
---@field clickData any
---@field buttonText string
---@field disableClick fun()
---@field disableButtonText string
---@field icon string @name of icon Sprite
---@field num1 number @item need
---@field num2 number @item had
---@field singleNumber boolean @only show num1
---@field buttonState number @BistateButton.BUTTON_TYPE
---@field onPressDown fun()
---@field onPressUp fun()

---@class BistateButton : BaseUIComponent
local BistateButton = class("BistateButton", BaseUIComponent)

BistateButton.BUTTON_TYPE = BistateButtonDefine.BUTTON_TYPE

local BTN_INFO  = BistateButtonDefine.BTN_INFO

function BistateButton:ctor()
	self._enabled = nil
end

function BistateButton:OnCreate()
    self.statusCtrl = self.CSComponent.gameObject:GetComponent(typeof(CS.StatusRecordParent))
    self.imgBase = self:Image('p_base')
    self.goNumberBl = self:GameObject('p_number_bl')
    self.imgIconItemBl = self:Image('p_icon_item_bl')
    self.textNumGreenBl = self:Text('p_text_num_green_bl')
    self.textNumRedBl = self:Text('p_text_num_red_bl')
    self.textNumWilthBl = self:Text('p_text_num_wilth_bl')
    self.goNumberDm = self:GameObject('p_number_dm')
    self.imgIconItemDm = self:Image('p_icon_item_dm')
    self.textNumGreenDm = self:Text('p_text_num_green_dm')
    self.textNumRedDm = self:Text('p_text_num_red_dm')
    self.textNumWilthDm = self:Text('p_text_num_wilth_dm')
    self.button = self:Button("child_comp_btn_b_s", Delegate.GetOrCreate(self, self.OnClick))
    self.disableButton = self:Button("child_comp_btn_d_s", Delegate.GetOrCreate(self, self.DisableClick))
    self.buttonText = self:Text("p_text_b")
    self.disabledButtonText = self:Text("p_text_d")
    self:PointerUp("child_comp_btn_b_s", Delegate.GetOrCreate(self, self.OnPointerUp))
end

---@param param BistateButtonParameter
function BistateButton:OnFeedData(param)
    if (param) then
        self.onClick = param.onClick
		self.overrideClick = param.overrideClick
        self.clickData = param.clickData
        self.disableClick = param.disableClick
        if self.buttonText then
            self.buttonText.text = param.buttonText
        end

        if self.disabledButtonText then
            if param.disableButtonText then
                self.disabledButtonText.text = param.disableButtonText
            else
                self.disabledButtonText.text = param.buttonText
            end
        end
        
        self.onPressDown = param.onPressDown
        self.onPressUp = param.onPressUp
        if self.onPressDown then
            local listener = CS.UIPointerDownListener.Get(self.button.gameObject)
            local originalFunc = listener.onDown
            listener.onDown = Delegate.GetOrCreate(self, function()
                originalFunc()
                self.onPressDown()
            end)
        end
        self:SelectBtnState(param)
        self:RefreshIconState(param)
    end
end

---@param param BistateButtonParameter
function BistateButton:SelectBtnState(param)
    local curState = param.buttonState
    if not curState then
        curState = BistateButton.BUTTON_TYPE.PINK
    end
    local buttonInfo = BTN_INFO[curState]
    g_Game.SpriteManager:LoadSprite(buttonInfo.baseIcon, self.imgBase)
    if self.buttonText then
        self.buttonText.color = UIHelper.TryParseHtmlString(buttonInfo.textColor)
    end

    if self.textNumRedBl then
        self.textNumRedBl.color = UIHelper.TryParseHtmlString(buttonInfo.lackTextColor)
    end
end

---@param param BistateButtonParameter
function BistateButton:RefreshIconState(param)
    if not self.goNumberBl then
        return
    end
    local showIcon = param.icon ~= nil
    self.goNumberBl:SetActive(showIcon)
    self.goNumberDm:SetActive(showIcon)
    if showIcon then
        g_Game.SpriteManager:LoadSprite(param.icon, self.imgIconItemBl)
        g_Game.SpriteManager:LoadSprite(param.icon, self.imgIconItemDm)
        if param.singleNumber then
            self:ShowSingleNumber(param)
        else
            self:ShowCompareNumbers(param)
        end
    end
end

---@param param BistateButtonParameter
function BistateButton:ShowSingleNumber(param)
    self.textNumGreenBl.gameObject:SetActive(false)
    self.textNumGreenDm.gameObject:SetActive(false)
    self.textNumRedBl.gameObject:SetActive(false)
    self.textNumRedDm.gameObject:SetActive(false)
    self.textNumWilthBl.text = param.num1
    self.textNumWilthDm.text = param.num1
end

---@param param BistateButtonParameter
function BistateButton:ShowCompareNumbers(param)
    if not param.num1 or not param.num2 then
        return
    end
    local isGreen = param.num1 <= param.num2
    self.textNumGreenBl.gameObject:SetActive(isGreen)
    self.textNumGreenDm.gameObject:SetActive(isGreen)

    if self.textNumRedBl then
        self.textNumRedBl.gameObject:SetActive(not isGreen)
    end

    if self.textNumRedDm then
        self.textNumRedDm.gameObject:SetActive(not isGreen)
    end

    if isGreen then
        self.textNumGreenBl.text = param.num2
        self.textNumGreenDm.text = param.num2
    else
        if self.textNumRedBl then
            self.textNumRedBl.text = param.num2
        end

        if self.textNumRedDm then
            self.textNumRedDm.text = param.num2
        end
    end

    self.textNumWilthBl.text = "/" .. param.num1
    self.textNumWilthDm.text = "/" .. param.num1
end

function BistateButton:OnClick()
	if (self.overrideClick) then
		self.overrideClick(self.clickData, self.button.transform)
    elseif (self.onClick) then
        self.onClick(self.clickData, self.button.transform)
    end
end

function BistateButton:DisableClick()
    if (self.disableClick) then
        self.disableClick(self.disableButton.transform)
    end
end

function BistateButton:SetEnabled(enabled)
	if (self._enabled == enabled) then return end
	self._enabled = enabled
    if (enabled) then
        self.statusCtrl:SetState(0)
    else
        self.statusCtrl:SetState(1)
    end
end

function BistateButton:SetButtonText(text)
    if (self.buttonText) then
        self.buttonText.text = text
    end
    if (self.disabledButtonText) then
        self.disabledButtonText.text = text
    end
end

function BistateButton:OnPointerDown()
    if self.onPressDown then
        self.onPressDown()
    end
end

function BistateButton:OnPointerUp()
    if self.onPressUp then
        self.onPressUp()
    end
end

return BistateButton
