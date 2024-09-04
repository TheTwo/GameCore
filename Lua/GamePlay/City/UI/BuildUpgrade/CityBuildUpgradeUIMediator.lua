---Scene Name : scene_build_upgrade
local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local CommonItemDetailsDefine = require("CommonItemDetailsDefine")
local UIMediatorNames = require("UIMediatorNames")
local CastleBuildingUpgradeParameter = require("CastleBuildingUpgradeParameter")
local CityConst = require("CityConst")
local CityUtils = require("CityUtils")
local EventConst = require("EventConst")
local TimeFormatter = require("TimeFormatter")
local I18N = require("I18N")
local ConfigTimeUtility = require("ConfigTimeUtility")
local HUDMediatorPartDefine = require("HUDMediatorPartDefine")
local Utils = require("Utils")
local CityWorkTargetType = require("CityWorkTargetType")

---@class CityBuildUpgradeUIMediator:BaseUIMediator
---@field lackList {id:number,num:number,cost:number}[]
local CityBuildUpgradeUIMediator = class('CityBuildUpgradeUIMediator', BaseUIMediator)
local CityConstructState = require("CityConstructState")
local SizeStr = "%dx%d"

---@class CityBuildUpgradeUIParameter
---@field cellTile CityCellTile
---@field workerData CityCitizenData
---
function CityBuildUpgradeUIMediator:OnCreate()
    self.goNeed = self:GameObject('p_need')

    self.textBuildingName = self:Text('p_text_building_name')
    self.textLvBuilding = self:Text('p_text_lv_building')
    self.goMax = self:GameObject('p_max')
    self.goTime = self:GameObject('p_time')
    self.textMax = self:Text('p_text_max', I18N.Get("city_level_max"))


    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.goItemTitle = self:GameObject('p_item_title')
    self.textAdd = self:Text('p_text_add', I18N.Get("city_upgrade_consume"))
    self.goItemTitleResident = self:GameObject('p_item_title_resident')
    self.textResident = self:Text('p_text_resident')
    self.goResident = self:GameObject('p_resident')
    self.compItemResident = self:LuaBaseComponent('p_item_resident')
    self.btnResidentAdd = self:Button("p_btn_resident_add", Delegate.GetOrCreate(self, self.OnChangeWorkerClick))
    self.goResidentSelected = self:GameObject("p_resident_selected")
    self.btnChange = self:Button('p_btn_change', Delegate.GetOrCreate(self, self.OnChangeWorkerClick))
    self.btnDelete = self:Button('p_btn_delete', Delegate.GetOrCreate(self, self.OnCallbackWorkerClick))
    self.textStatus = self:Text('p_text_status', I18N.Get("citizen_select"))
    self.compGrid = self:LuaBaseComponent('p_grid')
    self.compGrid1 = self:LuaBaseComponent('p_grid_1')
    self.compGrid2 = self:LuaBaseComponent('p_grid_2')
    self.compGrid3 = self:LuaBaseComponent('p_grid_3')
    self.compGrid4 = self:LuaBaseComponent('p_grid_4')
    self.textCondition = self:Text('p_text_condition', I18N.Get("city_upgrade_condition"))
    self.compCondition = self:LuaBaseComponent('p_conditions')
    self.compCondition1 = self:LuaBaseComponent('p_conditions_1')
    self.compCondition2 = self:LuaBaseComponent('p_conditions_2')
    self.goBottomBtn = self:GameObject("p_bottom_btn")
    ---@type BistateButton
    self.compBtnUpgrade = self:LuaObject("p_comp_btn_a_l_u2")

    self.compItem = self:LuaObject('p_item')
    self.compItem1 = self:LuaObject('p_item_1')
    self.compItem2 = self:LuaObject('p_item_2')
    self.compItem3 = self:LuaObject('p_item_3')
    self.compItems = {self.compItem, self.compItem1, self.compItem2, self.compItem3}
    self.gridList = {self.compGrid1, self.compGrid2, self.compGrid3, self.compGrid4}
    for i = 1, #self.gridList do
        self.gridList[i].gameObject:SetActive(false)
    end
    self.conditionList = {self.compCondition, self.compCondition1, self.compCondition2}
    for i = 1, #self.conditionList do
        self.conditionList[i].gameObject:SetActive(false)
    end

    self.gocontentright = self:GameObject("content_right")
    ---进度条---
    self.goprogress = self:GameObject("p_progress")
    self.goprogressn = self:Image("p_progress_n")
    self.goprogresspause = self:Image("p_progress_pause")
    self.textprogress = self:Text("p_text_progress", I18N.Get("buildupgrade_leveluping"))
    self.textadtime = self:Text("p_text_ad_time")
    self.gobasestop = self:GameObject("p_base_stop")

    self.childtimeeditor = self:LuaObject("child_time_editor_cost")
    self.texttimeb = self:Text("p_text_time_b", I18N.Get("city_upgrade_time"))

    ---被污染---
    self._p_hint_creep = self:GameObject("p_hint_creep")
    self._p_text_hint_creep = self:Text("p_text_hint_creep", "building_cannot_expand_tips_1")
end


function CityBuildUpgradeUIMediator:OnBtnDetailClicked(args)
    -- body
end


function CityBuildUpgradeUIMediator:GetAttrValue(attrGroupId)
    local attrGroupCfg = ConfigRefer.AttrGroup:Find(attrGroupId)
    local attrList = {}
    for i = 1 , attrGroupCfg:AttrListLength() do
        local attrCfg = attrGroupCfg:AttrList(i)
        local typeId = attrCfg:TypeId()
        local attrTypeCfg = ConfigRefer.AttrElement:Find(typeId)
        if attrTypeCfg:Show() ~= 0 then
            local name = attrTypeCfg:Name()
            local quality = attrTypeCfg.FixedQuality and attrTypeCfg:FixedQuality() or 0
            attrList[#attrList + 1] = {typeId, name, ModuleRefer.AttrModule:GetAttrValueShowTextByType(attrTypeCfg, attrCfg:Value()), nil, attrTypeCfg:Icon(), quality}
        end
    end
    return attrList
end

function CityBuildUpgradeUIMediator:GetNextLvAttrValue(attrGroupId, curAttrList)
    local attrGroupCfg = ConfigRefer.AttrGroup:Find(attrGroupId)
    for i = 1 , attrGroupCfg:AttrListLength() do
        local attrCfg = attrGroupCfg:AttrList(i)
        local typeId = attrCfg:TypeId()
        local attrTypeCfg = ConfigRefer.AttrElement:Find(typeId)
        if attrTypeCfg:Show() ~= 0 then
            local value = ModuleRefer.AttrModule:GetAttrValueShowTextByType(attrTypeCfg, attrCfg:Value())
            local index = self:CheckIsContain(typeId, curAttrList)
            if index > 0 then
                curAttrList[index][4] = value
            else
                local name = attrTypeCfg:Name()
                curAttrList[#curAttrList + 1] = {typeId, name, nil, value, attrTypeCfg:Icon()}
            end
        end
    end
    return curAttrList
end

function CityBuildUpgradeUIMediator:CheckIsContain(typeId, curAttrList)
    for index, attr in ipairs(curAttrList) do
        if attr[1] == typeId then
            return index
        end
    end
    return 0
end

---@return {desc:string, isFinish:boolean, gotoId:number}[]
function CityBuildUpgradeUIMediator:GetConditionsStatue()
    local result = {}
    for i = 1, self.nextLvCell:LvUpPreconditionLength() do
        local taskId = self.nextLvCell:LvUpPrecondition(i)
        local taskCfg = ConfigRefer.Task:Find(taskId)
        local taskName,param = ModuleRefer.QuestModule:GetTaskNameByID(taskId)
        local taskInfoStr = ''
        if param then
            taskInfoStr = taskInfoStr .. I18N.GetWithParamList(taskName,param)
        else
            taskInfoStr = taskInfoStr .. I18N.Get(taskName)
        end
        local conditionDesc = taskInfoStr
        local taskState = ModuleRefer.QuestModule:GetQuestFinishedStateLocalCache(taskId)
        local isFinish = taskState == wds.TaskState.TaskStateFinished
        result[#result + 1] = {desc = conditionDesc, isFinish = isFinish, gotoId = taskCfg:Property():Goto()}
    end
    return result
end

---@param param CityBuildUpgradeUIParameter
function CityBuildUpgradeUIMediator:OnOpened(param)
    self.param = param
    self.cellTile = param.cellTile

    local cell = self.cellTile:GetCell()
    if not cell or not cell:IsBuilding() then
        g_Logger.Error("Logic Error")
        return
    end

    local city = self.cellTile:GetCity()
    local center = CityUtils.GetCityCellCenterPos(city, cell)
    city:GetCamera():ForceGiveUpTween()
    self.cameraStack = city:GetCamera():ZoomToWithFocusStack(CityConst.CITY_NEAR_CAMERA_SIZE, CS.UnityEngine.Vector3(0.45, 0.35), center, CityConst.CITY_UI_CAMERA_FOCUS_TIME)

    self.lvCell = ConfigRefer.BuildingLevel:Find(cell.configId)
    self.typCell = ConfigRefer.BuildingTypes:Find(self.lvCell:Type())
    self.buildingInfo = self.cellTile:GetCastleBuildingInfo()
    self.textBuildingName.text = I18N.Get(self.typCell:Name())
    self.textLvBuilding.text = tostring(self.lvCell:Level())
    local building = city.buildingManager:GetBuilding(cell.tileId)
    self.isPolluted = building:IsPolluted()
    local isMax = self.lvCell:NextLevel() == 0
    self.goMax.gameObject:SetActive(isMax)
    self.goItemTitle:SetActive(not isMax)
    self.compCondition:SetVisible(not isMax)
    self.goNeed:SetActive(not isMax)
    self.goResident:SetActive(not isMax)
    self.goBottomBtn:SetActive(not isMax)
    self._p_hint_creep:SetActive(self.isPolluted)
    local sizeInfo = {}
    sizeInfo.propName = I18N.Get("city_upgrade_attr_size")
    sizeInfo.propNow = SizeStr:format(self.lvCell:SizeX(), self.lvCell:SizeY())
    local attrCfg = self.lvCell:Attr()
    local attrList = self:GetAttrValue(attrCfg)
    self.lackList = {}
    if isMax then
        for i = 1, #self.gridList do
            local attr = attrList[i]
            self.gridList[i].gameObject:SetActive(attr ~= nil)
            if attr then
                local attrInfo = {}
                attrInfo.propName = I18N.Get(attr[2])
                attrInfo.propNow = attr[3]
                attrInfo.propIcon = attr[5]
                attrInfo.quality = attr[6]
                self.gridList[i]:FeedData(attrInfo)
            end
        end
        self.goTime:SetActive(false)
    else
        ---Only Return ConditionNotMeet, LackOfResource, CanBuild
        self.nextLvCell = ConfigRefer.BuildingLevel:Find(self.lvCell:NextLevel())
        self.status = ModuleRefer.CityConstructionModule:GetBuildingLevelState(self.nextLvCell, true)
        if not (self.nextLvCell:SizeX() == self.lvCell:SizeX() and self.nextLvCell:SizeY() == self.lvCell:SizeY()) then
            sizeInfo.propNext = SizeStr:format(self.nextLvCell:SizeX(), self.nextLvCell:SizeY())
        end
        self.compBtnUpgrade:FeedData({
            onClick = Delegate.GetOrCreate(self, self.OnStartUpgradeClick),
            buttonText = I18N.Get("city_upgrade_button_new"),

            disableClick = Delegate.GetOrCreate(self, self.OnDisableStartUpgradeClick)})
        self:GetNextLvAttrValue(self.nextLvCell:Attr(), attrList)

        local conditions = self:GetConditionsStatue()
        for i = 1, #self.conditionList do
            local condition = conditions[i]
            self.conditionList[i].gameObject:SetActive(condition ~= nil)
            if condition then
                self.conditionList[i]:FeedData(condition)
            end
        end

        local array = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(self.nextLvCell:CostItemGroupCfgId())
        local hideMaterial = #array == 0
        if hideMaterial then
            self.goNeed:SetActive(false)
        else
            self.goNeed:SetActive(true)
            local showItems = {}
            for _, v in ipairs(array) do
                local itemId = v.configCell:Id()
                local single = {}
                local curNum = ModuleRefer.InventoryModule:GetAmountByConfigId(itemId)
                local cost = v.count
                single.num1 = curNum
                single.num2 = cost
                single.icon = v.configCell:Icon()
                single.id = itemId
                single.isEnough = curNum >= cost
                single.addListenter = true
                if cost > curNum then
                    self.lackList[#self.lackList + 1] = {id = itemId, cost = cost, num = cost - curNum}
                end
                showItems[#showItems + 1] = single
            end
            local sort = function(a, b)
                if a.isEnough ~= b.isEnough then
                    return not a.isEnough
                else
                    return a.id < b.id
                end
            end
            table.sort(showItems, sort)
            for i = 1, #self.compItems do
                local item = showItems[i]
                self.compItems[i]:SetVisible(item ~= nil)
                if item then
                    item.lackList = self.lackList
                    self.compItems[i]:FeedData(item)
                end
            end
        end
        local isShowWorker = self.status ~= CityConstructState.ConditionNotMeet
        if isShowWorker then
            self.goResident:SetActive(true)
            self.workerData = self:InitWorkerData()
            if self.workerData == nil then
                self.btnResidentAdd.gameObject:SetActive(true)
                self.goResidentSelected:SetActive(false)
            else
                self.btnResidentAdd.gameObject:SetActive(false)
                self.goResidentSelected:SetActive(true)
                ---@type CommonCitizenCellComponentParameter
                local parameter = {}
                parameter.citizenData = self.workerData
                self.compItemResident:FeedData(parameter)
            end
            self.hasWorker = self.workerData ~= nil
            self.tick = self.workData ~= nil
        else
            self.hasWorker = false
            self.goResident:SetActive(false)
        end
        if self:IsProcessing() then
            self.goprogress:SetActive(true)
            self.goBottomBtn:SetActive(false)
            self:UpdateProcessDisplay()
            self:UpdateProcessInfo()
            self.goTime:SetActive(false)
        else
            self.goprogress:SetActive(false)
            self.goBottomBtn:SetActive(true)
            self:UpdateBottomInfo()
            self:UpdateStartButtonGray()
            self.goTime:SetActive(true)
        end
    end
    self.compGrid:FeedData(sizeInfo)
    for i = 1, #self.gridList do
        local attr = attrList[i]
        self.gridList[i].gameObject:SetActive(attr ~= nil)
        if attr then
            local attrInfo = {}
            attrInfo.propName = I18N.Get(attr[2])
            attrInfo.propNow = attr[3]
            if attr[3] ~= attr[4] then
                attrInfo.propNext = attr[4]
            end
            attrInfo.propIcon = attr[5]
            attrInfo.quality = attr[6]
            self.gridList[i]:FeedData(attrInfo)
        end
    end

    g_Game.EventManager:TriggerEvent(EventConst.CITY_UPGRADE_BUILDING_UI_OPEN)
    g_Game.ServiceManager:AddResponseCallback(CastleBuildingUpgradeParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnUpgradeCallback))
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.bottomCenterRight, false)
    g_Game.EventManager:AddListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    self:AddItemCountChangeListener()
end


function CityBuildUpgradeUIMediator:ClickItem(info)
    ModuleRefer.InventoryModule:OpenExchangePanel({{id = info.configCell:Id()}})
end

function CityBuildUpgradeUIMediator:CloseSelf(param, forceClose)
    BaseUIMediator.CloseSelf(self, param, forceClose)
    if self.cameraStack then
        self.cameraStack:back()
    end
end

function CityBuildUpgradeUIMediator:OnClose(param)
    self:RemoveItemCountChangeListener()
    g_Game.UIManager:CloseByName(UIMediatorNames.CityCitizenNewManageUIMediator)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    g_Game.ServiceManager:RemoveResponseCallback(CastleBuildingUpgradeParameter.GetMsgId(), Delegate.GetOrCreate(self, self.OnUpgradeCallback))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_WORK_DATA_ADD, Delegate.GetOrCreate(self, self.OnWorkDataAdd))
    g_Game.EventManager:RemoveListener(EventConst.CITY_CITIZEN_DATA_REFRESH, Delegate.GetOrCreate(self, self.OnCitizenDataRefresh))
    g_Game.EventManager:TriggerEvent(EventConst.CITY_UPGRADE_BUILDING_UI_CLOSE)
    g_Game.EventManager:TriggerEvent(EventConst.HUD_PART_SHOW_HIDE_CHANGE, HUDMediatorPartDefine.bottomCenterRight, true)
end

---@return any 首次获取正在工作的工人信息
function CityBuildUpgradeUIMediator:InitWorkerData()
    local city = self.cellTile:GetCity()
    self.workData = city.cityCitizenManager:GetWorkDataByTarget(self.cellTile:GetCell().tileId, CityWorkTargetType.Building)
    if self.workData then
        local citizenId = city.cityCitizenManager:GetCitizenIdByWorkId(self.workData._id)
        self.workerData = city.cityCitizenManager:GetCitizenDataById(citizenId)
    else
        self.workerData = self.param.workerData
    end
    return self.workerData
end

---@return boolean 是否有工人在升级
function CityBuildUpgradeUIMediator:IsProcessing()
    return self.workData ~= nil or CityUtils.IsStatusUpgrade(self.buildingInfo.Status)
end

function CityBuildUpgradeUIMediator:UpdateProcessDisplay()
    if self.hasWorkData ~= (self.workData ~= nil) then
        self.hasWorkData = self.workData ~= nil
        self.goprogressn.gameObject:SetActive(self.hasWorkData)
        self.goprogresspause.gameObject:SetActive(not self.hasWorkData)
        self.gobasestop:SetActive(not self.hasWorkData)
    end
end

function CityBuildUpgradeUIMediator:UpdateProcessInfo()
    local curTime = g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if self.workData ~= nil then
        self.textprogress.text = I18N.Get("buildupgrade_leveluping")
        local progress, leftTime = self.workData:GetMakeProgress(curTime)
        self.goprogressn.fillAmount = progress
        self.textadtime.text = TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)
    else
        self.textprogress.text = I18N.Get("buildupgrade_pause")
        local duration = ConfigTimeUtility.NsToSeconds(self.nextLvCell:BuildDuration())
        local progress = self.buildingInfo.Progress / duration
        --local leftTime = duration - self.buildingInfo.Progress
        self.goprogresspause.fillAmount = math.clamp01(progress)
        self.textadtime.text = ""
    end
end

function CityBuildUpgradeUIMediator:UpdateBottomInfo()
    local duration = ConfigTimeUtility.NsToSeconds(self.nextLvCell:BuildDuration())
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    self.childtimeeditor:FeedData({endTime = curTime + duration})
end

function CityBuildUpgradeUIMediator:UpdateStartButtonGray()
    local flag = (self.status == CityConstructState.CanBuild or self.status == CityConstructState.LackOfResource) and CityUtils.IsStatusReady(self.buildingInfo.Status) and not self.isPolluted
    self.compBtnUpgrade:SetEnabled(flag)
end

function CityBuildUpgradeUIMediator:OnChangeWorkerClick()
    self.gocontentright:SetActive(false)
    ---@type CityCitizenNewManageUIParameter
    local param = {}
    param.citizenMgr = self.cellTile:GetCity().cityCitizenManager
    param.onSelected = Delegate.GetOrCreate(self, self.OnSelectWorker)
    param.onClosed = Delegate.GetOrCreate(self, self.OnSelectFinish)
    g_Game.UIManager:Open(UIMediatorNames.CityCitizenNewManageUIMediator, param)
end

function CityBuildUpgradeUIMediator:OnCallbackWorkerClick()
    if self:IsProcessing() then
        self.cellTile:GetCity().cityCitizenManager:AssignProcessWorkCitizen(self.btnDelete.transform, self.workData._id, 0)
    end
    self.workerData = nil
    self.hasWorker = nil
    self.btnResidentAdd.gameObject:SetActive(true)
    self.goResidentSelected:SetActive(false)
    self:UpdateStartButtonGray()
end

---@return boolean 是否升级会产生大小变化
function CityBuildUpgradeUIMediator:HasSizeChange()
    return self.lvCell:SizeX() ~= self.nextLvCell:SizeX() or self.lvCell:SizeY() ~= self.nextLvCell:SizeY()
end

function CityBuildUpgradeUIMediator:OnDisableStartUpgradeClick()
    if self.isPolluted then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("city_set_room_tips_8"))
    elseif #self.lackList > 0 then
        ModuleRefer.InventoryModule:OpenExchangePanel(self.lackList)
    end
end

function CityBuildUpgradeUIMediator:OnStartUpgradeClick()
    if self.status ~= CityConstructState.CanBuild then
        if self.status == CityConstructState.LackOfResource then
            local getmore = ModuleRefer.CityConstructionModule:GetLackResourceMap(self.nextLvCell)
            ModuleRefer.InventoryModule:OpenExchangePanel(getmore)
        end
        return
    end

    if self:HasSizeChange() then
        self.cellTile:GetCity():EnterUpgradePreviewMode(self.cellTile, self.workerData)
        self:CloseSelf()
    else
        self.cellTile:GetCity():UpgradeBuilding(self.cellTile:GetCell().tileId, self.cellTile.x, self.cellTile.y, self.workerData, self.compBtnUpgrade and self.compBtnUpgrade.button and self.compBtnUpgrade.button.transform or nil)
    end
end

function CityBuildUpgradeUIMediator:OnSelectWorker(citizenId)
    g_Game.UIManager:CloseByName(UIMediatorNames.CityCitizenChooseUIMediator)

    self.workerData = self.cellTile:GetCity().cityCitizenManager:GetCitizenDataById(citizenId)
    self.btnResidentAdd.gameObject:SetActive(false)
    self.goResidentSelected:SetActive(true)
    ---@type CommonCitizenCellComponentParameter
    local parameter = {}
    parameter.citizenData = self.workerData
    self.compItemResident:FeedData(parameter)

    self.hasWorker = not self.workerData:HasWork()

    if self:IsProcessing() then
        self.cellTile:GetCity().cityCitizenManager:AssignProcessWorkCitizen(self.btnResidentAdd.transform, self.workData._id, citizenId)
    else
        self:UpdateStartButtonGray()
    end
end

function CityBuildUpgradeUIMediator:OnCitizenDataRefresh(city, citizenIdMap)
    if self.workerData == nil then return end
    if city ~= self.cellTile:GetCity() then return end
    if not citizenIdMap or not citizenIdMap[self.workerData._id] then return end
    if not self:IsProcessing() then
        self.hasWorker = not self.workerData:HasWork()
        self:UpdateStartButtonGray()
    end
end

function CityBuildUpgradeUIMediator:OnSelectFinish()
    if Utils.IsNotNull(self.gocontentright) then
        self.gocontentright:SetActive(true)
    end
end

---@param isSuccess boolean
---@param rsp wrpc.CastleBuildingUpgradeReply
function CityBuildUpgradeUIMediator:OnUpgradeCallback(isSuccess, rsp)
    if isSuccess then
        self:CloseSelf()
    end
end

---@param city City
---@param content table @{targetId=targetId,targetType=targetType}
function CityBuildUpgradeUIMediator:OnWorkDataAdd(city, id, content)
    if city ~= self.cellTile:GetCity() then
        return
    end

    if self.workerData == nil then return end
    if content.targetType ~= CityWorkTargetType.Building then return end
    if content.targetId ~= self.cellTile:GetCell().tileId then return end

    self.workData = city.cityCitizenManager:GetWorkData(id)
    self.tick = true
end

function CityBuildUpgradeUIMediator:OnTick(deltaTime)
    if self.tick then
        self:UpdateProcessDisplay()
        self:UpdateProcessInfo()
        local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
        local progress, _ = self.workData:GetMakeProgress(curTime)
        if progress >= 1 then
            self:CloseSelf()
        end
    end
end

function CityBuildUpgradeUIMediator:AddItemCountChangeListener()
    self.itemCountEvtHandle = {}
    for i, v in ipairs(self.lackList) do
        self.itemCountEvtHandle[v.id] = ModuleRefer.InventoryModule:AddCountChangeListener(v.id, Delegate.GetOrCreate(self, self.OnLackItemCountChanged))
    end
end

function CityBuildUpgradeUIMediator:RemoveItemCountChangeListener()
    for id, clearHandle in pairs(self.itemCountEvtHandle) do
        clearHandle()
    end
    self.itemCountEvtHandle = nil
end

function CityBuildUpgradeUIMediator:OnLackItemCountChanged()
    for i = #self.lackList, 1, -1 do
        local v = self.lackList[i]
        local count = ModuleRefer.InventoryModule:GetAmountByConfigId(v.id)
        if count >= v.cost then
            table.remove(self.lackList, i)
            self.itemCountEvtHandle[v.id]()
            self.itemCountEvtHandle[v.id] = nil
        end
    end
    self.status = ModuleRefer.CityConstructionModule:GetBuildingLevelState(self.nextLvCell, true)
end

return CityBuildUpgradeUIMediator