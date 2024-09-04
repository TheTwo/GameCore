local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local EventConst = require('EventConst')
local Delegate = require('Delegate')
local BaseTableViewProCell = require('BaseTableViewProCell')

local QuestChatTextRightCell = class('QuestChatTextRightCell',BaseTableViewProCell)

function QuestChatTextRightCell:OnCreate(param)
    self.animation = self:BindComponent("p_cell_group", typeof(CS.UnityEngine.Animation))
    self.textContent = self:Text('p_text_content')
    g_Game.EventManager:AddListener(EventConst.QUEST_EVENT_CLEAR_PLAY, Delegate.GetOrCreate(self, self.Clear))
end

function QuestChatTextRightCell:OnClose()
    g_Game.EventManager:RemoveListener(EventConst.QUEST_EVENT_CLEAR_PLAY, Delegate.GetOrCreate(self, self.Clear))
end

function QuestChatTextRightCell:Clear()
end

function QuestChatTextRightCell:OnFeedData(data)
    local mediator = self:GetParentBaseUIMediator()
    if data.newAnim and not mediator:GetNewDialogueAnim(data.dialogueId) then
        mediator:RecordNewDialogueAnim(data.dialogueId)
        self.animation:Play('anim_vx_mission_event_duihua')
    end
    self.data = data
    local dialogueCfg = ConfigRefer.StoryDialog:Find(data.dialogueId)
    self.textContent.text = I18N.Get(dialogueCfg:DialogKey())
end

return QuestChatTextRightCell
