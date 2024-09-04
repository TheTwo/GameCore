---Scene Name : scene_city_popup_accredit
local CityCommonRightPopupUIMediator = require ('CityCommonRightPopupUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityFurnitureDeployI18N = require("CityFurnitureDeployI18N")
local LuaReusedComponentPool = require("LuaReusedComponentPool")

---@class CityFurnitureDeployUIMediator:CityCommonRightPopupUIMediator
local CityFurnitureDeployUIMediator = class('CityFurnitureDeployUIMediator', CityCommonRightPopupUIMediator)

function CityFurnitureDeployUIMediator:OnCreate()
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_focus_target = self:Transform("p_focus_target")
    self._p_btn_exit = self:Button("p_btn_exit", Delegate.GetOrCreate(self, self.CloseSelf))

    ---UI左侧底部综合性描述
    self._p_text_hint = self:Text("p_text_hint")

    ---标题、能力需要
    self._group_title = self:GameObject("group_title")
    self._p_text_property_name = self:Text("p_text_property_name")

    self._p_layout_type = self:Transform("p_layout_type")
    self._p_btn_type = self:Button("p_btn_type", Delegate.GetOrCreate(self, self.OnClickNeedFeature))
    self._p_text_type = self:Text("p_text_type", CityFurnitureDeployI18N.UIHint_NeedFeature)
    self._p_icon_type = self:Image("p_icon_type")
    self._pool_featureIcon = LuaReusedComponentPool.new(self._p_icon_type, self._p_layout_type)

    ---描述内容
    self._p_text_desc = self:Text("p_text_desc")

    ---增益效果
    self._p_layout_buff = self:Transform("p_layout_buff")
    ---增益标题
    self._p_text_buff = self:Text("p_text_buff")
    self._p_item_buff = self:LuaBaseComponent("p_item_buff")
    self._pool_buff = LuaReusedComponentPool.new(self._p_item_buff, self._p_layout_buff)

    ---提示内容
    self._p_hint = self:GameObject("p_hint")
    self._p_text_hint_pet = self:Text("p_text_hint_pet")

    ---子标题
    self._p_title = self:GameObject("p_title")
    self._p_text_title_l = self:Text("p_text_title_l")
    self._p_text_title_r = self:Text("p_text_title_r")

    ---列表
    self._p_table = self:TableViewPro("p_table")
end

---@param param CityFurnitureDeployUIParameter
function CityFurnitureDeployUIMediator:OnOpened(param)
    self.param = param
    self.city = param.city
    self.param:OnMediatorOpened(self)

    self:UpdateUI()
end

function CityFurnitureDeployUIMediator:OnClose(param)
    if self.param then
        self.param:OnMediatorClosed(self)
    end
end

function CityFurnitureDeployUIMediator:UpdateUI()
    self._p_text_hint.text = self.param.dataSrc:GetMainHint()

    self._group_title:SetActive(self.param.dataSrc:ShowMainTitle())
    local showName = self.param.dataSrc:ShowName()
    self._p_text_property_name:SetVisible(showName)
    if showName then
        self._p_text_property_name.text = self.param.dataSrc.name
    end

    local showFeature = self.param.dataSrc:ShowFeature()
    if showFeature then
        self._pool_featureIcon:HideAll()
        for i, v in ipairs(self.param.dataSrc.features) do
            local image = self._pool_featureIcon:GetItem()
            g_Game.SpriteManager:LoadSprite(self.city.petManager:GetFeatureIcon(v), image)
        end
    end

    local showDesc = self.param.dataSrc:ShowDesc()
    if showDesc then
        self._p_text_desc.text = self.param.dataSrc.desc
    end

    local showBuffValue = self.param.dataSrc:ShowBuffValue()
    self._p_layout_buff:SetVisible(showBuffValue)
    if showBuffValue then
        self._p_text_buff.text = self.param.dataSrc:GetBuffTitle()
        self._pool_buff:HideAll()
        for i, v in ipairs(self.param.dataSrc:GetBuffData()) do
            local item = self._pool_buff:GetItem()
            item:FeedData(v)
        end
    end

    local showHint = self.param.dataSrc:ShowHint()
    self._p_hint:SetActive(showHint)
    if showHint then
        self._p_text_hint_pet.text = self.param.dataSrc:GetHint()
    end

    local showTitle = self.param.dataSrc:ShowMemberTitle()
    self._p_title:SetActive(showTitle)
    if showTitle then
        local showLeftTitle = self.param.dataSrc:ShowLeftTitle()
        self._p_text_title_l:SetVisible(showLeftTitle)
        if showLeftTitle then
            self._p_text_title_l.text = self.param.dataSrc:GetLeftTitle()
        end
        
        local showRightTitle = self.param.dataSrc:ShowRightTitle()
        self._p_text_title_r:SetVisible(showRightTitle)
        if showRightTitle then
            self._p_text_title_r.text = self.param.dataSrc:GetRightTitle()
        end
    end

    self._p_table:Clear()
    local dataList = self.param.dataSrc:GetTableViewCellData()
    for i, v in ipairs(dataList) do
        self._p_table:AppendData(v, v:GetPrefabIndex())
    end
end

---@return CS.UnityEngine.RectTransform
function CityFurnitureDeployUIMediator:GetFocusAnchor()
    return self._p_focus_target
end

return CityFurnitureDeployUIMediator