local BaseTableViewProCell = require('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')

---class UIHeroStrengthenCellGroupData
---field strengthLv number

---@class UIHeroStrengthenCellGroup : BaseTableViewProCell
---@field data HeroConfigCache
local UIHeroStrengthenCellGroup = class('UIHeroStrengthenCellGroup', BaseTableViewProCell)

function UIHeroStrengthenCellGroup:OnCreate()
    self.go = self:GameObject('')
    self.star1 = self:LuaObject('p_strengthen_hero_icon_1')
    self.star2 = self:LuaObject('p_strengthen_hero_icon_2')
    self.star3 = self:LuaObject('p_strengthen_hero_icon_3')
    self.star4 = self:LuaObject('p_strengthen_hero_icon_4')
    self.star5 = self:LuaObject('p_strengthen_hero_icon_5')
    self.star6 = self:LuaObject('p_strengthen_hero_icon_6')

    self.stars = {self.star1, self.star2, self.star3, self.star4, self.star5, self.star6}
end

---@param starLevel number
function UIHeroStrengthenCellGroup:OnFeedData(starLevel)
    local stageNum = math.floor(starLevel / 5)
    local lastStarNum = starLevel % 5

    for i = 0, 5 do
        local stars
        if i < stageNum then
            stars = 5
        elseif i == stageNum then
            stars = lastStarNum
        else
            stars = 0
        end

        self.stars[i + 1]:FeedData(stars)
    end
end

return UIHeroStrengthenCellGroup;
