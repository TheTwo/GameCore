local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local ConfigRefer = require("ConfigRefer")
local UIMediatorNames = require("UIMediatorNames")
local TimeFormatter = require("TimeFormatter")
local CommonConfirmPopupMediatorDefine = require("CommonConfirmPopupMediatorDefine")
local AllianceWarTabHelper = require("AllianceWarTabHelper")
local SlgUtils = require("SlgUtils")

local BaseTableViewProExpendData = require("BaseTableViewProExpendData")

---@class AllianceWarCellData:BaseTableViewProExpendData
---@field new fun(childData:AllianceWarPlayerCellData[]):AllianceWarCellData
---@field super BaseTableViewProExpendData
local AllianceWarCellData = class('AllianceWarCellData', BaseTableViewProExpendData)

---@param childData AllianceWarPlayerCellData[]
function AllianceWarCellData:ctor(childData)
    BaseTableViewProExpendData.ctor(self)
    self:RefreshChildCells(nil, childData)
    for i, v in pairs(childData) do
        v.owner = self
    end
    ---@type wds.AllianceBattleMemberInfo
    self._leftPlayerInfo = nil
    self._distance = nil
    self._selfInTeam = false
    self._selfIsCaptain = false
    self._memberCount = 0
    self._memberMax = 6
    self._teamPower = 0
    self._targetPower = 0
end

function AllianceWarCellData:GetIdAndType()
    return self._id, 1
end

function AllianceWarCellData:GetCompareValue()
    return 0
end

---@param serverData wds.AllianceTeamInfo
function AllianceWarCellData:Setup(id, serverData)
    self._selfInTeam = false
    self._id = id
    self._serverData = serverData
    self._distance = nil
    self._teamPower = 0
    self._targetPower = 0
    local allMembers = serverData.Members
    local myPlayerID = ModuleRefer.PlayerModule:GetPlayerId()
    for i, v in pairs(allMembers) do
        if v.PlayerId == serverData.CaptainId then
            self._leftPlayerInfo = v
        end
        if myPlayerID == v.PlayerId then
            self._selfInTeam = true
        end
        self._teamPower = self._teamPower + v.Power
    end
    if not self._leftPlayerInfo then
        g_Logger.Error("AllianceWarCellData:Setup(id:%s) CaptainId:%s not in Members", id, serverData.CaptainId)
    end
    self._memberCount = #allMembers
    self._memberMax = ConfigRefer.ConstMain:SlgTeamTrusteeshipTroopMaxCount()
    self._selfIsCaptain = serverData.CaptainId == myPlayerID
    local leftPos = self:GetLeftCoord()
    if leftPos then
        local castlePos = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
        self._distance = AllianceWarTabHelper.CalculateMapDistance(leftPos.x, leftPos.y, castlePos.X, castlePos.Y)
    end

    if serverData.TargetInfo then
        if serverData.TargetInfo.CfgId ~= 0 then
            local name, icon, power = SlgUtils.GetNameIconPowerByConfigId(serverData.TargetInfo.ObjectType, serverData.TargetInfo.CfgId)
            self._targetPower = power
            self._targetName = name
            self._targetIcon = icon
        else
            self._targetName = serverData.TargetInfo.Name
        end
    end
end

function AllianceWarCellData:ReGenerateChildCell(tableView)
    ---@type AllianceWarPlayerCellData[]
    local children = {}
    for _, member in pairs(self._serverData.Members) do
        ---@type AllianceWarPlayerCellData
        local playerCell = {}
        playerCell.memberInfo = member
        playerCell.owner = self
        table.insert(children, playerCell)
    end
    self:RefreshChildCells(tableView, children)
end

---@return wds.PlayerBasicInfo|wds.AllianceMember|wrpc.AllianceMemberInfo|wds.DamagePlayerInfo
function AllianceWarCellData:GetLeftPlayerInfo()
    if self._leftPlayerInfo then
        if self._leftPlayerInfo.FacebookId == ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID then
            return ModuleRefer.PlayerModule:GetPlayer().Basics
        end
        return ModuleRefer.AllianceModule:QueryMyAllianceMemberData(self._leftPlayerInfo.FacebookId)
    end
    return nil
end

---@return wds.PortraitInfo
function AllianceWarCellData:GetLeftPortraitInfo()
    if self._leftPlayerInfo then
        if self._leftPlayerInfo.FacebookId == ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID then
            return ModuleRefer.PlayerModule:GetPlayer().Basics.PortraitInfo
        end
        local info =  ModuleRefer.AllianceModule:QueryMyAllianceMemberData(self._leftPlayerInfo.FacebookId)
        return info and info.PortraitInfo
    end
    return nil
end

function AllianceWarCellData:GetRightPortraitInfo()
    return self._serverData.TargetInfo.PortraitInfo
end

---@return wds.PlayerBasicInfo|wds.AllianceMember|wrpc.AllianceMemberInfo|wds.DamagePlayerInfo|wds.AllianceTeamTargetBaseInfo
function AllianceWarCellData:GetRightPlayerInfo()
    return self._serverData.TargetInfo.CfgId == 0 and self._serverData.TargetInfo or nil
end

---@return string
function AllianceWarCellData:GetRightImage()
    return self._targetIcon
end

---@return number|nil
function AllianceWarCellData:GetLeftDistance()
    return self._distance
end

---@return string
function AllianceWarCellData:GetLeftName()
    if self._leftPlayerInfo then
        local selfData = ModuleRefer.PlayerModule:GetPlayer()
        if self._leftPlayerInfo.FacebookId == selfData.Owner.FacebookID then
            return selfData.Owner.PlayerName.String
        end
        local member = ModuleRefer.AllianceModule:QueryMyAllianceMemberData(self._leftPlayerInfo.FacebookId)
        if member then
            return member.Name
        end
    end
    return self._leftPlayerInfo and self._leftPlayerInfo.PlayerName or string.Empty
end

---@return string
function AllianceWarCellData:GetRightName()
    return self._targetName
end

---@return boolean
function AllianceWarCellData:IsLeftAttacker()
    return true
end

---@return {x:number,y:number}|nil
function AllianceWarCellData:GetLeftCoord()
    if self._leftPlayerInfo then
        if self._leftPlayerInfo.FacebookId == ModuleRefer.PlayerModule:GetPlayer().Owner.FacebookID then
            local castlePos = ModuleRefer.PlayerModule:GetCastle().MapBasics.Position
            return {x=math.floor(castlePos.X+0.5), y=math.floor(castlePos.Y+0.5)}
        end
        local playerInfo=  ModuleRefer.AllianceModule:QueryMyAllianceMemberData(self._leftPlayerInfo.FacebookId)
        if playerInfo then
            return {x=math.floor(playerInfo.BigWorldPosition.X+0.5), y=math.floor(playerInfo.BigWorldPosition.Y+0.5)}
        end
    end
    return nil
end

---@return {x:number,y:number}|nil
function AllianceWarCellData:GetRightCoord()
    return {x=math.floor(self._serverData.TargetInfo.Pos.X+0.5), y=math.floor(self._serverData.TargetInfo.Pos.Y+0.5)}
end

---@return string
function AllianceWarCellData:GetVsCenterText()
    if self._teamPower <= 0 or self._targetPower <= 0 then
        return ""
    end
    return ("%s vs %s"):format(self._teamPower, self._targetPower)
end

---@return number, number|nil
function AllianceWarCellData:GetProgress(nowTime)
    if nowTime < self._serverData.StartTime then
        return 3, math.inverseLerp(self._serverData.CreateTime, self._serverData.StartTime, nowTime)
    end
    if self:IsLeftAttacker() then
        return 1, nil
    else
        return 2, nil
    end
end

---@param nowTime number
---@return string
function AllianceWarCellData:GetStatusString(nowTime)
    if nowTime < self._serverData.StartTime then
        return I18N.Get("alliance_team_zhunbeizhong")
    elseif self._leftPlayerInfo.Battling then
        return I18N.Get("alliance_team_zhandouzhong")
    end
    return I18N.Get("alliance_team_xingjunzhong")
end

function AllianceWarCellData:Preparing(nowTime)
    if nowTime < self._serverData.StartTime then
        return true
    end
    return false
end

---@param nowTime number
---@return string
function AllianceWarCellData:GetTimeString(nowTime)
    if nowTime < self._serverData.StartTime then
        return TimeFormatter.SimpleFormatTime(self._serverData.StartTime - nowTime)
    end
    return string.Empty
end

---@return boolean
function AllianceWarCellData:ShowJoin(nowTime)
    return not self._selfInTeam and self._memberCount < self._memberMax and nowTime < self._serverData.StartTime and self:IsLeftAttacker()
end

---@return boolean
function AllianceWarCellData:ShowQuit(nowTime)
    return self._selfIsCaptain and nowTime < self._serverData.StartTime and self:IsLeftAttacker()
end

---@return boolean, string, string
function AllianceWarCellData:ShowJoined(nowTime)
    local upTitle = string.Empty
    if self._selfInTeam then
        upTitle = I18N.Get("alliance_team_yijiaru")
    end
    return self._selfInTeam or not self:Preparing(nowTime), upTitle, self:IsLeftAttacker() and ("(%d/%d)"):format(self._memberCount, self._memberMax) or string.Empty
end

---@return boolean
function AllianceWarCellData:UseTick()
    return true
end

---@param troopInfo TroopInfo
function AllianceWarCellData.GetPresetIndexAndTroopIdByPreset(troopInfo)
    if not troopInfo or not troopInfo.preset then
        return
    end
    local troopId = nil
    local idx = nil
    local p = ModuleRefer.PlayerModule:GetCastle().TroopPresets
    local presets = p.Presets or {}
    for i = 1, #presets do
        local pre = presets[i]
        if pre.ID == troopInfo.preset.ID then
            idx = i
            troopId = troopInfo.troopId
            break
        end
    end
    return idx,troopId
end

function AllianceWarCellData:OnClickJoin()
    local teamId = self._serverData.Id
    ---@type HUDSelectTroopListData
    local selectTroopData = {}
    selectTroopData.needPower = -1
    selectTroopData.recommendPower = -1
    selectTroopData.costPPP = 0
    selectTroopData.isAssemble = true
    selectTroopData.joinAssembleTeam = self._serverData.Id
    selectTroopData.overrideItemClickGoFunc = function(troopItemData)
        local idx, _ = self.GetPresetIndexAndTroopIdByPreset(troopItemData.troopInfo)
        if idx then
            ModuleRefer.SlgModule:JoinAllianceTeam(teamId, idx)
        end
    end
    require("HUDTroopUtils").StartMarch(selectTroopData)
end

function AllianceWarCellData:OnClickQuit()
    if self._selfIsCaptain then
        ---@type CommonConfirmPopupMediatorParameter
        local confirmParameter = {}
        confirmParameter.styleBitMask = CommonConfirmPopupMediatorDefine.Style.ConfirmAndCancel
        confirmParameter.content = I18N.Get("alliance_team_quxiao")
        confirmParameter.confirmLabel = I18N.Get("confirm")
        confirmParameter.cancelLabel = I18N.Get("cancle")
        confirmParameter.onConfirm = function()
            ModuleRefer.SlgModule:LeaveAllianceTeam(self._leftPlayerInfo.Troops[1].PresetQueue + 1)
            return true
        end
        g_Game.UIManager:Open(UIMediatorNames.CommonConfirmPopupMediator, confirmParameter)
    end
end

function AllianceWarCellData:OnClickPlayerPosition()
    local pos = self:GetLeftCoord()
    if not pos then
        return
    end
    AllianceWarTabHelper.GoToCoord(pos.x, pos.y)
    return true
end

function AllianceWarCellData:OnClickEnemyPosition()
    local pos = self:GetRightCoord()
    if not pos then
        return
    end
    AllianceWarTabHelper.GoToCoord(pos.x, pos.y)
    return true
end

return AllianceWarCellData