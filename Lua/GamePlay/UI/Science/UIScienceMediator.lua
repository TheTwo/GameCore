local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local Delegate = require('Delegate')
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local ArtResourceUtils = require("ArtResourceUtils")
local CastleUnlockTechnologyParameter = require("CastleUnlockTechnologyParameter")
local CastleCancelUnlockTechParameter = require("CastleCancelUnlockTechParameter")
local TimerUtility = require("TimerUtility")
local Utils = require("Utils")
local CommonItemDetailsDefine = require('CommonItemDetailsDefine')
local I18N = require('I18N')
local ConfigTimeUtility = require("ConfigTimeUtility")

---@class UIScienceMediator : BaseUIMediator
local UIScienceMediator = class('UIScienceMediator', BaseUIMediator)

function UIScienceMediator:ctor()

end

function UIScienceMediator:OnCreate()

    self.tableviewproTable = self:TableViewPro('p_table')
    self.goContent = self:GameObject('p_content')
    self.scrollRectContent = self:BindComponent("p_table", typeof(CS.UnityEngine.UI.ScrollRect))
    self.goPopupDetail = self:GameObject('p_popup_detail')
    self.goProgress = self:GameObject('p_progress')

    self.imgProgressBar = self:Image('p_progress_bar')
    self.imgIconItem = self:Image('p_icon_item')
    self.goTypeBItem = self:GameObject('p_type_b_item')
    self.goTypeCItem = self:GameObject('p_type_c_item')
    self.goWork = self:GameObject('p_work')
    self.textName = self:Text('p_text_name')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnBtnDetailClicked))
    self.goTipsDetail = self:GameObject('p_tips_detail')
    self.textNameTips = self:Text('p_text_name_tips')
    self.textContentTips = self:Text('p_text_content_tips')
    self.goTipsLv1 = self:GameObject('p_tips_lv_1')
    self.textLv1 = self:Text('p_text_lv_1')
    self.textAdd1 = self:Text('p_text_add_1')
    self.goTipsLv2 = self:GameObject('p_tips_lv_2')
    self.textLv2 = self:Text('p_text_lv_2')
    self.textAdd2 = self:Text('p_text_add_2')
    self.goTipsLv3 = self:GameObject('p_tips_lv_3')
    self.textLv3 = self:Text('p_text_lv_3')
    self.textAdd3 = self:Text('p_text_add_3')
    self.goLayoutDesc1 = self:GameObject('layout_desc_1')
    self.textSpeed = self:Text('p_text_speed')
    self.goLayoutDesc2 = self:GameObject('layout_desc_2')
    self.textSpeed2 = self:Text('p_text_speed_2')
    self.goSchedule = self:GameObject('p_schedule')
    self.textTechlv = self:Text('p_text_techlv', I18N.Get("tech_info_techleveltitle"))
    self.textEffect = self:Text('p_text_effect', I18N.Get("tech_info_effecttitle"))
    self.textUnmber3 = self:Text('p_text_unmber_3')
    self.goIconArrowL = self:GameObject('p_icon_arrow_l')
    self.textUnmber1 = self:Text('p_text_unmber_1')
    self.goIconArrowR = self:GameObject('p_icon_arrow_r')
    self.textUnmber2 = self:Text('p_text_unmber_2')
    self.textSpeedA = self:Text('p_text_speed_a')
    self.textSpeedB = self:Text('p_text_speed_b')
    self.tableviewproTableItem = self:TableViewPro('p_table_item')
    self.goResources = self:GameObject('p_resources')
    self.compChildItemStandardS = self:LuaBaseComponent('child_item_standard_s')
    self.compChildItemStandardSEditor1 = self:LuaBaseComponent('child_item_standard_s_editor_1')
    self.compChildItemStandardSEditor2 = self:LuaBaseComponent('child_item_standard_s_editor_2')
    self.compChildItemStandardSEditor3 = self:LuaBaseComponent('child_item_standard_s_editor_3')
    self.textHine = self:Text('p_text_hine', I18N.Get("tech_info_unlock_des"))
    self.textNeed = self:Text('p_text_need', I18N.Get("tech_info_needs"))
    self.tableviewproTableSkill = self:TableViewPro('p_table_skill')
    self.goImgMastered = self:GameObject('p_img_mastered')
    self.textAchieved = self:Text('p_text_achieved', I18N.Get("tech_info_achieve"))
    self.goBtns = self:GameObject('p_btns')
    self.compChildTime = self:LuaBaseComponent('child_time')
    self.compALU2Editor = self:LuaObject('p_comp_btn_a_l_u2')
    self.btnCompCLU2Editor = self:Button('p_comp_btn_c_l_u2', Delegate.GetOrCreate(self, self.OnBtnCompCLU2EditorClicked))
    self.textR = self:Text('p_text_r', I18N.Get("tech_btn_stop"))
    self.btnClose = self:Button('p_btn_close', Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    self.textLock = self:Text('p_text_lock', I18N.Get("tech_info_stageneeds"))
    self.goTips = self:GameObject('p_tips')
    self.goTipsContent = self:GameObject('p_tips_content')
    self.goIconLamp = self:GameObject("p_icon_lamp")
    self.goTargetLamp = self:GameObject("p_target_lamp")
    self.animationsTips = self:BindComponent('p_tips', typeof(CS.UnityEngine.Animation))
    self.btnTips = self:Button('p_btn_tips', Delegate.GetOrCreate(self, self.OnBtnTipsClicked))
    self.goFinish = self:GameObject('p_finish')
    self.textFinish = self:Text('p_text_finish')
    self.textNumberSchedule = self:Text('p_text_number_schedule')
    self.goProgressTips = self:GameObject('p_progress_tips')
    self.imgProgressTipsBar = self:Image('p_progress_tips_bar')
    self.imgIconItemTips = self:Image('p_icon_item_tips')
    self.goChildScienceWorkTips = self:GameObject('child_science_work_editor_tips')
    self.animationChildScienceWorkTips = self:BindComponent("child_science_work_editor_tips", typeof(CS.UnityEngine.Animation))
    self.goStage = self:GameObject('p_stage')
    self.textNameStage = self:Text('p_text_name_stage')
    self.textQuantity = self:Text('p_text_quantity')
    self.textOpen = self:Text("p_text_open")
    self.compChildCommonBack = self:LuaBaseComponent('child_common_btn_back')
    self.itemConditionLeft = self:LuaBaseComponent('p_item_condition_left')

    --self.btnNewStage = self:Button('p_btn_new_stage', Delegate.GetOrCreate(self, self.OnBtnNewStageClicked))
    self.textNew = self:Text('p_text_new', I18N.Get("tech_info_newstage"))
    self.goPopupDetail:SetActive(false)
    self.tipsGos = {self.goTipsLv1, self.goTipsLv2, self.goTipsLv3}
    self.tipsLvs = {self.textLv1, self.textLv2, self.textLv3}
    self.tipsAdds = {self.textAdd1, self.textAdd2, self.textAdd3}
    self.costItems = {self.compChildItemStandardS, self.compChildItemStandardSEditor1, self.compChildItemStandardSEditor2, self.compChildItemStandardSEditor3}
    self.goTypeBItem:SetActive(false)
    self.goLampOriginPos = self.goIconLamp.transform.localPosition
end

function UIScienceMediator:OnOpened()
    self.showStage = {}
    self.stagesX = {}
    self.compChildCommonBack:FeedData({title = I18N.Get("tech_info_title"), onClose = Delegate.GetOrCreate(self,self.OnBackBtnClick)})
    self:RefreshCurStageInfo()
    self:RefreshStageTable()
    self:CheckIsShowLeftResearching()
    self:CheckIsShowNewStage()
    g_Game.EventManager:AddListener(EventConst.ON_REFRESH_TECH_STAGE_WDS, Delegate.GetOrCreate(self, self.OnUnlockNewStage))
    g_Game.EventManager:AddListener(EventConst.ON_REFRESH_TECH_RESEARCHING, Delegate.GetOrCreate(self, self.OnResearchingNewTech))
    g_Game.EventManager:AddListener(EventConst.ON_CLICK_TECH_NODE, Delegate.GetOrCreate(self, self.ShowTechDetailsPanel))
    g_Game.EventManager:AddListener(EventConst.ON_ADD_TECH_STAGE, Delegate.GetOrCreate(self, self.AddShowStage))
    g_Game.EventManager:AddListener(EventConst.ON_REMOVE_TECH_STAGE, Delegate.GetOrCreate(self, self.RemoveShowStage))
    g_Game.EventManager:AddListener(EventConst.ON_CLICK_EMPTY, Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    g_Game.EventManager:AddListener(EventConst.ON_FINISH_RESEARCH, Delegate.GetOrCreate(self, self.OnFinishResearch))
    g_Game.EventManager:AddListener(EventConst.ON_CLICK_NEW_CHAPTER, Delegate.GetOrCreate(self, self.OnBtnNewStageClicked))
    g_Game.EventManager:AddListener(EventConst.ON_LOCK_TO_TECH, Delegate.GetOrCreate(self, self.LockToTargetTech))

    local reschedId = ModuleRefer.ScienceModule:GetMaxResearchedTechId()
    if reschedId then
        self:LockToTargetTech(reschedId, true)
    else
        local curStage = ModuleRefer.ScienceModule:GetCurScienceStage()
        self:LockToTargetStage(curStage)
    end

    local buttonParamStartWork = {}
    buttonParamStartWork.onClick = Delegate.GetOrCreate(self, self.OnBtnCompALU2EditorClicked)
    buttonParamStartWork.buttonText =  I18N.Get("tech_btn_research")

    buttonParamStartWork.disableClick = Delegate.GetOrCreate(self, self.OnDisableClick)
    self.compALU2Editor:OnFeedData(buttonParamStartWork)
    TimerUtility.DelayExecute(function() self.scrollRectContent.horizontal = true end, 0.3)
end

function UIScienceMediator:OnDisableClick()
    if self.lackList and #self.lackList > 0 then
        ModuleRefer.InventoryModule:OpenExchangePanel(self.lackList)
    end
end

function UIScienceMediator:AddShowStage(stageId)
    self.showStage[stageId] = true
    self:CheckIsShowNewStage()
    self:CheckIsShowLeftResearching()
    self:CheckIsShowLeftCondi()
end

function UIScienceMediator:RemoveShowStage(stageId)
    self.showStage[stageId] = false
    self:CheckIsShowNewStage()
    self:CheckIsShowLeftResearching()
    self:CheckIsShowLeftCondi()
end

function UIScienceMediator:OnUnlockNewStage()
    self:RefreshCurStageInfo()
    local recordPos = self.goContent.transform.localPosition
    self:RefreshStageTable()
    self.goContent.transform.localPosition = recordPos
    local curStage = ModuleRefer.ScienceModule:GetCurScienceStage()
    g_Game.UIManager:Open('UIScienceStageMediator', curStage)
end

function UIScienceMediator:OnResearchingNewTech()
    local recordPos = self.goContent.transform.localPosition
    local researchingId = ModuleRefer.ScienceModule:GetCurResearchingTech()
    if researchingId > 0 then
        local stageId = ConfigRefer.CityTechTypes:Find(researchingId):Stage()
        if self.showStage[stageId] then
            g_Game.EventManager:TriggerEvent(EventConst.ON_REFRESH_TECH_STAGE, researchingId)
        else
            self:CheckIsShowLeftResearching()
        end
    else
        self:RefreshCurStageInfo()
        self:RefreshStageTable()
    end
    self.goContent.transform.localPosition = recordPos
    if researchingId == self.curSelectTechId or researchingId == 0 then
        self:RefreshDetailsPanel()
        self:CheckIsShowNewStage()
    end
end

function UIScienceMediator:CheckIsShowNewStage()
    -- local curStage = ModuleRefer.ScienceModule:GetCurScienceStage()
    -- local isShow = ModuleRefer.ScienceModule:IsMeetAllStageConditions(curStage)
    -- local isLastStage = ConfigRefer.CityTechStage:Find(curStage):NextStage() == 0
    -- self.btnNewStage.gameObject:SetActive(isShow and not isLastStage and not self.showStage[curStage + 1])
end

function UIScienceMediator:RefreshCurStageInfo(offset)
    local curStage = ModuleRefer.ScienceModule:GetCurScienceStage()
    local isShowNext = ModuleRefer.ScienceModule:IsMeetAllStageConditions(curStage)
    local nextStage = ConfigRefer.CityTechStage:Find(curStage):NextStage()
    local isLastStage = nextStage == 0
    if  isShowNext and not isLastStage then
        self.textNameStage.text = I18N.Get(ConfigRefer.CityTechStage:Find(nextStage):Name())
        self.textOpen.text = I18N.Get("tech_info_waitforopen")
        self.textQuantity.gameObject:SetActive(false)
    else
        local stageConfig = ConfigRefer.CityTechStage:Find(curStage)
        local curProgress, totalProgress = ModuleRefer.ScienceModule:GetstageProgress(curStage)
        self.textNameStage.text = I18N.Get(stageConfig:Name())
        if offset then
            curProgress = curProgress + offset
        end
        self.textOpen.text = ""
        self.textQuantity.gameObject:SetActive(true)
        self.textQuantity.text = string.format(("<color=#13FFD5><size=50>%s</size></color>"), curProgress .. '/') .. totalProgress
    end
end

function UIScienceMediator:RefreshStageTable()
    local curStage = ModuleRefer.ScienceModule:GetCurScienceStage()
    self.tableviewproTable:Clear()
    self.stageList = {}
    local lastWidth = 0
    for i = 1, curStage + 1 do
        local stageCfg = ConfigRefer.CityTechStage:Find(i)
        if stageCfg then
            local maxWidth = ModuleRefer.ScienceModule:GetStageMaxWidth(i)
            local isLastStage = stageCfg:NextStage() == 0
            if isLastStage then
                maxWidth = maxWidth - ModuleRefer.ScienceModule:GetStageCondiWidth()
            end
            self.stagesX[i] = lastWidth
            lastWidth = lastWidth + maxWidth
            self.tableviewproTable:AppendDataEx(i, maxWidth, 0, 0, -1, 0)
            self.stageList[#self.stageList + 1] = i
        end
    end
    self.tableviewproTable:RefreshAllShownItem(false)
    self.tableviewproTable:SetFocusData(curStage)
    self.tableviewproTable.BeginDragAction = function() self:OnBtnCloseClicked()
        g_Game.EventManager:TriggerEvent(EventConst.ON_CLICK_TECH_NODE, nil)
    end
end

function UIScienceMediator:LockToTargetTech(techId, hideDetails)
    local teachCfg = ConfigRefer.CityTechTypes:Find(techId)
    local stageId = teachCfg:Stage()
    local targetX = teachCfg:X()
    local x = self.stagesX[stageId] or 0
    x = x + (targetX - 1) * 720
    local limitMaxX = self.goContent.transform.sizeDelta.x -  CS.UnityEngine.Screen.width
    local realX = math.clamp(-x, -limitMaxX, 0)
    local y = self.goContent.transform.anchoredPosition.y
    self.goContent.transform.anchoredPosition = CS.UnityEngine.Vector2(realX, y)
    if not hideDetails then
        self:ShowTechDetailsPanel(techId)
    end
end

function UIScienceMediator:LockToTargetStage(stageId)
    local x = self.stagesX[stageId] or 0
    local limitMaxX = self.goContent.transform.sizeDelta.x -  CS.UnityEngine.Screen.width
    x = math.clamp(x, 0, limitMaxX)
    local y = self.goContent.transform.anchoredPosition.y
    self.goContent.transform.anchoredPosition = CS.UnityEngine.Vector2(-x, y)
end

function UIScienceMediator:ShowTechDetailsPanel(techId)
    if not techId then
        return
    end
    self.curSelectTechId = techId
    self.goPopupDetail:SetActive(false)
    self.goPopupDetail:SetActive(true)
    self:RefreshDetailsPanel()
end

function UIScienceMediator:RefreshDetailsPanel()
    if not self.goPopupDetail.activeSelf then
        return
    end
    self.goTipsDetail:SetActive(false)
    local techId = self.curSelectTechId
    local teachCfg = ConfigRefer.CityTechTypes:Find(techId)
    local isResearchAll = ModuleRefer.ScienceModule:CheckIsResearchAll(techId)
    self:LoadSprite(teachCfg:Image(), self.imgIconItem)
    self.textName.text = I18N.Get(teachCfg:Name())
    self.textSpeed.text = I18N.Get(teachCfg:Desc())
    self.textSpeed2.text = I18N.Get(teachCfg:Desc())
    local isShowBuffNum = ModuleRefer.ScienceModule:CheckIsShowBuffNum(techId)
    self:RefreshDetailsProgress()
    self.goImgMastered:SetActive(isResearchAll)
    self.btnDetail.gameObject:SetActive(isShowBuffNum and teachCfg:LevelCfgListLength() > 1)
    local techLv = ModuleRefer.ScienceModule:GetTeachLevel(techId)
    local maxLevel = teachCfg:LevelCfgListLength()
    self.goSchedule:SetActive(isShowBuffNum)
    self.textUnmber3.text = ""
    self.textSpeedB.gameObject:SetActive(isShowBuffNum)
    if isShowBuffNum then
        self.goLayoutDesc1:SetActive(true)
        self.goLayoutDesc2:SetActive(false)
        self.tableviewproTableItem:SetVisible(false)
        self.goTypeCItem:SetActive(true)
        self.goIconArrowL:SetActive(not isResearchAll)
        self.goIconArrowR:SetActive(not isResearchAll)
        if isResearchAll then
            self.textUnmber3.text = maxLevel .. "/" .. maxLevel
        else
            self.textUnmber1.text = techLv
            self.textUnmber2.text = techLv + 1
            local isPercent, value = ModuleRefer.ScienceModule:GetBuffValue(techId, techLv + 1)
            if isPercent then
                value = value .. "%"
            end
            self.textSpeedB.text = '+' .. value
        end
    else
        self.goTypeCItem:SetActive(false)
        local getLevel
        if isResearchAll then
            getLevel = maxLevel
        else
            getLevel = techLv + 1
        end
        local itemIds = ModuleRefer.ScienceModule:GetAbilityRewardItems(techId, getLevel)
        local isShowItems = #itemIds > 0
        self.tableviewproTableItem:SetVisible(isShowItems)
        self.tableviewproTableItem:Clear()
        for i = 1, #itemIds do
            self.tableviewproTableItem:AppendData(itemIds[i])
        end
        self.goLayoutDesc1:SetActive(not isShowItems)
        self.goLayoutDesc2:SetActive(isShowItems)
    end
    if isResearchAll then
        self.goResources:SetActive(false)
        self.tableviewproTableSkill.gameObject:SetActive(false)
        self.textLock.gameObject:SetActive(false)
        self.goBtns:SetActive(false)
        self.textHine.gameObject:SetActive(false)
    else
        local isResearching = techId == ModuleRefer.ScienceModule:GetCurResearchingTech()
        local isCanResearch = ModuleRefer.ScienceModule:CheckIsCanResearch(techId)
        local isNextStage = teachCfg:Stage() == ModuleRefer.ScienceModule:GetCurScienceStage() + 1
        self.goResources:SetActive(isCanResearch and not isResearching)
        self.tableviewproTableSkill.gameObject:SetActive(not (isCanResearch or isNextStage))
        self.goBtns:SetActive(isCanResearch or isResearching)
        self.compALU2Editor:SetVisible(isCanResearch)
        self.textLock.gameObject:SetActive(isNextStage)
        local nextLevelCfg = ModuleRefer.ScienceModule:GetTechLevelCfg(techId,  techLv + 1)
        self.textHine.gameObject:SetActive(not (isResearching or isCanResearch))
        if isCanResearch then
            self.compChildTime.gameObject:SetActive(true)
            local nextTechLevelCfg = ModuleRefer.ScienceModule:GetTechLevelCfg(techId, techLv + 1)
            local costTime = ConfigTimeUtility.NsToSeconds(nextTechLevelCfg:ResearchTime())
            self.compChildTime:FeedData({fixTime = costTime})
        end
        if isCanResearch and not isResearching then
            local isEnoughItem = true
            local prcessArrays = {}
            self.lackList = {}
            local itemArrays = ModuleRefer.InventoryModule:ItemGroupId2ItemArrays(nextLevelCfg:ResearchCost()) or {}
            self.goResources:SetActive(#itemArrays > 0)
            for i = 1, #itemArrays do
                local cost = itemArrays[i]
                local singleItem = {}
                singleItem.configCell = ConfigRefer.Item:Find(cost.configCell:Id())
                singleItem.addCount = cost.count
                local curCount = ModuleRefer.InventoryModule:GetAmountByConfigId(cost.configCell:Id())
                singleItem.count = curCount
                singleItem.showNumPair = true
                singleItem.onClick = function() self:ClickItem(singleItem) end
                prcessArrays[#prcessArrays + 1] = singleItem
                if curCount < cost.count then
                    isEnoughItem = false
                    self.lackList[#self.lackList + 1] = {id = cost.configCell:Id(), num = cost.count - curCount}
                end
            end
            for i = 1, #self.costItems do
                self.costItems[i].gameObject:SetActive(i <= #prcessArrays)
                if i <= #prcessArrays then
                    self.costItems[i]:FeedData(prcessArrays[i])
                end
            end
            self.compALU2Editor:SetEnabled(isEnoughItem)
        elseif not isNextStage then
            self.tableviewproTableSkill:Clear()
            local showConditions = {}
            for i = 1, nextLevelCfg:PreBdConditionsLength() do
                local buildCond = {}
                local buildingLevelCfg = ConfigRefer.BuildingLevel:Find(nextLevelCfg:PreBdConditions(i))
                local buildingTypeCfg = ConfigRefer.BuildingTypes:Find(buildingLevelCfg:Type())
                buildCond.icon = buildingTypeCfg:Image()
                buildCond.name = buildingTypeCfg:Name()
                local maxLevels, unlockLevel = ModuleRefer.ScienceModule:GetUnlockBuildingLevel(nextLevelCfg:PreBdConditions(i))
                buildCond.curProgess = maxLevels
                buildCond.totalProgress = unlockLevel
                buildCond.curNum = maxLevels
                buildCond.totalNum = unlockLevel
                buildCond.isFinish = unlockLevel >= maxLevels
                if not buildCond.isFinish then
                    buildCond.onClick = function() end --todo 引导建造？
                end
                buildCond.index = #showConditions
                showConditions[#showConditions + 1] = buildCond
            end
            local addedTechs = {}
            for i = 1, teachCfg:ParentTechLength() do
                local singleTechCond = {}
                local parentTechId = teachCfg:ParentTech(i)
                local techLevelCfg = ConfigRefer.CityTechLevels:Find(parentTechId)
                local techLevel = ModuleRefer.ScienceModule:GetTeachLevel(techLevelCfg:Type())
                local parentTechCfg = ConfigRefer.CityTechTypes:Find(techLevelCfg:Type())
                singleTechCond.icon = ArtResourceUtils.GetUIItem(parentTechCfg:Image())
                singleTechCond.name = parentTechCfg:Name()
                singleTechCond.curProgess = techLevel
                singleTechCond.totalProgress = techLevelCfg:Level()
                singleTechCond.curNum = techLevel
                singleTechCond.totalNum = techLevelCfg:Level()
                singleTechCond.isFinish = techLevel >= techLevelCfg:Level()
                if not singleTechCond.isFinish then
                    singleTechCond.onClick = function() g_Game.EventManager:TriggerEvent(EventConst.ON_LOCK_TO_TECH, parentTechId) end
                end
                singleTechCond.index = #showConditions
                addedTechs[parentTechId] =  true
                showConditions[#showConditions + 1] = singleTechCond
            end
            for i = 1, nextLevelCfg:PreTechConditionsLength() do
                local singleTechCond = {}
                local techLevelId = nextLevelCfg:PreTechConditions(i)
                local techLevelCfg = ConfigRefer.CityTechLevels:Find(techLevelId)
                    if not addedTechs[techLevelCfg:Type()] then
                        local techLevel = ModuleRefer.ScienceModule:GetTeachLevel(techLevelCfg:Type())
                        local parentTechCfg = ConfigRefer.CityTechTypes:Find(techLevelCfg:Type())
                        singleTechCond.icon = ArtResourceUtils.GetUIItem(parentTechCfg:Image())
                        singleTechCond.name = parentTechCfg:Name()
                        singleTechCond.curProgess = techLevel
                        singleTechCond.totalProgress = techLevelCfg:Level()
                        singleTechCond.curNum = techLevel
                        singleTechCond.totalNum = techLevelCfg:Level()
                        singleTechCond.isFinish = techLevel >= techLevelCfg:Level()
                        if not singleTechCond.isFinish then
                            singleTechCond.onClick = function()  g_Game.EventManager:TriggerEvent(EventConst.ON_LOCK_TO_TECH, techLevelId) end
                        end
                        singleTechCond.index = #showConditions
                        showConditions[#showConditions + 1] = singleTechCond
                    end
            end
            local sortFunc = function(a, b)
                if a.isFinish ~= b.isFinish then
                    return not a.isFinish
                else
                    return a.index < b.index
                end
            end
            table.sort(showConditions, sortFunc)
            for _, conditionInfo in ipairs(showConditions) do
                self.tableviewproTableSkill:AppendData(conditionInfo)
            end
        end
    end
end


function UIScienceMediator:ClickItem(info)
    if info.count >= info.addCount then
        local param = {
            itemId = info.configCell:Id(),
            itemType = CommonItemDetailsDefine.ITEM_TYPE.ITEM,
        }
        g_Game.UIManager:Open(UIMediatorNames.PopupItemDetailsUIMediator, param)
    else
        ModuleRefer.InventoryModule:OpenExchangePanel({{id = info.configCell:Id()}})
    end
end


function UIScienceMediator:RefreshDetailsProgress()
    local isResearching = self.curSelectTechId == ModuleRefer.ScienceModule:GetCurResearchingTech()
    self.goProgress:SetActive(isResearching)
    self.goWork:SetActive(isResearching)
    self.compChildTime.gameObject:SetActive(isResearching)
    self.btnCompCLU2Editor.gameObject:SetActive(isResearching)
    if isResearching then
        if not self.detailsProgressTimer then
            self:OnDetailsProgress()
            self.detailsProgressTimer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnDetailsProgress), 1, -1)
        end
    else
        self:StopDetailsTimer()
    end
end

function UIScienceMediator:StopDetailsTimer()
    if self.detailsProgressTimer then
        TimerUtility.StopAndRecycle(self.detailsProgressTimer)
        self.detailsProgressTimer = nil
    end
end

function UIScienceMediator:OnDetailsProgress()
    local techId = ModuleRefer.ScienceModule:GetCurResearchingTech()
    if techId <= 0 then
        return
    end
    local teachLevel = ModuleRefer.ScienceModule:GetTeachLevel(techId)
    local finishTime = ModuleRefer.ScienceModule:GetCurResearchingTechFinishTime()
    local nextTechLevelCfg = ModuleRefer.ScienceModule:GetTechLevelCfg(techId, teachLevel + 1)
    local costTime = ConfigTimeUtility.NsToSeconds(nextTechLevelCfg:ResearchTime())
    local lastTime = finishTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if lastTime >= 0 then
        self.imgProgressBar.fillAmount = 1 -  lastTime / costTime
    else
        self.imgProgressBar.fillAmount = 1
    end
    self.compChildTime:FeedData({endTime = finishTime})
end

function UIScienceMediator:CheckIsShowLeftResearching()
    local researchingId = ModuleRefer.ScienceModule:GetCurResearchingTech()
    if researchingId <= 0 then
        self:ChangeResearchingState(false)
        return
    end
    local stageId = ConfigRefer.CityTechTypes:Find(researchingId):Stage()
    if self.showStage[stageId] then
        self:ChangeResearchingState(false)
    else
        self:ChangeResearchingState(true)
    end
end

function UIScienceMediator:CheckIsShowLeftCondi()
    local curStage = ModuleRefer.ScienceModule:GetCurScienceStage()
    local isShow = ModuleRefer.ScienceModule:IsMeetAllStageConditions(curStage)
    local nextStage = ConfigRefer.CityTechStage:Find(curStage):NextStage()
    local isLastStage = nextStage == 0
    if isLastStage or not isShow then
        self.itemConditionLeft.gameObject:SetActive(false)
        return
    end
    if self.showStage[curStage] then
        self.itemConditionLeft.gameObject:SetActive(false)
    else
        self.itemConditionLeft.gameObject:SetActive(true)
        self.itemConditionLeft:FeedData(curStage * 10000)
    end
end

function UIScienceMediator:OnBtnTipsClicked()
    -- local techId = ModuleRefer.ScienceModule:GetCurResearchingTech()
    -- self:ShowTechDetailsPanel(techId)
end

function UIScienceMediator:ChangeResearchingState(isShow)
    if self.forceShowTips then
        return
    end
    if Utils.IsNull(self.goTips) then
        return
    end
    self.goTips:SetActive(isShow)
    if isShow then
        self.goTipsContent.transform.localPosition = CS.UnityEngine.Vector3(81.5, 0, 0)
        if not self.researchingTimer then
            self:OnResearching()
            self.researchingTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.OnResearching), 0.1, -1)
        end
    else
        self:StopResearchingTimer()
    end
end

function UIScienceMediator:StopResearchingTimer()
    if self.researchingTimer then
        TimerUtility.StopAndRecycle(self.researchingTimer)
        self.researchingTimer = nil
    end
end

function UIScienceMediator:OnResearching()
    local researchingId = ModuleRefer.ScienceModule:GetCurResearchingTech()
    if researchingId <= 0 then
        self:ChangeResearchingState(false)
        return
    end
    local teachLevel = ModuleRefer.ScienceModule:GetTeachLevel(researchingId)
    local teachCfg = ConfigRefer.CityTechTypes:Find(researchingId)
    local totalLevel = teachCfg:LevelCfgListLength()
    if teachLevel == totalLevel then
        return
    end
    self:LoadSprite(teachCfg:Image(), self.imgIconItemTips)
    local finishTime = ModuleRefer.ScienceModule:GetCurResearchingTechFinishTime()
    local nextTechLevelCfg = ModuleRefer.ScienceModule:GetTechLevelCfg(researchingId, teachLevel + 1)
    local costTime = ConfigTimeUtility.NsToSeconds(nextTechLevelCfg:ResearchTime())
    local lastTime = finishTime - g_Game.ServerTime:GetServerTimestampInSeconds()
    if lastTime >= 0 then
        self.goIconLamp:SetActive(false)
        self.goFinish:SetActive(false)
        self.goChildScienceWorkTips:SetActive(true)
        self.imgProgressTipsBar.fillAmount = 1 -  lastTime / costTime
    end
end

function UIScienceMediator:OnFinishResearch(param)
    self.forceShowTips = true
    self:StopResearchingTimer()
    if self.delayRepateTimer then
        TimerUtility.StopAndRecycle(self.delayRepateTimer)
        self.delayRepateTimer = nil
    end
    self.delayRepateTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.OnResearchingFinish), 3, 1)
    self.goTips:SetActive(true)
    self.animationsTips:SetAnimationTime(self.animationsTips.clip.name, 0)
    self.animationsTips:Sample()
    self.animationsTips:Play()
    self.goChildScienceWorkTips:SetActive(false)
    self.goFinish:SetActive(true)
    self.imgProgressTipsBar.fillAmount = 1
    local teachCfg = ConfigRefer.CityTechTypes:Find(param.id)
    local totalLevel = teachCfg:LevelCfgListLength()
    self:LoadSprite(teachCfg:Image(), self.imgIconItemTips)
    self.textFinish.text = I18N.Get(teachCfg:Name()) .. I18N.Get("tech_info_achieve")
    self.textNumberSchedule.text = param.lv .. "/" .. totalLevel
    self.goIconLamp.transform.localPosition = self.goLampOriginPos
    self.goIconLamp.transform.localScale = CS.UnityEngine.Vector3.one
    self.goIconLamp:SetActive(true)
    self.goIconLamp.transform:DOMove(self.goTargetLamp.transform.position, 1.8):SetEase(CS.DG.Tweening.Ease.InOutQuart):OnComplete(function()
        self.goIconLamp.transform:DOScale(1.5, 0.2):SetEase(CS.DG.Tweening.Ease.InOutElastic)
    end)
    self:RefreshCurStageInfo(-1)
    if self.delayHideLampTimer then
        TimerUtility.StopAndRecycle(self.delayHideLampTimer)
        self.delayHideLampTimer = nil
    end
    self.delayHideLampTimer = TimerUtility.IntervalRepeat(Delegate.GetOrCreate(self, self.HideLamp), 2, 1)
    self:CloseCancelPanel()
end

function UIScienceMediator:HideLamp()
    self:RefreshCurStageInfo()
    self.goIconLamp:SetActive(false)
end

function UIScienceMediator:OnResearchingFinish()
    self.forceShowTips = false
    self:ChangeResearchingState(false)
end

function UIScienceMediator:OnBackBtnClick()
    self:BackToPrevious()
end

function UIScienceMediator:OnBtnDetailClicked()
    local isShow = not self.goTipsDetail.activeSelf
    self.goTipsDetail:SetActive(isShow)
    if isShow then
        local teachCfg = ConfigRefer.CityTechTypes:Find(self.curSelectTechId)
        self.textNameTips.text = I18N.Get("tech_info_preview")
        self.textContentTips.text = I18N.Get(teachCfg:Desc())
        for i = 1, 3 do
            local isShowTips = i <= teachCfg:LevelCfgListLength()
            self.tipsGos[i]:SetActive(isShowTips)
            if isShowTips then
                self.tipsLvs[i].text = i
                local isPercent, value = ModuleRefer.ScienceModule:GetBuffValue(self.curSelectTechId, i)
                if isPercent then
                    value = value .. "%"
                end
                self.tipsAdds[i].text = value
            end
        end
    end
end

function UIScienceMediator:CloseCancelPanel()
    g_Game.UIManager:CloseByName(UIMediatorNames.CommonConfirmPopupMediator)
end

function UIScienceMediator:OnBtnCompALU2EditorClicked()
    if ModuleRefer.ScienceModule:GetCurResearchingTech() <= 0 then
        local param = CastleUnlockTechnologyParameter.new()
        local techCfg = ConfigRefer.CityTechTypes:Find(self.curSelectTechId)
        local techLevel = techCfg:LevelCfgList(ModuleRefer.ScienceModule:GetTeachLevel(self.curSelectTechId) + 1)
        param.args.ConfigId = techLevel
        param:Send(self.compALU2Editor.button.transform)
    else
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("tech_info_fullqueue"))
    end
end

function UIScienceMediator:OnBtnCompCLU2EditorClicked()
    local dialogParam = {}
    dialogParam.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.ExitBtn
    dialogParam.title = I18N.Get("tech_info_tips")
    dialogParam.content = I18N.GetWithParams("tech_info_stop_tips") .. I18N.GetWithParams("tech_info_stop_rerurn")
    dialogParam.onConfirm = function()
        local param = CastleCancelUnlockTechParameter.new()
        param:Send(self.btnCompCLU2Editor.transform)
        return true
    end
    g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, dialogParam)
end


function UIScienceMediator:OnBtnNewStageClicked()
    local curStage = ModuleRefer.ScienceModule:GetCurScienceStage()
    local nextStage = curStage + 1
    self:LockToTargetStage(nextStage)
end

function UIScienceMediator:OnBtnCloseClicked()
    self.goPopupDetail:SetActive(false)
    self.goTipsDetail:SetActive(false)
    self:StopDetailsTimer()
end

function UIScienceMediator:OnClose()
    self.goIconLamp.transform:DOKill()
    self:StopDetailsTimer()
    self:StopResearchingTimer()
    if self.delayRepateTimer then
        TimerUtility.StopAndRecycle(self.delayRepateTimer)
        self.delayRepateTimer = nil
    end
    if self.delayHideLampTimer then
        TimerUtility.StopAndRecycle(self.delayHideLampTimer)
        self.delayHideLampTimer = nil
    end
    g_Game.EventManager:TriggerEvent(EventConst.ON_REFRESH_TECH)
    self.tableviewproTable.BeginDragAction = nil
    g_Game.EventManager:RemoveListener(EventConst.ON_REFRESH_TECH_STAGE_WDS, Delegate.GetOrCreate(self, self.OnUnlockNewStage))
    g_Game.EventManager:RemoveListener(EventConst.ON_REFRESH_TECH_RESEARCHING, Delegate.GetOrCreate(self, self.OnResearchingNewTech))
    g_Game.EventManager:RemoveListener(EventConst.ON_CLICK_TECH_NODE, Delegate.GetOrCreate(self, self.ShowTechDetailsPanel))
    g_Game.EventManager:RemoveListener(EventConst.ON_ADD_TECH_STAGE, Delegate.GetOrCreate(self, self.AddShowStage))
    g_Game.EventManager:RemoveListener(EventConst.ON_REMOVE_TECH_STAGE, Delegate.GetOrCreate(self, self.RemoveShowStage))
    g_Game.EventManager:RemoveListener(EventConst.ON_CLICK_EMPTY, Delegate.GetOrCreate(self, self.OnBtnCloseClicked))
    g_Game.EventManager:RemoveListener(EventConst.ON_FINISH_RESEARCH, Delegate.GetOrCreate(self, self.OnFinishResearch))
    g_Game.EventManager:RemoveListener(EventConst.ON_CLICK_NEW_CHAPTER, Delegate.GetOrCreate(self, self.OnBtnNewStageClicked))
    g_Game.EventManager:RemoveListener(EventConst.ON_LOCK_TO_TECH, Delegate.GetOrCreate(self, self.LockToTargetTech))
end

return UIScienceMediator
