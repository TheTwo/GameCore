local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')
local UIMediatorNames = require('UIMediatorNames')
local TimeFormatter = require('TimeFormatter')
local ProtectDefine = require('ProtectDefine')
local Utils = require('Utils')


---@class PlayerStatusToastMediator : BaseUIMediator
local PlayerStatusToastMediator = class('PlayerStatusToastMediator', BaseUIMediator)

---@class PlayerStatusToastParam
---@field status number


function PlayerStatusToastMediator:OnCreate()
    self.imgStatus = self:Image('p_icon_playerstatus')
    self.textStatus = self:Text('p_text_playerstatus')

    self.sliderProgress = self:BindComponent("p_progress", typeof(CS.UnityEngine.UI.Slider))
    self.textTime = self:Text('p_text_time')

    self.goBtnRoot = self:GameObject('btn')
    self.btnDetail = self:Button('p_btn_detail', Delegate.GetOrCreate(self, self.OnDetailBtnClick))
    self.textDetail = self:Text('p_text_detail', I18N.Get("protect_info_details"))
end

---@param param PlayerStatusToastParam
function PlayerStatusToastMediator:OnOpened(param)
    self:SetStatus(param.status)
    
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
end


function PlayerStatusToastMediator:OnClose(param)

    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTicker))
end

function PlayerStatusToastMediator:SetStatus(status)
    self.status = status
    self.totalTime = 0
    self.endTime = 0
    self.goBtnRoot:SetActive(false)
    
    local spriteName = ModuleRefer.ProtectModule:GetProtectStatusIconName(self.status)
    g_Game.SpriteManager:LoadSprite(spriteName, self.imgStatus)

    local stateWrapper = ModuleRefer.PlayerModule:GetCastle().MapStates.StateWrapper
    if self.status == ProtectDefine.STATUS_TYPE.Newbie_Protect then
        self.endTime = stateWrapper.FallCastleAddonExpireTime
        self.attrEndTime = stateWrapper.ProtectionExpireTime
        local protectConfig = ConfigRefer.Protection:Find(ProtectDefine.Protection_NewbieProtectIndex)
        self.totalTime =  Utils.ParseDurationToSecond(protectConfig:Duration())
        self.textStatus.text = I18N.Get("protect_info_Novice_help")
        self.goBtnRoot:SetActive(true)
    elseif self.status == ProtectDefine.STATUS_TYPE.Item_Protect then
        self.endTime = stateWrapper.ProtectionExpireTime
        local protectConfig = ConfigRefer.Protection:Find(stateWrapper.ProtectionConfigId)
        self.totalTime =  Utils.ParseDurationToSecond(protectConfig:Duration())
        self.textStatus.text = I18N.Get("protect_info_shield")
    elseif self.status == ProtectDefine.STATUS_TYPE.War then
        self.endTime = stateWrapper.WarExpireTime
        self.totalTime = Utils.ParseDurationToSecond(ConfigRefer.ConstMain:WarStateDuration())
        self.textStatus.text = I18N.Get("protect_info_war_state ")
    else
        self.status = ProtectDefine.STATUS_TYPE.Normal
    end
    self:RefreshTime()
    if self.totalTime == 0 or self.status == ProtectDefine.STATUS_TYPE.Normal then
        self:CloseSelf()
    end
end

function PlayerStatusToastMediator:OnSecondTicker()
    self:RefreshTime()
end

function PlayerStatusToastMediator:RefreshTime()
    if self.status == ProtectDefine.STATUS_TYPE.Normal or self.totalTime == 0 then
        return
    end
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    local leftTime = self.endTime - curTime
    if leftTime <= 0 then
        self:CloseSelf()
        return
    end
    self.sliderProgress.value = 1 - leftTime / self.totalTime
    self.textTime.text = TimeFormatter.SimpleFormatTime(leftTime)
end

function PlayerStatusToastMediator:OnDetailBtnClick()
    ---@type NewbieAttrDetailsParam
    local param = {attrEndTime = self.attrEndTime, protectEndTime = self.endTime}
    g_Game.UIManager:Open(UIMediatorNames.NewbieAttrDetailsMediator, param)
    self:CloseSelf()
end


return PlayerStatusToastMediator