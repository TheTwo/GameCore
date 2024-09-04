local BaseModule = require('BaseModule')
local DBEntityType = require("DBEntityType")
local DBEntityPath = require("DBEntityPath")
local Delegate = require("Delegate")
local ConfigRefer = require("ConfigRefer")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIMediatorNames = require("UIMediatorNames")
local TimeFormatter = require("TimeFormatter")
local KingdomMapUtils = require("KingdomMapUtils")
local EventConst = require("EventConst")

---@class PlayerModule : BaseModule
---@field castleBrief wds.CastleBrief
local PlayerModule = class('PlayerModule', BaseModule)

function PlayerModule:ctor()
    self.playerId = 0
    self.accountId = ''
	self.totalExpTable = {}
	self.maxLevel = 0
	self.oldExp = 0
	self.oldLevel = 0
	self.portraitId = 0


end

function PlayerModule:OnRegister()
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Basics.CommanderExp.MsgPath, Delegate.GetOrCreate(self, self.OnExpChange))
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Basics.CommanderLevel.MsgPath, Delegate.GetOrCreate(self, self.OnLevelChange))
	g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.Basics.PortraitInfo.MsgPath, Delegate.GetOrCreate(self, self.OnPortraitChange))
    g_Game.DatabaseManager:AddChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPower.TotalPower.MsgPath, Delegate.GetOrCreate(self,self.OnPlayerPowerChanged))
end

function PlayerModule:OnRemove()
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Basics.CommanderExp.MsgPath, Delegate.GetOrCreate(self, self.OnExpChange))
	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Basics.CommanderLevel.MsgPath, Delegate.GetOrCreate(self, self.OnLevelChange))
	g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.Basics.PortraitInfo.MsgPath, Delegate.GetOrCreate(self, self.OnPortraitChange))
    g_Game.DatabaseManager:RemoveChanged(DBEntityPath.Player.PlayerWrapper2.PlayerPower.TotalPower.MsgPath, Delegate.GetOrCreate(self,self.OnPlayerPowerChanged))
end

function PlayerModule:InitExpTable()
	local expTempId = ConfigRefer.ConstMain:CommanderExpTemplateId()
	if (expTempId and expTempId > 0) then
		local expTemp = ConfigRefer.ExpTemplate:Find(expTempId)
		if (expTemp) then
			self.totalExpTable[1] = 0
			local totalExp = 0
			self.maxLevel = expTemp:MaxLv()
			for i = 1, self.maxLevel do
				totalExp = totalExp + expTemp:ExpLv(i)
				self.totalExpTable[i + 1] = totalExp
			end
		end
	end
end

function PlayerModule:InitData()
	local player = self:GetPlayer()
	self.oldExp = player.Basics.CommanderExp
	self.oldLevel = player.Basics.CommanderLevel
	self.portraitId = player.Basics.PortraitInfo.PlayerPortrait
    self.playerPower = self:GetPlayerPower()
    self:InitPlayerLoginPopupState()
end

--- 获取最大等级
---@param self PlayerModule
---@return number
function PlayerModule:GetMaxLevel()
	return self.maxLevel
end

--- 获取指定等级最小经验值
---@param self PlayerModule
---@param level number
---@return number
function PlayerModule:GetMinExpByLevel(level)
	return self.totalExpTable[level]
end

---@param id number
function PlayerModule:SetPlayerId(id)
    self.playerId = id
    self.player = nil
    self.castleBrief = nil
end

function PlayerModule:GetPlayerId()
    local player = self:GetPlayer()
    if player then
        g_Game.PlayerPrefsEx:SetLong('player_id', player.ID)
        return player.ID
    end

    local cachedPlayerId = g_Game.PlayerPrefsEx:GetLong('player_id', 0)
    if cachedPlayerId > 0 then
        return cachedPlayerId
    end

    return 0
end

---注意！！ 和服务端交互 用于表示联盟成员的id 使用其FacebookId， 问就是这玩意标识一个跨服身份 但是名字有误导
function PlayerModule:GetAllianceFacebookId()
    local player = self:GetPlayer()
    if player and player.Owner then
        return player.Owner.FacebookID
    end
    return 0
end

---@return wds.Player
function PlayerModule:GetPlayer()
    if self.player == nil then
        self.player = g_Game.DatabaseManager:GetEntity(self.playerId, DBEntityType.Player)
    end
    return self.player
end

function PlayerModule:GetPlayerUploadAvatarCount()
    local player = self:GetPlayer()
    if not player then
        return 0
    end
    return player.PlayerWrapper3.Appearance.UploadAvatarCnt
end

function PlayerModule:SetAccountId(accountId)
    self.accountId = accountId
end

function PlayerModule:GetAccountId()
    return self.accountId
end

---@return number 领主体力
function PlayerModule:GetLordST()
    ---todo
    return 999
end

---@param owner wds.Owner
function PlayerModule:IsFriendly(owner)
    if not owner then
        return false
    end
    return self:IsFriendlyById(owner.AllianceID, owner.PlayerID)
end

function PlayerModule:IsProtected(entity)
    if not entity then
        return false
    end
    local stateWrapper = entity.MapStates.StateWrapper
    local curTime = g_Game.ServerTime:GetServerTimestampInSeconds()
    if stateWrapper.ProtectionExpireTime > curTime then
        return true
    end
end

---@param player wds.Player
function PlayerModule:IsFriendlyById(allianceId, playerId)
    local player = self:GetPlayer()
    if not player then
        return false
    end
    if player.ID ~= nil and player.ID > 0 and player.ID == playerId then
        return true
    end
    if player.Owner.AllianceID == nil or player.Owner.AllianceID <= 0 then
        return false
    end
    return player.Owner.AllianceID == allianceId
end

function PlayerModule:IsHostile(owner)
    return not self:IsFriendly(owner)
end

function PlayerModule:IsHostileById(allianceId, playerId)
    return not self:IsFriendlyById(allianceId, playerId)
end

function PlayerModule:IsEmpty(owner)
    if not owner then
        return true
    end
    return owner.PlayerID == nil or owner.PlayerID <= 0
end

function PlayerModule:IsNeutral(allianceId)
    return allianceId == 0
end

---@param owner wds.Owner
function PlayerModule:IsMine(owner)
    if not owner then
        return false
    end
    return self:IsMineById(owner.PlayerID)
end

function PlayerModule:IsMineById(playerId)
    local player = self:GetPlayer()
    if player.ID == nil or player.ID <= 0 then
        return false
    end
    return player.ID == playerId
end

---TODO:正式读取
function PlayerModule:GetOwnerImage()
    return "sp_img_player"
end

---@param owner wds.Owner
function PlayerModule:GetOwnerNameWithColor(owner)
    local name = owner.PlayerName.String
    if name:IsNullOrEmpty() then
        name = "#empty"
    end

    return PlayerModule.ModifyNameColor(name, owner)
end

---@return wds.CastleBrief
function PlayerModule:GetCastle()
    if self.castleBrief == nil then
        local player = self:GetPlayer()
        local sceneInfo = player.SceneInfo
        local castleId = sceneInfo.CastleBriefId
        self.castleBrief = g_Game.DatabaseManager:GetEntity(castleId, DBEntityType.CastleBrief)
    end
    return self.castleBrief
end

function PlayerModule:GetBornDistrictId()
    local castleBrief = self:GetCastle()
    if castleBrief == nil then return 0 end
    local baseID = KingdomMapUtils.GetStaticMapData():GetBaseId()
    return castleBrief.BornInfo.DistrictId + baseID
end

function PlayerModule:StrongholdLevel()
    local castleBrief = self:GetCastle()
    local lv = castleBrief and castleBrief.BasicInfo.MainBuildingLevel or 1
    if lv <= 0 then
        lv = 1
    end
    return lv
end

function PlayerModule:MyFullName()
    local player = self:GetPlayer()
    local allianceBasicInfo = ModuleRefer.AllianceModule:GetMyAllianceBasicInfo()
    if allianceBasicInfo and player then
        return PlayerModule.FullName(allianceBasicInfo.Abbr, player.Basics.Name)
    end

    return player.Basics.Name
end

---@param owner wds.Owner
function PlayerModule.FullNameOwner(owner, myName)
    if not owner then
        return string.Empty
    end
    if ModuleRefer.PlayerModule:IsMine(owner) and myName then
        return  PlayerModule.FullName(owner.AllianceAbbr.String, I18N.Get("My_city"))
    end
    return PlayerModule.FullName(owner.AllianceAbbr.String, owner.PlayerName.String)
end

function PlayerModule.FullName(allianceAbbr, name)
    if string.IsNullOrEmpty(allianceAbbr) then
        return name
    end
    return string.format("[%s]%s", allianceAbbr, name)
end

function PlayerModule.ModifyNameColor(nameStr, owner)
    if ModuleRefer.PlayerModule:IsMine(owner) then
        return ("<color=green>%s</color>"):format(nameStr)
    elseif ModuleRefer.PlayerModule:IsFriendly(owner) then
        return ("<color=blue>%s</color>"):format(nameStr)
    else
        return ("<color=red>%s</color>"):format(nameStr)
    end
end

function PlayerModule:OnExpChange()
	local newExp = self:GetPlayer().Basics.CommanderExp
	local deltaExp = newExp - self.oldExp
	self.oldExp = newExp
	ModuleRefer.ToastModule:AddJumpToast(I18N.GetWithParams("playerinfo_addexp_toast", deltaExp))
end

function PlayerModule:OnLevelChange()
	--local newLevel = self:GetPlayer().Basics.CommanderLevel
	g_Game.UIManager:Open(UIMediatorNames.UIPlayerLevelUpMediator)
end

--- 根据ID获取头像
---@param self PlayerModule
---@param id number
---@return string
function PlayerModule:GetPortraitSpriteName(id)
	local cfg = ConfigRefer.PlayerIcon:Find(id)
	if (not cfg) then
		g_Logger.Error("未找到玩家头像! id: %s", id)
	else
		local uiCfg = ConfigRefer.ArtResourceUI:Find(cfg:Asset())
		if (not uiCfg) then
			g_Logger.Error("未找到玩家头像! id: %s, ArtResourceUI id: %s", id, cfg:Asset())
		else
			return uiCfg:Path()
		end
	end
	return "sp_icon_missing"
end

--- 根据ID获取头像框
---@param self PlayerModule
---@param id number
---@return string
function PlayerModule:GetPortraitFrameSpriteName(id)
	local cfg = ConfigRefer.Adornment:Find(id)
	if (not cfg) then
		g_Logger.Warn("未找到玩家头像框! id: %s", id)
	else
		return cfg:Icon()
	end
	return string.Empty
end

--- 获取自身头像
---@param self PlayerModule
---@return string
function PlayerModule:GetSelfPortraitSpriteName()
	return self:GetPortraitSpriteName(self.portraitId)
end

function PlayerModule:OnPortraitChange()
	self.portraitId = self:GetPlayer().Basics.PortraitInfo.PlayerPortrait
end

function PlayerModule:GetSelfPortraitId()
    local customAvatar = self:GetPlayer().Basics.PortraitInfo.CustomAvatar
    if not string.IsNullOrEmpty(customAvatar) then
        --正在使用自定义头像
        return 999
    end
	return self.portraitId
end

---@return wds.PortraitInfo
function PlayerModule:GetSelfPortaitInfo()
    local player = self:GetPlayer()
    if not player then return nil end

    return player.Basics.PortraitInfo
end

--- 本地玩家首次登录相关逻辑

---初始化本地玩家登录时间
---@param self PlayerModule
---@return void
function PlayerModule:InitPlayerLoginPopupState()
    local LASTEST_LOGIN_TIME = 'LASTEST_ENTER_CITY_TIME'
    local isFirstLogin = not g_Game.PlayerPrefsEx:HasUidKey(LASTEST_LOGIN_TIME)
    local thisTimeSec = g_Game.ServerTime:GetServerTimestampInSeconds()
    local lastTimeSec = 0
    if not isFirstLogin then
        lastTimeSec = g_Game.PlayerPrefsEx:GetFloatByUid(LASTEST_LOGIN_TIME)
        g_Game.PlayerPrefsEx:SetFloatByUid(LASTEST_LOGIN_TIME, thisTimeSec)
    else
        g_Game.PlayerPrefsEx:SetFloatByUid(LASTEST_LOGIN_TIME, 0)
    end
    local lastestLoginTimeDate = TimeFormatter.ToDateTime(lastTimeSec)
    local thisTimeDate = TimeFormatter.ToDateTime(thisTimeSec)
    local isTodayFirstLogin = not TimeFormatter.InSameDay(lastestLoginTimeDate, thisTimeDate)
    self.isFirstLogin = isFirstLogin
    self.isTodayFirstLogin = isTodayFirstLogin
    self.lastLoginTime = thisTimeSec
end

---获取本地玩家上次登录时间
---@param self PlayerModule
---@return number
function PlayerModule:GetLatestLoginTime()
    return self.lastLoginTime
end

---获取本地玩家是否是历史首次登录
---@param self PlayerModule
---@return boolean
function PlayerModule:IsFirstLoginInHistory()
    return self.isFirstLogin
end

---获取本地玩家是否是今日首次登录
---@param self PlayerModule
---@return boolean
function PlayerModule:IsFirstLoginInToday()
    return self.isTodayFirstLogin
end

---@return wds.CastleBuildingInfo
function PlayerModule:GetCastleBuildingInfoByType(typId)
    local castleBrief = self:GetCastle()
    if castleBrief == nil then return end

    local buildingInfo = castleBrief.Castle.BuildingInfos
    for id, info in pairs(buildingInfo) do
        if info.BuildingType == typId then
            return info
        end
    end
    return nil
end

---@return wds.CastleBuildingInfo
function PlayerModule:GetCastleBuildingInfoByTypeAndLevel(typId, level)
    local castleBrief = self:GetCastle()
    if castleBrief == nil then return end
    level = level or 1
    local buildingInfo = castleBrief.Castle.BuildingInfos
    for id, info in pairs(buildingInfo) do
        if info.BuildingType == typId and info.Level >= level then
            return info
        end
    end
    return nil
end

---@return wds.CastleFurniture
function PlayerModule:GetCastleFurnitureByType(typId)
    local castleBrief = self:GetCastle()
    if castleBrief == nil then return end

    local furnitures = castleBrief.Castle.CastleFurniture
    for id, info in pairs(furnitures) do
        local lvCell = ConfigRefer.CityFurnitureLevel:Find(info.ConfigId)
        if lvCell and lvCell:Type() == typId then
            return info
        end
    end
    return nil
end

---@return wds.CastleFurniture
function PlayerModule:GetCastleFurnitureByCfg(cfgId)
    local castleBrief = self:GetCastle()
    if castleBrief == nil then return end

    local furnitures = castleBrief.Castle.CastleFurniture
    for id, info in pairs(furnitures) do
        if info.ConfigId == cfgId then
            return info
        end
    end
    return nil
end

---@return number
function PlayerModule:GetPlayerPower()
    local player = self:GetPlayer()
    return player.PlayerWrapper2.PlayerPower.TotalPower
end

function PlayerModule:OnPlayerPowerChanged()
    local curPower = self:GetPlayerPower()
    if self.playerPower then
        if curPower > self.playerPower then
            self.powerUp = true
        elseif curPower < self.playerPower then
            g_Game.EventManager:TriggerEvent(EventConst.HUD_PLAY_POWER_EFFECT)
            self.powerDown = true
        end
    end
    self.playerPower = curPower
end

---@param lockable CS.UnityEngine.Transform|CS.UnityEngine.Transform[]
---@param callback fun(cmd:BaseParameter, isSuccess:boolean, rsp:any)
function PlayerModule:UploadCustomAvatar(lockable, errCode, callback)
    local sendCmd = require("UploadCustomAvatarParameter").new()
    sendCmd.args.UploadAvatarCnt = self:GetPlayerUploadAvatarCount() + 1
    sendCmd:SendOnceCallback(lockable, nil, nil, callback)
end

function PlayerModule:CheckServerUploadCD(callback)
    local sendCmd = require("CheckUploadAvatarCDParameter").new()
    sendCmd:SendOnceCallback(nil, nil, nil, callback)
end

function PlayerModule:GetRewardBoxes()
    local player = self:GetPlayer()
    return player.PlayerWrapper3.PlayerRewardBox.Infos
end

function PlayerModule:GetLandLayer()
    local player = self:GetPlayer()
    local landCfgId = player.PlayerWrapper3.Landform.CurLandform
    local landCfg = ConfigRefer.Land:Find(landCfgId)
    return landCfg
end

function PlayerModule:ShowPlayerInfoPanel(playerId, anchorObj, isManager)
    local selfId = ModuleRefer.PlayerModule:GetPlayer().ID
    if playerId == selfId then
        return
    end

    local msg = require("GetPlayerBriefInfoParameter").new()
    msg.args.PlayerIds:Add(playerId)
    msg:SendWithFullScreenLockAndOnceCallback(nil, nil, function(cmd, suc, resp)
        if (suc) then
            local playerInfo = resp.PlayerInfos[1]
            if not playerInfo then
                g_Logger.Error("无法找到此玩家，可能是机器人或者已被清库")
                return
            end
            playerInfo.anchorObj = anchorObj
            playerInfo.isManager = isManager
            g_Game.UIManager:Open(UIMediatorNames.CommonPlayerInfoPopupMediator,playerInfo)
        else
            return
        end
    end)
end

function PlayerModule:GetCurPPP()
    local player = self:GetPlayer()
    local curPPP = player and player.PlayerWrapper2.Radar.PPPCur or 0
    return curPPP
end

return PlayerModule
