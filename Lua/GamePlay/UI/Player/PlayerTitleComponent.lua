local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class PlayerTitleComponent : BaseUIComponent
local PlayerTitleComponent = class('PlayerTitleComponent', BaseUIComponent)

---@class PlayerTitleParam
---@field configID number
---@field name string

function PlayerTitleComponent:OnCreate()
    self.imgTitleIcon = self:Image('p_icon')
    self.imgTitleBase_l = self:Image('p_line_l')
    self.imgTitleBase = self:Image('p_base_name')
    self.imgTitleBase_r = self:Image('p_line_r')
    self.textName = self:Text('p_text_title_name')
end

---@param param PlayerTitleParam
function PlayerTitleComponent:OnFeedData(param)
    if not param then
        return
    end

    if param.name then
        self.textName:SetVisible(true)
        self.textName.text = param.name
    end
    local configInfo = ConfigRefer.AdornmentTitle:Find(param.configID)
    if not configInfo then
        return
    end
    if not string.IsNullOrEmpty(configInfo:TitleIcon()) then
        self.imgTitleIcon:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(configInfo:TitleIcon(), self.imgTitleIcon)
    else
        self.imgTitleIcon:SetVisible(false)
    end

    if not string.IsNullOrEmpty(configInfo:TitleBaseL()) then
        self.imgTitleBase_l:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(configInfo:TitleBaseL(), self.imgTitleBase_l)
    else
        self.imgTitleBase_l:SetVisible(false)
    end

    if not string.IsNullOrEmpty(configInfo:TitleBase()) then
        self.imgTitleBase:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(configInfo:TitleBase(), self.imgTitleBase)
    else
        self.imgTitleBase:SetVisible(false)
    end

    if not string.IsNullOrEmpty(configInfo:TitleBaseR()) then
        self.imgTitleBase_r:SetVisible(true)
        g_Game.SpriteManager:LoadSprite(configInfo:TitleBaseR(), self.imgTitleBase_r)
    else
        self.imgTitleBase_r:SetVisible(false)
    end
end

return PlayerTitleComponent