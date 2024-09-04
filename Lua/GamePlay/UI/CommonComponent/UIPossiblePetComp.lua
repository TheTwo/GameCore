local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local Utils = require('Utils')

local UIPossiblePetComp = class('UIPossiblePetComp', BaseTableViewProCell)

---@class UIPossiblePetCompData : CommonPetIconBaseData
---@field isRecommend boolean

function UIPossiblePetComp:OnCreate()
    self.child_card_pet_circle = self:LuaBaseComponent("child_card_pet_circle")
    self._p_icon_recomment = self:GameObject("p_icon_recomment")
end

---@param data UIPossiblePetCompData
function UIPossiblePetComp:OnFeedData(data)
    self.child_card_pet_circle:FeedData(data)
    if not Utils.IsNullOrEmpty(self._p_icon_recomment) then
        if data.isRecommend then
            self._p_icon_recomment:SetActive(true)
        else
            self._p_icon_recomment:SetActive(false)
        end
    end
end

return UIPossiblePetComp