local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityPetI18N = require("CityPetI18N")
local LuaReusedComponentPool = require("LuaReusedComponentPool")

---@class CityPetAssignmentUICell:BaseTableViewProCell
local CityPetAssignmentUICell = class('CityPetAssignmentUICell', BaseTableViewProCell)

function CityPetAssignmentUICell:OnCreate()
    self._button = self:Button("", Delegate.GetOrCreate(self, self.OnClick))

    ---备选框
    self._base_1 = self:GameObject("base_1")
    ---已选择钩
    self._p_img_selected = self:GameObject("p_img_selected")
    ---宠物名字
    self._p_text_name = self:Text("p_text_name")

    ---工作相关数值显示区
    self._p_layout_buff = self:Transform("p_layout_buff")
    ---工作相关属性模板节点
    ---@type CityPetAssignProperty
    self._p_item_buff = self:LuaBaseComponent("p_item_buff")
    self._pool_buff = LuaReusedComponentPool.new(self._p_item_buff, self._p_layout_buff)

    ---工作能力显示
    self._p_layout_type = self:Transform("p_layout_type")
    ---工作能力图标模板节点
    ---@type CityPetAssignWorkType
    self._p_type = self:LuaBaseComponent("p_type")
    self._pool_type = LuaReusedComponentPool.new(self._p_type, self._p_layout_type)

    ---血条
    self._p_progress_blood = self:Slider("p_progress_blood")

    ---宠物头像
    ---@type CommonPetIconSmall
    self._p_pet = self:LuaObject("p_pet")

    ---空闲状态
    self._p_free = self:GameObject("p_free")
    self._p_text_free = self:Text("p_text_free", CityPetI18N.UIHint_Free)

    ---工作地点
    self._p_position = self:GameObject("p_position")
    self._p_text_position = self:Text("p_text_position")

    ---圈层不适配提示
    self._p_btn_hint = self:Button("p_btn_hint", Delegate.GetOrCreate(self, self.OnClickLandNotFit))

    ---在编队上的遮罩
    self._p_mask = self:GameObject("p_mask")
end

---@param data CityPetAssignmentUICellData
function CityPetAssignmentUICell:OnFeedData(data)
    self.data = data
    local needShowMultiToggle = data:IsMultiSelection()
    self._base_1:SetVisible(needShowMultiToggle)

    self._p_img_selected:SetVisible(data:IsSelected())
    self._p_text_name.text = data:GetPetName()

    local needShowBuffValue = data:NeedShowBuff()
    self._p_layout_buff:SetVisible(needShowBuffValue)

    if needShowBuffValue then
        self._pool_buff:HideAll()
        local buffData = data:GetWorkRelativeBuffData()
        for i, v in ipairs(buffData) do
            local item = self._pool_buff:GetItem()
            item:FeedData(v)
        end
    end

    local needShowFeature = data:NeedShowFeature()
    self._p_layout_type:SetVisible(needShowFeature)
    if needShowFeature then
        self._pool_type:HideAll()
        local features = data:GetPetWorkCfgs()
        for i, v in ipairs(features) do
            local item = self._pool_type:GetItem()
            item:FeedData(v)
        end
    end

    self._p_pet:FeedData(data:GetPetData())

    local needShowPosition = data:NeedShowPosition()
    local isFree = data:IsFree()
    self._p_free:SetVisible(needShowPosition and isFree)
    self._p_position:SetVisible(needShowPosition and not isFree)
    if needShowPosition and not isFree then
        self._p_text_position.text = data:GetWorkPositionName()
    end

    self._p_btn_hint:SetVisible(data:IsLandNotFit())
    self._p_progress_blood.value = data:GetBloodPercent()
    self._p_mask:SetActive(data:IsInTroop())
end

function CityPetAssignmentUICell:OnClick()
    if self.data:SwitchSelect() then
        self:OnFeedData(self.data)
    end
end

function CityPetAssignmentUICell:OnClickLandNotFit()
    self.data:ShowLandNotFitHint(self._p_btn_hint.transform)
end

return CityPetAssignmentUICell