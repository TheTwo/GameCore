---Scene Name : scene_construction_process
local BaseUIMediator = require ('BaseUIMediator')
local CastleAssignProcessPlanParameter = require('CastleAssignProcessPlanParameter')
local CityWorkProcessWdsHelper = require('CityWorkProcessWdsHelper')
local Delegate = require('Delegate')
local CityWorkProcessUIUnitData = require("CityWorkProcessUIUnitData")
local NumberFormatter = require("NumberFormatter")
local EventConst = require("EventConst")
local HUDLogicPartDefine = require("HUDLogicPartDefine")
local CityWorkFormula = require("CityWorkFormula")
local Utils = require("Utils")
local DBEntityPath = require("DBEntityPath")
local CityWorkHelper = require("CityWorkHelper")
local CityWorkProcessUIUnitBubbleData = require("CityWorkProcessUIUnitBubbleData")
local CastleCitizenAssignProcessWorkParameter = require("CastleCitizenAssignProcessWorkParameter")
local ConfigRefer = require("ConfigRefer")
local ConfigTimeUtility = require("ConfigTimeUtility")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local CityWorkType = require("CityWorkType")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local CityWorkI18N = require("CityWorkI18N")
local UIMediatorNames = require("UIMediatorNames")

---@class CityWorkProcessUIMediator:BaseUIMediator
local CityWorkProcessUIMediator = class('CityWorkProcessUIMediator', BaseUIMediator)

local NormalPreferHeight = 344
local FurniturePreferHeight = 524

function CityWorkProcessUIMediator:OnCreate()
    self._p_btn_exit = self:Button("p_btn_exit", Delegate.GetOrCreate(self, self.OnClickExit))
    self._p_focus_target = self:Transform("p_focus_target")

    ---@type CityFurnitureConstructionProcessCitizenBlock
    self._p_resident_root = self:LuaObject("p_resident_root")
    self._p_icon_efiiciency = self:Image("p_icon_efiiciency")
    self._p_btn_efficiency = self:Button("p_btn_efficiency", Delegate.GetOrCreate(self, self.OnClickGear))
    self._p_text_efficiency = self:Text("p_text_efficiency")

    ---@type CityWorkUIBuffItem
    self._p_btn_buff_1 = self:LuaObject("p_btn_buff_1")
    ---@type CityWorkUIBuffItem
    self._p_btn_buff_2 = self:LuaObject("p_btn_buff_2")
    ---@type CityWorkUIBuffItem
    self._p_btn_buff_3 = self:LuaObject("p_btn_buff_3")

    self._p_table = self:TableViewPro("p_table")
    self._p_hint = self:GameObject("p_hint")
    self._p_text_hint = self:Text("p_text_hint", "sys_city_28")

    self._p_name = self:GameObject("p_name")
    self._p_text_furniture_name = self:Text("p_text_furniture_name")
    self._p_btn_detail = self:Button("p_btn_detail", Delegate.GetOrCreate(self, self.OnClickBtnDetail))
    ---@see CityWorkProcessUIRecipeItem
    self._p_table_process = self:TableViewPro("p_table_process")

    self._p_pollution = self:GameObject("p_pollution")
    self._p_text_pollution = self:Text("p_text_pollution", CityWorkI18N.UIHint_CityWorkProcess_FurniturePolluted)

    self._p_text_item = self:Text("p_text_item")
    self._p_text_num = self:Text("p_text_num")
    self._p_text_desc = self:Text("p_text_desc")

    self._base_table = self:BindComponent("base_table", typeof(CS.UnityEngine.UI.LayoutElement))
    ---@type CityWorkProcessUIRecipeDetailsPanel
    self._p_tips_item_produce = self:LuaObject("p_tips_item_produce")

    self._p_base_empty = self:GameObject("p_base_empty")
    self._p_text_empty = self:Text("p_text_empty", "sys_city_29")

    ---@type CityWorkProcessUIUnitBubble
    self._p_btn_bubble = self:LuaObject("p_btn_bubble")
    self._p_btn_bubble:SetVisible(false)
    
    self._vx_trigger = self:AnimTrigger("vx_trigger")
end

---@param param CityWorkProcessUIParameter
function CityWorkProcessUIMediator:OnOpened(param)
    self.param = param
    self.cellTile = self.param.source
    self.city = param:GetCity()
    self.workCfg = param:GetWorkCfg()
    self.furnitureId = self.cellTile:GetCell().singleId
    ---@type CityProcessConfigCell
    self.selectedRecipe = nil
    ---@type CityWorkProcessUIUnitData[]
    self.unitDataCaches = {}
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.ConstructionColor)
    self.cellTile:SetSelected(true)

    self._p_tips_item_produce:GetDataFromMediator()
    g_Game.SpriteManager:LoadSprite(self.city.cityWorkManager:GetWorkBuffIconForCitizen(self.workCfg), self._p_icon_efiiciency)
    self._p_pollution:SetActive(self.cellTile:IsPolluted())

    self:ConfirmRecipeIsMakingFurniture()
    self:UpdateWorkingStatus()
    self:UpdateAutoStatus()
    self:InitCitizenComponent()
    self:UpdateWorkAttributes()
    self:UpdateRecipesTable()
    self:UpdateRecipeDetailsPanel()
    self:UpdateQueueTableNew()
    self:MoveCameraToFocusTarget()
    self:AddEventListeners()
    self:AutoSelectFirstRecipe()
    self:HideHud()
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
end

function CityWorkProcessUIMediator:OnClose(param)
    self.cellTile:SetSelected(false)
    self.city.outlineController:ChangeOutlineColor(self.city.outlineController.OtherColor)
    g_Game.EventManager:TriggerEvent(EventConst.CITY_BUBBLE_STATE_CHANGE)
    self:RecoverHud()
    self:RemoveEventListeners()
    self:RecoverCamera()
end

function CityWorkProcessUIMediator:AddEventListeners()
    g_Game.EventManager:AddListener(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    g_Game.EventManager:AddListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_FURNITURE_STORAGE_COUNT_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureStorageCountChanged))
    g_Game.ServiceManager:AddResponseCallback(CastleAssignProcessPlanParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnAssignCallback))
    g_Game.ServiceManager:AddResponseCallback(CastleCitizenAssignProcessWorkParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnMemberChanged))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.Castle.LastWorkUpdateTime.MsgPath, Delegate.GetOrCreate(self, self.OnTimeUpdate))
end

function CityWorkProcessUIMediator:RemoveEventListeners()
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnFurnitureDataChanged))
    g_Game.EventManager:RemoveListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_FURNITURE_STORAGE_COUNT_CHANGE, Delegate.GetOrCreate(self, self.OnFurnitureStorageCountChanged))
    g_Game.ServiceManager:RemoveResponseCallback(CastleAssignProcessPlanParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnAssignCallback))
    g_Game.ServiceManager:RemoveResponseCallback(CastleCitizenAssignProcessWorkParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnMemberChanged))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.Castle.LastWorkUpdateTime.MsgPath, Delegate.GetOrCreate(self, self.OnTimeUpdate))
end

function CityWorkProcessUIMediator:HideHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.inCityOnlyShowRes, false)
end

function CityWorkProcessUIMediator:RecoverHud()
    g_Game.EventManager:TriggerEvent(EventConst.HUD_LOGIC_SHOW_HIDE_CHANGE, HUDLogicPartDefine.inCityOnlyShowRes, true)
end

function CityWorkProcessUIMediator:UpdateWorkingStatus()
    self.isWorking = false
    local castleFurniture = self.cellTile:GetCastleFurniture()
    for _, v in ipairs(castleFurniture.ProcessInfo) do
        if v.LeftNum > 0 or v.Auto then
            self.isWorking = true
            return
        end
    end
end

function CityWorkProcessUIMediator:UpdateAutoStatus()
    self.isAuto = false
    local castleFurniture = self.cellTile:GetCastleFurniture()
    for _, v in ipairs(castleFurniture.ProcessInfo) do
        if v.Auto then
            self.isAuto = true
            return
        end
    end
end

function CityWorkProcessUIMediator:ConfirmRecipeIsMakingFurniture()
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

function CityWorkProcessUIMediator:HasCitizenWorking()
    local workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.Process] or 0
    local workData = self.city.cityWorkManager:GetWorkData(workId)
    return workData ~= nil and workData.CitizenId ~= 0
end

function CityWorkProcessUIMediator:InitCitizenComponent()
    self._p_resident_root:SetVisible(true)
    if not self:HasCitizenWorking() then
        if self.param.autoAssignFreeCitizen then
            local pos = self.cellTile:GetWorldCenter()
            local freeCitizen = self.city.cityCitizenManager:GetFreeCitizen(pos)
            if freeCitizen then
                self.citizenId = freeCitizen._data._id
            end
        else
            self.citizenId = nil
        end
    else
        local workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.Process] or 0
        local workData = self.city.cityWorkManager:GetWorkData(workId)
        self.citizenId = workData.CitizenId
    end

    ---@type CityFurnitureConstructionProcessCitizenBlockData
    self._citizenCompData = self._citizenCompData or {}
    self._citizenCompData.citizenId = self.citizenId
    self._citizenCompData.workCfgId = self.workCfg:Id()
    self._citizenCompData.citizenMgr = self.city.cityCitizenManager
    self._citizenCompData.onSelectedChanged = Delegate.GetOrCreate(self, self.OnCitizenChanged)
    self._p_resident_root:FeedData(self._citizenCompData)
end

function CityWorkProcessUIMediator:OnCitizenChanged(citizenId)
    --- 选的同一个人，直接返回
    if citizenId == self.citizenId then
        return true
    end
    
    local workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.Process] or 0
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
                        if not isSuccess then return end
                        self:SelectCitizen(citizenId)
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
                if workId > 0 then
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
            --- 制造数据中有存盘数据
            if self.isWorking then
                --- 正在进行中
                if workId > 0 then
                    self.city.cityWorkManager:AttachCitizenToWork(workId, citizenId)
                --- 制造暂停了，重新开始这个工作
                else
                    self.city.cityWorkManager:StartWorkImp(self.furnitureId, self.workCfg:Id(), citizenId, 0)
                end
            end
        end
    end
    
    self:SelectCitizen(citizenId)
    return true
end

function CityWorkProcessUIMediator:SelectCitizen(citizenId)
    self._citizenCompData.citizenId = citizenId
    self._p_resident_root:FeedData(self._citizenCompData)
    self.citizenId = citizenId
    self:UpdateWorkAttributes()
    self:UpdateRecipeDetailsPanel()
    self:UpdateQueueTableNew()

    self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom2)
    if self.citizenId ~= nil then
        self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom3)
    end
end

function CityWorkProcessUIMediator:OnCitizenDataRefresh(city, needRefreshCitizenId)
    if self.city ~= city then return end
    
    if self.citizenId == nil then return end
    if needRefreshCitizenId[self.citizenId] then
        self._p_resident_root:FeedData(self._citizenCompData)
    end
end

function CityWorkProcessUIMediator:UpdateWorkAttributes()
    --- 强度显示
    local power = CityWorkFormula.GetWorkPower(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    local citizenPower = self.city.cityWorkManager:GetWorkBuffValueFromCitizenId(self.param.workCfg, self.citizenId)
    if citizenPower > 0 then
        self._p_text_efficiency.text = string.format("%.0f(%s)", (power - citizenPower), NumberFormatter.WithSign(citizenPower))
    else
        self._p_text_efficiency.text = string.format("%.0f", power)
    end

    --- 效率加成显示
    local efficiency = CityWorkFormula.GetWorkEfficiency(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    local originEfficiency = CityWorkFormula.GetWorkEfficiency(self.param.workCfg, nil, self.furnitureId, nil)
    self._p_btn_buff_1:SetVisible(efficiency ~= 0)
    if efficiency ~= 0 then
        local total, other, citizen = CityWorkHelper.GetBuffPercentItemDescStringForI18NParams(efficiency, originEfficiency)
        self._p_btn_buff_1:FeedData({desc = NumberFormatter.PercentWithSignSymbol(efficiency), tip = I18N.GetWithParams("sys_city_70", total, citizen, other)})
    end

    --- 消耗减少显示
    local costDecrease = CityWorkFormula.GetCostDecrease(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    local originCostDecrease = CityWorkFormula.GetCostDecrease(self.param.workCfg, nil, self.furnitureId, nil)
    self._p_btn_buff_2:SetVisible(costDecrease ~= 0)
    if costDecrease ~= 0 then
        local total, other, citizen = CityWorkHelper.GetBuffPercentItemDescStringForI18NParams(costDecrease, originCostDecrease)
        self._p_btn_buff_2:FeedData({desc = NumberFormatter.PercentWithSignSymbol(costDecrease), tip = I18N.GetWithParams("sys_city_71", total, citizen, other)})
    end

    --- 产出增加显示
    local outputIncrease = CityWorkFormula.GetOutputIncrease(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    local originOutputIncrease = CityWorkFormula.GetOutputIncrease(self.param.workCfg, nil, self.furnitureId)
    self._p_btn_buff_3:SetVisible(outputIncrease ~= 0)
    if outputIncrease ~= 0 then
        local total, other, citizen = CityWorkHelper.GetBuffPercentItemDescStringForI18NParams(outputIncrease, originOutputIncrease)
        self._p_btn_buff_3:FeedData({desc = NumberFormatter.PercentWithSignSymbol(outputIncrease), tip = I18N.GetWithParams("sys_city_72", total, citizen, other)})
    end
end

function CityWorkProcessUIMediator:UpdateRecipesTable()
    self._p_text_furniture_name.text = self.cellTile:GetName()
    
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

function CityWorkProcessUIMediator:GetPrefabIndex()
    return self.isMakingFurniture and 1 or 0
end

function CityWorkProcessUIMediator:TryMakeRecipesFullFillAtLeastTwoLine(srcArray)
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

function CityWorkProcessUIMediator:UpdateRecipeDetailsPanel()
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

function CityWorkProcessUIMediator:GetSelectRecipeOutputFurnitureLvCfgId(recipe)
    return self.city.cityWorkManager:GetProcessRecipeOutputFurnitureLvCfgId(recipe)
end

function CityWorkProcessUIMediator:AutoSelectFirstRecipe()
    if self.firstRecipe then
        g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_WORK_PROCESS_SELECT_RECIPE, self.firstRecipe)
        self.firstRecipe = nil
    end
end

function CityWorkProcessUIMediator:UpdateQueueTable()
    local castle = self.city:GetCastle()
    local castleFurniture = castle.CastleFurniture[self.furnitureId]
    if castleFurniture == nil then return end

    local processInfo = castleFurniture.ProcessInfo
    if processInfo == nil then return end

    local working, inqueue, finished = CityWorkProcessWdsHelper.GetWorking_InQueue_FinishedPart(processInfo)
    local oldWorkingUid = self.working ~= nil and self.working.Uid or -1
    local newWorkingUid = working ~= nil and working.Uid or -1
    if oldWorkingUid ~= newWorkingUid and newWorkingUid ~= -1 and oldWorkingUid ~= -1 then
        self:CreateAnimFromInqueueToWorking(working, self.inqueue)
    end
    self.processInfo = processInfo
    self.working = working
    self.inqueue = inqueue
    self.finished = finished

    self:UpdateQueueTableImp()
end

function CityWorkProcessUIMediator:UpdateQueueTableNew()
    self.isWorking = false
    self.processInfo = nil
    local castle = self.city:GetCastle()
    local castleFurniture = castle.CastleFurniture[self.furnitureId]
    if castleFurniture == nil then return end

    local processInfo = castleFurniture.ProcessInfo
    if processInfo == nil then return end

    self.processInfo = processInfo
    self._p_hint:SetVisible(false)

    local queueCount = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if queueCount == 0 then return end

    local working, inqueue, finished = CityWorkProcessWdsHelper.GetWorking_InQueue_FinishedPart(processInfo)
    self.isWorking = working ~= nil
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

function CityWorkProcessUIMediator:UpdateQueueTableImp()
    self._p_hint:SetVisible(false)
    self._p_table:Clear()

    local queueCount = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if queueCount == 0 then return end

    local showQueueCount = queueCount
    if self.working ~= nil then
        showQueueCount = showQueueCount - 1
    end

    local idx = 0
    for _, v in ipairs(self.inqueue) do
        idx = idx + 1
        if idx <= showQueueCount then
            if self.unitDataCaches[idx] == nil then
                self.unitDataCaches[idx] = CityWorkProcessUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId))
            end
            self.unitDataCaches[idx]:SetInQueue(v)
            self._p_table:AppendData(self.unitDataCaches[idx])
        else --- 超过数量时说明数据有误，直接跳出
            return
        end
    end

    for _, v in ipairs(self.finished) do
        idx = idx + 1
        if idx <= showQueueCount then
            if self.unitDataCaches[idx] == nil then
                self.unitDataCaches[idx] = CityWorkProcessUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId))
            end
            self.unitDataCaches[idx]:SetFinished(v)
            self._p_table:AppendData(self.unitDataCaches[idx])
        else --- 超过数量时说明数据有误，直接跳出
            return
        end
    end

    for i = 1, showQueueCount - idx do
        if self.unitDataCaches[idx + i] == nil then
            self.unitDataCaches[idx + i] = CityWorkProcessUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId))
        end
        self.unitDataCaches[idx + i]:SetFree()
        self._p_table:AppendData(self.unitDataCaches[idx + i])
    end
end

function CityWorkProcessUIMediator:UpdateBubble()
    self._bubbleData = self._bubbleData or CityWorkProcessUIUnitBubbleData.new()
    self._bubbleData:SetFree()
    -- local castle = self.city:GetCastle()
    -- local castleFurniture = castle.CastleFurniture[self.furnitureId]
    -- if castleFurniture == nil then return end

    -- local processInfo = castleFurniture.ProcessInfo
    -- if processInfo == nil then return end

    -- for i, v in ipairs(processInfo) do
    --     if v.LeftNum ~= 0 then
    --         --- 遇到第一个正在制造种的Process时，就不再显示完成的Process
    --         self._bubbleData:SetWorking(v)
    --         break
    --     end
    -- end

    -- self._p_btn_bubble:FeedData(self._bubbleData)
    self._p_btn_bubble:SetVisible(false)
end

---@param entity wds.CastleBrief
function CityWorkProcessUIMediator:OnTimeUpdate(entity, _)
    if self.city.uid ~= entity.ID then return end
    if self._bubbleData then
        self._p_btn_bubble:FeedData(self._bubbleData)
    end
end

---@param newProcess wds.CastleProcess
---@param oldInQueue wds.CastleProcess[]
function CityWorkProcessUIMediator:CreateAnimFromInqueueToWorking(newProcess, oldInQueue)
    self._vx_trigger:PlayAll(CS.FpAnimation.CommonTriggerType.Custom1)
end

function CityWorkProcessUIMediator:CollectSingleProcess(process, lockable)
    if process == nil or self.processInfo == nil then return end

    local idx = table.indexof(self.processInfo, process)
    if idx <= 0 then return end

    self.city.cityWorkManager:RequestCollectProcessLike(self.furnitureId, idx-1, self.workCfg:Id(), lockable, Delegate.GetOrCreate(self, self.SimpleErrorOverride))
end

function CityWorkProcessUIMediator:SimpleErrorOverride(msgId, errorCode, jsonTable)
    self:InitCitizenComponent()
    self:UpdateWorkAttributes()
    self:UpdateRecipesTable()
    self:UpdateRecipeDetailsPanel()
    self:UpdateQueueTableNew()
    self:UpdateBubble()
end

function CityWorkProcessUIMediator:MoveCameraToFocusTarget()
    local uiCamera = g_Game.UIManager:GetUICamera()
    if Utils.IsNull(uiCamera) then return end

    local basicCamera = self.city:GetCamera()
    if basicCamera == nil then return end

    local viewport = uiCamera:WorldToViewportPoint(self._p_focus_target.position)
    local tileView = self.cellTile.tileView
    local mainAssets = tileView and tileView:GetMainAssets()
    ---@type CityTileAsset
    local asset = next(mainAssets or {})
    if asset then
        local flag, pos = asset:TryGetAnchorPos()
        self.cameraStackHandle = basicCamera:ZoomToWithFocusStack(basicCamera:GetMinSize(), viewport, pos, 0.5)
    else
        self.cameraStackHandle = basicCamera:ZoomToWithFocusStack(basicCamera:GetMinSize(), viewport, self.cellTile:GetWorldCenter(), 0.5)
    end
end

function CityWorkProcessUIMediator:RecoverCamera()
    if self.cameraStackHandle then
        self.cameraStackHandle:back()
        self.cameraStackHandle = nil
    end
end

---点击左上方退出按钮
function CityWorkProcessUIMediator:OnClickExit()
    self:CloseSelf()
end

---点击左侧齿轮按钮
function CityWorkProcessUIMediator:OnClickGear()
    ---@type TextToastMediatorParameter
    if not self.toastData then
        self.toastData = {}
        self.toastData.clickTransform = self._p_btn_efficiency.transform
    end
    local power = CityWorkFormula.GetWorkPower(self.workCfg, nil, self.furnitureId, self.citizenId)
    self.toastData.content = I18N.GetWithParams("sys_city_16", power)
    ModuleRefer.ToastModule:ShowTextToast(self.toastData)
end

---点击右侧建筑名旁的详情按钮
function CityWorkProcessUIMediator:OnClickBtnDetail()
    
end

function CityWorkProcessUIMediator:OnRecipeSelected(recipe)
    self.selectedRecipe = recipe
    self:UpdateRecipeDetailsPanel()
end

---@param reply wrpc.CastleAssignProcessPlanReply
---@param rpc rpc.CastleAssignProcessPlan
function CityWorkProcessUIMediator:OnAssignCallback(isSuccess, reply, rpc)
    self:UpdateRecipeDetailsPanel()
    if isSuccess then
        self:UpdateQueueTableNew()
        self:UpdateBubble()
    end
end

function CityWorkProcessUIMediator:OnMemberChanged(isSuccess, reply, rpc)
    if not isSuccess then
        self:InitCitizenComponent()
        self:UpdateWorkAttributes()
        self:UpdateRecipesTable()
        self:UpdateRecipeDetailsPanel()
        self:UpdateQueueTableNew()
        self:UpdateBubble()
    end
end

---@param city City
function CityWorkProcessUIMediator:OnFurnitureDataChanged(city, batchEvt)
    if city ~= self.city then return end

    if batchEvt.Remove[self.furnitureId] then
        self:CloseSelf()
        return
    end

    if batchEvt.Change[self.furnitureId] then
        local castleFurniture = self.city:GetCastle().CastleFurniture[self.furnitureId]
        if self.param.lvCfgId ~= castleFurniture.ConfigId then
            self:CloseSelf()
            return
        end
        g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_WORK_PROCESS_QUEUE_MAY_CHANGED)
        self._p_pollution:SetActive(self.cellTile:IsPolluted())
        self:UpdateWorkingStatus()
        self:UpdateAutoStatus()
        self:UpdateQueueTableNew()
        self:UpdateBubble()
        self._p_tips_item_produce:GetDataFromMediator()
        self._p_tips_item_produce:UpdateButtonState()
    end
end

function CityWorkProcessUIMediator:GetActiveQueueCount()
    local castle = self.city:GetCastle()
    local castleFurniture = castle.CastleFurniture[self.furnitureId]
    if castleFurniture == nil then return 0 end

    local processInfo = castleFurniture.ProcessInfo
    if processInfo == nil then return 0 end

    return processInfo:Count()
end

function CityWorkProcessUIMediator:GetCurrentRecipeProgress()
    local castle = self.city:GetCastle()
    local castleFurniture = castle.CastleFurniture[self.furnitureId]
    local process = self._bubbleData.process
    return CityWorkProcessWdsHelper.GetCityWorkProcessProgress(castleFurniture, process)
end

function CityWorkProcessUIMediator:GetCurrentRecipeRemainTime()
    local process = self._bubbleData.process
    return CityWorkProcessWdsHelper.GetCityWorkProcessRemainTime(self.city, process)
end

---@param process wds.CastleProcess
---@param lockable CS.UnityEngine.RectTransform
function CityWorkProcessUIMediator:RequestRemoveInQueue(process, lockable)
    if process == nil then return end
    local castle = self.city:GetCastle()
    local castleFurniture = castle.CastleFurniture[self.furnitureId]
    if castleFurniture == nil then return end

    local processInfo = castleFurniture.ProcessInfo
    local index = table.indexof(processInfo, process)
    if index <= 0 then return end

    self.city.cityWorkManager:RemoveProcessWork(self.furnitureId, index-1, self.workCfg:Id(), self.citizenId, lockable)
end

function CityWorkProcessUIMediator:CanAddOrChangeCitizen()
    return not self.isWorking or self.citizenId == nil
end

function CityWorkProcessUIMediator:OnCastleAttrChanged()
    self:UpdateWorkAttributes()
    self:UpdateRecipeDetailsPanel()
end

function CityWorkProcessUIMediator:OnFurnitureStorageCountChanged(city, lvMap, typMap)
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

return CityWorkProcessUIMediator