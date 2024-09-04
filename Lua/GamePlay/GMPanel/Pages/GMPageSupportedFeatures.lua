local GMPageUtils = require("GMPageUtils")
local GUILayout = require("GUILayout")
local UnityEngine = CS.UnityEngine
local SystemInfo = UnityEngine.Device.SystemInfo
local TextureFormat = UnityEngine.TextureFormat
local RenderTextureFormat = UnityEngine.RenderTextureFormat
local GraphicsFormat = UnityEngine.Experimental.Rendering.GraphicsFormat
local FormatUsage = UnityEngine.Experimental.Rendering.FormatUsage
local DefaultFormat = UnityEngine.Experimental.Rendering.DefaultFormat
local Enum = CS.System.Enum
local EnumHelper = CS.DragonReborn.Utilities.EnumHelper

local GMPage = require("GMPage")

---@class GMPageSupportedFeatures:GMPage
local GMPageSupportedFeatures = class('GMPageSupportedFeatures', GMPage)

GMPageSupportedFeatures.InfoCollectionLowerAdd = false
GMPageSupportedFeatures.InfoCollection = {
    {"---------------- Graphics - Features ----------------", function() return nil end},
    {"UV Starts at top", function() return GMPageUtils.PrintBool(SystemInfo.graphicsUVStartsAtTop) end},
    {"Shader Level", function() return GMPageUtils.PrintBool(SystemInfo.graphicsShaderLevel) end},
    {"Multi Threaded", function() return GMPageUtils.PrintBool(SystemInfo.graphicsMultiThreaded) end},
    {"Hidden Service Removal (GPU)", function() return GMPageUtils.PrintBool(SystemInfo.hasHiddenSurfaceRemovalOnGPU) end},
    {"Uniform Array Indexing (Fragment Shaders)", function() return GMPageUtils.PrintBool(SystemInfo.hasDynamicUniformArrayIndexingInFragmentShaders) end},
    {"Shadows", function() return GMPageUtils.PrintBool(SystemInfo.supportsShadows) end},
    {"Raw Depth Sampling (Shadows)", function() return GMPageUtils.PrintBool(SystemInfo.supportsRawShadowDepthSampling) end},
    {"Motion Vectors", function() return GMPageUtils.PrintBool(SystemInfo.supportsMotionVectors) end},
    {"Cubemaps", function() return GMPageUtils.PrintBool(SystemInfo.supportsRenderToCubemap) end},
    {"Image Effects", function() return GMPageUtils.PrintBool(SystemInfo.supportsImageEffects) end},
    {"3D Textures", function() return GMPageUtils.PrintBool(SystemInfo.supports3DTextures) end},
    {"2D Array Textures", function() return GMPageUtils.PrintBool(SystemInfo.supports2DArrayTextures) end},
    {"3D Render Textures", function() return GMPageUtils.PrintBool(SystemInfo.supports3DRenderTextures) end},
    {"Cubemap Array Textures", function() return GMPageUtils.PrintBool(SystemInfo.supportsCubemapArrayTextures) end},
    {"Copy Texture Support", function() return GMPageUtils.PrintBool(SystemInfo.copyTextureSupport) end},
    {"Compute Shaders", function() return GMPageUtils.PrintBool(SystemInfo.supportsComputeShaders) end},
    {"Instancing", function() return GMPageUtils.PrintBool(SystemInfo.supportsInstancing) end},
    {"Hardware Quad Topology", function() return GMPageUtils.PrintBool(SystemInfo.supportsHardwareQuadTopology) end},
    {"32-bit index buffer", function() return GMPageUtils.PrintBool(SystemInfo.supports32bitsIndexBuffer) end},
    {"Sparse Textures", function() return GMPageUtils.PrintBool(SystemInfo.supportsSparseTextures) end},
    {"Render Target Count", function() return GMPageUtils.PrintBool(SystemInfo.supportedRenderTargetCount) end},
    {"Separated Render Targets Blend", function() return GMPageUtils.PrintBool(SystemInfo.supportsSeparatedRenderTargetsBlend) end},
    {"Multisampled Textures", function() return GMPageUtils.PrintBool(SystemInfo.supportsMultisampledTextures) end},
    {"Texture Wrap Mirror Once", function() return GMPageUtils.PrintBool(SystemInfo.supportsTextureWrapMirrorOnce) end},
    {"Reversed Z Buffer", function() return GMPageUtils.PrintBool(SystemInfo.usesReversedZBuffer) end},
    {"---------------- Other - Features -----------------", function() return nil end},
    {"Location", function() return GMPageUtils.PrintBool(SystemInfo.supportsLocationService) end},
    {"Accelerometer", function() return GMPageUtils.PrintBool(SystemInfo.supportsAccelerometer) end},
    {"Gyroscope", function() return GMPageUtils.PrintBool(SystemInfo.supportsGyroscope) end},
    {"Vibration", function() return GMPageUtils.PrintBool(SystemInfo.supportsVibration) end},
    {"Audio", function() return GMPageUtils.PrintBool(SystemInfo.supportsAudio) end},
}
if not GMPageSupportedFeatures.InfoCollectionLowerAdd then
    GMPageSupportedFeatures.InfoCollectionLowerAdd = true
    for _,i in ipairs(GMPageSupportedFeatures.InfoCollection) do
        i[3] = string.lower(i[1])
    end
end

---@param t table @cs enum type
---@return table,table @namesArray, valuesArray
local function GetEnumNotObsoleteNameAndValueArray(t)
    local retNames = {}
    local retValues = {}
    local names = Enum.GetNames(t)
    local values = Enum.GetValues(t)
    local count = names.Length - 1
    for i = 0, count do
        if not EnumHelper.IsEnumValueObsolete(values[i]) then
            table.insert(retNames, names[i])
            table.insert(retValues, values[i])
        end
    end
    return retNames, retValues
end

---@param t table @enum type
---@param checker fun(value):boolean
---@return table
local function FillFormatSupportArray(t, checker)
    local list = {}
    local names,values = GetEnumNotObsoleteNameAndValueArray(t)
    for i = 1, #names do
        local name = names[i]
        local value = values[i]
        local supported = GMPageUtils.PrintBool(checker(value))
        table.insert(list, {name, supported, string.lower(name)})
    end
    return list
end

local function FillGraphicsFormatSupport()
    local list = {}
    local t = typeof(GraphicsFormat)
    local usage = typeof(FormatUsage)
    local names, values = GetEnumNotObsoleteNameAndValueArray(t)
    local usageNames, usageValues = GetEnumNotObsoleteNameAndValueArray(usage)
    local supportUsage = {}
    for i = 1, #names do
        local name = names[i]
        local value = values[i]
        table.clear(supportUsage)
        for j = 1, #usageNames do
            local usageName = usageNames[j]
            local usageValue = usageValues[j]
            if SystemInfo.IsFormatSupported(value, usageValue) then
                table.insert(supportUsage, usageName)
            end
        end
        if #supportUsage > 0 then
            table.insert(list, {name, table.concat(supportUsage, '|'), string.lower(name)})
        end
    end
    return list
end

local function FillGraphicsFormatByDefaultFormat()
    local list = {}
    local names, values = GetEnumNotObsoleteNameAndValueArray(typeof(DefaultFormat))
    local graphicsNames, graphicsValues = GetEnumNotObsoleteNameAndValueArray(typeof(GraphicsFormat))
    local graphicsNamesDic = {}
    for i = 1, #graphicsNames do
        graphicsNamesDic[graphicsValues[i]] = graphicsNames[i]
    end
    for i = 1, #names do
        local name = names[i]
        local graphicFormat = SystemInfo.GetGraphicsFormat(values[i])
        table.insert(list, {name, graphicsNamesDic[graphicFormat], string.lower(name)})
    end
    return list
end

function GMPageSupportedFeatures:ctor()
    self._scrollPos = UnityEngine.Vector2.zero
    self._textureFormats = FillFormatSupportArray(typeof(TextureFormat), SystemInfo.SupportsTextureFormat)
    self._renderTextureFormats = FillFormatSupportArray(typeof(RenderTextureFormat), SystemInfo.SupportsRenderTextureFormat)
    self._graphicsFormats = FillGraphicsFormatSupport()
    self._defaultFormats = FillGraphicsFormatByDefaultFormat()
    self._filter = nil
end

function GMPageSupportedFeatures:OnGUI()
    GUILayout.BeginVertical()
    GUILayout.BeginHorizontal()
    GUILayout.Label("Search:",GUILayout.shrinkWidth)
    self._filter = GUILayout.TextField(self._filter, GUILayout.expandWidth)
    if GUILayout.Button("Copy", GUILayout.shrinkWidth) then
        self:Copy()
    end
    GUILayout.EndHorizontal()
    local inFilterMode = not string.IsNullOrEmpty(self._filter)
    local filter
    if inFilterMode then
        filter = string.lower(self._filter)
    end
    self._scrollPos = GUILayout.BeginScrollView(self._scrollPos)
    for _,i in ipairs(self.InfoCollection) do
        local content = i[2]()
        if nil == content then
            if not inFilterMode then
                GUILayout.Label(i[1])
            end
        else
            if (not inFilterMode) or string.find(i[3], filter) then
                GUILayout.Label(string.format("%s:%s", i[1], content))
            end
        end
    end
    self:DrawSupportFormat(inFilterMode, filter)
    GUILayout.EndScrollView()
    GUILayout.EndVertical()
end

function GMPageSupportedFeatures:DrawSupportFormat(inFilterMode,filter )
    if not inFilterMode then
        GUILayout.Label("---------------- TextureFormat -----------------")
    end
    for _,i in ipairs(self._textureFormats) do
        if (not inFilterMode) or string.find(i[3], filter) then
            GUILayout.Label(string.format("%s:%s", i[1], i[2]))
        end
    end
    if not inFilterMode then
        GUILayout.Label("---------------- RenderTextureFormat -----------------")
    end
    for _,i in ipairs(self._renderTextureFormats) do
        if (not inFilterMode) or string.find(i[3], filter) then
            GUILayout.Label(string.format("%s:%s", i[1], i[2]))
        end
    end
    if not inFilterMode then
        GUILayout.Label("---------------- GraphicsFormat -----------------")
    end
    for _,i in ipairs(self._graphicsFormats) do
        if (not inFilterMode) or string.find(i[3], filter) then
            GUILayout.Label(string.format("%s:%s", i[1], i[2]))
        end
    end
    if not inFilterMode then
        GUILayout.Label("---------------- DefaultFormat -----------------")
    end
    for _,i in ipairs(self._defaultFormats) do
        if (not inFilterMode) or string.find(i[3], filter) then
            GUILayout.Label(string.format("%s:%s", i[1], i[2]))
        end
    end
end

function GMPageSupportedFeatures:Copy()
    local toCopy = {}
    for _,i in ipairs(self.InfoCollection) do
        local content = i[2]()
        if nil == content then
            table.insert(toCopy, i[1])
        else
            table.insert(toCopy,string.format("%s:%s", i[1], content))
        end
    end
    table.insert(toCopy, "---------------- TextureFormat -----------------")
    for _,i in ipairs(self._textureFormats) do
        table.insert(toCopy, string.format("%s:%s", i[1], i[2]))
    end
    table.insert(toCopy, "---------------- RenderTextureFormat -----------------")
    for _,i in ipairs(self._renderTextureFormats) do
        table.insert(toCopy, string.format("%s:%s", i[1], i[2]))
    end
    table.insert(toCopy, "---------------- GraphicsFormat -----------------")
    for _,i in ipairs(self._graphicsFormats) do
        table.insert(toCopy, string.format("%s:%s", i[1], i[2]))
    end
    table.insert(toCopy, "---------------- DefaultFormat -----------------")
    for _,i in ipairs(self._defaultFormats) do
        table.insert(toCopy, string.format("%s:%s", i[1], i[2]))
    end
    UnityEngine.GUIUtility.systemCopyBuffer = table.concat(toCopy, '\n')
end

return GMPageSupportedFeatures