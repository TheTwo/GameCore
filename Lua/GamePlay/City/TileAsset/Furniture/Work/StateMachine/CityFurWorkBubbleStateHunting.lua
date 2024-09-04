local CityFurWorkBubbleStateBase = require("CityFurWorkBubbleStateBase")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")
local DBEntityPath = require("DBEntityPath")
local ConfigRefer = require("ConfigRefer")
local I18N = require("I18N")
local Utils = require("Utils")
---@class CityFurWorkBubbleStateHunting:CityFurWorkBubbleStateBase
local CityFurWorkBubbleStateHunting = class("CityFurWorkBubbleStateHunting", CityFurWorkBubbleStateBase)

function CityFurWorkBubbleStateHunting:GetName()
    return CityFurWorkBubbleStateBase.Names.Hunting
end

function CityFurWorkBubbleStateHunting:Enter()
    CityFurWorkBubbleStateBase.Enter(self)
    local bubble = self.tileAsset:GetBubble()
    if bubble and bubble:IsValid() then
        self:OnBubbleLoaded(bubble)
    else
        self:OnBubbleUnload()
    end
    g_Game.DatabaseManager:AddChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetChanged))
end

function CityFurWorkBubbleStateHunting:Exit()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.CastleBrief.TroopPresets.Presets.MsgPath, Delegate.GetOrCreate(self, self.OnTroopPresetChanged))
end

---@param bubble City3DBubbleStandard
function CityFurWorkBubbleStateHunting:OnBubbleLoaded(bubble)
    self._bubble = bubble
    self._bubble:Reset()
    local icon = ConfigRefer.HuntingConst:HuntingBubbleIcon()
    if Utils.IsNullOrEmpty(icon) then
        icon = "sp_item_icon_debris_egril"
    end
    self._bubble:ShowBubble(icon):ShowBubbleBackIcon("sp_city_bubble_base_yellow")
    self._bubble:SetBubbleIconSortingOrder(1300)
    self._bubble:SetOnTrigger(Delegate.GetOrCreate(self, self.OnClick), self:GetTile())

    self:OnTroopPresetChanged()
end

function CityFurWorkBubbleStateHunting:OnBubbleUnload()
    if self._bubble then
        self._bubble:ClearTrigger()
        self._bubble = nil
    end
end

function CityFurWorkBubbleStateHunting:OnClick()
    ModuleRefer.HuntingModule:OpenHuntingMediator()
    return true
end

function CityFurWorkBubbleStateHunting:OnTroopPresetChanged()
    if not self._bubble then return end

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
    local threshold = ConfigRefer.HuntingConst:HUDHintThreshold()
    if (highestTroopPower - secInfo.power) / secInfo.power > (threshold / 100) then
        self._bubble:ShowBubbleText(I18N.Get("hunt_mention_tip"))
    else
        self._bubble:ShowBubbleText(nil)
    end
end

return CityFurWorkBubbleStateHunting