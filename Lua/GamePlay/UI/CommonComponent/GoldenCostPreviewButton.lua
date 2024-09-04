local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class GoldenCostPreviewButton:BaseUIComponent
local GoldenCostPreviewButton = class('GoldenCostPreviewButton', BaseUIComponent)

---@class GoldenCostPreviewButtonData
---@field onClick fun(transform:CS.UnityEngine.RectTransform)
---@field buttonText string
---@field costInfo GoldenCostPreviewButtonCostInfo
---@field rechargeInfo GoldenCostPreviewButtonRechargeInfo

---@class GoldenCostPreviewButtonCostInfo
---@field icon string|nil
---@field need number
---@field own number

---@class GoldenCostPreviewButtonRechargeInfo
---@field num number

function GoldenCostPreviewButton:OnCreate()
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._p_text_e = self:Text("p_text_e")
    
    self._p_resouce_e = self:GameObject("p_resouce_e")
    self._icon_item = self:GameObject("icon_item")
    self._p_icon_e = self:Image("p_icon_e")
    
    self._p_text_num_green_e = self:Text("p_text_num_green_e")
    self._p_text_num_red_e = self:Text("p_text_num_red_e")
    self._p_text_num_e = self:Text("p_text_num_e")

    self._p_btn_recharge_points = self:GameObject("p_btn_recharge_points")
    self._p_text_num = self:Text("p_text_num")
end

---@param data GoldenCostPreviewButtonData
function GoldenCostPreviewButton:OnFeedData(data)
    self.data = data

    self._p_text_e.text = data.buttonText
    self._p_resouce_e:SetActive(data.costInfo ~= nil)
    self._p_btn_recharge_points:SetActive(data.rechargeInfo ~= nil)

    if data.costInfo then
        self._p_icon_e:SetVisible(self.data.costInfo.icon ~= nil)
        if self.data.costInfo.icon ~= nil then
            g_Game.SpriteManager:LoadSprite(self.data.costInfo.icon, self._p_icon_e)
        end

        local enough = data.costInfo.own >= data.costInfo.need
        self._p_text_num_green_e:SetVisible(enough)
        self._p_text_num_red_e:SetVisible(not enough)
        local text = enough and self._p_text_num_green_e or self._p_text_num_red_e
        text.text = tostring(data.costInfo.own)
        self._p_text_num_e.text = ("/%d"):format(data.costInfo.need)
    end

    if data.rechargeInfo then
        self._p_text_num.text = tostring(data.rechargeInfo.num)
    end
end

function GoldenCostPreviewButton:OnClick()
    if self.data.onClick then
        self.data.onClick(self._button.transform)
    end
end

return GoldenCostPreviewButton