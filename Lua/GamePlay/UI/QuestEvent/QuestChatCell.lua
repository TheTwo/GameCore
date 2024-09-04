local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local Delegate = require('Delegate')
local UIHelper = require('UIHelper')
local EventConst = require('EventConst')
local BaseTableViewProCell = require('BaseTableViewProCell')
local QuestChatCell = class('QuestChatCell',BaseTableViewProCell)

function QuestChatCell:OnCreate(param)
    self.btnItemLeft = self:Button('', Delegate.GetOrCreate(self, self.OnBtnItemLeftClicked))
    self.statusrecordparentItemLeft = self:BindComponent('', typeof(CS.StatusRecordParent))
    self.goGroupSelect = self:GameObject('p_group_select')
    self.compChildReddotDefault = self:LuaObject('child_reddot_default')
    self.imgImgHeroHead = self:Image('p_img_hero_head')
    self.textName = self:Text('p_text_name')
    self.textTask = self:Text('p_text_task')
    self.goWarningDisconnected = self:GameObject('p_warning_disconnected')
    self.textDisconnected = self:Text('p_text_disconnected', 'new_chapter_nosignal_short')
end

function QuestChatCell:OnFeedData(data)
    if not data then
        return
    end
    self.data = data
    self.statusrecordparentItemLeft:SetState(data.isMainChatNpc and 1 or 0)
    local showRedDot = data.newDialogueIds and #data.newDialogueIds > 0 or false
    self.compChildReddotDefault:SetVisible(showRedDot)
    if showRedDot then
        self.compChildReddotDefault:ShowNumRedDot(#data.newDialogueIds)
    end
    local chatNpcCfg = ConfigRefer.ChatNPC:Find(data.chatNpcId)
    self.textName.text = I18N.Get(chatNpcCfg:Name())
    g_Game.SpriteManager:LoadSprite(chatNpcCfg:Icon(), self.imgImgHeroHead)
    self.goWarningDisconnected:SetActive(data.outOfSignal)
    self.textTask.gameObject:SetActive(not data.outOfSignal)
    if not data.outOfSignal then
        local lastDialogueId = (data.allDialogues[#data.allDialogues] or {}) [1]
        if lastDialogueId then
            local dialogueCfg = ConfigRefer.StoryDialog:Find(lastDialogueId)
            UIHelper.Ellipsis(self.textTask, I18N.Get(dialogueCfg:DialogKey()))
        else
            self.textTask.text = ""
        end
    end
end


function QuestChatCell:OnBtnItemLeftClicked(args)
    if self.data then
        g_Game.EventManager:TriggerEvent(EventConst.QUEST_EVENT_CHAT_NPC_CLICKED, self.data)
    end
end

return QuestChatCell
