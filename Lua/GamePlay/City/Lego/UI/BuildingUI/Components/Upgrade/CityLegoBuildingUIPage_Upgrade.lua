local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")
local Utils = require("Utils")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local CityWorkFormula = require("CityWorkFormula")
local NumberFormatter = require("NumberFormatter")
local CityWorkUIPropertyChangeItemData = require("CityWorkUIPropertyChangeItemData")
local CityWorkType = require("CityWorkType")
local CityWorkUICostItemData = require("CityWorkUICostItemData")
local CityWorkI18N = require("CityWorkI18N")
local TimerUtility = require("TimerUtility")
local ConfigTimeUtility = require("ConfigTimeUtility")
local UIMediatorNames = require("UIMediatorNames")
local CityLegoBuffDifferData = require("CityLegoBuffDifferData")

local CastleStartWorkParameter = require("CastleStartWorkParameter")
local CastleFurnitureLvUpConfirmParameter = require("CastleFurnitureLvUpConfirmParameter")
local CityFurnitureUpgradeSpeedUpHolder = require("CityFurnitureUpgradeSpeedUpHolder")
local EventConst = require("EventConst")
local TimeFormatter = require("TimeFormatter")

local FailureCode = {
    Success = 0,
    InOtherWork = 1,
    LackRes = 2,
    SameWorkTypeFull = 3,
    NotMeetCondition = 4,
    Polluted = 5,
}

local FailureReason = {
    [FailureCode.LackRes] = "sys_city_38",
    [FailureCode.SameWorkTypeFull] = "sys_city_68",
    [FailureCode.NotMeetCondition] = "sys_city_78",
    [FailureCode.Polluted] = CityWorkI18N.FAILURE_REASON_POLLUTED,
}

---@class CityLegoBuildingUIPage_Upgrade:BaseUIComponent
local CityLegoBuildingUIPage_Upgrade = class('CityLegoBuildingUIPage_Upgrade', BaseUIComponent)

function CityLegoBuildingUIPage_Upgrade:OnCreate()
    self.transform = self:Transform("")
    
    self._p_text_property_name = self:Text("p_text_property_name")
    self._p_text_property_value_old = self:Text("p_text_property_value_old")
    self._p_text_property_value_new = self:Text("p_text_property_value_new")

    self._p_property_vertical = self:Transform("p_property_vertical")
    ---@see CityLegoBuffDifferCell
    self._p_table_property = self:TableViewPro("p_table_property")

    self._p_title_cost = self:GameObject("p_title_cost")
    self._p_text_cost = self:Text("p_text_cost", "city_upgrade_consume")
    self._p_cost_grid = self:Transform("p_cost_grid")
    self._p_item_cost = self:LuaBaseComponent("p_item_cost")
    self._pool_cost = LuaReusedComponentPool.new(self._p_item_cost, self._p_cost_grid)

    self._p_title_condition = self:GameObject("p_title_condition")
    self._p_text_condition = self:Text("p_text_condition", "city_upgrade_condition")
    self._p_condition_vertical = self:Transform("p_condition_vertical")
    ---@type CityWorkUIConditionItem
    self._p_conditions = self:LuaBaseComponent("p_conditions")
    self._pool_condition = LuaReusedComponentPool.new(self._p_conditions, self._p_condition_vertical)
    -- self._p_btn_open = self:Button("p_btn_open", Delegate.GetOrCreate(self, self.OnClickConditionStretch))
    -- self._p_icon_arrow = self:Transform("p_icon_arrow")

    self._p_bottom_btn = self:RectTransform("p_bottom_btn")

    ---@type BistateButton
    self._p_btn_complete = self:LuaObject("p_btn_complete")
    ---@type BistateButton
    self._p_btn_upgrade = self:LuaObject("p_btn_upgrade")

    self._p_progress = self:GameObject("p_progress")
    self._p_progress_n = self:Image("p_progress_n")
    self._p_progress_pause = self:Image("p_progress_pause")
    self._p_text_progress = self:Text("p_text_progress", "buildupgrade_leveluping")
    ---@type CommonTimer
    self._child_time_progress = self:LuaObject("child_time_progress")
    self._p_btn_delect = self:Button("p_btn_delect", Delegate.GetOrCreate(self, self.OnClickCancel))

    self._p_hint_creep = self:GameObject("p_hint_creep")
    self._p_text_hint_creep = self:Text("p_text_hint_creep", "building_cannot_expand_tips_1")

    self._vx_effect_glow = self:GameObject("vx_effect_glow")
    -- if Utils.IsNotNull(self._vx_effect_glow) then
    --     self._vx_effect_glow:SetActive(self._upgrading)
    -- end
end

---@param param CityWorkFurnitureUpgradeUIParameter
function CityLegoBuildingUIPage_Upgrade:OnFeedData(param)
    self.param = param
    self.cellTile = param.source
    self.furnitureId = self.cellTile:GetCell().singleId
    self.workCfg = param:GetWorkCfg()
    self.typCell = param:GetTypeCell()
    self.lvCell = param:GetLvCell()
    self.nextLvCell = param:GetNextLvCell()
    self.city = param:GetCity()

    ---@type CityWorkUICostItemData[]
    self.inputDataList = {}
    ---@type CityWorkUICostItem[]
    self.inputItemList = {}
    self.conditionStretch = false
    self._p_hint_creep:SetActive(self.cellTile:IsPolluted())

    self:UpdateBasicInfo()
    self:UpdateProperty()
    self:UpdateWorkingStatus()
    self:UpdateCondition()
    self:UpdateCost()
    self:UpdateProcessing() 
    self:UpdateConditionUIStatus()
    self:CheckIfFinishedAndClaimIt()

    local itemCfg = ModuleRefer.ConsumeModule:GetSpeedUpCommonItemCfg()
    self.speedUpListener = ModuleRefer.InventoryModule:AddCountChangeListener(itemCfg:Id(), Delegate.GetOrCreate(self, self.OnSpeedUpCoinChanged))
end

function CityLegoBuildingUIPage_Upgrade:OnShow()
    self:AddEventListeners()
end

function CityLegoBuildingUIPage_Upgrade:OnHide()
    self:RemoveEventListeners()
    self:ReleaseAllItemCountChangeListener()
    if self._tickTimer then
        self:StopTimer(self._tickTimer)
        self._tickTimer = nil
    end
    if self.speedUpListener ~= nil then
        self.speedUpListener()
        self.speedUpListener = nil
    end
end

function CityLegoBuildingUIPage_Upgrade:OnClose()
    self:OnHide()
end

function CityLegoBuildingUIPage_Upgrade:UpdateBasicInfo()
    self._p_text_property_name.text = I18N.Get(self.typCell:Name())
    self._p_text_property_value_old.text = ("Lv.%d"):format(self.lvCell:Level())
    self._p_text_property_value_new.text = ("Lv.%d"):format(self.nextLvCell:Level())
end

function CityLegoBuildingUIPage_Upgrade:UpdateWorkAttributes()
    -- --- 消耗减少显示
    -- local costDecrease = CityWorkFormula.GetCostDecrease(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    -- self._p_buff_1:SetVisible(costDecrease ~= 0)
    -- if costDecrease ~= 0 then
    --     g_Game.SpriteManager:LoadSprite("sp_common_icon_time_01", self._p_icon_1)
    --     self._p_text_1.text = NumberFormatter.PercentWithSignSymbol(costDecrease)
    -- end

    -- --- 产出增加显示
    -- local outputIncrease = CityWorkFormula.GetOutputIncrease(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    -- self._p_buff_2:SetVisible(outputIncrease ~= 0)
    -- if outputIncrease ~= 0 then
    --     g_Game.SpriteManager:LoadSprite("sp_comp_icon_set", self._p_icon_2)
    --     self._p_text_2.text = NumberFormatter.PercentWithSignSymbol(outputIncrease)
    -- end

    -- --- 耗时减少
    -- local timeDecrease = math.clamp01(1 - CityWorkFormula.CalculateTimeCostDecrease(self.param.workCfg, ConfigTimeUtility.NsToSeconds(self.lvCell:LevelUpTime()), nil, self.furnitureId, self.citizenId))
    -- self._p_buff_3:SetVisible(timeDecrease ~= 0)
    -- if timeDecrease ~= 0 then
    --     g_Game.SpriteManager:LoadSprite("sp_comp_icon_hero_tab", self._p_icon_3)
    --     self._p_text_3.text = NumberFormatter.PercentWithSignSymbol(timeDecrease)
    -- end
end

function CityLegoBuildingUIPage_Upgrade:UpdateProperty()
    if self.nextLvCell == nil then
        return self:UpdatePropertyCurrent()
    else
        return self:UpdatePropertyUpgrade()
    end
end


function CityLegoBuildingUIPage_Upgrade:UpdatePropertyCurrent()
    self._p_table_property:Clear()
    
    local typCfg = ConfigRefer.CityFurnitureTypes:Find(self.lvCell:Type())
    if not typCfg:HideAddScore() then
        self._p_table_property:AppendData({from=self.lvCell:AddScore()}, 1)
    end

    local dataList = {}
    local propertyList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(self.lvCell:Attr())
    if propertyList then
        for i, v in ipairs(propertyList) do
            local data = CityLegoBuffDifferData.new(v.type, v.originValue)
            table.insert(dataList, data)
        end
    end

    for i = 1, self.lvCell:BattleAttrGroupsLength() do
        local battleGroup = self.lvCell:BattleAttrGroups(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup)
        if battleValues then
            for _, v in ipairs(battleValues) do
                if battleGroup:TextLength() == 0 then
                    local data = CityLegoBuffDifferData.new(v.type, v.originValue)
                    table.insert(dataList, data)
                else
                    for j = 1, battleGroup:TextLength() do
                        local prefix = battleGroup:Text(j)
                        local data = CityLegoBuffDifferData.new(v.type, v.originValue, nil, prefix)
                        table.insert(dataList, data)
                    end
                end
            end
        end
    end

    for _, data in ipairs(dataList) do
        self._p_table_property:AppendData(data, 0)
    end
end

function CityLegoBuildingUIPage_Upgrade:UpdatePropertyUpgrade()
    self._p_table_property:Clear()

    local typCfg = ConfigRefer.CityFurnitureTypes:Find(self.lvCell:Type())
    if not typCfg:HideAddScore() then
        self._p_table_property:AppendData({from=self.lvCell:AddScore(), to=self.nextLvCell:AddScore()}, 1)
    end

    ---@type CityLegoBuffDifferData[]
    local oldDataList = {}
    local propertyList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(self.lvCell:Attr())
    if propertyList then
        for i, v in ipairs(propertyList) do
            local data = CityLegoBuffDifferData.new(v.type, v.originValue)
            table.insert(oldDataList, data)
        end
    end

    for i = 1, self.lvCell:BattleAttrGroupsLength() do
        local battleGroup = self.lvCell:BattleAttrGroups(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
        if battleValues then
            for _, v in ipairs(battleValues) do
                if battleGroup:TextLength() == 0 then
                    local data = CityLegoBuffDifferData.new(v.type, v.originValue)
                    table.insert(oldDataList, data)
                else
                    for j = 1, battleGroup:TextLength() do
                        local prefix = battleGroup:Text(j)
                        local data = CityLegoBuffDifferData.new(v.type, v.originValue, nil, prefix)
                        table.insert(oldDataList, data)
                    end
                end
            end
        end
    end

    ---@type CityLegoBuffDifferData[]
    local newDataList = {}
    local newPropertyList = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(self.nextLvCell:Attr())
    if newPropertyList then
        for i, v in ipairs(newPropertyList) do
            local data = CityLegoBuffDifferData.new(v.type, v.originValue)
            table.insert(newDataList, data)
        end
    end

    for i = 1, self.nextLvCell:BattleAttrGroupsLength() do
        local battleGroup = self.nextLvCell:BattleAttrGroups(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
        if battleValues then
            for _, v in ipairs(battleValues) do
                if battleGroup:TextLength() == 0 then
                    local data = CityLegoBuffDifferData.new(v.type, v.originValue)
                    table.insert(newDataList, data)
                else
                    for j = 1, battleGroup:TextLength() do
                        local prefix = battleGroup:Text(j)
                        local data = CityLegoBuffDifferData.new(v.type, v.originValue, nil, prefix)
                        table.insert(newDataList, data)
                    end
                end
            end
        end
    end

    ---@type table<string, CityLegoBuffDifferData>
    local propertyMap = {}
    for i, v in ipairs(oldDataList) do
        propertyMap[v:GetUniqueName()] = v
    end

    local toShowList = {}
    for i, newProp in ipairs(newDataList) do
        local oldProp = propertyMap[newProp:GetUniqueName()]
        --- 数值变化的词条
        if oldProp ~= nil then
            if newProp.oldValue ~= oldProp.oldValue then
                local data = CityLegoBuffDifferData.new(newProp.elementId, oldProp.oldValue, newProp.oldValue, oldProp.prefix)
                table.insert(toShowList, data)
            end
            propertyMap[newProp:GetUniqueName()] = nil
        --- 新增的词条
        else
            local data = CityLegoBuffDifferData.new(newProp.elementId, 0, newProp.oldValue, newProp.prefix)
            table.insert(toShowList, data)
        end
    end

    --- 删除的词条
    for _, oldProp in pairs(propertyMap) do
        local data = CityLegoBuffDifferData.new(oldProp.elementId, oldProp.oldValue, 0, oldProp.prefix)
        table.insert(toShowList, data)
    end

    for i, data in ipairs(toShowList) do
        self._p_table_property:AppendData(data, 0)
    end

    local showExtra = self:GetExtraInfos()
    if #showExtra > 0 then
        self._p_table_property:AppendDataEx({title = I18N.Get("function_unlock"), dataList = showExtra}, 592, #showExtra * 48 + 8, 2)
    end

    local hasNewRecipe = self:GetNewRecipeInfo()
    if #hasNewRecipe > 0 then
        self._p_table_property:AppendDataEx({title = I18N.Get("furproduce_unlock"), dataList = showExtra}, 592, #hasNewRecipe * 48 + 8, 2)
    end
end

function CityLegoBuildingUIPage_Upgrade:GetExtraInfos()
    local extraInfos = {}
    for i = 1, self.nextLvCell:NextLevelExtraUnlockInfoLength() do
        table.insert(extraInfos, I18N.Get(self.nextLvCell:NextLevelExtraUnlockInfo(i)))
    end
    return extraInfos
end

function CityLegoBuildingUIPage_Upgrade:GetNewRecipeInfo()
    local extraInfos = {}
    for i = 1, self.nextLvCell:NextLevelExtraUnlockInfoLength() do
        table.insert(extraInfos, I18N.Get(self.nextLvCell:NextLevelExtraUnlockInfo(i)))
    end
    return extraInfos
end

function CityLegoBuildingUIPage_Upgrade:UpdatePropertyStretchButton()
    local rotation = self.conditionStretch and -90 or 90
    self._p_icon_arrow.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, rotation)
end

function CityLegoBuildingUIPage_Upgrade:UpdateWorkingStatus()
    local workType = CityWorkType.FurnitureLevelUp
    local castleFurniture = self.param.source:GetCastleFurniture()
    self.workId = castleFurniture.WorkType2Id[workType] or 0
    self.work = self.city.cityWorkManager:GetWorkData(self.workId)

    if self.work ~= nil then
        self._upgrading = true
        return
    end

    local levelUpInfo = self:GetLevelUpInfo()
    if levelUpInfo.Working then
        self._upgrading = true
        return
    end

    self._upgrading = false
end

function CityLegoBuildingUIPage_Upgrade:UpdateCondition()
    local meetCondition = false
    local conditionCount = self.lvCell:LevelUpConditionLength()
    if conditionCount == 0 then
        self.meetCondition = true
        return
    end

    meetCondition = true
    for i = 1, conditionCount do
        local taskId = self.lvCell:LevelUpCondition(i)
        local taskCfg = ConfigRefer.Task:Find(taskId)
        if taskCfg ~= nil then
            local status = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskCfg:Id())
            local finished = status == wds.TaskState.TaskStateFinished or status == wds.TaskState.TaskStateCanFinish
            meetCondition = meetCondition and finished
        end
    end
    self.meetCondition = meetCondition
end

function CityLegoBuildingUIPage_Upgrade:UpdateCost()
    self._p_cost_grid:SetVisible(not self._upgrading)
    if self._upgrading then return end

    local itemGroup = ConfigRefer.ItemGroup:Find(self.lvCell:LevelUpCost())
    local cost = CityWorkFormula.CalculateInput(self.workCfg, itemGroup, nil, self.furnitureId, self.citizenId)
    local costTypes = #cost

    self:ReleaseAllItemCountChangeListener()
    self._p_cost_grid:SetVisible(costTypes > 0)
    if costTypes > 0 then
        self._pool_cost:HideAll()
        self.inputDataList = {}
        self.inputItemList = {}
        for i, v in ipairs(cost) do
            local item = self._pool_cost:GetItem()
            if item then
                local data = CityWorkUICostItemData.new(v.id, v.count)
                data:AddCountListener(Delegate.GetOrCreate(self, self.OnItemCountChanged))
                item:FeedData(data)
                table.insert(self.inputDataList, data)
                table.insert(self.inputItemList, item)
            end
        end
    end
    self.costItems = cost
end

function CityLegoBuildingUIPage_Upgrade:ReleaseAllItemCountChangeListener()
    if self.inputDataList == nil then return end
    for i, v in ipairs(self.inputDataList) do
        v:ReleaseCountListener()
    end
end

function CityLegoBuildingUIPage_Upgrade:OnItemCountChanged()
    for i, v in ipairs(self.inputItemList) do
        v:FeedData(self.inputDataList[i])
    end
    self:UpdateProcessing()
end

function CityLegoBuildingUIPage_Upgrade:UpdateProcessing()
    if self._upgrading then
        self:UpdateStatusProcessing()
    else
        self:UpdateStatusNotWork()
    end
end

function CityLegoBuildingUIPage_Upgrade:UpdateStatusProcessing()
    self._p_bottom_btn:SetVisible(true)
    self._p_btn_complete:SetVisible(true)
    self._p_progress:SetActive(true)
    if Utils.IsNotNull(self._vx_effect_glow) then
        self._vx_effect_glow:SetActive(true)
    end

    local paused = self.work == nil
    self._p_progress_n:SetVisible(not paused)
    self._p_progress_pause:SetVisible(paused)

    if paused then
        ---@type BistateButtonParameter
        self._buttonData = self._buttonData or {}
        self._buttonData.buttonText = I18N.Get(CityWorkI18N.UI_FurnitureUpgrade_Button_Continue)
        self._buttonData.onClick = Delegate.GetOrCreate(self, self.OnClickContinue)
        self._buttonData.disableClick = Delegate.GetOrCreate(self, self.OnClickContinueDisable)
        self._buttonData.singleNumber = false
        self._buttonData.icon = nil
        self._p_btn_upgrade:FeedData(self._buttonData)
        self._p_btn_upgrade:SetEnabled(not self.cellTile:IsPolluted())
    else
        local info = self:GetLevelUpInfo()
        if info.Helped 
            or not ModuleRefer.AllianceModule:IsInAlliance() 
            or not ModuleRefer.AllianceModule:IsAllianceEntryUnLocked()
            or not ModuleRefer.AllianceModule:IsAllianceHelpUnlocked() then
            ---@type BistateButtonParameter
            self._buttonData = self._buttonData or {}
            self._buttonData.buttonText = I18N.Get(CityWorkI18N.UI_FurnitureUpgrade_Button_SpeedUp)
            self._buttonData.onClick = Delegate.GetOrCreate(self, self.OnClickSpeedUp)
            self._buttonData.disableClick = Delegate.GetOrCreate(self, self.OnClickSpeedUpDisable)
            self._buttonData.singleNumber = false
            self._buttonData.icon = nil
            self._p_btn_upgrade:FeedData(self._buttonData)
            self._p_btn_upgrade:SetEnabled(not self.cellTile:IsPolluted())
        else
            ---@type BistateButtonParameter
            self._buttonData = self._buttonData or {}
            self._buttonData.buttonText = I18N.Get(CityWorkI18N.UI_FurnitureUpgrade_Button_AllianceHelp)
            self._buttonData.onClick = Delegate.GetOrCreate(self, self.OnClickHelp)
            self._buttonData.disableClick = Delegate.GetOrCreate(self, self.OnClickHelpDisable)
            self._buttonData.singleNumber = false
            self._buttonData.icon = nil
            self._p_btn_upgrade:FeedData(self._buttonData)
            self._p_btn_upgrade:SetEnabled(not self.cellTile:IsPolluted())
        end
    end

    if self._tickTimer then
        TimerUtility.StopAndRecycle(self._tickTimer)
        self._tickTimer = nil
    end

    local itemCfg = ModuleRefer.ConsumeModule:GetSpeedUpCommonItemCfg()
    self._priceButtonData = self._priceButtonData or {}
    self._priceButtonData.buttonText = I18N.Get("Pay_FurUpTime")
    self._priceButtonData.onClick = Delegate.GetOrCreate(self, self.OnClickFinishImmediately)
    self._priceButtonData.disableClick = Delegate.GetOrCreate(self, self.OnClickFinishImmediately)
    self._priceButtonData.singleNumber = false
    self._priceButtonData.num1 = self:GetConsumeLevelUpPrice()
    self._priceButtonData.num2 = ModuleRefer.ConsumeModule:GetOwnedConsumeCoin()
    self._priceButtonData.icon = itemCfg:Icon()
    self._p_btn_complete:FeedData(self._priceButtonData)

    if paused then
        local levelUpInfo = self:GetLevelUpInfo()
        self._p_progress_pause.fillAmount = levelUpInfo.CurProgress / levelUpInfo.TargetProgress
        self._p_text_progress = I18N.Get("sys_city_26")
        self._child_time_progress:SetVisible(false)
    else
        self._p_progress_n.fillAmount = self:GetWorkProgress()
        self._p_text_progress = I18N.Get("buildupgrade_leveluping")
        self._timerData = self._timerData or {}
        self._timerData.needTimer = false
        self._timerData.fixTime = self:GetWorkRemainTime()
        self._child_time_progress:SetVisible(true)
        self._child_time_progress:FeedData(self._timerData)
        self._tickTimer = self:StartFrameTicker(Delegate.GetOrCreate(self, self.UpdateProgress), 1, -1, false)
    end
    self:UpdateProgressVfxPosition()
    self:UpdateProgressComsumeButton()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_bottom_btn)
end

function CityLegoBuildingUIPage_Upgrade:UpdateProgress()
    if self.work == nil then return end

    self._p_progress_n.fillAmount = self:GetWorkProgress()
    self._timerData.fixTime = self:GetWorkRemainTime()
    self._child_time_progress:RefreshTimeText()
    self:UpdateProgressVfxPosition()
    self:UpdateProgressComsumeButton()
end

function CityLegoBuildingUIPage_Upgrade:GetConsumeLevelUpPrice()
    local remainTime = self:GetRemainTime()
    return ModuleRefer.ConsumeModule:CalculateFurnitureLevelUpCost(remainTime)
end

function CityLegoBuildingUIPage_Upgrade:GetRemainTime()
    if self._upgrading then
        if self.work == nil then
            local levelUpInfo = self:GetLevelUpInfo()
            return levelUpInfo.TargetProgress - levelUpInfo.CurProgress
        else
            return self:GetWorkRemainTime()
        end
    else
        return CityWorkFormula.CalculateFinalTimeCost(self.workCfg, ConfigTimeUtility.NsToSeconds(self.lvCell:LevelUpTime()), self.lvCell:LevelUpDifficulty(), nil, self.furnitureId, self.citizenId)
    end
end

function CityLegoBuildingUIPage_Upgrade:GetLevelUpInfo()
    local castleFurniture = self.param.source:GetCastleFurniture()
    return castleFurniture.LevelUpInfo
end

function CityLegoBuildingUIPage_Upgrade:GetWorkProgress()
    local levelUpInfo = self:GetLevelUpInfo()
    if levelUpInfo.TargetProgress == 0 then return 1 end

    local gap = self.city:GetWorkTimeSyncGap()
    local done = levelUpInfo.CurProgress + gap * self:GetSpeed()
    local target = levelUpInfo.TargetProgress
    return math.clamp01(done / target)
end

function CityLegoBuildingUIPage_Upgrade:GetWorkRemainTime()
    local gap = self.city:GetWorkTimeSyncGap()
    local levelUpInfo = self:GetLevelUpInfo()
    local efficiency = self:GetSpeed()
    local done = levelUpInfo.CurProgress + gap * efficiency
    local target = levelUpInfo.TargetProgress
    return math.max(0, (target - done) / efficiency)
end

function CityLegoBuildingUIPage_Upgrade:GetSpeed()
    if not self.work then return 1 end
    return self.work.Efficiency
end

function CityLegoBuildingUIPage_Upgrade:UpdateProgressVfxPosition()
    local rect = self._p_progress_n.rectTransform
    local lb, lt, rb, rt = rect:GetTiledWorldCorner()
    self._vxStartX = lb.x
    self._vxStartY = (lb.y + lt.y) / 2
    self._vxEndX = rb.x
    self._vxEndY = (rb.y + rt.y) / 2

    local curX = math.lerp(self._vxStartX, self._vxEndX, self._p_progress_n.fillAmount)
    if Utils.IsNotNull(self._vx_effect_glow) then
        self._vx_effect_glow.transform.position = CS.UnityEngine.Vector3(curX, self._vxStartY, 0)
    end
end

function CityLegoBuildingUIPage_Upgrade:UpdateProgressComsumeButton()
    if not self._upgrading then return end

    self._priceButtonData = self._priceButtonData or {}
    self._priceButtonData.num1 = self:GetConsumeLevelUpPrice()
    self._priceButtonData.num2 = ModuleRefer.ConsumeModule:GetOwnedConsumeCoin()
    self._p_btn_complete:ShowCompareNumbers(self._priceButtonData)

    --- 升级中一定是满足条件的，所以此时只需要检查钱是否够用就行
    local isEnough = self:IsConsumeButtonEnabled()
    self._p_btn_complete:SetEnabled(isEnough and not self.cellTile:IsPolluted())
end

function CityLegoBuildingUIPage_Upgrade:IsConsumeButtonEnabled()
    local remainTime = self:GetRemainTime()
    return ModuleRefer.ConsumeModule:CanSpeedUpFurnitureLevelUpCostWithMoney(remainTime)
end

function CityLegoBuildingUIPage_Upgrade:UpdateStatusNotWork()
    local errCode = self:CanUpgrade()
    --- 不满足条件时，升级按钮全部隐藏
    if errCode == FailureCode.NotMeetCondition then
        self._p_bottom_btn:SetVisible(false)
    else
        self._p_bottom_btn:SetVisible(true)
        self._p_btn_upgrade:SetVisible(true)
        local time = CityWorkFormula.CalculateFinalTimeCost(self.workCfg, ConfigTimeUtility.NsToSeconds(self.lvCell:LevelUpTime()), self.lvCell:LevelUpDifficulty(), nil, self.furnitureId, self.citizenId)
        ---@type BistateButtonParameter
        self._buttonData = self._buttonData or {}
        self._buttonData.buttonText = I18N.Get("sys_city_25")
        self._buttonData.onClick = Delegate.GetOrCreate(self, self.OnClickStart)
        self._buttonData.disableClick = Delegate.GetOrCreate(self, self.OnClickDisable)
        self._buttonData.singleNumber = true
        self._buttonData.num1 = TimeFormatter.SimpleFormatTime(time)
        self._buttonData.icon = "sp_common_icon_time_01"
        self._p_btn_upgrade:FeedData(self._buttonData)

        self._p_btn_complete:SetVisible(self.lvCell:LevelUpTime() > 0)
        local itemCfg = ModuleRefer.ConsumeModule:GetSpeedUpCommonItemCfg()
        self._priceButtonData = self._priceButtonData or {}
        self._priceButtonData.buttonText = I18N.Get("Pay_FurUpTime")
        self._priceButtonData.onClick = Delegate.GetOrCreate(self, self.OnClickFinishImmediately)
        self._priceButtonData.disableClick = Delegate.GetOrCreate(self, self.OnClickFinishImmediately)
        self._priceButtonData.singleNumber = false
        self._priceButtonData.num1 = self:GetConsumeLevelUpPrice()
        self._priceButtonData.num2 = ModuleRefer.ConsumeModule:GetOwnedConsumeCoin()
        self._priceButtonData.icon = itemCfg:Icon()
        self._p_btn_complete:FeedData(self._priceButtonData)

        local basicEnabled = errCode == FailureCode.Success or errCode == FailureCode.LackRes or errCode == FailureCode.SameWorkTypeFull
        self._p_btn_upgrade:SetEnabled(basicEnabled)
        --- 这里因为加速消耗的东西是一个道具，无法保证他们的升级材料中是否也包含这个道具，故需另外单独处理
        local extraErrCode = self:CanUpgradeWithConsume()
        local consumeEnabled = extraErrCode == FailureCode.Success or extraErrCode == FailureCode.LackRes or extraErrCode == FailureCode.SameWorkTypeFull
        local isEnough = self:IsConsumeButtonEnabled()
        self._p_btn_complete:SetEnabled(isEnough and consumeEnabled)
    end

    self._p_progress:SetActive(false)
    if Utils.IsNotNull(self._vx_effect_glow) then
        self._vx_effect_glow:SetActive(false)
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._p_bottom_btn)
end

function CityLegoBuildingUIPage_Upgrade:UpdateConditionUIStatus()
    if self._upgrading then
        self._p_condition_vertical:SetVisible(false)
        return
    end

    if self.meetCondition then
        self._p_condition_vertical:SetVisible(false)
        return
    end

    self._pool_condition:HideAll()
    local conditionCount = self.lvCell:LevelUpConditionLength()
    self._p_condition_vertical:SetVisible(conditionCount > 0)

    if conditionCount == 0 then
        return
    end

    local furniture = self.cellTile:GetCell()
    for i = 1, conditionCount do
        local taskId = self.lvCell:LevelUpCondition(i)
        local taskCfg = ConfigRefer.Task:Find(taskId)
        if taskCfg ~= nil then
            local item = self._pool_condition:GetItem()
            item:FeedData({cfg = taskCfg, furniture = furniture})
        end
    end
end

function CityLegoBuildingUIPage_Upgrade:AddEventListeners()
    g_Game.ServiceManager:AddResponseCallback(CastleStartWorkParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnStartWorkCallback))
    g_Game.ServiceManager:AddResponseCallback(CastleFurnitureLvUpConfirmParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimCallback))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_UPGRADE_FINISHED, Delegate.GetOrCreate(self, self.OnTurnToRibbonCutting))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnLevelUpFinished))
    g_Game.EventManager:AddListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_WORK_UPDATE, Delegate.GetOrCreate(self, self.OnCastleWorkChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_WORK_UPDATE_TIME, Delegate.GetOrCreate(self, self.OnWorkTimeUpdate))
    g_Game.EventManager:AddListener(EventConst.UI_CITY_LEGO_SELECT_TARGET_FURNITURE_FAILED, Delegate.GetOrCreate(self, self.GotoFallback))
end

function CityLegoBuildingUIPage_Upgrade:RemoveEventListeners()
    g_Game.ServiceManager:RemoveResponseCallback(CastleStartWorkParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnStartWorkCallback))
    g_Game.ServiceManager:RemoveResponseCallback(CastleFurnitureLvUpConfirmParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnClaimCallback))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_UPGRADE_FINISHED, Delegate.GetOrCreate(self, self.OnTurnToRibbonCutting))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_FURNITURE_LEVEL_UP_STATS_CHANGE, Delegate.GetOrCreate(self, self.OnLevelUpFinished))
    g_Game.EventManager:RemoveListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_WORK_UPDATE, Delegate.GetOrCreate(self, self.OnCastleWorkChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_WORK_UPDATE_TIME, Delegate.GetOrCreate(self, self.OnWorkTimeUpdate))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_LEGO_SELECT_TARGET_FURNITURE_FAILED, Delegate.GetOrCreate(self, self.GotoFallback))
end

function CityLegoBuildingUIPage_Upgrade:CheckIfFinishedAndClaimIt()
    local levelUpInfo = self:GetLevelUpInfo()
    if levelUpInfo.Working and levelUpInfo.CurProgress >= levelUpInfo.TargetProgress then
        self.city.furnitureManager:RequestClaimFurnitureLevelUp(self.furnitureId)
    end
end

function CityLegoBuildingUIPage_Upgrade:OnStartWorkCallback(isSuccess, reply, rpc)
    self:UpdateWorkingStatus()
    self:UpdateCondition()
    self:UpdateCost()
    self:UpdateProcessing()
    self:UpdateConditionUIStatus()
end

function CityLegoBuildingUIPage_Upgrade:OnClaimCallback(isSuccess, reply, rpc)
    if not isSuccess then return end
    if rpc.request.FurnitureId ~= self.furnitureId then return end

    if self.param:UpdateDataByFurnitureTile() then
        self:GetParentBaseUIMediator():ShowFurniturePage(self.furnitureId)
        return
    end

    self.furnitureId = self.cellTile:GetCell().singleId
    self.workCfg = self.param:GetWorkCfg()
    self.typCell = self.param:GetTypeCell()
    self.lvCell = self.param:GetLvCell()
    self.nextLvCell = self.param:GetNextLvCell()

    self._p_hint_creep:SetActive(self.cellTile:IsPolluted())
    self:ReleaseAllItemCountChangeListener()
    -- self:UpdateCitizenUnitVisible() --没有这个方法 看起来是没有从CityWorkFurnitureUpgradeUIMediator挪过来
    self:UpdateBasicInfo()
    self:UpdateProperty()
    self:UpdateWorkingStatus()
    self:UpdateCondition()
    self:UpdateCost()
    self:UpdateProcessing()
    self:UpdateConditionUIStatus()
end

function CityLegoBuildingUIPage_Upgrade:OnFurnitureDataChanged(city, batchEvt)
    if city ~= self.city then return end

    if batchEvt.Change[self.furnitureId] then
        self._p_hint_creep:SetActive(self.cellTile:IsPolluted())
    end
    self:UpdateProcessing()
end

function CityLegoBuildingUIPage_Upgrade:OnTurnToRibbonCutting(city, batchEvt)
    if city ~= self.city then return end
    
    if batchEvt.furnitureId == self.furnitureId then
        self.city.furnitureManager:RequestClaimFurnitureLevelUp(self.furnitureId)
    end
    self:UpdateProcessing()
end

function CityLegoBuildingUIPage_Upgrade:OnLevelUpFinished(city, batchEvt)
    if city ~= self.city then return end
    
    if not batchEvt.Change[self.furnitureId] then return end
    if self.param:UpdateDataByFurnitureTile() then
        self:GetParentBaseUIMediator():ShowFurniturePage(self.furnitureId)
        return
    end

    self.furnitureId = self.cellTile:GetCell().singleId
    self.workCfg = self.param:GetWorkCfg()
    self.typCell = self.param:GetTypeCell()
    self.lvCell = self.param:GetLvCell()
    self.nextLvCell = self.param:GetNextLvCell()

    self._p_hint_creep:SetActive(self.cellTile:IsPolluted())
    self:ReleaseAllItemCountChangeListener()
    self:UpdateBasicInfo()
    self:UpdateProperty()
    self:UpdateWorkingStatus()
    self:UpdateCondition()
    self:UpdateCost()
    self:UpdateProcessing()
    self:UpdateConditionUIStatus()
end

function CityLegoBuildingUIPage_Upgrade:OnCastleAttrChanged()
    self:UpdateCondition()
    self:UpdateCost()
    self:UpdateProcessing()
    self:UpdateConditionUIStatus()
end

function CityLegoBuildingUIPage_Upgrade:OnCastleWorkChanged(city, batchEvt)
    if city ~= self.city then return end

    if self.workId and batchEvt.Change and batchEvt.Change[self.workId] then
        self.work = self.city.cityWorkManager:GetWorkData(self.workId)
        self:UpdateProcessing()
    end
end

function CityLegoBuildingUIPage_Upgrade:OnWorkTimeUpdate(city, batchEvt)
    if city ~= self.city then return end

    if self._upgrading then
        self:UpdateProgress()
    end
end

function CityLegoBuildingUIPage_Upgrade:CanUpgrade()
    if self.cellTile:IsPolluted() then
        return FailureCode.Polluted
    end

    local castleFurniture = self.param.source:GetCastleFurniture()
    local workType = CityWorkType.FurnitureLevelUp
    local workId = castleFurniture.WorkType2Id[workType] or 0
    local workData = self.city.cityWorkManager:GetWorkData(workId)
    if workId > 0 and workData and workData.ConfigId ~= self.workCfg:Id() then
        return FailureCode.InOtherWork
    end

    if not self.workCfg:NotCheckQueueCount() then
        local upgradingCount = self.city.cityWorkManager:GetWorkingCountByType(self.workCfg:Type())
        local maxCount = CityWorkFormula.GetTypeMaxQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
        if upgradingCount >= maxCount then
            return FailureCode.SameWorkTypeFull
        end
    end

    if not self.meetCondition then
        return FailureCode.NotMeetCondition
    end

    for i, v in ipairs(self.costItems) do
        if ModuleRefer.InventoryModule:GetAmountByConfigId(v.id) < v.count then
            return FailureCode.LackRes
        end
    end

    return 0
end

function CityLegoBuildingUIPage_Upgrade:CanUpgradeWithConsume()
    if self.cellTile:IsPolluted() then
        return FailureCode.Polluted
    end

    local castleFurniture = self.param.source:GetCastleFurniture()
    local workType = CityWorkType.FurnitureLevelUp
    local workId = castleFurniture.WorkType2Id[workType] or 0
    local workData = self.city.cityWorkManager:GetWorkData(workId)
    if workId > 0 and workData and workData.ConfigId ~= self.workCfg:Id() then
        return FailureCode.InOtherWork
    end

    local upgradingCount = self.city.cityWorkManager:GetWorkingCountByType(self.workCfg:Type())
    local maxCount = CityWorkFormula.GetTypeMaxQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if upgradingCount >= maxCount then
        return FailureCode.SameWorkTypeFull
    end

    if not self.meetCondition then
        return FailureCode.NotMeetCondition
    end

    local consumeItemCfgId = ModuleRefer.ConsumeModule:GetSpeedUpCommonItemCfg():Id()
    local remainTime = self:GetRemainTime()
    local extraCost = ModuleRefer.ConsumeModule:CalculateFurnitureLevelUpCost(remainTime)
    for i, v in ipairs(self.costItems) do
        local plus = v.id == consumeItemCfgId and extraCost or 0
        if ModuleRefer.InventoryModule:GetAmountByConfigId(v.id) < (v.count + plus) then
            return FailureCode.LackRes
        end
    end

    return 0
end

function CityLegoBuildingUIPage_Upgrade:OnClickConditionStretch()
    self.conditionStretch = not self.conditionStretch
    self:UpdateProperty()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.transform)
end

function CityLegoBuildingUIPage_Upgrade:OnClickStart(_, buttonTransform)
    local failureCode = self:CanUpgrade()
    if failureCode == FailureCode.LackRes then
        self:ShowLackResGetMore()
    elseif failureCode == FailureCode.SameWorkTypeFull then
        self:ShowUpgradePopupUI()
    elseif failureCode == FailureCode.Success then
        if self.lvCell and self.lvCell:LevelUpTime() == 0 then
            self:RequestUpgradeImmediately(buttonTransform)
        else
            self.city.cityWorkManager:StartLevelUpWork(self.furnitureId, self.workCfg:Id(), self.citizenId, buttonTransform, Delegate.GetOrCreate(self, self.TryStartGuide))
        end
    end
end

function CityLegoBuildingUIPage_Upgrade:ShowLackResGetMore()
    local getmoreList = {}
    for i, v in ipairs(self.costItems) do
        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
        if own < v.count then
            table.insert(getmoreList, {id = v.id, num = v.count - own})
        end
    end
    ModuleRefer.InventoryModule:OpenExchangePanel(getmoreList)
end

function CityLegoBuildingUIPage_Upgrade:OnClickDisable()
    local failureCode = self:CanUpgrade()
    if failureCode ~= 0 then
        if FailureReason[failureCode] then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[failureCode]))
        end
    end
    self:UpdateWorkingStatus()
    self:UpdateCondition()
    self:UpdateCost()
    self:UpdateConditionUIStatus()
    self:UpdateProcessing()
end

function CityLegoBuildingUIPage_Upgrade:ShowUpgradePopupUI()
    g_Game.UIManager:Open(UIMediatorNames.CityWorkFurnitureUpgradePopupUIMediator, self.city)
end

function CityLegoBuildingUIPage_Upgrade:OnClickFinishImmediately()
    if self._upgrading then
        if self.cellTile:IsPolluted() then
            if FailureReason[FailureCode.Polluted] then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[FailureCode.Polluted]))
            end
            return
        end

        local isEnough = self:IsConsumeButtonEnabled()
        if isEnough then
            local remainTime = self:GetRemainTime()
            self:ConfirmTwice(remainTime, Delegate.GetOrCreate(self, self.RequestFinishUpgradeWorking))
        else
            self:ShowLackSpeedUpCost()
        end
    else
        local failureCode = self:CanUpgradeWithConsume()
        if failureCode == FailureCode.LackRes then
            return self:ShowLackResGetMoreWithConsume()
        end

        if failureCode == FailureCode.SameWorkTypeFull then
            return self:ShowUpgradePopupUI()
        end

        local basicEnabled = failureCode == FailureCode.Success
        local isEnough = self:IsConsumeButtonEnabled()
        if basicEnabled and isEnough then
            local remainTime = self:GetRemainTime()
            self:ConfirmTwice(remainTime, Delegate.GetOrCreate(self, self.RequestUpgradeImmediately))
        elseif not isEnough then
            self:ShowLackSpeedUpCost()
        else
            if FailureReason[failureCode] then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[failureCode]))
            end
        end
    end
end

function CityLegoBuildingUIPage_Upgrade:ConfirmTwice(time, callback)
    ModuleRefer.ConsumeModule:OpenCommonConfirmUIForLevelUpCost(time, callback)
end

function CityLegoBuildingUIPage_Upgrade:RequestUpgradeImmediately(lockable)
    self.city.furnitureManager:RequestLevelUpImmediately(self.furnitureId, self.workCfg:Id(), self.citizenId, lockable)
    return true
end

function CityLegoBuildingUIPage_Upgrade:ShowLackSpeedUpCost()
    local consumeItemCfgId = ModuleRefer.ConsumeModule:GetSpeedUpCommonItemCfg():Id()
    local remainTime = self:GetRemainTime()
    local need = ModuleRefer.ConsumeModule:CalculateFurnitureLevelUpCost(remainTime)
    local own = ModuleRefer.InventoryModule:GetAmountByConfigId(consumeItemCfgId)
    local getmoreList = {}
    if need > own then
        table.insert(getmoreList, {id = consumeItemCfgId, num = need - own})
        ModuleRefer.InventoryModule:OpenExchangePanel(getmoreList)
    end
end

function CityLegoBuildingUIPage_Upgrade:ShowLackResGetMoreWithConsume()
    local consumeItemCfgId = ModuleRefer.ConsumeModule:GetSpeedUpCommonItemCfg():Id()
    local remainTime = self:GetRemainTime()
    local extraCost = ModuleRefer.ConsumeModule:CalculateFurnitureLevelUpCost(remainTime)
    local getmoreList = {}
    local isConsumeItemUsed = false
    for i, v in ipairs(self.costItems) do
        if v.id == consumeItemCfgId then
            isConsumeItemUsed = true
        end
        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
        local need = consumeItemCfgId == v.id and (v.count + extraCost) or v.count
        if own < need then
            table.insert(getmoreList, {id = v.id, num = need - own})
        end
    end

    if not isConsumeItemUsed then
        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(consumeItemCfgId)
        local need = extraCost
        if need > own then
            table.insert(getmoreList, {id = consumeItemCfgId, num = need - own})
        end
    end

    ModuleRefer.InventoryModule:OpenExchangePanel(getmoreList)
end

function CityLegoBuildingUIPage_Upgrade:OnClickContinue(_, buttonTransform)
    self.city.cityWorkManager:StartLevelUpWork(self.furnitureId, self.workCfg:Id(), self.citizenId, buttonTransform, Delegate.GetOrCreate(self, self.TryStartGuide))
end

function CityLegoBuildingUIPage_Upgrade:OnClickContinueDisable()
    if FailureReason[FailureCode.Polluted] then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[FailureCode.Polluted]))
    end
end

function CityLegoBuildingUIPage_Upgrade:TryStartGuide()
    local guideCfgId = self.workCfg:GuideOnStart()
    if guideCfgId > 0 then
        ModuleRefer.GuideModule:CallGuide(guideCfgId)
    end
end

function CityLegoBuildingUIPage_Upgrade:OnClickSpeedUp(_, buttonTransform)
    local furniture = self.cellTile:GetCell()
    local holder = CityFurnitureUpgradeSpeedUpHolder.new(furniture)
    local itemList = ModuleRefer.CityWorkSpeedUpModule:GetItemList(furniture:GetWorkCfgId(CityWorkType.FurnitureLevelUp))
    local provider = require("CitySpeedUpGetMoreProvider").new()
    provider:SetHolder(holder)
    provider:SetItemList(itemList)
    g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
end

function CityLegoBuildingUIPage_Upgrade:OnClickSpeedUpDisable()
    if FailureReason[FailureCode.Polluted] then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[FailureCode.Polluted]))
    end
end

function CityLegoBuildingUIPage_Upgrade:OnClickHelp(_, buttonTransform)
    local furniture = self.cellTile:GetCell()
    local lvCfgId = furniture.configId
    ModuleRefer.AllianceModule:RequestAllianceHelp(buttonTransform, nil, lvCfgId, self.furnitureId, furniture:GetUpgradingWorkId())
end

function CityLegoBuildingUIPage_Upgrade:OnClickHelpDisable()
    if FailureReason[FailureCode.Polluted] then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[FailureCode.Polluted]))
    end
end

function CityLegoBuildingUIPage_Upgrade:RequestFinishUpgradeWorking()
    self.city.cityWorkManager:RequestSpeedUpWorking(self.workId)
    return true
end

function CityLegoBuildingUIPage_Upgrade:OnSpeedUpCoinChanged()
    self:UpdateProcessing() 
end

function CityLegoBuildingUIPage_Upgrade:GotoFallback(gotoId)
    ModuleRefer.GuideModule:CallGuide(gotoId)
end

return CityLegoBuildingUIPage_Upgrade
