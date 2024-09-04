local BaseUIMediator = require ('BaseUIMediator')
local ModuleRefer = require('ModuleRefer')
local Delegate = require('Delegate')
local EventConst = require('EventConst')
local ConfigRefer = require('ConfigRefer')
local I18N = require('I18N')

---@class ShareChannelChooseParam
---@field type number
---@field configID number 	WorldExpeditionTemplateInstanceID
---@field x number
---@field y number
---@field z number
---@field payload any
---@field skillLevels table ---宠物用
---@field blockPrivateChannel boolean
---@field blockWorldChannel boolean
---@field blockAllianceChannel boolean

---@class ShareChannelChooseMediator : BaseUIMediator
local ShareChannelChooseMediator = class('ShareChannelChooseMediator', BaseUIMediator)

local SORTVALUE_WORLD = 99999999999902
local SORTVALUE_ALLIANCE = 99999999999901


function ShareChannelChooseMediator:OnCreate()
    self.compChildPopupBaseS = self:LuaObject('child_popup_base_s')
    self.channelTable = self:TableViewPro('p_table')
end

---@param param ShareChannelChooseParam
function ShareChannelChooseMediator:OnOpened(param)
    if not param then
        return
    end
	self.type = param.type
	self.configID = param.configID
	self.x = param.x
	self.y = param.y
	self.z = param.z
	self.skillLevels = param.skillLevels
	self.petGeneInfo = param.petGeneInfo
	self.payload = param.payload
	self.blockPrivateChannel = param.blockPrivateChannel
	self.blockWorldChannel = param.blockWorldChannel
	self.blockAllianceChannel = param.blockAllianceChannel
	
    local baseData = {}
    baseData.title = I18N.Get("chat_share_exploration")
    self.compChildPopupBaseS:FeedData(baseData)

    self:InitChannelTable()
end


function ShareChannelChooseMediator:OnClose(param)
    --TODO
end

function ShareChannelChooseMediator:InitChannelTable()
    self._channelDataList = {}

	-- 特殊频道
	local worldSession = ModuleRefer.ChatModule:GetWorldSession()
	local allianceSession = ModuleRefer.ChatModule:GetAllianceSession()
	local toastSession = ModuleRefer.ChatModule:GetSystemToastSession()

	if not self.blockPrivateChannel then
		-- 其他频道
		local sessionList = ModuleRefer.ChatModule:GetSessionList()
		for id, session in pairs(sessionList) do
			if ((not worldSession or id ~= worldSession.SessionId)
					and (not allianceSession or id ~= allianceSession.SessionId)
					and (not toastSession or id ~= toastSession.SessionId)
				) then
				---@type ShareChannelItemParam
				local data = {
					sessionID = session.SessionId,
					pinned = ModuleRefer.ChatModule:IsPinned(session.SessionId),
					sortValue = session.OperationTime,
					type = self.type,
					configID = self.configID,
					x = self.x,
					y = self.y,
					z = self.z,
					skillLevels = self.skillLevels,
					petGeneInfo = self.petGeneInfo,
					payload = self.payload,
					blockPrivateChannel = self.blockPrivateChannel,
					blockWorldChannel = self.blockWorldChannel,
					blockAllianceChannel = self.blockAllianceChannel,
				}
				table.insert(self._channelDataList, data)
			end
		end
	end

	if not self.blockWorldChannel then
		-- 世界频道
		if (worldSession) then
			---@type ShareChannelItemParam
			local data = {
				sessionID = worldSession.SessionId,
				pinned = true,
				sortValue = SORTVALUE_WORLD,
				type = self.type,
				configID = self.configID,
				x = self.x,
				y = self.y,
				z = self.z,
				skillLevels = self.skillLevels,
				petGeneInfo = self.petGeneInfo,
				payload = self.payload,
				blockPrivateChannel = self.blockPrivateChannel,
				blockWorldChannel = self.blockWorldChannel,
				blockAllianceChannel = self.blockAllianceChannel,
			}
			table.insert(self._channelDataList, 1, data)
		end
	end

	if not self.blockAllianceChannel then
		-- 联盟频道
		if (allianceSession) then
			---@type ShareChannelItemParam
			local data = {
				sessionID = allianceSession.SessionId,
				pinned = true,
				sortValue = SORTVALUE_ALLIANCE,
				type = self.type,
				configID = self.configID,
				x = self.x,
				y = self.y,
				z = self.z,
				skillLevels = self.skillLevels,
				petGeneInfo = self.petGeneInfo,
				payload = self.payload,
				blockPrivateChannel = self.blockPrivateChannel,
				blockWorldChannel = self.blockWorldChannel,
				blockAllianceChannel = self.blockAllianceChannel,
			}
			table.insert(self._channelDataList, 1, data)
		end
	end

	-- 排序
	table.sort(self._channelDataList, ModuleRefer.ChatModule.SortBySortValueDescWithPin)

    for _, data in ipairs(self._channelDataList) do
		---@type CS.FunPlusChat.Models.FPSession
		local sessionID = data.sessionID
		local session = ModuleRefer.ChatModule:GetSession(sessionID)
		if (session) then
			-- 忽略会话过滤
			local ignored = ModuleRefer.ChatModule:IsIgnoredSession(session)

			-- 额外联盟检查
			local allianceCheckPass = true
			if (ModuleRefer.ChatModule:IsAllianceSession(session)) then
				allianceCheckPass = ModuleRefer.AllianceModule:IsInAlliance()
			end

			if (not ignored and allianceCheckPass) then
				self.channelTable:AppendData(data)
			end
		end
	end
end

return ShareChannelChooseMediator