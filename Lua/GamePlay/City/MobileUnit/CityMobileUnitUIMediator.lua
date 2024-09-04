---Scene Name : scene_city_popup_accredit_troop
local CityCommonRightPopupUIMediator = require ('CityCommonRightPopupUIMediator')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local Delegate = require('Delegate')
local CityMobileUnitI18N = require("CityMobileUnitI18N")
local LuaMultiTemplateReusedCompPool = require("LuaMultiTemplateReusedCompPool")
local EfficiencyConditionType = require("EfficiencyConditionType")
local UIHelper = require("UIHelper")
local I18N = require("I18N")

---@class CityMobileUnitUIMediator:CityCommonRightPopupUIMediator
local CityMobileUnitUIMediator = class('CityMobileUnitUIMediator', CityCommonRightPopupUIMediator)

function CityMobileUnitUIMediator:OnCreate()
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_focus_target = self:Transform("p_focus_target")
    self._p_btn_exit = self:Button("p_btn_exit", Delegate.GetOrCreate(self, self.CloseSelf))

    --- 建筑名
    self._p_text_property_name = self:Text("p_text_property_name")

    --- 产量信息
    self._p_layout_buff = self:Transform("p_layout_buff")
    self._p_text_buff = self:Text("name", CityMobileUnitI18N.UIHint_Efficiency)
    ---@type CityFurnitureDeployBuffComponent
    self._p_item_buff = self:LuaBaseComponent("p_item_buff")
    self._pool_buff = LuaReusedComponentPool.new(self._p_item_buff, self._p_layout_buff)

    --- 欠缺工种信息
    self._p_hint_need = self:GameObject("p_hint_need")
    self._p_text_hint_need = self:Text("p_text_hint_need", CityMobileUnitI18N.UIHint_NeedWorkerType)
    self._p_icon_1 = self:Image("p_icon_1")
    self._p_icon_2 = self:Image("p_icon_2")
    self._p_icon_3 = self:Image("p_icon_3")

    --- 额外效率加成条件
    self._p_layout_buff_add = self:Transform("p_layout_buff_add")
    --- 效率总加成显示
    self._p_text_buff_add = self:Text("p_text_buff_add")
    ---@type CityMobileUnitBonusAssociatedTagNeedComp
    self._p_btn_style = self:LuaObject("p_btn_style")
    ---@type CityMobileUnitBonusQualityNeedComp
    self._p_btn_quality = self:LuaObject("p_btn_quality")
    ---@type CityMobileUnitBonusWorkTypeSumNeedComp
    self._p_btn_type = self:LuaObject("p_btn_type")
    self._multi_pool = LuaMultiTemplateReusedCompPool.new(self._p_layout_buff_add)

    self._associate_pool = self._multi_pool:GetOrCreateLuaBaseCompPool(self._p_btn_style)
    self._quality_pool = self._multi_pool:GetOrCreateLuaBaseCompPool(self._p_btn_quality)
    self._workTypeSum_pool = self._multi_pool:GetOrCreateLuaBaseCompPool(self._p_btn_type)

    --- 宠物列表
    self._p_title = self:GameObject("p_title")
    self._p_text_title_l = self:Text("p_text_title_l", CityMobileUnitI18N.UIHint_MobileUnit)
    --- 入驻宠物数量提示
    self._p_text_title_r = self:Text("p_text_title_r")
    ---@see CityMobileUnitPetCell
    self._p_table = self:TableViewPro("p_table")

    self._p_btn_change = self:Button("p_btn_change", Delegate.GetOrCreate(self, self.OnClickChangePet))
    self._p_text_change = self:Text("p_text_change", CityMobileUnitI18N.UIButton_Exchange)
    self._p_btn_one = self:Button("p_btn_one", Delegate.GetOrCreate(self, self.OnClickAssignImmediately))
    self._p_text_one = self:Text("p_text_one", CityMobileUnitI18N.UIButton_BatchAssign)

    self._p_text_hint = self:Text("p_text_hint")
end

---@param param CityMobileUnitUIParameter
function CityMobileUnitUIMediator:OnOpened(param)
    self.param = param
    self.city = param.city
    self.param:OnMediatorOpen(self)
    self._p_text_property_name.text = self.param:GetName()
    
    self:UpdateUI()
end

function CityMobileUnitUIMediator:OnClose(param)
    if self.param then
        self.param:OnMediatorClosed(self)
    end
end

function CityMobileUnitUIMediator:GetFocusAnchor()
    return self._p_focus_target
end

function CityMobileUnitUIMediator:OnClickChangePet()
    return self.param:OpenAssignPopupUI(self._p_btn_change.transform)
end

function CityMobileUnitUIMediator:OnClickAssignImmediately()
    return self.param:AutoBatchAssign(self._p_btn_one.transform)
end

function CityMobileUnitUIMediator:UpdateOutput()
    self._pool_buff:HideAll()
    for i, v in ipairs(self.param:GetOutputList()) do
        local item = self._pool_buff:GetItem()
        item:FeedData(v)
    end
end

function CityMobileUnitUIMediator:UpdateFeature()
    local showWorkTypeNeed = self.param:ShowFeatureNeed()
    self._p_hint_need:SetActive(showWorkTypeNeed)
    if showWorkTypeNeed then
        local icons = {self._p_icon_1, self._p_icon_2, self._p_icon_3}
        local needList = self.param:GetCurrentNeedFeatureList()
        for i, image in ipairs(icons) do
            local feature = needList[i]
            if feature then
                g_Game.SpriteManager:LoadSprite(self.city.petManager:GetFeatureIcon(feature), image)
                image:SetVisible(true)
            else
                image:SetVisible(false)
            end
        end
    end
end

function CityMobileUnitUIMediator:UpdateBonus()
    local showBonus = self.param:ShowBonus()
    self._p_layout_buff_add:SetVisible(showBonus)
    if showBonus then
        self._p_text_buff_add.text = I18N.Get("hotspring_subtitle02")..self.param:GetBonusText()
    end

    self._multi_pool:HideAllPool()
    for i, v in ipairs(self.param:GetBonusList()) do
        if v.condition:EfficiencyConditionType() == EfficiencyConditionType.AssociatedTagNumAbove then
            local item = self._associate_pool:Alloc()
            item:FeedData(v)
            UIHelper.SetUIComponentParent(item.CSComponent, self._p_layout_buff_add)
        elseif v.condition:EfficiencyConditionType() == EfficiencyConditionType.PetQualityNumAbove then
            local item = self._quality_pool:Alloc()
            item:FeedData(v)
            UIHelper.SetUIComponentParent(item.CSComponent, self._p_layout_buff_add)
        elseif v.condition:EfficiencyConditionType() == EfficiencyConditionType.PetLevelSumAbove then
            local item = self._workTypeSum_pool:Alloc()
            item:FeedData(v)
            UIHelper.SetUIComponentParent(item.CSComponent, self._p_layout_buff_add)
        end
    end
end

function CityMobileUnitUIMediator:UpdatePetTableView()
    local petCellData = self.param:GetPetCellData()
    self._p_table:Clear()
    for i, v in ipairs(petCellData) do
        self._p_table:AppendData(v)
    end
end

function CityMobileUnitUIMediator:UpdateUI()
    self:UpdateOutput()
    self:UpdateFeature()
    self:UpdateBonus()
    self:UpdatePetTableView()
    self._p_text_hint.text = self.param:GetOfflineTimeStr()
end

return CityMobileUnitUIMediator