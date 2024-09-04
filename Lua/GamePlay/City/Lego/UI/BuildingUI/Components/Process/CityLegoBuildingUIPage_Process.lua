local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityWorkFormula = require("CityWorkFormula")
local CityWorkType = require("CityWorkType")
local NumberFormatter = require("NumberFormatter")
local CityWorkI18N = require("CityWorkI18N")
local CityWorkProcessWdsHelper = require("CityWorkProcessWdsHelper")
local CityWorkProcessUIUnitData = require("CityWorkProcessUIUnitData")
local EventConst = require("EventConst")
local CastleAssignProcessPlanParameter = require("CastleAssignProcessPlanParameter")
local CastleCitizenAssignProcessWorkParameter = require("CastleCitizenAssignProcessWorkParameter")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local UIMediatorNames = require("UIMediatorNames")

local I18N = require("I18N")
local NormalPreferHeight = 344
local FurniturePreferHeight = 524

---@class CityLegoBuildingUIPage_Process:BaseUIComponent
local CityLegoBuildingUIPage_Process = class('CityLegoBuildingUIPage_Process', BaseUIComponent)

function CityLegoBuildingUIPage_Process:OnCreate()
    ---@see CityWorkProcessUIRecipeItem
    ---@see CityWorkProcessUIRecipeFurnitureItem
    self._p_table_process = self:TableViewPro("p_table_process")

    self._p_text_item = self:Text("p_text_item")
    self._p_text_num = self:Text("p_text_num")
    self._p_text_desc = self:Text("p_text_desc")

    self._base_table = self:BindComponent("base_table", typeof(CS.UnityEngine.UI.LayoutElement))
    ---@type CityWorkProcessUIRecipeDetailsPanel
    self._p_tips_item_produce = self:LuaObject("p_tips_item_produce")
    self._p_base_empty = self:GameObject("p_base_empty")
    self._p_text_empty = self:Text("p_text_empty", "sys_city_29")

    self._p_buff_1 = self:GameObject("p_buff_1")
    self._p_icon_1 = self:Image("p_icon_1")
    self._p_text_1 = self:Text("p_text_1")

    self._p_buff_2 = self:GameObject("p_buff_2")
    self._p_icon_2 = self:Image("p_icon_2")
    self._p_text_2 = self:Text("p_text_2")

    self._p_buff_3 = self:GameObject("p_buff_3")
    self._p_icon_3 = self:Image("p_icon_3")
    self._p_text_3 = self:Text("p_text_3")

    self._mask_table = self:GameObject("mask_table")
    self._p_table = self:TableViewPro("p_table")

    self._p_hint = self:GameObject("p_hint")
end

---@param param CityWorkProcessUIParameter
function CityLegoBuildingUIPage_Process:OnFeedData(param)
    self.param = param
    self.cellTile = self.param.source
    self.city = param:GetCity()
    self.workCfg = param:GetWorkCfg()
    self.furnitureId = self.cellTile:GetCell().singleId
    ---@type CityProcessConfigCell
    self.selectedRecipe = nil
    ---@type CityWorkProcessUIUnitData[]
    self.unitDataCaches = {}
    self._p_tips_item_produce.uiMediator = self
    self._p_tips_item_produce:GetDataFromMediator()
    self.showAuto = self.workCfg:IsAuto()
    self:ConfirmRecipeIsMakingFurniture()
    self:UpdateWorkingStatus()
    self:UpdateAutoStatus()
    self:InitCitizenStatus()
    self:UpdateWorkAttributes()
    self:UpdateRecipesTable()
    self:UpdateRecipeDetailsPanel()
    self:UpdateQueueTableNew()
    self:AutoSelectFirstRecipe()
end

---@param comp CityLegoBuildingFurnitureWorkComp
function CityLegoBuildingUIPage_Process:AgentFurnitureWorkComp(comp)
    self.workComp = comp
    if self.workComp.furniture then
        self.workComp:ReleaseLastFurnitureData()
    end

    self.workComp._p_resident_root:SetVisible(true)
    self.workComp._p_produce:SetActive(false)
    self.workComp._p_group_produce_num:SetActive(false)
    self.workComp._p_group_produce_time:SetActive(false)
    self.workComp._p_resident_root:FeedData(self.citizenBlockData)
end

function CityLegoBuildingUIPage_Process:OnShow()
    self:AddEventListeners()
end

function CityLegoBuildingUIPage_Process:OnHide()
    self:RemoveEventListeners()
    self._p_table:Clear()
end

function CityLegoBuildingUIPage_Process:OnClose()
    self:OnHide()
end

function CityLegoBuildingUIPage_Process:ConfirmRecipeIsMakingFurniture()
    self.isMakingFurniture = false

    local recipes = self.param:GetRecipes()
    if #recipes == 0 then return end

    local recipe = recipes[1]
    local output = ConfigRefer.ItemGroup:Find(recipe:Output())
    if output == nil then return end
    if output:ItemGroupInfoListLength() == 0 then return end

    local firstItemInfo = output:ItemGroupInfoList(1)
    local itemId = firstItemInfo:Items()

    if itemId == 0 then return end
    
    if ModuleRefer.CityConstructionModule:IsFurnitureRelativeItem(itemId) then
        self.isMakingFurniture = true
    end
end

function CityLegoBuildingUIPage_Process:UpdateWorkingStatus()
    self.isWorking = false
    self.workId, self.workData = 0, nil
    local castleFurniture = self.cellTile:GetCastleFurniture()
    for _, v in ipairs(castleFurniture.ProcessInfo) do
        if v.LeftNum > 0 or v.Auto then
            self.isWorking = true
            self.workId = castleFurniture.WorkType2Id[CityWorkType.Process]
            self.workData = self.city.cityWorkManager:GetWorkData(self.workId)
            return
        end
    end
end

function CityLegoBuildingUIPage_Process:UpdateAutoStatus()
    self.isAuto = false
    local castleFurniture = self.cellTile:GetCastleFurniture()
    for _, v in ipairs(castleFurniture.ProcessInfo) do
        if v.Auto then
            self.isAuto = true
            return
        end
    end
end

function CityLegoBuildingUIPage_Process:InitCitizenStatus()
    if not self:HasCitizenWorking() then
        if not self.isWorking then
            local citizenId = self:GetParentBaseUIMediator():GetBestFreeCitizenForWork(self.workCfg)
            if citizenId then
                self.citizenId = citizenId
            end
        end
    else
        self.citizenId = self.workData.CitizenId
    end

    ---@type CityFurnitureConstructionProcessCitizenBlockData
    self.citizenBlockData = self.citizenBlockData or {}
    self.citizenBlockData.citizenId = self.citizenId
    self.citizenBlockData.citizenMgr = self.city.cityCitizenManager
    self.citizenBlockData.workCfgId = self.workCfg:Id()
    self.citizenBlockData.onSelectedChanged = Delegate.GetOrCreate(self, self.OnCitizenSelectedChanged)
end

function CityLegoBuildingUIPage_Process:HasCitizenWorking()
    return self.isWorking and self.workData ~= nil and self.workData.CitizenId ~= 0
end

function CityLegoBuildingUIPage_Process:OnCitizenSelectedChanged(citizenId)
    if citizenId == self.citizenId then
        return true
    end

    local workId = self.workId
    --- 卸掉居民
    if citizenId == nil then
        if workId > 0 then
            --- 当前工作必须要人
            if not self.workCfg:AllowNoCitizen() then
                ---@type CommonConfirmPopupMediatorParameter
                local param = {}
                param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
                param.title = I18N.Get(CityWorkI18N.NotAllowCitizen_RemoveCitizen_Title)
                param.content = I18N.Get(CityWorkI18N.NotAllowCitizen_RemoveCitizen_Content)
                param.onConfirm = function()
                    ---确认后卸掉居民
                    self.city.cityWorkManager:DetachCitizenFromWork(workId, nil, function(isSuccess)
                        if isSuccess then
                            self:SelectCitizen(citizenId)
                            g_Game.UIManager:CloseByName(UIMediatorNames.CityFurnitureOverviewUIMediator)
                        end
                    end)
                    return true
                end
                g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
                return true
            else
                self.city.cityWorkManager:DetachCitizenFromWork(workId)
            end
        end
    else
        local citizenWorkData = self.city.cityWorkManager:GetCitizenWorkDataByCitizenId(citizenId)
        --- 选的其他居民有工作，确认后会卸载对方工作
        if citizenWorkData ~= nil then
            ---@type CommonConfirmPopupMediatorParameter
            local param = {}
            param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
            param.title = I18N.Get(CityWorkI18N.RemoveOtherCitizen_Title)
            param.content = I18N.Get(CityWorkI18N.RemoveOtherCitizen_Content)
            param.onConfirm = function()
                if workId ~= nil and workId > 0 then
                    self.city.cityWorkManager:AttachCitizenToWork(workId, citizenId, nil, function(cmd, isSuccess)
                        if not isSuccess then return end
                        self:SelectCitizen(citizenId)
                    end)
                else
                    if self.isWorking then
                        self.city.cityWorkManager:StartWorkImp(self.furnitureId, self.workCfg:Id(), citizenId, 0, nil, function(cmd, isSuccess)
                            if not isSuccess then return end
                            self:SelectCitizen(citizenId)
                        end)
                    else
                        self.city.cityWorkManager:DetachCitizenFromWork(citizenWorkData._id, nil, function(cmd, isSuccess)
                            if not isSuccess then return end
                            self:SelectCitizen(citizenId)
                        end)
                    end
                end
                return true
            end
            g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
            return true
        --- 选的其他居民没有工作
        else
            --- 采集数据中有存盘数据
            if self.isWorking then
                --- 正在进行中
                if workId > 0 then
                    self.city.cityWorkManager:AttachCitizenToWork(workId, citizenId)
                --- 采集暂停了，重新开始这个工作
                else
                    self.city.cityWorkManager:StartWorkImp(self.furnitureId, self.workCfg:Id(), citizenId, 0)
                end
            end
        end
    end

    self:SelectCitizen(citizenId)
    return true
end

function CityLegoBuildingUIPage_Process:SelectCitizen(citizenId)
    self.citizenId = citizenId
    self.citizenBlockData.citizenId = citizenId
    if self.workComp then
        self.workComp._p_resident_root:FeedData(self.citizenBlockData)
    end
    self:UpdateWorkAttributes()
    self:UpdateRecipeDetailsPanel()
    self:UpdateQueueTableNew()
end

function CityLegoBuildingUIPage_Process:UpdateWorkAttributes()
    --- 消耗减少显示
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

    -- local difficulty = self.selectedRecipe ~= nil and self.selectedRecipe:Difficulty() or 0
    -- --- 耗时减少
    -- local timeDecrease = math.clamp01(1 - CityWorkFormula.CalculateTimeCostDecrease(self.param.workCfg, difficulty, nil, self.furnitureId, self.citizenId))
    -- self._p_buff_3:SetVisible(timeDecrease ~= 0)
    -- if timeDecrease ~= 0 then
    --     g_Game.SpriteManager:LoadSprite("sp_comp_icon_hero_tab", self._p_icon_3)
    --     self._p_text_3.text = NumberFormatter.PercentWithSignSymbol(timeDecrease)
    -- end
end

function CityLegoBuildingUIPage_Process:UpdateRecipesTable()
    ---@type {recipe:CityProcessConfigCell, isEmpty:boolean}[]
    local recipesTableDataSrc = {}
    for i, v in ipairs(self.param:GetRecipes()) do
        if self.city.cityWorkManager:IsProcessVisible(v) then
            table.insert(recipesTableDataSrc, {recipe = v, isEmpty = false, uiMediator = self})
        end
    end

    self._base_table.preferredHeight = self.isMakingFurniture and FurniturePreferHeight or NormalPreferHeight
    self:TryMakeRecipesFullFillAtLeastTwoLine(recipesTableDataSrc)
    self._p_table_process:Clear()
    local prefabIndex = self:GetPrefabIndex()
    for _, v in ipairs(recipesTableDataSrc) do
        self._p_table_process:AppendData(v, prefabIndex)
        if self.isMakingFurniture then
            if v.isEmpty then
                self._p_table_process:AppendCellCustomName("empty")
            else
                self._p_table_process:AppendCellCustomName(tostring(v.recipe:Id()))
            end
        end
    end

    self.firstRecipe = recipesTableDataSrc[1] and recipesTableDataSrc[1].recipe or nil
    self.recipesTableDataSrc = recipesTableDataSrc
end

function CityLegoBuildingUIPage_Process:TryMakeRecipesFullFillAtLeastTwoLine(srcArray)
    local prefabIndex = self:GetPrefabIndex()
    local oneLineCellCount = self._p_table_process:GetCountInOneLine(prefabIndex)
    if oneLineCellCount < 0 then return end

    local srcArrayCount = #srcArray
    if srcArrayCount <= oneLineCellCount * 2 then
        for i = srcArrayCount + 1, oneLineCellCount * 2 do
            table.insert(srcArray, {isEmpty = true})
        end
        return
    end

    local remainCount = srcArrayCount % oneLineCellCount
    if remainCount == 0 then return end

    for i = remainCount + 1, oneLineCellCount do
        table.insert(srcArray, {isEmpty = true})
    end
end

function CityLegoBuildingUIPage_Process:GetPrefabIndex()
    return self.isMakingFurniture and 1 or 0
end

function CityLegoBuildingUIPage_Process:UpdateRecipeDetailsPanel()
    local selected = self.selectedRecipe ~= nil
    self._p_tips_item_produce:SetVisible(selected)
    self._p_base_empty:SetActive(not selected)

    if selected then
        self._p_tips_item_produce:FeedData(self.selectedRecipe)
    end

    self._p_text_item.text = self.selectedRecipe ~= nil and I18N.Get(self.selectedRecipe:Name()) or string.Empty
    self._p_text_desc.text = self.selectedRecipe ~= nil and I18N.Get(self.selectedRecipe:Description()) or string.Empty

    if self.isMakingFurniture then
        local lvCfgId = self:GetSelectRecipeOutputFurnitureLvCfgId(self.selectedRecipe)
        local canProcessCount, reachVersionLimit = self.city.furnitureManager:GetFurnitureCanProcessCount(lvCfgId)

        if selected then
            self._p_text_num:SetVisible(canProcessCount > 0 and self.city.cityWorkManager:IsProcessEffective(self.selectedRecipe))
        else
            self._p_text_num:SetVisible(false)
        end

        if canProcessCount > 0 then
            self._p_text_num.text = I18N.GetWithParams(CityWorkI18N.UIHint_CityWorkProcess_FurnitureCanProcessCount, canProcessCount)
        end
    else
        self._p_text_num:SetVisible(false)
    end
end

function CityLegoBuildingUIPage_Process:GetSelectRecipeOutputFurnitureLvCfgId(recipe)
    return self.city.cityWorkManager:GetProcessRecipeOutputFurnitureLvCfgId(recipe)
end

function CityLegoBuildingUIPage_Process:UpdateQueueTableNew()
    self.processInfo = nil
    self._mask_table:SetActive(not self.showAuto)
    local castle = self.city:GetCastle()
    local castleFurniture = castle.CastleFurniture[self.furnitureId]
    if castleFurniture == nil then return end

    local processInfo = castleFurniture.ProcessInfo
    if processInfo == nil then return end

    self.processInfo = processInfo
    self._p_hint:SetVisible(false)

    if self.showAuto then return end

    local queueCount = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if queueCount == 0 then return end

    local working, inqueue, finished = CityWorkProcessWdsHelper.GetWorking_InQueue_FinishedPart(processInfo)
    local processCount = processInfo:Count()
    for i = 1, queueCount do
        local isNew = self.unitDataCaches[i] == nil
        if isNew then
            self.unitDataCaches[i] = CityWorkProcessUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId), self)
        end

        if i <= processCount then
            local process = processInfo[i]
            if process.LeftNum == 0 and not process.Auto then
                self.unitDataCaches[i]:SetFinished(process)
            else
                if process == working then
                    self.unitDataCaches[i]:SetWorking(process)
                else
                    self.unitDataCaches[i]:SetInQueue(process)
                end
            end
        else
            if self.isAuto then
                self.unitDataCaches[i]:SetForbid()
            else
                self.unitDataCaches[i]:SetFree()
            end
        end

        if isNew then
            self._p_table:AppendData(self.unitDataCaches[i])
        else
            self._p_table:UpdateChild(self.unitDataCaches[i])
        end
    end
end

function CityLegoBuildingUIPage_Process:AddEventListeners()
    g_Game.EventManager:AddListener(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    g_Game.EventManager:AddListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_STORAGE_COUNT_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureStorageCountChanged))
    g_Game.ServiceManager:AddResponseCallback(CastleAssignProcessPlanParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnAssignCallback))
    g_Game.ServiceManager:AddResponseCallback(CastleCitizenAssignProcessWorkParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnMemberChanged))
end

function CityLegoBuildingUIPage_Process:RemoveEventListeners()
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_STORAGE_COUNT_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureStorageCountChanged))
    g_Game.ServiceManager:RemoveResponseCallback(CastleAssignProcessPlanParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnAssignCallback))
    g_Game.ServiceManager:RemoveResponseCallback(CastleCitizenAssignProcessWorkParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnMemberChanged))
end

function CityLegoBuildingUIPage_Process:AutoSelectFirstRecipe()
    if self.firstRecipe then
        g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, self.firstRecipe)
        self:OnRecipeSelected(self.firstRecipe)
        self.firstRecipe = nil
    end
end

function CityLegoBuildingUIPage_Process:OnRecipeSelected(recipe)
    if not self.param then return end
    self.selectedRecipe = recipe
    self:UpdateWorkAttributes()
    self:UpdateRecipeDetailsPanel()
end

function CityLegoBuildingUIPage_Process:OnCitizenDataRefresh(city, needRefreshCitizenId)
    if not self.param then return end
    if self.city ~= city then return end
    
    if self.citizenId == nil then return end
    if needRefreshCitizenId[self.citizenId] then
        self:UpdateWorkingStatus()
        self:UpdateAutoStatus()
    end
end

function CityLegoBuildingUIPage_Process:OnFurnitureDataChanged(city, batchEvt)
    if not self.param then return end
    if city ~= self.city then return end

    if batchEvt.Remove[self.furnitureId] then
        self:GetParentBaseUIMediator():FurnitureRemoved()
        return
    end

    if batchEvt.Change[self.furnitureId] then
        local castleFurniture = self.city:GetCastle().CastleFurniture[self.furnitureId]
        if self.param.lvCfgId ~= castleFurniture.ConfigId then
            self:GetParentBaseUIMediator():ProcessReopen()
            return
        end
        g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_WORK_PROCESS_QUEUE_MAY_CHANGED)
        self:UpdateWorkingStatus()
        self:UpdateAutoStatus()
        self:UpdateQueueTableNew()
        self._p_tips_item_produce:GetDataFromMediator()
        self._p_tips_item_produce:UpdateButtonState()
    end
end

function CityLegoBuildingUIPage_Process:OnCastleAttrChanged()
    if not self.param then return end
    self:UpdateWorkAttributes()
    self:UpdateRecipeDetailsPanel()
end

function CityLegoBuildingUIPage_Process:OnFurnitureStorageCountChanged(city, lvMap, typMap)
    if not self.param then return end
    if not self.isMakingFurniture then return end
    if self.city ~= city then return end
    if self.selectedRecipe == nil then return end
    
    local output = ConfigRefer.ItemGroup:Find(self.selectedRecipe:Output())
    local firstItemInfo = output:ItemGroupInfoList(1)
    local itemId = firstItemInfo:Items()
    local lvCfgId = ModuleRefer.CityConstructionModule:GetFurnitureRelative(itemId)
    if lvCfgId > 0 and lvMap[lvCfgId] == true then
        for _, v in ipairs(self.recipesTableDataSrc) do
            if v.recipe == self.selectedRecipe then
                self._p_table_process:UpdateChild(v)
                break
            end
        end
    end

    self:UpdateRecipeDetailsPanel()
end

function CityLegoBuildingUIPage_Process:OnAssignCallback(isSuccess, reply, rpc)
    if not self.param then return end
    self:UpdateRecipeDetailsPanel()
    if isSuccess then
        self:UpdateQueueTableNew()
    end
end

function CityLegoBuildingUIPage_Process:OnMemberChanged(isSuccess, reply, rpc)
    if not self.param then return end
    if not isSuccess then
        self:UpdateWorkAttributes()
        self:UpdateRecipesTable()
        self:UpdateRecipeDetailsPanel()
        self:UpdateQueueTableNew()
    end
end

function CityLegoBuildingUIPage_Process:GetActiveQueueCount()
    local castle = self.city:GetCastle()
    local castleFurniture = castle.CastleFurniture[self.furnitureId]
    if castleFurniture == nil then return 0 end

    local processInfo = castleFurniture.ProcessInfo
    if processInfo == nil then return 0 end

    return processInfo:Count()
end

---@param process wds.CastleProcess
---@param lockable CS.UnityEngine.RectTransform
function CityLegoBuildingUIPage_Process:RequestRemoveInQueue(process, lockable)
    if process == nil then return end
    local castle = self.city:GetCastle()
    local castleFurniture = castle.CastleFurniture[self.furnitureId]
    if castleFurniture == nil then return end

    local processInfo = castleFurniture.ProcessInfo
    local index = table.indexof(processInfo, process)
    if index <= 0 then return end

    self.city.cityWorkManager:RemoveProcessWork(self.furnitureId, index-1, self.workCfg:Id(), self.citizenId, lockable)
end

function CityLegoBuildingUIPage_Process:CollectSingleProcess(process, lockable)
    if process == nil or self.processInfo == nil then return end

    local idx = table.indexof(self.processInfo, process)
    if idx <= 0 then return end

    self.city.cityWorkManager:RequestCollectProcessLike(self.furnitureId, idx-1, self.workCfg:Id(), lockable, Delegate.GetOrCreate(self, self.SimpleErrorOverride))
end

function CityLegoBuildingUIPage_Process:SimpleErrorOverride()
    self:InitCitizenStatus()
    self:UpdateWorkAttributes()
    self:UpdateRecipesTable()
    self:UpdateRecipeDetailsPanel()
    self:UpdateQueueTableNew()
end

return CityLegoBuildingUIPage_Process