local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local UIHelper = require("UIHelper")

---@class CityLegoBuildingUIFurnitureToggleButtonData
---@field furniture CityFurniture
---@field isSelect boolean
---@field onClick fun(data:CityLegoBuildingUIFurnitureToggleButtonData)

---@class CityLegoBuildingUIFurnitureToggleButton:BaseTableViewProCell
local CityLegoBuildingUIFurnitureToggleButton = class('CityLegoBuildingUIFurnitureToggleButton', BaseTableViewProCell)

function CityLegoBuildingUIFurnitureToggleButton:OnCreate()
    self._child_img_select_circle_s = self:GameObject("child_img_select_circle_s")

    self._p_icon_furniture = self:Image("p_icon_furniture")
    self._p_text_lv = self:Text("p_text_lv")
    self._p_upgrade = self:GameObject("p_upgrade")
    self._p_btn_furniture = self:Button("p_btn_furniture", Delegate.GetOrCreate(self, self.OnClick))
    self._p_broken = self:GameObject("p_broken")
end

---@param data CityLegoBuildingUIFurnitureToggleButtonData
function CityLegoBuildingUIFurnitureToggleButton:OnFeedData(data)
    self.data = data
    
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(data.furniture.furType)
    g_Game.SpriteManager:LoadSprite(typCfg:Image(), self._p_icon_furniture)

    if data.furniture:IsLocked() then
        self._p_icon_furniture.color = UIHelper.TryParseHtmlString("#7F89A6")
    else
        self._p_icon_furniture.color = CS.UnityEngine.Color.white
    end
    
    self._p_text_lv.text = ("Lv.<b>%d</b>"):format(data.furniture.level)
    self._p_text_lv:SetVisible(false)
    self._p_upgrade:SetActive(data.furniture:CanUpgrade() and not data.furniture:IsLocked())
    self._p_broken:SetActive(data.furniture:IsLocked())
    self._child_img_select_circle_s:SetActive(data.isSelect)
end

function CityLegoBuildingUIFurnitureToggleButton:OnClick()
    if self.data.onClick then
        self.data.onClick(self.data)
    end
end

return CityLegoBuildingUIFurnitureToggleButton