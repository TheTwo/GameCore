local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local UIMediatorNames = require("UIMediatorNames")
local ConfigRefer = require("ConfigRefer")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local DBEntityType = require("DBEntityType")
local KingdomMapUtils = require("KingdomMapUtils")
local TimeFormatter = require("TimeFormatter")
local Delegate = require("Delegate")
local DBEntityPath = require("DBEntityPath")

local AllianceBehemothInfoComponentOperationProvider = require("AllianceBehemothInfoComponentOperationProvider")

---@class AllianceBehemothMainOperationProvider:AllianceBehemothInfoComponentOperationProvider
---@field new fun():AllianceBehemothMainOperationProvider
---@field super AllianceBehemothInfoComponentOperationProvider
local AllianceBehemothMainOperationProvider = class('AllianceBehemothMainOperationProvider', AllianceBehemothInfoComponentOperationProvider)

function AllianceBehemothMainOperationProvider:ShowDetailTip()
    return true
end

function AllianceBehemothMainOperationProvider:OnClickDetailTip(clickRectTrans)
    ModuleRefer.ToastModule:SimpleShowTextToastTip(I18N.Get("alliance_behemoth_rule_declarecage"), clickRectTrans)
end

function AllianceBehemothMainOperationProvider:ShowInChallengeText()
    local battle = ModuleRefer.AllianceModule.Behemoth:GetCurrentBehemothActivityWar()
    if not battle then return false end
    if battle.Status ~= wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then return false end
    local selfFacebookId = ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID
    return battle.Members[selfFacebookId] == nil
end

function AllianceBehemothMainOperationProvider:TickInChallengeText(dt)
    local battle = ModuleRefer.AllianceModule.Behemoth:GetCurrentBehemothActivityWar()
    if not battle then return false, string.Empty end
    local leftTime = battle.CloseTime.ServerSecond - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    return true, I18N.Get("Alliance_battle_hud3") .. ' ' .. TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)
end

function AllianceBehemothMainOperationProvider:ShowChallenge()
    if self:ShowInChallengeText() then return false end
    if ModuleRefer.AllianceModule:IsAllianceLeader() then return false end
    if not ModuleRefer.AllianceModule:IsAllianceR4Above() then return false end
    if ModuleRefer.AllianceModule.Behemoth:IsCurrentBehemothInSummon() then return false end
    local battle = ModuleRefer.AllianceModule.Behemoth:GetCurrentBehemothActivityWar()
    return battle ~= nil
end

function AllianceBehemothMainOperationProvider:OnClickChallenge()
    -- -----@type ActivityCenterOpenParam
    -- local param = {}
    -- param.tabId = ConfigRefer.AllianceConsts:BehemothActiviyChallengeTab()
    -- g_Game.UIManager:Open(UIMediatorNames.ActivityCenterMediator, param)
    ModuleRefer.ActivityBehemothModule:GotoBehemothActivity()
end

function AllianceBehemothMainOperationProvider:ShowChallengeR5()
    if self:ShowInChallengeText() then return false end
    if not ModuleRefer.AllianceModule:IsAllianceLeader() then return false end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.ActivateBattle) then return false end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.OpenBattle) then return false end
    if ModuleRefer.AllianceModule.Behemoth:IsCurrentBehemothInSummon() then return false end
    local battle = ModuleRefer.AllianceModule.Behemoth:GetCurrentBehemothActivityWar()
    return battle ~= nil
end

function AllianceBehemothMainOperationProvider:OnClickChallengeR5()
    -- -----@type ActivityCenterOpenParam
    -- local param = {}
    -- param.tabId = ConfigRefer.AllianceConsts:BehemothActiviyChallengeTab()
    -- g_Game.UIManager:Open(UIMediatorNames.ActivityCenterMediator, param)
    ModuleRefer.ActivityBehemothModule:GotoBehemothActivity()
end

function AllianceBehemothMainOperationProvider:ShowCall()
    if self:ShowInChallengeText() then return false end
    return ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.SummonBehemoth) and not ModuleRefer.AllianceModule.Behemoth:IsCurrentBehemothInSummon()
end

function AllianceBehemothMainOperationProvider:IsCallDisabled()
    return ModuleRefer.AllianceModule.Behemoth:IsCurrentBehemothInSummon()
end

function AllianceBehemothMainOperationProvider:GetServerPosition()
    local castle = ModuleRefer.PlayerModule:GetCastle()
    return castle.MapBasics.Position.X, castle.MapBasics.Position.Y
end

function AllianceBehemothMainOperationProvider:OnClickCall()
    local summonInfo = ModuleRefer.AllianceModule.Behemoth:GetSummonerInfo()
    if not summonInfo then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_tips_CitySummon"))
        return false
    end
    local staticMapData = KingdomMapUtils.GetStaticMapData()
    local x,z = self:GetServerPosition()
    
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    local inKingdomMap = false
    if scene and scene:GetName() == 'KingdomScene' and not scene:IsInCity() then
        local lookAt = scene.basicCamera:GetLookAtPlanePosition()
        x = lookAt.x / staticMapData.UnitsPerTileX
        z = lookAt.z / staticMapData.UnitsPerTileZ
        inKingdomMap = true
    end
    local allianceBuilds = ModuleRefer.AllianceModule:GetMyAllianceDataMapBuildingBriefs()
    local distance = nil
    local chooseX,chooseY
    for _, v in pairs(allianceBuilds) do
        if v.EntityTypeHash == DBEntityType.Village or v.EntityTypeHash == DBEntityType.EnergyTower then
            local pos = v.Pos
            local d = (pos.X - x) * (pos.X - x) + (pos.Y - z) * (pos.Y - z)
            if not distance or distance > d then
                distance = d
                chooseX,chooseY = pos.X,pos.Y
            end
        end
    end
    if chooseX and chooseY then
        AllianceWarTabHelper.GoToCoord(chooseX, chooseY, true)
        return true
    end
    if not inKingdomMap then
        g_Game.EventManager:TriggerEvent(EventConst.HUD_GOTO_KINGDOM)
    end
    return true
end

function AllianceBehemothMainOperationProvider:ShowReward()
    return true
end

function AllianceBehemothMainOperationProvider:OnClickReward(clickRectTrans)
    ---@type AllianceBehemothAwardTipMediatorParameter
    local param = {}
    param.kMonsterConfig = self._currentBehemoth:GetRefKMonsterDataConfig(ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel())
    param.clickTrans = clickRectTrans
    g_Game.UIManager:Open(UIMediatorNames.AllianceBehemothAwardTipMediator, param)
end

function AllianceBehemothMainOperationProvider:ShowNowControl()
    return self:NeedTickNowControl()
end

function AllianceBehemothMainOperationProvider:NeedTickNowControl()
    local info = ModuleRefer.AllianceModule.Behemoth:GetCurrentInSummonBehemothInfo()
    if not info then return false end
    local endTime = info:GetVanishTime()
    if not endTime then return false end
    return endTime > g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
end

function AllianceBehemothMainOperationProvider:TickNowControl(dt)
    local info = ModuleRefer.AllianceModule.Behemoth:GetCurrentInSummonBehemothInfo()
    if not info then return false, string.Empty end
    local endTime = info:GetVanishTime()
    if not endTime then return false, string.Empty end
    local leftTime = endTime - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    if leftTime >= 0 then
        return true, I18N.GetWithParams("alliance_war_toast9", TimeFormatter.SimpleFormatTimeWithoutZero(leftTime))
    end
    return false, string.Empty
end

function AllianceBehemothMainOperationProvider:ShowR5Text()
    return ModuleRefer.AllianceModule:IsAllianceLeader()
end

function AllianceBehemothMainOperationProvider:R5Text()
    return I18N.Get("alliance_behemoth_summon_tip2")
end

function AllianceBehemothMainOperationProvider:ShowCivilianText()
    return not ModuleRefer.AllianceModule:IsAllianceR4Above()
end

function AllianceBehemothMainOperationProvider:CivilianText()
    return I18N.Get("alliance_behemoth_summon_tip1")
end

function AllianceBehemothMainOperationProvider:OnShow()
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_ADD, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_UPDATE, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_REMOVED, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.RefreshHost))
end

function AllianceBehemothMainOperationProvider:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_ADD, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_UPDATE, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_UPDATE, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_REMOVED, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.RefreshHost))   
end

function AllianceBehemothMainOperationProvider:RefreshHost()
    self._host:RefreshBehemoth()
    self._host:RefreshOperation()
end

return AllianceBehemothMainOperationProvider