---@class CityConstructionUICellDataFurniture
---@field new fun():CityConstructionUICellDataFurniture
---@field typCell CityFurnitureTypesConfigCell
---@field lvCell CityFurnitureLevelConfigCell
---@field stockCount number
---@field stockFold CityConstructionUICellDataFurniture[]
---@field building CityCellTile
---@field itemGroup ItemGroupConfigCell
local CityConstructionUICellDataFurniture = class("CityConstructionUICellDataFurniture")
local CityConstructState = require("CityConstructState")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local CityGridCellDef = require("CityGridCellDef")
local CastleAddFurnitureParameter = require("CastleAddFurnitureParameter")
local ArtResourceUtils = require("ArtResourceUtils")
local I18N = require("I18N")
local Delegate = require('Delegate')
local UIHelper = require("UIHelper")
local EventConst = require("EventConst")
local TimerUtility = require("TimerUtility")
local ShowTipInterval = 0.1
local Utils = require("Utils")
local NotificationType = require("NotificationType")

---@param uiCell CityConstructionModeUICell
function CityConstructionUICellDataFurniture:OnFeedData(uiCell)
    self.uiCell = uiCell
    local state = self:GetState()
    local canBuild = state == CityConstructState.CanBuild
    local lackMaterial = state == CityConstructState.LackOfResource
    local isFull = state == CityConstructState.IsFull
    local conditionNotMeet = state == CityConstructState.ConditionNotMeet
    local notOwn = state == CityConstructState.NotOwn
    uiCell.canBuild = canBuild

    --- 家具冲突
    local isMutex = state == CityConstructState.Mutex
    uiCell._p_icon_ban:SetActive(isMutex)

    --- 未知状态
    uiCell._p_case_unactivated:SetActive(false)
    uiCell._p_case_activated:SetActive(true)

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
    local QuantityHide = (state == CityConstructState.UnknownBuilding) or isFull
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

    --- 家具改成没有库存，收纳是直接拆除
    -- local stock = self:GetStock()
    uiCell._p_save.gameObject:SetActive(false)
    -- uiCell._p_txt_quantity_save.text = tostring(stock)

    --- 展示材料显示
    local materialShow = (canBuild or lackMaterial)
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

    uiCell._p_txt_desc.text = I18N.Get(self.typCell:BriefDescription())

    --- 不能建造的提示信息
    uiCell._p_txt_hint.gameObject:SetActive(isFull)
    if isFull then
        uiCell._p_txt_hint.text = I18N.Get("build_limit")
    end

    --- 占地
    uiCell._p_area:SetActive(true)
    uiCell._p_txt_quantity_area.text = ("%dx%d"):format(self.lvCell:SizeX(), self.lvCell:SizeY())

    uiCell.child_reddot_default.go:SetActive(true)
    local node = ModuleRefer.NotificationModule:GetDynamicNode("CityConstruction_FurnitureType_"..self.typCell:Id(), NotificationType.CITY_CONSTRUCTION_FURNITURE)
    if node then
        ModuleRefer.NotificationModule:AttachToGameObject(node, uiCell.child_reddot_default.go, uiCell.child_reddot_default.redNew)
    end

    if self.ping then
        self.ping = nil
        self:OnPingFinger(self)
    end

    UIHelper.SetGray(uiCell._p_btn_click.gameObject, (isFull or conditionNotMeet or isMutex or notOwn))

    g_Game.EventManager:AddListener(EventConst.CITY_CONSTRUCTION_CELL_GUIDE_FINGER, Delegate.GetOrCreate(self, self.OnPingFinger))
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))

    local matType = self:GetMaterialTypeAmount()
    for i = 1, matType do
        ModuleRefer.InventoryModule:AddCountChangeListener(self:GetMaterial(i):Id(), Delegate.GetOrCreate(self, self.OnMatCountChange))
    end
end

function CityConstructionUICellDataFurniture:OnRecycle()
    local matType = self:GetMaterialTypeAmount()
    for i = 1, matType do
        ModuleRefer.InventoryModule:RemoveCountChangeListener(self:GetMaterial(i):Id(), Delegate.GetOrCreate(self, self.OnMatCountChange))
    end

    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnTick))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CONSTRUCTION_CELL_GUIDE_FINGER, Delegate.GetOrCreate(self, self.OnPingFinger))
    self.uiCell = nil
end

---@param uiCell CityConstructionModeUICell
function CityConstructionUICellDataFurniture:OnClick(uiCell)
    local state, mutexLvCell = self:GetState()
    if state ~= CityConstructState.CanBuild then
        if state == CityConstructState.NotOwn then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_need_more_furniture", self:GetName()))
        elseif state == CityConstructState.IsFull then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_furniture_quantity_limit", self:GetName()))
        elseif state == CityConstructState.Mutex then
            local typCell = ConfigRefer.CityFurnitureTypes:Find(mutexLvCell:Type())
            local name = I18N.Get(typCell:Name())
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_furniture_type_limit", name))
        elseif state == CityConstructState.LackOfResource then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("sys_city_73"))
            ModuleRefer.InventoryModule:OpenExchangePanelByItemGroup(self.itemGroup)
        elseif state == CityConstructState.ConditionNotMeet then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("build_unknown"))
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


---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionUICellDataFurniture:BeginDrag(uiCell, go, eventData)
    uiCell.dragChecking = true
    self.pointerDown = false
    self:HideTips()

    local state, mutexLvCell = self:GetState()
    if state ~= CityConstructState.CanBuild then
        if state == CityConstructState.NotOwn then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_need_more_furniture", self:GetName()))
        elseif state == CityConstructState.IsFull then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_furniture_quantity_limit", self:GetName()))
        elseif state == CityConstructState.Mutex then
            local typCell = ConfigRefer.CityFurnitureTypes:Find(mutexLvCell:Type())
            local name = I18N.Get(typCell:Name())
            ModuleRefer.ToastModule:AddSimpleToast(I18N.GetWithParams("tips_furniture_type_limit", name))
        elseif state == CityConstructState.LackOfResource then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("sys_city_73"))
            ModuleRefer.InventoryModule:OpenExchangePanelByItemGroup(self.itemGroup)
        elseif state == CityConstructState.ConditionNotMeet then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("build_unknown"))
        end
    end
end

---@param go CS.UnityEngine.GameObject
---@param eventData CS.UnityEngine.EventSystems.PointerEventData
function CityConstructionUICellDataFurniture:Drag(uiCell, go, eventData)
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
function CityConstructionUICellDataFurniture:EndDrag(uiCell, go, eventData)
    if uiCell.isStockFold then
        return
    end

    uiCell.dragChecking = false
    if uiCell.canBuild then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_BUILDING_UICELL_DRAG_RELEASE)
    end
end

function CityConstructionUICellDataFurniture:OnClickDetails(uiCell)
    uiCell:GetParentBaseUIMediator():ListStockView(self)
end

function CityConstructionUICellDataFurniture:OnPingFinger(data)
    if data ~= self then return end

    TimerUtility.DelayExecuteInFrame(function()
        local rectTrans = self.uiCell._p_btn_click.transform
        --require('GuideFingerUtil').ShowGuideFinger(rectTrans)
    end)
end

---@return boolean
function CityConstructionUICellDataFurniture:IsUnactivated()
    return false
end

---@return number
function CityConstructionUICellDataFurniture:GetState()
    local limitCount = self:LimitCount()
    if limitCount == 0 then
        return CityConstructState.ConditionNotMeet
    end

    if self:IsLimit() then
        if self:Existed() >= limitCount then
            return CityConstructState.IsFull
        end
    end

    for i = 1, self:GetMaterialTypeAmount() do
        local matItem = self:GetMaterial(i)
        if ModuleRefer.InventoryModule:GetAmountByConfigId(matItem:Id()) < self:GetMaterialNeed(i) then
            return CityConstructState.LackOfResource
        end
    end

    return CityConstructState.CanBuild
end

---@return string
function CityConstructionUICellDataFurniture:GetName()
    return I18N.Get(self.typCell:Name())
end

---@return number
function CityConstructionUICellDataFurniture:GetLevel()
    if self.lvCell then
        return self.lvCell:Level()
    end
    return 0
end

---@return string
function CityConstructionUICellDataFurniture:GetImage()
    return self.typCell:Image()
end

---@return boolean
function CityConstructionUICellDataFurniture:IsLimit()
    return self:LimitCount() > 0
end

---@return boolean
function CityConstructionUICellDataFurniture:Existed()
    if self.building == nil then
        return ModuleRefer.CityConstructionModule:GetFurnitureCountByType(self.typCell:Id())
    else
        local ret = 0
        local castle = self.building:GetCity():GetCastle()
        local cell = self.building:GetCell()
        local furnitures = castle.CastleFurniture
        local buildingInfo = castle.BuildingInfos[cell.tileId]
        if buildingInfo then
            for _, v in pairs(buildingInfo.InnerFurniture) do
                local furniture = furnitures[v]
                local lvCell = ConfigRefer.CityFurnitureLevel:Find(furniture.ConfigId)
                if lvCell:Type() == self.typCell:Id() then
                    ret = ret + 1
                end
            end
        end
        return ret
    end
end

---@return number
function CityConstructionUICellDataFurniture:LimitCount()
    return ModuleRefer.CityConstructionModule:GetPlaceFurnitureTypeNumLimit(self.typCell:Id())
end

---@return number
function CityConstructionUICellDataFurniture:GetStock()
    return self.stockCount
end

---@return number
function CityConstructionUICellDataFurniture:GetStockKind()
    if self.stockFold then
        return #self.stockFold
    end
    return 0
end

---@return number
function CityConstructionUICellDataFurniture:GetMaterialTypeAmount()
    if self.itemGroup then
        return self.itemGroup:ItemGroupInfoListLength()
    else
        return 0
    end
end

---@return ItemConfigCell
function CityConstructionUICellDataFurniture:GetMaterial(index)
    local info = self.itemGroup:ItemGroupInfoList(index)
    return ConfigRefer.Item:Find(info:Items())
end

---@return number
function CityConstructionUICellDataFurniture:GetMaterialNeed(index)
    local info = self.itemGroup:ItemGroupInfoList(index)
    return info:Nums()
end

---@return string
function CityConstructionUICellDataFurniture:GetShowConditionDesc()
    return string.Empty
end

---@return string
function CityConstructionUICellDataFurniture:GetUnlockConditionDesc()
    return string.Empty
end

function CityConstructionUICellDataFurniture:SizeX()
    if self.lvCell then
        return self.lvCell:SizeX()
    end
    return 0
end

function CityConstructionUICellDataFurniture:SizeY()
    if self.lvCell then
        return self.lvCell:SizeY()
    end
    return 0
end

function CityConstructionUICellDataFurniture:PrefabName()
    if self.lvCell then
        local model = ArtResourceUtils.GetItem(self.lvCell:Model())
        if model then
            return model
        end
    end
    return string.Empty
end

function CityConstructionUICellDataFurniture:Scale()
    if self.lvCell then
        local scale = ArtResourceUtils.GetItem(self.lvCell:Model(), 'ModelScale')
        if scale then
            return scale
        end
    end
    return 1
end

function CityConstructionUICellDataFurniture:ConfigId()
    if self.lvCell then
        return self.lvCell:Id()
    end
    return 0
end

function CityConstructionUICellDataFurniture:RequestToBuild(x, y, dir)
    local msg = CastleAddFurnitureParameter.new()
    msg.args.ConfigId = self.lvCell:Id()
    msg.args.X = x
    msg.args.Y = y
    msg.args.Dir = dir
    local myCity = ModuleRefer.CityModule:GetMyCity()
    if myCity then
        local legoBuilding = myCity.legoManager:GetLegoBuildingAt(x, y)
        msg.args.BuildingId = legoBuilding and legoBuilding.id or 0
    end
    msg:SendWithFullScreenLock()
end

function CityConstructionUICellDataFurniture:IsBuilding()
    return false
end

function CityConstructionUICellDataFurniture:IsMutex()
    return false
end

function CityConstructionUICellDataFurniture:TypeId()
    return self.typCell:Id()
end

function CityConstructionUICellDataFurniture:OnTick(deltaTime)
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

function CityConstructionUICellDataFurniture:OnPointerDown(uiCell)
    self.pointerDown = true
    self.downTime = 0
end

function CityConstructionUICellDataFurniture:OnPointerUp(uiCell)
    self.pointerDown = false
    self:HideTips()
end

---@param lvCell CityFurnitureLevelConfigCell
function CityConstructionUICellDataFurniture:ShowTipsAt(worldPos, lvCell)
    local attrGroup = ConfigRefer.AttrGroup:Find(lvCell:Attr())
    if attrGroup == nil then return end

    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_SHOW_TIPS, worldPos, attrGroup)
end

function CityConstructionUICellDataFurniture:HideTips()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_CONSTRUCTION_UI_HIDE_TIPS)
end

function CityConstructionUICellDataFurniture:IsFurniture()
    return true
end

function CityConstructionUICellDataFurniture:OnMatCountChange()
    if Utils.IsNotNull(self.uiCell.CSComponent) then
        self:OnFeedData(self.uiCell)
    end
end

function CityConstructionUICellDataFurniture:GetRecommendPos()
    if self.lvCell then
        local typCell = ConfigRefer.CityFurnitureTypes:Find(self.lvCell:Type())
        if typCell then
            return true, typCell:PositionX(), typCell:PositionY()
        end
    end
    return false
end

return CityConstructionUICellDataFurniture