---@class BehaviourTreeTest
---@field new fun():BehaviourTreeTest
local BehaviourTreeTest = class("BehaviourTreeTest")
local BehaviourTree = require("BehaviourTree")
local Delegate = require("Delegate")

function BehaviourTreeTest:ctor()
    local leftSequence = require("SequenceNode").new();
    local leftChild1 = require("NodeBase").new();
    local leftChild2 = require("WaitNode").new(4);
    leftSequence:AppendNode(leftChild1)
    leftSequence:AppendNode(leftChild2)

    local left = require("InvertNode").new(leftSequence);

    local right = require("SequenceNode").new();
    local rightChild1 = require("NodeBase").new();
    local rightChild2 = require("WaitNode").new(2.5);
    right:AppendNode(rightChild1)
    right:AppendNode(rightChild2);

    local root = require("SelectorNode").new();
    root:AppendNode(left);
    root:AppendNode(right);

    self.tree = BehaviourTree.new(root);
end

function BehaviourTreeTest:Start()
    g_Game:AddSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
    self.tick = 0;
end

function BehaviourTreeTest:OnTick()
    self.tick = self.tick + 1;
    if self["BeforeOnTick"..self.tick] then
        self["BeforeOnTick"..self.tick](self);
    end
    self.tree:Update();
    if self["AfterOnTick"..self.tick] then
        self["AfterOnTick"..self.tick](self);
    end
end

function BehaviourTreeTest:Stop()
    g_Game:RemoveSecondTicker(Delegate.GetOrCreate(self, self.OnTick))
end

function BehaviourTreeTest:BeforeOnTick1()
    local root = self.tree.root;

    assert(root.state == -1);
    assert(root.depth == 0);
    
    local l1 = root.children[1]
    local r1 = root.children[2]

    assert(l1.state == -1)
    assert(l1.depth == 1)
    assert(r1.state == -1)
    assert(r1.depth == 1)

    local l2 = l1.child;
    assert(l2.state == -1)
    assert(l2.depth == 2);

    local r2_1 = r1.children[1];
    local r2_2 = r1.children[2];
    assert(r2_1.state == -1)
    assert(r2_1.depth == 2)
    assert(r2_2.state == -1)
    assert(r2_2.depth == 2)

    local l3_1 = l2.children[1];
    local l3_2 = l2.children[2];
    assert(l3_1.state == -1)
    assert(l3_1.depth == 3)
    assert(l3_2.state == -1)
    assert(l3_2.depth == 3)
    print("Finish Before Tick1 Check")
end

function BehaviourTreeTest:AfterOnTick1()
    local root = self.tree.root;

    assert(root.state == 1);
    
    local l1 = root.children[1]
    local r1 = root.children[2]

    assert(l1.state == 1)
    assert(r1.state == -1)

    local l2 = l1.child;
    assert(l2.state == 1)

    local r2_1 = r1.children[1];
    local r2_2 = r1.children[2];
    assert(r2_1.state == -1)
    assert(r2_2.state == -1)

    local l3_1 = l2.children[1];
    local l3_2 = l2.children[2];
    assert(l3_1.state == 2)
    assert(l3_2.state == 1)
    print("Finish After Tick1 Check")
end

function BehaviourTreeTest:AfterOnTick4()
    self:Stop()
    print("Finish Check");
end

local node = BehaviourTreeTest.new();
node:Start();