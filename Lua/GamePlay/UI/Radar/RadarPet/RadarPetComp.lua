local BaseUIComponent = require('BaseUIComponent')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local ManualUIConst = require('ManualUIConst')

---@class RadarPetComp : BaseUIComponent
---@field data HeroConfigCache
local RadarPetComp = class('RadarPetComp', BaseUIComponent)

function RadarPetComp:ctor()

end

function RadarPetComp:OnCreate()
    self.child_card_pet_circle = self:LuaObject('child_card_pet_circle')
    self.p_icon_arrow = self:GameObject('p_icon_arrow')
end

function RadarPetComp:OnFeedData(param)
    self.cfgId = param.cfgId
    self.child_card_pet_circle:FeedData(param)
end

function RadarPetComp:Select(param)
    self.p_icon_arrow:SetVisible(true)
    self.child_card_pet_circle:OnSelect()
end

function RadarPetComp:UnSelect(param)
    self.p_icon_arrow:SetVisible(false)
    self.child_card_pet_circle:OnUnselect()
end

function RadarPetComp:SetCheck(isCheck)
    self.child_card_pet_circle:SetCheck(isCheck)
end

return RadarPetComp
