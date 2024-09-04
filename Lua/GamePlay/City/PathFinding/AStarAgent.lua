---@type CS.AstarPath
local AstarPath = CS.AstarPath
---@type CS.DragonReborn.Utilities.FindSmoothAStarPathHelper
local FindSmoothAStarPathHelper = CS.DragonReborn.Utilities.FindSmoothAStarPathHelper

local Utils = require("Utils")

---@class AStarAgent
---@field new fun():AStarAgent
local AStarAgent = class("AStarAgent")

---@param root CS.UnityEngine.GameObject
function AStarAgent:ctor()
    self.active = AstarPath.active
end

function AStarAgent:Release()
    if Utils.IsNotNull(self.active) and Utils.IsNotNull(self.active.data) and Utils.IsNotNull(self.graph) then
        self.active.data:RemoveGraph(self.graph)
    end
    self.graph = nil
    self.active = nil
end

function AStarAgent:Initialize(center, width, height, nodeSize, walkable)
    if width * height ~= #walkable then
        error("Grid Size not match")
    end

    self.width = width
    self.height = height

    ---@type CS.Pathfinding.GridGraph
    self.graph = self.active.data:AddGraph(typeof(CS.Pathfinding.GridGraph))
    self.graph.center = center
    self.graph:SetDimensions(width, height, nodeSize)

    --- custom setting may be removed
    self.graph.collision.collisionCheck = false
    self.graph.collision.heightCheck = false

    self.active:AddWorkItem(function()
        local graph = self.graph
        for x = 1, width do
            for y = 1, height do
                local node = graph:GetNode(x-1, y-1)
                node.Walkable = walkable[x + (y-1)*width]
            end
        end
    end)

    -- 首次初始化会重建连通性
    AstarPath.active:Scan()
end

function AStarAgent:UpdateWalkable(x, y, flag)
    local node = self.graph:GetNode(x-1, y-1)
    node.Walkable = flag
    self.graph:CalculateConnectionsForCellAndNeighbours(x-1, y-1)
end

---@return CS.UnityEngine.Vector3 @ nil
function AStarAgent:RandomPositionOnGraph()
    if (not self.active) or (not self.graph) then
        return nil
    end
    local x = math.random(0, self.width -1)
    local y = math.random(0, self.height - 1)
    local node = self.graph:GetNode(x, y)
    local pos = node:RandomPointOnSurface()
    local info = self.active:GetNearest(pos, CS.Pathfinding.NNConstraint.Default)
    if Utils.IsNull(info.node) then
        return nil
    end
    return info.position
end

---@param position CS.UnityEngine.Vector3
---@return CS.UnityEngine.Vector3 @ nil
function AStarAgent:NearestWalkableOnGraph(position)
    if (not self.active) or (not self.graph) then
        return nil
    end
    local info = self.active:GetNearest(position, CS.Pathfinding.NNConstraint.Default)
    if Utils.IsNull(info.node) then
        return nil
    end
    return info.position
end

---@param startPos CS.UnityEngine.Vector3
---@param endPos CS.UnityEngine.Vector3
---@param callback fun(waypoints:CS.UnityEngine.Vector3[])
---@return CS.DragonReborn.Utilities.FindSmoothAStarPathHelper.PathHelperHandle
function AStarAgent:FindPath(startPos, endPos, callback)
    return FindSmoothAStarPathHelper.FindPath(startPos, endPos, function(path) 
        local param = {}
        if Utils.IsNotNull(path) then
            for _, v in pairs(path) do
                table.insert(param, v)
            end
        end
        if callback then
            callback(param)
        end
    end)
end

---@param startPos CS.UnityEngine.Vector3
---@param length number
---@param callback fun(waypoints:CS.UnityEngine.Vector3[])
---@return CS.DragonReborn.Utilities.FindSmoothAStarPathHelper.PathHelperHandle
function AStarAgent:RandomPath(startPos, length, callback)
    return FindSmoothAStarPathHelper.RandomPath(startPos, length, function(path) 
        local param = {}
        if Utils.IsNotNull(path) then
            for _, v in pairs(path) do
                table.insert(param, v)
            end
        end
        if callback then
            callback(param)
        end
    end)
end

return AStarAgent