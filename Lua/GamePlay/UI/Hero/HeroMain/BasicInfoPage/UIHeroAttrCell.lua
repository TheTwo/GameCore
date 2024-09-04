local BaseTableViewProCell = require('BaseTableViewProCell')
local TimerUtility = require('TimerUtility')
local Utils = require('Utils')

---@class UIHeroAttrCell : BaseTableViewProCell
local UIHeroAttrCell = class('UIHeroAttrCell',BaseTableViewProCell)

function UIHeroAttrCell:OnCreate(param)
    self.imgIcon = self:Image('p_icon')
    self.textLv = self:Text('p_text_lv')
    self.textAdd = self:Text('p_text_add')
    self.textNum = self:Text('p_text_num')
    self.goAddition = self:GameObject("p_base_addition")
    self.goBaseAddition = self:GameObject("p_base_basics_unlock")
    self.goArrow = self:GameObject('p_icon_arrow')
    self.numEffect = self:GameObject('vfx_hero_strengthen_lightsweep')
    self.animtriggerTrigger = self:AnimTrigger('trigger_addition')
    if Utils.IsNotNull(self.numEffect) then
        self.numEffect:SetActive(false)
    end
    if Utils.IsNotNull(self.goAddition) then
        self.goAddition:SetActive(false)
    end
    if Utils.IsNotNull(self.goBaseAddition) then
        self.goBaseAddition:SetActive(false)
    end
end

function UIHeroAttrCell:OnRecycle(param)
    if self.delayTImer then
        TimerUtility.StopAndRecycle(self.delayTImer)
        self.delayTImer = nil
    end
    if self.hideTimer then
        TimerUtility.StopAndRecycle(self.hideTimer)
        self.hideTimer = nil
    end
end

---OnFeedData
---@param data ItemIconData
function UIHeroAttrCell:OnFeedData(data)
    if Utils.IsNotNull(self.goAddition) then
        self.goAddition:SetActive(data.showBase)
    end
    if Utils.IsNotNull(self.goBaseAddition) then
        self.goBaseAddition:SetActive(data.showBase)
    end
    g_Game.SpriteManager:LoadSprite(data.icon, self.imgIcon)
    self.index = data.index or 1
    self.textLv.text = data.name
    local showAdd = data.add and data.add > 0
    local firstNum = data.num or 0
    local addNum = data.add or 0
    local char = data.showArrow and string.Empty or "+"
    if Utils.IsNotNull(self.goArrow) then
        self.goArrow:SetActive(data.showArrow and showAdd)
    end
    if showAdd then
        if data.isPer then
            self.textAdd.text = char .. string.format('%0.1f', addNum) .. "%"
        else
            self.textAdd.text = char .. addNum
        end
        -- firstNum = firstNum - addNum
    else
        self.textAdd.text = ""
    end
    if data.isPer then
        self.textNum.text = string.format('%0.1f', firstNum) .. "%"
    else
        self.textNum.text = firstNum or 0
    end
    if self.delayTImer then
        TimerUtility.StopAndRecycle(self.delayTImer)
        self.delayTImer = nil
    end
    if self.hideTimer then
        TimerUtility.StopAndRecycle(self.hideTimer)
        self.hideTimer = nil
    end
    if Utils.IsNotNull(self.numEffect) then
        self.numEffect:SetActive(false)
        if data.needPlayNPropEffect then
            self.delayTImer = TimerUtility.DelayExecute(function()
                self.numEffect:SetActive(true)
                self.hideTimer = TimerUtility.DelayExecute(function()
                    self.numEffect:SetActive(false)
                end, 0.5)
            end, 0.1 + self.index * 0.1)
        end
    end
    if data.isUpValue then
        self.numEffect:SetActive(true)
        if Utils.IsNotNull(self.animtriggerTrigger) then
            self.animtriggerTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
        end
    end
    if data.isNewValue then
        if Utils.IsNotNull(self.animtriggerTrigger) then
            self.animtriggerTrigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
        end
    end
end

return UIHeroAttrCell
