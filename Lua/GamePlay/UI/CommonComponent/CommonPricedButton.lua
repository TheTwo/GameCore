local BaseUIComponent = require ('BaseUIComponent')
local UIHelper = require('UIHelper')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CommonPricedButton:BaseUIComponent
local CommonPricedButton = class('CommonPricedButton', BaseUIComponent)

---@class CommonPricedButtonData
---@field buttonName string
---@field buttonIcon string|nil
---@field needCount number|nil
---@field ownCount number|nil
---@field enabled boolean
---@field callback function
---@field disableCallback function|nil

function CommonPricedButton:OnCreate()
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._p_text = self:Text("p_text")
    self._p_number_bl = self:GameObject("p_number_bl")

    self._icon_item = self:GameObject("icon_item")
    self._p_icon_item_bl = self:Image("p_icon_item_bl")

    self._p_text_num_green_bl = self:Text("p_text_num_green_bl")
    self._p_text_num_red_bl = self:Text("p_text_num_red_bl")
    self._p_text_num_wilth_bl = self:Text("p_text_num_wilth_bl")
end

---@param data CommonPricedButtonData
function CommonPricedButton:OnFeedData(data)
    self.data = data
    self._p_text.text = I18N.Get(data.buttonName)

    local showIcon = data.buttonIcon ~= nil
    local showNumber = data.needCount ~= nil and data.ownCount ~= nil

    if not showIcon and not showNumber then
        self._p_number_bl:SetActive(false)
        return
    end

    self._p_number_bl:SetActive(true)
    self._icon_item:SetActive(showIcon)
    if showIcon then
        g_Game.SpriteManager:LoadSprite(data.buttonIcon, self._p_icon_item_bl)
    end

    if showNumber then
        self._p_text_num_green_bl:SetVisible(data.ownCount >= data.needCount)
        self._p_text_num_red_bl:SetVisible(data.ownCount < data.needCount)
        self._p_text_num_wilth_bl:SetVisible(true)
        self._p_text_num_green_bl.text = tostring(data.ownCount)
        self._p_text_num_red_bl.text = tostring(data.ownCount)
        self._p_text_num_wilth_bl.text = ("/%d"):format(data.needCount)
    else
        self._p_text_num_green_bl:SetVisible(false)
        self._p_text_num_red_bl:SetVisible(false)
        self._p_text_num_wilth_bl:SetVisible(false)
    end

    UIHelper.SetGray(self._button.gameObject, not data.enabled)
end

function CommonPricedButton:OnClick()
    if self.data.enabled then
        self.data.callback(self._button.transform)
    elseif self.data.disableCallback then
        self.data.disableCallback(self._button.transform)
    end
end

return CommonPricedButton