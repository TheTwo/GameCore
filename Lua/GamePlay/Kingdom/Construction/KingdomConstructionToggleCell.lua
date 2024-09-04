local BaseTableViewProCell = require("BaseTableViewProCell")
local Delegate = require("Delegate") 
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local FlexibleMapBuildingFilterType = require("FlexibleMapBuildingFilterType")

---@class KingdomConstructionToggleData
---@field image string
---@field context any

---@class KingdomConstructionToggleCell : BaseTableViewProCell
---@field data KingdomConstructionToggleData
local KingdomConstructionToggleCell = class("KingdomConstructionToggleCell", BaseTableViewProCell)

function KingdomConstructionToggleCell:OnCreate(param)
    self._p_button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))
    self._p_tab_a = self:GameObject("p_tab_a")
    self._p_icon_tab_a = self:Image("p_icon_tab_a")
    self._p_tab_b = self:GameObject("p_tab_b")
    self._p_icon_tab_b = self:Image("p_icon_tab_b")
    self._p_red_dot = self:GameObject("child_reddot_default")
end

---@param data KingdomConstructionToggleData
function KingdomConstructionToggleCell:OnFeedData(data)
    self.data = data
    g_Game.SpriteManager:LoadSprite(data.image, self._p_icon_tab_a)
    g_Game.SpriteManager:LoadSprite(data.image, self._p_icon_tab_b)
    self._p_red_dot:SetVisible(false)
end

function KingdomConstructionToggleCell:OnClick()
    if self.data.context ~= FlexibleMapBuildingFilterType.Alliance then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_bj_weikaifang"))
        return
    end
    self:SelectSelf()
end

function KingdomConstructionToggleCell:Select()
    self._p_tab_a:SetVisible(false)
    self._p_tab_b:SetVisible(true)
end

function KingdomConstructionToggleCell:UnSelect()
    self._p_tab_a:SetVisible(true)
    self._p_tab_b:SetVisible(false)
end

return KingdomConstructionToggleCell