local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")
local Utils = require("Utils")
local LuaReusedComponentPool = require("LuaReusedComponentPool")
local CityWorkFormula = require("CityWorkFormula")
local CityWorkType = require("CityWorkType")
local CityWorkUICostItemData = require("CityWorkUICostItemData")
local CityWorkI18N = require("CityWorkI18N")
local TimerUtility = require("TimerUtility")
local ConfigTimeUtility = require("ConfigTimeUtility")
local UIMediatorNames = require("UIMediatorNames")
local CityLegoBuffDifferData = require("CityLegoBuffDifferData")
local CityAttrType = require("CityAttrType")

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
    NonConstructQueue = 6,
}

local FailureReason = {
    [FailureCode.LackRes] = "sys_city_38",
    [FailureCode.SameWorkTypeFull] = "sys_city_68",
    [FailureCode.NotMeetCondition] = "sys_city_78",
    [FailureCode.Polluted] = CityWorkI18N.FAILURE_REASON_POLLUTED,
    [FailureCode.NonConstructQueue] = "toast_unlock_construct_01",
}

---@class CityWorkFurnitureUpgradeContent:BaseUIComponent
local CityWorkFurnitureUpgradeContent = class('CityWorkFurnitureUpgradeContent', BaseUIComponent)

function CityWorkFurnitureUpgradeContent:OnCreate()
    self.transform = self:Transform("")
    
    self._p_text_property_name = self:Text("p_text_property_name")
    self._p_text_property_value_old = self:Text("p_text_property_value_old")
    self._arrow = self:GameObject("arrow")
    self._p_text_property_value_new = self:Text("p_text_property_value_new")

    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickDetails))
    self._p_btn_detail:SetVisible(false)

    self._p_property_vertical = self:Transform("p_property_vertical")
    ---@see CityLegoBuffDifferCell
    self._p_table_property = self:TableViewPro("p_table_property")

    self._p_mask = self:GameObject("p_mask")
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

    self.p_upgrade_reward = self:GameObject("p_upgrade_reward")
    self.p_text_unlock = self:Text("p_text_unlock")
    self.p_text_reward_work = self:Text("p_text_reward_work")
    self.p_text_reward_recipe = self:Text("p_text_reward_recipe","citylevel_unlock_preview_recipe")
    self.p_icon_recipe = self:Image("p_icon_recipe")
    self.btn_icon_recipe = self:Button("p_icon_recipe")
    self.p_holder_recipe = self:Transform('p_holder_recipe')
    self.pool_recipe = LuaReusedComponentPool.new(self.p_icon_recipe, self.p_holder_recipe)

    self.p_text_reward_pet = self:Text("p_text_reward_pet","citylevel_unlock_preview_animal")
    self.p_holder_pet = self:Transform('p_holder_pet')
    ---@type CityWorkFurnitureUpgradePetComp
    self.p_pet = self:LuaBaseComponent("p_pet")
    self.pool_pet = LuaReusedComponentPool.new(self.p_pet, self.p_holder_pet)

    self.p_text_reward_land = self:Text("p_text_reward_land")
    self.p_img_landform = self:Image("p_img_landform")
    self.p_holder_landform = self:Transform('p_holder_landform')
    self.pool_landform = LuaReusedComponentPool.new(self.p_img_landform, self.p_holder_landform)
    self.p_btn_detail_landform = self:Button("p_btn_detail_landform", Delegate.GetOrCreate(self, self.OnClickLand))

    self.p_upgrade_reward_work = self:GameObject('p_upgrade_reward_work')
    self.p_upgrade_reward_recipe = self:GameObject('p_upgrade_reward_recipe')
    self.p_upgrade_reward_pet = self:GameObject('p_upgrade_reward_pet')
    self.p_upgrade_reward_landform = self:GameObject('p_upgrade_reward_landform')

end

---@param param CityWorkFurnitureUpgradeUIParameter
function CityWorkFurnitureUpgradeContent:OnFeedData(param)
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

function CityWorkFurnitureUpgradeContent:OnShow()
    self:AddEventListeners()
end

function CityWorkFurnitureUpgradeContent:OnHide()
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

function CityWorkFurnitureUpgradeContent:UpdateUnlockInfo()
    local level = self.lvCell:Level()
    local id = self.typCell:Id()
    local maxLevel = ConfigRefer.CityFurnitureTypes:Find(id):MaxLevel()
    for i = level, maxLevel-1 do
        local levelCfg = ConfigRefer.CityFurnitureLevel:Find(tonumber(id) + i)
        if levelCfg and levelCfg:UnlockPreviewLength()>0 then
            self.p_upgrade_reward:SetVisible(true)
            local length = levelCfg:UnlockPreviewLength()
            local petType = length > 0 and string.split(levelCfg:UnlockPreview(1), ',') or {}
            local land = length > 1 and levelCfg:UnlockPreview(2) or ""
            local cityWorkProcess = length > 2 and string.split(levelCfg:UnlockPreview(3), ',') or {}
            local slot = length > 3 and levelCfg:UnlockPreview(4) or ""
            local petPos = length > 4 and levelCfg:UnlockPreview(5) or ""

            self.p_text_unlock.text = I18N.GetWithParams("citylevel_unlock_preview",i+1)
            self.p_upgrade_reward_pet:SetVisible(#petType > 0)
            self.p_upgrade_reward_landform:SetVisible(land~="")
            self.p_upgrade_reward_recipe:SetVisible(#cityWorkProcess>0)
            self.p_upgrade_reward_work:SetVisible(slot~="" or petPos~="")

            if #petType > 0 then
                self.pool_pet:HideAll()
                for i = 1, #petType do
                    if i > 3 then
                        return
                    end
                    local param = {petTypeId = petType[i]}
                    local item = self.pool_pet:GetItem().Lua
                    item:FeedData(param)
                end
            end

            if land ~= "" then
                self.pool_landform:HideAll()
                self.landId = tonumber(land)
                local landCfg = ConfigRefer.Land:Find( self.landId)
                local sprite = landCfg:Icon()
                g_Game.SpriteManager:LoadSprite(sprite,self.pool_landform:GetItem())
                self.p_text_reward_land.text = I18N.Get(landCfg:Name())
            end

            if #cityWorkProcess > 0 then
                self.pool_recipe:HideAll()
                for i = 1, #cityWorkProcess do
                    if i > 3 then
                        return
                    end
                    local itemId = ConfigRefer.CityWorkProcess:Find(tonumber(cityWorkProcess[i])):Output()
                    if itemId > 0 then
                        local sprite= ConfigRefer.Item:Find(itemId):Icon()
                        local image = self.pool_recipe:GetItem()
                        g_Game.SpriteManager:LoadSprite(sprite,image)
                    end
                end
            end

            if slot ~="" then
                self.p_text_reward_work.text = I18N.Get("citylevel_unlock_preview_workslot")
            end

            if petPos~="" then
                self.p_text_reward_work.text = I18N.Get("citylevel_unlock_preview_team0"..petPos)
            end

            return
        end
    end
    self.p_upgrade_reward:SetVisible(false)
end


function CityWorkFurnitureUpgradeContent:UpdateBasicInfo()
    self._p_text_property_name.text = I18N.Get(self.typCell:Name())
    self._p_text_property_value_old.text = ("Lv.%d"):format(self.lvCell:Level())
    if self.nextLvCell ~= nil and self.workCfg ~= nil then
        self._p_text_property_value_new.text = ("Lv.%d"):format(self.nextLvCell:Level())
    end
    self._arrow:SetActive(self.nextLvCell ~= nil and self.workCfg ~= nil)
end

function CityWorkFurnitureUpgradeContent:UpdateProperty()
    self:UpdateUnlockInfo()
    if self.nextLvCell == nil or self.workCfg == nil then
        return self:UpdatePropertyCurrent()
    else
        return self:UpdatePropertyUpgrade()
    end
end

function CityWorkFurnitureUpgradeContent:UpdatePropertyCurrent()
    self._p_table_property:Clear()
    
    -- local typCfg = ConfigRefer.CityFurnitureTypes:Find(self.lvCell:Type())
    -- if not typCfg:HideAddScore() then
    --     self._p_table_property:AppendData({from=self.lvCell:AddScore()}, 1)
    -- end

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
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
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

    for i = 1, self.lvCell:TroopBattleAttrLength() do
        local battleGroup = self.lvCell:TroopBattleAttr(i)
        local battleValues = ModuleRefer.AttrModule:CalcAttrGroupByGroupId(battleGroup:Attr())
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

    self._p_property_vertical:SetVisible(#dataList > 0)
end

function CityWorkFurnitureUpgradeContent:UpdatePropertyUpgrade()
    self._p_table_property:Clear()

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

    for i = 1, self.lvCell:TroopBattleAttrLength() do
        local battleGroup = self.lvCell:TroopBattleAttr(i)
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

    for i = 1, self.nextLvCell:TroopBattleAttrLength() do
        local battleGroup = self.nextLvCell:TroopBattleAttr(i)
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

    self._p_property_vertical:SetVisible(#toShowList > 0 or #showExtra > 0 or #hasNewRecipe > 0)
end

function CityWorkFurnitureUpgradeContent:GetExtraInfos()
    local extraInfos = {}
    for i = 1, self.nextLvCell:NextLevelExtraUnlockInfoLength() do
        table.insert(extraInfos, I18N.Get(self.nextLvCell:NextLevelExtraUnlockInfo(i)))
    end
    return extraInfos
end

function CityWorkFurnitureUpgradeContent:GetNewRecipeInfo()
    local extraInfos = {}
    for i = 1, self.nextLvCell:NextLevelExtraUnlockInfoLength() do
        table.insert(extraInfos, I18N.Get(self.nextLvCell:NextLevelExtraUnlockInfo(i)))
    end
    return extraInfos
end

function CityWorkFurnitureUpgradeContent:UpdatePropertyStretchButton()
    local rotation = self.conditionStretch and -90 or 90
    self._p_icon_arrow.localRotation = CS.UnityEngine.Quaternion.Euler(0, 0, rotation)
end

function CityWorkFurnitureUpgradeContent:UpdateWorkingStatus()
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

function CityWorkFurnitureUpgradeContent:UpdateCondition()
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

function CityWorkFurnitureUpgradeContent:UpdateCost()
    self._p_cost_grid:SetVisible(not self._upgrading and self.nextLvCell ~= nil)
    if self._upgrading or self.nextLvCell == nil then return end

    local itemGroup = ConfigRefer.ItemGroup:Find(self.nextLvCell:LevelUpCost())
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

function CityWorkFurnitureUpgradeContent:ReleaseAllItemCountChangeListener()
    if self.inputDataList == nil then return end
    for i, v in ipairs(self.inputDataList) do
        v:ReleaseCountListener()
    end
end

function CityWorkFurnitureUpgradeContent:OnItemCountChanged()
    for i, v in ipairs(self.inputItemList) do
        v:FeedData(self.inputDataList[i])
    end
    self:UpdateProcessing()
end

function CityWorkFurnitureUpgradeContent:UpdateProcessing()
    if self._upgrading then
        self:UpdateStatusProcessing()
    elseif self.nextLvCell == nil or self.workCfg == nil then
        self:UpdateStatusNone()
    else
        self:UpdateStatusNotWork()
    end
end

function CityWorkFurnitureUpgradeContent:UpdateStatusProcessing()
    self._p_mask:SetActive(true)
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

function CityWorkFurnitureUpgradeContent:UpdateProgress()
    if self.work == nil then return end

    self._p_progress_n.fillAmount = self:GetWorkProgress()
    self._timerData.fixTime = self:GetWorkRemainTime()
    self._child_time_progress:RefreshTimeText()
    self:UpdateProgressVfxPosition()
    self:UpdateProgressComsumeButton()
end

function CityWorkFurnitureUpgradeContent:GetConsumeLevelUpPrice()
    local remainTime = self:GetRemainTime()
    return ModuleRefer.ConsumeModule:CalculateFurnitureLevelUpCost(remainTime)
end

function CityWorkFurnitureUpgradeContent:GetRemainTime()
    if self._upgrading then
        if self.work == nil then
            local levelUpInfo = self:GetLevelUpInfo()
            return levelUpInfo.TargetProgress - levelUpInfo.CurProgress
        else
            return self:GetWorkRemainTime()
        end
    else
        return self:GetLevelUpNeedTime()
    end
end

function CityWorkFurnitureUpgradeContent:GetLevelUpNeedTime()
    return self.city.furnitureManager:GetFurnitureUpgradeCostTime(self.nextLvCell)
end

function CityWorkFurnitureUpgradeContent:GetLevelUpInfo()
    local castleFurniture = self.param.source:GetCastleFurniture()
    return castleFurniture.LevelUpInfo
end

function CityWorkFurnitureUpgradeContent:GetWorkProgress()
    local levelUpInfo = self:GetLevelUpInfo()
    if levelUpInfo.TargetProgress == 0 then return 1 end

    local gap = self.city:GetWorkTimeSyncGap()
    local done = levelUpInfo.CurProgress + gap * self:GetSpeed()
    local target = levelUpInfo.TargetProgress
    return math.clamp01(done / target)
end

function CityWorkFurnitureUpgradeContent:GetWorkRemainTime()
    local gap = self.city:GetWorkTimeSyncGap()
    local levelUpInfo = self:GetLevelUpInfo()
    local efficiency = self:GetSpeed()
    local done = levelUpInfo.CurProgress + gap * efficiency
    local target = levelUpInfo.TargetProgress
    return math.max(0, (target - done) / efficiency)
end

function CityWorkFurnitureUpgradeContent:GetSpeed()
    return 1
end

function CityWorkFurnitureUpgradeContent:UpdateProgressVfxPosition()
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

function CityWorkFurnitureUpgradeContent:UpdateProgressComsumeButton()
    if not self._upgrading then return end

    self._priceButtonData = self._priceButtonData or {}
    self._priceButtonData.num1 = self:GetConsumeLevelUpPrice()
    self._priceButtonData.num2 = ModuleRefer.ConsumeModule:GetOwnedConsumeCoin()
    self._p_btn_complete:ShowCompareNumbers(self._priceButtonData)

    --- 升级中一定是满足条件的，所以此时只需要检查钱是否够用就行
    local isEnough = self:IsConsumeButtonEnabled()
    self._p_btn_complete:SetEnabled(isEnough and not self.cellTile:IsPolluted())
end

function CityWorkFurnitureUpgradeContent:IsConsumeButtonEnabled()
    local remainTime = self:GetRemainTime()
    return ModuleRefer.ConsumeModule:CanSpeedUpFurnitureLevelUpCostWithMoney(remainTime)
end

function CityWorkFurnitureUpgradeContent:UpdateStatusNone()
    self._p_mask:SetActive(false)
    self._p_progress:SetActive(false)
    self._p_bottom_btn:SetVisible(false)
end

function CityWorkFurnitureUpgradeContent:UpdateStatusNotWork()
    self._p_mask:SetActive(true)
    local errCode = self:CanUpgrade()
    --- 不满足条件时，升级按钮全部隐藏
    if errCode == FailureCode.NotMeetCondition then
        self._p_bottom_btn:SetVisible(false)
    else
        self._p_bottom_btn:SetVisible(true)
        self._p_btn_upgrade:SetVisible(true)
        local time = self:GetRemainTime()

        ---@type BistateButtonParameter
        self._buttonData = self._buttonData or {}
        self._buttonData.buttonText = I18N.Get("sys_city_25")
        self._buttonData.onClick = Delegate.GetOrCreate(self, self.OnClickStart)
        self._buttonData.disableClick = Delegate.GetOrCreate(self, self.OnClickDisable)
        self._buttonData.singleNumber = true
        self._buttonData.num1 = TimeFormatter.SimpleFormatTime(time)
        self._buttonData.icon = "sp_common_icon_time_01"
        self._p_btn_upgrade:FeedData(self._buttonData)

        self._p_btn_complete:SetVisible(time > 0)
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

function CityWorkFurnitureUpgradeContent:UpdateConditionUIStatus()
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

function CityWorkFurnitureUpgradeContent:AddEventListeners()
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

function CityWorkFurnitureUpgradeContent:RemoveEventListeners()
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

function CityWorkFurnitureUpgradeContent:CheckIfFinishedAndClaimIt()
    local levelUpInfo = self:GetLevelUpInfo()
    if levelUpInfo.Working and levelUpInfo.CurProgress >= levelUpInfo.TargetProgress then
        self.city.furnitureManager:RequestClaimFurnitureLevelUp(self.furnitureId)
    end
end

function CityWorkFurnitureUpgradeContent:OnStartWorkCallback(isSuccess, reply, rpc)
    self:UpdateWorkingStatus()
    self:UpdateCondition()
    self:UpdateCost()
    self:UpdateProcessing()
    self:UpdateConditionUIStatus()
end

function CityWorkFurnitureUpgradeContent:FullUpdate()
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

function CityWorkFurnitureUpgradeContent:OnClaimCallback(isSuccess, reply, rpc)
    if not isSuccess then return end
    if rpc.request.FurnitureId ~= self.furnitureId then return end

    if self.param:UpdateDataByFurnitureTile() then
        self:CloseParentUIMediator()
        return
    end

    self:FullUpdate()
end

function CityWorkFurnitureUpgradeContent:OnFurnitureDataChanged(city, batchEvt)
    if city ~= self.city then return end

    if batchEvt.Change[self.furnitureId] then
        self._p_hint_creep:SetActive(self.cellTile:IsPolluted())
    end
    self:UpdateProcessing()
end

function CityWorkFurnitureUpgradeContent:OnTurnToRibbonCutting(city, batchEvt)
    if city ~= self.city then return end
    
    if batchEvt.furnitureId == self.furnitureId then
        self.city.furnitureManager:RequestClaimFurnitureLevelUp(self.furnitureId)
    end
    self:UpdateProcessing()
end

function CityWorkFurnitureUpgradeContent:OnLevelUpFinished(city, batchEvt)
    if city ~= self.city then return end
    
    if not batchEvt.Change[self.furnitureId] then return end
    if self.param:UpdateDataByFurnitureTile() then
        self:CloseParentUIMediator()
        return
    end

    self:FullUpdate()
end

function CityWorkFurnitureUpgradeContent:OnCastleAttrChanged()
    self:UpdateCondition()
    self:UpdateCost()
    self:UpdateProcessing()
    self:UpdateConditionUIStatus()
end

function CityWorkFurnitureUpgradeContent:OnCastleWorkChanged(city, batchEvt)
    if city ~= self.city then return end

    if self.workId and batchEvt.Change and batchEvt.Change[self.workId] then
        self.work = self.city.cityWorkManager:GetWorkData(self.workId)
        self:UpdateProcessing()
    end
end

function CityWorkFurnitureUpgradeContent:OnWorkTimeUpdate(city, batchEvt)
    if city ~= self.city then return end

    if self._upgrading then
        self:UpdateProgress()
    end
end

function CityWorkFurnitureUpgradeContent:CanUpgrade()
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

    if not self.meetCondition then
        return FailureCode.NotMeetCondition
    end

    local maxCount = self.city.furnitureManager:GetUpgradeQueueMaxCount()
    if maxCount == 0 then
        return FailureCode.NonConstructQueue
    end

    local needTime = self:GetLevelUpNeedTime()
    if needTime > 0 then
        local upgradingCount = self.city.cityWorkManager:GetWorkingCountByType(self.workCfg:Type())
        if upgradingCount >= maxCount then
            return FailureCode.SameWorkTypeFull
        end
    end

    for i, v in ipairs(self.costItems) do
        if ModuleRefer.InventoryModule:GetAmountByConfigId(v.id) < v.count then
            return FailureCode.LackRes
        end
    end

    return 0
end

function CityWorkFurnitureUpgradeContent:CanUpgradeWithConsume()
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

    if not self.meetCondition then
        return FailureCode.NotMeetCondition
    end

    local maxCount = self.city.furnitureManager:GetUpgradeQueueMaxCount()
    if maxCount == 0 then
        return FailureCode.NonConstructQueue
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

function CityWorkFurnitureUpgradeContent:OnClickConditionStretch()
    self.conditionStretch = not self.conditionStretch
    self:UpdateProperty()
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.transform)
end

function CityWorkFurnitureUpgradeContent:OnClickStart(_, buttonTransform)
    local failureCode = self:CanUpgrade()
    if failureCode == FailureCode.LackRes then
        self:ShowLackResGetMore()
    elseif failureCode == FailureCode.SameWorkTypeFull then
        self:ShowUpgradePopupUI()
    elseif failureCode == FailureCode.Success then
        if self.nextLvCell and self:GetRemainTime() == 0 then
            self:RequestUpgradeImmediately(buttonTransform)
        else
            self.city.cityWorkManager:StartLevelUpWork(self.furnitureId, self.workCfg:Id(), self.citizenId, buttonTransform, function(isSuccess)
                if not isSuccess then return end
                self:TryStartGuide()
                self.city.furnitureManager:CreateUpgradePetCountdownTimeU2D(self.furnitureId)
            end)
        end
    end
end

function CityWorkFurnitureUpgradeContent:ShowLackResGetMore()
    local getmoreList = {}
    for i, v in ipairs(self.costItems) do
        local own = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
        if own < v.count then
            table.insert(getmoreList, {id = v.id, num = v.count - own})
        end
    end
    ModuleRefer.InventoryModule:OpenExchangePanel(getmoreList)
end

function CityWorkFurnitureUpgradeContent:OnClickDisable()
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

function CityWorkFurnitureUpgradeContent:ShowUpgradePopupUI()
    g_Game.UIManager:Open(UIMediatorNames.CityWorkFurnitureUpgradePopupUIMediator, self.city)
end

function CityWorkFurnitureUpgradeContent:OnClickFinishImmediately()
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

        if failureCode == FailureCode.NonConstructQueue then
            ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[failureCode]))
            return
        end

        local basicEnabled = failureCode == FailureCode.Success
        local isEnough = self:IsConsumeButtonEnabled()
        if basicEnabled and isEnough then
            local remainTime = self:GetRemainTime()
            self:ConfirmTwice(remainTime, Delegate.GetOrCreate(self, self.RequestUpgradeImmediately))
        elseif not isEnough then
            ModuleRefer.ConsumeModule:GotoShop()
        else
            if FailureReason[failureCode] then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[failureCode]))
            end
        end
    end
end

function CityWorkFurnitureUpgradeContent:ConfirmTwice(time, callback)
    ModuleRefer.ConsumeModule:OpenCommonConfirmUIForLevelUpCost(time, callback)
end

function CityWorkFurnitureUpgradeContent:RequestUpgradeImmediately(lockable)
    self.city.furnitureManager:RequestLevelUpImmediately(self.furnitureId, self.workCfg:Id(), self.citizenId, lockable)
    return true
end

function CityWorkFurnitureUpgradeContent:ShowLackSpeedUpCost()
    ModuleRefer.ConsumeModule:GotoShop()
end

function CityWorkFurnitureUpgradeContent:ShowLackResGetMoreWithConsume()
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

function CityWorkFurnitureUpgradeContent:OnClickContinue(_, buttonTransform)
    self.city.cityWorkManager:StartLevelUpWork(self.furnitureId, self.workCfg:Id(), self.citizenId, buttonTransform, Delegate.GetOrCreate(self, self.TryStartGuide))
end

function CityWorkFurnitureUpgradeContent:OnClickContinueDisable()
    if FailureReason[FailureCode.Polluted] then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[FailureCode.Polluted]))
    end
end

function CityWorkFurnitureUpgradeContent:TryStartGuide()
    local guideCfgId = self.workCfg:GuideOnStart()
    if guideCfgId > 0 then
        ModuleRefer.GuideModule:CallGuide(guideCfgId)
    end
end

function CityWorkFurnitureUpgradeContent:OnClickSpeedUp(_, buttonTransform)
    local furniture = self.cellTile:GetCell()
    local holder = CityFurnitureUpgradeSpeedUpHolder.new(furniture)
    local itemList = ModuleRefer.CityWorkSpeedUpModule:GetItemList(furniture:GetWorkCfgId(CityWorkType.FurnitureLevelUp))
    local provider = require("CitySpeedUpGetMoreProvider").new()
    provider:SetHolder(holder)
    provider:SetItemList(itemList)
    g_Game.UIManager:Open(UIMediatorNames.UseResourceMediator, provider)
end

function CityWorkFurnitureUpgradeContent:OnClickSpeedUpDisable()
    if FailureReason[FailureCode.Polluted] then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[FailureCode.Polluted]))
    end
end

function CityWorkFurnitureUpgradeContent:OnClickHelp(_, buttonTransform)
    local furniture = self.cellTile:GetCell()
    local lvCfgId = furniture.configId
    ModuleRefer.AllianceModule:RequestAllianceHelp(buttonTransform, nil, lvCfgId, self.furnitureId, furniture:GetUpgradingWorkId())
end

function CityWorkFurnitureUpgradeContent:OnClickHelpDisable()
    if FailureReason[FailureCode.Polluted] then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(FailureReason[FailureCode.Polluted]))
    end
end

function CityWorkFurnitureUpgradeContent:RequestFinishUpgradeWorking()
    self.city.cityWorkManager:RequestSpeedUpWorking(self.workId)
    return true
end

function CityWorkFurnitureUpgradeContent:OnSpeedUpCoinChanged()
    self:UpdateProcessing() 
end

function CityWorkFurnitureUpgradeContent:GotoFallback(gotoId)
    ModuleRefer.GuideModule:CallGuide(gotoId)
end

function CityWorkFurnitureUpgradeContent:CloseParentUIMediator()
    local uiMediator = self:GetParentBaseUIMediator()
    if uiMediator then
        uiMediator:CloseSelf()
    end
end

function CityWorkFurnitureUpgradeContent:OnClickLand()
    g_Game.UIManager:Open(UIMediatorNames.LandformIntroUIMediator,{entryLandCfgId = self.landId})
end

return CityWorkFurnitureUpgradeContent
