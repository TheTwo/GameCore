--    Author:	ZhangYang
--    Date:	2021-12-16
--    Description:	脚本描述

local BaseManager = require("BaseManager")

---@class ModuleManager
---@field new fun():ModuleManager
local ModuleManager = class("ModuleManager", BaseManager)

function ModuleManager:ctor()
    self.moduleMap = {}
end

local function _retrieveImp(name)
    local cls = require(name);
    local inst = cls.new();
    inst:OnRegister();
    return inst;
end

---@param name string Module名字
---@return BaseModule 返回一个Module实例
function ModuleManager:RetrieveModule(name)
    if not self.moduleMap[name] then
        local error, inst = try_catch_traceback_with_vararg(_retrieveImp, nil, name)
        if error then
            g_Logger.Error('Failed to create Module %s', name)
        else
            self.moduleMap[name] = inst;
        end
    end
    return self.moduleMap[name];
end

local function _removeImp(inst)
    inst:OnRemove();
end

---@param name string Module名字
function ModuleManager:RemoveModule(name)
    if not self.moduleMap[name] then
        g_Logger.Error("%s not exist in Manager", name);
        return;
    end
    
    local inst = self.moduleMap[name];
    try_catch_traceback_with_vararg(_removeImp, nil, inst)
    self.moduleMap[name] = nil;
end

function ModuleManager:Reset()
    if self.moduleMap then
        for k, v in pairs(self.moduleMap) do
            self:RemoveModule(k);
        end
        table.clear(self.moduleMap);
    end
end

return ModuleManager