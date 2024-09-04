--全局辅助类
local Utils = class("Utils")

function Utils.IsNull(object)
    if type(object) ~= "table"
            and type(object) ~= "userdata"
            and type(object) ~= "nil" then
        return false
    end
    if object == nil or (object.IsNull ~= nil and object:IsNull()) then
        return true
    end
    return false
end

function Utils.IsNullOrEmpty(object)
    return Utils.IsNull(object) or object == ""
end

function Utils.IsNotNull(object)
    return not Utils.IsNull(object)
end

function Utils.IsEntityNull(entity)
    if entity == nil or (entity.IsEntityNull ~= nil and entity:IsEntityNull()) then
        return true
    end
    return false
end

function Utils.IsEntityNotNull(entity)
    return not Utils.IsEntityNull(entity)
end

function Utils.InvokeCSGenericMethod(instance, methodName, genericType, ...)
    if instance == nil or genericType == nil then
        return;
    end

    local param = {...};
    local generic = xlua.get_generic_method(instance:GetType(), methodName)
    local customMethod = generic(genericType);
    if #param == 0 then
        return customMethod(instance);
    else
        return customMethod(instance, ...);
    end
end

function Utils.InvokeCSStaticGenericMethod(csClass, methodName, genericType, ...)
    if csClass == nil or genericType == nil then
        return;
    end

    local param = {...};
    local generic = xlua.get_generic_method(csClass, methodName)
    local customMethod = generic(genericType);
    if #param == 0 then
        return customMethod();
    else
        return customMethod(...);
    end
end

function Utils.Swap(tableObj, index1, index2)
    local temp = tableObj[index1]
    tableObj[index1] = tableObj[index2]
    tableObj[index2] = temp
end

function Utils.CopyTable(tableFrom, tableTo)
    table.clear(tableTo)
    for k, v in pairs(tableFrom) do
        tableTo[k] = v
    end
end

function Utils.CopyArray(arrayFrom, arrayTo)
    table.clear(arrayTo)
    for i = 1, #arrayFrom do
        arrayTo[i] = arrayFrom[i]
    end
end

function Utils.DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils.DeepCopy(orig_key)] = Utils.DeepCopy(orig_value)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(orig)))
    else
        -- 基本类型直接复制
        copy = orig
    end
    return copy
end

---判断原数据是否符合指定位掩码
---@param source 原数据
---@param mask 掩码
---@return boolean 当掩码中所有为1的位在原数据中的对应位均为1时返回true, 否则返回false
function Utils.IsBitMaskMatch(source, mask)
    if (not source or not mask) then return false end
    return (source & mask) == mask
end

function Utils.SqrMagnitudeIgnoreY(v3)
    -- v3.y = 0
    -- return Vector3.SqrMagnitude(v3)
    return v3.x *v3.x + v3.z*v3.z
end

---@param v1 CS.UnityEngine.Vector3
---@param v2 CS.UnityEngine.Vector3
function Utils.DotIgnoreY(v1,v2)
    return v1.x*v2.x + v1.z*v2.z
end

function Utils.IsTable(v)
	return v and type(v) == "table"
end

--- TableViewPro滚动到末端
---@param tableViewPro CS.TableViewPro
---@param refresh boolean
function Utils.TableViewProScrollToEnd(tableViewPro, refresh)
	if (Utils.IsNull(tableViewPro)) then return end
	local dataCount = tableViewPro.DataCount
	if (dataCount <= 0) then return end
	local data = tableViewPro:GetDataByIndex(dataCount - 1)
	if (data) then
		tableViewPro:SetDataVisable(data)
		if (refresh) then
			tableViewPro:RefreshAllShownItem()
		end
	end
end

--- TableViewPro滚动到首端
---@param tableViewPro CS.TableViewPro
---@param refresh boolean
function Utils.TableViewProScrollToHome(tableViewPro, refresh)
	if (Utils.IsNull(tableViewPro)) then return end
	local dataCount = tableViewPro.DataCount
	if (dataCount <= 0) then return end
	local data = tableViewPro:GetDataByIndex(0)
	if (data) then
		tableViewPro:SetDataVisable(data)
		if (refresh) then
			tableViewPro:RefreshAllShownItem()
		end
	end
end

--- 复制文本到系统剪贴板
---@param text string
function Utils.CopyToClipboard(text)
	CS.UnityEngine.GUIUtility.systemCopyBuffer = text
end

--- 判断两个数组内容是否相等
---@param a any[]
---@param b any[]
---@return boolean
function Utils.IsArrayContentEqual(a, b)
	if (not a and not b) then return true end
	if (a and not b) then return false end
	if (b and not a) then return false end
	if (#a ~= #b) then return false end
	for i = 1, #a do
		if (a[i] ~= b[i]) then return false end
	end
	return true
end

---@param duration number
function Utils.ParseDurationToSecond(duration)
    return duration / 1000000000
end

function Utils.FullGC()
    g_Game.SpriteManager:CleanZeroRefLRU()
    g_Game.AssetManager:UnloadUnused(function()
        collectgarbage("collect")
        CS.System.GC.Collect()
        collectgarbage("collect")
        g_Game.AssetManager:UnloadUnused()
    end)
end

--- 获取table中所有key的有序列表
---@param t table<K, any>
---@param sortFunc fun(a: K, b: K)
---@return K[]
function Utils.TableGetSortedKeys(t, sortFunc)
	if (not Utils.IsTable(t) or table.isNilOrZeroNums(t)) then return {} end
	local keys = {}
	for k, _ in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys, sortFunc)
	return keys
end

--- 反转数组
---@param array any[]
function Utils.ReverseArray(array)
	if (not array or #array <= 1) then return end
	local i = 1
	local j = #array
	while (i < j) do
		array[i], array[j] = array[j], array[i]
		i = i + 1
		j = j - 1
	end
end

--- 去除字符串首尾空白
---@param str string
function Utils.Strip(str)
    if not str or str == "" then return str end
    return str:match("^%s*(.-)%s*$")
end

---@param x number
---@param y number
---@return number
function Utils.GetLongHashCode(x, y)
    local hash = 5381
    hash = hash * 33 + x
    hash = hash * 33 + y
    return hash
end

---@param transform CS.UnityEngine.Transform
---@return string
function Utils.GetTransformPath(transform)
    local p = {}
    repeat
        table.insert(p, 1, transform.name)
        transform = transform.parent
    until Utils.IsNull(transform)
    return table.concat(p, '/')
end

return Utils
