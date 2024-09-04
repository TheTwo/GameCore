local schema = {}

---@param subclass table
---@param superclass table
function schema.append(subclass, superclass)
    if type(subclass) ~= "table" or type(superclass) ~= "table" then
        return {}
    end

    local cache = {}
    
    for _,item in ipairs(subclass) do
        local name = item[1]
        if name ~= nil and name ~= "" then
            cache[name] = true
        end
    end

    for _, item in ipairs(superclass) do
        local name = item[1]
        if not cache[name] then
            table.insert(subclass, item)
        end
    end
    
    return subclass
end

return schema