local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class ChatV2LeagueRecruitMessage:BaseUIComponent
local ChatV2LeagueRecruitMessage = class('ChatV2LeagueRecruitMessage', BaseUIComponent)

function ChatV2LeagueRecruitMessage:OnCreate()
    ---@type CS.SuperScrollView.LoopListViewItem2
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

    ---@type ChatAllianceRecruitItem
    self._p_league_recruit = self:LuaObject("p_league_recruit")
    self._rect = self:RectTransform("p_league_recruit")
end

---@class ChatV2LeagueRecruitMessageData
---@field sessionId number
---@field imId number
---@field time number
---@field text string
---@field uid number
---@field extInfo table @json
---@field recruitParam ChatAllianceRecruitItemParam

---@param message ChatV2LeagueRecruitMessageData
function ChatV2LeagueRecruitMessage:OnFeedData(message)
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

    self._p_league_recruit:FeedData(message.recruitParam)
    self.loaded = true
    local sizeDelta = self._rect.sizeDelta
    self.height = sizeDelta.y
end

function ChatV2LeagueRecruitMessage:OnShow()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnUpdate))
end

function ChatV2LeagueRecruitMessage:OnHide()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnUpdate))
end

function ChatV2LeagueRecruitMessage:OnUpdate(dt)
    if not self.loaded then return end
    local sizeDelta = self._rect.sizeDelta     
    if self.height ~= sizeDelta.y then
        self.height = sizeDelta.y
        self._item.CachedRectTransform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, self.height)
        self._item.ParentListView:OnItemSizeChanged(self._item.ItemIndex)
    end
end

return ChatV2LeagueRecruitMessage