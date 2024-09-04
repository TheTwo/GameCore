local Delegate = require("Delegate")

local BaseTableViewProCell = require("BaseTableViewProCell")

---@class StoryDialogRecordChatItemCellData : StoryDialogRecordCellData
---@field name string
---@field audioId number

---@class StoryDialogRecordChatItemCell:BaseTableViewProCell
---@field new fun():StoryDialogRecordChatItemCell
---@field super BaseTableViewProCell
local StoryDialogRecordChatItemCell = class('StoryDialogRecordChatItemCell', BaseTableViewProCell)

function StoryDialogRecordChatItemCell:ctor()
    BaseTableViewProCell.ctor(self)
    self._playingAudioHandle = nil
end

function StoryDialogRecordChatItemCell:OnCreate(param)
    self._p_text_name = self:Text("p_text_name")
    self._p_text_chat_content = self:Text("p_text_chat_content")
    self._p_btn_icon = self:Button("p_btn_icon", Delegate.GetOrCreate(self, self.OnClickPlayBtn))
end

---@param data StoryDialogRecordChatItemCellData
function StoryDialogRecordChatItemCell:OnFeedData(data)
    self:StopAndClearLastAudio()
    self._data = data
    self._p_text_name.text = data.name
    self._p_text_chat_content.text = data.textContent
    self._p_btn_icon:SetVisible(self._data and self._data.audioId and self._data.audioId > 0)
end

function StoryDialogRecordChatItemCell:OnClickPlayBtn()
    self:StopAndClearLastAudio()
    if self._data and self._data.audioId > 0 then
        self._playingAudioHandle = g_Game.SoundManager:PlayAudio(self._data.audioId)
    end
end

function StoryDialogRecordChatItemCell:OnRecycle()
    self:StopAndClearLastAudio()
end

function StoryDialogRecordChatItemCell:StopAndClearLastAudio()
    if self._playingAudioHandle then
        g_Game.SoundManager:Stop(self._playingAudioHandle)
        self._playingAudioHandle = nil
    end
end

return StoryDialogRecordChatItemCell