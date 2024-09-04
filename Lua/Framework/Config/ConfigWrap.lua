---@class ConfigWrap 二维表数据封装
---@field new fun(name:string):ConfigWrap
local ConfigWrap = sealedClass("ConfigWrap")
local flatbuffers = require("flatbuffers")
local LRUList = require("LRUList")
local ConfigUtils = require("ConfigUtils");

--- 配置名约定构成：
--- name.fbs 为后端生成的fbs文件
--- name+Cfg[s].lua 为flatc生成的lua代码
function ConfigWrap:ctor(name, useLRU)
    self.name = name;
    local bytes = ConfigUtils.LoadConfigBinary(name);
    self:LoadFlatBuffer(name, bytes);
    self:PreloadIndex(bytes);
    self.useLRU = useLRU
    if self.useLRU then
        self.m_LRUList = LRUList.new(self.length)
    else
        self.m_FullList = {}
    end
end

---@private
function ConfigWrap:PreloadIndex(str)
    self.iidtoidx = {}
    if str == nil then
        g_Logger.ErrorChannel("ConfigWrap", "binary file error, load empty binary str. config name : %s", self.name)
        return
    end

    local t = #str;
    -- 这里减3是因为lua的idx是从1开始
    local p = t - 3;
    assert(p > 0, ("binary file error, when got offset. config name : %s"):format(self.name));
    local offset = string.unpack("<I4", str, p)

    p = p - offset;
    assert(p > 0, ("binary file error, when got idx length. config name : %s, read offset %d, got p %d"):format(self.name, offset, p));
    local length = string.unpack("<I4", str, p);
    
    assert((p + length * 4) < t, ("binary file error, idx offset overflow. config name : %s, got length : %d"):format(self.name, length));
    for i = 1, length do
        local iid = string.unpack("<I4", str, p + i * 4);
        self.iidtoidx[iid] = i;

        if i == 1 then
            self.firstIid = iid
        end
        if i == length then
            self.lastIid = iid
        end
    end
end

---约定, 二维表的数组命名统一为Cells
---约定, 二维表的表名+Cells是对应的lua文件名
---@private
function ConfigWrap:LoadFlatBuffer(name, data)
    local luaName = ConfigUtils.GetCfgLuaName(name);
    local fb = require(luaName);
    if data ~= nil then
        local buf = flatbuffers.binaryArray.New(data);
        self.fbInstance = fb["GetRootAs"..luaName](buf, 0);
        self.length = self.fbInstance:CellsLength();
    else
        self.length = 0;
    end
end

---@private
function ConfigWrap:CacheHit(id)
    if self.useLRU then
        return self.m_LRUList:Get(id)
    else
        return self.m_FullList[id]
    end
end

---约定, 二维表的数组命名统一为Cells
---@private
function ConfigWrap:Cache(id, inst)
    if inst == nil then
        return nil;
    end

    if self.useLRU then
        self.m_LRUList:Add(id, inst)
    else
        self.m_FullList[id] = inst
    end
    return inst;
end

---约定, 二维表的数组命名统一为Cells
---@public
---@return nil
function ConfigWrap:Find(id)
    local cache = self:CacheHit(id);
    if cache then
        return cache;
    end

    if self.iidtoidx and self.fbInstance then
        local idx = self.iidtoidx[id];
        if idx then
            local inst = self.fbInstance:Cells(idx)
            return self:Cache(id, inst);
        end
    end
    return nil;
end

function ConfigWrap:pairs()
    local iid, idx = nil, nil
    return function()
        iid, idx = next(self.iidtoidx, iid)
        if iid ~= nil then
            return idx, self:Find(iid)
        end
    end
end

---@public
function ConfigWrap:ipairs()
    local index = 0;
    local count = self.length;
    local iids = {}
    for iid, idx in pairs(self.iidtoidx) do
        table.insert(iids, iid)
    end
    table.sort(iids, function(l, r)
        return self.iidtoidx[l] < self.iidtoidx[r]
    end)

    return function()
        index = index + 1;
        if index <= count then
            return index, self:Find(iids[index]);
        end
    end
end

function ConfigWrap:inverse_ipairs()
    local index = self.length + 1;
    local iids = {}
    for iid, idx in pairs(self.iidtoidx) do
        table.insert(iids, iid)
    end
    table.sort(iids, function(l, r)
        return self.iidtoidx[l] < self.iidtoidx[r]
    end)

    return function()
        index = index - 1;
        if index > 0 then
            return index, self:Find(iids[index]);
        end
    end
end

return ConfigWrap