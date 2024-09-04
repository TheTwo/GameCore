--[[

Copyright (c) 2014-2017 Chukong Technologies Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

function printLog(tag, fmt, ...)
    local t = {
        "[",
        string.upper(tostring(tag)),
        "] ",
        string.format(tostring(fmt), ...)
    }
    print(table.concat(t))
end

function printError(fmt, ...)
    printLog("ERR", fmt, ...)
    print(debug.traceback("", 2))
end

function printInfo(fmt, ...)
    if type(DEBUG) ~= "number" or DEBUG < 2 then return end
    printLog("INFO", fmt, ...)
end

local function dump_value_(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function dump(value, description, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function dump_(value, description, indent, nest, keylens)
        description = description or "<var>"
        local spc = ""
        if type(keylens) == "number" then
            spc = string.rep(" ", keylens - string.len(dump_value_(description)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_value_(description), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, dump_value_(description), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(description))
            else
                result[#result +1 ] = string.format("%s%s = {", indent, dump_value_(description))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, description, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

function printf(fmt, ...)
    print(string.format(tostring(fmt), ...))
end

function checknumber(value, base)
    return tonumber(value, base) or 0
end

function checkint(value)
    return math.round(checknumber(value))
end

function checkbool(value)
    return (value ~= nil and value ~= false)
end

function checktable(value)
    if type(value) ~= "table" then value = {} end
    return value
end

function isset(hashtable, key)
    local t = type(hashtable)
    return (t == "table" or t == "userdata") and hashtable[key] ~= nil
end

local setmetatableindex_
setmetatableindex_ = function(t, index)
    if type(t) == "userdata" then
        local peer = tolua.getpeer(t)
        if not peer then
            peer = {}
            tolua.setpeer(t, peer)
        end
        setmetatableindex_(peer, index)
    else
        local mt = getmetatable(t)
        if not mt then mt = {} end
        if not mt.__index then
            mt.__index = index
            setmetatable(t, mt)
        elseif mt.__index ~= index then
            setmetatableindex_(mt, index)
        end
    end
end
setmetatableindex = setmetatableindex_

function FormatValue(val)
    if type(val) == "string" then
        return string.format("%q", val)
    end
    return tostring(val)
end

function FormatTable(t, tabcount)
    tabcount = tabcount or 0
    if tabcount > 10 then
        --防止栈溢出
        return "<table too deep>"..tostring(t)
    end
    local str = ""
    if type(t) == "table" then
        for k, v in pairs(t) do
            local tab = string.rep("\t", tabcount)
            if type(v) == "table" then
                str = str..tab..string.format("[%s] = {", FormatValue(k))..'\n'
                str = str..FormatTable(v, tabcount + 1)..tab..'}\n'
            else
                str = str..tab..string.format("[%s] = %s", FormatValue(k), FormatValue(v))..',\n'
            end
        end
    else
        str = str..tostring(t)..'\n'
    end
    return str
end

function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local newObject = {}
        lookup_table[object] = newObject
        for key, value in pairs(object) do
            newObject[_copy(key)] = _copy(value)
        end
        return setmetatable(newObject, getmetatable(object))
    end
    return _copy(object)
end

function math.newrandomseed()
    local ok, socket = pcall(function()
        return require("socket")
    end)

    if ok then
        math.randomseed(socket.gettime() * 1000)
    else
        math.randomseed(os.time())
    end
    math.random()
    math.random()
    math.random()
    math.random()
end

function math.round(value)
    value = checknumber(value)
    return math.floor(value + 0.5)
end

local pi_div_180 = math.pi / 180
function math.angle2radian(angle)
    return angle * pi_div_180
end

function math.radian2angle(radian)
    return radian * 180 / math.pi
end

function math.clamp(value, min, max)
    return math.max(min, math.min(value, max));
end

function math.clamp01(value)
    if value ~= value then return 0 end
    return math.clamp(value, 0, 1);
end

function math.step(startV, endV, step)
    local rawStep = math.clamp01(step)
    return startV + (endV - startV) * rawStep
end

function math.lerp(from, to, percent)
    return from + (to - from) * math.clamp01(percent);
end

function math.inverseLerp(a, b, value)
    if math.Approximately(a, b) then
        return 0
    else
        return math.clamp01((value - a) / (b - a))
    end
end

function math.sign(number)
    return (number > 0 and 1) or (number == 0 and 0) or -1
end

function math.float02(number)
    return tonumber(string.format('%.2f', number))
end

function math.divprotect(number)
    if number == 0 then return 1 end
    return number
end

math.Epsilon = CS.UnityEngine.Mathf.Epsilon

---@param a number
---@param b number
---@return boolean
function math.Approximately(a, b)
    if a == b then
        return true
    end
    return math.abs(b - a) < 1E-06
end

function math.isinteger(number)
    return math.floor(number) == number
end

function io.exists(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        return true
    end
    return false
end

function io.readfile(path, isBinary)
    local file = io.open(path, isBinary and "rb" or "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        return content
    end
    return nil
end

function io.writefile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

function io.pathinfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname
    }
end

function io.filesize(path)
    local size = false
    local file = io.open(path, "r")
    if file then
        local current = file:seek()
        size = file:seek("end")
        file:seek("set", current)
        io.close(file)
    end
    return size
end

function table.ipairsNums(t)
    local count = 0
    if t ~= nil then
        for k, v in ipairs(t) do
            count = count + 1
        end
    end
    return count
end

function table.nums(t)
    local count = 0
    if t ~= nil then
        for _, _ in pairs(t) do
            count = count + 1
        end
    end
    return count
end

function table.morethan(t,num)
    local count = 0
    if t ~= nil then
        for _, _ in pairs(t) do
            count = count + 1
            if count > num then
                return true
            end
        end
    end
    return false
end

function table.keys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

function table.values(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

function table.sumValues(hashtable)
    local ret = 0
    for k, v in pairs(hashtable) do
        ret = ret + v
    end
    return ret
end

function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

function table.insertto(dest, src, begin)
    begin = checkint(begin)
    if begin <= 0 then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

function table.addrange(dest, src)
    if dest ~= nil then
        local len = table.nums(dest);
        local begin = len + 1;
        table.insertto(dest, src, begin);
    end
end

function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then return i end
    end
    return -1
end

function table.keyof(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then return k end
    end
    return nil
end

function table.Valueof(hashtable, key)
    for k, v in pairs(hashtable) do
        if k == key then return v end
    end
    return nil
end

function table.pairsByKeys(hashTable)
    local a = {};
    for n in pairs(hashTable) do
        a[#a + 1] = n;
    end
    table.sort(a);
    
    local i = 0;
    return function()
        i = i + 1;
        return a[i], hashTable[a[i]];
    end
end

function table.ValueOfIndex(hashtable, index)
    local i = 1;
    for k, v in table.pairsByKeys(hashtable) do
        if i == tonumber(index) then
            return v;
        end
        i = i + 1;
    end
end

function table.KeyOfIndex(hashtable, index)
    local i = 1;
    for k, v in table.pairsByKeys(hashtable) do
        if i == tonumber(index) then
            return k;
        end
        i = i + 1;
    end
end

function table.ContainsKey(hashtable, key)
    if hashtable ~= nil then
        for k, v in pairs(hashtable) do
            if k == key then return true end
        end
    end
    return false
end

function table.ContainsValue(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then return true end
    end
    return false
end

function table.removebyvalue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

function table.removeElementByKey(tbl,key)
    local tmp ={}
    for i in pairs(tbl) do
        table.insert(tmp,i)
    end

    local newTbl = {}
    local i = 1
    while i <= #tmp do
        local val = tmp [i]
        if val == key then
            table.remove(tmp,i)
        else
            newTbl[val] = tbl[val]
            i = i + 1
        end
    end
    return newTbl
end

function table.getLastValue(tbl)
    local tmp ={}
    for _,v in pairs(tbl) do
        if v ~= nil then
            table.insert(tmp,v);
        end
    end
    return tmp[#tmp];
end

function table.map(t, fn)
    for k, v in pairs(t) do
        t[k] = fn(v, k)
    end
end

function table.walk(t, fn)
    for k,v in pairs(t) do
        fn(v, k)
    end
end

function table.filter(t, fn)
    for k, v in pairs(t) do
        if not fn(v, k) then t[k] = nil end
    end
end

function table.unique(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end

function table.mapToList(t)
    if not t then return t end
    local list = {}
    for k, v in pairs(t) do
        list[#list+1] = {key = k,value = v}
    end
    return list;
end

function table.mapToListAndMap(t)
    if not t then return t end
    local list = {array = {},map = t}
    list.array = table.mapToList(t)
    return list
end



function table.clear(t)
    if not t then return t end
    
    for k, _ in pairs(t) do
        t[k] = nil;
    end
    return t;
end

function table.shuffle(array)
    local counter = #array
    while counter > 1 do
        local index = math.random(counter)
        array[counter], array[index] = array[index], array[counter]
        counter = counter - 1
    end
    return array
end

---@return boolean, number
function table.IsNullOrEmpty(tbl)
    if tbl ~= nil then
        local nums = table.nums(tbl);
        return nums == 0, nums;
    end
    return true, 0;
end

---@return boolean
function table.isNilOrZeroNums(t)
    if t == nil then
        return true
    end
    for _, _ in pairs(t) do
        return false
    end
    return true
end

function table.any(tbl, func)
    for k, v in pairs(tbl) do
        if func(v) then
            return true;
        end
    end
    return false;
end

function table.getOrCreate(tbl, key)
    local ret = tbl[key]
    if not ret then
        ret = {}
        tbl[key] = ret
    end
    return ret
end

string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end

function string.restorehtmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, v, k)
    end
    return input
end

function string.nl2br(input)
    return string.gsub(input, "\n", "<br />")
end

function string.text2html(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

function string.ucfirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end
function string.urlencode(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end

function string.urldecode(input)
    input = string.gsub (input, "+", " ")
    input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h,16)) end)
    input = string.gsub (input, "\r\n", "\n")
    return input
end

function string.utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

---@param src string
---@param value string
---@return boolean
function string.EndWith(src, value)
    if string.IsNullOrEmpty(value) then
        return true;
    end
    if string.IsNullOrEmpty(src) then
        return false;
    end
    return string.StartWith(string.reverse(src), string.reverse(value));
end

---@param src string
---@param value string
---@return boolean
function string.StartWith(src, value)
    if string.IsNullOrEmpty(value) then
        return true;
    end
    if string.IsNullOrEmpty(src) then
        return false;
    end
    local lenSrc = #src;
    local lenValue = #value;
    if lenSrc >= lenValue then
        local idx = 1;
        while idx <= lenValue and (string.sub(src, idx, idx) == string.sub(value, idx, idx)) do
            idx = idx + 1;
        end
        return idx >= lenValue + 1;
    end
    return false;
end

string.Empty = '';

function string.IsNullOrEmpty(str)
    return str == nil or str == string.Empty;
end

function string.AppendLine(src, str)
    if string.IsNullOrEmpty(src) then
        return str;
    end
    return string.format('%s\n%s', src, str);
end

function string.compare(a, b)
    local la, lb = #a, #b
    for i = 1, math.min(la, lb) do
        local ca, cb = string.byte(a, i), string.byte(b, i)
        if ca ~= cb then
            return ca < cb
        end
    end
    return la < lb
end

--暂未优化
function utf8.find(src, sub, i, j)
    if sub == nil or sub == "" then
        return -1, -1
    end
    local srcList = {}
    for _, v in utf8.codes(src) do
        table.insert(srcList, v)
    end
    local subList = {}
    for _, v in utf8.codes(sub) do
        table.insert(subList, v)
    end
    local subLen = #subList
    local srcLen = #srcList
    i = i or 1
    j = j and (j > srcLen and srcLen or j) or #srcList
    if j - i + 1 < subLen then
        return -1, -1
    end
    for k = i, j do
        if j - k + 1 < subLen then
            break
        end
        local match = true
        for s, v in ipairs(subList) do
            if srcList[k + s - 1] ~= v then
                match = false
                break
            end
        end
        if match then
            return k, k + subLen - 1
        end
    end
    return -1, -1
end

function utf8.sub(s, i, j)
    i = i or 1
    j = j or utf8.len(s)
    local wordIndex = 0
    local beginByteIndex = 1
    local endByteIndex
    for k, v in utf8.codes(s) do
        wordIndex = wordIndex + 1
        if wordIndex == i then
            beginByteIndex = k
        end
        if wordIndex == j + 1 then
            endByteIndex = k - 1
            break
        end
    end
    if not endByteIndex then
        endByteIndex = string.len(s)
    end
    return string.sub(s, beginByteIndex, endByteIndex)
end

function os.gettimezone()
    return tonumber(os.date("%z", 0))/100
end

function deepcompare(t1,t2)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
   
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    if #t1 ~= #t2 then return false end
    for k1,v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not deepcompare(v1,v2) then return false end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
         if v1 == nil or not deepcompare(v1,v2) then return false end
    end
    return true
end

function get_filename_without_extension(path)
    local filename = string.match(path, "[^/\\]*$")
    local pos = string.find(filename, ".", 1, true)
    if pos then
        return string.sub(filename, 1, pos-1)
    else
        return filename
    end
end

function fix_url(url)
    if string.IsNullOrEmpty(url) then
        return url
    end

    if not string.match(url, "^[a-zA-Z]+://") then
        url = "http://" .. url
    end
    
    return url
end