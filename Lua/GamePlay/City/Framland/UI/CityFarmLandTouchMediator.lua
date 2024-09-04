--- scene:scene_farm_touch

local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local CityCitizenDefine = require("CityCitizenDefine")
local OnChangeHelper = require("OnChangeHelper")
local DBEntityPath = require("DBEntityPath")
local AudioConsts = require("AudioConsts")

local BaseUIMediator = require("BaseUIMediator")

---@class CityFarmLandTouchMediatorParameter
---@field city MyCity
---@field farmland wds.CastleFurniture
---@field farmlandMgr CityFarmlandManager

---@class CityFarmLandTouchMediator:BaseUIMediator
---@field new fun():CityFarmLandTouchMediator
---@field super BaseUIMediator
local CityFarmLandTouchMediator = class('CityFarmLandTouchMediator', BaseUIMediator)

function CityFarmLandTouchMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type CityFarmLandTouchCellData
    self._currentDragCellData = nil
    self._harvestMode = false
    ---@type table<number, boolean>
    self._pickedFurnitureIds = {}
    self._tempResourceLeft = 0
    self._lastToastCooldown = 0
    ---@type CS.UnityEngine.Vector2
    self._dragPos = nil
    ---@type CityFurnitureTile
    self._lastFarmlandTile = nil
    ---@type table<number, CityFarmLandTouchCellData[]>
    self._needItem2FormulaMap = {}
    ---@type table<number, CityFarmLandTouchCellData[]>
    self._outputItem2FormulaMap = {}
end

function CityFarmLandTouchMediator:OnCreate(param)
    self._p_table_material = self:TableViewPro("p_table_material")
    ---@type CityFarmLandTouchDragCell
    self._p_dragItem = self:LuaObject("p_dragItem")
    ---@type CityFarmlandTouchMediatorOutputTips
    self._p_tips_item = self:LuaObject("p_tips_item")
    self._p_rect_tip_range = self:RectTransform("p_rect_tip_range")
    self._p_table_material.OnScrollRectMovingAction = Delegate.GetOrCreate(self, self.OnFormulaTableScroll)
    self._p_table_material.OnScrollRectEndAction = Delegate.GetOrCreate(self, self.OnFormulaTableScrollEnd)
    self._p_need = self:Transform("p_need")
    ---@type CS.FpAnimation.FpAnimatorTotalCommander
    self._dragVfx = self._p_need:Find("vx_trigger/drag"):GetComponent(typeof(CS.FpAnimation.FpAnimatorTotalCommander))
    ---@type CS.FpAnimation.FpAnimatorTotalCommander
    self._drag_out = self._p_need:Find("vx_trigger/drag_out"):GetComponent(typeof(CS.FpAnimation.FpAnimatorTotalCommander))
    ---@type CS.FpAnimation.FpAnimatorTotalCommander
    self._lack_loop = self._p_need:Find("vx_trigger/lack_loop"):GetComponent(typeof(CS.FpAnimation.FpAnimatorTotalCommander))
end

function CityFarmLandTouchMediator:OnShow(param)
    ModuleRefer.InventoryModule:ForceInitCache()
    self:SetupEvents(true)
end

function CityFarmLandTouchMediator:OnHide(param)
    self:SetupEvents(false)
end

---@param param CityFarmLandTouchMediatorParameter
function CityFarmLandTouchMediator:OnOpened(param)
    self._param = param
    self._city = param.city
    self._p_dragItem:SetVisible(false)
    if param.farmland.LandInfo.state == wds.CastleLandState.CastleLandHarvestable then
        self._harvestMode = true
    else
        self._harvestMode = false
    end
    self:GenerateTableCell()
    if self._harvestMode then
        if not g_Game.UIManager:IsOpenedByName(UIMediatorNames.CityItemHarvestMediator) then
            g_Game.UIManager:Open(UIMediatorNames.CityItemHarvestMediator)
        end
    end
    if not g_Game.UIManager:IsOpenedByName(UIMediatorNames.CityItemResumeMediator) then
        g_Game.UIManager:Open(UIMediatorNames.CityItemResumeMediator)
    end
end

function CityFarmLandTouchMediator:OnClose(data)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_FURNITURE_FARMLAND_TOUCH_UI_CLOSED, self:GetRuntimeId())
end

function CityFarmLandTouchMediator:GenerateTableCell()
    table.clear(self._needItem2FormulaMap)
    table.clear(self._outputItem2FormulaMap)
    self._p_table_material:Clear()
    if not self._harvestMode then
        ---@type CityFarmLandTouchCellData[]
        local cells = {}
        local castleAbility = self._param.city:GetCastle().CastleAbility or {}
        for _, cropConfigCell in ConfigRefer.Crop:pairs() do
            ---@type CityFarmLandTouchCellData
            local cell = {}
            cell.host = self
            cell.harvestMode = false
            cell.cropConfig = cropConfigCell
            cell.isLocked = false
            cell.seedNeedCount = 1
            local needAbility = cropConfigCell:AbilityNeed()
            if needAbility then
                local ability = ConfigRefer.CityAbility:Find(needAbility)
                if ability then
                    local abilityType = ability:Type()
                    local abV = castleAbility[abilityType] or 0
                    if ability:Level() > abV then
                        cell.isLocked = true
                    end
                end
            end
            local needItemId = cell.cropConfig:ItemId()
            local inList = self._needItem2FormulaMap[needItemId]
            if not inList then
                inList = {}
                self._needItem2FormulaMap[needItemId] = inList
            end
            table.insert(inList, cell)
            inList = self._outputItem2FormulaMap[needItemId]
            if not inList then
                inList = {}
                self._outputItem2FormulaMap[needItemId] = inList
            end
            table.insert(inList, cell)
            table.insert(cells, cell)
            ::continue::
        end
        table.sort(cells, function(a, b)
            if a.isLocked and not b.isLocked then
                return false
            end
            if not a.isLocked and b.isLocked then
                return true
            end
            return a.cropConfig:Id() < b.cropConfig:Id()
        end)
        for _, cell in ipairs(cells) do
            self._p_table_material:AppendData(cell)
        end
    else
        ---@type CityFarmLandTouchCellData
        local cell = {}
        cell.host = self
        cell.harvestMode = true
        cell.harvestIcon = string.Empty
        self._p_table_material:AppendData(cell)
    end
end

---@param cellData CityFarmLandTouchCellData
---@param data CS.UnityEngine.EventSystems.PointerEventData
---@return boolean
function CityFarmLandTouchMediator:OnBeginDrag(cellData, data)
    if self._currentDragCellData then
        return false
    end
    self._dragPos = nil
    table.clear(self._pickedFurnitureIds)
    self._currentDragCellData = cellData
    if not self._currentDragCellData.harvestMode then
        local screenPos = data.position
        self._dragPos = screenPos
        self:CheckAndSetDetailTip(screenPos)
        local needItemId = self._currentDragCellData.cropConfig:ItemId()
        self._tempResourceLeft = ModuleRefer.InventoryModule:GetAmountByConfigId(needItemId)
        local lakeCount = self._currentDragCellData.seedNeedCount - self._tempResourceLeft
        if lakeCount > 0 then
            ModuleRefer.InventoryModule:OpenExchangePanel({{id = needItemId}})
            self:OnDragCancel(nil, true)
            return false
        end
        self._p_dragItem:UpdateLeftCount(self._tempResourceLeft)
    end
    self._p_dragItem:SetVisible(true)
    self._p_dragItem:FeedData(cellData)
    local pick, tile = self:PickFarmLand(data)
    if pick then
        if self._lastFarmlandTile ~= tile then
            if self._lastFarmlandTile then
                self._lastFarmlandTile:SetSelected(false)
            end
            self._lastFarmlandTile = tile
            self._lastFarmlandTile:SetSelected(true)
        end
    end
    self:UpdateDragCellPos(data)
    self._dragVfx:PlayAll()
    return true
end

---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFarmLandTouchMediator:OnDrag(data)
    if not self._currentDragCellData then
        return
    end
    local screenPos = data.position
    self._dragPos = screenPos
    self:CheckAndSetDetailTip(screenPos)
    self:UpdateDragCellPos(data)
    local pick, tile = self:PickFarmLand(data)
    if pick then
        if self._lastFarmlandTile ~= tile then
            if self._lastFarmlandTile then
                self._lastFarmlandTile:SetSelected(false)
            end
            self._lastFarmlandTile = tile
            self._lastFarmlandTile:SetSelected(true)
        end
    end
end

---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFarmLandTouchMediator:OnEndDrag(data)
    if not self._currentDragCellData then
        return
    end
    if self._lastFarmlandTile then
        self._lastFarmlandTile:SetSelected(false)
    end
    self._lastFarmlandTile = nil
    self._dragPos = nil
    local cellData = self._currentDragCellData
    --self:PickFarmLand(data)
    self._currentDragCellData = nil
    self._p_dragItem:SetVisible(false)
    self._p_tips_item:SetVisible(false)
    self:CheckAndFireEvent(cellData)
    table.clear(self._pickedFurnitureIds)
    self._tempResourceLeft = 0
    self:CloseSelf()
end

function CityFarmLandTouchMediator:CheckLeftResourceAndToast()
    if self._tempResourceLeft < self._currentDragCellData.seedNeedCount then
        if self._lastToastCooldown < g_Game.ServerTime:GetServerTimestampInSeconds() then
            local item = ConfigRefer.Item:Find(self._currentDragCellData.cropConfig:ItemId())
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(string.format("farm_info_notenoughresource", I18N.Get(item:NameKey()))))
            self._lastToastCooldown = g_Game.ServerTime:GetServerTimestampInSeconds() + 2
            if not self._lack_loop.IsPlaying then
                self._lack_loop:PlayAll()
            end
        end
        return false
    end
    return true
end

function CityFarmLandTouchMediator:OnDragCancel(go, skipSelectCancel)
    if not self._currentDragCellData then
        return
    end
    self._currentDragCellData = nil
    table.clear(self._pickedFurnitureIds)
    self._tempResourceLeft = 0
    if not skipSelectCancel then
        self._param.farmlandMgr:DummyCancel()
    end
end

---@param cellData CityFarmLandTouchCellData
---@param rectTransform CS.UnityEngine.RectTransform
function CityFarmLandTouchMediator:OnCellShowTip(cellData, rectTransform)
    if self._harvestMode then
        return
    end
    self._p_tips_item:FeedData(cellData)
    self._p_tips_item:SetVisible(true)
    local pos = rectTransform.rect.center
    local worldPos = rectTransform:TransformPoint(pos.x, pos.y, 0)
    local uiCamera = g_Game.UIManager:GetUICamera()
    local screenPos = uiCamera:WorldToScreenPoint(worldPos)
    self:CheckAndSetDetailTip(CS.UnityEngine.Vector2(screenPos.x, screenPos.y))
end

function CityFarmLandTouchMediator:OnCellHideTip()
    self._p_tips_item:SetVisible(false)
end

---@param data CS.UnityEngine.EventSystems.PointerEventData
function CityFarmLandTouchMediator:UpdateDragCellPos(data)
    local screenPos = CS.UnityEngine.Vector3(data.position.x, data.position.y, 0)
    local camera = g_Game.UIManager:GetUICamera()
    local worldPos = camera:ScreenToWorldPoint(screenPos)
    self._p_dragItem:UpdatePos(worldPos)
end

---@param data CS.UnityEngine.EventSystems.PointerEventData
---@return boolean
function CityFarmLandTouchMediator:PickFarmLand(data)
    local screenPos = data.position
    local furniture = self._param.city:RaycastFurnitureTile(CS.UnityEngine.Vector3(screenPos.x, screenPos.y, 0))
    if not furniture then
        return false
    end
    local typeId = furniture:GetFurnitureType()
    if not typeId or not CityCitizenDefine.IsFarmlandFurniture(typeId) then
        return false
    end
    local castleFurniture = furniture:GetCastleFurniture()
    if not castleFurniture then
        return false
    end
    local furnitureCell = furniture:GetCell()
    local furnitureId = furnitureCell:UniqueId()
    if self._currentDragCellData.harvestMode then
        if castleFurniture.LandInfo.state ~= wds.CastleLandState.CastleLandHarvestable then
            return false
        end
    else
        if castleFurniture.LandInfo.state ~= wds.CastleLandState.CastleLandFree then
            return false
        end
    end
    if self._pickedFurnitureIds[furnitureId] then
        return false
    end
    if not self._currentDragCellData.harvestMode then
        if not self:CheckLeftResourceAndToast() then
            return false
        end
        self._tempResourceLeft = self._tempResourceLeft - self._currentDragCellData.seedNeedCount
        self._p_dragItem:UpdateLeftCount(self._tempResourceLeft)
    end
    self._pickedFurnitureIds[furnitureId] = true
    self._param.farmlandMgr:DummySelect(furnitureId)
    if self._harvestMode then
        self._param.farmlandMgr:DummyHarvest(furnitureId)
        g_Game.SoundManager:PlayAudio(AudioConsts.sfx_ui_reward_crop)
    else
        self._param.farmlandMgr:DummySowSeed(furnitureId, self._currentDragCellData.cropConfig)
    end
    if self._currentDragCellData.harvestMode then
        local landInfo = furniture:GetCastleFurniture().LandInfo
        local cropConfig = ConfigRefer.Crop:Find(landInfo.cropTid)
        local cellPos = self._param.city:GetCenterWorldPositionFromCoord(furnitureCell.x, furnitureCell.y, furnitureCell.sizeX, furnitureCell.sizeY)
        local cellViewPortPos = self._param.city:GetCamera():GetUnityCamera():WorldToViewportPoint(cellPos)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_SCENE_UI_ITEM_HARVEST, cropConfig:ItemId(), cropConfig:HarvestNum(), cellViewPortPos)
    elseif self._currentDragCellData.cropConfig then
        local cellPos = self._param.city:GetCenterWorldPositionFromCoord(furnitureCell.x, furnitureCell.y, furnitureCell.sizeX, furnitureCell.sizeY)
        local cellViewPortPos = self._param.city:GetCamera():GetUnityCamera():WorldToViewportPoint(cellPos)
        --g_Game.EventManager:TriggerEvent(EventConst.CITY_SCENE_UI_ITEM_HARVEST, self._currentDragCellData.cropConfig:ItemId(), -1 * self._currentDragCellData.seedNeedCount, cellViewPortPos)
        g_Game.EventManager:TriggerEvent(EventConst.CITY_SCENE_UI_ITEM_RESUME, self._currentDragCellData.cropConfig:ItemId(), self._currentDragCellData.seedNeedCount, cellViewPortPos)
    end
    return true, furniture
end

---@param cellData CityFarmLandTouchCellData
function CityFarmLandTouchMediator:CheckAndFireEvent(cellData)
    if table.isNilOrZeroNums(self._pickedFurnitureIds) then
        return
    end
    local ids = table.keys(self._pickedFurnitureIds)
    table.sort(ids)
    if cellData.harvestMode then
        self._param.farmlandMgr:HarvestCrops(ids)
    else
        self._param.farmlandMgr:SowSeeds(cellData.cropConfig:Id(), ids)
    end
    self._param.farmlandMgr:DummyCancel()
end

---@param screenPos CS.UnityEngine.Vector2
---@param skipCheckRange boolean
function CityFarmLandTouchMediator:CheckAndSetDetailTip(screenPos, skipCheckRange)
    if self._p_tips_item:IsHide() then
        return
    end
    local uiCamera = g_Game.UIManager:GetUICamera()
    local inRange = CS.UnityEngine.RectTransformUtility.RectangleContainsScreenPoint(self._p_rect_tip_range, screenPos, uiCamera)
    if not inRange and not skipCheckRange then
        self._p_tips_item:SetVisible(false)
        return
    end
    local worldPos = uiCamera:ScreenToWorldPoint(CS.UnityEngine.Vector3(screenPos.x, screenPos.y, 0))
    local parent = self._p_tips_item.SelfTrans.parent
    local localPos = parent:InverseTransformPoint(worldPos)
    localPos.y = localPos.y + 80
    localPos.z = 0
    self._p_tips_item.SelfTrans.anchoredPosition3D = localPos
end

function CityFarmLandTouchMediator:OnFormulaTableScroll()
    self._formulaTableInDragging = true
    self._dragPos = nil
    self:OnCellHideTip()
end

function CityFarmLandTouchMediator:OnFormulaTableScrollEnd()
    self._formulaTableInDragging = false
end

function CityFarmLandTouchMediator:SetupEvents(add)
    if add then
        g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnCastleItemChanged))
    else
        g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Bag.KItems.MsgPath, Delegate.GetOrCreate(self, self.OnCastleItemChanged))
    end
end

---@param entity wds.CastleBrief
---@param changedData any
function CityFarmLandTouchMediator:OnCastleItemChanged(entity, changedData)
    if not self._city or entity.ID ~= self._city.uid then
        return
    end
    ---@type table<number, boolean>
    local changedItems = {}
    local add,remove,change = OnChangeHelper.GenerateMapFieldChangeMap(changedData)
    if add then
        for _, v in pairs(add) do
            changedItems[v.ConfigId] = true
        end
    end
    if remove then
        for _, v in pairs(remove) do
            changedItems[v.ConfigId] = true
        end
    end
    if change then
        for _, v in pairs(change) do
            changedItems[v[2].ConfigId] = true
        end
    end
    ---@type table<CityFarmLandTouchCellData, boolean>
    local needUpdateCell = {}
    for itemId, _ in pairs(changedItems) do
        local cellList = self._needItem2FormulaMap[itemId]
        if cellList then
            for _, cellData in pairs(cellList) do
                needUpdateCell[cellData] = true
            end
        end
        cellList = self._outputItem2FormulaMap[itemId]
        if cellList then
            for _, cellData in pairs(cellList) do
                needUpdateCell[cellData] = true
            end
        end
    end
    for cellData,_ in pairs(needUpdateCell) do
        self._p_table_material:UpdateData(cellData)
    end
end

return CityFarmLandTouchMediator