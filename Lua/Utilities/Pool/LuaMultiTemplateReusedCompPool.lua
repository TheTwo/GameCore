---@class MultiTemplateReusedPool
---@field name string
---@field template CS.UnityEngine.GameObject
---@field componentType CS.System.Type
---@field reusedList CS.UnityEngine.GameObject[]|CS.UnityEngine.Component[]
---@field index number
---@field parent CS.UnityEngine.Transform
---@field isLua boolean
local MultiTemplateReusedPool = sealedClass("MultiTemplateReusedPool")
local Utils = require("Utils")
local UIHelper = require("UIHelper")

function MultiTemplateReusedPool:ctor(name, template, componentType, reusedList, index, parent, isLua, isGameObj)
    self.name = name
    self.template = template
    self.componentType = componentType
    self.reusedList = reusedList
    self.index = index
    self.parent = parent
    self.isLua = isLua or false
    self.isGameObj = isGameObj or false
end

---@return CS.UnityEngine.GameObject|CS.UnityEngine.Component|BaseUIComponent
function MultiTemplateReusedPool:Alloc()
    if Utils.IsNull(self.template) then
        g_Logger.ErrorChannel("MultiTemplateReusedPool", "MultiTemplateReusedPool:Alloc template is null")
        return nil
    end

    if self.index >= #self.reusedList then
        if not self.isLua then
            local item = CS.UnityEngine.Object.Instantiate(self.template, self.parent)
            table.insert(self.reusedList, item)
        else
            local item = UIHelper.DuplicateUIGameObject(self.template, self.parent)
            table.insert(self.reusedList, item)
        end
    end

    self.index = self.index + 1
    local ret = self.reusedList[self.index]
    ret:SetActive(true)
    ret.transform:SetAsLastSibling()
    if self.isLua then
        return ret:GetComponent(self.componentType).Lua
    elseif self.componentType ~= nil then
        return ret:GetComponent(self.componentType)
    else
        return ret
    end
end

function MultiTemplateReusedPool:Recycle(node)
    local gameObj
    if self.isLua then
        gameObj = node.CSComponent.gameObject
    elseif self.isGameObj then
        gameObj = node
    else
        gameObj = node.gameObject
    end
    gameObj:SetActive(false)

    for i, v in ipairs(self.reusedList) do
        if v == gameObj then
            table.remove(self.reusedList, i)
            self.index = self.index - 1
            break
        end
    end
    
    table.insert(self.reusedList, gameObj)
    if self.isLua then
        UIHelper.SetUIComponentParent(gameObj.transform, self.parent)
    else
        gameObj.transform:SetParent(self.parent)
    end
end

function MultiTemplateReusedPool:HideAll()
    for i = #self.reusedList, 1, -1 do
        local item = self.reusedList[i]
        if Utils.IsNotNull(item) then
            if self.isLua then
                UIHelper.SetUIComponentParent(item:GetComponent(self.componentType), self.parent)
            else
                item.transform:SetParent(self.parent)
            end
            item:SetActive(false)
        else
            table.remove(self.reusedList, i)
        end
    end
    self.index = 0
end

function MultiTemplateReusedPool:Release()
    for _, item in ipairs(self.reusedList) do
        CS.UnityEngine.Object.Destroy(item)
    end
    self.index = 0
end

---@class LuaMultiTemplateReusedCompPool
---@field new fun(transform:CS.UnityEngine.Transform):LuaMultiTemplateReusedCompPool
local LuaMultiTemplateReusedCompPool = sealedClass("LuaMultiTemplateReusedCompPool")

---@param parent CS.UnityEngine.Transform
---@param allowAutoCreate boolean @在回收时，如果没有对应的模板，是否自动创建缓存池
function LuaMultiTemplateReusedCompPool:ctor(parent, allowAutoCreate)
    if Utils.IsNull(parent) then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaReusedComponentPool:ctor parent is null")
        return
    end
    
    self.parent = parent
    self.allowAutoCreate = allowAutoCreate or false
    ---@type table<string, MultiTemplateReusedPool>
    self.pools = {}
end

---@param templateGameObj CS.UnityEngine.GameObject
function LuaMultiTemplateReusedCompPool:GetOrCreateGameObjPool(templateGameObj)
    if Utils.IsNull(templateGameObj) then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:AddGameObjTemplate templateGameObj is null")
        return nil
    end

    local poolName = ("__gameObj:%s"):format(templateGameObj.name)
    if not self.pools[poolName] then
        self.pools[poolName] = MultiTemplateReusedPool.new(poolName, templateGameObj, nil, {}, 0, CS.UnityEngine.GameObject(poolName).transform, false, true)
        self.pools[poolName].parent:SetParent(self.parent)
    elseif not self.pools[poolName].isGameObj then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:AddGameObjTemplate poolName is exist and is not GameObj pool")
        return nil
    else
        self.pools[poolName]:Recycle(templateGameObj)
    end

    templateGameObj.transform:SetParent(self.pools[poolName].parent)
    return self.pools[poolName]
end

---@param component CS.UnityEngine.Component
---@return MultiTemplateReusedPool 可以重复添加同一种类型的模板
function LuaMultiTemplateReusedCompPool:GetOrCreateCSPool(component)
    if Utils.IsNull(component) then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:AddCSCompTemplate component is null")
        return nil
    end

    local templateGameObj = component.gameObject
    local componentType = component:GetType()
    local poolName = ("__csComp:%s"):format(component:GetType().Name)
    if not self.pools[poolName] then
        self.pools[poolName] = MultiTemplateReusedPool.new(poolName, templateGameObj, componentType, {}, 0, CS.UnityEngine.GameObject(poolName).transform)
        self.pools[poolName].parent:SetParent(self.parent)
    elseif self.pools[poolName].isLua then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:AddCSCompTemplate poolName is exist and is lua")
        return nil
    end

    templateGameObj.transform:SetParent(self.pools[poolName].parent)
    return self.pools[poolName]
end

---@param baseUIComponent BaseUIComponent
---@return MultiTemplateReusedPool
function LuaMultiTemplateReusedCompPool:GetOrCreateLuaBaseCompPool(baseUIComponent)
    if baseUIComponent == nil then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:AddLuaBaseCompTemplate baseUIComponent is null")
        return nil
    end

    local component = baseUIComponent.CSComponent
    if Utils.IsNull(component) then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:AddLuaBaseCompTemplate baseUIComponent is not a LuaBaseComponent")
        return nil
    end

    local scriptName = component:LuaScriptPath()
    if string.IsNullOrEmpty(scriptName) then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:AddLuaBaseCompTemplate templateGameObj is not a LuaBaseComponent")
        return nil
    end

    local templateGameObj = component.gameObject
    local poolName = ("__luaBaseComp:%s"):format(scriptName)
    if not self.pools[poolName] then
        self.pools[poolName] = MultiTemplateReusedPool.new(poolName, templateGameObj, typeof(CS.DragonReborn.UI.LuaBaseComponent), {}, 0, CS.UnityEngine.GameObject(poolName).transform, true)
        self.pools[poolName].parent:SetParent(self.parent)
        self.pools[poolName].parent:SetVisible(false)
    elseif not self.pools[poolName].isLua then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:AddLuaBaseCompTemplate poolName is exist and is cs")
        return nil
    end

    templateGameObj.transform:SetParent(self.pools[poolName].parent)
    templateGameObj:SetActive(false)
    return self.pools[poolName]
end

---@param name string
---@return CS.UnityEngine.GameObject
function LuaMultiTemplateReusedCompPool:GetGameObjItem(name)
    if string.IsNullOrEmpty(name) then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:GetGameObjItem name is null")
        return nil
    end

    local poolName = ("__gameObj:%s"):format(name)
    if not self.pools[poolName] then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:GetGameObjItem poolName is not exist")
        return nil
    end

    local pool = self.pools[poolName]
    return pool:Alloc()
end

---@param node CS.UnityEngine.GameObject
function LuaMultiTemplateReusedCompPool:RecycleGameObjItem(node)
    if Utils.IsNull(node) then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:RecycleGameObjItem node is null")
        return false
    end

    local poolName = ("__gameObj:%s"):format(node.name)
    if not self.pools[poolName] then
        if self.allowAutoCreate then
            g_Logger.WarnChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:RecycleGameObjItem poolName is not exist")
            self:GetOrCreateGameObjPool(node)
            return true
        else
            g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:RecycleGameObjItem poolName is not exist")
            return false
        end
    end

    local pool = self.pools[poolName]
    pool:Recycle(node)
    return true
end

---@param componentType CS.System.Type
function LuaMultiTemplateReusedCompPool:GetCSItem(componentType)
    if componentType == nil then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:AddCSCompTemplate componentType is nil")
        return nil
    end

    local poolName = ("__csComp:%s"):format(componentType.Name)
    if not self.pools[poolName] then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:GetCSItem poolName is not exist")
        return nil
    end

    local pool = self.pools[poolName]
    return pool:Alloc()
end

---@param node CS.UnityEngine.Component
function LuaMultiTemplateReusedCompPool:RecyleCSItem(node)
    if Utils.IsNull(node) then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:RecyleCSItem node is null")
        return false
    end

    local poolName = ("__csComp:%s"):format(node:GetType().Name)
    if not self.pools[poolName] then
        if self.allowAutoCreate then
            g_Logger.WarnChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:RecyleCSItem poolName is not exist")
            self:GetOrCreateCSPool(node.gameObject, node:GetType())
            return true
        else
            g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:RecyleCSItem poolName is not exist")
            return false
        end
    end

    local pool = self.pools[poolName]
    pool:Recycle(node)
    return true
end

---@param scriptName string
---@return table
function LuaMultiTemplateReusedCompPool:GetLuaItem(scriptName)
    if string.IsNullOrEmpty(scriptName) then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:GetLuaItem scriptName is null")
        return nil
    end

    local poolName = ("__luaBaseComp:%s"):format(scriptName)
    if not self.pools[poolName] then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:GetLuaItem poolName is not exist")
        return nil
    end

    local pool = self.pools[poolName]
    return pool:Alloc()
end

---@param node CS.DragonReborn.UI.LuaBaseComponent
function LuaMultiTemplateReusedCompPool:RecyleLuaItem(luaTable)
    if luaTable == nil then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:RecyleLuaItem luaTable is null")
        return false
    end

    local node = luaTable.CSComponent
    if Utils.IsNull(node) then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:RecyleLuaItem node is null")
        return false
    end

    local scriptName = node:LuaScriptPath()
    if string.IsNullOrEmpty(scriptName) then
        g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:RecyleLuaItem scriptName is null")
        return false
    end

    local poolName = ("__luaBaseComp:%s"):format(scriptName)
    if not self.pools[poolName] then
        if self.allowAutoCreate then
            g_Logger.WarnChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:RecyleLuaItem poolName is not exist")
            self:GetOrCreateLuaBaseCompPool(node.gameObject)
            return true
        else
            g_Logger.ErrorChannel("LuaMultiTemplateReusedCompPool", "LuaMultiTemplateReusedCompPool:RecyleLuaItem poolName is not exist")
            return false
        end
    end

    local pool = self.pools[poolName]
    pool:Recycle(luaTable)
    return true
end

function LuaMultiTemplateReusedCompPool:ReleaseAllPool()
    for _, pool in pairs(self.pools) do
        pool:Release()
    end
end

function LuaMultiTemplateReusedCompPool:HideAllPool()
    for _, pool in pairs(self.pools) do
        pool:HideAll()
    end
end

return LuaMultiTemplateReusedCompPool