local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local KingdomMapUtils = require("KingdomMapUtils")
local UIMediatorNames = require("UIMediatorNames")
local EventConst = require("EventConst")
local KingdomConstant = require("KingdomConstant")
local MapUtils = CS.Grid.MapUtils
local CameraConst = require("CameraConst")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local MapBuildingSubType = require("MapBuildingSubType")
local Utils = require("Utils")

local AllianceWarBuildingCellData = require("AllianceWarBuildingCellData")

---@class AllianceWarBuildingCellDataVillageWar:AllianceWarBuildingCellData
---@field new fun(id:number):AllianceWarBuildingCellDataVillageWar
---@field super AllianceWarBuildingCellData
local AllianceWarBuildingCellDataVillageWar = class('AllianceWarBuildingCellDataVillageWar', AllianceWarBuildingCellData)

function AllianceWarBuildingCellDataVillageWar:ctor(id)
    AllianceWarBuildingCellData.ctor(self, id, 1)
    ---@type CS.UnityEngine.RectTransform
    self._tipRect = nil
end

---@param payload wds.VillageAllianceWarInfo
function AllianceWarBuildingCellDataVillageWar:UpdateData(payload, isUnderAttack)
    ---@type wds.VillageAllianceWarInfo
    self._warInfo = payload
    self._isAttack = (not isUnderAttack)
    self._territoryConfig = ConfigRefer.Territory:Find(payload.TerritoryId)
    self._buildingConfig = ConfigRefer.FixedMapBuilding:Find(self._territoryConfig:VillageId())
    local pos = self._territoryConfig:VillagePosition()
    self._posX = pos:X()
    self._posY = pos:Y()
    local castlePos = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
    self._distance = AllianceWarTabHelper.CalculateMapDistance(pos:X(), pos:Y(), castlePos.X, castlePos.Y)
end

---@return {allianceId:number, abbr:string, name:string}|nil
function AllianceWarBuildingCellDataVillageWar:GetSourceInfo()
    if self._warInfo then
        return {allianceId =  self._warInfo.AllianceId, abbr = self._warInfo.ChangeData.AttackerAbbr, name = self._warInfo.ChangeData.AttackerName}
    end
    return nil
end

function AllianceWarBuildingCellDataVillageWar:GetDistance()
    return self._distance
end

function AllianceWarBuildingCellDataVillageWar:UseTick()
    return true
end

function AllianceWarBuildingCellDataVillageWar:IsAttack()
    return self._isAttack
end

function AllianceWarBuildingCellDataVillageWar:GetPos()
    return self._posX, self._posY
end

function AllianceWarBuildingCellDataVillageWar:GetTargetName()
    return I18N.Get(self._buildingConfig:Name())
end

function AllianceWarBuildingCellDataVillageWar:GetTargetIcon()
    return self._buildingConfig:Image()
end

function AllianceWarBuildingCellDataVillageWar:GetLv()
    local villageConfig = ConfigRefer.FixedMapBuilding:Find(self._territoryConfig:VillageId())
    return villageConfig:Level()
end

function AllianceWarBuildingCellDataVillageWar:GetStatusName(nowTime)
    if self._warInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
        return I18N.GetWithParams("village_info_preparing", string.Empty)
    elseif self._warInfo.Status > wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
        return I18N.GetWithParams("village_info_time_to_end", string.Empty)
    end
    return string.Empty
end

function AllianceWarBuildingCellDataVillageWar:GetEndTime()
    return self._warInfo.EndTime
end

function AllianceWarBuildingCellDataVillageWar:GetProgressValueSting(nowTime)
    local leftTime
    if self._warInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
        leftTime = self._warInfo.StartTime - nowTime
    else
        leftTime = self._warInfo.EndTime - nowTime
    end
    leftTime = math.max(leftTime, 0)
    return TimeFormatter.SimpleFormatTimeWithDay(leftTime)
end

function AllianceWarBuildingCellDataVillageWar:GetProgress(nowTime)
    if self._warInfo.Status == wds.VillageAllianceWarStatus.VillageAllianceWarStatus_Declare then
        return math.inverseLerp(self._warInfo.DeclareTime, self._warInfo.StartTime, nowTime)
    end
    return math.inverseLerp(self._warInfo.StartTime, self._warInfo.EndTime, nowTime)
end

function AllianceWarBuildingCellDataVillageWar:ShowJoin()
    return true
end

function AllianceWarBuildingCellDataVillageWar:ShowQuit()
    return false
end

function AllianceWarBuildingCellDataVillageWar:OnClickJoin()
    g_Game.UIManager:CloseAllByName(UIMediatorNames.AllianceWarNewMediator)
    ---@type VillageFastForwardToSelectTroopDelegate
    local context = {}
    context.__name = "VillageFastForwardToSelectTroopDelegate"
    AllianceWarTabHelper.GoToCoord(self._posX, self._posY, true, nil, nil, context)
end

function AllianceWarBuildingCellDataVillageWar:OnClickEscrowTip()
    ---@type TextToastMediatorParameter
    local param = {}
    param.content = I18N.Get("village_tips_proxy")
    param.clickTransform = self._tipRect
    ModuleRefer.ToastModule:ShowTextToast(param)
end

function AllianceWarBuildingCellDataVillageWar:NeedEscrowInfoUpdated()
    return not self:IsTargetBehemothCage()
end

function AllianceWarBuildingCellDataVillageWar:EscrowInfoUpdated()
    self._showMyEscrowInfo = false
    self._myEscrowCount = 0
    self._escrowAttackCount = 0
    self._escrowDurabilityCount = 0

    if self:IsTargetBehemothCage() then
        return
    end

    self._escrowAttackCount = self._warInfo.AttackerLen
end

function AllianceWarBuildingCellDataVillageWar:SetUpExtraInfo(root, title, icon1, value1, icon2, value2)
    if self._escrowAttackCount <= 0 and self._escrowDurabilityCount <= 0 and not self._isAttack then
        root:SetVisible(false)
        return
    end
    root:SetVisible(true)
    if self._isAttack then
        icon1:SetVisible(true)
        value1:SetVisible(true)
        icon2:SetVisible(true)
        value2:SetVisible(true)
        title.text = I18N.GetWithParams("village_info_alliance_proxy")
        g_Game.SpriteManager:LoadSprite("sp_comp_icon_engineering", icon1)
        value1.text = tostring(self._escrowDurabilityCount)
        g_Game.SpriteManager:LoadSprite("sp_hud_icon_friends", icon2)
        value2.text = tostring(self._escrowAttackCount)
    else
        icon1:SetVisible(true)
        value1:SetVisible(true)
        icon2:SetVisible(false)
        value2:SetVisible(false)
        title.text = I18N.GetWithParams("village_info_Garrisoned")
        g_Game.SpriteManager:LoadSprite("sp_comp_icon_durability", icon1)
        value1.text = tostring(self._escrowDurabilityCount)
    end
end

function AllianceWarBuildingCellDataVillageWar:SetUpEscrowPart(root, icon, text, btn)
    root:SetVisible(self._showMyEscrowInfo)
    if Utils.IsNotNull(btn) then
        self._tipRect = btn:GetComponent(typeof(CS.UnityEngine.RectTransform))
    end
    if not self._showMyEscrowInfo then
        return
    end
    g_Game.SpriteManager:LoadSprite("sp_comp_icon_agency", icon)
    text.text = I18N.GetWithParams("village_info_my_proxy", tostring(self._myEscrowCount))
    
end

function AllianceWarBuildingCellDataVillageWar:IsTargetBehemothCage()
    if self._buildingConfig then
        return self._buildingConfig:SubType() == MapBuildingSubType.CageSubType1 or self._buildingConfig:SubType() == MapBuildingSubType.CageSubType2
    end
end

return AllianceWarBuildingCellDataVillageWar