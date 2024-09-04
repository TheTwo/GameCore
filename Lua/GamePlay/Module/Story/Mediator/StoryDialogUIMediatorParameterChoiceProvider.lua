local I18N = require("I18N")
local StoryDialogUiOptionCellType = require("StoryDialogUiOptionCellType")
local ArtResourceUtils = require("ArtResourceUtils")

---@class StoryDialogUIMediatorParameterChoiceProviderOption
---@field type StoryDialogUiOptionCellType.enum
---@field requireNum number
---@field nowNum number
---@field showNumberPair boolean
---@field content string
---@field showIsOnGoing boolean
---@field userData any
---@field onClickOption fun(option:StoryDialogUIMediatorParameterChoiceProviderOption, lockable:CS.UnityEngine.Transform):boolean
---@field isOptionShowCreep boolean
---@field uiRuntimeId number|nil @set by mediator

---@class StoryDialogUIMediatorParameterChoiceProvider
---@field new fun():StoryDialogUIMediatorParameterChoiceProvider
local StoryDialogUIMediatorParameterChoiceProvider = class('StoryDialogUIMediatorParameterChoiceProvider')

function StoryDialogUIMediatorParameterChoiceProvider:ctor()
    self._type = nil
    ---@type StoryDialogUIMediatorParameterChoiceProviderOption[]
    self._choice = nil
    self._characterImageSprite = false
    self._characterImage = nil
    self._characterSpine = nil
    self._characterName = nil
    self._dialogText = nil
    self._voice = nil
end

---@param storyChoiceConfig StoryChoiceConfigCell
function StoryDialogUIMediatorParameterChoiceProvider:InitWithStoryChoiceConfig(storyChoiceConfig)
    self._type = storyChoiceConfig:Type()
    self._characterName = I18N.Get(storyChoiceConfig:CharacterName())
    self._characterImage = ArtResourceUtils.GetUIItem(storyChoiceConfig:CharacterImage())
    self._characterSpine = storyChoiceConfig:CharacterImage()
    self._dialogText = I18N.Get(storyChoiceConfig:DialogText())
    self._voice = storyChoiceConfig:Voice() > 0 and ArtResourceUtils.GetAudio(storyChoiceConfig:Voice()) or string.Empty
    self._choice = {}
    local count = storyChoiceConfig:ChoiceLength()
    for i = 1, count do
        ---@type StoryDialogUIMediatorParameterChoiceProviderOption
        local option = {}
        option.type = StoryDialogUiOptionCellType.enum.None
        option.showNumberPair = false
        option.showIsOnGoing = false
        option.content = I18N.Get(storyChoiceConfig:Choice(i))
        table.insert(self._choice, option)
    end
end

---@param npcCfg CityElementNpcConfigCell
function StoryDialogUIMediatorParameterChoiceProvider:InitForNpc(npcCfg)
    self._type = 2
    self._characterName = I18N.Get(npcCfg:Name())
    local npcSpine = npcCfg:SpinePortrait() > 0 and ArtResourceUtils.GetUIItem(npcCfg:SpinePortrait()) or string.Empty
    if not string.IsNullOrEmpty(npcSpine) then
        self._characterImageSprite = false
        self._characterImage = npcSpine
        self._characterSpine = npcCfg:SpinePortrait()
    else
        self._characterImageSprite = true
        self._characterImage = npcCfg:Image()
    end
    self._dialogText = I18N.Get(npcCfg:DialogContent())
    self._voice = npcCfg:Voice() > 0 and ArtResourceUtils.GetAudio(npcCfg:Voice()) or string.Empty
    self._choice = {}
end

function StoryDialogUIMediatorParameterChoiceProvider:InitCharacterImage(characterName, imageName)
    self._type = 2
    self._characterName = I18N.Get(characterName)
    self._characterImageSprite = true
    self._characterImage = imageName
    self._choice = {}
end

---@param option StoryDialogUIMediatorParameterChoiceProviderOption
function StoryDialogUIMediatorParameterChoiceProvider:AppendOption(option)
    table.insert(self._choice, option)
end

---@return number @1-fullscreen|2-leftChoice|3-rightChoice
function StoryDialogUIMediatorParameterChoiceProvider:Type()
    return self._type
end

---@return StoryDialogUIMediatorParameterChoiceProviderOption
function StoryDialogUIMediatorParameterChoiceProvider:Choice(index)
    return self._choice[index]
end

function StoryDialogUIMediatorParameterChoiceProvider:ChoiceLength()
    return #self._choice
end

function StoryDialogUIMediatorParameterChoiceProvider:IsCharacterImageSprite()
    return self._characterImageSprite
end

function StoryDialogUIMediatorParameterChoiceProvider:CharacterImage()
   return self._characterImage 
end

function StoryDialogUIMediatorParameterChoiceProvider:CharacterSpine()
    return self._characterSpine
end

function StoryDialogUIMediatorParameterChoiceProvider:CharacterName()
    return self._characterName
end

function StoryDialogUIMediatorParameterChoiceProvider:DialogText()
    return self._dialogText
end

function StoryDialogUIMediatorParameterChoiceProvider:Voice()
    return self._voice
end

return StoryDialogUIMediatorParameterChoiceProvider