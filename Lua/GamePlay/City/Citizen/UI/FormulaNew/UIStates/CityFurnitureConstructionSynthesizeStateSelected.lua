local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local ColorConsts = require("ColorConsts")
local GuideUtils = require("GuideUtils")
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local CityWorkTargetType = require("CityWorkTargetType")
local CityFurnitureConstructionSynthesizeState = require("CityFurnitureConstructionSynthesizeState")

---@class CityFurnitureConstructionSynthesizeStateSelected:CityFurnitureConstructionSynthesizeState
---@field new fun(host:CityFurnitureConstructionSynthesizeUIMediator):CityFurnitureConstructionSynthesizeStateSelected
---@field super CityFurnitureConstructionSynthesizeState
local CityFurnitureConstructionSynthesizeStateSelected = class('CityFurnitureConstructionSynthesizeStateSelected', CityFurnitureConstructionSynthesizeState)

function CityFurnitureConstructionSynthesizeStateSelected:ctor(host)
    CityFurnitureConstructionSynthesizeState.ctor(self, host)
    self._processId = 0
    ---@type CityProcessConfigCell
    self._processConfig = nil
    ---@type CityAbilityConfigCell
    self._needAbility = nil
    ---@type table<number, {id:number, num:number}[]>
    self._lakeItem = {}
    self._isNotEnough = false
    self._produceCountMax = 0
    self._produceCount = 0
    ---@type {id:number,count:number}[]
    self._requireItems = {}
    ---@type ItemConfigCell
    self._outputItemConfig = nil
    ---@type ItemInfo
    self._outputItemInfo = nil
end

function CityFurnitureConstructionSynthesizeStateSelected:GetName()
    require(self._host._stateKey.Selected)
end

function CityFurnitureConstructionSynthesizeStateSelected:IsCurrentSelectedFormula(processId)
    return self._processId == processId
end

function CityFurnitureConstructionSynthesizeStateSelected:Enter()
    ---@type CityFurnitureConstructionProcessFormulaCellParameter
    local parameter = self._host:ReadBlackboard("FormulaCellParameter")
    if not parameter then
        self._host:ChangeState(self._host._stateKey.Idle)
        return
    end
    self._processId = parameter.processId
    self._processConfig = parameter.process
    self._needAbility = parameter.needAbility
    self:SetupItemIcons()
    self:CalculateMaxCount()
    self:UpdateOutputItemCount()
    self._produceCount = (self._produceCountMax > 0) and 1 or 0
    ---@type CommonNumberSliderData
    local sliderParameter = {}
    sliderParameter.callBack = Delegate.GetOrCreate(self, self.OnSliderChangeNum)
    sliderParameter.minNum = (self._produceCountMax > 0) and 1 or 0
    sliderParameter.maxNum = (self._produceCountMax > 0) and self._produceCountMax or 0
    sliderParameter.curNum = self._produceCount
    self._host._child_set_bar:FeedData(sliderParameter)
    self._host._p_Input_quantity:SetTextWithoutNotify(tostring(self._produceCount))
    self._host._p_Input_quantity.onEndEdit:AddListener(Delegate.GetOrCreate(self, self.OnInputQuantity))

    self:RefreshUI()
    for _, v in pairs(self._requireItems) do
        ModuleRefer.InventoryModule:AddCountChangeListener(v.id, Delegate.GetOrCreate(self, self.OnRequireItemCountChanged))
    end
    ModuleRefer.InventoryModule:AddCountChangeListener(self._outputItemInfo:ItemId(), Delegate.GetOrCreate(self, self.UpdateOutputItemCount))
end

function CityFurnitureConstructionSynthesizeStateSelected:Exit()
    ModuleRefer.InventoryModule:RemoveCountChangeListener(self._outputItemInfo:ItemId(), Delegate.GetOrCreate(self, self.UpdateOutputItemCount))
    for i, v in pairs(self._requireItems) do
        ModuleRefer.InventoryModule:RemoveCountChangeListener(v.id, Delegate.GetOrCreate(self, self.OnRequireItemCountChanged))
    end
    self._host._p_Input_quantity.onEndEdit:RemoveListener(Delegate.GetOrCreate(self, self.OnInputQuantity))
    self._host._p_btn_reduce:SetVisible(false)
end

function CityFurnitureConstructionSynthesizeStateSelected:ReEnter()
    self:Exit()
    self:Enter()
end

function CityFurnitureConstructionSynthesizeStateSelected:RefreshUI()
    local isLocked
    if self._needAbility then
        local castle = self._host._city:GetCastle()
        local abilityMap = castle and castle.CastleAbility or {}
        isLocked = self._needAbility:Level() > (abilityMap[self._needAbility:Type()] or 0)
    end
    if isLocked then
        self._host._p_cell_group:SetState(3)
    else
        self._host._p_cell_group:SetState(2)
    end
    self:UpdateItemsCount()
end

function CityFurnitureConstructionSynthesizeStateSelected:UpdateBtnStatus()
    self._host._p_comp_btn_mix:SetEnabled(true)--self._produceCount > 0)
end

function CityFurnitureConstructionSynthesizeStateSelected:CalculateMaxCount()
    local requireCount = self._processConfig:CostLength()
    local InventoryModule = ModuleRefer.InventoryModule
    local produceCountMax = (requireCount > 0) and 2147483647 or 0
    for i = 1, requireCount do
        local cost = self._processConfig:Cost(i)
        local needItemId = cost:ItemId()
        local count = InventoryModule:GetAmountByConfigId(needItemId)
        local needCount = cost:Count()
        if needCount > 0 then
            local produceCount = math.floor(count / needCount)
            if produceCount < produceCountMax then
                produceCountMax = produceCount
            end
        end
    end
    self._produceCountMax = produceCountMax
    self._host._p_text_input_quantity.text = string.format("/%d", self._produceCountMax)
end

function CityFurnitureConstructionSynthesizeStateSelected:UpdateOutputItemCount()
    self._host._p_text_inventory_num.text = tostring(ModuleRefer.InventoryModule:GetAmountByConfigId(self._outputItemInfo:ItemId()))
end

function CityFurnitureConstructionSynthesizeStateSelected:SetupItemIcons()
    table.clear(self._requireItems)
    local requireCount = self._processConfig:CostLength()
    local ItemConfig = ConfigRefer.Item
    for i = 1, math.max(self._host._requireSlotCount, requireCount) do
        local cell = self._host._p_item_btn[i]
        --local frame = self._host._p_img_frame_img[i]
        local icon = self._host._p_icon_img[i]
        if i > requireCount then
            cell:SetVisible(false)
        else
            local cost = self._processConfig:Cost(i)
            local needItemId = cost:ItemId()
            local itemConfig = ItemConfig:Find(needItemId)
            self._requireItems[i] = {id = needItemId, count = cost:Count()}
            if i <= self._host._requireSlotCount then
                local quality = 0
                local iconStr = "sp_icon_missing"
                if itemConfig then
                    quality = itemConfig:Quality()
                    iconStr = itemConfig:Icon()
                end
                cell:SetVisible(true)
                --g_Game.SpriteManager:LoadSprite('sp_item_frame_circle_'..tostring(quality), frame)
                g_Game.SpriteManager:LoadSprite(iconStr, icon)
            end
        end
    end
    self._outputItemInfo = self._processConfig:Output(1)
    self._outputItemConfig = ItemConfig:Find(self._outputItemInfo:ItemId())
    g_Game.SpriteManager:LoadSprite(self._outputItemConfig:Icon(), self._host._p_icon_item)
    self._host._p_text_item_name.text = I18N.Get(self._outputItemConfig:NameKey())
    self._host._p_text_item_name_lock.text = I18N.Get(self._outputItemConfig:NameKey())
end

function CityFurnitureConstructionSynthesizeStateSelected:OnRequireItemCountChanged()
    self._itemsDirty = true
end

function CityFurnitureConstructionSynthesizeStateSelected:Tick(dt)
    if not self._itemsDirty  then
        return
    end
    self._itemsDirty = false
    local oldMax = self._produceCountMax
    self:CalculateMaxCount()
    if oldMax ~= self._produceCountMax then
        if oldMax <= 0 then
            self._produceCount = 1
        else
            self._produceCount = math.min(self._produceCount, self._produceCountMax)
        end

        ---@type CommonNumberSliderData
        local sliderParameter = {}
        sliderParameter.callBack = Delegate.GetOrCreate(self, self.OnSliderChangeNum)
        sliderParameter.minNum = (self._produceCountMax > 0) and 1 or 0
        sliderParameter.maxNum = (self._produceCountMax > 0) and self._produceCountMax or 0
        sliderParameter.curNum = self._produceCount
        self._host._child_set_bar:FeedData(sliderParameter)
        self._host._p_Input_quantity:SetTextWithoutNotify(tostring(self._produceCount))
        self:UpdateItemsCount()
    else
        self:UpdateItemsCount()
    end
end

function CityFurnitureConstructionSynthesizeStateSelected:UpdateItemsCount()
    self._isNotEnough = false
    table.clear(self._lakeItem)
    local InventoryModule = ModuleRefer.InventoryModule
    local pCount = math.max(1, self._produceCount)
    local requireCount = self._processConfig:CostLength()
    for i = 1, math.max(self._host._requireSlotCount, requireCount)do
        local needPair = self._requireItems[i]
        if needPair then
            local needCount = needPair.count * pCount
            local count = InventoryModule:GetAmountByConfigId(needPair.id)
            if needCount > count then
                self._isNotEnough = true
                --self._lakeItem[i] = {{id = needPair.id, num=(needCount - count)}}
                self._lakeItem[i] = {{id = needPair.id, num=nil}}
            end
            if i <= self._host._requireSlotCount then
                local numText = self._host._p_text_num_text[i]
                local addBtn = self._host._p_item_add_btn[i]
                addBtn:SetVisible(needCount > count)
                ---@type CommonPairsQuantityParameter
                local param = {}
                param.num1 = count
                param.num2 = needCount
                param.compareType = CommonItemDetailsDefine.COMPARE_TYPE.LEFT_OWN_RIGHT_COST
                numText:FeedData(param)
            end
        end
    end
    self._host._p_text_item_quantity.text = string.format("x%d", self._produceCount * self._outputItemInfo:Count())
    self:UpdateBtnStatus()
end

function CityFurnitureConstructionSynthesizeStateSelected:OnClickItemBtn(index)
    local lake = self._lakeItem[index]
    if not lake then
        return
    end
    ModuleRefer.InventoryModule:OpenExchangePanel(lake)
end

function CityFurnitureConstructionSynthesizeStateSelected:OnClickGotoBtn()
    if not self._processConfig then
        return
    end
    local guideCall = self._processConfig:AbilityNeedGuide()
    local guideCallConfig = ConfigRefer.GuideCall:Find(guideCall)
    if not guideCallConfig then
        g_Logger.Error("processConfig:%s, AbilityNeedGuide:%s, guideCallConfig is nil", self._processConfig:Id(), guideCall)
        return
    end
    GuideUtils.GotoByGuide(guideCall,false)
end

function CityFurnitureConstructionSynthesizeStateSelected:OnClickSynthesizeBtn()
    if self._isNotEnough then
        self:OnClickDisabledSynthesizeBtn()
        return
    end
    local lockTrans = self._host._p_comp_btn_mix.button.transform
    local furnitureId = self._host._furniture:UniqueId()
    self._host._citizenMgr:ModifyProcessPlan(lockTrans, furnitureId, {0}, self._processId ,self._produceCount, function(context, isSuccess, data)
        if isSuccess then
            self._host._citizenMgr:StartWork(0, furnitureId, CityWorkTargetType.Furniture, lockTrans)
            self._host:ChangeState(self._host._stateKey.Working)
        else
            self._host:ChangeState(self._host._stateKey.Idle)
        end
    end)
end

function CityFurnitureConstructionSynthesizeStateSelected:OnClickDisabledSynthesizeBtn()
    local array = {}
    for _, v in pairs(self._lakeItem) do
        for _, needItem in pairs(v) do
            table.insert(array, needItem)
        end
    end
    if #array > 0 then
        ModuleRefer.InventoryModule:OpenExchangePanel(array)
    end
end

function CityFurnitureConstructionSynthesizeStateSelected:OnSliderChangeNum(curName)
    self._produceCount = curName
    self._host._p_Input_quantity:SetTextWithoutNotify(tostring(curName))
    self:UpdateItemsCount()
end

function CityFurnitureConstructionSynthesizeStateSelected:OnCastleAbilityChanged()
    self:RefreshUI()
end

function CityFurnitureConstructionSynthesizeStateSelected:OnInputQuantity(text)
    local value = tonumber(text) or 0
    local minCount
    local maxCount = self._produceCountMax
    if self._produceCountMax > 0 then
        minCount = 1
    else
        minCount = 0
    end
    value = math.clamp(value, minCount, maxCount)
    self._produceCount = value
    self._host._child_set_bar:OutInputChangeSliderValue(value)
    self:UpdateItemsCount()
end

---@param cellData CityFurnitureConstructionProcessFormulaCellParameter
function CityFurnitureConstructionSynthesizeStateSelected:OnClickFormulaCell(cellData)
    if self._processId == cellData.processId then
        return
    end
    self._host:WriteBlackboard("FormulaCellParameter", cellData, true)
    self._host:ChangeState(self._host._stateKey.Selected)
end

return CityFurnitureConstructionSynthesizeStateSelected