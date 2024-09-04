local BTUtils = {}

function BTUtils.GetRandomList(length)
    local ret = {};
    local chosen_list = {}
    for i = 1, length do
        table.insert(chosen_list, i);
    end

    for i = 1, length do
        local r = math.random(1, #chosen_list);
        table.insert(ret, chosen_list[r]);
        table.remove(chosen_list, r);
    end
    return ret;
end

return BTUtils;