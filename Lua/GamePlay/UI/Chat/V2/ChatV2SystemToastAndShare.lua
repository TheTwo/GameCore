local BaseUIComponent = require ('BaseUIComponent')

---@class ChatV2SystemToastAndShare:BaseUIComponent
local ChatV2SystemToastAndShare = class('ChatV2SystemToastAndShare', BaseUIComponent)

function ChatV2SystemToastAndShare:OnCreate()
    self._item = self:BindComponent("", typeof(CS.SuperScrollView.LoopListViewItem2))

    self._p_head_right = self:GameObject("p_head_right")
    ---@type PlayerInfoComponent
    self._child_ui_head_player_r = self:LuaObject("child_ui_head_player_r")
    self._p_text_name_r = self:Text("p_text_name_r")
    
    self._p_head_left = self:GameObject("p_head_left")
    self._p_text_name_l = self:Text("p_text_name_l")
    ---@type PlayerInfoComponent
    self._child_ui_head_player_l = self:LuaObject("child_ui_head_player_l")
    self._p_head_icon = self:GameObject("p_head_icon")

    self._p_share = self:GameObject("p_share")
    self._p_text_share = self:Text("p_text_share")

    self._base_head = self:GameObject("base_head")
    self._p_img_head_monster = self:Image("p_img_head_monster")

    self._right = self:GameObject("right")
    self._p_text_world_event = self:Text("p_text_world_event")

    self._p_group_reward = self:GameObject("p_group_reward")
    self._p_text_reward = self:Text("p_text_reward")
    self._p_reward_1 = self:GameObject("p_reward_1")
    self._p_reward_2 = self:GameObject("p_reward_2")
    self._p_reward_3 = self:GameObject("p_reward_3")

    self._btn = self:GameObject("btn")
    ---@type BistateButton
    self._p_btn_share = self:LuaObject("p_btn_share")
end

function ChatV2SystemToastAndShare:OnFeedData(data)
    
end

return ChatV2SystemToastAndShare