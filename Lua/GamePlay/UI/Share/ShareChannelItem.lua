local BaseUIMediator = require ('BaseUIMediator')
local BaseTableViewProCell = require ('BaseTableViewProCell')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local ObjectType = require('ObjectType')

---@class ShareChannelItemParam
---@field sessionID string
---@field pinned boolean
---@field sortValue number
---@field type number
---@field configID number
---@field x number
---@field y number
---@field skillLevels table --宠物用
---@field payload any
---@field blockPrivateChannel boolean
---@field blockWorldChannel boolean
---@field blockAllianceChannel boolean

---@class ShareChannelItem : BaseTableViewProCell
local ShareChannelItem = class('ShareChannelItem', BaseTableViewProCell)

function ShareChannelItem:OnCreate()
    self.imgIcon = self:Image("p_icon_logo")
    self.textName = self:Text("p_text_name")
    self.btnItem = self:Button("", Delegate.GetOrCreate(self, self.OnItemClick))
end

---@param param ShareChannelItemParam
function ShareChannelItem:OnFeedData(param)
    if not param then
        return
    end
    self.param = param
    self.sessionID = param.sessionID
    self.session = ModuleRefer.ChatModule:GetSession(self.sessionID)
    self.name = ModuleRefer.ChatModule:GetSessionName(self.session)
    self.textName.text = self.name
    self.type = param.type
    self.configID = param.configID
    self.x = param.x
    self.y = param.y
    self.z = param.z
    self.payload = param.payload
    self.blockPrivateChannel = param.blockPrivateChannel
    self.blockWorldChannel = param.blockWorldChannel
    self.blockAllianceChannel = param.blockAllianceChannel

    if ModuleRefer.ChatModule:IsWorldSession(self.session) then
		g_Game.SpriteManager:LoadSprite(ModuleRefer.ChatModule:GetWorldSpriteName(), self.imgIcon)
    elseif ModuleRefer.ChatModule:IsAllianceSession(self.session) then
        g_Game.SpriteManager:LoadSprite(ModuleRefer.ChatModule:GetAllianceSpriteName(), self.imgIcon)
    elseif ModuleRefer.ChatModule:IsGroupSession(self.session) then
        g_Game.SpriteManager:LoadSprite(ModuleRefer.ChatModule:GetGroupSpriteName(), self.imgIcon)
    end
end

function ShareChannelItem:OnItemClick()
    ---@type ShareConfirmParam
    local param = {}
    param.sessionID = self.sessionID
    param.type = self.type
    param.configID = self.configID
    param.x = self.x
    param.y = self.y
    param.z = self.z
    param.petGeneInfo = self.param.petGeneInfo
    param.skillLevels = self.param.skillLevels
    param.payload = self.payload
    param.blockPrivateChannel = self.blockPrivateChannel
    param.blockWorldChannel = self.blockWorldChannel
    param.blockAllianceChannel = self.blockAllianceChannel
    g_Game.UIManager:Open(UIMediatorNames.ShareConfirmMediator, param)
    g_Game.UIManager:CloseByName(UIMediatorNames.ShareChannelChooseMediator)
end

return ShareChannelItem