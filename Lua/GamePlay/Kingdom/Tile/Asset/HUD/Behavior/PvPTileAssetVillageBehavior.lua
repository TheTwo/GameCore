local Utils = require("Utils")
local PoolUsage = require("PoolUsage")

local VisualEffectHandle = CS.DragonReborn.VisualEffect.VisualEffectHandle

---@class PvPTileAssetVillageBehavior
---@field towerAnimators CS.System.Collections.Generic.List(CS.UnityEngine.Animator)
---@field effectBones CS.System.Collections.Generic.List(CS.UnityEngine.Component)
---@field skillEffects CS.System.Collections.Generic.List(CS.System.String)
---@field vfxHandles table<number, CS.DragonReborn.VisualEffect.VisualEffectHandle>
---@field effectCount number
---@field boneCount number
local PvPTileAssetVillageBehavior = class("PvPTileAssetVillageBehavior")

function PvPTileAssetVillageBehavior:Awake()
    self:InitOnce()
end

function PvPTileAssetVillageBehavior:PlayTowerAnim(anim, normalizedTime)
    self:InitOnce()
    for i = 0, self.animatorCount - 1 do
        local animator = self.towerAnimators[i]
        if Utils.IsNotNull(animator) then
            animator.enabled = true
            if normalizedTime then
                animator:Play(anim, -1, normalizedTime)
            else
                animator:Play(anim)
            end
        end
    end
end

function PvPTileAssetVillageBehavior:PlayBattleTowerAnim()
    self:InitOnce()
    for i = 0, self.animatorCount - 1 do
        local animator = self.towerAnimators[i]
        local effectBone = self.effectBones[i]
        local effectName
        local anim
        if i > 3 then
            anim = "attack_loop02"
            effectName = self.skillEffects[1]
        elseif i > 1 then
            anim = "attack_loop01"
            effectName = self.skillEffects[0]
        else
            anim = "attack_loop03"
            effectName = self.skillEffects[2]
        end
        animator.enabled = true
        animator:Play(anim)

        if not string.IsNullOrEmpty(effectName) and Utils.IsNotNull(effectBone) then
            local handle = self.vfxHandles[i]
            if not handle then
                handle = VisualEffectHandle()
                self.vfxHandles[i] = handle
            end
            handle:Create(effectName, PoolUsage.Map, effectBone)
        end
    end
end

function PvPTileAssetVillageBehavior:StopTowerAnim(anim)
    for i = 0, self.towerAnimators.Count - 1 do
        local animator = self.towerAnimators[i]
        if Utils.IsNotNull(animator) then
            animator.enabled = false
            local handle = self.vfxHandles[i]
            if handle then
                handle:Delete()
            end
        end
    end
end

function PvPTileAssetVillageBehavior:InitOnce()
    if not self.vfxHandles then
        self.vfxHandles = {}
        self.animatorCount = self.towerAnimators and self.towerAnimators.Count or 0
        self.effectCount = self.skillEffects and self.skillEffects.Count or 0
        self.boneCount = self.effectBones and self.effectBones.Count or 0
    end
end

function PvPTileAssetVillageBehavior:ClearAllVfx()
    for _, handle in pairs(self.vfxHandles) do
        if handle then
            handle:Delete()
        end
    end
    table.clear(self.vfxHandles)
end

return PvPTileAssetVillageBehavior
