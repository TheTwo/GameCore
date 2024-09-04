local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

---@class CityFurniturePlaceUIToggleCell:BaseTableViewProCell
---@field uiMediator CityFurniturePlaceUIMediator
local CityFurniturePlaceUIToggleCell = class('CityFurniturePlaceUIToggleCell', BaseTableViewProCell)

function CityFurniturePlaceUIToggleCell:OnCreate()
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))

    self._p_tab_a = self:GameObject("p_tab_a")          ----未选中根节点
    self._p_icon_tab_a = self:Image("p_icon_tab_a")     ----未选中图片
    self._p_txt_name_tab_a = self:Text("p_txt_name_tab_a")  ----未选中名字
    
    self._p_tab_b = self:GameObject("p_tab_b")          ----未选中根节点
    self._p_icon_tab_b = self:Image("p_icon_tab_b")     ----选中图片
    self._p_txt_name_tab_b = self:Text("p_txt_name_tab_b")  ----选中名字
    
    self._child_reddot_default = self:GameObject("child_reddot_default")     ----红点
end

---@param data CityFurniturePlaceUIToggleDatum
function CityFurniturePlaceUIToggleCell:OnFeedData(data)
    self.data = data
    self.uiMediator = self:GetParentBaseUIMediator()
    
    -- g_Game.SpriteManager:LoadSprite(data.image, self._p_icon_tab_a)
    -- g_Game.SpriteManager:LoadSprite(data.image, self._p_icon_tab_b)

    self._p_tab_a:SetActive(not self.data.isSelected)
    self._p_tab_b:SetActive(self.data.isSelected)

    self._p_txt_name_tab_a.text = self.data.name
    self._p_txt_name_tab_b.text = self.data.name

    if data.notifyNode then
        ModuleRefer.NotificationModule:AttachToGameObject(data.notifyNode, self._child_reddot_default)
        self._child_reddot_default:SetActive(true)
    else
        ModuleRefer.NotificationModule:RemoveFromGameObject(self._child_reddot_default, false)
        self._child_reddot_default:SetActive(false)
    end
end

function CityFurniturePlaceUIToggleCell:OnClick()
    if self.uiMediator then
        self.uiMediator:SelectToggleData(self.data)
    end
end

return CityFurniturePlaceUIToggleCell