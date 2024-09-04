--- scene:scene_common_touch_circle_brief
local Delegate = require("Delegate")
local EventConst = require("EventConst")
local ModuleRefer = require("ModuleRefer")
local I18N = require("I18N")
local UIHelper = require("UIHelper")

local BaseUIMediator = require("BaseUIMediator")

---@class CityCircleMenuUISeTroopMediatorParameter
---@field sceneCamera CS.UnityEngine.Camera
---@field team CityExplorerTeam
---@field btnsData CircleMenuSimpleButtonData[]

---@class CityCircleMenuUISeTroopMediator:BaseUIMediator
---@field new fun():CityCircleMenuUISeTroopMediator
---@field super BaseUIMediator
local CityCircleMenuUISeTroopMediator = class('CityCircleMenuUISeTroopMediator', BaseUIMediator)

function CityCircleMenuUISeTroopMediator:OnCreate()
    
    self._selfTrans = self:Transform("")
    ---@type CS.UnityEngine.UI.GraphicRaycaster
    self._uiRayCaster = self._selfTrans.gameObject:GetComponent(typeof(CS.UnityEngine.UI.GraphicRaycaster))
    self._btnRootTrans = self:Transform("p_target")
    ---@type CircleMenuSimpleButtons
    self._child_circle_menu_simple_buttons = self:LuaObject("child_circle_menu_simple_buttons")
    ---@type CommonTimer
    self._p_trop_info_bottom = self:LuaObject("p_trop_info_bottom")
    if self._p_trop_info_bottom then
        self._p_trop_info_bottom:SetVisible(false)
    end
end

---@param param CityCircleMenuUISeTroopMediatorParameter
function CityCircleMenuUISeTroopMediator:OnOpened(param)
    self._sceneCamera = param.sceneCamera
    self._team = param.team
    self._child_circle_menu_simple_buttons:FeedData(param.btnsData)
end

function CityCircleMenuUISeTroopMediator:OnShow()
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

function CityCircleMenuUISeTroopMediator:OnHide()
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.Tick))
end

---@param screenPos CS.UnityEngine.Vector2
function CityCircleMenuUISeTroopMediator:IsScreenInMyElement(screenPos)
    return true
end

function CityCircleMenuUISeTroopMediator:Tick(dt)
    if not self._team then return end
    local teamPos = self._team:GetPosition()
    if not teamPos then return end
    local uiPos = UIHelper.WorldPos2UIPos(self._sceneCamera, teamPos, self._selfTrans)
    uiPos.z = 0
    self._btnRootTrans.localPosition = uiPos
end

return CityCircleMenuUISeTroopMediator