---@class RogueSERoom
---@field new fun():RogueSERoom
local RogueSERoom = class("RogueSERoom")
local ModuleRefer = require("ModuleRefer")
local Delegate = require("Delegate")
local Utils = require("Utils")

---@param stage RogueSEStage
function RogueSERoom:ctor(stage)
    self.stage = stage
    self.loaded = false
    ---@type CS.DragonReborn.AssetTool.PooledGameObjectHandle
    self.handle = nil
end

function RogueSERoom:GetAssetName()
    
end

function RogueSERoom:LoadAsset()
    if self:Loaded() then return end

    local assetName = self:GetAssetName()
    if string.IsNullOrEmpty(assetName) then return end

    local helper = ModuleRefer.RogueSEModule:GetPooledCreateHelper()
    self.handle = helper:Create(assetName, self.stage:GetRootTransform(), Delegate.GetOrCreate(self, self.OnAssetLoaded))
end

function RogueSERoom:UnloadAsset()
    self.loaded = false
end

function RogueSERoom:OnAssetLoaded(go, userdata, handle)
    if Utils.IsNull(go) then return end

    self.loaded = true
    self.stage:OnRoomLoaded(self)
end

function RogueSERoom:Loaded()
    return self.loaded
end

return RogueSERoom