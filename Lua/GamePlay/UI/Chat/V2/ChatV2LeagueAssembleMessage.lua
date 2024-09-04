local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ObjectType = require("ObjectType")
local Delegate = require('Delegate')
local TimeFormatter = require("TimeFormatter")
local I18N = require("I18N")
local SlgUtils = require("SlgUtils")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local UIMediatorNames = require("UIMediatorNames")

---@class ChatV2LeagueAssembleMessage:BaseUIComponent
local ChatV2LeagueAssembleMessage = class('ChatV2LeagueAssembleMessage', BaseUIComponent)

function ChatV2LeagueAssembleMessage:OnCreate()
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

    self._p_league_group = self:GameObject("p_league_group")
    self._layout_text = self:GameObject("layout_text")
    self._p_text_group = self:Text("p_text_group")
    self._p_text_distance = self:Text("p_text_distance")
    self._p_text_time = self:Text("p_text_time")
    
    self._base_head = self:GameObject("base_head")
    self._p_img_head = self:Image("p_img_head")

    self._p_text_join_content = self:Text("p_text_join_content")
    
    self._btns = self:GameObject("btns")
    self._p_btn_joined = self:Button("p_btn_joined")
    self._p_text_joined = self:Text("p_text_joined")
    self._p_btn_joined:SetVisible(false)

    self._p_btn_join = self:Button("p_btn_join", Delegate.GetOrCreate(self, self.OnClickJoin))
    self._p_text_join = self:Text("p_text_join", "goto")

    self._p_btn_d = self:Button("p_btn_d")
    self._p_text_d = self:Text("p_text_d")
    self._p_btn_d:SetVisible(false)
end

---@class ChatV2LeagueAssembleMessageData
---@field sessionId number
---@field imId number
---@field time number
---@field text string
---@field uid number
---@field extInfo table @json

---@param message ChatV2LeagueAssembleMessageData
function ChatV2LeagueAssembleMessage:OnFeedData(message)
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

    self:SetupAssembleInfo(self._message.extInfo)
end

function ChatV2LeagueAssembleMessage:GetTargetDistance(posX, posY)
    local castle = ModuleRefer.PlayerModule:GetCastle()
    if not castle then return end
    local castlePos = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
    return AllianceWarTabHelper.CalculateMapDistance(posX, posY, castlePos.X, castlePos.Y)
end

function ChatV2LeagueAssembleMessage:SetupAssembleInfo(args)
    local t = args.t
    local configId = args.c
    local objectType = args.ot or ObjectType.SlgMob
    local srcName = args.n
    local distance = self:GetTargetDistance(args.px, args.py)

    self._p_text_distance:SetVisible(distance ~= nil)
    if distance then
        if distance > 1000 then
            self._p_text_distance.text = ("%dKM"):format(math.floor(distance / 1000 + 0.5))
        else
            self._p_text_distance.text = ("%dM"):format(math.floor(distance + 0.5))
        end
    end

    self._p_text_time.text = TimeFormatter.TimeToDateTimeStringUseFormat(t, "MM.dd HH:mm:ss")
    local pic
    local targetName
    if configId then
        targetName, pic = SlgUtils.GetNameIconPowerByConfigId(objectType, configId)
    else
        targetName = args.tn
        local pPortrait = args.tp
        pic = ModuleRefer.PlayerModule:GetPortraitSpriteName(pPortrait)
    end
    self._p_text_join_content.text = I18N.GetWithParams("alliance_team_toast01", srcName, targetName)
    g_Game.SpriteManager:LoadSprite(pic, self._p_img_head)
end

function ChatV2LeagueAssembleMessage:OnClickJoin()
    ---@type AllianceWarNewMediatorParameter
    local param = {
        enterTabIndex = 1
    }
    g_Game.UIManager:Open(UIMediatorNames.AllianceWarNewMediator, param)
end

return ChatV2LeagueAssembleMessage