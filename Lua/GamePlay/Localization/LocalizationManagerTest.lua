local I18N = require("I18N")
local Logger = require("Logger")
local Delegate = require("Delegate")

local GameObject = CS.UnityEngine.GameObject
local GameObjectCreateHelper = CS.DragonReborn.AssetTool.GameObjectCreateHelper
local Input = CS.UnityEngine.Input

--for LanguageManager Test. Remove it when LanguageManager is ready.
local LocalizationManagerTest = class("LocalizationManagerTest")

function LocalizationManagerTest:Tick()
    if Input.GetMouseButtonDown(1) then
        self:Test();
    end

    if Input.GetKey(CS.UnityEngine.KeyCode.A) then
        self:ShowLangValidation()
    end
end

function LocalizationManagerTest:Test()
    local helper = GameObjectCreateHelper.Create();
    if GameObject.Find("TestUI") == nil then
        helper:Create("TestUI", Delegate.GetOrCreate(self, self.LoadUICallback));
    end
end

function LocalizationManagerTest:LoadUICallback(go)
    
    local uiRoot = GameObject("UIRootFake");
    go.transform:SetParent(uiRoot.transform);
    
    local text_1 = go.transform:Find("text_1"):GetComponent("Text");
    text_1.text = I18N.Get("BP_activity_title")

    local text_2 = go.transform:Find("text_2"):GetComponent("Text");
    text_2.text = I18N.Get("BP_buy_title")

    local text_3 = go.transform:Find("text_3"):GetComponent("Text");
    text_3.text = I18N.GetWithParams("load_event_37wan_start_date",  111, 222, 333);
end

function LocalizationManagerTest:ShowLangValidation()
    CS.LangValidation.LangValidationManager.DrawDebugView(Delegate.GetOrCreate(self, self.RestartGame()))

end

function LocalizationManagerTest:RestartGame()
    --XH TODO:restart logic
end

return LocalizationManagerTest