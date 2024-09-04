local GMPage = require("GMPage")
local GUILayout = require("GUILayout")

local Delegate = require("Delegate")
local LocalizationManagerTest = require("LocalizationManagerTest")

local LangValidationManager = CS.LangValidation.LangValidationManager
local EditorUtility = CS.UnityEditor.EditorUtility;
local Application = CS.UnityEngine.Application;
local Vector2 = CS.UnityEngine.Vector2

---@class GMPageLocalization:GMPage
local GMPageLocalization = class('GMPageLocalization', GMPage)

function GMPageLocalization:OnShow()
    self._scrollPosition = Vector2.zero
end

function GMPageLocalization:OnGUI()
    
    --GUILayout.BeginHorizontal();
    --if GUILayout.Button("Load TestUI") then
    --    self.test:Test();
    --end
    --if GUILayout.Button("Open Persistent Folder") then
    --    EditorUtility.RevealInFinder(Application.persistentDataPath);
    --end
    --GUILayout.EndHorizontal();
    --
    --LangValidationManager.DrawDebugView(Delegate.GetOrCreate(self, self.OnRestart));

    self._scrollPosition = GUILayout.BeginScrollView(self._scrollPosition)
    GUILayout.BeginVertical()
    local keyMode = g_Game.LocalizationManager:GetDebugKeyMode()
    local buttonText = keyMode and "Disable" or "Enable"
    local needRestart = false
    if GUILayout.Button(buttonText .. " Key Mode") then
        g_Game.LocalizationManager:SetDebugKeyMode(not keyMode)
        needRestart = true
    end
    GUILayout.EndVertical()
    GUILayout.EndScrollView()

    if needRestart then
        g_Game:RestartGame()
    end
end

function GMPageLocalization:OnRestart()
    
end

return GMPageLocalization