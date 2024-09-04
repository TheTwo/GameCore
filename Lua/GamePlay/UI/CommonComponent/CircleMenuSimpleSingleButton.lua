local BaseUIComponent = require ('BaseUIComponent')
local UIHelper = require('UIHelper')
local Delegate = require('Delegate')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
---@class CircleMenuSimpleSingleButton:BaseUIComponent
local CircleMenuSimpleSingleButton = class('CircleMenuSimpleSingleButton', BaseUIComponent)

function CircleMenuSimpleSingleButton:OnCreate()
    self._p_group_item = self:GameObject("p_group_item")
    self._p_table_item = self:TableViewPro("p_table_item")
    self._p_mask = self:GameObject("p_mask")
    self._p_icon = self:Image("p_icon")
    self._p_num = self:Text('p_text_num')
    self._p_text = self:Text('p_text')
    self._back = self:Image("")
    self._btn = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self.vfxTrigger = self:AnimTrigger('vx_trigger')
end

---@param data CircleMenuSimpleButtonData
function CircleMenuSimpleSingleButton:OnFeedData(data)
    if self._p_icon then
        if string.IsNullOrEmpty(data.buttonIcon) then
            self._p_icon:SetVisible(false)
        else
            self._p_icon:SetVisible(true)
            g_Game.SpriteManager:LoadSprite(data.buttonIcon, self._p_icon)
            UIHelper.SetGray(self._p_icon.gameObject, not data.buttonEnable)
        end
    end
    if self._back then
        g_Game.SpriteManager:LoadSprite(data.buttonBack, self._back)
    end
    if self._p_num then
        if data.number and data.number > 0 then
            self._p_num:SetVisible(true)
            self._p_num.text = tostring(data.number)
        else
            self._p_num:SetVisible(false)
        end
    end
    self._p_mask:SetVisible(not data.buttonEnable)
    self._p_group_item:SetActive(data.extraData ~= nil)
    if data.extraData then
        self._p_table_item:Clear()
        for _, v in ipairs(data.extraData) do
            self._p_table_item:AppendData(v)
        end
    end
    self._p_text:SetVisible(data.name ~= nil)
    if data.name then
        self._p_text.text = data.name
    end
    self.data = data
    if data.activeNoticeAnim then
        self.vfxTrigger:PlayAll(FpAnimTriggerEvent.Custom1)
    else
        self.vfxTrigger:FinishAll(FpAnimTriggerEvent.Custom1)
    end

    if not string.IsNullOrEmpty(data.nodeName) then
        self.CSComponent.gameObject.name = data.nodeName
    else
        self.CSComponent.gameObject.name = "p_btn_troop"
    end
end

function CircleMenuSimpleSingleButton:OnClick()
    if self.data.buttonEnable and self.data.onClick then
        self.data.onClick()
    elseif not self.data.buttonEnable and self.data.onClickFailed then
        self.data.onClickFailed()
    end
end

return CircleMenuSimpleSingleButton