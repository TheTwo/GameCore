local TyperStyle = require("TyperStyle")

---@class StoryDialogUIMediatorDialogQueue
---@field _voiceEnd boolean
---@field _voiceHandle CS.DragonReborn.SoundPlayingHandle
---@field _playingTyping boolean
---@field _effectListTime number
---@field _delayLeftTime number
---@field _currentIndex number
---@field _queue StoryDialogConfigCell[]
---@field _dialogMode StoryDialogUIMediatorHelper.ModeEnum
---@field _typerStyle TyperStyle

---@class StoryDialogUIMediatorHelper
local StoryDialogUIMediatorHelper = {}

---@class StoryDialogUIMediatorHelper.ModeEnum
StoryDialogUIMediatorHelper.ModeEnum = {
    Normal = 0,
    SmallDialog = 1,
}

---@param dialogList StoryDialogConfigCell[]
---@return StoryDialogUIMediatorDialogQueue
function StoryDialogUIMediatorHelper.MakeDialogQueue(dialogList)
    ---@type StoryDialogUIMediatorDialogQueue
    local ret = {}
    ret._voiceEnd = false
    ret._voiceHandle = nil
    ret._playingTyping = false
    ret._effectListTime = 0
    ret._delayLeftTime = 0
    ret._currentIndex = 0
    ret._queue = dialogList
    ret._typerStyle = TyperStyle.new()
    return ret
end

return StoryDialogUIMediatorHelper

