local BaseUIComponent = require('BaseUIComponent')
local Delegate = require("Delegate")
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local FpAnimTriggerEvent = require('FpAnimTriggerEvent')
local TimerUtility = require('TimerUtility')

---@class SEClimbTowerSectionPointData
---@field chapterId number
---@field index number

---@class SEClimbTowerSectionPoint:BaseUIComponent
---@field new fun():SEClimbTowerSectionPoint
---@field super BaseUIComponent
local SEClimbTowerSectionPoint = class('SEClimbTowerSectionPoint', BaseUIComponent)

function SEClimbTowerSectionPoint:OnCreate()
    self.btn = self:Button('p_btn_practice', Delegate.GetOrCreate(self, self.OnPointClick))

    self.imgStar1 = self:Image('p_icon_star_1')
    self.imgStar2 = self:Image('p_icon_star_2')
    self.imgStar3 = self:Image('p_icon_star_3')

    self.stateNormal = self:GameObject('p_icon_nomal')
    self.stateLocked = self:GameObject('p_status_lock')
    self.txtNumber = self:Text('p_text_number')

    self.selectGo = self:GameObject('p_status_selected')
    self.vxTrigger = self:AnimTrigger('vx_trigger')
end

---@param data SEClimbTowerSectionPointData
function SEClimbTowerSectionPoint:OnFeedData(data)
    self.chapterId = data.chapterId
    self.index = data.index
    
    ---@type ClimbTowerSectionConfigCell
    self.sectionConfigCell = ModuleRefer.SEClimbTowerModule:GetSectionConfigCell(self.chapterId, self.index)

    self:UpdateUI()

    if self.vxTrigger then
        self.vxTrigger:FinishAll(FpAnimTriggerEvent.Custom2)
        self.vxTrigger:ResetAll(FpAnimTriggerEvent.Custom3)
    end
end

function SEClimbTowerSectionPoint:UpdateUI()
    self.txtNumber.text = I18N.Get(self.sectionConfigCell:Name())
    self.isUnlock = ModuleRefer.SEClimbTowerModule:IsSectionUnlock(self.chapterId, self.index)
    self.stateLocked:SetVisible(not self.isUnlock)
    self.stateNormal:SetVisible(self.isUnlock)

    self.imgStar1:SetVisible(ModuleRefer.SEClimbTowerModule:IsSectionStarAchieved(self.sectionConfigCell:Id(), 1))
    self.imgStar2:SetVisible(ModuleRefer.SEClimbTowerModule:IsSectionStarAchieved(self.sectionConfigCell:Id(), 2))
    self.imgStar3:SetVisible(ModuleRefer.SEClimbTowerModule:IsSectionStarAchieved(self.sectionConfigCell:Id(), 3))
end

function SEClimbTowerSectionPoint:OnPointClick()
    g_Game.EventManager:TriggerEvent(EventConst.SE_CLIMB_TOWER_SECTION_CLICK, self.chapterId, self.index)
end

---@param select boolean
function SEClimbTowerSectionPoint:SetSelect(select)
    self.selectGo:SetVisible(select)

    -- 复位alpha值
    self.vxTrigger:FinishAll(FpAnimTriggerEvent.Custom2)

    if select then
        self.vxTrigger:PlayAll(FpAnimTriggerEvent.Custom3)
    else
        self.vxTrigger:ResetAll(FpAnimTriggerEvent.Custom3)
    end

    if self.isUnlock then
        if select then
            TimerUtility.DelayExecute(function() self.vxTrigger:PlayAll(FpAnimTriggerEvent.Custom1) end, 0.1)
        end
    end
end

return SEClimbTowerSectionPoint