local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local UIMediatorNames = require("UIMediatorNames")
local I18N = require("I18N")

---@class ChatV2LeagueTaskMessage:BaseUIComponent
local ChatV2LeagueTaskMessage = class('ChatV2LeagueTaskMessage', BaseUIComponent)

function ChatV2LeagueTaskMessage:OnCreate()
    self._item = self:BindComponent("", typeof(CS.SuperScrollView.LoopListViewItem2))

    self._p_head_left = self:GameObject("p_head_left")
    self._p_text_name_l = self:Text("p_text_name_l")
    ---@type PlayerInfoComponent
    self._child_ui_head_player_l = self:LuaObject("child_ui_head_player_l")
    self._p_head_icon = self:Image("p_head_icon")
    
    self._p_head_right = self:GameObject("p_head_right")
    ---@type PlayerInfoComponent
    self._child_ui_head_player_r = self:LuaObject("child_ui_head_player_r")
    self._p_text_name_r = self:Text("p_text_name_r")

    self._p_task = self:GameObject("p_task")
    self._p_text_task_title = self:Text("p_text_task_title")
    self._p_text_task = self:Text("p_text_task")
    self._p_btn_goto = self:Button("p_btn_goto", Delegate.GetOrCreate(self, self.OnClick))
    self._p_progress = self:Slider("p_progress")
    self._p_text_progress = self:Text("p_text_progress")
end

---@class ChatV2LeagueTaskMessageData
---@field sessionId number
---@field imId number
---@field time number
---@field text string
---@field uid number
---@field extInfo table @json

---@param message ChatV2LeagueTaskMessageData
function ChatV2LeagueTaskMessage:OnFeedData(message)
    self._message = message
    self._isLeft = message.uid ~= ModuleRefer.PlayerModule:GetPlayerId()
    self._p_head_left:SetActive(self._isLeft)
    self._p_head_right:SetActive(not self._isLeft)

    local name = ModuleRefer.ChatModule:GetNicknameWithAllianceFromExtInfo(self._message.extInfo, self._message.uid)
    if self._isLeft then
        self._p_text_name_l.text = name
    else
        self._p_text_name_r.text = name
    end

    ---@type wds.PortraitInfo
    local portraitInfo = wds.PortraitInfo.New()
    portraitInfo.PlayerPortrait = self._message.extInfo.p
    portraitInfo.PortraitFrameId = self._message.extInfo.fp
    portraitInfo.CustomAvatar = self._message.extInfo.ca and self._message.extInfo.ca or ""
    if self._isLeft then
        self._child_ui_head_player_l:FeedData(portraitInfo)
    else
        self._child_ui_head_player_r:FeedData(portraitInfo)
    end

    self:UpdateAllianceTask()
end

function ChatV2LeagueTaskMessage:UpdateAllianceTask()
    local provider = require('AllianceTaskItemDataProvider').new(self._message.extInfo.c)
    self._p_text_task_title.text =  I18N.Get("alliance_target_3")
    self._p_text_task.text = provider:GetTaskStr(true)
    local numCurrent, numNeeded = ModuleRefer.WorldTrendModule:GetAllianceTaskSchedule(self._message.extInfo.c)
    self._p_progress.value = numCurrent/numNeeded
    self._p_text_progress.text = numCurrent .. "/" .. numNeeded
end

function ChatV2LeagueTaskMessage:OnClick()
    local provider = require('AllianceTaskItemDataProvider').new(self._message.extInfo.c)
	provider:OnGoto()
    g_Game.UIManager:CloseByName(UIMediatorNames.ChatV2UIMediator)
end

return ChatV2LeagueTaskMessage