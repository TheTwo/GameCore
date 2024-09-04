local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local AdornmentType = require('AdornmentType')
local NotificationType = require('NotificationType')
local PersonaliseDefine = require('PersonaliseDefine')

---@class UIPlayerPersonaliseMediator : BaseUIMediator
local UIPlayerPersonaliseMediator = class('UIPlayerPersonaliseMediator', BaseUIMediator)


function UIPlayerPersonaliseMediator:OnCreate()
    self.compChildCommonBack = self:LuaObject('child_common_btn_back')

    self.btnBuff = self:Button('p_btn_buff', Delegate.GetOrCreate(self, self.OnClickBuff))
    self.textbuff = self:Text('p_text_buff', 'skincollection_increases')

    ---@type PlayerInfoComponent
    self.luaGoPlayerHead = self:LuaObject('child_ui_head_player')
    self.btnHeadFrame = self:Button('p_btn_head', Delegate.GetOrCreate(self, self.OnClickHeadFrame))
    self.textHeadFrame = self:Text('p_text_head', 'skincollection_frame')
    self.textHeadFrameSchedule = self:Text('p_text_head_quantity')
    self.reddot_frame = self:LuaObject('child_reddot_head')

    self.btnCitySkin = self:Button('p_btn_city', Delegate.GetOrCreate(self, self.OnClickCitySkin))
    self.imgCity = self:Image('p_img_city')
    self.textCitySkin = self:Text('p_text_city', 'skincollection_castleskin')
    self.textCitySkinSchedule = self:Text('p_text_city_quantity')
    self.reddot_citySkin = self:LuaObject('child_reddot_city')

    self.btnTitle = self:Button('p_btn_name', Delegate.GetOrCreate(self, self.OnClickTitle))
    self.luagoTitle = self:LuaObject('child_personalise_title')
    self.goEmptyTitle = self:GameObject('p_img_empty')
    self.textEmptyTitle = self:Text('p_text_empty', 'adornment_title0_name')
    self.textTitle = self:Text('p_text_name', 'skincollection_title')
    self.textTitleSchedule = self:Text('p_text_name_quantity')
    self.reddot_title = self:LuaObject('child_reddot_name')

    self.btnCitySkin:SetVisible(false)
end

function UIPlayerPersonaliseMediator:OnOpened(param)
    self.compChildCommonBack:FeedData({
        title = I18N.Get("skincollection_system")
    })

    self.reddot_frame:SetVisible(true)
    self.reddot_citySkin:SetVisible(true)
    self.reddot_title:SetVisible(true)
    local mainHeadFrameNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseMainHeadFrameNode", NotificationType.PERSONALISE_MAIN_HEAD_FRAME)
    ModuleRefer.NotificationModule:AttachToGameObject(mainHeadFrameNode, self.reddot_frame.go, self.reddot_frame.redDot)
    local mainCastleSkinNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseMainCastleSkinNode", NotificationType.PERSONALISE_MAIN_CASTLE_SKIN)
    ModuleRefer.NotificationModule:AttachToGameObject(mainCastleSkinNode, self.reddot_citySkin.go, self.reddot_citySkin.redDot)
    local mainTitleNode = ModuleRefer.NotificationModule:GetDynamicNode("PersonaliseMainTitleNode", NotificationType.PERSONALISE_MAIN_TITLE)
    ModuleRefer.NotificationModule:AttachToGameObject(mainTitleNode, self.reddot_title.go, self.reddot_title.redDot)

    ModuleRefer.PersonaliseModule:AdornmentOpenBILog(false, 0, 0)
end


function UIPlayerPersonaliseMediator:OnShow(param)
    self:RefreshHeadFrame()
    self:RefreshCastleSkin()
    self:RefreshTitle()
    ModuleRefer.PersonaliseModule:RefreshRedPoint()
end


function UIPlayerPersonaliseMediator:OnClose(param)
    --TODO
end

function UIPlayerPersonaliseMediator:RefreshHeadFrame()
    local player = ModuleRefer.PlayerModule:GetPlayer()
    ---@type wds.PortraitInfo
    self.luaGoPlayerHead:FeedData(player.Basics.PortraitInfo)
    self.textHeadFrameSchedule.text = self:GetHeadFrameSchedule()
end

function UIPlayerPersonaliseMediator:RefreshCastleSkin()
    local usingCitySkin = ModuleRefer.PersonaliseModule:GetUsingAdornmentDataByType(AdornmentType.CastleSkin)
    local usingCitySkinConfig = ConfigRefer.Adornment:Find(usingCitySkin.ConfigID)
    if usingCitySkinConfig and not string.IsNullOrEmpty(usingCitySkinConfig:Icon()) then
        g_Game.SpriteManager:LoadSprite(usingCitySkinConfig:Icon(), self.imgCity)
    end
    self.textCitySkinSchedule.text = self:GetCitySkinSchedule()
end

function UIPlayerPersonaliseMediator:RefreshTitle()
    local usingTitle = ModuleRefer.PersonaliseModule:GetUsingAdornmentDataByType(AdornmentType.Titles)
    if usingTitle.ConfigID == PersonaliseDefine.DefaultTitleID then
        self.luagoTitle:SetVisible(false)
        self.goEmptyTitle:SetActive(true)
    else
        self.luagoTitle:SetVisible(true)
        self.goEmptyTitle:SetActive(false)
        local usingTitleConfig = ConfigRefer.Adornment:Find(usingTitle.ConfigID)
        if usingTitleConfig then
            ---@type PlayerTitleParam
            local param = {configID = tonumber(usingTitleConfig:Icon()), name = I18N.Get(usingTitleConfig:Name())}
            self.luagoTitle:FeedData(param)
        end
    end
    
    self.textTitleSchedule.text = self:GetTitleSchedule()
end

function UIPlayerPersonaliseMediator:OnClickBuff()
    g_Game.UIManager:Open(UIMediatorNames.UIPlayerPersonaliseGainMediator)
end

function UIPlayerPersonaliseMediator:OnClickHeadFrame()
    ---@param param PersonaliseChangeParam
    g_Game.UIManager:Open(UIMediatorNames.PersonaliseChangeMediator, {typeIndex = AdornmentType.PortraitFrame})
    ModuleRefer.PersonaliseModule:AdornmentOpenBILog(true, 0, AdornmentType.PortraitFrame)
end

function UIPlayerPersonaliseMediator:OnClickCitySkin()
    ---@param param PersonaliseChangeParam
    g_Game.UIManager:Open(UIMediatorNames.PersonaliseChangeMediator, {typeIndex = AdornmentType.CastleSkin})
    ModuleRefer.PersonaliseModule:AdornmentOpenBILog(true, 0, AdornmentType.CastleSkin)
end

function UIPlayerPersonaliseMediator:OnClickTitle()
    ---@param param PersonaliseChangeParam
    g_Game.UIManager:Open(UIMediatorNames.PersonaliseChangeMediator, {typeIndex = AdornmentType.Titles})
    ModuleRefer.PersonaliseModule:AdornmentOpenBILog(true, 0, AdornmentType.Titles)
end

function UIPlayerPersonaliseMediator:GetHeadFrameSchedule()
    local have, total = ModuleRefer.PersonaliseModule:GetScheduleByType(AdornmentType.PortraitFrame)
    return string.format("%d/%d", have, total)
end

function UIPlayerPersonaliseMediator:GetCitySkinSchedule()
    local have, total = ModuleRefer.PersonaliseModule:GetScheduleByType(AdornmentType.CastleSkin)
    return string.format("%d/%d", have, total)
end

function UIPlayerPersonaliseMediator:GetTitleSchedule()
    local have, total = ModuleRefer.PersonaliseModule:GetScheduleByType(AdornmentType.Titles)
    return string.format("%d/%d", have, total)
end


return UIPlayerPersonaliseMediator