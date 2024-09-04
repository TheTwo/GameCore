local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local AllianceAuthorityItem = require("AllianceAuthorityItem")
local UIMediatorNames = require("UIMediatorNames")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local ConfigRefer = require("ConfigRefer")
local SlgTouchMenuHelper = require("SlgTouchMenuHelper")
local TimeFormatter = require("TimeFormatter")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local KingdomMapUtils = require("KingdomMapUtils")
local DBEntityType = require("DBEntityType")
local DBEntityPath = require("DBEntityPath")

local AllianceBehemothInfoComponentOperationProvider = require("AllianceBehemothInfoComponentOperationProvider")

---@class AllianceBehemothListOperationProvider:AllianceBehemothInfoComponentOperationProvider
---@field new fun():AllianceBehemothListOperationProvider
---@field super AllianceBehemothInfoComponentOperationProvider
local AllianceBehemothListOperationProvider = class('AllianceBehemothListOperationProvider', AllianceBehemothInfoComponentOperationProvider)

function AllianceBehemothListOperationProvider:SetCurrentContext(currentBehemoth)
    AllianceBehemothListOperationProvider.super.SetCurrentContext(self, currentBehemoth)
end

function AllianceBehemothListOperationProvider:DeviceRequireReady()
    return ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceBuildingStatus() == wds.BuildingStatus.BuildingStatus_Constructed
end


function AllianceBehemothListOperationProvider:ShowDetailTip()
    return true
end

function AllianceBehemothListOperationProvider:OnClickDetailTip(clickRectTrans)
    ModuleRefer.ToastModule:SimpleShowTextToastTip(I18N.Get("alliance_behemoth_rule_declarecage"), clickRectTrans)
end

function AllianceBehemothListOperationProvider:ShowInChallengeText()
    if not self:DeviceRequireReady() then return false end
    if not self._currentBehemoth or self._currentBehemoth ~= ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth() then return false end
    local battle = ModuleRefer.AllianceModule.Behemoth:GetCurrentBehemothActivityWar()
    if not battle then return false end
    if battle.Status ~= wds.AllianceActivityBattleStatus.AllianceBattleStatusBattling then return false end
    local selfFacebookId = ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID
    return battle.Members[selfFacebookId] == nil
end

function AllianceBehemothListOperationProvider:TickInChallengeText(dt)
    local battle = ModuleRefer.AllianceModule.Behemoth:GetCurrentBehemothActivityWar()
    if not battle then return false, string.Empty end
    local leftTime = battle.CloseTime.ServerSecond - g_Game.ServerTime:GetServerTimestampInSecondsNoFloor()
    return true, I18N.Get("Alliance_battle_hud3") .. ' ' .. TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)
end

function AllianceBehemothListOperationProvider:ShowChallenge()
    if not self:DeviceRequireReady() then return false end
    if not self._currentBehemoth or self._currentBehemoth ~= ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth() then return false end
    if self:ShowInChallengeText() then return false end
    if ModuleRefer.AllianceModule:IsAllianceLeader() then return false end
    if not ModuleRefer.AllianceModule:IsAllianceR4Above() then return false end
    if ModuleRefer.AllianceModule.Behemoth:IsCurrentBehemothInSummon() then return false end
    local battle = ModuleRefer.AllianceModule.Behemoth:GetCurrentBehemothActivityWar()
    return battle ~= nil
end

function AllianceBehemothListOperationProvider:OnClickChallenge()
    ModuleRefer.ActivityBehemothModule:GotoBehemothActivity()
end

function AllianceBehemothListOperationProvider:ShowChallengeR5()
    if not self:DeviceRequireReady() then return false end
    if not self._currentBehemoth or self._currentBehemoth ~= ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth() then return false end
    if self:ShowInChallengeText() then return false end
    if not ModuleRefer.AllianceModule:IsAllianceLeader() then return false end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.ActivateBattle) then return false end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.OpenBattle) then return false end
    if ModuleRefer.AllianceModule.Behemoth:IsCurrentBehemothInSummon() then return false end
    local battle = ModuleRefer.AllianceModule.Behemoth:GetCurrentBehemothActivityWar()
    return battle ~= nil
end

function AllianceBehemothListOperationProvider:OnClickChallengeR5()
    ModuleRefer.ActivityBehemothModule:GotoBehemothActivity()
end

function AllianceBehemothListOperationProvider:ShowCall()
    if not self:DeviceRequireReady() then return false end
    if not self._currentBehemoth or self._currentBehemoth ~= ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth() then return false end
    if self:ShowInChallengeText() then return false end
    return ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.SummonBehemoth) and not ModuleRefer.AllianceModule.Behemoth:IsCurrentBehemothInSummon()
end

function AllianceBehemothListOperationProvider:IsCallDisabled()
    return ModuleRefer.AllianceModule.Behemoth:IsCurrentBehemothInSummon()
end

function AllianceBehemothListOperationProvider:GetServerPosition()
    local castle = ModuleRefer.PlayerModule:GetCastle()
    return castle.MapBasics.Position.X, castle.MapBasics.Position.Y
end

function AllianceBehemothListOperationProvider:OnClickCall()
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

function AllianceBehemothListOperationProvider:ShowReward()
    return true
end

function AllianceBehemothListOperationProvider:OnClickReward(clickRectTrans)
    ---@type AllianceBehemothAwardTipMediatorParameter
    local param = {}
    param.kMonsterConfig = self._currentBehemoth:GetRefKMonsterDataConfig(ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceLevel() or 1)
    param.clickTrans = clickRectTrans
    g_Game.UIManager:Open(UIMediatorNames.AllianceBehemothAwardTipMediator, param)
end

function AllianceBehemothListOperationProvider:ShowChange()
    if not self:DeviceRequireReady() then return false end
    if not self._currentBehemoth or self._currentBehemoth == ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth() then return false end
    if not self._currentBehemoth or self._currentBehemoth:IsFake() then return false end
    if not ModuleRefer.AllianceModule:CheckHasAuthority(AllianceAuthorityItem.BindBehemoth) then
        return false
    end
    if ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceBuildingStatus() ~= wds.BuildingStatus.BuildingStatus_Constructed then
        return false
    end
    if self._currentBehemoth == ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth() then
        return false
    end
    return true
end

function AllianceBehemothListOperationProvider:OnClickChange(clickTrans)
    local currentBehemoth = ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth()
    local currentBehemothBuildingId = currentBehemoth:GetBuildingEntityId()
    if ModuleRefer.AllianceModule.Behemoth:IsBehemothCageInActivityBattle(currentBehemothBuildingId) then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemoth_copy_notswitch"))
        return
    end
    if ModuleRefer.AllianceModule.Behemoth:IsCurrentBehemothInSummon() then
        ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("alliance_behemothSummon_tips_switch"))
        return
    end
    local cost = ConfigRefer.AllianceConsts:BindBehemothCostCurrency()
    local costCount = ConfigRefer.AllianceConsts:BindBehemothCostCurrencyCount()
    if cost ~= 0 and costCount > 0 then
        local monsterConfig = self._currentBehemoth:GetRefKMonsterDataConfig(1)
        local name, _, _ = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(monsterConfig)
        local targetName = name
        monsterConfig = currentBehemoth:GetRefKMonsterDataConfig(1)
        local oldBehemothName, _, _ = SlgTouchMenuHelper.GetMobNameImageLevelHeadIconsFromConfig(monsterConfig)
        ---@type CommonConfirmPopupMediatorParameter
        local param = {}
        param.content = I18N.GetWithParams("alliance_behemoth_attend_pop1", targetName, oldBehemothName)
        param.confirmLabel = I18N.Get("confirm")
        param.cancelLabel = I18N.Get("cancle")
        param.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel | CommonConfirmPopupMediatorDefine.Style.WithResource
        ---@type CommonResourceRequirementComponentParameter
        param.resourceParameter = {}
        param.resourceParameter.requireType = 3
        param.resourceParameter.requireId = cost
        param.resourceParameter.requireValue = costCount
        param.onConfirm = function()
            local hasCount = ModuleRefer.AllianceModule:GetAllianceCurrencyById(cost)
            if costCount > hasCount then
                ModuleRefer.ToastModule:AddSimpleToast(I18N.Get("world_build_ziyuanbuzu"))
                return false
            end
            if self._currentBehemoth:IsDeviceDefault() then
                local deviceInfo = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceBuildingId()
                ModuleRefer.AllianceModule.Behemoth:UnbindBehemoth(nil, deviceInfo)
            else
                local deviceId = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceBuildingId()
                ModuleRefer.AllianceModule.Behemoth:BindBehemoth(clickTrans, deviceId, self._currentBehemoth:GetBuildingEntityId())
            end
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, param)
    else
        if self._currentBehemoth:IsDeviceDefault() then
            local deviceInfo = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceBuildingId()
            ModuleRefer.AllianceModule.Behemoth:UnbindBehemoth(nil, deviceInfo)
        else
            local deviceId = ModuleRefer.AllianceModule.Behemoth:GetCurrentDeviceBuildingId()
            ModuleRefer.AllianceModule.Behemoth:BindBehemoth(clickTrans, deviceId, self._currentBehemoth:GetBuildingEntityId())
        end
    end
end

function AllianceBehemothListOperationProvider:ShowNowControl()
    if not self._currentBehemoth or self._currentBehemoth:IsFake() then return false end
    return self._currentBehemoth == ModuleRefer.AllianceModule.Behemoth:GetCurrentBindBehemoth() and ModuleRefer.AllianceModule.Behemoth:IsCurrentBehemothInSummon()
end

function AllianceBehemothListOperationProvider:TickNowControl(dt)
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

function AllianceBehemothListOperationProvider:ShowR5Text()
    if not self._currentBehemoth or self._currentBehemoth:IsFake() then return end
    return ModuleRefer.AllianceModule:IsAllianceLeader()
end

function AllianceBehemothListOperationProvider:R5Text()
    return I18N.Get("alliance_behemoth_summon_tip2")
end

function AllianceBehemothListOperationProvider:ShowCivilianText()
    if not self._currentBehemoth or self._currentBehemoth:IsFake() then return end
   return not ModuleRefer.AllianceModule:IsAllianceR4Above() 
end

function AllianceBehemothListOperationProvider:CivilianText()
    return I18N.Get("alliance_behemoth_attend_tip2")
end

function AllianceBehemothListOperationProvider:OnShow()
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_ADD, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_UPDATE, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.EventManager:AddListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_REMOVED, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.RefreshHost))
end

function AllianceBehemothListOperationProvider:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_ADD, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_UPDATE, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_UPDATE, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.EventManager:RemoveListener(EventConst.ALLIANCE_BEHEMOTH_MOBILE_FORTRESS_REMOVED, Delegate.GetOrCreate(self, self.RefreshHost))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Alliance.AllianceActivityBattles.Battles.MsgPath, Delegate.GetOrCreate(self, self.RefreshHost))   
end

function AllianceBehemothListOperationProvider:RefreshHost()
    self._host:RefreshBehemoth()
    self._host:RefreshOperation()
end

function AllianceBehemothListOperationProvider:ShowNotHave()
    if AllianceBehemothListOperationProvider.super.ShowNotHave(self) then return true end
    return not self:DeviceRequireReady()
end

return AllianceBehemothListOperationProvider