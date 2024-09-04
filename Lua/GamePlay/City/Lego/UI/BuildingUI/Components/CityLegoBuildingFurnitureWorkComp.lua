local BaseUIComponent = require ('BaseUIComponent')
local CityWorkType = require("CityWorkType")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local CityWorkFormula = require("CityWorkFormula")
local ConfigTimeUtility = require("ConfigTimeUtility")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local I18N = require("I18N")
local CityWorkI18N = require("CityWorkI18N")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require("ModuleRefer")
local TimeFormatter = require("TimeFormatter")
local Utils = require("Utils")
local CityElementResType = require("CityElementResType")

---@class CityLegoBuildingFurnitureWorkComp:BaseUIComponent
local CityLegoBuildingFurnitureWorkComp = class('CityLegoBuildingFurnitureWorkComp', BaseUIComponent)

function CityLegoBuildingFurnitureWorkComp:OnCreate()
    --- 产量信息
    self._p_produce = self:GameObject("p_produce")
    self._p_group_produce_num = self:GameObject("p_group_produce_num")
    self._p_icon_produce = self:Image("p_icon_produce")
    self._p_text_produce_num = self:Text("p_text_produce_num")

    self._p_group_produce_time = self:GameObject("p_group_produce_time")
    self._p_text_time = self:Text("p_text_time")
    --- 居民节点
    ---@type CityFurnitureConstructionProcessCitizenBlock
    self._p_resident_root = self:LuaObject("p_resident_root")
    --- 造兵界面专用提示
    self._p_produce_shortage = self:Button("p_produce_shortage", Delegate.GetOrCreate(self, self.OnClickShortage))
    self._p_text_produce_shortage = self:Text("p_text_produce_shortage")
    self._icon = self:GameObject("icon")
end

---@param furniture CityFurniture
function CityLegoBuildingFurnitureWorkComp:OnFeedData(furniture)
    if self.furniture ~= nil then
        self:ReleaseLastFurnitureData()
    end

    self.furniture = furniture
    self.furnitureId = furniture:UniqueId()
    self.city = furniture.manager.city
    if self.furniture:CanDoCityWork(CityWorkType.Process) and not self.furniture:IsMakingFurnitureProcess() then
        self:BindAsAutoProcess()
    elseif self.furniture:CanDoCityWork(CityWorkType.FurnitureResCollect) then
        self:BindAsAutoCollect()
    elseif self.furniture:CanDoCityWork(CityWorkType.ResourceGenerate) then
        self:BindAsAutoProduce()
    elseif self.furniture:CanDoCityWork(CityWorkType.MilitiaTrain) then
        self:BindAsAutoTrain()
    end
end

function CityLegoBuildingFurnitureWorkComp:OnFurnitureUpdate(furniture)
    if self.furniture ~= furniture then return end
    self:ReleaseItemListeners()

    if self.furniture:CanDoCityWork(CityWorkType.Process) and not self.furniture:IsMakingFurnitureProcess() then
        self:BindAsAutoProcess()
    elseif self.furniture:CanDoCityWork(CityWorkType.FurnitureResCollect) then
        self:BindAsAutoCollect()
    elseif self.furniture:CanDoCityWork(CityWorkType.ResourceGenerate) then
        self:BindAsAutoProduce()
    elseif self.furniture:CanDoCityWork(CityWorkType.MilitiaTrain) then
        self:BindAsAutoTrain()
    end
end

function CityLegoBuildingFurnitureWorkComp:ReleaseItemListeners()
    for _, releaseCall in pairs(self.itemCountListeners or {}) do
        releaseCall()
    end
end

function CityLegoBuildingFurnitureWorkComp:BindAsAutoProcess()
    self.workType = CityWorkType.Process
    self.workCfg = ConfigRefer.CityWork:Find(self.furniture:GetWorkCfgId(CityWorkType.Process))
    self.isWorking = false
    self.workId, self.workData, self.process = 0, nil, nil
    local castleFurniture = self.furniture:GetCastleFurniture()
    for _, v in ipairs(castleFurniture.ProcessInfo) do
        --- 只处理aotu，非auto的不处理
        if v.Auto then
            self.isWorking = true
            self.workId = castleFurniture.WorkType2Id[CityWorkType.Process]
            self.workData = self.city.cityWorkManager:GetWorkData(self.workId)
            ---@type wds.CastleProcess
            self.process = v
            break
        end
    end

    local hasCitizen = self.isWorking and self.workData ~= nil and self.workData.CitizenId ~= 0
    if hasCitizen then
        self.citizenId = self.workData.CitizenId
    else
        self.citizenId = nil
    end

    ---@type CityFurnitureConstructionProcessCitizenBlockData
    self.citizenBlockData = self.citizenBlockData or {}
    if self.citizenBlockData.citizenId ~= self.citizenId or self.citizenBlockData.citizenMgr == nil then
        self.citizenBlockData.citizenId = self.citizenId
        self.citizenBlockData.citizenMgr = self.city.cityCitizenManager
        self.citizenBlockData.workCfgId = self.workCfg:Id()
        self.citizenBlockData.onSelectedChanged = Delegate.GetOrCreate(self, self.OnCitizenSelectedChanged)
        self._p_resident_root:FeedData(self.citizenBlockData)
    end
    self._p_resident_root:SetVisible(true)

    if self.process then
        self._p_produce:SetActive(true)
        local recipe = ConfigRefer.CityProcess:Find(self.process.ConfigId)

        local icon = "sp_icon_missing"
        local count = "0"
        local itemGroup = ConfigRefer.ItemGroup:Find(recipe:Output())
        if itemGroup == nil then
            icon = "sp_icon_missing"
            count = "1"
        else
            local output = CityWorkFormula.CalculateOutput(self.workCfg, itemGroup, nil, self.furniture.singleId, self.citizenId)
            local firstOutput = output[1]
            local itemCfg = ConfigRefer.Item:Find(firstOutput.id)
            icon = itemCfg:Icon()
            if firstOutput.minCount ~= firstOutput.maxCount then
                count = ("%.0f~%.0f"):format(firstOutput.minCount, firstOutput.maxCount)
            else
                count = tostring(firstOutput.minCount)
            end
        end

        if not string.IsNullOrEmpty(recipe:OutputIcon()) then
            icon = recipe:OutputIcon()
        end
        self._p_group_produce_num:SetActive(true)
        g_Game.SpriteManager:LoadSprite(icon, self._p_icon_produce)
        self._p_text_produce_num.text = ("+%s"):format(count)

        self._p_group_produce_time:SetActive(true)
        local time = CityWorkFormula.CalculateFinalTimeCost(self.workCfg, ConfigTimeUtility.NsToSeconds(recipe:Time()), recipe:Difficulty(), nil, self.furniture.singleId, self.citizenId)
        self._p_text_time.text = ("/%s"):format(TimeFormatter.TimerStringFormat(time))
    else
        self._p_produce:SetActive(false)
        self._p_group_produce_num:SetActive(false)
        self._p_group_produce_time:SetActive(false)
    end
end

function CityLegoBuildingFurnitureWorkComp:BindAsAutoCollect()
    self.workType = CityWorkType.FurnitureResCollect
    self.workCfg = ConfigRefer.CityWork:Find(self.furniture:GetWorkCfgId(CityWorkType.FurnitureResCollect))
    self.isWorking = false
    local castleFurniture = self.furniture:GetCastleFurniture()
    for i, v in ipairs(castleFurniture.FurnitureCollectInfo) do
        if v.Auto and not v.Finished then
            self.isWorking = true
            self.collectInfo = v
            break
        end
    end
    if self.isWorking then
        self.workId = self.furniture:GetCastleFurniture().WorkType2Id[CityWorkType.FurnitureResCollect] or 0
        self.workData = self.city.cityWorkManager:GetWorkData(self.workId)
    else
        self.workId, self.workData = 0, nil
    end

    local hasCitizen = self.isWorking and self.workData ~= nil and self.workData.CitizenId ~= 0
    if hasCitizen then
        self.citizenId = self.workData.CitizenId
    else
        self.citizenId = nil
    end

    ---@type CityFurnitureConstructionProcessCitizenBlockData
    self.citizenBlockData = self.citizenBlockData or {}
    if self.citizenBlockData.citizenId ~= self.citizenId or self.citizenBlockData.citizenMgr == nil then
        self.citizenBlockData.citizenId = self.citizenId
        self.citizenBlockData.citizenMgr = self.city.cityCitizenManager
        self.citizenBlockData.workCfgId = self.workCfg:Id()
        self.citizenBlockData.onSelectedChanged = Delegate.GetOrCreate(self, self.OnCitizenSelectedChanged)
        self._p_resident_root:FeedData(self.citizenBlockData)
    end
    self._p_resident_root:SetVisible(true)

    self._p_produce:SetActive(false)
    self._p_group_produce_num:SetActive(false)
    self._p_group_produce_time:SetActive(false)

    local needShowNonCitizen = self.isWorking and not hasCitizen
    local needShowLackRes, resType = false, nil
    if self.collectInfo then
        resType = self.collectInfo.ResourceType
        local count = self.city.elementManager:GetElementResourceCountByType(resType)
        needShowLackRes = count <= 0
    end
    self._p_produce_shortage:SetVisible(needShowNonCitizen or needShowLackRes)
    if needShowNonCitizen then
        self._p_text_produce_shortage.text = I18N.Get("lack_citizen")
        self._onClickImp = Delegate.GetOrCreate(self, self.OnClickSelectCitizen)
    else
        if resType == CityElementResType.WoodTargets then
            self._p_text_produce_shortage.text = I18N.Get("lack_wood")
        elseif resType == CityElementResType.MetalTargets then
            self._p_text_produce_shortage.text = I18N.Get("lack_metal")
        elseif resType == CityElementResType.WheatTargets or resType == CityElementResType.ChillTargets or resType == CityElementResType.PumpkinTargets or resType == CityElementResType.CornTargets then
            self._p_text_produce_shortage.text = I18N.Get("lack_food")
        elseif resType == CityElementResType.RolinTargets then
            self._p_text_produce_shortage.text = I18N.Get("lack_rolin")
        end
    end
    self._icon:SetActive(self._onClickImp ~= nil)
end

function CityLegoBuildingFurnitureWorkComp:BindAsAutoProduce()
    self.workType = CityWorkType.ResourceGenerate
    self.workCfg = ConfigRefer.CityWork:Find(self.furniture:GetWorkCfgId(CityWorkType.ResourceGenerate))
    self.isWorking = false
    local castleFurniture = self.furniture:GetCastleFurniture()
    self.isWorking = castleFurniture.ResourceGenerateInfo.GeneratePlan:Count() > 0
    self.workId, self.workData = 0, nil
    if self.isWorking then
        self.workId = castleFurniture.WorkType2Id[CityWorkType.ResourceGenerate]
        self.workData = self.city.cityWorkManager:GetWorkData(self.workId)
    end
    local hasCitizen = self.isWorking and self.workData ~= nil and self.workData.CitizenId ~= 0
    if hasCitizen then
        self.citizenId = self.workData.CitizenId
    else
        self.citizenId = nil
    end

    ---@type CityFurnitureConstructionProcessCitizenBlockData
    self.citizenBlockData = self.citizenBlockData or {}
    if self.citizenBlockData.citizenId ~= self.citizenId or self.citizenBlockData.citizenMgr == nil then
        self.citizenBlockData.citizenId = self.citizenId
        self.citizenBlockData.citizenMgr = self.city.cityCitizenManager
        self.citizenBlockData.workCfgId = self.workCfg:Id()
        self.citizenBlockData.onSelectedChanged = Delegate.GetOrCreate(self, self.OnCitizenSelectedChanged)
        self._p_resident_root:FeedData(self.citizenBlockData)
    end
    self._p_resident_root:SetVisible(true)

    self.generatingInfo = nil
    for _, info in ipairs(castleFurniture.ResourceGenerateInfo.GeneratePlan) do
        if info.Auto then
            self.generatingInfo = info
            break
        end
    end

    if self.generatingInfo then
        self._p_produce:SetActive(true)
        local recipe = ConfigRefer.CityProcess:Find(self.generatingInfo.ProcessId)
        local resCfg = ConfigRefer.CityElementResource:Find(recipe:GenerateResType())
        local icon = resCfg:Icon()
        local count = "1"
        self._p_group_produce_num:SetActive(true)
        g_Game.SpriteManager:LoadSprite(icon, self._p_icon_produce)
        self._p_text_produce_num.text = ("+%s"):format(count)

        self._p_group_produce_time:SetActive(true)
        local time = CityWorkFormula.CalculateFinalTimeCost(self.workCfg, ConfigTimeUtility.NsToSeconds(recipe:Time()), recipe:Difficulty(), nil, self.furnitureId, self.citizenId)
        self._p_text_time.text = ("/%s"):format(TimeFormatter.TimerStringFormat(time))
    else
        self._p_produce:SetActive(false)
        self._p_group_produce_num:SetActive(false)
        self._p_group_produce_time:SetActive(false)
    end
end

function CityLegoBuildingFurnitureWorkComp:BindAsAutoTrain()
    self.workId = ModuleRefer.TrainingSoldierModule:GetWorkId(self.furniture:ConfigId())
    self:RefreshTrainingState()
    self.itemCountListeners = {}
    local costItems = ModuleRefer.TrainingSoldierModule:GetCostItems(self.workId, nil, self.furnitureId, nil)
    for _, costItem in ipairs(costItems) do
        local releaseCall = ModuleRefer.InventoryModule:AddCountChangeListener(costItem.id, Delegate.GetOrCreate(self, self.RefreshTrainingState))
        if self.itemCountListeners[costItem.id] then
            self.itemCountListeners[costItem.id]()
        end
        self.itemCountListeners[costItem.id] = releaseCall
    end
    -- local traingSpeed = ModuleRefer.TrainingSoldierModule:GetTraingSpeed(self.workId, nil, self.furnitureId, nil)
    local castleMilitia = ModuleRefer.TrainingSoldierModule:GetCastleMilitia()
    self._p_text_produce_num.text = "+" .. math.floor(castleMilitia.IncPerMinute)
    self._p_text_time.text = I18N.Get('Energy_EnergyProductUnit')
    g_Game.SpriteManager:LoadSprite("sp_icon_item_hero_exp_lv2", self._p_icon_produce)
    self._p_produce:SetActive(true)
    self._p_group_produce_num:SetActive(true)
    self._p_group_produce_time:SetActive(true)
end

function CityLegoBuildingFurnitureWorkComp:RefreshTrainingState()
    local costItems = ModuleRefer.TrainingSoldierModule:GetCostItems(self.workId, nil, self.furnitureId, nil)
    local isEnough = true
    for i = 1, #costItems do
        local hasNum = ModuleRefer.InventoryModule:GetAmountByConfigId(costItems[i].id)
        local costNum = costItems[i].count
        if hasNum < costNum then
            isEnough = false
        end
    end
    self._p_produce_shortage:SetVisible(not isEnough)
    self._p_text_produce_shortage.text = I18N.Get("lack_food_soldier")
    self._onClickImp = Delegate.GetOrCreate(self, self.OnClickTrainCostItemGetMore)
    self._icon:SetActive(self._onClickImp ~= nil)
end

function CityLegoBuildingFurnitureWorkComp:OnCitizenSelectedChanged(citizenId)
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
                            g_Game.UIManager:CloseByName(UIMediatorNames.CityCitizenManageV3UIMediator)
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

function CityLegoBuildingFurnitureWorkComp:SelectCitizen(citizenId)
    self.citizenId = citizenId
    self.citizenBlockData.citizenId = citizenId
    self._p_resident_root:FeedData(self.citizenBlockData)

    if self.workType == CityWorkType.Process then
        if self.process then
            local recipe = ConfigRefer.CityProcess:Find(self.process.ConfigId)
            local count = "0"
            local itemGroup = ConfigRefer.ItemGroup:Find(recipe:Output())
            if itemGroup == nil then
                count = "1"
            else
                local output = CityWorkFormula.CalculateOutput(self.workCfg, itemGroup, nil, self.furniture.singleId, self.citizenId)
                local firstOutput = output[1]
                if firstOutput.minCount ~= firstOutput.maxCount then
                    count = ("%.0f~%.0f"):format(firstOutput.minCount, firstOutput.maxCount)
                else
                    count = tostring(firstOutput.minCount)
                end
            end
            self._p_text_produce_num.text = ("+%s"):format(count)
            local time = CityWorkFormula.CalculateFinalTimeCost(self.workCfg, ConfigTimeUtility.NsToSeconds(recipe:Time()), recipe:Difficulty(), nil, self.furniture.singleId, self.citizenId)
            self._p_text_time.text = ("/%s"):format(TimeFormatter.TimerStringFormat(time))
        end
    elseif self.workType == CityWorkType.ResourceGenerate then
        if self.generatingInfo then
            local recipe = ConfigRefer.CityProcess:Find(self.generatingInfo.ProcessId)
            local time = CityWorkFormula.CalculateFinalTimeCost(self.workCfg, ConfigTimeUtility.NsToSeconds(recipe:Time()), recipe:Difficulty(), nil, self.furnitureId, self.citizenId)
            self._p_text_time.text = ("/%s"):format(TimeFormatter.TimerStringFormat(time))
        end
    end
end

function CityLegoBuildingFurnitureWorkComp:ReleaseLastFurnitureData()
    self:ReleaseItemListeners()

    self.citizenBlockData = nil
    self._p_resident_root:SetVisible(false)

    self._p_produce:SetActive(false)
    self._p_group_produce_num:SetActive(false)
    self._p_group_produce_time:SetActive(false)
    self._p_produce_shortage:SetVisible(false)
    self.furniture = nil
    self._onClickImp = nil
end

function CityLegoBuildingFurnitureWorkComp:OnClickShortage()
    if self._onClickImp then
        self._onClickImp()
    end
end

function CityLegoBuildingFurnitureWorkComp:OnClickSelectCitizen()
    if Utils.IsNotNull(self._p_resident_root) and self._p_resident_root.CSComponent.gameObject.activeInHierarchy then
        self._p_resident_root:OnClickAddOrChangeCitizen()
    end
end

function CityLegoBuildingFurnitureWorkComp:OnClickTrainCostItemGetMore()
    ModuleRefer.InventoryModule:OpenExchangePanel({{ id = 63000 }})
end

return CityLegoBuildingFurnitureWorkComp