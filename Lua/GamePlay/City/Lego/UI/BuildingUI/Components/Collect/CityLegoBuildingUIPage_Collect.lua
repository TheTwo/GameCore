local BaseUIComponent = require ('BaseUIComponent')
local CityWorkCollectUIUnitData = require('CityWorkCollectUIUnitData')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CityWorkType = require("CityWorkType")
local CityWorkFormula = require("CityWorkFormula")
local CityWorkCollectWdsHelper = require("CityWorkCollectWdsHelper")
local NumberFormatter = require("NumberFormatter")
local EventConst = require("EventConst")
local CityUtils = require("CityUtils")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local CityWorkI18N = require("CityWorkI18N")
local UIMediatorNames = require("UIMediatorNames")

local I18N = require("I18N")
local UIHelper = require("UIHelper")
local ModuleRefer = require("ModuleRefer")
local CantStartReason = {"sys_city_3", "sys_city_4", "sys_city_5", "sys_city_6", "sys_city_7", "sys_city_8", "toast_gatherworklimited", "toast_needcitizen"}

---@class CityLegoBuildingUIPage_Collect:BaseUIComponent
local CityLegoBuildingUIPage_Collect = class('CityLegoBuildingUIPage_Collect', BaseUIComponent)

function CityLegoBuildingUIPage_Collect:OnCreate()
    self._statusRecordParent = self:StatusRecordParent("")
    self._p_text_building_name = self:Text("p_text_building_name")
    
    ---@see CityWorkCollectUIRecipeItem
    self._p_table_item = self:TableViewPro("p_table_item")

    self._p_group_quantity = self:GameObject("p_group_quantity")
    self._p_text_select = self:Text("p_text_select", "sys_city_12")
    self._p_text_input_quantity = self:Text("p_text_input_quantity")
    self._p_input_box_click = self:InputField("p_input_box_click", nil, nil, Delegate.GetOrCreate(self, self.OnSubmit))
    ---@type CommonNumberSlider
    self._p_set_num_bar = self:LuaObject("p_set_num_bar")
    self._p_text_max = self:Text("p_text_max", "sys_city_22")
    self._p_btn_max = self:Button("p_btn_max", Delegate.GetOrCreate(self, self.OnClickSliderMax))

    self._p_bottom_btn = self:GameObject("p_bottom_btn")

    self._p_group_auto = self:GameObject("p_group_auto")
    --- 自动勾选根节点
    self._p_toggle = self:GameObject("p_toggle")
    self._p_btn_pading = self:Button("p_btn_pading", Delegate.GetOrCreate(self, self.OnClickAuto))
    self._p_status_n = self:GameObject("p_status_n")
    self._p_status_select = self:GameObject("p_status_select")
    self._p_text_auto = self:Text("p_text_auto", "sys_city_48")
    self._vx_trigger = self:GameObject("vx_trigger")

    --- 手动部分
    self._p_group_normal = self:GameObject("p_group_normal")
    self._child_comp_btn_b_l = self:Button("child_comp_btn_b_l", Delegate.GetOrCreate(self, self.OnClickStart))
    self._p_text = self:Text("p_text", "sys_city_14")
    self._p_number_bl = self:GameObject("p_number_bl")
    self._p_number_bl:SetActive(false)
    self._p_icon_item_bl = self:Image("p_icon_item_bl")
    self._p_text_num_green_bl = self:Text("p_text_num_green_bl")
    self._p_text_num_red_bl = self:Text("p_text_num_red_bl")
    self._p_text_num_wilth_bl = self:Text("p_text_num_wilth_bl")
    ---@type CommonTimer
    self._child_time = self:LuaObject("child_time")
    self._child_time:SetVisible(false)

    --- buff部分
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
    
    ---@type CityFurnitureConstructionProcessCitizenBlock
    self._p_resident_root = self:LuaObject("p_resident_root")
end

---@param param CityWorkCollectUIParameter
function CityLegoBuildingUIPage_Collect:OnFeedData(param)
    self.param = param
    self.city = self.param.city
    self.cellTile = self.param.source
    self.workCfg = self.param.workCfg
    self.furnitureId = self.cellTile:GetCell().singleId
    self.citizenId = nil
    ---@type CityWorkCollectUIUnitData[]
    self.unitDataCaches = {}
    ---@type table<number, ItemConfigCell[]>
    self.outputCache = {}
    self._p_text_building_name.text = I18N.Get(self.workCfg:Name())

    self.showAuto = self.workCfg:IsAuto()
    self:InitWorkStatus()
    self:InitAutoStatus()
    self:InitCitizenStatus()
    self:UpdateWorkAttributes()
    self._statusRecordParent:ApplyStatusRecord(0)
    self:InitRecipeTable()
    self:UpdateWorkingQueue()
    self:DefaultSelectFirst()
end

function CityLegoBuildingUIPage_Collect:OnShow()
    self:AddEventListener()    
end

function CityLegoBuildingUIPage_Collect:OnHide()
    self:RemoveEventListener()
end

function CityLegoBuildingUIPage_Collect:OnClose()
    self:OnHide()
end

function CityLegoBuildingUIPage_Collect:InitWorkStatus()
    self:UpdateIsWorking()
    if self.isWorking then
        self.workId = self.cellTile:GetCastleFurniture().WorkType2Id[CityWorkType.FurnitureResCollect] or 0
        self.workData = self.city.cityWorkManager:GetWorkData(self.workId)
    else
        self.workId, self.workData = 0, nil
    end
end

function CityLegoBuildingUIPage_Collect:UpdateIsWorking()
    local castleFurniture = self.cellTile:GetCastleFurniture()
    for i, v in ipairs(castleFurniture.FurnitureCollectInfo) do
        if not v.Finished then
            self.isWorking = true
            return
        end
    end
    self.isWorking = false
end

function CityLegoBuildingUIPage_Collect:InitAutoStatus()
    self.isAuto = false
    local castleFurniture = self.cellTile:GetCastleFurniture()
    for i, v in ipairs(castleFurniture.FurnitureCollectInfo) do
        if v.Auto then
            self.isAuto = true
            return
        end
    end
end

function CityLegoBuildingUIPage_Collect:InitCitizenStatus()
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
    self._p_resident_root:FeedData(self.citizenBlockData)
end

function CityLegoBuildingUIPage_Collect:HasCitizenWorking()
    return self.isWorking and self.workData ~= nil and self.workData.CitizenId ~= 0
end

function CityLegoBuildingUIPage_Collect:OnCitizenSelectedChanged(citizenId)
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

function CityLegoBuildingUIPage_Collect:SelectCitizen(citizenId)
    self.citizenId = citizenId
    self.citizenBlockData.citizenId = citizenId
    self._p_resident_root:FeedData(self.citizenBlockData)
    self:UpdateWorkAttributes()
    self:UpdateButtonStatus()
end

function CityLegoBuildingUIPage_Collect:UpdateWorkAttributes()
    --- 消耗减少显示
    local costDecrease = CityWorkFormula.GetCostDecrease(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    self._p_buff_1:SetVisible(costDecrease ~= 0)
    if costDecrease ~= 0 then
        g_Game.SpriteManager:LoadSprite("sp_common_icon_time_01", self._p_icon_1)
        self._p_text_1.text = NumberFormatter.PercentWithSignSymbol(costDecrease)
    end

    --- 产出增加显示
    local outputIncrease = CityWorkFormula.GetOutputIncrease(self.param.workCfg, nil, self.furnitureId, self.citizenId)
    self._p_buff_2:SetVisible(outputIncrease ~= 0)
    if outputIncrease ~= 0 then
        g_Game.SpriteManager:LoadSprite("sp_comp_icon_set", self._p_icon_2)
        self._p_text_2.text = NumberFormatter.PercentWithSignSymbol(outputIncrease)
    end

    local difficulty = self._select and self._select.recipe:Difficulty() or 0
    --- 耗时减少
    local timeDecrease = math.clamp01(1 - CityWorkFormula.CalculateTimeCostDecrease(self.param.workCfg, difficulty, nil, self.furnitureId, self.citizenId))
    self._p_buff_3:SetVisible(timeDecrease ~= 0)
    if timeDecrease ~= 0 then
        g_Game.SpriteManager:LoadSprite("sp_comp_icon_hero_tab", self._p_icon_3)
        self._p_text_3.text = NumberFormatter.PercentWithSignSymbol(timeDecrease)
    end
end

function CityLegoBuildingUIPage_Collect:InitRecipeTable()
    ---@type table<number, CityWorkCollectUIRecipeData|CityWorkCollectUIRecipeSubData>
    self.recipesTableDataSrc = {}
    for i, v in ipairs(self.param:GetRecipes()) do
        local resType = v:CollectResType()
        local count = self:GetResCountByType(resType)
        local subData = self:GetExpandedSubData(resType)
        table.insert(self.recipesTableDataSrc, {recipe = v, resType = resType, count = count, subData = subData, uiMediator = self})
    end

    self._p_table_item:Clear()
    for i, v in ipairs(self.recipesTableDataSrc) do
        self._p_table_item:AppendData(v, 0)
    end
end

function CityLegoBuildingUIPage_Collect:GetResCountByType(resType)
    return self.city.elementManager:GetElementResourceCountByType(resType)
end

---@return CityWorkCollectUIRecipeSubData
function CityLegoBuildingUIPage_Collect:GetExpandedSubData(resType)
    local data = {}
    data.eleResArray = CityUtils.GetElementResourceCfgsByType(resType)
    data.expanded = false
    return data
end

function CityLegoBuildingUIPage_Collect:UpdateWorkingQueue()
    self._mask_table:SetActive(not self.showAuto)
    if self.showAuto then return end

    local castleFurniture = self.cellTile:GetCastleFurniture()
    local collectInfoArray = castleFurniture.FurnitureCollectInfo
    self.collecting, self.inqueue, self.finished = CityWorkCollectWdsHelper.GetCollecting_InQueue_FinishedPart(collectInfoArray)

    local queueCount = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if queueCount == 0 then return end

    local collectCount = collectInfoArray:Count()
    for i = 1, queueCount do
        local isNew = self.unitDataCaches[i] == nil
        if isNew then
            self.unitDataCaches[i] = CityWorkCollectUIUnitData.new(self.city.furnitureManager:GetFurnitureById(self.furnitureId), self)
        end

        if i <= collectCount then
            local info = collectInfoArray[i]
            if info == self.collecting then
                self.unitDataCaches[i]:SetWorking(info)
            elseif info.Finished then
                self.unitDataCaches[i]:SetFinished(info)
            else
                self.unitDataCaches[i]:SetInQueue(info)
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

function CityLegoBuildingUIPage_Collect:AddEventListener()
    g_Game.EventManager:AddListener(EventConst.UI_CITY_COLLECT_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnCastleFurnitureChanged))
    g_Game.EventManager:AddListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnElementCountChange))
    g_Game.EventManager:AddListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
end

function CityLegoBuildingUIPage_Collect:RemoveEventListener()
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_FURNITURE_UPDATE, Delegate.GetOrCreate(self, self.OnCastleFurnitureChanged))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:RemoveListener(EventConst.UI_CITY_COLLECT_SELECT_RECIPE, Delegate.GetOrCreate(self, self.OnRecipeSelected))
    g_Game.EventManager:RemoveListener(EventConst.CITY_BATCH_WDS_CASTLE_ELEMENT_UPDATE, Delegate.GetOrCreate(self, self.OnElementCountChange))
    g_Game.EventManager:RemoveListener(EventConst.CASTLE_ATTR_UPDATE, Delegate.GetOrCreate(self, self.OnCastleAttrChanged))
end

---@param data CityWorkCollectUIRecipeData
function CityLegoBuildingUIPage_Collect:OnRecipeSelected(data)
    if not self.param then return end
    if data == nil or data.recipe == nil then return end

    self._select = data
    self.times = nil
    self._statusRecordParent:ApplyStatusRecord(1)
    self:UpdateWorkAttributes()
    self:UpdateQuantitySlider()
    self:UpdateButtonStatus()
end

function CityLegoBuildingUIPage_Collect:UpdateQuantitySlider()
    if self.showAuto then return end

    local maxTimes = CityWorkFormula.GetQueueCapacity(self.workCfg, nil, self.furnitureId, self.citizenId)
    local realMaxTimes = math.min(self._select.count, maxTimes)
    self.times = realMaxTimes > 0 and 1 or 0
    ---@type CommonNumberSliderData
    self.sliderData = self.sliderData or {}
    self.sliderData.maxNum = maxTimes
    self.sliderData.minNum = realMaxTimes > 0 and 1 or 0
    self.sliderData.curNum = realMaxTimes > 0 and 1 or 0
    self.sliderData.callBack = Delegate.GetOrCreate(self, self.OnSliderValueChanged)
    self._p_set_num_bar:FeedData(self.sliderData)
    self._p_input_box_click.text = tostring(self.times)
    self._p_text_input_quantity.text = ("/%d"):format(maxTimes)
end

function CityLegoBuildingUIPage_Collect:UpdateButtonStatus()
    self._p_group_auto:SetActive(self.showAuto)
    self._p_group_normal:SetActive(not self.showAuto)
    self._p_group_quantity:SetActive(not self.showAuto)

    self.cantStartReason = self:GetButtonStatus()
    self.canStart = self.cantStartReason == 0
    if self.showAuto then
        self._p_status_n:SetActive(not self.isAuto)
        self._p_status_select:SetActive(self.isAuto)
        self._vx_trigger:SetActive(self.isAuto)
    else
        if not self.isAuto then
            UIHelper.SetGray(self._child_comp_btn_b_l.gameObject, not self.canStart)
        end
    end
end

function CityLegoBuildingUIPage_Collect:GetButtonStatus()
    local queueCount = CityWorkFormula.GetQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if queueCount == 0 then
        return 1
    end

    local activeQueue = self.cellTile:GetCastleFurniture().FurnitureCollectInfo:Count()
    if activeQueue >= queueCount then
        return 2
    end

    if not self._select then return 3 end
    if self._select.count <= 0 then return 4 end

    if self.times ~= nil then
        if self.times <= 0 then return 5 end
    end
    
    local castleFurniture = self.cellTile:GetCastleFurniture()
    local collectType = CityWorkType.FurnitureResCollect
    local workData = self.city.cityWorkManager:GetWorkData(castleFurniture.WorkType2Id[collectType])
    if castleFurniture.WorkType2Id[collectType] ~= nil and workData ~= nil and workData.ConfigId ~= self.workCfg:Id() then
        return 6
    end

    local sameWorkTypeCount = self.city.cityWorkManager:GetWorkingCountByType(self.workCfg:Type())
    local maxSameWorkTypeCount = CityWorkFormula.GetTypeMaxQueueCount(self.workCfg, nil, self.furnitureId, self.citizenId)
    if sameWorkTypeCount >= maxSameWorkTypeCount then
        return 7
    end

    if not self.workCfg:AllowNoCitizen() and self.citizenId == nil then
        return 8
    end

    return 0
end

function CityLegoBuildingUIPage_Collect:OnCitizenDataRefresh(city, needRefreshCitizenId)
    if not self.param then return end
    if self.city ~= city then return end
    
    if self.citizenId == nil then return end
    if needRefreshCitizenId[self.citizenId] then
        self:InitWorkStatus()
        -- self._p_resident_root:FeedData(self.citizenBlockData)
        -- self._p_btn_resident_root:FeedData(self.citizenBlockData)
    end
end

function CityLegoBuildingUIPage_Collect:OnCastleFurnitureChanged(city, batchEvt)
    if not self.param then return end
    if city ~= self.city then return end

    if batchEvt.Remove[self.furnitureId] then
        self:GetParentBaseUIMediator():FurnitureRemoved()
        return
    end

    if batchEvt.Change[self.furnitureId] then
        local castleFurniture = self.city:GetCastle().CastleFurniture[self.furnitureId]
        if castleFurniture.ConfigId ~= self.param.lvCfgId then
            self:GetParentBaseUIMediator():CollectReopen()
            return
        end
        self:UpdateIsWorking()
        self:InitAutoStatus()
        self:UpdateWorkingQueue()
        self:UpdateButtonStatus()
    end
end

function CityLegoBuildingUIPage_Collect:OnElementCountChange(evtInfo)
    if not self.param then return end
    if not self.recipesTableDataSrc then return end

    for i, v in ipairs(self.recipesTableDataSrc) do
        v.count = self:GetResCountByType(v.resType)
        ---@type CityWorkCollectUIRecipeItem
        local cell = self._p_table_item:LuaGetCell(i-1)
        if cell ~= nil and cell.IsMainCell and cell:IsMainCell() then
            cell:UpdateCount()
        end
    end

    self:UpdateButtonStatus()
end

function CityLegoBuildingUIPage_Collect:OnCastleAttrChanged()
    if not self.param then return end
    self:UpdateWorkAttributes()
    self:UpdateButtonStatus()
end

function CityLegoBuildingUIPage_Collect:OnClickSliderMax()
    local maxTimes = CityWorkFormula.GetQueueCapacity(self.workCfg, nil, self.furnitureId, self.citizenId)
    local maxCount = maxTimes
    if self._select then
        maxCount = math.min(self._select.count, maxTimes)
    end
    self._p_set_num_bar:ChangeCurNum(maxCount)
    self:OnSliderValueChanged(maxCount)
end

function CityLegoBuildingUIPage_Collect:OnSliderValueChanged(count)
    self._p_input_box_click.text = tostring(count)

    self.times = count
    self.sliderData.curNum = count
    self:UpdateButtonStatus()
end

function CityLegoBuildingUIPage_Collect:OnClickStart(lockable, isAuto)
    if not self.canStart then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get(CantStartReason[self.cantStartReason]))
        return
    end

    if lockable == nil then
        lockable = self._child_comp_btn_b_l.transform
    end

    if isAuto == nil then
        isAuto = self.isAuto
    end

    self.city.cityWorkManager:StartCollectWork(self.workCfg:Id(), self.furnitureId, self.citizenId or 0, self._select.recipe:Id(), self.times, isAuto, lockable
        ,Delegate.GetOrCreate(self, self.TryStartGuide)
        ,Delegate.GetOrCreate(self, self.OnSimpleError))
end

function CityLegoBuildingUIPage_Collect:TryStartGuide()
    local guideCfgId = self.workCfg:GuideOnStart()
    if guideCfgId > 0 then
        ModuleRefer.GuideModule:CallGuide(guideCfgId)
    end
end

function CityLegoBuildingUIPage_Collect:OnSimpleError(msgId, errorCode, jsonTable)
    if errorCode == 46016 then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("sys_city_79"))
    end
end

function CityLegoBuildingUIPage_Collect:OnClickAuto()
    if not self.isAuto then
        self:OnClickStart(self._p_btn_pading.transform, true)
    else
        self:RequestRemoveAutoCollect(self._p_btn_pading.transform)
    end
end

function CityLegoBuildingUIPage_Collect:RequestRemoveAutoCollect(lockable)
    local castleFurniture = self.cellTile:GetCastleFurniture()
    for i, v in ipairs(castleFurniture.FurnitureCollectInfo) do
        if v.Auto then
            self.city.cityWorkManager:RemoveCollectProcess(self.furnitureId, i-1, lockable)
            return
        end
    end
end

function CityLegoBuildingUIPage_Collect:RequestCollect(info, lockable)
    local infos = self.cellTile:GetCastleFurniture().FurnitureCollectInfo
    local index = table.indexof(infos, info)
    if index <= 0 then return end

    self.city.cityWorkManager:RequestCollectProcessLike(self.furnitureId, index-1, self.workCfg:Id(), lockable)
end

function CityLegoBuildingUIPage_Collect:RequestCancel(info, lockable)
    local infos = self.cellTile:GetCastleFurniture().FurnitureCollectInfo
    local index = table.indexof(infos, info)
    if index <= 0 then return end

    self.city.cityWorkManager:RemoveCollectProcess(self.furnitureId, index-1, lockable)
end

function CityLegoBuildingUIPage_Collect:DefaultSelectFirst()
    if self.recipesTableDataSrc and #self.recipesTableDataSrc > 0 then
        for i, v in ipairs(self.recipesTableDataSrc) do
            if not v.isEmpty then
                g_Game.EventManager:TriggerEvent(EventConst.UI_CITY_COLLECT_SELECT_RECIPE, v)
                return
            end
        end
    end
end

function CityLegoBuildingUIPage_Collect:GetOutputByResType(resType)
    if self.outputCache[resType] ~= nil then
        return self.outputCache[resType]
    end

    local eleResArray = CityUtils.GetElementResourceCfgsByType(resType)
    local itemMap = {}
    self.outputCache[resType] = {}
    
    for _, v in ipairs(eleResArray) do
        local itemGroup = ConfigRefer.ItemGroup:Find(v:Reward())
        if itemGroup then
            for i = 1, math.min(itemGroup:ItemNum(), itemGroup:ItemGroupInfoListLength()) do
                local itemInfo = itemGroup:ItemGroupInfoList(i)
                itemMap[itemInfo:Items()] = true
            end
        end
    end

    for id, flag in pairs(itemMap) do
        local itemCfg = ConfigRefer.Item:Find(id)
        table.insert(self.outputCache[resType], itemCfg)
    end

    table.sort(self.outputCache[resType], function(l, r)
        if l:Quality() == r:Quality() then
            return l:Id() < r:Id()
        end
        return l:Quality() > r:Quality()
    end)

    return self.outputCache[resType]
end

---@param data CityWorkCollectUIRecipeData
function CityLegoBuildingUIPage_Collect:InsertSubDataForDetails(data)
    for i, v in ipairs(self.recipesTableDataSrc) do
        if v == data then
            table.insert(self.recipesTableDataSrc, i, v.subData)
            self._p_table_item:InsertData(i, v.subData, 1)
            return
        end
    end
end

---@param data CityWorkCollectUIRecipeData
function CityLegoBuildingUIPage_Collect:RemoveSubData(data)
    for i, v in ipairs(self.recipesTableDataSrc) do
        if v == data.subData then
            table.remove(self.recipesTableDataSrc, i)
            self._p_table_item:RemAt(i)
            return
        end
    end
end

return CityLegoBuildingUIPage_Collect