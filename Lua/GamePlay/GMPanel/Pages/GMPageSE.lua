local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local GotoUtils = require('GotoUtils')
local ConfigRefer = require("ConfigRefer")
local SceneType = require("SceneType")
local CityConst = require("CityConst")
local RuntimeDebugSettings = require("RuntimeDebugSettings")
local RuntimeDebugSettingsKeyDefine = require("RuntimeDebugSettingsKeyDefine")

---@class GMPageSE:GMPage
local GMPageSE = class('GMPageSE', GMPage)

function GMPageSE:ctor()
    self.tid = "99999"
    self.npcCfgId = ""
    self._webReq = nil
	self._scrollPos = CS.UnityEngine.Vector2.zero
	self._coordX = 0
	self._coordY = 0
	self._dirX = 0
	self._dirY = 0
	self._presetIndex = 0
end

function GMPageSE:OnGUI()
    GUILayout.BeginVertical()
    
		GUILayout.BeginHorizontal()
			GUILayout.Label("MapInstance ID:", GUILayout.shrinkWidth)
			self.tid = GUILayout.TextField(self.tid)
			if GUILayout.Button("进入关卡") then
				self.panel:PanelShow(false)
				GotoUtils.GotoSceneSeGM(tonumber(self.tid), 0)
			end
		GUILayout.EndHorizontal()
		
		if (GUILayout.Button("直接过关")) then
			self.panel:SendGMCmd("finishlevel", 0)
			self.panel:PanelShow(false)
		end
		local myCity = require("ModuleRefer").CityModule.myCity
		if myCity and (GUILayout.Button("City 测试战斗模式")) then
			local cap = myCity.citySeManger._seEnvironment._unitManager:GetCaptain()
			if cap then
				local pos = cap:GetEntity().MapBasics.Position
				local st = myCity.stateMachine
				st:WriteBlackboard("presetIndex", cap:GetEntity().BasicInfo.PresetIndex)
				st:WriteBlackboard("x", pos.X)
				st:WriteBlackboard("y", pos.Y)
				st:ChangeState(CityConst.STATE_CITY_SE_BATTLE_FOCUS)
			end
		end

		if myCity and myCity.citySeManger and myCity.citySeManger._seEnvironment then
			GUILayout.BeginHorizontal()
			GUILayout.Label("摇杆移动模式")
			if GUILayout.Button("SE代理无队形变速") then
				local teamManager = myCity.citySeManger._seEnvironment:GetTeamManager()
				for _, mainTeam in pairs(teamManager._mainPlayerTeam) do
					local SETeamUnitSEController = require("SETeamUnitSEController")
					mainTeam._formation._controlMode = 1
					mainTeam._formation._moveController = SETeamUnitSEController.new(mainTeam._formation)
					mainTeam._formation._moveController._moveMode = 1
				end
			end
			if GUILayout.Button("SE代理有队形") then
				local teamManager = myCity.citySeManger._seEnvironment:GetTeamManager()
				for _, mainTeam in pairs(teamManager._mainPlayerTeam) do
					local SETeamUnitSEController = require("SETeamUnitSEController")
					mainTeam._formation._controlMode = 1
					mainTeam._formation._moveController = SETeamUnitSEController.new(mainTeam._formation)
					mainTeam._formation._moveController._moveMode = 2
				end
			end
			if GUILayout.Button("ORCA代理无阵型") then
				local teamManager = myCity.citySeManger._seEnvironment:GetTeamManager()
				for _, mainTeam in pairs(teamManager._mainPlayerTeam) do
					local SETeamUnitCustomController = require("SETeamUnitCustomController")
					mainTeam._formation._controlMode = 2
					mainTeam._formation._moveController = SETeamUnitCustomController.new(mainTeam._formation)
					mainTeam._formation._moveController._moveMode = 1
				end
			end
			if GUILayout.Button("Circle代理") then
				local teamManager = myCity.citySeManger._seEnvironment:GetTeamManager()
				for _, mainTeam in pairs(teamManager._mainPlayerTeam) do
					mainTeam._formation._controlMode = 3
					local SETeamUnitCircleController = require("SETeamUnitCircleController")
					mainTeam._formation._moveController = SETeamUnitCircleController.new(mainTeam._formation)
				end
			end
			GUILayout.EndHorizontal()

			local teamManager = myCity.citySeManger._seEnvironment:GetTeamManager()
			local mainTeam = teamManager:GetOperatingTeam()
			if mainTeam and mainTeam._formation._controlMode == 3 then
				GUILayout.BeginHorizontal()
				local speed = mainTeam._formation._moveController._rotSpeed
				GUILayout.Label(("阵型角速度:%.2f"):format(speed))
				local newSpeed = GUILayout.HorizontalSlider(speed, 90, 360)
				if speed ~= newSpeed then
					mainTeam._formation._moveController._rotSpeed = newSpeed
				end

				speed = mainTeam._formation._moveController._unitRotSpeed
				GUILayout.Label(("单位角速度:%.2f"):format(speed))
				newSpeed = GUILayout.HorizontalSlider(speed, 90, 720)
				if speed ~= newSpeed then
					mainTeam._formation._moveController._unitRotSpeed = newSpeed
				end

				speed = mainTeam._formation._moveController._unitMoveSpeedMulti
				GUILayout.Label(("单位移速倍率:%.2f"):format(speed))
				newSpeed = GUILayout.HorizontalSlider(speed, 1.1, 3)
				if speed ~= newSpeed then
					mainTeam._formation._moveController._unitMoveSpeedMulti = newSpeed
				end
				GUILayout.EndHorizontal()
			end

			if mainTeam and mainTeam._formation.newFormation then
				local heroMap = mainTeam:GetHeroMembers()
				GUILayout.BeginHorizontal()
				GUILayout.Label("当前队长")
				local curCaptainId = mainTeam._formation:GetCaptainId()
				for _, seUnit in pairs(heroMap) do
					local oldState = seUnit._id == curCaptainId
					if GUILayout.Toggle(oldState, seUnit:GetDebugName()) and not oldState then
						mainTeam._formation:DebugForceSetCaptain(seUnit._id)
					end
				end
				GUILayout.EndHorizontal()
			end
		end

		if myCity then
			local st = myCity.stateMachine
			if st:GetCurrentStateName() == CityConst.STATE_NORMAL then
				GUILayout.BeginHorizontal()
				GUILayout.Label("x:")
				self._coordX = tonumber(GUILayout.TextField(tostring(self._coordX))) or 0
				GUILayout.Label("y:")
				self._coordY = tonumber(GUILayout.TextField(tostring(self._coordY))) or 0
				GUILayout.Label("DirX:")
				self._dirX = tonumber(GUILayout.TextField(tostring(self._dirX))) or 0
				GUILayout.Label("DirY:")
				self._dirY = tonumber(GUILayout.TextField(tostring(self._dirY))) or 0
				GUILayout.Label("preset:")
				self._presetIndex = tonumber(GUILayout.TextField(tostring(self._presetIndex))) or 0
				GUILayout.EndHorizontal()
				if GUILayout.Button("City 测试聚焦探索模式") then
					myCity.cityExplorerManager:CreateHomeSeTroop(self._presetIndex, self._coordX, self._coordY, nil, nil, nil, self._dirX, self._dirY)
				end
			end
		end
		local has,value = RuntimeDebugSettings:GetInt(RuntimeDebugSettingsKeyDefine.DebugAllownClickGroundCitySeMode)
		if not has then
			value = 0
		end
		local allownClickGround = GUILayout.Toggle(value == 1, "内城探索模式允许点地面" )
		local v = allownClickGround and 1 or 0
		if (has and value ~= v) or (not has and v == 1) then
			RuntimeDebugSettings:SetInt(RuntimeDebugSettingsKeyDefine.DebugAllownClickGroundCitySeMode, v)
		end
		local h = GUILayout.Toggle(self:get_showEntityId(), "是否显示单位EntityId")
		if h ~= self:get_showEntityId() then
			self:set_showEntityId(h)
		end
		
		GUILayout.Label('快捷进入关卡')
	
	GUILayout.EndVertical()
	
	local setidlist = {}
	local senamelist = {}
	
	if (ConfigRefer.ConstSe.SeGMPanelIDListLength) then
		for i = 1, ConfigRefer.ConstSe:SeGMPanelIDListLength() do
			local cell = ConfigRefer.MapInstance:Find(ConfigRefer.ConstSe:SeGMPanelIDList(i))
			if (cell and cell:InstanceType() == SceneType.SeInstance) then
				table.insert(setidlist, cell:Id())
				table.insert(senamelist, cell:Note())
			end
		end
	end

	self._scrollPos = GUILayout.BeginScrollView(self._scrollPos)

		for i = 1, #setidlist do
			if GUILayout.Button(tostring(setidlist[i]) .. ": " .. senamelist[i]) then
				self.panel:PanelShow(false)
				GotoUtils.GotoSceneSeGM(setidlist[i], 0)
			end
		end

	GUILayout.EndScrollView()
end

function GMPageSE:get_showEntityId()
	return g_Game.PlayerPrefsEx:GetInt("GM_SE_ShowEntityId") == 1
end

function GMPageSE:set_showEntityId(value)
    g_Game.PlayerPrefsEx:SetInt("GM_SE_ShowEntityId", value and 1 or 0)
end

return GMPageSE
