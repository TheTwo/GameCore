local Delegate = require("Delegate")
local CommonPlayerDefine = require("CommonPlayerDefine")
local ModuleRefer = require('ModuleRefer')
local BaseUIComponent = require("BaseUIComponent")
local DBEntityPath = require('DBEntityPath')
local DBEntityType = require("DBEntityType")
local EventConst = require("EventConst")
local Utils = require("Utils")
local UIMediatorNames = require('UIMediatorNames')

---@class PlayerInfoComponent : BaseUIComponent
---@field iconId number
---@field iconName string
local PlayerInfoComponent = class("PlayerInfoComponent", BaseUIComponent)

function PlayerInfoComponent:ctor()
    BaseUIComponent.ctor(self)
    ---@type fun()
    self._onClickFunc = nil
    self.iconId = nil
    self.iconName = string.Empty
    self.frameIconId = nil
    self.customAvatar = nil
    self._customIconRequestId = 0
end

function PlayerInfoComponent:OnCreate(param)
    self._img_PlayerFrame = self:Image('p_frame_head')
    self._img_PlayerIcon = self:Image('p_icon_head')
    self._img_CustomIcon = self:Image("p_player_custom_head")
    self._p_btn_head = self:Button("p_btn_head", Delegate.GetOrCreate(self, self.OnClickPlayerHead))
end

function PlayerInfoComponent:OnShow(param)
    g_Game.EventManager:AddListener(EventConst.PLAYER_CUSTOM_ICON_READY, Delegate.GetOrCreate(self, self.OnPlayerCustomIconReady))
end

function PlayerInfoComponent:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.PLAYER_CUSTOM_ICON_READY, Delegate.GetOrCreate(self, self.OnPlayerCustomIconReady))
end

function PlayerInfoComponent:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.PLAYER_CUSTOM_ICON_READY, Delegate.GetOrCreate(self, self.OnPlayerCustomIconReady))
end

PlayerInfoComponent.WrapToNewMap = {
    ["wds.PlayerBasicInfo"] = true,
    ["wds.AllianceMember"] = true,
    ["wds.DamagePlayerInfo"] = true,
    ["wds.TopListMemDataPlayer"] = true,
    ["wds.TopListMemDataPlayer"] = true,
    ["wrpc.AllianceMemberInfo"] = true,
}

---@param data wds.PortraitInfo|wrpc.PortraitInfo|wrpc.AllianceMemberInfo|wds.Owner|{iconId:number, iconName:string, frameIconId:number}
function PlayerInfoComponent:OnFeedData(data)
    self._customIconRequestId = 0
    self.iconId = nil
    self.iconName = string.Empty
    self.frameIconName = nil
    self.customAvatar = nil
    self.playerId = data.PlayerId or data.PlayerID
    if data and data.TypeName then
        local typeName = data.TypeName
        if typeName == "wds.PortraitInfo" or typeName == "wrpc.PortraitInfo" then
            self:DoFeedOnPortraitInfo(data)
            return
        end
        if typeName == "wds.Owner" then
            self:DoFeedOnPortraitInfo(data.OwnerAppearance.PortraitInfo)
            return
        end
        if PlayerInfoComponent.WrapToNewMap[typeName] then
            self:DoFeedOnPortraitInfo(data.PortraitInfo)
            return
        end
        if data.PortraitInfo and (data.PortraitInfo.TypeName == "wds.PortraitInfo" or data.PortraitInfo.TypeName == "wrpc.PortraitInfo") then
            self:DoFeedOnPortraitInfo(data.PortraitInfo)
        end
        g_Logger.Warn("PlayerInfoComponent supported feed data type need wds.PortraitInfo! %s", data)
    end
    if data then
        self.iconId = data.iconId
        self.iconName = data.iconName
        if data.frameIconId then
            self.frameIconId = data.frameIconId
        end
        if not self.iconId and not self.iconName then
            if data.HeadPortrait and type(data.HeadPortrait) == "number" then
                self.iconId = data.HeadPortrait
            end
        end
    end

    if (self.iconId and self.iconId < 1) then
        self.iconId = 1
    end
    self:RefreshHeadIcon()
    self:RefreshCustomAvatar()
    self:RefreshHeadFrameIcon()
end

---@param data wds.PortraitInfo
function PlayerInfoComponent:DoFeedOnPortraitInfo(data)
    self.iconName = nil
    self.iconId = data.PlayerPortrait
    if not self.iconId or self.iconId < 1 then
        self.iconId = 1
    end
    self.frameIconId = data.PortraitFrameId
    self.customAvatar = data.CustomAvatar -- 'https://pic.616pic.com/ys_bnew_img/00/13/44/S1u5Y2obmQ.jpg'
    self:RefreshHeadIcon()
    self:RefreshCustomAvatar()
    self:RefreshHeadFrameIcon()
end

function PlayerInfoComponent:RefreshHeadIcon()
    local iconName
    if string.IsNullOrEmpty(self.iconName) then
        if (self.iconId) then
            iconName = ModuleRefer.PlayerModule:GetPortraitSpriteName(self.iconId)
        else
            iconName = ModuleRefer.PlayerModule:GetSelfPortraitSpriteName()
        end
    else
        iconName = self.iconName
    end
    self:ChangeIcon(iconName)
end

function PlayerInfoComponent:RefreshHeadFrameIcon()
    if self.frameIconId then
        local spriteName = ModuleRefer.PlayerModule:GetPortraitFrameSpriteName(self.frameIconId)
        if not string.IsNullOrEmpty(spriteName) then
            self._img_PlayerFrame:SetVisible(true)
            g_Game.SpriteManager:LoadSprite(spriteName, self._img_PlayerFrame)
        else
            self._img_PlayerFrame:SetVisible(false)
        end
    end
end

function PlayerInfoComponent:RefreshCustomAvatar()
    if string.IsNullOrEmpty(self.customAvatar) then
        self._img_PlayerIcon:SetVisible(true)
        if Utils.IsNotNull(self._img_CustomIcon) then
            self._img_CustomIcon:SetVisible(false)
        end
        return
    end
    local success, reqId = ModuleRefer.PlayerCustomIconModule:LoadSpite(self.customAvatar, self._img_CustomIcon)
    self._customIconRequestId = success and reqId or 0
    if Utils.IsNotNull(self._img_CustomIcon) then
        self._img_CustomIcon:SetVisible(success)
    else
        if UNITY_EDITOR then
            error("求求了 组件导出别再用内嵌式的了 PlayerInfoComponent._img_CustomIcon is nil!")
        else
            g_Logger.Error("求求了 组件导出别再用内嵌式的了 PlayerInfoComponent._img_CustomIcon is nil!")
        end
    end
    self._img_PlayerIcon:SetVisible(not success)
end

function PlayerInfoComponent:ChangeIcon(iconName)
    self._customIconRequestId = 0
    self._img_PlayerIcon:SetVisible(true)
    if Utils.IsNotNull(self._img_CustomIcon) then
        self._img_CustomIcon:SetVisible(false)
    end
    g_Game.SpriteManager:LoadSprite(iconName, self._img_PlayerIcon)
end

---@param callback fun()
function PlayerInfoComponent:SetClickHeadCallback(callback)
    self._onClickFunc = callback
end

function PlayerInfoComponent:OnClickPlayerHead()
    if self._onClickFunc then
        self._onClickFunc()
        return
    end

    if self.playerId then
        ModuleRefer.PlayerModule:ShowPlayerInfoPanel(self.playerId,self._p_btn_head.gameObject)
    end
end

function PlayerInfoComponent:OnPlayerCustomIconReady(reqIndex, _)
    if self._customIconRequestId ~= reqIndex then
        return
    end
    self._customIconRequestId = 0
    self:RefreshCustomAvatar()
end

return PlayerInfoComponent
