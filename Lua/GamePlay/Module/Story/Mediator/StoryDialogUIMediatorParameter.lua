local ConfigRefer = require("ConfigRefer")
local StoryDialogUIMediatorParameterChoiceProvider = require("StoryDialogUIMediatorParameterChoiceProvider")

---@class StoryDialogUIMediatorParameter
---@field new fun():StoryDialogUIMediatorParameter
local StoryDialogUIMediatorParameter = class('StoryDialogUIMediatorParameter')

function StoryDialogUIMediatorParameter:ctor()
    self._isDialogGroup = false
    self._isChoiceGroup = false
    self._isCaptionGroup = false
    
    self._choiceProvider = nil
    self._delayTime = 0
    self._storyDialogType = nil
    self._uiRuntimeId = nil
end

---@param dialogGroupConfigId number
---@param callBack fun(uiRuntimeId:number)
---@return number|nil @dialogType 1- normal, 2 - chat, 3 - chat but through
function StoryDialogUIMediatorParameter:SetDialogGroup(dialogGroupConfigId, callBack)
    self._isDialogGroup = true
    local dialogConfig = ConfigRefer.StoryDialogGroup:Find(dialogGroupConfigId)
    if not dialogConfig then
        g_Logger.Error("dialogGroupConfigId:%s not found", dialogGroupConfigId)
        return nil
    end
    self._dialogGroupConfig = dialogConfig
    ---@type StoryDialogConfigCell[]
    self._dialogList = {}
    self._dialogEndCallback = callBack
    local StoryDialogConfig = ConfigRefer.StoryDialog
    local dialogStart = StoryDialogConfig:Find(self._dialogGroupConfig:StoryDialogId())
    while dialogStart do
        table.insert(self._dialogList, dialogStart)
        local nextId = dialogStart:Subsequent()
        if nextId > 0 and nextId ~= dialogStart:Id() then
            dialogStart = StoryDialogConfig:Find(nextId)
        else
            break
        end
    end
    return self._dialogGroupConfig:DialogType()
end

---@param choiceConfigId number
---@param callback fun(index:number, lockable:CS.UnityEngine.Transform):boolean
function StoryDialogUIMediatorParameter:SetChoiceGroup(choiceConfigId, callback)
    self._isChoiceGroup = true
    self._choiceChoose = callback
    self._choiceConfig = StoryDialogUIMediatorParameterChoiceProvider.new()
    self._choiceConfig:InitWithStoryChoiceConfig(ConfigRefer.StoryChoice:Find(choiceConfigId))
end

---@param provider StoryDialogUIMediatorParameterChoiceProvider
function StoryDialogUIMediatorParameter:SetChoiceProvider(provider)
    self._isChoiceGroup = true
    self._choiceChoose = function(index, lockable)
        local option = provider._choice[index]
        if option and option.onClickOption then
            option.uiRuntimeId = self._uiRuntimeId
            return option.onClickOption(option, lockable)
        end
        return true
    end
    self._choiceConfig = provider
end

---@param captionConfigId number
---@param callback fun()
function StoryDialogUIMediatorParameter:SetCaption(captionConfigId, callback)
    self._isCaptionGroup = true
    self._captionConfig = ConfigRefer.ChapterCaption:Find(captionConfigId)
    self._captionEnd = callback
end

function StoryDialogUIMediatorParameter:SetDelayTime(time)
    self._delayTime = time
end

return StoryDialogUIMediatorParameter