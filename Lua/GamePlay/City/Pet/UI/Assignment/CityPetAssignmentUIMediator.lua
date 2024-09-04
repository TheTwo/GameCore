---Scene Name : scene_city_popup_pet_list
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityPetI18N = require("CityPetI18N")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local I18N = require("I18N")
local CityPetAssignmentUICellData = require("CityPetAssignmentUICellData")
local CastleAddPetParameter = require("CastleAddPetParameter")
local PetModifyNameParameter = require("PetModifyNameParameter")
local PetWorkType = require('PetWorkType')
---@class CityPetAssignmentUIMediator:BaseUIMediator
local CityPetAssignmentUIMediator = class('CityPetAssignmentUIMediator', BaseUIMediator)

function CityPetAssignmentUIMediator:OnCreate()
    ---@type CommonPopupBackLargeComponent
    self._child_popup_base_l = self:LuaObject("child_popup_base_l")

    ---工种相关
    self._p_text_title = self:Text("p_text_title", CityPetI18N.UITitle_YouHave)
    self._p_features = self:Transform("p_features")

    ---@type UIPetWorkTypeComp
    self._p_type_main = self:LuaBaseComponent("p_type_main")
    ---工种图标池
    self._pool_feature = LuaReusedComponentPool.new(self._p_type_main, self._p_features)

    ---特殊缺少信息提示
    self._group_hint = self:GameObject("group_hint")
    self._ui_emoji_text = self:BindComponent("ui_emoji_text", typeof(CS.UnityEngine.UI.Extensions.TextPic))

    ---宠物卡片table
    ---@see CityPetAssignmentUICell
    self._p_table_pet = self:TableViewPro("p_table_pet")

    ---底部按钮
    self._p_bottom = self:GameObject("p_bottom")
    ---可多选文本显示（e.g:可多选:1/5）
    self._p_text_number = self:Text("p_text_number")
    self._child_comp_btn_a_l_u2 = self:Button("child_comp_btn_a_l_u2", Delegate.GetOrCreate(self, self.OnClick))
    self._p_text = self:Text("p_text", CityPetI18N.UIBtn_Assign)

    self._p_text_null = self:Text("p_text_null", CityPetI18N.UIHint_NonPet)
end

---@param param CityPetAssignmentUIParameter
function CityPetAssignmentUIMediator:OnOpened(param)
    self.param = param
    self.param:OnMediatorOpended(self)
    ---@type CommonBackButtonData
    local titleCompData = {title = self.param:GetTitle()}
    self._child_popup_base_l:FeedData(titleCompData)

    local needShowFeature = self.param:NeedShowFeature()
    self._p_text_title:SetVisible(needShowFeature)
    if needShowFeature then
        self._p_text_title.text = I18N.Get(CityPetI18N.UIHint_FeatureNeed)
        self._pool_feature:HideAll()
        
        local features = self.param:GetFeatures()
        local city = self.param.handle.city
        for i, v in ipairs(features) do
            local icon = city.petManager:GetFeatureIcon(v)
            local param = { icon =icon, onClick = function()
                local itemInfos
                if v == PetWorkType.AnimalHusbandry then
                    itemInfos = ModuleRefer.PetModule:GetPetItemInfoByPets(self.param.handle.allPetsId, v)
                else
                    itemInfos = ModuleRefer.PetModule:GetPetItemByWorkType(v)
                end
                ModuleRefer.InventoryModule:OpenExchangePanel(itemInfos)
            end}
            local item = self._pool_feature:GetItem().Lua
            item:FeedData(param)
        end
    end
    
    self._p_table_pet:Clear()
    local petsIds = self.param.handle.allPetsId
    local orderList = {}
    for id, v in pairs(petsIds) do
        table.insert(orderList, id)
    end

    if self.param.handle.petSort then
        table.sort(orderList, self.param.handle.petSort)
    end

    ---@type table<number, CityPetAssignmentUICellData>
    self._dataMap = {}
    self.petCount = #orderList
    for _, id in ipairs(orderList) do
        local data = CityPetAssignmentUICellData.new(self.param.handle, id)
        self._dataMap[id] = data
        self._p_table_pet:AppendData(data)
    end

    self._p_bottom:SetActive(self.param.handle.maxSelectCount > 1 and self.petCount > 0)
    if self.param.handle.maxSelectCount > 1 then
        self._p_text_number.text = ("%s:%d/%d"):format(I18N.Get(CityPetI18N.UIHint_CanMultiSelect), self.param.handle:GetCurrentSelectCount(), self.param.handle.maxSelectCount)
        self.param.handle:SetSelectedChange(Delegate.GetOrCreate(self, self.OnMultiSelectChange))
    else
        self.param.handle:SetSelectedChange(Delegate.GetOrCreate(self, self.OnSingleSelectChange))
    end

    self._p_text_null:SetVisible(self.petCount == 0)
    self:UpdateExtraHint()

    g_Game.ServiceManager:AddResponseCallback(CastleAddPetParameter.GetMsgId(), Delegate.GetOrCreate(self, self.CloseSelf))
    g_Game.ServiceManager:AddResponseCallback(PetModifyNameParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetChangeName))
end

function CityPetAssignmentUIMediator:OnClose(param)
    g_Game.ServiceManager:RemoveResponseCallback(CastleAddPetParameter.GetMsgId(), Delegate.GetOrCreate(self, self.CloseSelf))
    g_Game.ServiceManager:RemoveResponseCallback(PetModifyNameParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnPetChangeName))
    if self.param then
        self.param.handle:SetSelectedChange(nil)
        self.param:OnMediatorClosed(self)
    end
end

function CityPetAssignmentUIMediator:OnMultiSelectChange(...)
    self._p_text_number.text = ("%s:%d/%d"):format(I18N.Get(CityPetI18N.UIHint_CanMultiSelect), self.param.handle:GetCurrentSelectCount(), self.param.handle.maxSelectCount)
    self.param:OnMultiSelectChange(...)
end

function CityPetAssignmentUIMediator:OnSingleSelectChange(...)
    if not self.param:IsDirty() then
        if self.param:CloseAfterAssign() then
            self:CloseSelf()
        end
        return
    end

    if self.param:RequestAssign(self.param.handle.selectedPetsId, Delegate.GetOrCreate(self, self.OnAsyncRequestAssign)) then
        if self.param:CloseAfterAssign() then
            self:CloseSelf()
        else
            local changeIds = {...}
            for _, v in ipairs(changeIds) do
                if self._dataMap[v] then
                    self._p_table_pet:UpdateChild(self._dataMap[v])
                end
            end
        end
    end
end

function CityPetAssignmentUIMediator:OnAsyncRequestAssign(flag)
    if flag and self.param:CloseAfterAssign() then
        self:CloseSelf()
    else
        self._p_table_pet:UpdateOnlyAllDataImmediately()
        self._p_text_number.text = ("%s:%d/%d"):format(I18N.Get(CityPetI18N.UIHint_CanMultiSelect), self.param.handle:GetCurrentSelectCount(), self.param.handle.maxSelectCount)
    end
end

function CityPetAssignmentUIMediator:OnTwiceConfirmCancel()
    self._p_table_pet:UpdateOnlyAllDataImmediately()
end

function CityPetAssignmentUIMediator:OnClick()
    if not self.param:IsDirty() then
        if self.param:CloseAfterAssign() then
            self:CloseSelf()
        end
        return
    end

    if self.param:RequestAssign(self.param.handle.selectedPetsId, Delegate.GetOrCreate(self, self.OnAsyncRequestAssign)) then
        if self.param:CloseAfterAssign() then
            self:CloseSelf()
        else
            self._p_table_pet:UpdateOnlyAllDataImmediately()
        end
    end
end

function CityPetAssignmentUIMediator:UpdateExtraHint()
    local needShowExtraHint = self.param:NeedShowExtraHint()
    self._group_hint:SetActive(needShowExtraHint)
    if needShowExtraHint then
        self._ui_emoji_text.text = self.param:GetExtraHintText(self._ui_emoji_text.fontSize)
    end
end

---@param reply wrpc.PetModifyNameReply
---@param rpc rpc.PetModifyName
function CityPetAssignmentUIMediator:OnPetChangeName(isSuccess, reply, rpc)
    if not isSuccess then return end
    if not self._p_table_pet then return end
    if not self._dataMap then return end

    local request = rpc.request
    local petId = request.PetCompId
    if self._dataMap[petId] then
        self._p_table_pet:UpdateChild(self._dataMap[petId])
    end
end

return CityPetAssignmentUIMediator