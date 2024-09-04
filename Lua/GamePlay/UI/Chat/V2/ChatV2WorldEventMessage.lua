local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local I18N_FROM_NAME_SYSTEM_TOAST = "chat_system_name"
local I18N = require("I18N")

---@class ChatV2WorldEventMessage:BaseUIComponent
local ChatV2WorldEventMessage = class('ChatV2WorldEventMessage', BaseUIComponent)
local UIMediatorNames = require("UIMediatorNames")

function ChatV2WorldEventMessage:OnCreate()
    self._item = self:BindComponent("", typeof(CS.SuperScrollView.LoopListViewItem2))

    self._p_head_icon = self:GameObject("p_head_icon")
    self._p_text_name = self:Text("p_text_name")

    self._p_text_world_event_title = self:Text("p_text_world_event_title")
    self._p_img_head_world_event = self:Image("p_img_head_world_event")

    self._right = self:GameObject("right")
    self._p_text_join_battle_l = self:Text("p_text_join_battle_l")

    self._btn_l = self:GameObject("btn_l")
    self._child_comp_btn_share_world_event = self:Button("child_comp_btn_share_world_event", Delegate.GetOrCreate(self, self.OnClickGoto))
end

---@class ChatV2WorldEventMessageData
---@field cfgId number

---@param message ChatV2WorldEventMessageData
function ChatV2WorldEventMessage:OnFeedData(message)
    self._message = message
    self._p_text_name.text = I18N.Get(I18N_FROM_NAME_SYSTEM_TOAST)

    self._p_text_world_event_title.text = "联盟世界事件"

    ---@type ToastConfigCell
    local toastCfg = ConfigRefer.Toast:Find(8)

    if (string.IsNullOrEmpty(toastCfg:Icon())) then
        self._p_img_head_world_event:SetVisible(false)
    else
        self._p_img_head_world_event:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(toastCfg:Icon(), self._p_img_head_world_event)
    end

    local cfg = ConfigRefer.WorldExpeditionTemplate:Find(self._message.cfgId)
    self.cfgId = ModuleRefer.WorldEventModule:GetAllianceActivityExpeditionByExpeditionID(cfg:Id()).ConfigId
    self._p_text_join_battle_l.text = I18N.Get(cfg:Name())
end

function ChatV2WorldEventMessage:OnClickGoto()
    local scene = g_Game.SceneManager.current
    if scene:IsInCity() then
        g_Game.UIManager:CloseAllByName(UIMediatorNames.ChatV2UIMediator)
        scene:LeaveCity(function()
            ModuleRefer.WorldEventModule:GotoAllianceExpedition(self.cfgId)
        end)
    else
        g_Game.UIManager:CloseAllByName(UIMediatorNames.ChatV2UIMediator)
        ModuleRefer.WorldEventModule:GotoAllianceExpedition(self.cfgId)
    end
end

return ChatV2WorldEventMessage