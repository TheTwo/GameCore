--- scene: scene_story_dialog

local Delegate = require("Delegate")
local UIMediatorNames = require('UIMediatorNames')
local UIHelper = require("UIHelper")
local SEEnvironment = require("SEEnvironment")
local SeScene = require("SeScene")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")

local BaseUIMediator = require("BaseUIMediator")
local TimerUtility = require("TimerUtility")

---@class StoryDialogUIMediator:BaseUIMediator
---@field new fun():StoryDialogUIMediator
---@field super BaseUIMediator
local StoryDialogUIMediator = class('StoryDialogUIMediator', BaseUIMediator)

---@class OptionPair
---@field Btn CS.UnityEngine.UI.Button
---@field Lb CS.UnityEngine.UI.Text

function StoryDialogUIMediator:ctor()
    BaseUIMediator.ctor(self)
    ---@type StoryDialogUIMediatorParameter
    self._param = nil
    ---@type SetPortraitCallBack[]
    self._lastSetPortraits = {}
    ---@type StoryDialogUiOptionCellData[]
    self._sideChoiceOptionData = {}
    ---@type fun()
    self._checkRestoreSeSceneClickMove = nil
    ---@type CS.UnityEngine.GameObject[]
    self._createdCaptions = {}

    ---@type table<string, {name:string, parent:string, onloaded:fun(go:CS.UnityEngine.GameObject)}>
    self._compLoadWrap = {
        child_story_dialog_npc_left_1 = {name = "child_story_dialog_npc_left_1", onloaded = Delegate.GetOrCreate(self, self.NpcPartLoaded)},
        child_story_caption = {name = "child_story_caption", onloaded = Delegate.GetOrCreate(self, self.CaptionLoaded)},
        child_stroy_dialog_btn_top = {name = "child_stroy_dialog_btn_top", onloaded = Delegate.GetOrCreate(self, self.TopPartLoaded)},
        child_story_options_fullscreen = {name = "child_story_options_fullscreen", onloaded = Delegate.GetOrCreate(self, self.FullscreenLoaded)},
    }
    self.compNeed = {}
    ---@type table<string, CS.DragonReborn.UI.LuaBaseComponent>
    self._loadedComponents = {}
    self._dialogPlayer = nil
    ---@type CS.DragonReborn.UI.UIHelper.CallbackHolder[]
    self._loadingCallbackHolders = {}
end

---@param go CS.UnityEngine.GameObject
function StoryDialogUIMediator:NpcPartLoaded(go)
    self.compNeed[self._compLoadWrap.child_story_dialog_npc_left_1.name] = nil
    self._loadedComponents[self._compLoadWrap.child_story_dialog_npc_left_1.name] = self:LuaBaseComponent(self._compLoadWrap.child_story_dialog_npc_left_1.name)
    self:RemoveAsyncLoadFlag()
end

---@param go CS.UnityEngine.GameObject
function StoryDialogUIMediator:CaptionLoaded(go)
    self.compNeed[self._compLoadWrap.child_story_caption.name] = nil
    self._loadedComponents[self._compLoadWrap.child_story_caption.name] = self:LuaBaseComponent(self._compLoadWrap.child_story_caption.name)
    self:RemoveAsyncLoadFlag()
end

---@param go CS.UnityEngine.GameObject
function StoryDialogUIMediator:TopPartLoaded(go)
    self.compNeed[self._compLoadWrap.child_stroy_dialog_btn_top.name] = nil
    self._loadedComponents[self._compLoadWrap.child_stroy_dialog_btn_top.name] = self:LuaBaseComponent(self._compLoadWrap.child_stroy_dialog_btn_top.name)
    self:RemoveAsyncLoadFlag()
end

---@param go CS.UnityEngine.GameObject
function StoryDialogUIMediator:FullscreenLoaded(go)
    self.compNeed[self._compLoadWrap.child_story_options_fullscreen.name] = nil
    self._loadedComponents[self._compLoadWrap.child_story_options_fullscreen.name] = self:LuaBaseComponent(self._compLoadWrap.child_story_options_fullscreen.name)
    self:RemoveAsyncLoadFlag()
end

---@param param StoryDialogUIMediatorParameter
function StoryDialogUIMediator:OnCreate(param)
    -- background
    self._img_background = self:Image("p_base_background")
    self._img_mask = self:Image("p_mask", Delegate.GetOrCreate(self, self.OnClickMask))
    self._img_mask_text = self:Image("p_mask_text", Delegate.GetOrCreate(self, self.OnClickMask))
    ---@type CS.FpAnimation.FpAnimationCommonTrigger
    self._p_vx_anim_trigger = self:AnimTrigger("p_vx_anim_trigger")

    self:CheckAndLoadPart(param)
end

function StoryDialogUIMediator:AddToNeedLoadPart(partName)
    if not self._loadedComponents[partName] then
        self.compNeed[partName] = true
    end
end

---@param param StoryDialogUIMediatorParameter
function StoryDialogUIMediator:CheckAndLoadPart(param)
    if not param then return end
    if param._isDialogGroup or param._isCaptionGroup then
        self:AddToNeedLoadPart(self._compLoadWrap.child_story_dialog_npc_left_1.name)
        self:AddToNeedLoadPart(self._compLoadWrap.child_stroy_dialog_btn_top.name)
        self:AddToNeedLoadPart(self._compLoadWrap.child_story_caption.name)
    elseif param._isChoiceGroup then
        ---@type StoryDialogUIMediatorParameterChoiceProvider
        local cfg = param._choiceConfig
        local type = cfg:Type()
        if type == 2 or type == 3 then
            self:AddToNeedLoadPart(self._compLoadWrap.child_story_dialog_npc_left_1.name)
        else
            self:AddToNeedLoadPart(self._compLoadWrap.child_story_options_fullscreen.name)
        end
    end
    for _, _ in pairs(self.compNeed) do
        self:SetAsyncLoadFlag()
    end
    for prefabIdx, _ in pairs(self.compNeed) do
        local loadWrap = self._compLoadWrap[prefabIdx]
        local holder = CS.DragonReborn.UI.UIHelper.GeneratorChildManually(self.CSComponent, loadWrap.name, "content_animation", loadWrap.onloaded,false)
        if holder then
            table.insert(self._loadingCallbackHolders, holder)
        end
    end
end

function StoryDialogUIMediator:OnClose(data)
    if self._dialogPlayer then
        self._dialogPlayer:CleanUp()
    end
    if self._captionGroup and self._captionGroup._typerStyle then
        self._captionGroup._typerStyle:StopTyping()
    end
    for i, v in pairs(self._lastSetPortraits) do
        if v then
            v:Release()
        end
    end
    table.clear(self._lastSetPortraits)
    BaseUIMediator.OnClose(self, data)
    g_Game.EventManager:TriggerEvent(EventConst.STORY_DIALOG_UI_CLOSED)
    for index = #self._loadingCallbackHolders, 1, -1 do
        self._loadingCallbackHolders[index]:AbortAndCleanup()
        self._loadingCallbackHolders[index] = nil
    end
end

---@param param StoryDialogUIMediatorParameter
function StoryDialogUIMediator:OnOpened(param)
    self._param = param
    self._param._uiRuntimeId = self:GetRuntimeId()
    self:ResetMode()
    if param._isDialogGroup then
        self:InitForDialog()
    elseif param._isChoiceGroup then
        self:InitForChoice()
    elseif param._isCaptionGroup then
        self:InitForCaption()
    end
end

function StoryDialogUIMediator:OnShow(param)
    self.__canDelayCleanUp = false
    g_Game:AddFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    if self.timer then
        TimerUtility.StopAndRecycle(self.timer)
        self.timer = nil
    end
    self._checkRestoreSeSceneClickMove = self:CheckAndDisallowClickMoveInSeScene()
    if self._param and param and self._param ~= param then
       self:OnOpened(param)
    end
end

function StoryDialogUIMediator:OnHide(param)
    if self._checkRestoreSeSceneClickMove then
        self._checkRestoreSeSceneClickMove()
    end
    self._checkRestoreSeSceneClickMove = nil
    g_Game:RemoveFrameTicker(Delegate.GetOrCreate(self, self.OnTick))
    if self._runningVoiceHandle then
        g_Game.SoundManager:Stop(self._runningVoiceHandle)
        self._runningVoiceHandle = nil
    end
end

---@return fun()
function StoryDialogUIMediator:CheckAndDisallowClickMoveInSeScene()
    if g_Game.SceneManager.current then
        if g_Game.SceneManager.current:GetName() == SeScene.Name then
            local instance = SEEnvironment.Instance()
            if instance then
                return instance:SetAllowClickMoveWithStack(false)
            end
        end
    end
    return nil
end

--- button bind

function StoryDialogUIMediator:OnClickMask()
    if self._param._isDialogGroup then
        self:OnClickDialogNext()
    elseif self._param._isCaptionGroup then
        local g = self._captionGroup
        if g then
            if not g._typingEnd then
                g._typerStyle:CompleteTyping()
            else
                g._waitTimeRuntime = 0
            end
        else
            self:OnCaptionEnd()
        end
    elseif self._param._isChoiceGroup then
        self:CloseSelf()
    end
end

function StoryDialogUIMediator:OnClickDialogNext()
    if not self._dialogPlayer then
        return
    end
    self._dialogPlayer:OnClickDialogNext()
end

function StoryDialogUIMediator:OnClickAutoBtn()
    if not self._dialogPlayer then
        return
    end
    local s = self._dialogPlayer:ToggleAutoStatus()
    self:RefreshToggleAutoShowStatus(s)
end

function StoryDialogUIMediator:OnClickTendencyBtn()
    g_Game.UIManager:Open(UIMediatorNames.WorldTrendMediator, {focusCurStage = true})
end

function StoryDialogUIMediator:RefreshToggleAutoShowStatus(status)
    self._s_auto_status:SetState(status)
    self._p_btn_speed:SetVisible(status == 1)
    if status == 1 then
        local s = self._dialogPlayer:GetPlaySpeedMode()
        self._p_icon_1x:SetVisible(s == 1)
        self._p_icon_2x:SetVisible(s == 2)
    else
        self._p_icon_1x:SetVisible(false)
        self._p_icon_2x:SetVisible(false)
    end
end

function StoryDialogUIMediator:OnClickSpeedBtn()
    if not self._dialogPlayer then
        return
    end
    local s = self._dialogPlayer:TogglePlaySpeedMode()
    self._p_icon_1x:SetVisible(s == 1)
    self._p_icon_2x:SetVisible(s == 2)
end

function StoryDialogUIMediator:OnClickRecordBtn()
    if not self._dialogPlayer then
        return
    end
    if self._dialogPlayer:GetAutoStatus() == 1 then
        local s = self._dialogPlayer:SwitchAutoStatus(0)
        self:RefreshToggleAutoShowStatus(s)
    end
    local dialogGroupId = self._param._dialogGroupConfig:Id()
    local record = ModuleRefer.StoryModule:BuildStoryRecord(dialogGroupId, self._dialogPlayer:GetCurrentIndex())
    ---@type StoryDialogRecordUIMediatorParameter
    local param = {}
    param.record = record
    g_Game.UIManager:Open(UIMediatorNames.StoryDialogRecordUIMediator, param)
end

function StoryDialogUIMediator:OnClickSkipBtn()
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

function StoryDialogUIMediator:OnDialogGroupEnd()
    if self._param._dialogEndCallback then
        self._param._dialogEndCallback(self:GetRuntimeId())
    end
end

function StoryDialogUIMediator:OnChoice(index, lockable)
    if self._param._choiceChoose then
        if self._param._choiceChoose(index, lockable) then
            if self._param._delayTime > 0 then
                self.timer = TimerUtility.DelayExecute(function()
                    self:CloseSelf()
                end, self._param._delayTime)
            else
                self:CloseSelf()
            end
        end
    else
        self:CloseSelf()
    end
end

function StoryDialogUIMediator:OnCaptionEnd()
    if self._param._captionEnd then
        self._param._captionEnd()
    end
end

function StoryDialogUIMediator:ResetMode()
    for _, createdCaption in ipairs(self._createdCaptions) do
        UIHelper.DeleteUIGameObject(createdCaption)
    end
    for _, component in pairs(self._loadedComponents) do
        component:SetVisible(false)
    end
    self._img_background.gameObject:SetActive(false)
end

function StoryDialogUIMediator:InitForDialog()
    self._img_mask:SetVisible(true)
    self._img_mask_text:SetVisible(false)

    local cfg = self._param._dialogGroupConfig
    if cfg:TransparentBackground() then
        local c = self._img_mask.color
        c.a = 0
        self._img_mask.color = c
    end

    ---@type StoryDialogBtnTopComponent
    local topComp = self._loadedComponents[self._compLoadWrap.child_stroy_dialog_btn_top.name].Lua
    topComp.host = self
    ---@type StoryDialogNPCTalkComponent
    local talkComp = self._loadedComponents[self._compLoadWrap.child_story_dialog_npc_left_1.name].Lua
    talkComp.host = self

    topComp:SetVisible(true)
    talkComp:SetVisible(true)
    topComp:InitForDialog(self._param)
    talkComp:InitForDialog(self._param)
end

function StoryDialogUIMediator:InitForChoice()
    self._img_mask:SetVisible(true)
    self._img_mask_text:SetVisible(false)

    ---@type StoryDialogUIMediatorParameterChoiceProvider
    local cfg = self._param._choiceConfig
    local type = cfg:Type()
    if type == 2 or type == 3 then
        ---@type StoryDialogNPCTalkComponent
        local talkComp = self._loadedComponents[self._compLoadWrap.child_story_dialog_npc_left_1.name].Lua
        talkComp.host = self
        talkComp:SetVisible(true)
        talkComp:InitForChoice()
    else
        ---@type StoryDialogOptionsFullscreenComponent
        local talkComp = self._loadedComponents[self._compLoadWrap.child_story_options_fullscreen.name].Lua
        talkComp.host = self
        talkComp:SetVisible(true)
        talkComp:InitForChoice()
    end
end

function StoryDialogUIMediator:InitForCaption()
    self._img_mask:SetVisible(false)
    self._img_mask_text:SetVisible(true)
    ---@type StoryDialogCaptionComponent
    local captionComp = self._loadedComponents[self._compLoadWrap.child_story_caption.name].Lua
    captionComp.host = self
    captionComp:SetVisible(true)
    captionComp:InitForCaption()
end

function StoryDialogUIMediator:SetBackGround(show, img)
    self._img_background:SetVisible(show)
    if show then
        g_Game.SpriteManager:LoadSprite(img, self._img_background)
    end
end

function StoryDialogUIMediator:PlayVoice(voice)
    if string.IsNullOrEmpty(voice) then
        return true, nil
    end
    return false, g_Game.SoundManager:Play(voice)
end

function StoryDialogUIMediator:OnTick(delta)
    if self._param._isDialogGroup and self._dialogPlayer then
        self._dialogPlayer:Tick(delta)
    elseif self._param._isCaptionGroup and self._captionGroup then
        local g = self._captionGroup
        if not g._typingEnd then
            return
        end
        if g._waitTimeRuntime > 0 then
            g._waitTimeRuntime = g._waitTimeRuntime - delta
            return
        end
        if self._loadedComponents[self._compLoadWrap.child_story_caption.name] then
            ---@type StoryDialogCaptionComponent
            local captionComp = self._loadedComponents[self._compLoadWrap.child_story_caption.name].Lua
            if captionComp then
                captionComp:StartNextCaption()
            end
        end
    end
end

return StoryDialogUIMediator