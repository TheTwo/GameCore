local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local UIMediatorNames = require('UIMediatorNames')
local Delegate = require('Delegate')

local I18N = require("I18N")

---@class ChatV2SharePetMessage:BaseUIComponent
local ChatV2SharePetMessage = class('ChatV2SharePetMessage', BaseUIComponent)

function ChatV2SharePetMessage:OnCreate()
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

    self._p_share_pet_card = self:Button("p_share_pet_card", Delegate.GetOrCreate(self, self.OnClick))
    self._p_quality_base = self:Image("p_quality_base")
    self._p_quality_head = self:Image("p_quality_head")
    self._mask = self:GameObject("mask")
    self._p_icon_pet = self:Image("p_icon_pet")
    self._p_text_pet_name = self:Text("p_text_pet_name")
    ---@type PetStarLevelComponent
    self._group_star = self:LuaObject("group_star")
end

---@class ChatV2SharePetParam
---@field type number
---@field configID number
---@field x number
---@field y number
---@field z number
---@field gn table @这屌值给PetShareMediator界面用的，完全没有定义，不知道是什么
---@field pl {level:number, quality:number}[]|nil @给PetStarLevelComponent用的

---@class ChatV2SharePetMessageData
---@field sessionId number
---@field imId number
---@field time number
---@field text string
---@field uid number
---@field extInfo table @json
---@field shareParam ChatV2SharePetParam

---@param message ChatV2SharePetMessageData
function ChatV2SharePetMessage:OnFeedData(message)
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

    self.param = self._message.shareParam
    local petConfig = ModuleRefer.PetModule:GetPetCfg(self.param.configID)
    local quality = petConfig:Quality()
    g_Game.SpriteManager:LoadSprite("sp_chat_base_quality_0" .. quality, self._p_quality_base)
    g_Game.SpriteManager:LoadSprite("sp_hero_frame_circle_" .. (quality + 2), self._p_quality_head)
    self:LoadSprite(petConfig:Icon(), self._p_icon_pet)
    self._p_text_pet_name.text = I18N.Get(petConfig:Name())
    if self.param.pl then
        self._group_star:FeedData({skillLevels = self.param.pl})
        self._group_star:SetVisible(true)
    else
        self._group_star:SetVisible(false)
    end
end

function ChatV2SharePetMessage:OnClick()
    g_Game.UIManager:Open(UIMediatorNames.PetShareMediator, self.param)
end

return ChatV2SharePetMessage