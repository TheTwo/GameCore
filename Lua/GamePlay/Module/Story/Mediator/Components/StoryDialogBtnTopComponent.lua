local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")

--- scene:scene_child_stroy_dialog_btn_top
local BaseUIComponent = require("BaseUIComponent")

---@class StoryDialogBtnTopComponent:BaseUIComponent
---@field new fun():StoryDialogBtnTopComponent
---@field super BaseUIComponent
---@field host StoryDialogUIMediator
local StoryDialogBtnTopComponent = class('StoryDialogBtnTopComponent', BaseUIComponent)

function StoryDialogBtnTopComponent:OnCreate(param)
    -- btn
    self._btn_auto = self:Button("p_btn_auto", Delegate.GetOrCreate(self, self.OnClickAutoBtn))
    ---@type CS.StatusRecordParent
    self._s_auto_status = self.CSComponent:GetWithUniqueName("p_btn_auto",typeof(CS.StatusRecordParent))
    self._btn_record = self:Button("p_btn_record", Delegate.GetOrCreate(self, self.OnClickRecordBtn))
    self._btn_skip = self:Button("p_btn_skip", Delegate.GetOrCreate(self, self.OnClickSkipBtn))
    self._p_btn_speed = self:Button("p_btn_speed", Delegate.GetOrCreate(self, self.OnClickSpeedBtn))
    self._p_icon_1x = self:Image("p_icon_1x")
    self._p_icon_2x = self:Image("p_icon_2x")
    self._p_text_record = self:Text("p_text_record", "Story_RecordUI_Disc")
    self._p_text_auto = self:Text("p_text_auto", "Story_AutoUI_Disc")
    self._p_text_auto = self:Text("p_text_skip", "Story_SkipUI_Disc")
    self._g_topBtnNode = self:GameObject("")
    self._btn_tendency = self:Button("p_btn_tendency", Delegate.GetOrCreate(self, self.OnClickTendencyBtn))
end

function StoryDialogBtnTopComponent:InitForDialog()
    self._g_topBtnNode:SetActive(true)
    self._s_auto_status:SetState(0, true)
    self._p_btn_speed:SetVisible(false)

    local cfg = self.host._param._dialogGroupConfig
    self._btn_skip:SetVisible(cfg:CanSkip() > 0)
end

function StoryDialogBtnTopComponent:InitForChoice()
    if not self.host._param.showTendency then
        self._btn_tendency.gameObject:SetActive(false)
    else
        self._btn_tendency.gameObject:SetActive(true)
    end
end

function StoryDialogBtnTopComponent:OnClickRecordBtn()
    if not self.host._dialogPlayer then
        return
    end
    if self.host._dialogPlayer:GetAutoStatus() == 1 then
        local s = self.host._dialogPlayer:SwitchAutoStatus(0)
        self:RefreshToggleAutoShowStatus(s)
    end
    local dialogGroupId = self.host._param._dialogGroupConfig:Id()
    local record = ModuleRefer.StoryModule:BuildStoryRecord(dialogGroupId, self.host._dialogPlayer:GetCurrentIndex())
    ---@type StoryDialogRecordUIMediatorParameter
    local param = {}
    param.record = record
    g_Game.UIManager:Open(UIMediatorNames.StoryDialogRecordUIMediator, param)
end

function StoryDialogBtnTopComponent:OnClickSkipBtn()
    local dialogGroupId = self.host._param._dialogGroupConfig:Id()
    local summaryContent, storyGroup ,stopAt = ModuleRefer.StoryModule:BuildStorySummary(dialogGroupId)
    if table.isNilOrZeroNums(summaryContent) then
        if self.host._param._dialogEndCallback then
            self.host._param._dialogEndCallback(self.host:GetRuntimeId())
        end
        return
    end
    ---@type StoryDialogSkipPopupUIMediatorParameter
    local param = {}
    param.content = summaryContent
    param.callback = function(isSkip)
        if isSkip then
            ModuleRefer.StoryModule:MarkFastForwardStory(storyGroup, stopAt)
            if self.host._param._dialogEndCallback then
                self.host._param._dialogEndCallback(self.host:GetRuntimeId())
            end
        end
    end
    g_Game.UIManager:Open(UIMediatorNames.StoryDialogSkipPopupUIMediator, param)
end

function StoryDialogBtnTopComponent:OnClickSpeedBtn()
    if not self.host._dialogPlayer then
        return
    end
    local s = self.host._dialogPlayer:TogglePlaySpeedMode()
    self._p_icon_1x:SetVisible(s == 1)
    self._p_icon_2x:SetVisible(s == 2)
end

function StoryDialogBtnTopComponent:RefreshToggleAutoShowStatus(status)
    self._s_auto_status:SetState(status)
    self._p_btn_speed:SetVisible(status == 1)
    if status == 1 then
        local s = self.host._dialogPlayer:GetPlaySpeedMode()
        self._p_icon_1x:SetVisible(s == 1)
        self._p_icon_2x:SetVisible(s == 2)
    else
        self._p_icon_1x:SetVisible(false)
        self._p_icon_2x:SetVisible(false)
    end
end

function StoryDialogBtnTopComponent:OnClickTendencyBtn()
    g_Game.UIManager:Open(UIMediatorNames.WorldTrendMediator, {focusCurStage = true})
end

function StoryDialogBtnTopComponent:OnClickAutoBtn()
    if not self.host._dialogPlayer then
        return
    end
    local s = self.host._dialogPlayer:ToggleAutoStatus()
    self:RefreshToggleAutoShowStatus(s)
end

return StoryDialogBtnTopComponent