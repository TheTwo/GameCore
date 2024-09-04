---Scene Name : scene_common_touch_circle_brief
local BaseUIMediator = require ('BaseUIMediator')
local Delegate = require('Delegate')
local Utils = require("Utils")
local TimeFormatter = require("TimeFormatter")
local TipsRectTransformUtils = require("TipsRectTransformUtils")
local LuaReusedComponentPool = require("LuaReusedComponentPool")

---@class CityCircleMenuUIMediator:BaseUIMediator
---@field _child_circle_menu_simple_buttons CircleMenuSimpleButtons
---@field _child_circle_menu_city_info CityCircleMenuTitle
local CityCircleMenuUIMediator = class('CityCircleMenuUIMediator', BaseUIMediator)
local EventConst = require("EventConst")

---@class CityCircleMenuUIParameter
---@field new fun(camera:BasicCamera, worldPos:CS.UnityEngine.Vector3, name:string, btns:CircleMenuSimpleButtonData[])
---@field camera BasicCamera
---@field worldPos CS.UnityEngine.Vector3
---@field name string
---@field btns CircleMenuSimpleButtonData[]
---@field autoClose boolean
---@field timestamp number
local CityCircleMenuUIParameter = sealedClass("CityCircleMenuUIParameter")
function CityCircleMenuUIParameter:ctor(camera, worldPos, name, btns, autoClose, timestamp, petInfos)
    self.camera = camera
    self.worldPos = worldPos
    self.name = name
    self.btns = btns
    self.autoClose = autoClose
    self.timestamp = timestamp
    self.petInfos = petInfos
end

function CityCircleMenuUIParameter:SetLevel(level)
    self.level = level
    return self
end

---@param petInfos CommonPetIconBaseData[]
function CityCircleMenuUIParameter:SetPetInfo(petInfos)
    self.petInfos = petInfos
    return self
end

CityCircleMenuUIMediator.UIParameter = CityCircleMenuUIParameter

---@class CityCircleMenuCloseUIParameter
---@field skipEvent boolean 是否跳过发送通知关闭事件(会导致CityStateMovingBuilding和CityStateMovingFurniture状态退回Normla)
local CityCircleMenuCloseUIParameter = sealedClass("CityCircleMenuCloseUIParameter")
function CityCircleMenuCloseUIParameter:ctor(skipEvent)
    self.skipEvent = skipEvent
end
CityCircleMenuUIMediator.CloseUIParameter = CityCircleMenuCloseUIParameter

function CityCircleMenuUIMediator:OnCreate()
    self._child_circle_menu_city_info = self:LuaObject("child_circle_menu_city_info")
    self._child_circle_menu_simple_buttons = self:LuaObject("child_circle_menu_simple_buttons")
    self._p_anchor_root = self:Transform("p_anchor_root")
    self._p_pet_list = self:GameObject("p_pet_list")
    self._Content = self:Transform("Content")
    self._child_card_pet_circle = self:LuaBaseComponent("child_card_pet_circle")
    self._pet_pool = LuaReusedComponentPool.new(self._child_card_pet_circle, self._Content)
end

---@param param CityCircleMenuUIParameter
function CityCircleMenuUIMediator:OnOpened(param)
    self.param = param
    self._child_circle_menu_city_info:SetVisible(false)
    self._child_circle_menu_simple_buttons:FeedData(self.param.btns)
    self.camera = self.param.camera.mainCamera

    self:UpdatePosition()
    self:UpdatePetInfos()
    self:OnSecondTick()
    self:AdjustCameraPos()
    
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    if self.param.autoClose then
        g_Game.EventManager:AddListener(EventConst.UI_BUTTON_CLICK_PRE, Delegate.GetOrCreate(self, self.OnClickClose))
    end
    g_Game.EventManager:AddListener(EventConst.UI_REFRESH_CITY_CIRCLE_MENU, Delegate.GetOrCreate(self, self.OnRefreshData))
end

function CityCircleMenuUIMediator:OnClose(param)
    g_Game.EventManager:RemoveListener(EventConst.UI_REFRESH_CITY_CIRCLE_MENU, Delegate.GetOrCreate(self, self.OnRefreshData))
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateTick))
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    if self.param and self.param.autoClose then
        g_Game.EventManager:RemoveListener(EventConst.UI_BUTTON_CLICK_PRE, Delegate.GetOrCreate(self, self.OnClickClose))
    end
    if not param or not param.skipEvent then
        g_Game.EventManager:TriggerEvent(EventConst.CITY_CIRCLE_MENU_CLOSED)
    end
end

function CityCircleMenuUIMediator:OnSecondTick()
    local endTime = self.param.timestamp
    if endTime and endTime > 0 then
        local leftTime = endTime - g_Game.ServerTime:GetServerTimestampInSeconds()
        if leftTime > 0 then
            self._child_circle_menu_city_info._p_text_timer.text = TimeFormatter.SimpleFormatTimeWithoutZero(leftTime)
            self._child_circle_menu_city_info._p_text_timer:SetVisible(true)
            return
        end
    end
    self._child_circle_menu_city_info._p_text_timer:SetVisible(false)
end

function CityCircleMenuUIMediator:OnLateTick()
    self:UpdatePosition()
end

function CityCircleMenuUIMediator:UpdatePosition()
    if Utils.IsNull(self.camera) then
        return
    end

    local screenPoint = self.camera:WorldToScreenPoint(self.param.worldPos)
    screenPoint.z = 0
    local uiCamera = g_Game.UIManager:GetUICamera()
    self._p_anchor_root.position = uiCamera:ScreenToWorldPoint(screenPoint)
end

function CityCircleMenuUIMediator:UpdatePetInfos()
    local showPetInfos = self.param.petInfos ~= nil and next(self.param.petInfos) ~= nil
    self._p_pet_list:SetActive(showPetInfos)

    if showPetInfos then
        self._pet_pool:HideAll()
        for _, petInfo in ipairs(self.param.petInfos) do
            local petItem = self._pet_pool:GetItem()
            petItem:FeedData(petInfo)
        end
    end
end

---@param baseComponent BaseUIComponent
function CityCircleMenuUIMediator:OnClickClose(baseComponent)
    if not baseComponent then
        self:CloseSelf()
        return
    end
    
    local mediator = baseComponent:GetParentBaseUIMediator()
    if mediator == nil or mediator == self then
        return
    end
    self:CloseSelf()
end

function CityCircleMenuUIMediator:AdjustCameraPos()
    local uiCamera = g_Game.UIManager:GetUICamera()
    if uiCamera == nil then return end
    if Utils.IsNull(self._child_circle_menu_simple_buttons) or Utils.IsNull(self._child_circle_menu_simple_buttons.CSComponent) then return end

    ---@type CS.UnityEngine.RectTransform
    local rectTransform = self._child_circle_menu_simple_buttons.CSComponent.transform
    local ovx, ovy = TipsRectTransformUtils.CalculateTargetRectTransformViewportOffset(rectTransform, uiCamera)
    if math.abs(ovx) < 0.1 and math.abs(ovy) < 0.1 then return end

    local camera = self.param.camera
    if camera == nil then return end
    
    camera:MoveViewportOffset(ovx, ovy, 0.25)
end

function CityCircleMenuUIMediator:OnRefreshData(runtimeId, param)
    if runtimeId ~= self:GetRuntimeId() then return end

    self._child_circle_menu_simple_buttons:FeedData(param.btns)
end

return CityCircleMenuUIMediator