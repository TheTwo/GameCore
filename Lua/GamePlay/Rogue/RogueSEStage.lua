---@class RogueSEStage
---@field new fun(seEnvironment):RogueSEStage
local RogueSEStage = class("RogueSEStage")
local RogueSERoom = require("RogueSERoom")
local Utils = require("Utils")
local LoadingState = {
    None = 0,
    LoadAsset = 1,
    AllRoomLoaded = 2,
}

---@param scene RogueSEScene
---@param seEnvironment SEEnvironment
function RogueSEStage:ctor(scene, seEnvironment)
    self.scene = scene
    self.seEnvironment = seEnvironment
    self.width = 0
    self.height = 0
    ---@type table<number, RogueSERoom> @key:row * 100 + column
    self.rooms = nil
    ---@type table<RogueSERoom, boolean>
    self.notLoadedRoom = nil
    self.loadingState = LoadingState.None
    ---@type CS.UnityEngine.Transform
    self.rootTrans = nil
    ---@type CS.DynamicNavmeshBuilder
    self.dynamicNavmeshBuilder = nil
end

function RogueSEStage:InitRoom()
    self.width = 4
    self.height = 5
    self.rooms = {}
    for i = 1, self.width do
        for j = 1, self.height do
            if self:HasRoomAt(i, j) then 
                local room = RogueSERoom.new(self, i, j)
                self.rooms[i * 100 + j] = room
            end
        end
    end
end

function RogueSEStage:Release()
    self:DestroyNavmesh()
    self:UnloadRoomsAsset()
    self:DestroyRoot()
    self.rooms = nil
    self.notLoadedRoom = nil
    self.loadingState = LoadingState.None
end

function RogueSEStage:LoadRoomsAsset()
    self.loadingState = LoadingState.LoadAsset
    self:CreateRootIfNeed()
    self.notLoadedRoom = {}
    for _, room in pairs(self.rooms) do
        room:UnloadAsset()
        self.notLoadedRoom[room] = true
    end

    for _, room in pairs(self.rooms) do
        room:LoadAsset()
    end
end

function RogueSEStage:UnloadRoomsAsset()
    if self.loadingState == LoadingState.None then return end

    for _, room in pairs(self.rooms) do
        room:UnloadAsset()
    end
    self.loadingState = LoadingState.None
end

---@param room RogueSERoom
function RogueSEStage:OnRoomLoaded(room)
    if self.loadingState ~= LoadingState.LoadAsset then
        room:UnloadAsset()
        return
    end

    self.notLoadedRoom[room] = nil
    
    if next(self.notLoadedRoom) == nil then
        self:AllRoomLoaded() 
    end
end

---@private
function RogueSEStage:HasRoomAt(x, y)
    ---TODO:基于wds数据返回是否在[row:x, column:y]有房间
    return false
end

function RogueSEStage:AllRoomLoaded()
    self.loadingState = LoadingState.AllRoomLoaded
    
    self:RebuildNavmeshData()
end

function RogueSEStage:CreateRootIfNeed()
    if Utils.IsNotNull(self.rootTrans) then return end

    local gameObj = CS.UnityEngine.GameObject(self:GetStageName())
    gameObj.layer = CS.UnityEngine.LayerMask.NameToLayer("SEFloor")
    self.rootTrans = gameObj.transform
    self.rootTrans:SetPositionAndRotation(CS.UnityEngine.Vector3.zero, CS.UnityEngine.Quaternion.identity)
    self.rootTrans:SetParent(self.seEnvironment:GetMapRoot())
    self.rootTrans.localScale = CS.UnityEngine.Vector3.one
end

function RogueSEStage:DestroyRoot()
    if Utils.IsNotNull(self.rootTrans) then return end
    CS.UnityEngine.Object.Destroy(self.rootTrans.gameObject)
    self.rootTrans = nil
end

function RogueSEStage:GetStageName()
    return "StageName"
end

---@return CS.UnityEngine.Transform
function RogueSEStage:GetRootTransform()
    return self.rootTrans
end

function RogueSEStage:RebuildNavmeshData()
    local builderComp = self.rootTrans:GetComponent(typeof(CS.DynamicNavmeshBuilder))
    if Utils.IsNull(builderComp) then
        g_Logger.ErrorChannel("RogueSEStage", "RebuildNavmeshData failed, DynamicNavmeshBuilder is required")
        return false
    end

    builderComp:InitOnce()
    builderComp:Clear()
    for _, room in pairs(self.rooms) do
        if room.handle then
            builderComp:AppendSource(room.handle)
        end
    end
    self.dynamicNavmeshBuilder = builderComp
end

function RogueSEStage:DestroyNavmesh()
    if Utils.IsNull(self.dynamicNavmeshBuilder) then return end

    self.dynamicNavmeshBuilder:Release()
    self.dynamicNavmeshBuilder = nil
end

return RogueSEStage