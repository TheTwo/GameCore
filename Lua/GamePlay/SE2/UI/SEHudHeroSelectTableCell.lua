local BaseTableViewProCell = require ('BaseTableViewProCell')

---@class SEHudHeroSelectTableCell : BaseTableViewProCell
local SEHudHeroSelectTableCell = class('SEHudHeroSelectTableCell', BaseTableViewProCell)

function SEHudHeroSelectTableCell:ctor()

end

function SEHudHeroSelectTableCell:OnCreate(param)
    self._inTeam = self:GameObject("p_img_battle")
    self._selected = self:GameObject("p_img_selected")
end


function SEHudHeroSelectTableCell:OnShow(param)
    
end

function SEHudHeroSelectTableCell:OnOpened(param)
end

function SEHudHeroSelectTableCell:OnClose(param)
end

---@param param HeroConfigCache
function SEHudHeroSelectTableCell:OnFeedData(param)
    self._hero = self:LuaObject(param.nodeName)
    ---@type HeroInfoData
    local itemData = {
        heroData = param.data,
        onClick = param.onClick,
    }
    self._hero:FeedData(itemData)
    self._inTeam:SetActive(param.isInTeam == true)
    self._selected:SetActive(param.isSelected == true)
end

return SEHudHeroSelectTableCell;

