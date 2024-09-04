local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local TimerUtility = require("TimerUtility")
---@type CS.DragonReborn.AssetTool.GameObjectCreateHelper
local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper

--- scene:scene_child_story_options_fullscreen
local BaseUIComponent = require("BaseUIComponent")

---@class StoryDialogOptionsFullscreenComponent:BaseUIComponent
---@field new fun():StoryDialogOptionsFullscreenComponent
---@field super BaseUIComponent
---@field host StoryDialogUIMediator
local StoryDialogOptionsFullscreenComponent = class('StoryDialogOptionsFullscreenComponent', BaseUIComponent)

function StoryDialogOptionsFullscreenComponent:ctor()
    StoryDialogOptionsFullscreenComponent.super.ctor(self)
    ---@type StoryDialogUIMediatorParameter
    self._param = nil
    ---@type SetPortraitCallBack[]
    self._lastSetPortraits = {}
    self._goHelper = GameObjectCreateHelper.Create()
    ---@type StoryDialogUiOptionCellData[]
    self._sideChoiceOptionData = {}
    ---@type fun()
    self._checkRestoreSeSceneClickMove = nil
    ---@type CS.UnityEngine.GameObject[]
    self._createdCaptions = {}
    self._lastLRMode = nil
    self._grayLeft = false
    self._grayRight = false
    ---@type OptionPair[]
    self._btn_options = {}
end

function StoryDialogOptionsFullscreenComponent:OnCreate(param)
    -- options fullscreen node
    self._g_options_fullscreen = self:GameObject("")
    self._lb_options_subtitle = self:Text("p_text_subtitle")
    for i = 1, 4 do
        local btnKey = string.format("p_btn_op_f%d", i)
        local btnText = string.format("p_text_op_f%d", i)
        local index = i
        self._btn_options[i] = {
            Btn = self:Button(btnKey, function()
                local btnInfo = self._btn_options and self._btn_options[index] and self._btn_options[index].Btn
                self:OnChoice(index, btnInfo.transform)
        end)
        , Lb = self:Text(btnText)}
    end
end

function StoryDialogOptionsFullscreenComponent:InitForChoice()
    ---@type StoryDialogUIMediatorParameterChoiceProvider
    local cfg = self.host._param._choiceConfig
    local choiceCount = cfg:ChoiceLength()
    self._g_options_fullscreen:SetActive(true)
    self._lb_options_subtitle.text = cfg:DialogText()
    for i = 1, #self._btn_options do
        if choiceCount < i then
            self._btn_options[i].Btn.gameObject:SetActive(false)
        else
            self._btn_options[i].Btn.gameObject:SetActive(true)
            local option = cfg:Choice(i)
            self._btn_options[i].Lb.text = option.content
        end
    end
    local playEnd,handle = self.host:PlayVoice(cfg:Voice())
    if not playEnd then
        self.host._runningVoiceHandle = handle
    end
end

function StoryDialogOptionsFullscreenComponent:OnChoice(index, lockable)
    self.host:OnChoice(index, lockable)
end

return StoryDialogOptionsFullscreenComponent