local KingdomSceneState = require("KingdomSceneState")
local UIMediatorNames = require("UIMediatorNames")

---@class KingdomSceneStateEntry:KingdomSceneState
---@field new fun():KingdomSceneStateEntry
local KingdomSceneStateEntry = class("KingdomSceneStateEntry", KingdomSceneState)
KingdomSceneStateEntry.Name = "KingdomSceneStateEntry"
local ModuleRefer = require("ModuleRefer")
local KingdomSceneStateEntryToCity = require("KingdomSceneStateEntryToCity")
local KingdomSceneStateEntryToMap = require("KingdomSceneStateEntryToMap")

function KingdomSceneStateEntry:Enter()
    KingdomSceneState.Enter(self)

	local entryToMap = g_Game.StateMachine:ReadBlackboard("KINGDOM_GO_TO_WORLD", true)
    if entryToMap then
        self:EnterMap()
    else
        self:EnterCity()
    end

	-- SE失败后自动弹出RPP
	if (g_Game.StateMachine:ReadBlackboard("SE_DEFEATED")) then
		g_Game.StateMachine:WriteBlackboard("SE_FROM_CLIMB_TOWER", 0, true)
        local UIAsyncDataProvider = require("UIAsyncDataProvider")
        local provider = UIAsyncDataProvider.new()
        local name = UIMediatorNames.UIStrengthenMediator
        local check = UIAsyncDataProvider.CheckTypes.CheckAll
        provider:Init(name, nil, check)
        provider:SetOtherMediatorCheckType(0)
        provider:AddOtherMediatorBlackList(UIMediatorNames.LoadingPageMediator)
        provider:AddOtherMediatorBlackList(UIMediatorNames.HuntingMainMediator)
		-- g_Game.UIAsyncManager:AddAsyncMediator(provider) -- 095:不再弹出
	else
		-- 退出爬塔本自动进入爬塔界面
		local fromClimbTowerSectionId = g_Game.StateMachine:ReadBlackboard("SE_FROM_CLIMB_TOWER")
		if (fromClimbTowerSectionId and fromClimbTowerSectionId > 0) then
			g_Game.UIManager:Open(UIMediatorNames.SEClimbTowerMainMediator, {
				chapterId = fromClimbTowerSectionId,
			})
		end
	end

end

function KingdomSceneStateEntry:Exit()
    KingdomSceneState.Exit(self)
end

function KingdomSceneStateEntry:EnterCity()
    self.stateMachine:WriteBlackboard("City", ModuleRefer.CityModule.myCity)
    local useDefaultPos = g_Game.StateMachine:ReadBlackboard("se_use_default_pos")
    if not useDefaultPos then
        self.stateMachine:WriteBlackboard("City_ManualCoord", g_Game.StateMachine:ReadBlackboard("se_exit_pos"))
    end
    self.stateMachine:ChangeState(KingdomSceneStateEntryToCity.Name)
end

function KingdomSceneStateEntry:EnterMap()
    self.stateMachine:ChangeState(KingdomSceneStateEntryToMap.Name)
end

return KingdomSceneStateEntry
