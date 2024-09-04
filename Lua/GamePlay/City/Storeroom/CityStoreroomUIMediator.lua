---Scene Name : scene_city_popup_storehouse
local CityCommonRightPopupUIMediator = require ('CityCommonRightPopupUIMediator')
local Delegate = require('Delegate')
local LuaMultiTemplateReusedCompPool = require("LuaMultiTemplateReusedCompPool")
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")

---@class CityStoreroomUIMediator:CityCommonRightPopupUIMediator
local CityStoreroomUIMediator = class('CityStoreroomUIMediator', CityCommonRightPopupUIMediator)

function CityStoreroomUIMediator:OnCreate()
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_focus_target = self:Transform("p_focus_target")

    self._p_text_property_name = self:Text("p_text_property_name")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetails))
    self._p_btn_detail:SetVisible(false)

    self._p_layout_content = self:Transform("p_layout_content")
    ---@type CityStoreroomUITitleComp
    self._p_title_need = self:LuaObject("p_title_need")
    ---@type CityStoreroomUIGridComp
    self._p_layout_grid = self:LuaObject("p_layout_grid")
    ---@type CityStoreroomUIFoodGridComp
    self._p_layout_grid_food = self:LuaObject("p_layout_grid_food")
    self._poolRoot = LuaMultiTemplateReusedCompPool.new(self._p_layout_content)
    self._title_pool = self._poolRoot:GetOrCreateLuaBaseCompPool(self._p_title_need)
    self._grid_pool = self._poolRoot:GetOrCreateLuaBaseCompPool(self._p_layout_grid)
    self._foodGrid_pool = self._poolRoot:GetOrCreateLuaBaseCompPool(self._p_layout_grid_food)
end

---@param param CityStoreroomUIParameter
function CityStoreroomUIMediator:OnOpened(param)
    self.param = param
    self.city = param.city
    self.param:OnMediatorOpened(self)
    self._p_text_property_name.text = self.param:GetTitle()

    self:UpdateStoreroomDisplay()
end

function CityStoreroomUIMediator:OnClose()
    if self.param then
        self.param:OnMediatorClosed(self)
    end
end

function CityStoreroomUIMediator:UpdateStoreroomDisplay()
    self._poolRoot:HideAllPool()
    local dataList = self.param:GetData()
    for i, v in ipairs(dataList) do
        local titleComp = self._title_pool:Alloc()
        UIHelper.SetUIComponentParent(titleComp.CSComponent, self._p_layout_content)
        titleComp:FeedData(v.title)

        if v.title:NeedShowBlood() then
            local foodGridComp = self._foodGrid_pool:Alloc()
            UIHelper.SetUIComponentParent(foodGridComp.CSComponent, self._p_layout_content)
            foodGridComp:FeedData(v.grid)
        else
            local gridComp = self._grid_pool:Alloc()
            UIHelper.SetUIComponentParent(gridComp.CSComponent, self._p_layout_content)
            gridComp:FeedData(v.grid)
        end
    end
end

---@return CS.UnityEngine.RectTransform
function CityStoreroomUIMediator:GetFocusAnchor()
    return self._p_focus_target
end

return CityStoreroomUIMediator