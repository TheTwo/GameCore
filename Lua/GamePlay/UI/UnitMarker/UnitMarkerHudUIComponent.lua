---@childScene : scene_child_hud_hint
local BaseUIComponent = require ('BaseUIComponent')
local ModuleRefer = require('ModuleRefer')
local ConfigRefer = require('ConfigRefer')
local Delegate = require('Delegate')
local Mask = CS.UnityEngine.LayerMask.GetMask("UI")
local I18N = require("I18N")
local EventConst = require('EventConst')

---@class UnitMarkerHudUIComponent:BaseUIComponent
---@field super BaseUIComponent
---@field _p_troop_head HeroInfoItemComponent
local UnitMarkerHudUIComponent = class('UnitMarkerHudUIComponent', BaseUIComponent)

function UnitMarkerHudUIComponent:ctor()
    UnitMarkerHudUIComponent.super.ctor(self)
    self._castMask = Mask
end

function UnitMarkerHudUIComponent:OnCreate()
    self.transform = self:RectTransform("")
    self._p_troop_head = self:LuaObject("p_troop_head")
    self._p_img = self:GameObject("p_img")
    self._p_img_icon = self:Image("p_img_icon")
    self._p_arrow = self:GameObject("p_arrow")
    self._p_click = self:Button("p_click", Delegate.GetOrCreate(self, self.OnClick))
    self._p_text_diatance = self:Text("p_text_diatance")

    self._originDir = CS.UnityEngine.Vector2(1, 0)

    local sizeDelta = self.transform.sizeDelta
    local lossyScale = self.transform.lossyScale
    self._size = CS.UnityEngine.Vector2(sizeDelta.x * lossyScale.x, sizeDelta.y * lossyScale.y)

    self._screenWidth = CS.UnityEngine.Screen.width
    self._screenHeight = CS.UnityEngine.Screen.height
    self._distance = math.max(self._screenWidth, self._screenHeight) * 1.5
    g_Game:AddLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateUpdate))

    self._root = self:RectTransform("")
    local canvasGroup = self._root.gameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    if not canvasGroup then
        canvasGroup = self._root.gameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
    ---@type CS.UnityEngine.CanvasGroup
    self._rootCanvasGroup = canvasGroup

    self:ShowHideHint(true)
end

function UnitMarkerHudUIComponent:OnShow()
    g_Game.EventManager:AddListener(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, Delegate.GetOrCreate(self, self.OnCanvasShowHide))
end

function UnitMarkerHudUIComponent:OnHide()
    g_Game.EventManager:RemoveListener(EventConst.UNIT_MARKER_CANVAS_SHOW_HIDE_FOR_3D_UI, Delegate.GetOrCreate(self, self.OnCanvasShowHide))
end

function UnitMarkerHudUIComponent:OnClose()
    g_Game:RemoveLateFrameTicker(Delegate.GetOrCreate(self, self.OnLateUpdate))
end

---@param data IMarker
function UnitMarkerHudUIComponent:OnFeedData(data)
    self._marker = data
    if data.OverrrideMask then
        self._castMask = data:OverrrideMask() or Mask
    end
    local isTroop = data:IsTroop()
    self._p_troop_head:SetVisible(isTroop)
    self._p_img:SetVisible(not isTroop)
    self._p_text_diatance:SetVisible(not isTroop)
    if isTroop then
        self._p_troop_head:FeedData(self._marker:GetHeroInfoData())
    else
        g_Game.SpriteManager:LoadSprite(self._marker:GetImage(), self._p_img_icon)
    end
    self._marker:DoUpdate()
    
    CS.UnityEngine.Physics2D.SyncTransforms()
end

function UnitMarkerHudUIComponent:ShowHideHint(isShow)
    self.isShow = isShow
end

function UnitMarkerHudUIComponent:OnCanvasShowHide(show)
    if not show then
        self._rootCanvasGroup.alpha = 0
        self._rootCanvasGroup.interactable = false
        self._rootCanvasGroup.blocksRaycasts = false
    else
        self._rootCanvasGroup.alpha = 1
        self._rootCanvasGroup.interactable = true
        self._rootCanvasGroup.blocksRaycasts = true
    end
end

function UnitMarkerHudUIComponent:OnLateUpdate()
    if not self._marker then return end
    self._marker:DoUpdate()

    local show = self._marker:NeedShow()
    if not show or not self.isShow then
        self:SetVisible(false)
        return
    end

    local center = CS.UnityEngine.Vector2(0.5, 0.5)
    local viewport = self._marker:GetViewportPosition()
    local target = CS.UnityEngine.Vector2(viewport.x, viewport.y) * math.sign(viewport.z)
    local dir = (target - center).normalized
    local flag, point = CS.RaycastHelper.Physics2DBoxCastOutCentroid(CS.UnityEngine.Vector2.zero, self._size, 0, dir, self._distance, self._castMask)
    self:SetVisible(flag)
    if flag then
        local worldPosition = CS.UnityEngine.Vector3(point.x, point.y, 0)
        self.transform.position = worldPosition
        local angle = CS.UnityEngine.Vector2.SignedAngle(self._originDir, dir)
        self._p_arrow.transform.localEulerAngles = CS.UnityEngine.Vector3(0, 0, angle)
        if not self._marker:IsTroop() then
            local distance = self._marker:GetDistance()
            if distance >= 1000 then
                self._p_text_diatance.text = ("%dkm"):format(math.floor(distance / 1000))
            else
                self._p_text_diatance.text = ("%dm"):format(math.floor(distance))
            end
        end
    end
end

function UnitMarkerHudUIComponent:OnClick()
    if not self._marker then return end
    self._marker:OnClick()
end

return UnitMarkerHudUIComponent