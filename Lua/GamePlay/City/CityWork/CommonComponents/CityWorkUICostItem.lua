local BaseUIComponent = require ('BaseUIComponent')
local UIHelper = require('UIHelper')
local ColorConsts = require('ColorConsts')
local Delegate = require('Delegate')
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local NumberFormatter = require("NumberFormatter")

---@class CityWorkUICostItem:BaseUIComponent
local CityWorkUICostItem = class('CityWorkUICostItem', BaseUIComponent)

function CityWorkUICostItem:OnCreate()
    self._child_common_quantity_l = self:Button("child_common_quantity_l", Delegate.GetOrCreate(self, self.OnClickShowTips))
    self._p_base = self:Image("p_base")
    self._p_icon_item = self:Image("p_icon_item")
    self._p_base_farme = self:Image("p_base_farme")
    self._p_text_01 = self:Text("p_text_01")
    self._p_btn_add = self:Button("p_btn_add", Delegate.GetOrCreate(self, self.OnClickBtnAdd))
end

---@param data CityWorkUICostItemData
function CityWorkUICostItem:OnFeedData(data)
    self.data = data
    g_Game.SpriteManager:LoadSprite(data:GetIcon(), self._p_icon_item)
    g_Game.SpriteManager:LoadSprite(data:GetQualityBackground(), self._p_base_farme)
    
    local countNeed = data:GetCountNeed()
    local countOwn = data:GetCountOwn()
    local leftText
    if countOwn >= countNeed then
        leftText = UIHelper.GetColoredText(NumberFormatter.NumberAbbr(countOwn, true, false), ColorConsts.quality_green)
    else
        leftText = UIHelper.GetColoredText(NumberFormatter.NumberAbbr(countOwn, true, false), ColorConsts.army_red)
    end

    if self._p_base then
        if countOwn >= countNeed then
            self._p_base.color = UIHelper.TryParseHtmlString(ColorConsts.white_grey)
        else
            self._p_base.color = UIHelper.TryParseHtmlString(ColorConsts.army_red)
        end
    end

    self._p_text_01.text = ("%s/%s"):format(leftText, NumberFormatter.NumberAbbr(countNeed, true, false))
    self._p_btn_add:SetVisible(countOwn < countNeed)
end

function CityWorkUICostItem:OnClickBtnAdd()
    if not self.data then return end
    local countNeed = self.data:GetCountNeed()
    local countOwn = self.data:GetCountOwn()
    if countOwn >= countNeed then
        ModuleRefer.InventoryModule:OpenExchangePanel({{id = self.data.id, num = 1}})
    else
        ModuleRefer.InventoryModule:OpenExchangePanel({{id = self.data.id, num = (countNeed - countOwn)}})
    end
end

function CityWorkUICostItem:OnClickShowTips()
    if not self.data then return end

    ---@type CommonItemDetailsParameter
    local param = {}
    param.clickTransform = self._p_icon_item.transform
    param.itemId = self.data.id
    param.itemType = require("CommonItemDetailsDefine").ITEM_TYPE.ITEM
    g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
end

return CityWorkUICostItem