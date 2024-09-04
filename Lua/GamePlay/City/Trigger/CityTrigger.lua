local Utils = require("Utils")

---@class CityTrigger
---@field new fun():CityTrigger
---@field gameObject CS.UnityEngine.GameObject
---@field collider CS.UnityEngine.Collider
---@field btnClickAniProvider CS.UnityEngine.Animation|nil
---@field btnPressDownClip CS.UnityEngine.AnimationClip|nil
---@field btnPressUpClip CS.UnityEngine.AnimationClip|nil
local CityTrigger = class("CityTrigger")

function CityTrigger:ctor()
    self._onTrigger = nil
    self._ownerTileX = nil
    self._ownerTileY = nil
    self._clickInterval = 0.5
end

---@return number|nil,number|nil
function CityTrigger:GetOwnerPos()
    return self._ownerTileX,self._ownerTileY
end

function CityTrigger:SetClickInterval(value)
    self._clickInterval = value
end

function CityTrigger:Start()
    self.gameObject = self.behaviour.gameObject
    self.collider = self.gameObject:GetComponentInChildren(typeof(CS.UnityEngine.Collider), true)

    if self.collider == nil then
        g_Logger.ErrorChannel("CityTrigger", ("CityTrigger need a Collider(obj named %s)"):format(self.gameObject.name))
    end
end

function CityTrigger:OnEnable()
    if Utils.IsNotNull(self.btnClickAniProvider) then
        if Utils.IsNotNull(self.btnPressUpClip) then
            self.btnClickAniProvider:SetAnimationTime(self.btnPressUpClip.name, self.btnPressUpClip.length)
        else
            self.btnClickAniProvider:SetAnimationNormalizedTimeByIndex(0, 1)
        end
    end
end

---@param callback fun(trigger:CityTrigger):boolean
---@param tile CityTileBase|CityStaticObjectTile|nil
function CityTrigger:SetOnTrigger(callback, tile, isUIBubble, isCityTroop)
    self._onTrigger = callback
    self._tile = tile
    self._isUIBubble = isUIBubble or false
    self._isCityTroop = isCityTroop or false
    if tile and tile:Inited() then
        self._ownerTileX = tile.x
        self._ownerTileY = tile.y
    else
        self._ownerTileX = nil
        self._ownerTileY = nil
    end
    self._lastClickTime = nil
end

function CityTrigger:SetOnPress(onPressDown, onPress, onPressUp)
    self._onPressDown = onPressDown
    self._onPress = onPress
    self._onPressUp = onPressUp
end

function CityTrigger:IsUIBubble()
    return self._isUIBubble == true
end

function CityTrigger:IsCityTroop()
    return self._isCityTroop == true
end

function CityTrigger:IsTilePolluted()
    self:EnsureTileValid()
    if self._tile and self._tile:Inited() then
        return self._tile:IsPolluted()
    end
    return false
end

function CityTrigger:IsTileBlockExecute()
    self:EnsureTileValid()
    if self._tile and self._tile:Inited() then
        return self._tile:BlockTriggerExecute()
    end
    return false
end

---@return CityTileBase|CityStaticObjectTile
function CityTrigger:GetTile()
    self:EnsureTileValid()
    return self._tile
end

function CityTrigger:EnsureTileValid()
    if self._tile and not self._tile:Inited() then
        local className = "unknown"
        if self._tile.__class then
            className = self._tile.__class.__cname
        end
        g_Logger.ErrorChannel("CityTrigger", "异常情况, CityTrigger持有了一个已被释放的Tile仍在响应逻辑:%s", className)
        self._tile = nil
    end
end

---@return boolean 返回true时阻断CityMediator的OnClick向下进行
function CityTrigger:ExecuteOnClick()
    if self._onTrigger then
        if self:CheckClickInterval() then
            return self._onTrigger(self)
        else
            return true
        end
    end
    return false
end

function CityTrigger:CheckClickInterval()
    if self._lastClickTime == nil then
        self._lastClickTime = g_Game.RealTime.realtimeSinceStartup
        return true
    end

    local now = g_Game.RealTime.realtimeSinceStartup
    if now - self._lastClickTime > self._clickInterval then
        self._lastClickTime = now
        return true
    end
    return false
end

function CityTrigger:Pressable()
    return not self:IsUIBubble() or self:IsCityTroop()
end

function CityTrigger:ExecuteOnPressDown()
    if self._onPressDown then
        return self._onPressDown(self)
    end
    return false
end

function CityTrigger:ExecuteOnPress()
    if self._onPress then
        return self._onPress(self)
    end
    return false
end

function CityTrigger:ExecuteOnPressUp()
    if self._onPressUp then
        return self._onPressUp(self)
    end
    return false
end

function CityTrigger:OnPressDownAnim()
    if Utils.IsNotNull(self.btnClickAniProvider) then
        if Utils.IsNotNull(self.btnPressDownClip) then
            self.btnClickAniProvider.clip = self.btnPressDownClip
            self.btnClickAniProvider:PlayAnimationClip(self.btnPressDownClip.name)
        else
            self.btnClickAniProvider.clip = nil
            self.btnClickAniProvider:PlayAnimationClipAtIndex(1)
        end
    end
end

function CityTrigger:OnPressUpAnim()
    if Utils.IsNotNull(self.btnClickAniProvider) then
        if Utils.IsNotNull(self.btnPressUpClip) then
            local b,t = self.btnClickAniProvider:GetCurrentAnimationNormalizedTime()
            self.btnClickAniProvider.clip = nil
            if b then
                self.btnClickAniProvider:PlayAnimationClipEx(self.btnPressUpClip.name, 1, math.clamp(1 - t, 0, 0.75))
            else
                self.btnClickAniProvider:PlayAnimationClip(self.btnPressUpClip.name)
            end
        else
            self.btnClickAniProvider.clip = nil
            self.btnClickAniProvider:PlayAnimationClipAtIndex(0)
        end
    end
end

return CityTrigger