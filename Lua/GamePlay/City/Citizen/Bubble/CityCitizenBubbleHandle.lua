local Delegate = require("Delegate")
local ArtResourceUtils = require("ArtResourceUtils")
local ArtResourceConsts = require("ArtResourceConsts")
local Utils = require("Utils")

---@class CityCitizenBubbleHandle
---@field new fun():CityCitizenBubbleHandle
local CityCitizenBubbleHandle = sealedClass('CityCitizenBubbleHandle')

function CityCitizenBubbleHandle:ctor()
    ---@type CityCitizenBubbleManager
    self._mgr = nil
    self._active = false
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self._resHandle = nil
    self._go = nil
    self._delayRelease = nil
    self._needRelease = false
    ---@type CS.UnityEngine.Transform
    self._attachTrans = nil
    ---@type CityCitizenBubbleTip
    self._tip = nil
    ---@type CS.UnityEngine.Transform
    self._tipTrans = nil

    ---@type BubbleConfigCell
    self._config = nil
    ---@type CityCitizenBubbleTipTaskContext
    self._chapterTask = nil
    self._escape = false
    ---@type {icon:string, changeValue:number}
    self._indicator = nil
    ---@type {icon:string}
    self._emoji = nil
end

---@param mgr CityCitizenBubbleManager
function CityCitizenBubbleHandle:Init(mgr)
    self._mgr = mgr
    self._cityRoot = mgr._city:GetRoot().transform
end

function CityCitizenBubbleHandle:SetActive(active)
    if self._active == active then
        return
    end
    self._active = active
    if active and not self._resHandle then
        if Utils.IsNotNull(self._attachTrans) then
            self._resHandle = self._mgr._goCreator:Create(ArtResourceUtils.GetItem(ArtResourceConsts.ui3d_bubble_citizen_tip), self._cityRoot, Delegate.GetOrCreate(self, self.OnAssetLoaded))
        end
    elseif not active and self._resHandle then
        self._tip = nil
        self._tipTrans = nil
        self._resHandle:Delete()
        self._resHandle = nil
    end
end

---@return boolean
function CityCitizenBubbleHandle:Tick(dt)
    if Utils.IsNull(self._attachTrans) then
        return true
    end
    if Utils.IsNotNull(self._tipTrans) then
        self._tipTrans.position = self._attachTrans.position
    end
    if not self._delayRelease then
        return false
    end
    if self._delayRelease then
        self._delayRelease = self._delayRelease - dt
        if self._delayRelease < 0 then
            self._delayRelease = nil
            self._needRelease = true
        end
    end
    if not self._needRelease then
        if self._tip then
            self._tip:Tick(dt)
        end
    end
    return self._needRelease
end

---@param go CS.UnityEngine.GameObject
function CityCitizenBubbleHandle:OnAssetLoaded(go, _)
    if Utils.IsNull(go) then
        return
    end
    self._tipTrans = go.transform
    ---@type CityCitizenBubbleTip
    self._tip = go:GetLuaBehaviour("CityCitizenBubbleTip").Instance
    go:SetVisible(self._active)
    self:SetupBubbleLua()
end

function CityCitizenBubbleHandle:SetupBubbleLua()
    if not self._tip then return end
    self._tip:Reset()
    if self._chapterTask then
        self._tip:SetupTaskButton(self._chapterTask)
    elseif self._config then
        self._tip:SetTipContent(self._config)
    elseif self._escape then
        self._tip:SetupEscape()
    elseif self._indicator then
        self._tip:SetupEvaluation(self._indicator.icon, self._indicator.changeValue)
    elseif self._emoji then
        self._tip:SetupEmoji(self._emoji.icon)
    end
end

function CityCitizenBubbleHandle:Release()
    if self._resHandle then
        self._resHandle:Delete()
        self._resHandle = nil
    end
    self._tip = nil
    self._attachTrans = nil
    self._tipTrans = nil
    self._delayRelease = nil
end

function CityCitizenBubbleHandle:Reset()
    self._needRelease = false
    self._config = nil
    self._delayRelease = nil
    self._chapterTask = nil
    self._escape = false
    self._indicator = nil
    self._emoji = nil
    if Utils.IsNotNull(self._tip) then
        self._tip:Reset()
    end
end

---@param config BubbleConfigCell
function CityCitizenBubbleHandle:SetupBubbleConfig(config)
    self._config = config
    self._delayRelease = config:Duration()
    self:SetupBubbleLua()
end

---@param context CityCitizenBubbleTipTaskContext
function CityCitizenBubbleHandle:SetupTask(context)
    self._chapterTask = context
    self:SetupBubbleLua()
end

function CityCitizenBubbleHandle:SetupEscape()
    self._escape = true
    self:SetupBubbleLua()
end

---@param change {icon:string, changeValue:number}
function CityCitizenBubbleHandle:SetupIndicatorChange(change)
    self._indicator = change
    self:SetupBubbleLua()
end

---@param emoji {icon:string}
function CityCitizenBubbleHandle:SetupEmoji(emoji)
    self._emoji = emoji
    self:SetupBubbleLua()
end

return CityCitizenBubbleHandle