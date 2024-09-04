local BaseUIComponent = require ('BaseUIComponent')
local CityLegoBuffProviderType = require('CityLegoBuffProviderType')
local EventConst = require('EventConst')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class CityLegoBuffRouteMapUIFormulaElement:BaseUIComponent
local CityLegoBuffRouteMapUIFormulaElement = class('CityLegoBuffRouteMapUIFormulaElement', BaseUIComponent)

---@class CityLegoBuffRouteMapUIFormulaElementData
---@field cfg RoomTagConfigCell
---@field legoBuilding CityLegoBuilding
---@field provider CityLegoBuffProvider

function CityLegoBuffRouteMapUIFormulaElement:OnCreate()
    self._p_icon_furniture = self:Image("p_icon_furniture")
    self._p_img_select = self:GameObject("p_img_select")
    self._p_icon_have = self:GameObject("p_icon_have")
    self._p_btn_furniture = self:Button("p_btn_furniture", Delegate.GetOrCreate(self, self.OnClick))
    self._p_icon_style = self:Image("p_icon_style")
end

---@param data CityLegoBuffRouteMapUIFormulaElementData
function CityLegoBuffRouteMapUIFormulaElement:OnFeedData(data)
    self.data = data

    self._p_img_select:SetActive(false)

    local provider = data.provider
    -- if provider == nil then
        self._p_icon_furniture:SetVisible(true)
        self._p_icon_have:SetActive(provider ~= nil)
        self._p_icon_style:SetVisible(false)
        g_Game.SpriteManager:LoadSprite(data.cfg:IconInRouteMap(), self._p_icon_furniture)
    -- else
    --     self._p_icon_furniture:SetVisible(true)
    --     self._p_icon_have:SetActive(true)
    --     self._p_icon_style:SetVisible(false)
    --     g_Game.SpriteManager:LoadSprite(provider:GetImage(), self._p_icon_furniture)
    -- end
end

function CityLegoBuffRouteMapUIFormulaElement:OnClick()
    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_LEGO_BUFF_RECOMMEND_BUFF_TAG, self.data.cfg:Id())
end

return CityLegoBuffRouteMapUIFormulaElement