local GUILayout = require("GUILayout")
local GMPage = require("GMPage")
local UIMediatorNames = require("UIMediatorNames")
local ModuleRefer = require('ModuleRefer')

---@class GMPageSEClimbTower:GMPage
local GMPageSEClimbTower = class('GMPageSEClimbTower', GMPage)

function GMPageSEClimbTower:ctor()
	self.tid = "810201"
	self.sectionId = "100101"
end

function GMPageSEClimbTower:OnGUI()
    GUILayout.BeginVertical()
		GUILayout.BeginHorizontal()
			if GUILayout.Button("爬塔主界面") then
				self.panel:PanelShow(false)
				g_Game.UIManager:Open(UIMediatorNames.SEClimbTowerMainMediator)
			end
			if GUILayout.Button("爬塔编队界面") then
				self.panel:PanelShow(false)
				g_Game.UIManager:Open(UIMediatorNames.SEClimbTowerTroopMediator)
			end
		GUILayout.EndHorizontal()
		GUILayout.BeginHorizontal()
			GUILayout.Label("tid:", GUILayout.shrinkWidth)
			self.tid = GUILayout.TextField(self.tid)
			GUILayout.Label("sectionId:", GUILayout.shrinkWidth)
			self.sectionId = GUILayout.TextField(self.sectionId)
			if (GUILayout.Button("进入")) then
				self.panel:PanelShow(false)
				ModuleRefer.EnterSceneModule:EnterSeClimbTowerScene(tonumber(self.tid), nil, tonumber(self.sectionId))
			end
		GUILayout.EndHorizontal()
	GUILayout.EndVertical()
end

return GMPageSEClimbTower
