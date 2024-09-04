-- scene:scene_child_hud_explorer_list

local Delegate = require("Delegate")
local EventConst = require("EventConst")

local HUDExplorerListUnknownMode= require("HUDExplorerListUnknownMode")
local HUDExplorerListCityMode= require("HUDExplorerListCityMode")
local HUDExplorerListWorldMode= require("HUDExplorerListWorldMode")

local BaseUIComponent = require("BaseUIComponent")

---@class HUDExplorerList:BaseUIComponent
---@field new fun():HUDExplorerList
---@field super BaseUIComponent
local HUDExplorerList = class('HUDExplorerList', BaseUIComponent)
HUDExplorerList.Mode = {
    Unknown = 0,
    World = 1,
    City = 2,
}

function HUDExplorerList:ctor()
    BaseUIComponent.ctor(self)
    self._mode = HUDExplorerList.Mode.Unknown
    ---@type table<number, HUDExplorerListBaseMode>
    self._modes = {
        [HUDExplorerList.Mode.Unknown] = HUDExplorerListUnknownMode.new(),
        [HUDExplorerList.Mode.City] = HUDExplorerListCityMode.new(),
        [HUDExplorerList.Mode.World] = HUDExplorerListWorldMode.new(),
    }
end

function HUDExplorerList:OnCreate(param)
    self._p_hud_explore = self:GameObject("p_hud_explore")
    self._p_hint = self:GameObject("p_hint")
    self._p_text_hint = self:Text("p_text_hint")
    self._p_bubble = self:GameObject("p_bubble")
    self._p_icon_bubble_status = self:Image("p_icon_bubble_status")
    self._p_icon_add = self:GameObject("p_icon_add")
    self._p_img_hero = self:Image("p_img_hero")
    self._p_btn_resident = self:Button("p_btn_resident", Delegate.GetOrCreate(self, self.OnClick))
    self._p_btn_resident_rect = self:RectTransform("p_btn_resident")
    self._p_icon_explore = self:Image("p_icon_explore")
    self._p_icon_explore_empty = self:Image("p_icon_explore_empty")
    self._p_troop_status = self:Image("p_troop_status")
    self._p_icon_status = self:Image("p_icon_status")
    
    self:DragEvent("p_btn_resident"
            , Delegate.GetOrCreate(self, self.OnDragBegin)
            , Delegate.GetOrCreate(self, self.OnDragUpdate)
            , Delegate.GetOrCreate(self, self.OnDragEnd)
            , false
    )
    self:DragCancelEvent("p_btn_resident", Delegate.GetOrCreate(self, self.OnDragCancel))

    for _, mode in pairs(self._modes) do
        mode:OnCreate(self)
    end
end

function HUDExplorerList:OnClose(param)
    for _, mode in pairs(self._modes) do
        mode:OnRelease()
    end
end

function HUDExplorerList:OnShow(param)
    self:AutoSelectMode()
    self._modes[self._mode]:Enter()
    g_Game.EventManager:AddListener(EventConst.HUD_STATE_CHANGED, Delegate.GetOrCreate(self, self.AutoSelectMode))
    g_Game.EventManager:AddListener(EventConst.SCENE_LOADED, Delegate.GetOrCreate(self, self.AutoSelectMode))
end

function HUDExplorerList:OnHide(param)
    g_Game.EventManager:RemoveListener(EventConst.SCENE_LOADED, Delegate.GetOrCreate(self, self.AutoSelectMode))
    g_Game.EventManager:RemoveListener(EventConst.HUD_STATE_CHANGED, Delegate.GetOrCreate(self, self.AutoSelectMode))
    self._modes[self._mode]:Exit()
end

function HUDExplorerList:AutoSelectMode()
    ---@type KingdomScene
    local scene = g_Game.SceneManager.current
    if scene then
        local sceneName = scene:GetName()
        if sceneName == 'KingdomScene' then
            if scene:IsInMyCity() then
                self:ChangeMode(HUDExplorerList.Mode.City)
                return
            elseif not scene:IsInCity() then
                self:ChangeMode(HUDExplorerList.Mode.World)
                return
            end
        end
    end
    self:ChangeMode(HUDExplorerList.Mode.Unknown)
end

function HUDExplorerList:ChangeMode(mode)
    if mode == self._mode then
        self._modes[self._mode]:Refresh()
        return
    end
    self._modes[self._mode]:Exit()
    self._mode = mode
    self._modes[self._mode]:Enter()
end

function HUDExplorerList:OnClick()
    self._modes[self._mode]:OnClick()
end

---@param go CS.UnityEngine.GameObject
---@param event "CS.UnityEngine.PointerEventData"
function HUDExplorerList:OnDragBegin(go, event)
    self._modes[self._mode]:OnDragBegin(go, event)
end

---@param go CS.UnityEngine.GameObject
---@param event "CS.UnityEngine.PointerEventData"
function HUDExplorerList:OnDragUpdate(go, event)
    self._modes[self._mode]:OnDragUpdate(go, event)
end

---@param go CS.UnityEngine.GameObject
---@param event "CS.UnityEngine.PointerEventData"
function HUDExplorerList:OnDragEnd(go, event)
    self._modes[self._mode]:OnDragEnd(go, event)
end

---@param go CS.UnityEngine.GameObject
function HUDExplorerList:OnDragCancel(go)
    self._modes[self._mode]:OnDragCancel(go, event)
end

return HUDExplorerList