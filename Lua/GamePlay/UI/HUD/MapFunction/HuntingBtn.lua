local BaseUIComponent = require("BaseUIComponent")
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local NotificationType = require("NotificationType")
local DBEntityPath = require("DBEntityPath")
---@class HuntingBtn:BaseUIComponent
local HuntingBtn = class("HuntingBtn", BaseUIComponent)

function HuntingBtn:ctor()
    self.threshold = ConfigRefer.HuntingConst:HUDHintThreshold()
end

function HuntingBtn:OnCreate()
    self.goHunting = self:GameObject('')
    self.btnHunting = self:Button('', Delegate.GetOrCreate(self, self.OnHuntingButtonClick))

    self.goBubbleTips = self:GameObject('p_bubble_tips')
    self.btnBubbleTips = self:Button('p_bubble_tips', Delegate.GetOrCreate(self, self.OnHuntingButtonClick))
    self.imgItem = self:Image('p_icon_item')

    self.compReddotHunting = self:LuaObject('child_reddot_hunting')
    self.compReddotHunting:SetVisible(true)
end

function HuntingBtn:OnShow()
    -- g_Game.EventManager:AddListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.UpdateHuntingBtnState))
    -- g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetChanged))

    local redNodeHunting = ModuleRefer.NotificationModule:GetDynamicNode("HUNTING_HUD", NotificationType.HUNTING_HUD)
    ModuleRefer.NotificationModule:AttachToGameObject(redNodeHunting, self.compReddotHunting.go, self.compReddotHunting.redDot)

    -- self:OnTroopPresetChanged()
    self:UpdateHuntingBtnVisibility()
end

function HuntingBtn:OnHide()
    -- g_Game.EventManager:RemoveListener(EventConst.SYSTEM_ENTRY_OPEN, Delegate.GetOrCreate(self, self.UpdateHuntingBtnState))
    -- g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetChanged))
end

function HuntingBtn:UpdateHuntingBtnState(unlockList)
    local sysId = ConfigRefer.HuntingConst:FuncSwitch()
    if not table.ContainsValue(unlockList, sysId) then
        return
    end
    self:UpdateHuntingBtnVisibility()
end

function HuntingBtn:UpdateHuntingBtnVisibility()
    local isUnlocked = ModuleRefer.HuntingModule:IsUnlocked()
    -- self.goHunting:SetActive(isUnlocked)
    self.goHunting:SetActive(false)
end

function HuntingBtn:OnHuntingButtonClick()
    ModuleRefer.HuntingModule:OpenHuntingMediator()
end

function HuntingBtn:OnTroopPresetChanged()
    local castle = ModuleRefer.PlayerModule:GetCastle()
	local presets = castle.TroopPresets.Presets
    local highestTroopPower = 0
    for i, _ in ipairs(presets) do
        local power = ModuleRefer.TroopModule:GetTroopPower(i)
        if power > highestTroopPower then
            highestTroopPower = power
        end
    end
    local nextHuntingSecId = ModuleRefer.HuntingModule:GetNextImportantRewardSectionId()
    local secInfo = ModuleRefer.HuntingModule:GetSectionInfo(nextHuntingSecId)

    local itemCfg = ConfigRefer.Item:Find(secInfo.importantRewardId)
    if (highestTroopPower - secInfo.power) / secInfo.power > (self.threshold / 100) and itemCfg then
        self.goBubbleTips:SetActive(true)
        g_Game.SpriteManager:LoadSprite(itemCfg:Icon(), self.imgItem)
    else
        self.goBubbleTips:SetActive(false)
    end
end

return HuntingBtn