
---@class NativeLoadingOverlay
local NativeLoadingOverlay = sealedClass("NativeLoadingOverlay")

---@type fun():boolean,CS.DragonReborn.INativeLoadingOverlay
NativeLoadingOverlay.queryFrameInterfaceFunc = nil
NativeLoadingOverlay.currentVersion = 1

---@return CS.DragonReborn.INativeLoadingOverlay
function NativeLoadingOverlay.GetCSharpInterface()
    if not NativeLoadingOverlay.queryFrameInterfaceFunc then
        local genericBuilder = xlua.get_generic_method(CS.DragonReborn.FrameworkInterfaceManager, 'QueryFrameInterface')
        NativeLoadingOverlay.queryFrameInterfaceFunc = genericBuilder(CS.DragonReborn.INativeLoadingOverlay)
    end
    if NativeLoadingOverlay.queryFrameInterfaceFunc then
        local ret,overlay = NativeLoadingOverlay.queryFrameInterfaceFunc()
        if ret then
            return overlay
        end
    end
    return nil
end

---@param viewPortPos CS.UnityEngine.Vector2
---@param pivot CS.UnityEngine.Vector2
---@param size CS.UnityEngine.Vector2
---@param loopDuration number @ms
function NativeLoadingOverlay.Show(viewPortPos, pivot, size, loopDuration)
    pivot = pivot or CS.UnityEngine.Vector2(0.5, 0.5)
    if UNITY_ANDROID then
        size = size or CS.UnityEngine.Vector2(64, 64)
    else
        size = size or CS.UnityEngine.Vector2(48, 48)
    end
    loopDuration = loopDuration or 500
    local overlay = NativeLoadingOverlay.GetCSharpInterface()
    if not overlay then return end
    overlay:PlayFile(viewPortPos, pivot, size, loopDuration)
end

function NativeLoadingOverlay.Close()
    local overlay = NativeLoadingOverlay.GetCSharpInterface()
    if not overlay then return end
    overlay:Remove()
end

---@param viewPort CS.UnityEngine.Vector2
function NativeLoadingOverlay.UpdatePos(viewPort)
    local overlay = NativeLoadingOverlay.GetCSharpInterface()
    if not overlay then return end
    overlay:UpdatePos(viewPort)
end

function NativeLoadingOverlay.CheckAndWriteOverrideIcon()
    local overlay = NativeLoadingOverlay.GetCSharpInterface()
    if not overlay then return end
    if overlay:GetCurrentOverrideIconFileVersion() == NativeLoadingOverlay.currentVersion then return end
    local handle = g_Game.AssetManager:LoadAsset(require("ManualResourceConst").sp_custom_loading_icon_raw)
    if not handle or require("Utils").IsNull(handle.Asset) then return end
    NativeLoadingOverlay.WriteOverrideIcon(handle.Asset)
end

function NativeLoadingOverlay.WriteOverrideIcon(bytesAsset)
    local overlay = NativeLoadingOverlay.GetCSharpInterface()
    if not overlay then return end
    overlay:SetOverrideIconFile(bytesAsset, NativeLoadingOverlay.currentVersion)
end

function NativeLoadingOverlay.ClearOverrideIcon()
    local overlay = NativeLoadingOverlay.GetCSharpInterface()
    if not overlay then return end
    overlay:ClearOverrideIconFile()
end

return NativeLoadingOverlay