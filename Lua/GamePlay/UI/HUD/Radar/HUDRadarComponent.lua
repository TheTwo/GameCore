local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local KingdomMapUtils = require('KingdomMapUtils')
local DBEntityType = require('DBEntityType')
---@class HUDRadarComponent : BaseUIMediator
local HUDRadarComponent = class("HUDRadarComponent",BaseUIComponent)

function HUDRadarComponent:OnCreate()
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.textProgress = self:Text('p_text_progress')
    self.btnIntel = self:Button('p_btn_intel', Delegate.GetOrCreate(self, self.OnBtnIntelClicked))
    self.goImgSelectIntel = self:GameObject('p_img_select_intel')
    self.btnMonster = self:Button('p_btn_monster', Delegate.GetOrCreate(self, self.OnBtnMonsterClicked))
    self.goImgSelectMonster = self:GameObject('p_img_select_monster')
    self.btnResources = self:Button('p_btn_resources', Delegate.GetOrCreate(self, self.OnBtnResourcesClicked))
    self.goImgSelectResoures = self:GameObject('p_img_select_resoures')
    self.selectIcons = {self.goImgSelectIntel, self.goImgSelectMonster, self.goImgSelectResoures}
end

function HUDRadarComponent:OnOpened(param)

end

function HUDRadarComponent:OnClose(param)

end

function HUDRadarComponent:OnBtnDetailClicked()

end

function HUDRadarComponent:OnFeedData(param)

end

function HUDRadarComponent:OnBtnIntelClicked(args)
    -- ModuleRefer.WorldEventModule:SetFilterType(wrpc.RadarEntityType.RadarEntityType_Expedition)
    -- KingdomMapUtils.GetMapSystem():Refresh(DBEntityType.Expedition)
    -- self:HideSelect(1)
end

function HUDRadarComponent:OnBtnMonsterClicked(args)
    --ModuleRefer.WorldEventModule:SetFilterType()
    -- KingdomMapUtils.GetMapSystem():Refresh(DBEntityType.Expedition)
    -- self:HideSelect(2)
end

function HUDRadarComponent:OnBtnResourcesClicked(args)
    -- ModuleRefer.WorldEventModule:SetFilterType(wrpc.RadarEntityType.RadarEntityType_ResourceField)
    -- KingdomMapUtils.GetMapSystem():Refresh(DBEntityType.Expedition)
    -- self:HideSelect(3)
end

function HUDRadarComponent:HideSelect(index)
    for i, icon in ipairs(self.selectIcons) do
        icon:SetActive(i == index)
    end
end

return HUDRadarComponent