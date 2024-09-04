local BaseUIComponent = require('BaseUIComponent')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local ModuleRefer = require('ModuleRefer')
local I18N = require('I18N')
local Utils = require("Utils")
local UIHelper = require("UIHelper")
local EventConst = require('EventConst')
local TimerUtility = require("TimerUtility")
local NodeCell = class('NodeCell',BaseUIComponent)
local ConfigTimeUtility = require("ConfigTimeUtility")

function NodeCell:OnCreate(param)
    self.btnNotes = self:Button('', Delegate.GetOrCreate(self, self.OnBtnNotesClicked))
    self.animationNotes = self:BindComponent("", typeof(CS.UnityEngine.Animation))
    self.goLineL = self:GameObject('p_line_l')
    self.goLineLLock = self:GameObject('p_line_l_lock')
    self.goLineLUnlock = self:GameObject('p_line_l_unlock')
    self.goNailL = self:GameObject('p_icon_nail_l')
    self.goLineR = self:GameObject('p_line_r')
    self.goLineRLock = self:GameObject('p_line_r_lock')
    self.goLineRUnlock = self:GameObject('p_line_r_unlock')
    self.goNailR = self:GameObject('p_icon_nail_r')
    self.goBaseLock = self:GameObject('p_base_lock')
    self.imgIconItemLock = self:Image('p_icon_item_lock')
    self.textNameTaskLock = self:Text('p_text_name_task_lock')
    self.textQuantityTaskLock = self:Text('p_text_quantity_task_lock')
    self.goTypeBLock = self:GameObject('p_type_b_lock')
    self.goTypeCLock = self:GameObject('p_type_c_lock')
    self.goBaseN = self:GameObject('p_base_n')
    self.imgIconItem = self:Image('p_icon_item')
    self.textNameTask = self:Text('p_text_name_task')
    self.textQuantityTask = self:Text('p_text_quantity_task')
    self.goTypeB = self:GameObject('p_type_b')
    self.goTypeC = self:GameObject('p_type_c')
    self.goGroupProgress = self:GameObject('p_group_progress')
    self.imgProgress = self:Image('p_progress')
    self.imgIconCheck = self:Image('p_icon_check')
    self.goWorking = self:GameObject('p_working')
    self.compChildTime = self:LuaBaseComponent('child_time')
    self.goImgMask = self:GameObject('p_img_mask')
    self.goImgSelect = self:GameObject('p_img_select')
    self.goNailL:SetActive(false)
    self.goNailR:SetActive(false)

end

function NodeCell:OnFeedData(techId)
    self.techId = techId
    local isShowBuffNum = ModuleRefer.ScienceModule:CheckIsShowBuffNum(techId)
    local techCfg = ConfigRefer.CityTechTypes:Find(techId)
    if techCfg:ParentTechLength() == 0 then
        self.goLineL:SetActive(false)
    else             --------左侧线解锁需要所有的父节点都研究过
        self.goLineL:SetActive(true)
        local isLightL = true --ModuleRefer.ScienceModule:CheckIsResearched(techId)
        for i = 1, techCfg:ParentTechLength() do
            if not ModuleRefer.ScienceModule:CheckIsResearched(techCfg:ParentTech(i)) then
                isLightL = false
            end
        end
        self.goLineLLock:SetActive(not isLightL)
        self.goLineLUnlock:SetActive(isLightL)
    end
    if techCfg:ChildTechLength() == 0 then
        self.goLineR:SetActive(false)
    else             --------右侧线解锁需要自身研究过
        self.goLineR:SetActive(true)
        local isLightR = ModuleRefer.ScienceModule:CheckIsResearched(techId)
        -- local isLightChild = false
        -- for i = 1, techCfg:ChildTechLength() do
        --     if ModuleRefer.ScienceModule:CheckIsResearched(techCfg:ChildTech(i)) then
        --         isLightChild = true
        --     end
        -- end
        -- isLightR = isLightR and isLightChild
        self.goLineRLock:SetActive(not isLightR)
        self.goLineRUnlock:SetActive(isLightR)
    end
    local curStage = ModuleRefer.ScienceModule:GetCurScienceStage()
    --local isResearched = ModuleRefer.ScienceModule:CheckIsResearched(techId)
    local isResearching = techId == ModuleRefer.ScienceModule:GetCurResearchingTech()
    local techLevel = ModuleRefer.ScienceModule:GetTeachLevel(techId)
    local totalLevel = techCfg:LevelCfgListLength()
    local isResearchAll = techLevel == totalLevel
    self.goGroupProgress:SetActive(isResearching)
    self.goWorking:SetActive(isResearching)
    self.imgIconCheck.gameObject:SetActive(isResearchAll)
    self.imgIconCheck.fillAmount = 1
    self.compChildTime.gameObject:SetActive(isResearching)
    local isCanResearch = ModuleRefer.ScienceModule:CheckIsCanResearch(techId)
    local isNextStage = techCfg:Stage() == curStage + 1
    self.btnNotes.gameObject.transform.name = techId
    self.btnNotes.interactable = true
    if isNextStage or not (isCanResearch or isResearchAll) then
        self.goBaseN:SetActive(false)
        self.goBaseLock:SetActive(true)
        if isNextStage and not techCfg:DefaultVisible() then
            self.goImgMask:SetActive(true)
            self.btnNotes.interactable = false
        else
            self.goImgMask:SetActive(false)
        end
        self:LoadSprite(techCfg:Image(), self.imgIconItemLock)
        UIHelper.SetGray(self.imgIconItemLock.gameObject, techLevel <= 0)
        self.textNameTaskLock.text = I18N.Get(techCfg:Name())
        self.goTypeBLock:SetActive(false)
        self.goTypeCLock:SetActive(isShowBuffNum)
    else
        self.goTypeB:SetActive(false)
        self.goTypeC:SetActive(isShowBuffNum)
        self.goBaseLock:SetActive(false)
        self.goBaseN:SetActive(true)
        self.goImgMask:SetActive(false)
        self:LoadSprite(techCfg:Image(), self.imgIconItem)
        UIHelper.SetGray(self.imgIconItem.gameObject, not (isCanResearch or isResearchAll))
        self.textNameTask.text = I18N.Get(techCfg:Name())
        if isResearchAll then
            self.textQuantityTask.text = ("<color=#6B9936>%s</color>"):format(techLevel .. "/" .. totalLevel)
        else
            self.textQuantityTask.text = techLevel .. "/" .. totalLevel
        end
        if isResearching then
            if not self.progressTimer then
                self:OnProgress()
                self.progressTimer = TimerUtility.StartFrameTimer(Delegate.GetOrCreate(self, self.OnProgress), 1, -1)
            end
        else
            self:StopTimer()
        end
    end
end

function NodeCell:OnProgress()
    local techId = self.techId
    local teachLevel = ModuleRefer.ScienceModule:GetTeachLevel(techId)
    local finishTime = ModuleRefer.ScienceModule:GetCurResearchingTechFinishTime()
    local nextTechLevelCfg = ModuleRefer.ScienceModule:GetTechLevelCfg(techId, teachLevel + 1)
    local costTime = ConfigTimeUtility.NsToSeconds(nextTechLevelCfg:ResearchTime())
    local lastTime = finishTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if lastTime >= 0 then
        self.imgProgress.fillAmount = 1 -  lastTime / costTime
    else
        self.imgProgress.fillAmount = 1
        self:StopTimer()
        g_Logger.Log("GetServerTimestampInMilliseconds: " .. g_Game.ServerTime:GetServerTimestampInMilliseconds())
    end
    self.compChildTime:FeedData({endTime = finishTime, color = CS.UnityEngine.Color.white})
end

function NodeCell:StopTimer()
    if self.progressTimer then
        TimerUtility.StopAndRecycle(self.progressTimer)
        self.progressTimer = nil
    end
end

function NodeCell:OnShow()
    g_Game.EventManager:AddListener(EventConst.ON_CLICK_TECH_NODE, Delegate.GetOrCreate(self, self.ChangeSelectStatus))
    g_Game.EventManager:AddListener(EventConst.ON_LOCK_TO_TECH, Delegate.GetOrCreate(self, self.ChangeSelectStatus))
end

function NodeCell:OnHide()
    self:StopTimer()
    g_Game.EventManager:RemoveListener(EventConst.ON_CLICK_TECH_NODE, Delegate.GetOrCreate(self, self.ChangeSelectStatus))
    g_Game.EventManager:RemoveListener(EventConst.ON_LOCK_TO_TECH, Delegate.GetOrCreate(self, self.ChangeSelectStatus))
end

function NodeCell:OnClose()
    self:StopTimer()
end

function NodeCell:OnRecycle()
    self:StopTimer()
end

function NodeCell:ChangeSelectStatus(techId)
    if Utils.IsNull(self.goImgSelect) then
        return
    end
    if self.techId and techId then
        self.goImgSelect:SetActive(techId == self.techId)
    else
        self.goImgSelect:SetActive(false)
    end
end

function NodeCell:OnBtnNotesClicked()
    g_Game.EventManager:TriggerEvent(EventConst.ON_CLICK_TECH_NODE, self.techId)
end

return NodeCell
