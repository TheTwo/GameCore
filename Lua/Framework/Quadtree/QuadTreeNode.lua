---@class QuadTreeNode
---@field new fun(rect, maxObjects, maxLevel, level):QuadTreeNode
---@field trees QuadTreeNode[]
---@field children QuadTreeLeaf[]
local QuadTreeNode = class("QuadTreeNode")
local Rect = require("Rect")
local QueryBuffer = {}

local QuadRant = {
    UR = 1, -- 第一象限
    UL = 2, -- 第二象限
    LL = 3, -- 第三象限
    LR = 4, -- 第四象限
}

---@param rect Rect
---@param maxObjects number 每个节点最大叶子数
---@param maxLevel number 最大层级
---@param level number 当前层级
function QuadTreeNode:ctor(rect, maxObjects, maxLevel, level)
    self.rect = rect
    self.maxObjects = maxObjects or 8
    self.maxLevel = maxLevel or 4
    self.level = level or 1
    self.trees = {}
    self.children = {}
end

function QuadTreeNode:Split()
    local width = self.rect.sizeX / 2
    local height = self.rect.sizeY / 2
    
    self.trees[QuadRant.UR] = QuadTreeNode.new(Rect.new(self.rect.x + width, self.rect.y + height, width, height), self.maxObjects, self.maxLevel, self.level + 1)
    self.trees[QuadRant.UL] = QuadTreeNode.new(Rect.new(self.rect.x, self.rect.y + height, width, height), self.maxObjects, self.maxLevel, self.level + 1)
    self.trees[QuadRant.LL] = QuadTreeNode.new(Rect.new(self.rect.x, self.rect.y, width, height), self.maxObjects, self.maxLevel, self.level + 1)
    self.trees[QuadRant.LR] = QuadTreeNode.new(Rect.new(self.rect.x + width, self.rect.y, width, height), self.maxObjects, self.maxLevel, self.level + 1)
end

---@param rect Rect
function QuadTreeNode:GetTreeIdx(rect)
    local treeIdxs = {}

    if self.trees[QuadRant.UR].rect:Intersect(rect) then
        table.insert(treeIdxs, QuadRant.UR)
    end
    if self.trees[QuadRant.UL].rect:Intersect(rect) then
        table.insert(treeIdxs, QuadRant.UL)
    end
    if self.trees[QuadRant.LL].rect:Intersect(rect) then
        table.insert(treeIdxs, QuadRant.LL)
    end
    if self.trees[QuadRant.LR].rect:Intersect(rect) then
        table.insert(treeIdxs, QuadRant.LR)
    end
    return treeIdxs
end

---@param leaf QuadTreeLeaf
function QuadTreeNode:Insert(leaf)
    if self.trees and #self.trees > 0 then
        local idxs = self:GetTreeIdx(leaf.rect)
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
            local idxs = self:GetTreeIdx(subLeaf.rect)
            for _, idx in ipairs(idxs) do
                self.trees[idx]:Insert(subLeaf)
            end
        end
    end
end

function QuadTreeNode:Remove(leaf)
    if self.trees and #self.trees > 0 then
        local idxs = self:GetTreeIdx(leaf.rect)
        for _, idx in ipairs(idxs) do
            self.trees[idx]:Remove(leaf)
        end
        return
    end
    table.removebyvalue(self.children, leaf)
end

function QuadTreeNode:Clear()
    for _, tree in pairs(self.trees) do
        tree:Clear()
    end
    table.clear(self.children)
end

function QuadTreeNode:Query(rect)
    return self:SearchByRect(rect, true)
end

---@param rect Rect
---@return QuadTreeLeaf[]
function QuadTreeNode:SearchByRect(rect, skipSort, results)
    table.clear(QueryBuffer)
    local retHash = self:SearchByRectImp(rect, QueryBuffer)

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
        local cx, cy = rect:Center()
        table.sort(ret, function(l, r)
            local lcx, lcy = l.rect:Center()
            local rcx, rcy = r.rect:Center()
            return ((lcx - cx) ^ 2 + (lcy - cy) ^ 2) < ((rcx - cx) ^ 2 + (rcy - cy) ^ 2)
        end)
    end
    return ret
end

---@param rect Rect
---@return QuadTreeLeaf[]
function QuadTreeNode:SearchByRectImp(rect, results)
    results = results or {}
    if #self.trees == 0 then
        for k, v in pairs(self.children) do
            if v.rect:Intersect(rect) then
                results[v] = v
            end
        end
        return results;
    end
    
    if #self.trees > 0 then
        local idxs = self:GetTreeIdx(rect)
        for _, idx in ipairs(idxs) do
            self.trees[idx]:SearchByRectImp(rect, results)
        end
    end
    return results
end

---@return QuadTreeLeaf[]
function QuadTreeNode:SearchByPoint(x, y)
    local retHash = self:SearchByPointImp(x, y, {})
    local ret = {}
    for _, v in pairs(retHash) do
        table.insert(ret, v)
    end
    table.sort(ret, function(l, r)
        local lcx, lcy = l.rect:Center()
        local rcx, rcy = r.rect:Center()
        return ((lcx - x) ^ 2 + (lcy - y) ^ 2) < ((rcx - x) ^ 2 + (rcy - y) ^ 2)
    end)
    return ret
end

---@return QuadTreeLeaf[]
function QuadTreeNode:SearchByPointImp(x, y, results)
    results = results or {}
    if #self.trees == 0 then
        for k, v in pairs(self.children) do
            results[v] = v
        end
        return results;
    end
    
    local rect = Rect.new(x, y, 0, 0)
    if #self.trees > 0 then
        local idxs = self:GetTreeIdx(rect)
        for _, idx in ipairs(idxs) do
            self.trees[idx]:SearchByPointImp(x, y, results)
        end
    end
    return results
end

return QuadTreeNode