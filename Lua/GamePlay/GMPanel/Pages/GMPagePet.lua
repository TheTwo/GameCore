local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local ModuleRefer = require("ModuleRefer")
local ConfigRefer = require("ConfigRefer")
local TimeFormatter = require("TimeFormatter")
local UIMediatorNames = require("UIMediatorNames")
local PetStatusDebug = {
    [wds.CastlePetStatus.CastlePetStatusNone] = "无状态",
    [wds.CastlePetStatus.CastlePetStatusBath] = "洗澡中",
    [wds.CastlePetStatus.CastlePetStatusEating] = "吃饭中",
    [wds.CastlePetStatus.CastlePetStatusExhausted] = "昏厥",
    [wds.CastlePetStatus.CastlePetStatusMoving] = "移动中",
    [wds.CastlePetStatus.CastlePetStatusSleeping] = "睡觉中",
    [wds.CastlePetStatus.CastlePetStatusWalking] = "闲逛中",
    [wds.CastlePetStatus.CastlePetStatusWorking] = "工作中",
    [wds.CastlePetStatus.CastlePetStatusCarrying] = "搬运中",
    [wds.CastlePetStatus.CastlePetStatusBuilding] = "建造大师",
}

---@class GMPagePet:GMPage
local GMPagePet = class('GMPagePet', GMPage)

function GMPagePet:ctor()
	self._petCompId = '111'
	self._petWildId = '1'
end

function GMPagePet:OnShow()
	local ModuleRefer = require("ModuleRefer")
    self.city = ModuleRefer.CityModule.myCity
    self._scrollPosition = CS.UnityEngine.Vector2.zero
end

function GMPagePet:OnGUI()
    GUILayout.BeginVertical()
    
    GUILayout.BeginHorizontal()
    if GUILayout.Button("打开主界面") then
		g_Game.UIManager:Open(UIMediatorNames.UIPetMediator)
		self.panel:PanelShow(false)
	end
    GUILayout.EndHorizontal()

	GUILayout.BeginHorizontal()
	GUILayout.Label("PetCompId:")
	self._petCompId = GUILayout.TextField(self._petCompId)
	GUILayout.Label("PetWildId:")
	self._petWildId = GUILayout.TextField(self._petWildId)
	GUILayout.Label("TroopId:")
	self._troopId = GUILayout.TextField(self._troopId)
	if (GUILayout.Button("捕捉宠物")) then
		local param = {
			petCompId = tonumber(self._petCompId),
			petWildId = tonumber(self._petWildId),
			troopId = tonumber(self._troopId),
		}
		self.panel:PanelShow(false)
		g_Game.UIManager:Open(UIMediatorNames.SEHudPreviewMediator, param)
	end
	GUILayout.EndHorizontal()

    GUILayout.EndVertical()
	self:OnGUI_CityPet()
end

function GMPagePet:OnGUI_CityPet()
    if not self.city then return end
    if not self.city.petManager:IsDataReady() then return end

    self._scrollPosition = GUILayout.BeginScrollView(self._scrollPosition)
    GUILayout.Label("========================数据层========================")
    for _, pet in pairs(self.city.petManager.cityPetData) do
        GUILayout.BeginHorizontal()
        GUILayout.Label(("PetId:%d"):format(pet.id))
        GUILayout.Label(("CfgId:%d"):format(pet.petCfg:Id()))
        GUILayout.Label(("状态:%s"):format(PetStatusDebug[pet.status] or ("未知状态%d"):format(pet.status)))
        GUILayout.Label(("开始时间:%s"):format(TimeFormatter.SimpleFormatTime(pet.actionStartTime % 86400 + 8 * 3600)))
        GUILayout.Label(("结束时间:%s"):format(TimeFormatter.SimpleFormatTime(pet.nextFreeTime % 86400 + 8 * 3600)))
        GUILayout.EndHorizontal()
    end

    GUILayout.Label("========================视图层========================")
    for id, unit in pairs(self.city.petManager.unitMap) do
        GUILayout.BeginHorizontal()
        GUILayout.Label(("Pet-UnitId:%d"):format(id))
        GUILayout.Label(("服务器状态:%s"):format(PetStatusDebug[unit.petData.status] or ("未知状态%d"):format(unit.petData.status)))
        GUILayout.EndHorizontal()

        GUILayout.BeginHorizontal()
        GUILayout.Label("当前状态机:" .. tostring(unit.stateMachine.currentName))
        GUILayout.Label("当前子状态机:" .. tostring(unit.subStateMachine.currentName))
        if GUILayout.Button("强制同步服务器状态") then
            unit:SyncFromServer()
        end
        if GUILayout.Button("Test吃") then
            self.city.petManager:GMTestEat(id)
        end
        if GUILayout.Button("Look") then
            local camera = self.city.camera
            if camera then
                camera:LookAt(unit._moveAgent._currentPosition)
            end
        end
        GUILayout.EndHorizontal()

        GUILayout.BeginHorizontal()
        GUILayout.Label(("当前位置:%s"):format(unit._moveAgent._currentPosition))
        GUILayout.Label(("目标位置:%s"):format(unit.targetPos))
        GUILayout.EndHorizontal()
        
        if unit.subStateMachine.currentName == "CityUnitPetSubStateMoving" then
            GUILayout.Label("正在向目标点移动")
        else
            GUILayout.Label("播放动画中")
        end
        GUILayout.Label("===================================================")
    end

    GUILayout.EndScrollView()
end

return GMPagePet
