local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local UIHelper = require('UIHelper')
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')

local CommonSingleQuantity = class('CommonSingleQuantity', BaseUIComponent)

function CommonSingleQuantity:OnCreate()
    self:PointerDown('', Delegate.GetOrCreate(self, self.OnBtnPointerDown))
    self:PointerUp('', Delegate.GetOrCreate(self, self.OnBtnPointerUp))
    self.imgBaseFarme = self:Image('p_base_farme')
    self.imgIconItem = self:Image('p_icon_item')
    self.text01 = self:Text('p_text_01')
    self.btnAdd = self:Button('p_btn_add', Delegate.GetOrCreate(self, self.OnBtnAddClicked))
end

function CommonSingleQuantity:OnBtnAddClicked(args)
    if self.lackList then
        ModuleRefer.InventoryModule:OpenExchangePanel(self.lackList)
    end
end

function CommonSingleQuantity:OnClose()

end

---@param param CommonPairsQuantityParameter
function CommonSingleQuantity:OnFeedData(param)
    if not param then
        return
    end
    if param.itemId then
        local itemCfg = ConfigRefer.Item:Find(param.itemId)
        g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgIconItem)
        self.imgIconItem.gameObject:SetActive(true)
        local quality = itemCfg:Quality()
        g_Game.SpriteManager:LoadSprite('sp_item_frame_circle_'..tostring(quality), self.imgBaseFarme)
        self.btnAdd.gameObject:SetActive(param.num2 and param.num1 < param.num2)
        local isEnough = param.num2 and param.num1 >= param.num2
        if param.num2 and not isEnough then
            self.lackList = {{id = param.itemId, num = param.num2 - param.num1}}
        end
    elseif not string.IsNullOrEmpty(param.itemIcon) then
        self.imgIconItem.gameObject:SetActive(true)
        g_Game.SpriteManager:LoadSprite(param.itemIcon, self.imgIconItem)
        local quality = param.customQuality or 0
        g_Game.SpriteManager:LoadSprite('sp_item_frame_circle_'..tostring(quality), self.imgBaseFarme)
        self.btnAdd.gameObject:SetActive(false)
    else
        self.imgIconItem.gameObject:SetActive(false)
        self.btnAdd.gameObject:SetActive(false)
    end
    self.compareType = param.compareType
    self:ChangeNum(param.num1, param.num2, param.useColor1, param.useColor2)
    self.onClick = param.onClick
    self.onClickUp = param.onClickUp
end

function CommonSingleQuantity:ChangeNum(num1, num2, useColor1, useColor2)
    if type(num1) == 'string' or type(num2) == 'string' then
        self.text01.text = tostring(num1)
        return
    end
    if not num2 then
        self.text01.text = num1
        return
    end
    local useColorDef = CommonItemDetailsDefine.TEXT_COLOR
    if useColor1 then
        useColorDef = CommonItemDetailsDefine.TEXT_COLOR_1
    elseif useColor2 then
        useColorDef = CommonItemDetailsDefine.TEXT_COLOR_2
    end
    if self.compareType == CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST then
        if num1 >= num2 then
            self.text01.text = UIHelper.GetColoredText(num1, useColorDef.GREEN) .. UIHelper.GetColoredText("/" .. num2, useColorDef.WHITE)
        else
            self.text01.text = UIHelper.GetColoredText(num1, useColorDef.RED) .. UIHelper.GetColoredText("/" .. num2, useColorDef.WHITE)
        end
    elseif self.compareType == CommonItemDetailsDefine.COMPARE_TYPE.OVERFLOW then
        if num1 > num2 then
            self.text01.text = UIHelper.GetColoredText(num1, useColorDef.RED) .. UIHelper.GetColoredText("/" .. num2, useColorDef.WHITE)
        else
            self.text01.text = UIHelper.GetColoredText(num1 .. "/" .. num2, useColorDef.WHITE)
        end
    elseif self.compareType == CommonItemDetailsDefine.COMPARE_TYPE.LEFT_COST_RIGHT_OWN then
        if num1 <= num2 then
            self.text01.text = UIHelper.GetColoredText(num1, useColorDef.GREEN)
        else
            self.text01.text = UIHelper.GetColoredText(num1, useColorDef.RED)
        end
    end
end

function CommonSingleQuantity:ChangeIcon(icon)
    self.imgIconItem.gameObject:SetActive(true)
    g_Game.SpriteManager:LoadSprite(icon, self.imgIconItem)
end

function CommonSingleQuantity:ChangeText(text)
    self.text01.text = text
end

function CommonSingleQuantity:OnBtnPointerDown()
    if self.onClick then
        self.onClick()
    end
end

function CommonSingleQuantity:OnBtnPointerUp()
    if self.onClickUp then
        self.onClickUp()
    end
end

return CommonSingleQuantity
