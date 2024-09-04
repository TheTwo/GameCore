local GotoUtils = require("GotoUtils")
local ModuleRefer = require("ModuleRefer")
---@type CS.UnityEngine.Object
local Object = CS.UnityEngine.Object
local KingdomScene = require("KingdomScene")

local Delegate = require("Delegate")

local BaseUIMediator = require("BaseUIMediator")

---@class KingdomTestHud:BaseUIMediator
---@field new fun():KingdomTestHud
---@field super BaseUIMediator
local KingdomTestHud = class('KingdomTestHud', BaseUIMediator)

function KingdomTestHud:ctor()
    BaseUIMediator.ctor(self)
    self.tid = "10002"
end

 function KingdomTestHud:OnCreate(param)
     self._btn_template = self:Button("p_btn_op_template")
     self._p_bntParent = self._btn_template.transform.parent
     self._p_bntParent.gameObject:SetActive(false)
     self._btn_template.gameObject:SetActive(false)
     ---@type CS.UnityEngine.GameObject
     self._createdBtns = {}
     self:CreateButton("聚焦主城", Delegate.GetOrCreate(self, self.GoToMyCity))
     self:CreateButton("建造模式", Delegate.GetOrCreate(self, self.TestOpenBuildList))
     self:CreateButton("SE场景\n".. self.tid, Delegate.GetOrCreate(self, self.JumpToSeScene))
     self._p_bntParent.gameObject:SetActive(true)
 end

function KingdomTestHud:OnClose(data)
    BaseUIMediator.OnClose(self)
    for _, v in pairs(self._createdBtns) do
        Object.Destroy(v)
    end
    table.clear(self._createdBtns)
end

function KingdomTestHud:GoToMyCity()
    local scene = g_Game.SceneManager.current
    if scene and scene:is(KingdomScene) and scene.basicCamera then
        local city = ModuleRefer.CityModule.myCity
        scene.basicCamera:LookAt(city:GetCenter(), 0);
    end
end

function KingdomTestHud:TestOpenBuildList()
    local scene = g_Game.SceneManager.current
    if scene and scene:is(KingdomScene) and scene.basicCamera then
        local city = ModuleRefer.CityModule.myCity
        scene.basicCamera:LookAt(city:GetCenter(), 0.5, function()
            city:TryEnterEditMode();
        end);
    end
end

function KingdomTestHud:JumpToSeScene()
GotoUtils.GotoSceneSe(self.tid, function() end, {101, 102, 103})
end

function KingdomTestHud:CreateButton(btnTxt, btnFunc)
    ---@type CS.UnityEngine.GameObject
    local btnGo = Object.Instantiate(self._btn_template.gameObject, self._p_bntParent)
    ---@type CS.UnityEngine.UI.Button
    local btn = btnGo:GetComponent(typeof(CS.UnityEngine.UI.Button))
    ---@type CS.UnityEngine.UI.Text
    local txt = btnGo:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text), true)
    txt.text = btnTxt
    self:ButtonImp(btn, btnFunc)
    table.insert(self._createdBtns, btnGo)
    btnGo:SetActive(true)
end

return KingdomTestHud