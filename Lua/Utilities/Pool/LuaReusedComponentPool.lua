---@class LuaReusedComponentPool
---@field new fun(node:CS.UnityEngine.GameObject|CS.UnityEngine.Component, parent:CS.UnityEngine.Transform)
---@field inPoolList CS.UnityEngine.GameObject[]|CS.UnityEngine.Component[]
---@field inUseMap table<CS.UnityEngine.GameObject|CS.UnityEngine.Component, CS.UnityEngine.GameObject|CS.UnityEngine.Component>
local LuaReusedComponentPool = class("LuaReusedComponentPool")
local Utils = require("Utils")
local UIHelper = require("UIHelper")

---@param node CS.UnityEngine.GameObject|CS.UnityEngine.Component
---@param parent CS.UnityEngine.Transform
function LuaReusedComponentPool:ctor(node, parent)
    if Utils.IsNull(node) then
        g_Logger.ErrorChannel("LuaReusedComponentPool", "LuaReusedComponentPool:ctor node is null")
        return
    end

    self.template = node;
    self.parent = parent or node.transform.parent;

    self.inPoolList = {}
    self.inPoolCount = 0
    self.inUseMap = {}
    self.inUseCount = 0

    self.clsType = self.template:GetType();
    self.isGameObject = self.clsType == typeof(CS.UnityEngine.GameObject);
    self.isLuaBaseComponent = self.clsType == typeof(CS.DragonReborn.UI.LuaBaseComponent);
    if self.isLuaBaseComponent then
        self.luaScriptName = self.template:LuaScriptPath()
    end

    local childCount = self.parent.childCount;
    for i = 0, childCount - 1 do
        local child = self.parent:GetChild(i).gameObject;
        if not self.isGameObject then
            child = child:GetComponent(self.clsType);
        end
        if Utils.IsNotNull(child) then
            if not self.isLuaBaseComponent then
                table.insert(self.inPoolList, child);
            elseif self.luaScriptName == child:LuaScriptPath() then
                table.insert(self.inPoolList, child);
            end

            if self.isLuaBaseComponent then
                child.Lua:SetVisible(false)
            else
                child:SetVisible(false);
            end
            self.inPoolCount = self.inPoolCount + 1
        end
    end
end

function LuaReusedComponentPool:HideAll()
    if self.inUseCount == 0 then return end

    self:ClearNullItem()
    for _, v in pairs(self.inUseMap) do
        if self.isLuaBaseComponent then
            v.Lua:SetVisible(false)
        else
            v:SetVisible(false)
        end
        v.transform:SetParent(self.parent, false)
        table.insert(self.inPoolList, v)

        self.inPoolCount = self.inPoolCount + 1
    end

    self.inUseMap = {}
    self.inUseCount = 0
end

function LuaReusedComponentPool:Release()
    -- self.template = nil
    -- self.parent = nil
    -- self.clsType = nil

    self.inPoolList = {}
    self.inPoolCount = 0
    self.inUseMap = {}
    self.inUseCount = 0
end

---@private
function LuaReusedComponentPool:TryGetItemFromPool()
    while self.inPoolCount > 0 do
        local ret = table.remove(self.inPoolList, self.inPoolCount)
        self.inPoolCount = self.inPoolCount - 1

        if Utils.IsNotNull(ret) then
            self.inUseMap[ret] = ret
            self.inUseCount = self.inUseCount + 1
            if self.isLuaBaseComponent then
                ret.Lua:SetVisible(true)
            else
                ret:SetVisible(true)
            end
            ret.transform:SetAsLastSibling()
            return ret
        end
    end
    return nil
end

---@private
function LuaReusedComponentPool:DuplicateNewItem()
    local template = self.template
    if Utils.IsNull(template) then
        g_Logger.ErrorChannel("LuaReusedComponentPool", "LuaReusedComponentPool:DuplicateNewItem template is null")
        return nil
    end
    if not self.isGameObject then
        template = template.gameObject
    end
    if Utils.IsNull(template) then
        g_Logger.ErrorChannel("LuaReusedComponentPool", "LuaReusedComponentPool:DuplicateNewItem template.gameObject is null")
        return nil
    end
    local ret = UIHelper.DuplicateUIGameObject(template, self.parent);
    if Utils.IsNull(ret) then
        g_Logger.ErrorChannel("LuaReusedComponentPool", "(ret is null, template %s, self.parent %s)", (Utils.IsNull(template) and "is null" or "not null"), (Utils.IsNull(self.parent) and "is null" or "not null"))
        return nil
    end

    if not self.isGameObject then
        ret = ret:GetComponent(self.clsType)
    end
    self.inUseMap[ret] = ret
    self.inUseCount = self.inUseCount + 1
    if self.clsType == typeof(CS.DragonReborn.UI.LuaBaseComponent) then
        local lua = ret.Lua
        lua:SetVisible(true)
    else
        ret:SetVisible(true)
    end
    ret.transform:SetAsLastSibling()
    return ret
end

function LuaReusedComponentPool:GetItem()
    local ret = self:TryGetItemFromPool()
    if ret == nil then
        ret = self:DuplicateNewItem()
    end
    return ret;
end

function LuaReusedComponentPool:Recycle(item)
    if Utils.IsNull(item) then
        g_Logger.ErrorChannel("LuaReusedComponentPool", "LuaReusedComponentPool:Recycle item is null")
        return
    end

    if self.inUseCount == 0 then return end

    self:ClearNullItem()

    if self.inUseMap[item] == item then
        self.inUseMap[item] = nil
        self.inUseCount = self.inUseCount - 1

        if self.isLuaBaseComponent then
            item.Lua:SetVisible(false)
        else
            item:SetVisible(false)
        end
        item.transform:SetParent(self.parent, false)
        table.insert(self.inPoolList, item)
        self.inPoolCount = self.inPoolCount + 1
    end
end

function LuaReusedComponentPool:ClearNullItem()
    local toRemove = {}
    for k, v in pairs(self.inUseMap) do
        if Utils.IsNull(v) then
            table.insert(toRemove, k)
        end
    end

    for _, v in ipairs(toRemove) do
        self.inUseMap[v] = nil
        self.inUseCount = self.inUseCount - 1
    end
end

return LuaReusedComponentPool