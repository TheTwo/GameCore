---@class Delegate
local Delegate = {}
local getmetatable = getmetatable;
local setmetatable = setmetatable;
local type = type
local table = table
local pairs = pairs

Delegate.__index = Delegate;
Delegate.__call = function(tab, ...)
	if tab.funcs == nil then
		return;
	end

	local ret = nil;
	for _, v in pairs(tab.funcs) do
		ret = v(...);
	end
	return ret;
end

Delegate.__add = function(l, r)
	if type(l) == "table" and getmetatable(l) == Delegate then
		if type(r) == "table" and getmetatable(r) == Delegate then
			for k, v in pairs(r.funcs) do
				table.insert(l.funcs, v);
			end
		elseif type(r) == "function" then
			table.insert(l.funcs, r);
		end
		return l;
	elseif type(r) == "table" and getmetatable(l) == Delegate then
		if type(l) == "table" and getmetatable(l) == Delegate then
			for k, v in pairs(l.funcs) do
				table.insert(r.funcs, v);
			end
		elseif type(l) == "function" then
			table.insert(r.funcs, l);
		end
		return r;
	end
end

Delegate.__sub = function(l, r)
	if type(l) == "table" and getmetatable(l) == Delegate then
		if type(r) == "table" and getmetatable(r) == Delegate then
			for k, v in pairs(r.funcs) do
				table.removebyvalue(l.funcs, v);
			end
		elseif type(r) == "function" then
			table.removebyvalue(l.funcs, r);
		end
		return l;
	end
end

function Delegate.New()
	local inst = setmetatable({funcs = {}}, Delegate);
	return inst;
end

function Delegate:Clear()
	self.funcs = {}
end

function Delegate.GetOrCreate(instance, func)
	if not instance and func then
		return func
	end
	if instance and func then
		local f = instance[func]
		if not f then
			f = function(...)
				return func(instance, ...)
			end
			instance[func] = f
		end
		return f
	end
end

function Delegate.Combine(del, other)
    if not del then
        return other
    elseif other then
        return del + other
    end
    return del
end

function Delegate.Remove(del, other)
    if del then
        return del - other
    end
    return del
end

return Delegate