--- scene:scene_story_chat_popup

local Delegate = require("Delegate")
local StoryDialogUIMediatorHelper = require("StoryDialogUIMediatorHelper")
local StoryDialogUIMediatorDialogPlayer = require("StoryDialogUIMediatorDialogPlayer")
local Utils = require("Utils")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local UIMediatorNames = require("UIMediatorNames")

local BaseUIMediator = require("BaseUIMediator")

---@class StoryDialogChatUIMediator:BaseUIMediator
---@field new fun():StoryDialogChatUIMediator
---@field super BaseUIMediator
local StoryDialogChatUIMediator = class('StoryDialogChatUIMediator', BaseUIMediator)

function StoryDialogChatUIMediator:OnCreate(param)
    self._p_img_bg = self:Image("p_img_bg")
    self._p_btn_click = self:Button("p_btn_click", Delegate.GetOrCreate(self, self.OnClickNext))
    self._p_content = self:RectTransform("p_content")
    self._p_group_popup_cell_rect = self:RectTransform("p_group_popup_cell")
    ---@type StoryDialogChatUICell
    self._p_group_popup_cell = self:LuaBaseComponent("p_group_popup_cell").Lua
    self._p_group_popup_cell:SetOnClick(Delegate.GetOrCreate(self, self.OnClickNext))
    self._p_btn_top = self:GameObject("p_btn_top")
    self._p_btn_record = self:Button("p_btn_record", Delegate.GetOrCreate(self, self.OnClickRecord))
    self._p_btn_auto = self:Button("p_btn_auto", Delegate.GetOrCreate(self, self.OnClickAuto))
    ---@type CS.StatusRecordParent
    self._s_auto_status = self.CSComponent:GetWithUniqueName("p_btn_auto",typeof(CS.StatusRecordParent))
    self._p_btn_skip = self:Button("p_btn_skip", Delegate.GetOrCreate(self, self.OnClickSkip))
end

---@param param StoryDialogUIMediatorParameter
function StoryDialogChatUIMediator:OnOpened(param)
    if not param._isDialogGroup then
        g_Logger.Error("param:StoryDialogUIMediatorParameter must _isDialogGroup==true !")
        return
    end
    self._param = param
    ---@type StoryDialogUIMediatorDialogPlayerOperateTargets
    local operateTarget = {}
    operateTarget.nameTxt = self._p_group_popup_cell._p_text_name_1
    operateTarget.contentTxt = self._p_group_popup_cell._p_text_content_1
    operateTarget.headIcon = self._p_group_popup_cell._p_img_hero_1
    
    self._operateTarget = operateTarget
    
    ---@type StoryDialogUIMediatorDialogPlayerParameter
    local parameter = {}
    parameter.dialogQueue = StoryDialogUIMediatorHelper.MakeDialogQueue(self._param._dialogList)
    parameter.onDialogGroupEnd = Delegate.GetOrCreate(self, self.OnDialogGroupEnd)
    parameter.onGetOperateTargets = Delegate.GetOrCreate(self, self.GetOperateTargets)
    parameter.onSetHeadIcon = Delegate.GetOrCreate(self, self.SetHeadIcon)
    parameter.onSetChatPosition = Delegate.GetOrCreate(self, self.SetChatPosition)
    parameter.onSetBackground = Delegate.GetOrCreate(self, self.SetBackground)
    parameter.noTyperEffect = true
    self._dialogPlayer = StoryDialogUIMediatorDialogPlayer.new(parameter)
    self:StartNextDialog()
    if self._param._dialogGroupConfig:AutoPlay() > 0 then
        self._dialogPlayer:SwitchAutoStatus(1)
        self._p_group_popup_cell._p_self_click.enabled = true
        self._p_btn_click:SetVisible(false)
    else
        self._p_group_popup_cell._p_self_click.enabled = false
        self._p_btn_click:SetVisible(true)
    end
end

function StoryDialogChatUIMediator:OnShow(param)
    BaseUIMediator.OnShow(self, param)
    self.__canDelayCleanUp = false
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function StoryDialogChatUIMediator:OnHide(param)
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    BaseUIMediator.OnHide(self, param)
end

function StoryDialogChatUIMediator:OnClose(data)
    if self._dialogPlayer then
        self._dialogPlayer:CleanUp()
    end
    g_Game.EventManager:TriggerEvent(EventConst.STORY_DIALOG_UI_CLOSED)
    BaseUIMediator.OnClose(self,data)
end

function StoryDialogChatUIMediator:OnClickNext()
    self._dialogPlayer:OnClickDialogNext()
end

function StoryDialogChatUIMediator:StartNextDialog()
    self._dialogPlayer:StartNextDialog()
end

function StoryDialogChatUIMediator:OnDialogGroupEnd()
    if self._param._dialogEndCallback then
        self._param._dialogEndCallback(self:GetRuntimeId())
    end
end

function StoryDialogChatUIMediator:GetOperateTargets(mode)
    return self._operateTarget
end

function StoryDialogChatUIMediator:SetHeadIcon(pic, heroIcon)
    if string.IsNullOrEmpty(pic) then
        g_Game.SpriteManager:LoadSprite("sp_icon_missing", heroIcon)
        return
    end
    g_Game.SpriteManager:LoadSprite(pic, heroIcon)
end

---@param config StoryDialogConfigCell
function StoryDialogChatUIMediator:SetChatPosition(config)
    if not config then
        return
    end
    local posStr = config:SmallDialogLocation()
    if string.IsNullOrEmpty(posStr) then
        return
    end
    local posArray = string.split(posStr, ',')
    if posArray and #posArray > 1 then
        local posNormalizedX = tonumber(posArray[1])
        local posNormalizedY = tonumber(posArray[2])
        if posNormalizedX and posNormalizedY then
            posNormalizedX = math.clamp01(posNormalizedX)
            posNormalizedY = math.clamp01(posNormalizedY)
            local anchorPos = CS.UnityEngine.Vector2(posNormalizedX,posNormalizedY)
            self._p_group_popup_cell_rect.anchorMin = anchorPos
            self._p_group_popup_cell_rect.anchorMax = anchorPos
            self._p_group_popup_cell_rect.anchoredPosition = CS.UnityEngine.Vector2.zero
        end
    end
end

---@param show boolean
---@param img string
function StoryDialogChatUIMediator:SetBackground(show, img)
    if Utils.IsNull(self._p_img_bg) then
        return
    end
    if not show then
        self._p_img_bg:SetVisible(false)
    else
        self._p_img_bg:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(img, self._p_img_bg)
    end
end

function StoryDialogChatUIMediator:OnTick(dt)
    if self._dialogPlayer then
        self._dialogPlayer:Tick(dt)
    end
end

function StoryDialogChatUIMediator:OnClickRecord()
    if not self._dialogPlayer then
        return
    end
    local dialogGroupId = self._param._dialogGroupConfig:Id()
    local record = ModuleRefer.StoryModule:BuildStoryRecord(dialogGroupId, self._dialogPlayer:GetCurrentIndex())
    ---@type StoryDialogRecordUIMediatorParameter
    local param = {}
    param.record = record
    g_Game.UIManager:Open(UIMediatorNames.StoryDialogRecordUIMediator, param)
end

function StoryDialogChatUIMediator:OnClickAuto()
    if self._dialogPlayer then
        local s = self._dialogPlayer:ToggleAutoStatus()
        self._s_auto_status:SetState(s)
    end
end

function StoryDialogChatUIMediator:OnClickSkip()
    local dialogGroupId = self._param._dialogGroupConfig:Id()
    local summaryContent, storyGroup ,stopAt = ModuleRefer.StoryModule:BuildStorySummary(dialogGroupId)
    if table.isNilOrZeroNums(summaryContent) then
        if self._param._dialogEndCallback then
            self._param._dialogEndCallback(self:GetRuntimeId())
        end
        return
    end
    ---@type StoryDialogSkipPopupUIMediatorParameter
    local param = {}
    param.content = summaryContent
    param.callback = function(isSkip)
        if isSkip then
            ModuleRefer.StoryModule:MarkFastForwardStory(storyGroup, stopAt)
            if self._param._dialogEndCallback then
                self._param._dialogEndCallback(self:GetRuntimeId())
            end
        end
    end
    g_Game.UIManager:Open(UIMediatorNames.StoryDialogSkipPopupUIMediator, param)
end

return StoryDialogChatUIMediator

