local BaseUIComponent = require('BaseUIComponent')
local UIHelper = require('UIHelper')
local ConfigRefer = require('ConfigRefer')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local Delegate = require('Delegate')
local Utils = require("Utils")

---@class CommonPairsQuantityParameter
---@field itemId number
---@field itemIcon string
---@field num1 number|string
---@field num2 number|string
---@field onClick fun()
---@field onClickUp fun()
---@field compareType CommonItemDetailsDefine.COMPARE_TYPE
---@field useColor1 boolean

---@class CommonPairsQuantity:BaseUIComponent
---@field super BaseUIComponent
---@field FeedData fun(self:CommonPairsQuantity, param:CommonPairsQuantityParameter)
local CommonPairsQuantity = class('CommonPairsQuantity', BaseUIComponent)

function CommonPairsQuantity:OnCreate()
    self:PointerDown('', Delegate.GetOrCreate(self, self.OnBtnPointerDown))
    self:PointerUp('', Delegate.GetOrCreate(self, self.OnBtnPointerUp))
    self.imgIconItem = self:Image('p_icon_item')
    self.text01 = self:Text('p_text_01')
    self.text02 = self:Text('p_text_02')
end

function CommonPairsQuantity:OnClose()

end

---@param param CommonPairsQuantityParameter
function CommonPairsQuantity:OnFeedData(param)
    if not param then
        return
    end
    self.param = param
    if Utils.IsNotNull(self.imgIconItem) then
        if param.itemId then
            local itemCfg = ConfigRefer.Item:Find(param.itemId)
            g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgIconItem)
            self.imgIconItem.gameObject:SetActive(true)
        elseif not string.IsNullOrEmpty(param.itemIcon) then
            g_Game.SpriteManager:LoadSprite(param.itemIcon, self.imgIconItem)
            self.imgIconItem.gameObject:SetActive(true)
        else
            self.imgIconItem.gameObject:SetActive(false)
        end
    end
    if type(param.num2) == 'string' then
        self.text02.text = param.num2
    else
        self.text02.text = "/" .. param.num2
    end
    self.compareType = param.compareType
    self:ChangeNum(param.num1, param.num2)
    self.onClick = param.onClick
    self.onClickUp = param.onClickUp
end

function CommonPairsQuantity:ChangeIcon(icon)
    self.imgIconItem.gameObject:SetActive(true)
    g_Game.SpriteManager:LoadSprite(icon, self.imgIconItem)
end

function CommonPairsQuantity:ChangeNum(num1, num2)
    if type(num1) == 'string' or type(num2) == 'string' then
        self.text01.text = tostring(num1)
        return
    end
    self.text01:SetVisible(true)
    self.text02:SetVisible(true)

    if self.compareType == CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST then
        if num1 >= num2 then
            self.text01.text = UIHelper.GetColoredText(num1, CommonItemDetailsDefine.TEXT_COLOR.GREEN_2)
        else
            self.text01.text = UIHelper.GetColoredText(num1, CommonItemDetailsDefine.TEXT_COLOR.RED)
        end
    elseif self.compareType == CommonItemDetailsDefine.COMPARE_TYPE.OVERFLOW then
        if num1 > num2 then
            self.text01.text = UIHelper.GetColoredText(num1, CommonItemDetailsDefine.TEXT_COLOR.RED)
        else
            self.text01.text = UIHelper.GetColoredText(num1, CommonItemDetailsDefine.TEXT_COLOR.WHITE)
        end
    elseif self.compareType == CommonItemDetailsDefine.COMPARE_TYPE.LEFT_COST_RIGHT_OWN then
        if num1 <= num2 then
            self.text01.text = UIHelper.GetColoredText(num1, CommonItemDetailsDefine.TEXT_COLOR.GREEN_2)
        else
            self.text01.text = UIHelper.GetColoredText(num1, CommonItemDetailsDefine.TEXT_COLOR.RED)
        end
    end
    self.text02.text = "/" ..num2
end

function CommonPairsQuantity:SetCustomString(str)
    self.text01.text = UIHelper.GetColoredText(str, CommonItemDetailsDefine.TEXT_COLOR.RED)
    self.text02:SetVisible(false)
end

---@param color string
function CommonPairsQuantity:SetCustomLeftNumberColor(color)
    self.text01.text = UIHelper.GetColoredText(self.param.num1, color)
end

---@param color string
function CommonPairsQuantity:SetCustomRightNumberColor(color)
    self.text02.text = UIHelper.GetColoredText(self.param.num2, color)
end

function CommonPairsQuantity:OnBtnPointerDown()
    if self.onClick then
        self.onClick()
    end
end

function CommonPairsQuantity:OnBtnPointerUp()
    if self.onClickUp then
        self.onClickUp()
    end
end

return CommonPairsQuantity
