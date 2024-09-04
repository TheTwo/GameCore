local SlgUtils = require("SlgUtils")
local MailUtils = require("MailUtils")

---@class TroopHUDSimplified
local TroopHUDSimplified = class("TroopHUDSimplified")

function TroopHUDSimplified:FeedData(ctrl)
    self.rootSelf:SetVisible(false)
    self.rootFriend:SetVisible(false)
    self.rootEnemy:SetVisible(false)

    local troopType = ctrl.troopType
    if troopType == SlgUtils.TroopType.MySelf then
        self.rootSelf:SetVisible(true)
    elseif troopType == SlgUtils.TroopType.Friend then
        self.rootFriend:SetVisible(true)
    elseif troopType == SlgUtils.TroopType.Enemy then
        self.rootEnemy:SetVisible(true)
    end

    ---@type wds.Troop
    local troop = ctrl:GetData()
    if troop and troop.Battle and troop.Battle.Group and troop.Battle.Group.Heros then
        local mainHeroId = SlgUtils.GetTroopLeadHeroId(troop.Battle.Group.Heros)
        local heroIcon = MailUtils.GetHeroHeadMiniById(mainHeroId)
        g_Game.SpriteManager:LoadSpriteAsync(heroIcon, self.headImg)
    end
end

function TroopHUDSimplified:SetVisible(visible)
    self.facingCamera.transform:SetVisible(visible)
end

return TroopHUDSimplified