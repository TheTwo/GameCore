local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require("ConfigRefer")
local UIHelper = require('UIHelper')
local LightRewardCell = class('LightRewardCell',BaseUIComponent)

function LightRewardCell:OnCreate()
    self.imgItemIcon = self:Image('p_item_icon')
    self.textValueQuantity = self:Text('p_value_quantity')
    self.goRespond = self:GameObject('p_respond')
    self.itemCurve = self:BindComponent("", typeof(CS.ItemRewardCurve))
    self.goRespond:SetActive(false)
end

function LightRewardCell:OnFeedData(itemInfo)
    local itemCfg = ConfigRefer.Item:Find(itemInfo.id)
    local icon = UIHelper.GetFitItemIcon(self.imgItemIcon, itemCfg)
    if itemInfo.showCount then
        self.textValueQuantity.text = itemInfo.count
    else
        self.textValueQuantity.text = ""
    end
    g_Game.SpriteManager:LoadSprite(icon, self.imgItemIcon)
    self.itemInfo = itemInfo
end

function LightRewardCell:IsFixedScreenPos()
    return self.itemInfo.pos and self.itemInfo.pos.X ~= 0 and self.itemInfo.pos.Y ~= 0
end

function LightRewardCell:GetCoorPos()
    return self.itemInfo.pos
end

function LightRewardCell:GetProfitReason()
    return self.itemInfo.reason
end

function LightRewardCell:GetItemId()
    return self.itemInfo.id
end

function LightRewardCell:GetScale()
    return self.itemCurve.scale or 0.5
end

function LightRewardCell:GetScaleTime()
    return self.itemCurve.scaleTime or 0.2
end

function LightRewardCell:GetScaleEase()
    return self.itemCurve.scaleEase
end

function LightRewardCell:GetFlyTime()
    return self.itemCurve.minFlyTime + math.random(0, 1) * (self.itemCurve.maxFlyTime - self.itemCurve.minFlyTime)
end

function LightRewardCell:GetFlyCurve()
    local curves = self.itemCurve.animationCurves
    local index = math.random(0, curves.Length - 1)
    return curves[0]
end

function LightRewardCell:GetFlyEase()
    return self.itemCurve.flyEase
end

function LightRewardCell:GetRotation()
    return self.itemCurve.minRotation + math.random(0, 1) * (self.itemCurve.maxRotation - self.itemCurve.minRotation)
end

function LightRewardCell:GetFlyRotation()
    return self.itemCurve.minFlyRotation + math.random(0, 1) * (self.itemCurve.maxFlyRotation - self.itemCurve.minFlyRotation)
end

function LightRewardCell:PlayEffect()
    self.goRespond:SetActive(false)
    self.goRespond:SetActive(true)
end

function LightRewardCell:StopEffect()
    self.goRespond:SetActive(false)
end

return LightRewardCell
