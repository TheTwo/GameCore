local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local UIHelper = require("UIHelper")

local BaseUIComponent = require("BaseUIComponent")

---@class AllianceBehemothHeadCellData
---@field icon string
---@field lv number|nil
---@field isSelected boolean
---@field inUsing boolean
---@field setGrey boolean
---@field setNotifyNode fun(node:NotificationNode)
---@field onclick fun()

---@class AllianceBehemothHeadCell:BaseUIComponent
---@field new fun():AllianceBehemothHeadCell
---@field super BaseUIComponent
local AllianceBehemothHeadCell = class('AllianceBehemothHeadCell', BaseUIComponent)

function AllianceBehemothHeadCell:ctor()
    AllianceBehemothHeadCell.super.ctor(self)
    ---@type AllianceBehemothHeadCellData
    self._data = nil
end

function AllianceBehemothHeadCell:OnCreate(param)
    self._p_icon_behemoth_head = self:Image("p_icon_behemoth_head")
    self._p_select = self:GameObject("p_select")
    self._p_lv = self:GameObject("p_lv")
    self._p_text_lv = self:Text("p_text_lv")
    self._p_now = self:GameObject("p_now")
    ---@type NotificationNode
    self._p_red_dot = self:LuaObject("p_red_dot")
    self._p_click_area = self:Button("p_click_area", Delegate.GetOrCreate(self, self.OnClickCell))
end

---@param data AllianceBehemothHeadCellData
function AllianceBehemothHeadCell:FeedData(data)
    self._data = data
    g_Game.SpriteManager:LoadSprite(data.icon, self._p_icon_behemoth_head)
    UIHelper.SetGray(self._p_icon_behemoth_head.gameObject, data.setGrey or false)
    self:SetSelected(data.isSelected)
    self._p_lv:SetVisible(data.lv ~= nil)
    if data.lv then
        self._p_text_lv.text = tostring(data.lv) 
    end
    self._p_now:SetVisible(data.inUsing or false)
    ModuleRefer.NotificationModule:RemoveFromGameObject(self._p_red_dot.go, false)
    if data.setNotifyNode then
        self._p_red_dot.go:SetVisible(true)
        data.setNotifyNode(self._p_red_dot)
    else
        self._p_red_dot.go:SetVisible(false)
    end
end

function AllianceBehemothHeadCell:OnClickCell()
    if self._data and self._data.onclick then
        self._data.onclick()
    end
end

function AllianceBehemothHeadCell:SetSelected(selected)
    self._p_select:SetVisible(selected)
end

return AllianceBehemothHeadCell