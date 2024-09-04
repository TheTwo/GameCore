---@class HUDExplorerListBaseMode
---@field new fun():HUDExplorerListBaseMode
local HUDExplorerListBaseMode = class('HUDExplorerListBaseMode')

function HUDExplorerListBaseMode:ctor()
    ---@protected
    ---@type HUDExplorerList
    self._host = nil
end

---@param host HUDExplorerList
function HUDExplorerListBaseMode:OnCreate(host)
    self._host = host
end

function HUDExplorerListBaseMode:OnRelease()
    self._host = nil
end

function HUDExplorerListBaseMode:Enter()
    self._host._p_hint:SetVisible(false)
    self._host._p_img_hero:SetVisible(false)
    self._host._p_troop_status:SetVisible(false)
    self._host._p_bubble:SetVisible(false)
    self._host._p_icon_add:SetVisible(true)
    self._host._p_icon_explore:SetVisible(false)
    self._host._p_icon_explore_empty:SetVisible(true)
end

function HUDExplorerListBaseMode:Exit()
    
end

function HUDExplorerListBaseMode:OnClick()
    
end

---@param go CS.UnityEngine.GameObject
---@param event "CS.UnityEngine.PointerEventData"
function HUDExplorerListBaseMode:OnDragBegin(go, event)
end

---@param go CS.UnityEngine.GameObject
---@param event "CS.UnityEngine.PointerEventData"
function HUDExplorerListBaseMode:OnDragUpdate(go, event)
end

---@param go CS.UnityEngine.GameObject
---@param event "CS.UnityEngine.PointerEventData"
function HUDExplorerListBaseMode:OnDragEnd(go, event)
end

---@param go CS.UnityEngine.GameObject
function HUDExplorerListBaseMode:OnDragCancel(go)
end

function HUDExplorerListBaseMode:Refresh()
end

return HUDExplorerListBaseMode