local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local ChatShareType = require("ChatShareType")

---@class ShareConfirmParam
---@field sessionID number
---@field type number           类型
---@field configID number       配置ID
---@field x number
---@field y number
---@field payload any

---@class ShareConfirmMediator : BaseUIMediator
local ShareConfirmMediator = class('ShareConfirmMediator', BaseUIMediator)


function ShareConfirmMediator:OnCreate()
    self.compChildPopupBaseS = self:LuaObject('child_popup_base_s')

    self.imgChannelIcon = self:Image('p_icon_logo')
    self.textChannelName = self:Text('p_text_name')

    self.texthint = self:Text('p_text_hint', I18N.Get("send_message_to_channel"))

    self.compGroupCoord = self:LuaObject('group_coord')
    self.compSharePetCard = self:LuaObject('p_share_pet_card')

    self.btnCancle = self:Button('p_comp_btn_cancle', Delegate.GetOrCreate(self, self.OnBtnCancelClick))
    self.textBtnClose = self:Text('p_text_cancle', I18N.Get("chat_share_return"))
    self.btnSend = self:Button('p_comp_btn_send', Delegate.GetOrCreate(self, self.OnBtnSendClick))
    self.textBtnSend = self:Text('p_text_send', I18N.Get("chat_share_confirm"))
end

---@param param ShareConfirmParam
function ShareConfirmMediator:OnOpened(param)
    if not param then
        return
    end

    local baseData = {}
    baseData.title = I18N.Get("share_coordinates_title")
    self.compChildPopupBaseS:FeedData(baseData)

    self.sessionID = param.sessionID
    self.session = ModuleRefer.ChatModule:GetSession(self.sessionID)
    self.name = ModuleRefer.ChatModule:GetSessionName(self.session)
    self.textChannelName.text = self.name
    self.type = param.type
    self.configID = param.configID
    self.skillLevels = param.skillLevels
    self.petGeneInfo = param.petGeneInfo
    self.blockPrivateChannel = param.blockPrivateChannel
    self.blockWorldChannel = param.blockWorldChannel
    self.blockAllianceChannel = param.blockAllianceChannel
    self.payload = param.payload

    if ModuleRefer.ChatModule:IsWorldSession(self.session) then
		g_Game.SpriteManager:LoadSprite(ModuleRefer.ChatModule:GetWorldSpriteName(), self.imgChannelIcon)
    elseif ModuleRefer.ChatModule:IsAllianceSession(self.session) then
        g_Game.SpriteManager:LoadSprite(ModuleRefer.ChatModule:GetAllianceSpriteName(), self.imgChannelIcon)
    elseif ModuleRefer.ChatModule:IsGroupSession(self.session) then
        g_Game.SpriteManager:LoadSprite(ModuleRefer.ChatModule:GetGroupSpriteName(), self.imgChannelIcon)
    end

    ---@type ShareChatItemParam
    local chatParam = {}
    chatParam.type = param.type
    chatParam.configID = param.configID
    if chatParam.type == ChatShareType.WorldEvent then
        local configInfo = ConfigRefer.WorldExpeditionTemplate:Find(param.configID)
        if configInfo then
            chatParam.x = param.x
            chatParam.y = param.y
            chatParam.level = configInfo:Level()
            chatParam.name = I18N.Get(configInfo:Name())
        end
    elseif chatParam.type == ChatShareType.ResourceField then
        local configInfo = ConfigRefer.FixedMapBuilding:Find(param.configID)
        if configInfo then
            chatParam.x = param.x
            chatParam.y = param.y
            chatParam.level = configInfo:Level()
            chatParam.name = I18N.Get(configInfo:Name())
            local outputNum = configInfo:OutputResourceCount()
            local outputInterval = configInfo:OutputResourceInterval() or 300
            local resourceYield = 3600 / outputInterval * outputNum
            chatParam.resourceYield = resourceYield or 0
        end
    elseif chatParam.type == ChatShareType.SlgMonster then
        local configInfo = ConfigRefer.KmonsterData:Find(param.configID)
        if configInfo then
            chatParam.x = param.x
            chatParam.y = param.y
            chatParam.level = configInfo:Level()
            chatParam.name = I18N.Get(configInfo:Name())
            chatParam.combatValue = configInfo:RecommendPower() or 0
        end
    elseif chatParam.type == ChatShareType.SlgBuilding then
		local configInfo = ConfigRefer.FixedMapBuilding:Find(param.configID)
		if configInfo then
			chatParam.x = param.x
            chatParam.y = param.y
			chatParam.level = configInfo:Level()
			chatParam.name = I18N.Get(configInfo:Name())
            if param.payload and param.payload.content then
                chatParam.shareDesc = param.payload.content
            end
        end
    elseif chatParam.type == ChatShareType.Pet then
        chatParam.x = param.x
        chatParam.y = param.y
        chatParam.z = param.z
    elseif chatParam.type == ChatShareType.AllianceMark then
        chatParam.x = param.x
        chatParam.y = param.y
        chatParam.name = param.payload.content
        chatParam.shareDesc = param.payload.name
        chatParam.customPic = ConfigRefer.AllianceMapLabel:Find(param.configID):Icon()
    elseif chatParam.type == ChatShareType.AllianceTask then
        local cfg = ConfigRefer.AllianceTask:Find(param.configID)
        local provider = require('AllianceTaskItemDataProvider').new(param.configID)
        chatParam.name = provider:GetTaskStr()
    else
        chatParam.x = param.x
        chatParam.y = param.y
        chatParam.name = I18N.Get("share_position_content")
    end
    self.chatParam = chatParam
    if chatParam.type == ChatShareType.Pet then
        chatParam.skillLevels = param.skillLevels
        chatParam.petGeneInfo = param.petGeneInfo
        self.compGroupCoord:SetVisible(false)
        self.compSharePetCard:SetVisible(true)
        self.compSharePetCard:RefreshPet(chatParam)
    else
        self.compGroupCoord:SetVisible(true)
        self.compSharePetCard:SetVisible(false)
        self.compGroupCoord:RefreshGroupItemInfo(chatParam)
    end
end

function ShareConfirmMediator:OnBtnCancelClick()
    self:CloseSelf()
    ---@type ShareChannelChooseParam
    local param = {
        type = self.type,
        configID = self.configID,
        x = self.chatParam.x,
        y = self.chatParam.y,
        z = self.chatParam.z,
        payload = self.payload,
        blockPrivateChannel = self.blockPrivateChannel,
        blockWorldChannel = self.blockWorldChannel,
        blockAllianceChannel = self.blockAllianceChannel,
    }
    g_Game.UIManager:Open(UIMediatorNames.ShareChannelChooseMediator, param)
end

function ShareConfirmMediator:OnBtnSendClick()
    self:CloseSelf()
    self.chatParam.shareTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    ModuleRefer.ChatModule:SendShareMsg(self.sessionID, self.chatParam)
end

function ShareConfirmMediator:OnClose(param)
    --TODO
end

return ShareConfirmMediator