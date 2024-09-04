local BaseTableViewProCell = require ('BaseTableViewProCell')
local Delegate = require('Delegate')
local BattleSignalConfig = require("BattleSignalConfig")

---@class UIBattleSignalTableCellData
---@field config AllianceMapLabelConfigCell

---@class UIBattleSignalTableCell : BaseTableViewProCell
local UIBattleSignalTableCell = class('UIBattleSignalTableCell', BaseTableViewProCell)


function UIBattleSignalTableCell:ctor()
    BaseTableViewProCell.ctor(self)
end

function UIBattleSignalTableCell:OnCreate()
    self._selfBtn = self:Button("", Delegate.GetOrCreate(self, self.OnBtnItemIconClicked))
    self._p_icon = self:Image("p_icon")
    self._p_img_select_logo = self:GameObject('p_img_select_logo')
    self._p_text_use_1 = self:Text("p_text_use_1")
end

---@param param UIBattleSignalTableCellData
function UIBattleSignalTableCell:OnFeedData(param)
    self.data = param
    g_Game.SpriteManager:LoadSprite(self.data.config:Icon(), self._p_icon)
    local name = BattleSignalConfig.GetTypeName(self.data.config)
    if string.IsNullOrEmpty(name) then
        self._p_text_use_1:SetVisible(false)
    else
        self._p_text_use_1.text = name
        self._p_text_use_1:SetVisible(true)
    end
end

function UIBattleSignalTableCell:Select(param)
    self._p_img_select_logo:SetVisible(true)
end

function UIBattleSignalTableCell:UnSelect(param)
    self._p_img_select_logo:SetVisible(false)
end

function UIBattleSignalTableCell:OnBtnItemIconClicked()
    self:SelectSelf()
end

return UIBattleSignalTableCell
