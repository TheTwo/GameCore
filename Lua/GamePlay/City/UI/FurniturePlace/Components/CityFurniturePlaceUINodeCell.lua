local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local UIHelper = require("UIHelper")
local I18N = require("I18N")
local TimerUtility = require("TimerUtility")
local ShowTipInterval = 0.1
local CityFurniturePlaceI18N = require("CityFurniturePlaceI18N")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local ConfigRefer = require("ConfigRefer")
local CityFurnitureHelper = require("CityFurnitureHelper")
local NotificationType = require("NotificationType")
local UIHelper = require("UIHelper")
local UIMediatorNames = require("UIMediatorNames")
local CityProcessV2UIParameter = require("CityProcessV2UIParameter")
local CityProcessUtils = require("CityProcessUtils")
local CityWorkType = require("CityWorkType")

---@class CityFurniturePlaceUINodeCell:BaseTableViewProCell
local CityFurniturePlaceUINodeCell = class('CityFurniturePlaceUINodeCell', BaseTableViewProCell)

function CityFurniturePlaceUINodeCell:OnCreate()
    self.gameObject = self:GameObject("")
    self._p_btn_frame = self:Image("p_btn_frame")                               ----品质色
    self._p_icon_building_activated = self:Image("p_icon_building_activated")   ----家具图片

    self._p_lv = self:GameObject("p_lv")                                        ----家具等级根节点
    self._p_text_lv = self:Text("p_text_lv")                                    ----家具等级
    self._p_placed = self:GameObject("p_placed")                                ----已摆放标志
    self._p_text_placed = self:Text("p_text_placed")                           ----已摆放文本

    self._p_quantity = self:GameObject("p_quantity")                            ----库存根节点
    self._p_txt_quantity_building = self:Text("p_txt_quantity_building")        ----家具库存数量
    
    self._p_icon_recomment = self:GameObject("p_icon_recomment")                ----推荐标志

    self._child_img_select = self:GameObject("child_img_select")                ----选中特效
    self._p_txt_name = self:Text("p_txt_name")                                  ----家具名字

    self._p_btn = self:Button("p_btn")
    self:PointerClick("p_btn", Delegate.GetOrCreate(self, self.OnClick))
    self:DragEvent("p_btn", Delegate.GetOrCreate(self, self.BeginDrag), Delegate.GetOrCreate(self, self.Drag),
        Delegate.GetOrCreate(self, self.EndDrag), true, Delegate.GetOrCreate(self, self.OnSendToParent))
    self:PointerDown("p_btn", Delegate.GetOrCreate(self, self.OnPointerDown))
    self:PointerUp("p_btn", Delegate.GetOrCreate(self, self.OnPointerUp))

    ---@type NotificationNode
    self._child_reddot_default = self:LuaObject("child_reddot_default")

    self._p_layout_tag = self:Transform("p_layout_tag")                         ----Tag属性根节点
    self._p_icon_tag = self:Image("p_icon_tag")                                 ----Tag模板
    self._tag_pool = LuaReusedComponentPool.new(self._p_icon_tag, self._p_layout_tag)
end

---@param data CityFurniturePlaceUINodeDatum
function CityFurniturePlaceUINodeCell:OnFeedData(data)
    self.data = data
    self.uiMediator = self:GetParentBaseUIMediator()

    g_Game.SpriteManager:LoadSprite(data:GetQualityBackground(), self._p_btn_frame)
    g_Game.SpriteManager:LoadSprite(data:GetImage(), self._p_icon_building_activated)

    if self.data:IsPlaced() then
        self._p_icon_building_activated.color = ColorUtil.FromHex(0x838AABFF)
    else
        self._p_icon_building_activated.color = ColorUtil.FromHex(0xFFFFFFFF)
    end

    if self.data:IsStorage() then
        local dynamicNode = ModuleRefer.NotificationModule:GetDynamicNode(CityFurnitureHelper.GetPlaceUINodeNotifyName(self.data.lvCfg:Id()), NotificationType.CITY_FURNIURE_PLACE_UNIT)
        if dynamicNode then
            self._child_reddot_default:SetVisible(true)
            ModuleRefer.NotificationModule:AttachToGameObject(dynamicNode, self._child_reddot_default.go)
        else
            ModuleRefer.NotificationModule:RemoveFromGameObject(self._child_reddot_default.go, false)
            self._child_reddot_default:SetVisible(false)
        end
    else
        ModuleRefer.NotificationModule:RemoveFromGameObject(self._child_reddot_default.go, false)
        self._child_reddot_default:SetVisible(false)
    end

    self._p_lv:SetActive(data.showLevel)
    if data.showLevel then
        self._p_text_lv.text = ("Lv.<b>%d</b>"):format(self.data:GetLevel())
    end

    self._p_quantity:SetActive(self.data.showStorageNumber)
    if self.data.showStorageNumber then
        self._p_txt_quantity_building.text = self.data:GetStorageText()
    end

    self._p_placed:SetActive(self.data:IsPlaced())
    if self.data:IsPlaced() then
        self._p_text_placed.text = self.data:GetPlacedText()
    end

    self.sendToParent = false

    if self.data.triggerGuide then
        self.data:ClearTriggerGuideFinger()
        self:OnPingFinger(self.data)
    end

    self._p_txt_name:SetVisible(self.data.showName)
    if self.data.showName then
        self._p_txt_name.text = self.data:GetName()
    end

    self._tag_pool:HideAll()
    -- if self.data.showTag then
    --     local list = self.data:GetBuffTagList()
    --     for i, v in ipairs(list) do
    --         local tagCfg = ConfigRefer.RoomTag:Find(v)
    --         if not tagCfg:HideInConstructionUI() then
    --             local image = self._tag_pool:GetItem()
    --             g_Game.SpriteManager:LoadSprite(tagCfg:Icon(), image)
    --         end
    --     end
    -- end

    self._child_img_select:SetActive(self.uiMediator.selected == self.data)
    self._p_icon_recomment:SetActive(self.data.isRecommend == true)
    UIHelper.SetGray(self.gameObject, self.data:IsEmpty())

    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_CELL_GUIDE_FINGER, Delegate.GetOrCreate(self, self.OnPingFinger))
    g_Game.EventManager:AddListener(EventConst.UI_FURNITURE_PLACE_SELECT, Delegate.GetOrCreate(self, self.OnSelected))
    g_Game.EventManager:AddListener(EventConst.UI_CITY_PLACE_FURNITURE_UPDATE_NOFIFICATION, Delegate.GetOrCreate(self, self.OnNotificationUpdate))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function CityFurniturePlaceUINodeCell:OnRecycle()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_CELL_GUIDE_FINGER, Delegate.GetOrCreate(self, self.OnPingFinger))
    g_Game.EventManager:RemoveListener(EventConst.UI_FURNITURE_PLACE_SELECT, Delegate.GetOrCreate(self, self.OnSelected))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_PLACE_FURNITURE_UPDATE_NOFIFICATION, Delegate.GetOrCreate(self, self.OnNotificationUpdate))
end

function CityFurniturePlaceUINodeCell:OnClose()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_CELL_GUIDE_FINGER, Delegate.GetOrCreate(self, self.OnPingFinger))
    g_Game.EventManager:RemoveListener(EventConst.UI_FURNITURE_PLACE_SELECT, Delegate.GetOrCreate(self, self.OnSelected))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_PLACE_FURNITURE_UPDATE_NOFIFICATION, Delegate.GetOrCreate(self, self.OnNotificationUpdate))
end

function CityFurniturePlaceUINodeCell:OnClick()
    if self.sendToParent then return end

    if self.data:IsEmpty() then
        local city = self.data.city
        local targetFurniture = city.furnitureManager:GetFurnitureByTypeCfgId(1003401)
        local tile = nil
        local typCfgId = self.data.typCfg:Id()
        if targetFurniture ~= nil then
            tile = city.gridView:GetFurnitureTile(targetFurniture.x, targetFurniture.y)
        end

        g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_EXIT_EDIT_MODE)
        if tile then
            local workCfgId = targetFurniture:GetWorkCfgId(CityWorkType.Process)
            local recipeId = CityProcessUtils.GetRecipeIdFromFurnitureTypeCfgId(workCfgId, typCfgId)
            local param = CityProcessV2UIParameter.new(tile, recipeId)
            g_Game.UIManager:Open(UIMediatorNames.CityProcessV2UIMediator, param)
        end

        if UNITY_EDITOR then
            -- g_Logger.Error("[%d]:Lv.%d, ItemId:%d", self.data.typCfg:Id(), self.data.lvCfg:Level(), self.data.lvCfg:RelItem())
        end
        return
    end

    if self.data:IsStorage() then
        if self.data:IsFull() then
            return ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_furniture_quantity_limit", self.data:GetFurnitureName()))
        end
        if not self.dragChecking then
            self.data.city.furnitureManager:ClearSingleFurnitureNotifyData(self.data.lvCfg:Id())
            g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_PLACE_FURNITURE_UPDATE_NOFIFICATION, self.data.lvCfg:Id())
            g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_SELECTION, self.data:CreateCityStateData())
        end
    end

    if self.data:IsPlaced() and self.data.furniture ~= nil then
        local worldPos = self.data.furniture:CenterPos()
        local camera = self.data.city:GetCamera()
        if camera ~= nil then
            camera:LookAt(worldPos, 0.5)
        end
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityFurniturePlaceUINodeCell:BeginDrag(go, eventData)
    self.dragChecking = true
    self.pointerDown = false
    self:HideTips()

    if self.data:IsEmpty() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("crafting_toast_insufficient"))
        return
    end

    if self.data:IsStorage() then
        if self.data:IsFull() then
            return ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_furniture_quantity_limit", self.data:GetFurnitureName()))
        end
    end

    if self.data:IsPlaced() then
        g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_PLACE_CLICK_PLACED, self.data.furniture)
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityFurniturePlaceUINodeCell:Drag(go, eventData)
    if self.data:IsStorage() and not self.data:IsFull() then
        if self.dragChecking then
            local result = eventData.pointerCurrentRaycast.gameObject
            local isInGuide = ModuleRefer.GuideModule:GetGuideState()
            if result == nil or isInGuide then
                if not string.IsNullOrEmpty(self.data:GetPrefabName()) then
                    self.dragChecking = false
                    self.data.city.furnitureManager:ClearSingleFurnitureNotifyData(self.data.lvCfg:Id())
                    g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_PLACE_FURNITURE_UPDATE_NOFIFICATION, self.data.lvCfg:Id())
                    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_SELECTION, self.data:CreateCityStateData(), eventData.position)
                end
            end
        else
            g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_PREVIEW_POS, eventData.position)
        end
    elseif self.data:IsPlaced() then
        if self.dragChecking then
            local result = eventData.pointerCurrentRaycast.gameObject
            local isInGuide = ModuleRefer.GuideModule:GetGuideState()
            if result == nil or isInGuide then
                self.dragChecking = false
                g_Game.EventManager:TriggerEvent(EventConst.CITY_MOVING_SELECTION, self.data.furniture, eventData.position)
            end
        else
            g_Game.EventManager:TriggerEvent(EventConst.CITY_MOVING_PREVIEW_POS, eventData.position)
        end
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityFurniturePlaceUINodeCell:EndDrag(go, eventData)
    self.dragChecking = false
    if self.data:IsStorage() and not self.data:IsFull() then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_UICELL_DRAG_RELEASE)
    elseif self.data:IsPlaced() then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_MOVING_UITILE_DRAG_RELEASE)
    end
end

function CityFurniturePlaceUINodeCell:OnPingFinger(data)
    if self.data ~= data then return end

    TimerUtility.DelayExecuteInFrame(function()
        local rectTrans = self._p_btn.transform
        --require('GuideFingerUtil').ShowGuideFinger(rectTrans)
    end)
end

function CityFurniturePlaceUINodeCell:OnPointerDown()
    self.pointerDown = true
    self.downTime = 0
    if self.data then
        g_Game.EventManager:TriggerEvent(EventConst.UI_FURNITURE_PLACE_SELECT, self.data)
    end
end

function CityFurniturePlaceUINodeCell:OnPointerUp()
    self.pointerDown = false
    self:HideTips()
end

function CityFurniturePlaceUINodeCell:OnSendToParent(flag)
    self.sendToParent = flag
    if flag then
        self:OnPointerUp()
    end
end

function CityFurniturePlaceUINodeCell:OnTick(deltaTime)
    if not self.pointerDown then
        return
    end

    local lastTime = self.downTime
    self.downTime = self.downTime + deltaTime
    if self.downTime > ShowTipInterval and lastTime <= ShowTipInterval then
        local anchorMax = self._p_btn.transform.rect.max
        local anchorMin = self._p_btn.transform.rect.min
        local top = CS.UnityEngine.Vector3((anchorMax.x + anchorMin.x) / 2, anchorMax.y, 0)
        local topWorld = self._p_btn.transform:TransformPoint(top)
        self:ShowTipsAt(topWorld)
    end
end

function CityFurniturePlaceUINodeCell:ShowTipsAt(worldPos)

end

function CityFurniturePlaceUINodeCell:HideTips()

end

function CityFurniturePlaceUINodeCell:OnSelected(data)
    if self.data == nil then return end

    self._child_img_select:SetActive(self.data == data)
end

function CityFurniturePlaceUINodeCell:OnNotificationUpdate(lvCfgId)
    if not self.data then return end
    if self.data.lvCfg:Id() ~= lvCfgId then return end

    if self.data:IsStorage() then
        local dynamicNode = ModuleRefer.NotificationModule:GetDynamicNode(CityFurnitureHelper.GetPlaceUINodeNotifyName(self.data.lvCfg:Id()), NotificationType.CITY_FURNIURE_PLACE_UNIT)
        if dynamicNode then
            self._child_reddot_default:SetVisible(true)
            ModuleRefer.NotificationModule:AttachToGameObject(dynamicNode, self._child_reddot_default.go)
        else
            ModuleRefer.NotificationModule:RemoveFromGameObject(self._child_reddot_default.go, false)
            self._child_reddot_default:SetVisible(false)
        end
    else
        ModuleRefer.NotificationModule:RemoveFromGameObject(self._child_reddot_default.go, false)
        self._child_reddot_default:SetVisible(false)
    end
end

return CityFurniturePlaceUINodeCell