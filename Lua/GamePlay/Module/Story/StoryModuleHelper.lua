local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local StoryDialogPlaceType = require("StoryDialogPlaceType")

---@class StoryModuleHelper
---@field new fun():StoryModuleHelper
local StoryModuleHelper = sealedClass('StoryModuleHelper')

---@return boolean
function StoryModuleHelper.BuildRecordFromDialogGroup(toAdd, storyGroupId, toStepIndex)
    if not storyGroupId then
        return false
    end
    local config = ConfigRefer.StoryDialogGroup:Find(storyGroupId)
    if config then
        if UNITY_DEBUG then
            if not toStepIndex or type(toStepIndex) ~= 'number' then
                error("toStepIndex not a number")
            end
        end
        toStepIndex = toStepIndex or 0
        local dialogId= config:StoryDialogId()
        local dialogConfig = ConfigRefer.StoryDialog:Find(dialogId)
        while dialogConfig and toStepIndex > 0 do
            ---@type StoryDialogRecordChatItemCellData
            local addCell = {}
            addCell.type = 1
            local characterNameI18n
            if dialogConfig:Type() == StoryDialogPlaceType.Right or dialogConfig:Type() == StoryDialogPlaceType.BothRight then
                characterNameI18n = dialogConfig:CharacterNameRight()
            end
            if string.IsNullOrEmpty(characterNameI18n) then
                characterNameI18n = dialogConfig:CharacterName()
            end
            addCell.textContent = I18N.Get(dialogConfig:DialogKey())
            addCell.name = I18N.Get(characterNameI18n)
            addCell.audioId = dialogConfig:DubbingRes()
            table.insert(toAdd, addCell)
            dialogConfig = ConfigRefer.StoryDialog:Find(dialogConfig:Subsequent())
            toStepIndex = toStepIndex - 1
        end
        return true
    end
end

---@return boolean
function StoryModuleHelper.BuildRecordFromChoice(toAdd, choiceConfigId, choiceIndex)
    if not choiceConfigId then
        return
    end
    local config = ConfigRefer.StoryChoice:Find(choiceConfigId)
    if config then
        ---@type StoryDialogRecordOptionCellData
        local addCell = {}
        addCell.type = 2
        addCell.textContent = ''
        if config:ChoiceLength() >= choiceIndex then
            addCell.textContent = I18N.Get(config:Choice(choiceIndex))
        end
        table.insert(toAdd, addCell)
        return true
    end
end

---@return boolean
function StoryModuleHelper.BuildRecordFromCaptionConfig(toAdd, captionConfigId)
    if not captionConfigId then
        return false
    end
    local config = ConfigRefer.ChapterCaption:Find(captionConfigId)
    if config then
        ---@type StoryDialogRecordSubTitleCellData
        local addCell = {}
        addCell.type = 3
        addCell.textContent = ''
        if config:ContentLength() > 0 then
            addCell.textContent = I18N.Get(config:Content(1))
        end
        for i = 2, config:ContentLength() do
            addCell.textContent = addCell.textContent .. '\n' ..I18N.Get(config:Content(i))
        end
        table.insert(toAdd, addCell)
    end
    return true
end

return StoryModuleHelper