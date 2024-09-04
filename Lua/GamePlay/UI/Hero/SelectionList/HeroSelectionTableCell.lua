local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local Utils = require('Utils')

---@class HeroSelectionTableCell : BaseTableViewProCell
local HeroSelectionTableCell = class('HeroSelectionTableCell', BaseTableViewProCell)

function HeroSelectionTableCell:ctor()

end

function HeroSelectionTableCell:OnCreate(param)   
    -- self._selected = self:GameObject("p_img_selected")
    self._goCurTeamFlag = self:GameObject('p_img_current_team')
    self._goOtherTeamFlag = self:GameObject('p_base_other_team')
    self._textOtherTeamIndex = self:Text('p_text_team_index')
end


function HeroSelectionTableCell:OnShow(param)
    
end

function HeroSelectionTableCell:OnOpened(param)
end

function HeroSelectionTableCell:OnClose(param)
    local a = 1
end

---@param param HeroConfigCache
function HeroSelectionTableCell:OnFeedData(param)
    ---@type HeroInfoItemComponent
    self._hero = self:LuaObject(param.nodeName)
    ---@type HeroInfoData
    local itemData = {
        heroData = param.data,
        onClick = param.onClick,
    }
    self._hero:FeedData(itemData)    
    -- self._selected:SetActive(param.isSelected == true)
    self._hero:ChangeStateSelect(param.isSelected)
    self._goCurTeamFlag:SetActive(param.isInCurTeam)
    
    if param.isInOtherTeam then
        self._goOtherTeamFlag:SetActive(true)
        self._textOtherTeamIndex.text = tostring(param.teamIndex)
    else
        self._goOtherTeamFlag:SetActive(false)
    end
end

function HeroSelectionTableCell:Select(param)
    --override
    if Utils.IsNotNull(self._hero) then
        self._hero:ChangeStateSelect(true)
    end
end
function HeroSelectionTableCell:UnSelect(param)
    --override
    if Utils.IsNotNull(self._hero) then
        self._hero:ChangeStateSelect(false)
    end
end

return HeroSelectionTableCell;

