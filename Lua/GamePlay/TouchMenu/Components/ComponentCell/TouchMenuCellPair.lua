local BaseUIComponent = require ('BaseUIComponent')
local Delegate = require('Delegate')

---@class TouchMenuCellPair:BaseUIComponent
local TouchMenuCellPair = class('TouchMenuCellPair', BaseUIComponent)

function TouchMenuCellPair:OnCreate()
    self._p_text_item_name = self:Text("p_text_item_name")
    self._p_icon_item_original = self:Image("p_icon_item_original")
    self._p_icon_item = self:Image("p_icon_item")
    self._p_text_item_content = self:Text("p_text_item_content")
    self._child_comp_btn_detail = self:GameObject("child_comp_btn_detail")
    self._p_btn_goto = self:Image("p_btn_goto")
    self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickHintButton))
    self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClickGotoButton))
    
end

---@param data TouchMenuCellPairDatum
function TouchMenuCellPair:OnFeedData(data)
    self.data = data
    self.data:BindUICell(self)
end

function TouchMenuCellPair:OnClose()
    if self.data then
        self.data:UnbindUICell()
        self.data = nil
    end
end

function TouchMenuCellPair:UpdateLeftLabel(label)
    self._p_text_item_name.text = label
end

function TouchMenuCellPair:UpdateRightLabel(label)
    self._p_text_item_content.text = label
end

function TouchMenuCellPair:UpdateSprite(sprite)
    local show = not string.IsNullOrEmpty(sprite)
    self._p_icon_item_original:SetVisible(show)
    if show then
        g_Game.SpriteManager:LoadSprite(sprite, self._p_icon_item_original)
    end
end

function TouchMenuCellPair:UpdateBlackSprite(sprite)
    local show = not string.IsNullOrEmpty(sprite)
    self._p_icon_item:SetVisible(show)
    if show then
        g_Game.SpriteManager:LoadSprite(sprite, self._p_icon_item)
    end
end

function TouchMenuCellPair:DisplayHintButton(show)
    self._child_comp_btn_detail:SetVisible(show)
end

function TouchMenuCellPair:DisplayGotoButton(show)
    self._p_btn_goto:SetVisible(show)
end

function TouchMenuCellPair:OnClickHintButton()
    self.data:OnClickHintButton()
end

function TouchMenuCellPair:OnClickGotoButton()
    self.data:OnClickGotoButton()
end

return TouchMenuCellPair