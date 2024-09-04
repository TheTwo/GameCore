---Scene Name : scene_common_hud_hint
local BaseUIMediator = require ('BaseUIMediator')
local LuaReusedComponentPool = require('LuaReusedComponentPool')
local EventConst = require("EventConst")
local Delegate = require("Delegate")
local ModuleRefer = require("ModuleRefer")

---@interface IMarker
---@field IsTroop fun(self:IMarker):boolean
---@field GetHeroInfoData fun(self:IMarker):HeroInfoData
---@field GetImage fun(self:IMarker):string
---@field DoUpdate fun(self:IMarker)
---@field GetViewportPosition fun(self:IMarker):CS.UnityEngine.Vector3
---@field NeedShow fun(self:IMarker):boolean
---@field GetCamera fun(self:IMarker):BasicCamera
---@field GetDistance fun(self:IMarker):number
---@field OnClick fun(self:IMarker)
---@field OverrrideMask fun(self:IMarker):number|nil

---@interface IMarkerGroup
---@field AddEventListener fun()
---@field RemoveEventListener fun()
---@field SetupUIMediator fun(uiMediator:UnitMarkerHudUIMediator)
---@field GetMarkers fun():IMarker[]

---@class UnitMarkerHudUIMediator:BaseUIMediator
local UnitMarkerHudUIMediator = class('UnitMarkerHudUIMediator', BaseUIMediator)

---@private
function UnitMarkerHudUIMediator:OnCreate()
    self._content = self:Transform("content")
    self._child_hud_hint = self:LuaBaseComponent("child_hud_hint")
    local canvasGroup = self._content.gameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    if not canvasGroup then
        canvasGroup = self._content.gameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
    ---@type CS.UnityEngine.CanvasGroup
    self._contentCanvasGroup = canvasGroup
end

---@param param IMarkerGroup
---@private
function UnitMarkerHudUIMediator:OnOpened(param)
    self._group = param
    self._group:SetupUIMediator(self)
    self._group:AddEventListener()

    self:InitComponentPool()

    self._markers = self._group:GetMarkers()
    self._marker2Item = {}
    for i, v in ipairs(self._markers) do
        local item = self._pool:GetItem()
        item:FeedData(v)
        self._marker2Item[v] = item
    end

    g_Game.EventManager:AddListener(EventConst.UI_MARKER_APPEND, Delegate.GetOrCreate(self, self.AddMarker))
    g_Game.EventManager:AddListener(EventConst.UI_MARKER_REMOVE, Delegate.GetOrCreate(self, self.RemoveMarker))
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
end

function UnitMarkerHudUIMediator:OnShow()
    g_Game.EventManager:AddListener(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, Delegate.GetOrCreate(self, self.OnShowHideChange))
end

function UnitMarkerHudUIMediator:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, Delegate.GetOrCreate(self, self.OnShowHideChange))
end

---@private
function UnitMarkerHudUIMediator:OnClose(param)
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnSecondTick))
    g_Game.EventManager:RemoveListener(EventConst.UI_MARKER_APPEND, Delegate.GetOrCreate(self, self.AddMarker))
    g_Game.EventManager:RemoveListener(EventConst.UI_MARKER_REMOVE, Delegate.GetOrCreate(self, self.RemoveMarker))
    if self._group then
        self._group:RemoveEventListener()
    end
    self:ReleaseComponentPool()
end

function UnitMarkerHudUIMediator:OnSecondTick(delta)
    -- g_Logger.TraceChannel("UnitMarkerHudUIMediator", delta)
end

---@private
function UnitMarkerHudUIMediator:InitComponentPool()
    self._pool = LuaReusedComponentPool.new(self._child_hud_hint, self._content)
end

---@private
function UnitMarkerHudUIMediator:ReleaseComponentPool()
    if self._pool then
        self._pool:Release()
    end
end

function UnitMarkerHudUIMediator:AddMarker(marker)
    for i, v in ipairs(self._markers) do
        if v == marker then
            return
        end
    end
    table.insert(self._markers, marker)
    local item = self._pool:GetItem()
    item:FeedData(marker)
    self._marker2Item[marker] = item
end

function UnitMarkerHudUIMediator:RemoveMarker(marker)
    for i, v in ipairs(self._markers) do
        if v == marker then
            table.remove(self._markers, i)
            local item = self._marker2Item[marker]
            self._marker2Item[marker] = nil
            self._pool:Recycle(item)
            return
        end
    end
end

function UnitMarkerHudUIMediator:OnShowHideChange(show)
    if not show then
        self._contentCanvasGroup.alpha = 0
        self._contentCanvasGroup.interactable = false
        self._contentCanvasGroup.blocksRaycasts = false
    else
        self._contentCanvasGroup.alpha = 1
        self._contentCanvasGroup.interactable = true
        self._contentCanvasGroup.blocksRaycasts = true
    end
end

return UnitMarkerHudUIMediator