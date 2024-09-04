local rapidJson = require("rapidjson")
local memlib = ssr_memlib --implemented in C, registered in ScriptEngine(C#)
local IsLeakedManagedObject = CS.LuaMemoryProfiler.Utility.IsLeakedManagedObject
local CacheRefIndex = CS.LuaMemoryProfiler.Utility.GetCacheRefIndex()

---@class ObjectInfo
---@field type number
---@field category string
---@field remark string
---@field tag string
---@field size number @comment size in bytes

---@class ReferenceInfo
---@field name string
---@field type number

---@class ObjectReferenceInfoContainer
---@field references table<string, table<string, ReferenceInfo>>
---@field objects table<string, ObjectInfo>

local Public = {}
local Private = {}

local ReferenceType =
{
	None = 0,
	TableKey = 1,
	TableValue = 2,
	MetaTable = 3,
	Upvalue = 4,
	Env = 5,
}

local ObjectType = 
{
	Table = 1,
	Function = 2,
	Thread = 3,
	UserData = 4,
}

-- Get the string result without overrided __tostring.
local function GetOriginalToStringResult(cObject)
	if not cObject then
		return ""
	end

	local cMt = getmetatable(cObject)
	if not cMt or type(cMt) ~= "table" then
		return tostring(cObject)
	end

	-- Check tostring override.
	local strName = ""
	local cToString = rawget(cMt, "__tostring")
	if cToString then
		rawset(cMt, "__tostring", nil)
		strName = tostring(cObject)
		rawset(cMt, "__tostring", cToString)
	else
		strName = tostring(cObject)
	end

	return strName
end

local function SplitString(inputstr, sep)
	if inputstr == nil or string.len(inputstr) <= 0 then
		return "", ""
	end

	local startIndex, endIndex = string.find(inputstr, sep)
	if startIndex == nil or endIndex == nil then
		return "", ""
	end
	return string.sub(inputstr, 1, startIndex - 1), string.sub(inputstr, endIndex + 1)
end

local function GetCategoryAddress(object)
	local result = GetOriginalToStringResult(object)
	return SplitString(result, ": ")
end

local function GetTableCategoryAddress(object)
	local tag = ""
	local category, address = GetCategoryAddress(object)
	local isInstance = rawget(object, "__isInstance")
	if isInstance then
		local metatable = getmetatable(object)
		local cls = rawget(metatable, "__index")
		local cname = rawget(cls, "__cname")
		category = cname
		tag = "[Instance]"
	else
		local isClass = rawget(object, "__isClass")
		if isClass then
			local cname = rawget(object, "__cname")
			category = cname
			tag = "[Class]"
		end
	end
	return category, address, tag
end

-- Create a container to collect the mem ref info results.
---@return ObjectReferenceInfoContainer
function Private.CreateObjectReferenceInfoContainer()
    ---@type ObjectReferenceInfoContainer
	local container = {}

	---@type table<string, table<string, string>>
	local references = {}

    ---@type table<string, ObjectInfo>
	local objects = {}

	container.references = references
	container.objects = objects

	return container
end

---@param references table<string, table<string, string>>
---@param objectAddress string
---@param referenceName string
---@param referenceType number
---@param referencedBy string
function Private.AddReferenceInfo(references, objectAddress, referenceName, referenceType, referencedByAddress)
    if referencedByAddress == nil or referencedByAddress == "" then
        return
    end

    local set = references[objectAddress]
    if set == nil then
        set = {}
        references[objectAddress] = set
    end

	---@type ReferenceInfo
	local info = { name = referenceName, type = referenceType }
	
    set[referencedByAddress] = info
end

---@param referenceName string
---@param objectType number
---@param size number @comment 
---@return ObjectInfo
function Private.CreateObjectInfo(objectType, category, tag, remark, size)
	---@type ObjectInfo
    local objectInfo = { type = objectType, category = category, tag = tag, remark = remark, size = size}
	return objectInfo
end

---@param key any @comment a key of a table
---@return string
function Private.GetTableKeyName(key)
    local type = type(key)
    if type == "string" or type == "number" or type == "boolean" then
        return tostring(key)
    end
    return ""
end

function Private.IsUserDataLeakedManagedObject(object)
	local metatable = getmetatable(object)
	if type(metatable) == "table" then
		local xluatag = memlib.getxluatag()
		local mark = rawget(metatable, xluatag)
		if mark then
			return IsLeakedManagedObject(object)
		end
	end
	return false
end

-- Collect memory reference info from a root table or function.
---@param object any @comment The root object that start to search
---@param referenceName string @comment The root object name that start to search
---@param referenceType number @comment reference type
---@param referencedBy any @comment The object who references to the "object"
---@param container ObjectReferenceInfoContainer @comment The container of the dump result info.
function Private.CollectObjectReferences(object, referenceName, referenceType, referencedBy, container)
	-- Get object info.
	local objects = container.objects

	-- Get references.
	local references = container.references

    local getfenv = debug.getfenv
	local objectType = type(object)
	if "table" == objectType then
		local category, objectAddress, tag = GetTableCategoryAddress(object)
		local _, referencedByAddress = GetCategoryAddress(referencedBy)
		Private.AddReferenceInfo(references, objectAddress, referenceName, referenceType, referencedByAddress)
		
		-- If current object is visited, skip
		if objects[objectAddress] then
			return
		end

		-- Check if table is _G.
		if object == _G then
			tag = "[_G]"
		end

		-- Check if table is registry
		local Registry = debug.getregistry()
		if object == Registry then
			tag = "[Registry]"
		end

		-- Check if table is CS of XLua
		if object == CS then
			tag = "[CS]"
		end

		-- Check if table is CacheRef of XLua
		local CacheRef = Registry[CacheRefIndex]
		if object == CacheRef then
			tag = "[CacheRef]"
		end

		local size = memlib.gettablesize(object)
        objects[objectAddress] = Private.CreateObjectInfo(ObjectType.Table, category, tag, "", size)

		-- Get metatable.
		local bWeakK = false
		local bWeakV = false
		local cMt = getmetatable(object)
		if cMt and type(cMt) == "table" then
			-- Check mode.
			local strMode = rawget(cMt, "__mode")
			if strMode then
				if "k" == strMode then
					bWeakK = true
				elseif "v" == strMode then
					bWeakV = true
				elseif "kv" == strMode then
					bWeakK = true
					bWeakV = true
				end
			end
		end

		-- Dump table key and value.
		for k, v in pairs(object) do
            local keyName = Private.GetTableKeyName(k)
            if not bWeakK then
                Private.CollectObjectReferences(k, keyName, ReferenceType.TableKey, object, container)
            end

            if not bWeakV then
                Private.CollectObjectReferences(v, keyName, ReferenceType.TableValue, object, container)
            end
		end

		-- Dump metatable.
		if cMt then
			Private.CollectObjectReferences(cMt, "", ReferenceType.MetaTable, object, container)
		end
	elseif "function" == objectType then
		local category, objectAddress = GetCategoryAddress(object)
		local _, referencedByAddress = GetCategoryAddress(referencedBy)
		Private.AddReferenceInfo(references, objectAddress, referenceName, referenceType, referencedByAddress)
		
		-- If current object is visited, skip
		if objects[objectAddress] then
			return
		end

		local size = memlib.getluaclosuresize(object)

		-- Get function info.
		local cDInfo = debug.getinfo(object, "Su")

		-- Create object info.
        local source = string.format("%s:%d", string.gsub(cDInfo.short_src, '\\', '/'), cDInfo.linedefined)
        objects[objectAddress] = Private.CreateObjectInfo(ObjectType.Function, category, "", source, size)

		-- Get upvalues.
		local nUpsNum = cDInfo.nups
		for i = 1, nUpsNum do
			local strUpName, cUpValue = debug.getupvalue(object, i)
            Private.CollectObjectReferences(cUpValue, strUpName, ReferenceType.Upvalue, object, container)
		end

		-- Dump environment table.
		if getfenv then
			local cEnv = getfenv(object)
			if cEnv then
				Private.CollectObjectReferences(cEnv, "_ENV", ReferenceType.Env, object, container)
			end
		end
	elseif "thread" == objectType then
		local category, objectAddress = GetCategoryAddress(object)
		local _, referencedByAddress = GetCategoryAddress(referencedBy)
		Private.AddReferenceInfo(references, objectAddress, referenceName, referenceType, referencedByAddress)
		
		-- If current object is visited, skip
		if objects[objectAddress] then
			return
		end

		local size = memlib.getthreadsize(object)
        objects[objectAddress] = Private.CreateObjectInfo(ObjectType.Thread, category, "", "", size)

		-- Dump environment table.
		if getfenv then
			local cEnv = getfenv(object)
			if cEnv then
				Private.CollectObjectReferences(cEnv, "_ENV", ReferenceType.Env, object, container)
			end
		end

		-- Dump metatable.
		local cMt = getmetatable(object)
		if cMt then
			Private.CollectObjectReferences(cMt, "", ReferenceType.MetaTable, object, container)
		end
	elseif "userdata" == objectType then
		local category, objectAddress = GetCategoryAddress(object)
		local _, referencedByAddress = GetCategoryAddress(referencedBy)
		Private.AddReferenceInfo(references, objectAddress, referenceName, referenceType, referencedByAddress)
		
		-- If current object is visited, skip
		if objects[objectAddress] then
			return
		end

		local size = memlib.getuserdatasize(object)
		local leaked = Private.IsUserDataLeakedManagedObject(object)
		local remark = ""
		if leaked then
			remark = "Referenced Leaked Managed Shell of an Unity Object"
		end
        objects[objectAddress] = Private.CreateObjectInfo(ObjectType.UserData, category, "", remark, size)

		-- Dump environment table.
		if getfenv then
			local cEnv = getfenv(object)
			if cEnv then
				Private.CollectObjectReferences(cEnv, "_ENV", ReferenceType.Env, object, container)
			end
		end

		-- Dump metatable.
		local cMt = getmetatable(object)
		if cMt then
            Private.CollectObjectReferences(cMt, "", ReferenceType.MetaTable, object, container)
		end
	else
		-- Can not get address of string, number, boolean, skip
	end
end

-- Get the format string of date time.
local function FormatDateTimeNow()
	local cDateTime = os.date("*t")
	local strDateTime = string.format("%04d%02d%02d-%02d%02d%02d", tostring(cDateTime.year), tostring(cDateTime.month), tostring(cDateTime.day),
		tostring(cDateTime.hour), tostring(cDateTime.min), tostring(cDateTime.sec))
	return strDateTime
end

local function OutputJson(savePath, json)
	-- Check save path affix.
	local strAffix = string.sub(savePath, -1)
	if ("/" ~= strAffix) and ("\\" ~= strAffix) then
		savePath = savePath .. "/"
	end

	local strDateTime = FormatDateTimeNow()

	-- Combine file name.
	local strFileName = savePath .. "LuaMemorySnapshot-" .. strDateTime .. ".json"

	local cFile = io.open(strFileName, "w")
	cFile:write(json)
	io.close(cFile)
end

---@param savePath string
function Public.Capture(savePath)
	local size = collectgarbage("count") * 1024
    local container = Private.CreateObjectReferenceInfoContainer()
	container.size = math.round(size)
    Private.CollectObjectReferences(debug.getregistry(), "", ReferenceType.None, nil, container)
	local json = rapidJson.encode(container, { pretty = true })
	OutputJson(savePath, json)
end

return Public