---Scene Name : scene_city_popup_collect
local CityCommonRightPopupUIMediator = require ('CityCommonRightPopupUIMediator')
local CItyCollectV2I18N = require('CItyCollectV2I18N')
local I18N = require('I18N')
local Delegate = require('Delegate')
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local EventConst = require("EventConst")

---@class CityCollectV2UIMediator:CityCommonRightPopupUIMediator
local CityCollectV2UIMediator = class('CityCollectV2UIMediator', CityCommonRightPopupUIMediator)

function CityCollectV2UIMediator:OnCreate()
    self._p_btn_close = self:Button("p_btn_close", Delegate.GetOrCreate(self, self.CloseSelf))
    self._p_focus_target = self:Transform("p_focus_target")
    self._btn_exit = self:Button("btn_exit", Delegate.GetOrCreate(self, self.CloseSelf))

    ---右侧面板
    self._p_group_right = self:StatusRecordParent("p_group_right")
    ---工作名
    self._p_text_property_name = self:Text("p_text_property_name")
    ---所需feature
    self._p_btn_type = self:Button("p_btn_type", Delegate.GetOrCreate(self, self.OnClickFeature))
    self._p_text_type = self:Text("p_text_type", CItyCollectV2I18N.UIHint_NeedFeature)
    self._p_icon_type = self:Image("p_icon_type")
    self._pool_feature = LuaReusedComponentPool.new(self._p_icon_type, self._p_btn_type.transform)

    ---产物图标
    self._p_icon = self:Image("p_icon")
    ---生产简述
    self._p_text_status = self:Text("p_text_status")
    ---囤积量
    self._p_text_item_number = self:Text("p_text_item_number")
    ---单次进度
    self._p_progress = self:Image("p_progress")
    ---属性table
    self._p_table_content = self:TableViewPro("p_table_content")
    ---异常状态提示字
    self._p_text_hint = self:Text("p_text_hint")

    self._btn_b = self:GameObject("btn_b")
    ---@type BistateButton
    self._child_comp_btn_b = self:LuaObject("child_comp_btn_b")
    ---@type PetAssignComponent
    self._p_pet_list = self:LuaObject("p_pet_list")
end

---@param param CityCollectV2UIParameter
function CityCollectV2UIMediator:OnOpened(param)
    self.param = param
    self.param:OnUIMediatorOpened(self)
    self.city = param.city

    local petAssignData = self.param:GetPetAssignData()
    if petAssignData.slotCount == 0 then
        local furnitureId = self.param.cellTile:GetCell().singleId
        g_Logger.ErrorChannel("属性异常", "furnitureId:%d", furnitureId)
        local castle = self.city:GetCastle()
        local castleAttrMap = castle.CastleAttribute
        local furnitureAttrMap = castleAttrMap.FurnitureAttr[furnitureId]
        if not furnitureAttrMap then
            g_Logger.ErrorChannel("属性异常", "furnitureAttrMap is nil")
        else
            g_Logger.ErrorChannel("属性异常", FormatTable(furnitureAttrMap))
        end

        -- g_Game.ModuleManager:RemoveModule("CastleAttrModule")
        -- g_Game.ModuleManager:RetrieveModule("CastleAttrModule")
    end

    local petAssignData = self.param:GetPetAssignData()
    if petAssignData.slotCount == 0 then
        g_Logger.ErrorChannel("属性异常", "重载CastleAttrModule之后, petAssignData.slotCount == 0")
    end

    self._p_pet_list:FeedData(petAssignData)
    self._p_text_property_name.text = self.param:GetWorkName()
    local features = self.param:NeedFeatureList()
    if features and #features > 0 then
        self._p_btn_type:SetVisible(true)
        self._pool_feature:HideAll()
        for i, feature in ipairs(features) do
            local image = self._pool_feature:GetItem()
            local icon = self.city.petManager:GetFeatureIcon(feature)
            g_Game.SpriteManager:LoadSprite(icon, image)
        end
    else
        self._p_btn_type:SetVisible(false)
    end

    g_Game.SpriteManager:LoadSprite(self.param:GetOutputIcon(), self._p_icon)
    self:UpdateWorkStatDesc()
    self:UpdateOutputCount()
    self:UpdateSingleOutputProgress()
    self:UpdatePropertyTable()
    self:UpdateHintText()
    self._child_comp_btn_b:FeedData(self:GetBistateButtonData())
    self._child_comp_btn_b:SetEnabled(self:ButtonEnabled())
    CityCommonRightPopupUIMediator.OnOpened(self, param)
    self:AddEventListeners()
end

function CityCollectV2UIMediator:OnClose(param)
    self:RemoveEventListeners()
    CityCommonRightPopupUIMediator.OnClose(self, param)
    if self.param then
        self.param:OnUIMediatorClosed(self)
    end
end

function CityCollectV2UIMediator:AddEventListeners()
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_PET_UPDATE, Delegate.GetOrCreate(self, self.OnPetUpdate))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    self.evtAdded = true
end

function CityCollectV2UIMediator:RemoveEventListeners()
    if not self.evtAdded then return end
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureUpdate))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_PET_UPDATE, Delegate.GetOrCreate(self, self.OnPetUpdate))
    self.evtAdded = false
end

function CityCollectV2UIMediator:UpdateWorkStatDesc()
    self._p_text_status.text = self.param:GetWorkStatDesc()
end

function CityCollectV2UIMediator:UpdateOutputCount()
    if self.param:IsUndergoing() then
        self._p_text_item_number.text = ("x%d"):format(self.param:GetOutputNumber())
    else
        self._p_text_item_number.text = ""
    end
end

function CityCollectV2UIMediator:UpdateSingleOutputProgress()
    self._p_progress.fillAmount = self.param:GetSingleOutputProgress()
end

function CityCollectV2UIMediator:UpdatePropertyTable()
    self._p_table_content:Clear()
    for _, v in ipairs(self.param:GetProperties()) do
        self._p_table_content:AppendData(v)
    end
end

function CityCollectV2UIMediator:UpdateHintText()
    local hint = self.param:GetHintText()
    if string.IsNullOrEmpty(hint) then
        self._p_text_hint:SetVisible(false)
    else
        self._p_text_hint:SetVisible(true)
        self._p_text_hint.text = hint
    end
end

---@return BistateButtonParameter
function CityCollectV2UIMediator:GetBistateButtonData()
    local undergoing = self.param:IsUndergoing()
    local data = {
        buttonText = undergoing and I18N.Get(CItyCollectV2I18N.UIButton_Claim) or I18N.Get(CItyCollectV2I18N.UIButton_Assign),
        onClick = undergoing and Delegate.GetOrCreate(self, self.OnClickClaim) or Delegate.GetOrCreate(self, self.OnClickAssign),
        disableButtonText = undergoing and I18N.Get(CItyCollectV2I18N.UIButton_Claim) or I18N.Get(CItyCollectV2I18N.UIButton_Assign),
        disableClick = undergoing and Delegate.GetOrCreate(self, self.OnClickClaim) or Delegate.GetOrCreate(self, self.OnClickAssign),
    }
    return data
end

function CityCollectV2UIMediator:ButtonEnabled()
    if self.param:IsUndergoing() then
        return self.param:GetOutputNumber() > 0
    end
    return true
end

function CityCollectV2UIMediator:OnClickClaim(clickData, rectTransform)
    if self.param:GetOutputNumber() > 0 then
        self.param:RequestClaim(rectTransform)
    end
end

function CityCollectV2UIMediator:OnClickAssign(clickData, rectTransform)
    self.param:OpenAssignPopupUI(rectTransform)
end

function CityCollectV2UIMediator:GetFocusAnchor()
    return self._p_focus_target
end

function CityCollectV2UIMediator:GetWorldTargetPos()
    return self.param:GetWorldTargetPos()
end

function CityCollectV2UIMediator:GetBasicCamera()
    return self.param:GetBasicCamera()
end

function CityCollectV2UIMediator:GetZoomSize()
    return self.param:GetZoomSize()
end

function CityCollectV2UIMediator:OnFurnitureUpdate(city, batchEvt)
    if city ~= self.city then return end
    if not batchEvt.Change then return end
    if not batchEvt.Change[self.param.cellTile:GetCell().singleId] then return end

    self:UpdateWorkStatDesc()
    self:UpdateOutputCount()
    self:UpdateSingleOutputProgress()
    self:UpdatePropertyTable()
    self:UpdateHintText()
    self._child_comp_btn_b:SetEnabled(self:ButtonEnabled())
end

function CityCollectV2UIMediator:OnPetUpdate(city, batchEvt)
    if city ~= self.city then return end
    if not batchEvt.RelativeFurniture then return end
    if not batchEvt.RelativeFurniture[self.param.cellTile:GetCell().singleId] then return end

    self:UpdateWorkStatDesc()
    self._p_pet_list:FeedData(self.param:GetPetAssignData())
    self._child_comp_btn_b:FeedData(self:GetBistateButtonData())
    self._child_comp_btn_b:SetEnabled(self:ButtonEnabled())
end

function CityCollectV2UIMediator:OnTick(delta)
    self:UpdateSingleOutputProgress()
end

return CityCollectV2UIMediator