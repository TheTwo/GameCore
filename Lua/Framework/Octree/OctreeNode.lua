---@class OctreeNode @八叉树, 三轴正交右手坐标系, X为水平面向右，Z为水平面向前, Y为垂直向上
---@field new fun(bounds, maxObjects, maxLevel, level):OctreeNode
---@field trees OctreeNode[]
---@field children OctreeLeaf[]
local OctreeNode = class("OctreeNode")
local Bounds = require("Bounds")
local QueryBuffer = {}

local OctRant = {
    URT = 1, -- 上-第一象限
    ULT = 2, -- 上-第二象限
    LLT = 3, -- 上-第三象限
    LRT = 4, -- 上-第四象限

    URB = 5, -- 下-第一象限
    ULB = 6, -- 下-第二象限
    LLB = 7, -- 下-第三象限
    LRB = 8, -- 下-第四象限
}

---@param bounds Bounds
---@param maxObjects number 每个节点最大叶子数
---@param maxLevel number 最大层级
---@param level number 当前层级
function OctreeNode:ctor(bounds, maxObjects, maxLevel, level)
    self.bounds = bounds
    self.maxObjects = maxObjects or 8
    self.maxLevel = maxLevel or 4
    self.level = level or 1
    self.trees = {}
    self.children = {}
end

function OctreeNode:Split()
    local halfSizeX = self.bounds.sizeX / 2
    local halfSizeY = self.bounds.sizeY / 2
    local halfSizeZ = self.bounds.sizeZ / 2
    
    self.trees[OctRant.URT] = OctreeNode.new(Bounds.new(self.bounds.x + halfSizeX, self.bounds.y + halfSizeY, self.bounds.z + halfSizeZ, halfSizeX, halfSizeY, halfSizeZ), self.maxObjects, self.maxLevel, self.level + 1)
    self.trees[OctRant.ULT] = OctreeNode.new(Bounds.new(self.bounds.x, self.bounds.y + halfSizeY, self.bounds.z + halfSizeZ, halfSizeX, halfSizeY, halfSizeZ), self.maxObjects, self.maxLevel, self.level + 1)
    self.trees[OctRant.LLT] = OctreeNode.new(Bounds.new(self.bounds.x, self.bounds.y + halfSizeY, self.bounds.z, halfSizeX, halfSizeY, halfSizeZ), self.maxObjects, self.maxLevel, self.level + 1)
    self.trees[OctRant.LRT] = OctreeNode.new(Bounds.new(self.bounds.x + halfSizeX, self.bounds.y + halfSizeY, self.bounds.z, halfSizeX, halfSizeY, halfSizeZ), self.maxObjects, self.maxLevel, self.level + 1)

    self.trees[OctRant.URB] = OctreeNode.new(Bounds.new(self.bounds.x + halfSizeX, self.bounds.y, self.bounds.z + halfSizeZ, halfSizeX, halfSizeY, halfSizeZ), self.maxObjects, self.maxLevel, self.level + 1)
    self.trees[OctRant.ULB] = OctreeNode.new(Bounds.new(self.bounds.x, self.bounds.y, self.bounds.z + halfSizeZ, halfSizeX, halfSizeY, halfSizeZ), self.maxObjects, self.maxLevel, self.level + 1)
    self.trees[OctRant.LLB] = OctreeNode.new(Bounds.new(self.bounds.x, self.bounds.y, self.bounds.z, halfSizeX, halfSizeY, halfSizeZ), self.maxObjects, self.maxLevel, self.level + 1)
    self.trees[OctRant.LRB] = OctreeNode.new(Bounds.new(self.bounds.x + halfSizeX, self.bounds.y, self.bounds.z, halfSizeX, halfSizeY, halfSizeZ), self.maxObjects, self.maxLevel, self.level + 1)
end

---@param bounds Bounds
function OctreeNode:GetTreeIdx(bounds)
    local treeIdxs = {}

    if self.trees[OctRant.URT].bounds:Intersect(bounds) then
        table.insert(treeIdxs, OctRant.URT)
    end
    if self.trees[OctRant.ULT].bounds:Intersect(bounds) then
        table.insert(treeIdxs, OctRant.ULT)
    end
    if self.trees[OctRant.LLT].bounds:Intersect(bounds) then
        table.insert(treeIdxs, OctRant.LLT)
    end
    if self.trees[OctRant.LRT].bounds:Intersect(bounds) then
        table.insert(treeIdxs, OctRant.LRT)
    end
    if self.trees[OctRant.URB].bounds:Intersect(bounds) then
        table.insert(treeIdxs, OctRant.URB)
    end
    if self.trees[OctRant.ULB].bounds:Intersect(bounds) then
        table.insert(treeIdxs, OctRant.ULB)
    end
    if self.trees[OctRant.LLB].bounds:Intersect(bounds) then
        table.insert(treeIdxs, OctRant.LLB)
    end
    if self.trees[OctRant.LRB].bounds:Intersect(bounds) then
        table.insert(treeIdxs, OctRant.LRB)
    end
    return treeIdxs
end

---@param leaf OctreeLeaf
function OctreeNode:Insert(leaf)
    if self.trees and #self.trees > 0 then
        local idxs = self:GetTreeIdx(leaf.bounds)
        for _, idx in ipairs(idxs) do
            self.trees[idx]:Insert(leaf)
        end
        return
    end

    table.insert(self.children, leaf)

    if #self.children > self.maxObjects and self.level < self.maxLevel then
        self:Split()
        while(#self.children > 0) do
            local subLeaf = table.remove(self.children)
            local idxs = self:GetTreeIdx(subLeaf.bounds)
            for _, idx in ipairs(idxs) do
                self.trees[idx]:Insert(subLeaf)
            end
        end
    end
end

---@param leaf OctreeLeaf
function OctreeNode:Remove(leaf)
    if self.trees and #self.trees > 0 then
        local idxs = self:GetTreeIdx(leaf.bounds)
        for _, idx in ipairs(idxs) do
            self.trees[idx]:Remove(leaf)
        end
        return
    end
    table.removebyvalue(self.children, leaf)
end

function OctreeNode:Clear()
    for _, tree in pairs(self.trees) do
        tree:Clear()
    end
    table.clear(self.children)
end

---@param bounds Bounds
function OctreeNode:Query(bounds)
    return self:SearchByBounds(bounds, true)
end

---@param bounds Bounds
---@return OctreeLeaf[]
function OctreeNode:SearchByBounds(bounds, skipSort, results)
    table.clear(QueryBuffer)
    local retHash = self:SearchByBoundsImp(bounds, QueryBuffer)

    local ret = results
    if ret then
        table.clear(ret)
    else
        ret = {}
    end
    
    for _, v in pairs(retHash) do
        table.insert(ret, v)
    end
    if not skipSort then
        local cx, cy, cz = bounds:Center()
        table.sort(ret, function(l, r)
            local lcx, lcy, lcz = l.bounds:Center()
            local rcx, rcy, rcz = r.bounds:Center()
            return ((lcx - cx) ^ 2 + (lcy - cy) ^ 2 + (lcz - cz) ^ 2) < ((rcx - cx) ^ 2 + (rcy - cy) ^ 2 + (rcz - cz) ^ 2)
        end)
    end
    return ret
end

---@param bounds Bounds
---@return OctreeLeaf[]
function OctreeNode:SearchByBoundsImp(bounds, results)
    results = results or {}
    if #self.trees == 0 then
        for k, v in pairs(self.children) do
            if v.bounds:Intersect(bounds) then
                results[v] = v
            end
        end
        return results;
    end
    
    if #self.trees > 0 then
        local idxs = self:GetTreeIdx(bounds)
        for _, idx in ipairs(idxs) do
            self.trees[idx]:SearchByBoundsImp(bounds, results)
        end
    end
    return results
end

---@return OctreeLeaf[]
function OctreeNode:SearchByPoint(x, y, z)
    local retHash = self:SearchByPointImp(x, y, z, {})
    local ret = {}
    for _, v in pairs(retHash) do
        table.insert(ret, v)
    end
    table.sort(ret, function(l, r)
        local lcx, lcy, lcz = l.bounds:Center()
        local rcx, rcy, rcz = r.bounds:Center()
        return ((lcx - x) ^ 2 + (lcy - y) ^ 2 + (lcz - z) ^ 2) < ((rcx - x) ^ 2 + (rcy - y) ^ 2 + (rcz - z) ^ 2)
    end)
    return ret
end

---@return OctreeLeaf[]
function OctreeNode:SearchByPointImp(x, y, z, results)
    results = results or {}
    if #self.trees == 0 then
        for k, v in pairs(self.children) do
            results[v] = v
        end
        return results;
    end
    
    local bounds = Bounds.new(x, y, z, 0, 0, 0)
    if #self.trees > 0 then
        local idxs = self:GetTreeIdx(bounds)
        for _, idx in ipairs(idxs) do
            self.trees[idx]:SearchByPointImp(x, y, results)
        end
    end
    return results
end

return OctreeNode