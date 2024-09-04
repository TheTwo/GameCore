--- scene:scene_child_league_logo

local Utils = require("Utils")
local AllianceModuleDefine = require("AllianceModuleDefine")
local Delegate = require("Delegate")

local BaseUIComponent = require("BaseUIComponent")

---@class CommonAllianceLogoComponent:BaseUIComponent
---@field new fun():CommonAllianceLogoComponent
---@field super BaseUIComponent
local CommonAllianceLogoComponent = class('CommonAllianceLogoComponent', BaseUIComponent)

function CommonAllianceLogoComponent:ctor()
    BaseUIComponent.ctor(self)
    self._backgroundVisible = true
end

function CommonAllianceLogoComponent:OnCreate(param)
    self._p_icon_logo_bg = self:Image("p_icon_logo_bg")
    self._p_icon_logo = self:Image("p_icon_logo")
    self._p_btn_head = self:Button("p_btn_head", Delegate.GetOrCreate(self, self.OnClickLogo))
end

---@param data wrpc.AllianceFlag
function CommonAllianceLogoComponent:OnFeedData(data)
    if not data then
        return
    end
    self:Refresh(data.BadgeAppearance, data.BadgePattern)
end

function CommonAllianceLogoComponent:Refresh(appear, pattern)
    if appear and pattern then
        local appearSprite, patternSprite, _ = AllianceModuleDefine.GetAllianceFlagDetailByValue(appear, pattern, 0)
        if Utils.IsNotNull(self._p_icon_logo_bg) then
            g_Game.SpriteManager:LoadSprite(appearSprite, self._p_icon_logo_bg)
            self._p_icon_logo_bg:SetVisible(self._backgroundVisible)
        end
        if Utils.IsNotNull(self._p_icon_logo) then
            g_Game.SpriteManager:LoadSprite(patternSprite, self._p_icon_logo)
            self._p_icon_logo:SetVisible(true)
        end
    else
        self._p_icon_logo_bg:SetVisible(false)
        self._p_icon_logo:SetVisible(false)

    end
end

function CommonAllianceLogoComponent:BackgroundVisible(show)
    self._backgroundVisible = show
    if Utils.IsNotNull(self._p_icon_logo_bg) then
        self._p_icon_logo_bg:SetVisible(show)
    end
end

---@param callback fun()
function CommonAllianceLogoComponent:SetClickCallback(callback)
    self._onClickFunc = callback
end

function CommonAllianceLogoComponent:OnClickLogo()
    if self._onClickFunc then
        self._onClickFunc()
    end
end

return CommonAllianceLogoComponent