---@class CityConstructionUICellDataBuilding
---@field new fun():CityConstructionUICellDataBuilding
---@field typCell BuildingTypesConfigCell
---@field lvCell BuildingLevelConfigCell|nil
---@field state number
---@field stockCount number
---@field stockFold CityConstructionUICellDataBuilding[]|nil
---@field itemGroup ItemGroupConfigCell|nil
---@field tileId number
local CityConstructionUICellDataBuilding = class("CityConstructionUICellDataBuilding")
local CityConstructState = require("CityConstructState")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityGridCellDef = require("CityGridCellDef")
local CastleBuildingAddParameter = require("CastleBuildingAddParameter")
local CastleBuildingAddFromStorageParameter = require("CastleBuildingAddFromStorageParameter")
local ArtResourceUtils = require("ArtResourceUtils")
local I18N = require("I18N")
local NotificationType = require('NotificationType')
local Delegate = require('Delegate')
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")
local TimerUtility = require("TimerUtility")
local Utils = require("Utils")
local ShowTipInterval = 0.1

---@param uiCell CityConstructionModeUICell
function CityConstructionUICellDataBuilding:OnFeedData(uiCell)
    self.uiCell = uiCell
    local state = self:GetState()
    local canBuild = state == CityConstructState.CanBuild
    local lackMaterial = state == CityConstructState.LackOfResource
    local isFull = state == CityConstructState.IsFull
    local conditionNotMeet = state == CityConstructState.ConditionNotMeet
    local notOwn = state == CityConstructState.NotOwn
    uiCell.canBuild = canBuild

    --- 家具冲突
    uiCell._p_icon_ban:SetActive(false)

    --- 未知状态
    local IsUnactivated = self:IsUnactivated()
    uiCell._p_case_unactivated:SetActive(IsUnactivated)
    uiCell._p_case_activated:SetActive(not IsUnactivated)

    --- 等级
    local level = self:GetLevel()
    uiCell._p_lv.gameObject:SetActive(level > 0)
    if level > 0 then
        uiCell._p_text_lv.text = tostring(level)
    end

    --- 是否是折叠库存
    uiCell.isStockFold = self:GetStockKind() > 1
    uiCell._p_base_save:SetActive(uiCell.isStockFold)
    uiCell._p_detail.gameObject:SetActive(uiCell.isStockFold)

    --- 是否显示数量
    local QuantityHide = (state == CityConstructState.ConditionNotMeet) or (state == CityConstructState.UnknownBuilding) or isFull
    uiCell._p_quantity_building:SetActive(not QuantityHide)
    if not QuantityHide then
        local QuantityStr = string.format("%s%d/%d", I18N.Get("crafting_furniture_putup"), self:Existed(), self:LimitCount())
        if state == CityConstructState.IsFull then
            QuantityStr = ("<color=red>%s</color>"):format(QuantityStr)
        end
        uiCell._p_txt_quantity_building.text = QuantityStr
    end

    --- 名字
    uiCell._p_txt_name.text = self:GetName()

    --- 图片
    g_Game.SpriteManager:LoadSprite(self:GetImage(), uiCell._p_icon_building_activated)

    --- 库存
    local stock = self:GetStock()
    local showStock = stock > 0 or notOwn
    uiCell._p_save.gameObject:SetActive(showStock)
    uiCell._p_txt_quantity_save.text = tostring(stock)

    --- 展示材料显示
    local materialShow = (canBuild or lackMaterial) and stock == 0
    uiCell._p_material:SetActive(materialShow)
    if materialShow then
        local matType = self:GetMaterialTypeAmount()
        uiCell._p_item_material_1:SetActive(matType >= 1)
        uiCell._p_item_material_2:SetActive(matType >= 2)
        uiCell._p_item_material_3:SetActive(matType >= 3)

        if matType >= 1 then
            local mat = self:GetMaterial(1)
            local need = self:GetMaterialNeed(1)
            g_Game.SpriteManager:LoadSprite(mat:Icon(), uiCell._p_icon_material_1)
            local have = ModuleRefer.InventoryModule:GetAmountByConfigId(mat:Id())

            uiCell._p_txt_quantity_n_1.gameObject:SetActive(have >= need)
            uiCell._p_txt_quantity_red_1.gameObject:SetActive(have < need)

            if have >= need then
                uiCell._p_txt_quantity_n_1.text = tostring(need)
            else
                uiCell._p_txt_quantity_red_1.text = tostring(need)
            end
        end

        if matType >= 2 then
            local mat = self:GetMaterial(2)
            local need = self:GetMaterialNeed(2)
            g_Game.SpriteManager:LoadSprite(mat:Icon(), uiCell._p_icon_material_2)
            local have = ModuleRefer.InventoryModule:GetAmountByConfigId(mat:Id())

            uiCell._p_txt_quantity_n_2.gameObject:SetActive(have >= need)
            uiCell._p_txt_quantity_red_2.gameObject:SetActive(have < need)

            if have >= need then
                uiCell._p_txt_quantity_n_2.text = tostring(need)
            else
                uiCell._p_txt_quantity_red_2.text = tostring(need)
            end
        end

        if matType >= 3 then
            local mat = self:GetMaterial(3)
            local need = self:GetMaterialNeed(3)
            g_Game.SpriteManager:LoadSprite(mat:Icon(), uiCell._p_icon_material_3)
            local have = ModuleRefer.InventoryModule:GetAmountByConfigId(mat:Id())

            uiCell._p_txt_quantity_n_3.gameObject:SetActive(have >= need)
            uiCell._p_txt_quantity_red_3.gameObject:SetActive(have < need)

            if have >= need then
                uiCell._p_txt_quantity_n_3.text = tostring(need)
            else
                uiCell._p_txt_quantity_red_3.text = tostring(need)
            end
        end
    end

    --- 不能建造的提示信息
    uiCell._p_txt_hint.gameObject:SetActive(IsUnactivated or conditionNotMeet or isFull)
    if IsUnactivated then
        uiCell._p_txt_hint.text = self:GetShowConditionDesc()
    elseif conditionNotMeet then
        uiCell._p_txt_hint.text = self:GetUnlockConditionDesc()
    elseif isFull then
        uiCell._p_txt_hint.text = I18N.Get("build_limit");
    end

    --- 占地
    uiCell._p_area:SetActive(true)
    uiCell._p_txt_quantity_area.text = ("%dx%d"):format(self.lvCell:SizeX(), self.lvCell:SizeY())

    uiCell.child_reddot_default.go:SetActive(true)
    local node = ModuleRefer.NotificationModule:GetDynamicNode("CityConstruction_BuildingType_"..self.typCell:Id(), NotificationType.CITY_CONSTRUCTION_BUILDING)
    if node then
        ModuleRefer.NotificationModule:AttachToGameObject(node, uiCell.child_reddot_default.go, uiCell.child_reddot_default.redNew)
        ModuleRefer.CityConstructionModule:ClearBuildingIsNew(self.typCell)
    end

    if self.ping then
        self.ping = nil
        self:OnPingFinger(self)
    end

    UIHelper.SetGray(uiCell._p_btn_click.gameObject, not IsUnactivated and (isFull or conditionNotMeet or notOwn))

    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_CELL_GUIDE_FINGER, Delegate.GetOrCreate(self, self.OnPingFinger))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))

    local matType = self:GetMaterialTypeAmount()
    for i = 1, matType do
        ModuleRefer.InventoryModule:AddCountChangeListener(self:GetMaterial(i):Id(), Delegate.GetOrCreate(self, self.OnMatCountChange))
    end
end

function CityConstructionUICellDataBuilding:OnRecycle()
    local matType = self:GetMaterialTypeAmount()
    for i = 1, matType do
        ModuleRefer.InventoryModule:RemoveCountChangeListener(self:GetMaterial(i):Id(), Delegate.GetOrCreate(self, self.OnMatCountChange))
    end
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_CELL_GUIDE_FINGER, Delegate.GetOrCreate(self, self.OnPingFinger))
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    self.uiCell = nil
end

---@param uiCell CityConstructionModeUICell
function CityConstructionUICellDataBuilding:OnClick(uiCell)
    local state = self:GetState()
    if state ~= CityConstructState.CanBuild then
        if state == CityConstructState.NotOwn then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_need_more_furniture", self:GetName()))
        elseif state == CityConstructState.IsFull then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_furniture_quantity_limit", self:GetName()))
        elseif state == CityConstructState.LackOfResource then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("crafting_toast_insufficient"))
        end
        return
    end

    if uiCell.isStockFold then
        if uiCell.dragChecking then
            uiCell.dragChecking = false
        else
            self:OnClickDetails(uiCell)
        end
    else
        if uiCell.canBuild and not uiCell.dragChecking then
            if not string.IsNullOrEmpty(self:PrefabName()) then
                g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_SELECTION, self)
            else
                g_Logger.Error("模型配置为空, 请检查配置")
            end
        end
    end
end

---@param uiCell CityConstructionModeUICell
function CityConstructionUICellDataBuilding:OnClickDetails(uiCell)
    uiCell:GetParentBaseUIMediator():ListStockView(self)
end

function CityConstructionUICellDataBuilding:OnPingFinger(data)
    if data ~= self then return end

    TimerUtility.DelayExecuteInFrame(function()
        local rectTrans = self.uiCell._p_btn_click.transform
        --require('GuideFingerUtil').ShowGuideFinger(rectTrans)
    end)
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionUICellDataBuilding:BeginDrag(uiCell, go, eventData)
    uiCell.dragChecking = true
    self.pointerDown = false
    self:HideTips()

    local state = self:GetState()
    if state ~= CityConstructState.CanBuild then
        if state == CityConstructState.NotOwn then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_need_more_furniture", self:GetName()))
        elseif state == CityConstructState.IsFull then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_furniture_quantity_limit", self:GetName()))
        elseif state == CityConstructState.LackOfResource then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("crafting_toast_insufficient"))
        end
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionUICellDataBuilding:Drag(uiCell, go, eventData)
    if uiCell.isStockFold then
        return
    end

    if uiCell.canBuild then
        if uiCell.dragChecking then
            local result = eventData.pointerCurrentRaycast.gameObject
            local isInGuide = ModuleRefer.GuideModule:GetGuideState()
            if result == nil or isInGuide then
                if not string.IsNullOrEmpty(self:PrefabName()) then
                    uiCell.dragChecking = false
                    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_SELECTION, self, eventData.position)
                end
            end
        else
            g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_PREVIEW_POS, eventData.position)
        end
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionUICellDataBuilding:EndDrag(uiCell, go, eventData)
    if uiCell.isStockFold then
        return
    end

    uiCell.dragChecking = false
    if uiCell.canBuild then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_UICELL_DRAG_RELEASE)
    end
end

---@return boolean
function CityConstructionUICellDataBuilding:IsUnactivated()
    return self.state == CityConstructState.UnknownBuilding
end

---@return number
function CityConstructionUICellDataBuilding:GetState()
    return self.state
end

---@return string
function CityConstructionUICellDataBuilding:GetName()
    return I18N.Get(self.typCell:Name())
end

---@return number
function CityConstructionUICellDataBuilding:GetLevel()
    if self.lvCell then
        return self.lvCell:Level()
    end
    return 0
end

---@return string
function CityConstructionUICellDataBuilding:GetImage()
    return self.typCell:Image()
end

---@return boolean
function CityConstructionUICellDataBuilding:IsLimit()
    return self.typCell:MaxNum() > 0
end

---@return number
function CityConstructionUICellDataBuilding:Existed()
    local infos = ModuleRefer.CityConstructionModule:GetAllBuildingInfosByType(self.typCell:Id())
    return infos and #infos or 0
end

---@return number
function CityConstructionUICellDataBuilding:LimitCount()
    return ModuleRefer.CityConstructionModule:GetPlaceBuildingTypeNumLimit(self.typCell:Id())
end

---@return number
function CityConstructionUICellDataBuilding:GetStock()
    return self.stockCount
end

---@return number
function CityConstructionUICellDataBuilding:GetStockKind()
    if self.stockFold then
        return #self.stockFold
    end
    return 0
end

---@return number
function CityConstructionUICellDataBuilding:GetMaterialTypeAmount()
    if self.itemGroup then
        return self.itemGroup:ItemGroupInfoListLength()
    else
        return 0
    end
end

---@return ItemConfigCell
function CityConstructionUICellDataBuilding:GetMaterial(index)
    local info = self.itemGroup:ItemGroupInfoList(index)
    return ConfigRefer.Item:Find(info:Items())
end

---@return number
function CityConstructionUICellDataBuilding:GetMaterialNeed(index)
    local info = self.itemGroup:ItemGroupInfoList(index)
    return info:Nums()
end

function CityConstructionUICellDataBuilding:GetShowConditionDesc()
    return ModuleRefer.CityConstructionModule:GetShowConditionDesc(self.typCell)
end

function CityConstructionUICellDataBuilding:GetUnlockConditionDesc()
    return ModuleRefer.CityConstructionModule:GetUnlockConditionDesc(self.typCell)
end

function CityConstructionUICellDataBuilding:SizeX()
    return self.lvCell:SizeX()
end

function CityConstructionUICellDataBuilding:SizeY()
    return self.lvCell:SizeY()
end

function CityConstructionUICellDataBuilding:PrefabName()
    local model = ArtResourceUtils.GetItem(self.lvCell:ModelArtRes())
    if model then
        return model
    end
    return string.Empty
end

function CityConstructionUICellDataBuilding:Scale()
    local scale = ArtResourceUtils.GetItem(self.lvCell:ModelArtRes(), 'ModelScale')
    if scale then
        return scale
    end
    return 1
end

function CityConstructionUICellDataBuilding:ConfigId()
    if self.lvCell then
        return self.lvCell:Id()
    end
    return 0
end

function CityConstructionUICellDataBuilding:RequestToBuild(x, y)
    if self.tileId then
        local msg = CastleBuildingAddFromStorageParameter.new()
        msg.args.StorageBuildingId = self.tileId
        msg.args.Pos = wds.Point2.New(x, y)
        msg:SendWithFullScreenLock()
    else
        local msg = CastleBuildingAddParameter.new()
        msg.args.BuildingType = self.typCell:Id()
        msg.args.Pos = wds.Point2.New(x, y)
        msg:SendWithFullScreenLock()
    end
end

function CityConstructionUICellDataBuilding:IsFurniture()
    return false
end

function CityConstructionUICellDataBuilding:TypeId()
    return self.typCell:Id()
end

function CityConstructionUICellDataBuilding:OnTick(deltaTime)
    if not self.pointerDown then
        return
    end

    local lastTime = self.downTime
    self.downTime = self.downTime + deltaTime
    if self.downTime > ShowTipInterval and lastTime <= ShowTipInterval then
        local anchorMax = self.uiCell.transform.rect.max
        local anchorMin = self.uiCell.transform.rect.min
        local top = CS.UnityEngine.Vector3((anchorMax.x + anchorMin.x) / 2, anchorMax.y, 0)
        local topWorld = self.uiCell.transform:TransformPoint(top)
        self:ShowTipsAt(topWorld, self.lvCell)
    end
end

function CityConstructionUICellDataBuilding:OnMatCountChange()
    if Utils.IsNotNull(self.uiCell.CSComponent) then
        self:OnFeedData(self.uiCell)
    end
end

function CityConstructionUICellDataBuilding:OnPointerDown(uiCell)
    self.pointerDown = true
    self.downTime = 0
end

function CityConstructionUICellDataBuilding:OnPointerUp(uiCell)
    self.pointerDown = false
    self:HideTips()
end

---@param lvCell BuildingLevelConfigCell
function CityConstructionUICellDataBuilding:ShowTipsAt(worldPos, lvCell)
    local attrGroup = ConfigRefer.AttrGroup:Find(lvCell:Attr())
    if attrGroup == nil then return end

    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW_TIPS, worldPos, attrGroup)
end

function CityConstructionUICellDataBuilding:HideTips()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_HIDE_TIPS)
end

function CityConstructionUICellDataBuilding:GetRecommendPos()
    return false
end

return CityConstructionUICellDataBuilding