local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local Utils = require("Utils")
local TRANSLATION_DELAY = 0.5

local I18N = require("I18N")

---@class ChatV2PlayerMessage:BaseUIComponent
local ChatV2PlayerMessage = class('ChatV2PlayerMessage', BaseUIComponent)

function ChatV2PlayerMessage:OnCreate()
    self._item = self:BindComponent("", typeof(CS.SuperScrollView.LoopListViewItem2))

    self._p_head_left = self:GameObject("p_head_left")
    self._p_text_name_l = self:Text("p_text_name_l")
    ---@type PlayerInfoComponent
    self._child_ui_head_player_l = self:LuaObject("child_ui_head_player_l")
    self._child_ui_head_player_l:SetClickHeadCallback(Delegate.GetOrCreate(self, self.OnPortraitClick))
    self._p_head_icon = self:Image("p_head_icon")
    
    self._p_head_right = self:GameObject("p_head_right")
    ---@type PlayerInfoComponent
    self._child_ui_head_player_r = self:LuaObject("child_ui_head_player_r")
    self._p_text_name_r = self:Text("p_text_name_r")

    self._p_bubble_l = self:RectTransform("p_bubble_l")
    self._p_btn_bubble_l = self:RectTransform("p_btn_bubble_l")
    self._btns_translate = self:GameObject("btns_translate")
    self._p_btn_group_translate = self:Button("p_btn_group_translate", Delegate.GetOrCreate(self, self.OnClickTranslate))
    self._p_group_translating = self:GameObject("p_group_translating")
    self._p_btn_group_revert = self:Button("p_btn_group_revert", Delegate.GetOrCreate(self, self.OnClickRevert))
    ---@type UIEmojiText
    self._ui_emoji_text_l = self:LuaObject("ui_emoji_text_l")
    self._filter_l = self:BindComponent("ui_emoji_text_l", typeof(CS.UnityEngine.UI.ContentSizeFitterEx))
    
    self._p_bubble_r = self:RectTransform("p_bubble_r")
    self._p_btn_bubble_r = self:RectTransform("p_btn_bubble_r")
    ---@type UIEmojiText
    self._ui_emoji_text_r = self:LuaObject("ui_emoji_text_r")
    self._filter_r = self:BindComponent("ui_emoji_text_r", typeof(CS.UnityEngine.UI.ContentSizeFitterEx))
end

---@class ChatV2PlayerMessageData
---@field sessionId number
---@field imId number
---@field time number
---@field text string
---@field uid number
---@field extInfo table @json
---@field translation {isTranslated:boolean, translating:boolean, showTranslated:boolean, startTranslateTime:number}

---@param message ChatV2PlayerMessageData
function ChatV2PlayerMessage:OnFeedData(message)
    self._message = message
    self._isLeft = message.uid ~= ModuleRefer.PlayerModule:GetPlayerId()
    self._p_head_left:SetActive(self._isLeft)
    self._p_head_right:SetActive(not self._isLeft)
    self._p_bubble_l.gameObject:SetActive(self._isLeft)
    self._p_bubble_r.gameObject:SetActive(not self._isLeft)

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
        self:UpdateOtherMessage()
    else
        self._child_ui_head_player_r:FeedData(portraitInfo)
        self:UpdateMyMessage()
    end

    self._btns_translate:SetActive(self._isLeft)
    if self._isLeft then
        self:UpdateTranslationButton()
    end

    self.loaded = true
end

function ChatV2PlayerMessage:OnShow()
    g_Game:AddIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnUpdate))
end

function ChatV2PlayerMessage:OnHide()
    g_Game:RemoveIgnoreInvervalTicker(Delegate.GetOrCreate(self, self.OnUpdate))
end

function ChatV2PlayerMessage:OnUpdate(dt)
    if not self.loaded then return end
    if self._isLeft then
        local sizeDelta = self._ui_emoji_text_l.CSComponent.transform.sizeDelta
        if self.width == sizeDelta.x and self.height == sizeDelta.y then
            return
        end
        self:ApplyLeftSize(sizeDelta.x, sizeDelta.y)
        self._item.ParentListView:OnItemSizeChanged(self._item.ItemIndex)
    else
        local sizeDelta = self._ui_emoji_text_r.CSComponent.transform.sizeDelta
        if self.width == sizeDelta.x and self.height == sizeDelta.y then
            return
        end
        self:ApplyRightSize(sizeDelta.x, sizeDelta.y)
        self._item.ParentListView:OnItemSizeChanged(self._item.ItemIndex)
    end
end

function ChatV2PlayerMessage:ApplyLeftSize(width, height)
    self.width, self.height = width, height
    local width, height = self.width + 70, self.height + 20
    self._p_btn_bubble_l:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, height)
    self._p_btn_bubble_l:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, width)

    local rootHeight = height + 38
    self._p_bubble_l.sizeDelta = CS.UnityEngine.Vector2(width, rootHeight)
    if rootHeight < 135 then
        rootHeight = 135
    end
    self._item.CachedRectTransform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, rootHeight)
end

function ChatV2PlayerMessage:ApplyRightSize(width, height)
    self.width, self.height = width, height
    local width, height = self.width + 70, self.height + 20
    self._p_btn_bubble_r:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, height)
    self._p_btn_bubble_r:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Horizontal, width)

    local rootHeight = height + 38
    self._p_bubble_r.sizeDelta = CS.UnityEngine.Vector2(width, rootHeight)
    if rootHeight < 135 then
        rootHeight = 135
    end
    self._item.CachedRectTransform:SetSizeWithCurrentAnchors(CS.UnityEngine.RectTransform.Axis.Vertical, rootHeight)
end

function ChatV2PlayerMessage:OnClickTranslate()
    if self._message.translation == nil then
        return
    end

    if self._message.translation.isTranslated then
        self._message.translation.showTranslated = true
        self:UpdateTranslationButton()
        self:UpdateOtherMessage()
    else
        self._message.translation.translating = true
        local message = ModuleRefer.ChatModule:GetMessage(self._message.imId)
        self._message.translation.startTranslateTime = CS.UnityEngine.Time.realtimeSinceStartup
        self:UpdateTranslationButton()
        ModuleRefer.ChatSDKModule:Translate(message, Delegate.GetOrCreate(self, self.OnTranslationCallback))
    end
end

---@param imId number
---@param code number
---@param msg string
---@param info CS.FunPlusChat.Models.FPTranslatedInfo
function ChatV2PlayerMessage:OnTranslationCallback(imId, code, msg, info)
    if self._message == nil or imId ~= self._message.imId then
        return
    end

    local finishTime = CS.UnityEngine.Time.realtimeSinceStartup
    if finishTime - self._message.translation.startTranslateTime < TRANSLATION_DELAY then
        self:DelayExecute(function()
            self:OnTranslationCallback(imId, code, msg, info)
        end, TRANSLATION_DELAY - (finishTime - self._message.translation.startTranslateTime))
        return
    end

    self._message.translation.translating = false
    if code ~= 0 then
        g_Logger.ErrorChannel("Chat", "Translate failed, code: %s, msg: %s", code, msg)
    else
        self._message.translation.isTranslated = true
        self._message.translation.showTranslated = true
    end

    self:UpdateTranslationButton()
    self:UpdateOtherMessage()
end

function ChatV2PlayerMessage:OnClickRevert()
    if not self._isLeft then return end
    if self._message.translation == nil then return end

    self._message.translation.showTranslated = false
    self:UpdateTranslationButton()
    self._ui_emoji_text_l:FeedData({text = self._message.text})
    self._filter_l:SetLayoutVertical()

    local sizeDelta = self._ui_emoji_text_l.CSComponent.transform.sizeDelta
    self:ApplyLeftSize(sizeDelta.x, sizeDelta.y)
end

function ChatV2PlayerMessage:UpdateOtherMessage()
    if self._message.translation.showTranslated then
        local message = ModuleRefer.ChatModule:GetMessage(self._message.imId)
        if message then
            self._ui_emoji_text_l:FeedData({text = message.TranslatedInfo.targetText})
        else
            self._ui_emoji_text_l:FeedData({text = self._message.text})
        end
    else
        self._ui_emoji_text_l:FeedData({text = self._message.text})
    end
    self._filter_l:SetLayoutVertical()
    local sizeDelta = self._ui_emoji_text_l.CSComponent.transform.sizeDelta
    self:ApplyLeftSize(sizeDelta.x, sizeDelta.y)
end

function ChatV2PlayerMessage:UpdateMyMessage()
    self._ui_emoji_text_r:FeedData({text = self._message.text})
    self._filter_r:SetLayoutVertical()
    local sizeDelta = self._ui_emoji_text_r.CSComponent.transform.sizeDelta
    self:ApplyRightSize(sizeDelta.x, sizeDelta.y)
end

function ChatV2PlayerMessage:UpdateTranslationButton()
    if self._message.translation.showTranslated then
        self._p_btn_group_translate:SetVisible(false)
        self._p_group_translating:SetActive(false)
        self._p_btn_group_revert:SetVisible(true)
    elseif self._message.translation.translating then
        self._p_btn_group_translate:SetVisible(false)
        self._p_group_translating:SetActive(true)
        self._p_btn_group_revert:SetVisible(false)
    else
        self._p_btn_group_translate:SetVisible(true)
        self._p_group_translating:SetActive(false)
        self._p_btn_group_revert:SetVisible(false)
    end
end

function ChatV2PlayerMessage:OnPortraitClick()
    ModuleRefer.PlayerModule:ShowPlayerInfoPanel(self._message.uid, self._child_ui_head_player_l.CSComponent.gameObject)
end

return ChatV2PlayerMessage